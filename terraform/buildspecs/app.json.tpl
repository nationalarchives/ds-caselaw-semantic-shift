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
        APP_PORT="${APP_CONTAINER_PORT}";
        container_name="$CONTAINER_NAME";
        image="$REPOSITORY_URL:$IMAGE_TAG";
        cloudwatch_log_group="$CLOUDWATCH_LOG_GROUP";
        region="$AWS_DEFAULT_REGION";
        awslogs_stream_prefix="$AWSLOGS_STREAM_PREFIX";
        host_port="$APP_PORT";
        container_port="$APP_PORT";
        environment='[]';
        linux_parameters='{"initProcessEnabled":false}';
        entrypoint="$APP_ENTRYPOINT_JSON";
        export container_name image cloudwatch_log_group region awslogs_stream_prefix host_port container_port environment linux_parameters entrypoint;
        envsubst < terraform/container-definitions/app.json.tpl > /new-container-defs.json;
        NEW_TASK_DEFINITION="$(aws ecs register-task-definition \
          --family "$TASK_DEFINITION_FAMILY" \
          --container-definitions file:///new-container-defs.json \
          --task-role-arn "$TASK_ROLE_ARN" \
          --execution-role-arn "$EXECUTION_ROLE_ARN" \
          --network-mode "awsvpc" \
          --requires-compatibilities "FARGATE" \
          --memory "$TASK_MEMORY" \
          --cpu "$TASK_CPU" \
          )";
        NEW_TASK_DEFINITION_ARN="$(echo "$NEW_TASK_DEFINITION" | jq -r '.taskDefinition.taskDefinitionArn')";
        task_definition_arn="$NEW_TASK_DEFINITION_ARN";
        export task_definition_arn;
        envsubst < terraform/appspecs/ecs.json.tpl > appspec.json;
artifacts:
  files:
    - appspec.json
