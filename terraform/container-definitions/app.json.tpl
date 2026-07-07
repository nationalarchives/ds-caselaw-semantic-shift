[
  {
    "image": "${image}",
    "name": "${container_name}",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${cloudwatch_log_group}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${awslogs_stream_prefix}"
      }
    },
    "portMappings": [
      {
        "hostPort": ${host_port},
        "protocol": "tcp",
        "containerPort": ${container_port}
      }
    ],
    "environment": ${environment},
    "linuxParameters": ${linux_parameters},
    "entrypoint": ${entrypoint},
    "command": [],
    "memoryReservation": 16,
    "essential": true
  }
]
