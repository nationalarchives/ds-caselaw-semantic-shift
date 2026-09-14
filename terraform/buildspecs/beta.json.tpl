version: 0.2

phases:
  pre_build:
    commands:
      - echo Build started on `date`
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "${split("/", repository_url)[0]}"
  build:
    commands:
      - echo Building the Docker image...
      - IMAGE_TAG=commit-$CODEBUILD_RESOLVED_SOURCE_VERSION
      - docker build -t ${repository_url}:$IMAGE_TAG .
      - echo Tagging built image as latest...
      - docker tag ${repository_url}:$IMAGE_TAG ${repository_url}:latest
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image to ECR ...
      - IMAGE_TAG=commit-$CODEBUILD_RESOLVED_SOURCE_VERSION
      - docker push ${repository_url}:latest
      - docker push ${repository_url}:$IMAGE_TAG
      - |
        set -eu
        echo "Writing appspec file...";
        jq -n \
          --arg image "${repository_url}:$IMAGE_TAG" \
          --arg name "${container_name}" \
          --arg cloudwatch_log_group "${cloudwatch_log_group}" \
          --arg region "$AWS_DEFAULT_REGION" \
          --arg awslogs_stream_prefix "${awslogs_stream_prefix}" \
          --argjson host_port ${app_container_port} \
          --argjson container_port ${app_container_port} \
          --argjson environment '${environment_json}' \
          --argjson linux_parameters '${linux_parameters_json}' \
          --argjson entrypoint '${app_entrypoint_json}' \
          '[{
            image: $image,
            name: $name,
            logConfiguration: {
              logDriver: "awslogs",
              options: {
                "awslogs-group": $cloudwatch_log_group,
                "awslogs-region": $region,
                "awslogs-stream-prefix": $awslogs_stream_prefix
              }
            },
            portMappings: [{
              hostPort: $host_port,
              protocol: "tcp",
              containerPort: $container_port
            }],
            environment: $environment,
            linuxParameters: $linux_parameters,
            entryPoint: $entrypoint,
            command: [],
            memoryReservation: 16,
            essential: true
          }]' > new-container-defs.json;
        test -s new-container-defs.json;
        NEW_TASK_DEFINITION="$(aws ecs register-task-definition \
          --family "${task_definition_family}" \
          --container-definitions file://new-container-defs.json \
          --task-role-arn "${task_role_arn}" \
          --execution-role-arn "${execution_role_arn}" \
          --network-mode "awsvpc" \
          --requires-compatibilities "FARGATE" \
          --memory "${task_memory}" \
          --cpu "${task_cpu}" \
          )";
        NEW_TASK_DEFINITION_ARN="$(echo "$NEW_TASK_DEFINITION" | jq -r '.taskDefinition.taskDefinitionArn')";
        jq -n \
          --arg task_definition_arn "$NEW_TASK_DEFINITION_ARN" \
          --arg container_name "${container_name}" \
          --argjson container_port ${app_container_port} \
          '{
            version: "0.0",
            Resources: [{
              TargetService: {
                Type: "AWS::ECS::Service",
                Properties: {
                  TaskDefinition: $task_definition_arn,
                  LoadBalancerInfo: {
                    ContainerName: $container_name,
                    ContainerPort: $container_port
                  }
                }
              }
            }]
          }' > appspec.json;
        test -s appspec.json;
        jq . appspec.json;
artifacts:
  files:
    - appspec.json
