{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3vectors:QueryVectors"
      ],
      "Resource": "${index_arn}"
    }
  ]
}
