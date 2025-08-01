version: 0.2

phases:
  pre_build:
    commands:
      - echo Build started on `date`
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
  build:
    commands:
      - echo Building the Docker image...
      - cd app-folder
      - docker build -t $IMAGE_REPO_NAME:test .
      - cd ..
      - IMAGE_TAG=commit-$CODEBUILD_RESOLVED_SOURCE_VERSION
      - echo Tagging the successfully tested image as latest...
      - docker tag $IMAGE_REPO_NAME:test $REPOSITORY_URL:latest
      - docker tag $IMAGE_REPO_NAME:test $REPOSITORY_URL:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image to ECR ...
      - IMAGE_TAG=commit-$CODEBUILD_RESOLVED_SOURCE_VERSION
      - docker push $REPOSITORY_URL:latest
      - docker push $REPOSITORY_URL:$IMAGE_TAG
      - >-
        echo "Writing appspec file...";
        aws ecs describe-task-definition --task-definition "$TASK_DEFINITION_FAMILY" | jq > latest-task-definition.json;
        cat latest-task-definition.json | jq -r --arg image "$REPOSITORY_URL:$IMAGE_TAG" '.taskDefinition.containerDefinitions | .[0].image = $image' > /new-container-defs.json;
        NEW_TASK_DEFINITION="$(aws ecs register-task-definition \
          --family "$TASK_DEFINITION_FAMILY" \
          --container-definitions file:///new-container-defs.json \
          --task-role-arn "$(cat latest-task-definition.json | jq -r '.taskDefinition.taskRoleArn')" \
          --execution-role-arn "$(cat latest-task-definition.json | jq -r '.taskDefinition.executionRoleArn')" \
          --network-mode "$(cat latest-task-definition.json | jq -r '.taskDefinition.networkMode')" \
          --volumes "$(cat latest-task-definition.json | jq -r '.taskDefinition.volumes')" \
          --placement-constraints "$(cat latest-task-definition.json | jq -r '.taskDefinition.placementConstraints')" \
          --requires-compatibilities "$(cat latest-task-definition.json | jq -r '.taskDefinition.requiresCompatibilities')" \
          --memory "$(cat latest-task-definition.json | jq -r '.taskDefinition.memory')" \
          --cpu "$(cat latest-task-definition.json | jq -r '.taskDefinition.cpu')" \
          )";
        NEW_TASK_DEFINITION_ARN="$(echo "$NEW_TASK_DEFINITION" | jq -r '.taskDefinition.taskDefinitionArn')";
        CONTAINER_PORT="$(echo "$NEW_TASK_DEFINITION" | jq -r '.taskDefinition.containerDefinitions[0].portMappings[0].containerPort')";
        APPSPEC="$(jq -rn \
          --arg task_definition_arn "$NEW_TASK_DEFINITION_ARN" \
          --arg container_name "$CONTAINER_NAME" \
          --argjson container_port "$CONTAINER_PORT" \
          '{
            Resources: [
              {
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
              }
            ]
          }')";
        echo "$APPSPEC" > appspec.json;
artifacts:
  files:
    - appspec.json
