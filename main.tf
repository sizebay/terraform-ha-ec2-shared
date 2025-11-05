# Output variables
output "aws_asg_arn" {
  value = aws_autoscaling_group.default.arn
}

output "aws_iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "aws_iam_role_name" {
  value = aws_iam_role.default.name
}

output "aws_route53_record" {
  value = aws_route53_record.default.name
}

output "aws_alb_listener_https" {
  value = length(aws_alb_listener.https) > 0 ? aws_alb_listener.https[0].arn : null
}
