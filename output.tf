# Output values
#
output "prpl-role" {
  value = aws_iam_role.prpl
}
output "prpl-profile" {
  value = aws_iam_instance_profile.prpl
}