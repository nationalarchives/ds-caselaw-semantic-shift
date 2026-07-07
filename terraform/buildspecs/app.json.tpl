version: 0.2

phases:
  pre_build:
    commands:
      - echo Build started on `date`
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin "${aws_account_id}.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
  build:
    commands:
      - echo Building the Docker image...
      - cd app-folder
      - docker build -t ${image_repo_name}:test .
      - cd ..
      - IMAGE_TAG=commit-$CODEBUILD_RESOLVED_SOURCE_VERSION
      - echo Tagging the successfully tested image as latest...
      - docker tag ${image_repo_name}:test ${repository_url}:latest
      - docker tag ${image_repo_name}:test ${repository_url}:$IMAGE_TAG
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
        image="${repository_url}:$IMAGE_TAG";
        cloudwatch_log_group="${cloudwatch_log_group}";
        region="$AWS_DEFAULT_REGION";
        awslogs_stream_prefix="${awslogs_stream_prefix}";
        host_port="$APP_PORT";
        container_port="$APP_PORT";
        environment='${environment_json}';
        linux_parameters='${linux_parameters_json}';
        entrypoint='${app_entrypoint_json}';
        export container_name image cloudwatch_log_group region awslogs_stream_prefix host_port container_port environment linux_parameters entrypoint;
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
        container_name="${container_name}";
        container_port="${app_container_port}";
        task_definition_arn="$NEW_TASK_DEFINITION_ARN";
        export container_name container_port task_definition_arn;
        envsubst < terraform/appspecs/ecs.json.tpl > appspec.json;
artifacts:
  files:
    - appspec.json
