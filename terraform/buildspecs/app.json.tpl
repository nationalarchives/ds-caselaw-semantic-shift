version: 0.2

phases:
  pre_build:
    commands:
      - echo Build started on `date`
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "${repository_url%/*}"
  build:
    commands:
      - echo Building the Docker image...
      - IMAGE_TAG=commit-$CODEBUILD_RESOLVED_SOURCE_VERSION
      - cd app-folder
      - docker build -t ${repository_url}:$IMAGE_TAG .
      - cd ..
      - echo Tagging built image as latest...
      - docker tag ${repository_url}:$IMAGE_TAG ${repository_url}:latest
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image to ECR ...
      - IMAGE_TAG=commit-$CODEBUILD_RESOLVED_SOURCE_VERSION
      - docker push ${repository_url}:latest
      - docker push ${repository_url}:$IMAGE_TAG
      - >-
        echo "Writing appspec file...";
        APP_PORT="${app_container_port}";
        container_name="${container_name}";
        task_definition_family="${task_definition_family}";
        task_role_arn="${task_role_arn}";
        execution_role_arn="${execution_role_arn}";
        task_memory="${task_memory}";
        task_cpu="${task_cpu}";
        image="${repository_url}:$IMAGE_TAG";
        cloudwatch_log_group="${cloudwatch_log_group}";
        region="$AWS_DEFAULT_REGION";
        awslogs_stream_prefix="${awslogs_stream_prefix}";
        host_port="$APP_PORT";
        container_port="$APP_PORT";
        environment='${environment_json}';
        linux_parameters='${linux_parameters_json}';
        entrypoint='${app_entrypoint_json}';
        export container_name task_definition_family task_role_arn execution_role_arn task_memory task_cpu image cloudwatch_log_group region awslogs_stream_prefix host_port container_port environment linux_parameters entrypoint;
        envsubst < terraform/container-definitions/app.json.tpl > /new-container-defs.json;
        NEW_TASK_DEFINITION="$(aws ecs register-task-definition \
          --family "${task_definition_family}" \
          --container-definitions file:///new-container-defs.json \
          --task-role-arn "${task_role_arn}" \
          --execution-role-arn "${execution_role_arn}" \
          --network-mode "awsvpc" \
          --requires-compatibilities "FARGATE" \
          --memory "${task_memory}" \
          --cpu "${task_cpu}" \
          )";
        NEW_TASK_DEFINITION_ARN="$(echo "$NEW_TASK_DEFINITION" | jq -r '.taskDefinition.taskDefinitionArn')";
        task_definition_arn="$NEW_TASK_DEFINITION_ARN";
        export task_definition_arn;
        envsubst < terraform/appspecs/ecs.json.tpl > appspec.json;
artifacts:
  files:
    - appspec.json
