# iam-prpl

Terraform module for creating IAM Role and Profile for attaching to PRPL EC2 instances to give access to :

1) Register DNS record to Route53 for our ec2 host
3) PRPL get config files from S3
4) Cloudwatch logging and metrics
5) Check AutoScalingGroup for number of instances so can delay mounting EFS until no instances using it.
6) Send SNS messages for alerting
7) Send Update on instance health to the ASG
8) Get secret for prpl admin password
