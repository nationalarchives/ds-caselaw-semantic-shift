[
  {
    "image": "${image}",
    "name": "${container_name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${cloudwatch_log_group}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "app"
      }
    },
    "portMappings": [
      {
        "hostPort": ${host_port},
        "protocol": "tcp",
        "containerPort": ${container_port}
      }
    ],
    %{ if environment != "[]" }
    "environment": ${environment},
    %{ endif }
    "linuxParameters": ${linux_parameters},
    "entrypoint": ${entrypoint},
    "command": [],
    "memoryReservation": 16,
    "essential": true
  }
]
