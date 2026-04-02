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
  value = length(aws_route53_record.default) > 0 ? aws_route53_record.default[0].name : null
}

output "aws_alb_listener_https" {
  value = local.create_alb ? (
    length(aws_alb_listener.https) > 0 ? aws_alb_listener.https[0].arn : null
    ) : (
    length(data.aws_lb_listener.shared_https) > 0 ? data.aws_lb_listener.shared_https[0].arn : null
  )
}

output "aws_alb_arn" {
  description = "ARN of the ALB in use (created or shared)"
  value = local.create_alb ? (
    length(aws_alb.default) > 0 ? aws_alb.default[0].arn : null
    ) : (
    data.aws_lb.shared[0].arn
  )
}

output "aws_alb_dns_name" {
  description = "DNS name of the ALB in use (created or shared)"
  value       = local.alb_dns_name
}
