# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for use by an EC2 instance of PRPL to give access to :
#   1) Register DNS record to Route53 for our ec2 host
#   3) PRPL get config files from S3
#   4) Cloudwatch logging and metrics
#   5) Check AutoScalingGroup for number of instances so can delay mounting EFS until no instances using it.
#   6) Send SNS messages for alerting
#   7) Send Update on instance health to the ASG
#   8) Get secret for prpl admin password
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_role" "prpl" {
  name                 = "${var.resource_name_prefix}-prpl"
  max_session_duration = 43200
  assume_role_policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags                 = var.tags
}

# 1) Register DNS record to Route53 for our ec2 host
resource "aws_iam_policy" "route53" {
  name        = "${var.resource_name_prefix}-prpl-route53"
  description = "RegisterDNSwithRoute53"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Route53registerDNS",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:route53:::hostedzone/${var.route53_private_zone_id}"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "route53" {
  role       = aws_iam_role.prpl.name
  policy_arn = aws_iam_policy.route53.arn
}

# 3) PRPL get config files from S3
resource "aws_iam_policy" "prpl-s3" {
  name        = "${var.resource_name_prefix}-prpl-s3"
  description = "Read access to s3 bucket for PRPL config files"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PRPLReadS3",
      "Action": [
        "s3:List*",
        "s3:GetObject*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "prpl-s3" {
  role       = aws_iam_role.prpl.name
  policy_arn = aws_iam_policy.prpl-s3.arn
}

# 4) Cloudwatch logging and metrics - To allow output of metrics and logs to Cloudwatch
resource "aws_iam_role_policy_attachment" "prpl-cloudwatch" {
  role       = aws_iam_role.prpl.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# 5) Check AutoScalingGroup for number of instances so can delay mounting EFS until no instances using it.
resource "aws_iam_role_policy_attachment" "prpl-asg" {
  role       = aws_iam_role.prpl.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingReadOnlyAccess"
}

# 6) Send SNS messages for alerting
resource "aws_iam_policy" "prpl-sns" {
  name        = "${var.resource_name_prefix}-prpl-sns"
  description = "Add ability to send SNS alert message"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
  #      "Resource": "arn::sns:${aws_region}:${account_id}:*"
}
resource "aws_iam_role_policy_attachment" "prpl-sns" {
  role       = aws_iam_role.prpl.name
  policy_arn = aws_iam_policy.prpl-sns.arn
}

# 7) Send Update on instance health to the ASG
resource "aws_iam_policy" "prpl-asg-health" {
  name        = "${var.resource_name_prefix}-prpl-asg-health"
  description = "Send Update on instance health to the ASG"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:SetInstanceHealth"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy_attachment" "prpl-asg-health" {
  role       = aws_iam_role.prpl.name
  policy_arn = aws_iam_policy.prpl-asg-health.arn
}

# 8) Get secret for prpl admin password
resource "aws_iam_policy" "prpl-get-secrets" {
  name        = "${var.resource_name_prefix}-prpl-get-secrets"
  description = "Get secret for prpl admin password"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecretsForPRPL"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_arns
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "prpl-get-secrets" {
  role       = aws_iam_role.prpl.name
  policy_arn = aws_iam_policy.prpl-get-secrets.arn
}

resource "aws_iam_instance_profile" "prpl" {
  name = "prpl"
  role = aws_iam_role.prpl.name
}
