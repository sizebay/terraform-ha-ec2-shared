# Terraform EC2 HA
Zero Downtime and Highly Available deployment infrastructure using Terraform and EC2.

## Basic Usage

### ALB dedicado (primeiro servico cria o shared ALB)
```terraform
module "first-service" {
  source = "git@github.com:sizebay/terraform-ha-ec2.git"

  aws_region               = var.aws_region
  aws_vpc_id               = var.aws_vpc_id
  aws_instances_subnet_ids = data.aws_subnets.private.ids
  aws_lb_subnet_ids        = data.aws_subnets.public.ids
  aws_hosted_domain        = var.aws_hosted_domain
  dns_entry                = "my-service"
  environment              = "production"

  iam_statement_polices = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["*"]
    }
  ]
}
```

### Usando ALB shared existente
Quando o ALB `shared-alb-{environment}` ja foi criado por outro servico, use `aws_use_shared_alb = true`.
O modulo busca o ALB e seus listeners automaticamente via data source e cria listener rules com host-based routing.

```terraform
module "second-service" {
  source = "git@github.com:sizebay/terraform-ha-ec2.git"

  aws_region               = var.aws_region
  aws_vpc_id               = var.aws_vpc_id
  aws_instances_subnet_ids = data.aws_subnets.private.ids
  aws_hosted_domain        = var.aws_hosted_domain
  dns_entry                = "other-service"
  environment              = "production"
  aws_use_shared_alb       = true

  iam_statement_polices = [
    {
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["*"]
    }
  ]
}
```

> **Nota:** `aws_lb_subnet_ids` nao e necessario quando `aws_use_shared_alb = true`.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws\_region | AWS region in which the artifact will be deployed to. | string | n/a | yes |
| aws\_vpc\_id | AWS VPC ID in which your services will be deployed to. | string | n/a | yes |
| aws\_instances\_subnet\_ids | AWS Subnet IDs in which your instances will be placed on. | list(string) | n/a | yes |
| aws\_hosted\_domain | AWS Route 53 hosted zone domain. e.g. my.domain.com | string | n/a | yes |
| dns\_entry | The Register A DNS entry that will be created for your service. | string | n/a | yes |
| iam\_statement\_polices | Set new statement polices array. | any | n/a | yes |
| aws\_use\_shared\_alb | Quando true, usa o ALB shared existente (shared-alb-{environment}) com listener rules. | bool | `false` | no |
| aws\_lb\_subnet\_ids | AWS Subnet IDs for the load balancer. Not required when aws\_use\_shared\_alb is true. | list(string) | `[]` | no |
| aws\_lb\_is\_internal | Defines whether the ALB is internal or not. | bool | `false` | no |
| aws\_lb\_enable\_https | Habilita listener HTTPS com certificado TLS no ALB. | bool | `true` | no |
| dns\_private\_zone | Define se a zona Route53 e privada ou publica. | bool | `false` | no |
| aws\_shared\_alb\_name | Nome customizado do ALB shared. Se vazio, usa nome padrao. | string | `""` | no |
| aws\_lb\_health\_check\_url | URL ALB should probe to ensure the instances are healthy. | string | `"/health-check"` | no |
| aws\_lb\_health\_check\_type | Define how AWS should check if instances are healthy or not. | string | `"ELB"` | no |
| aws\_lb\_health\_check\_grace\_period | Grace period before the instance being checked. | string | `"30"` | no |
| aws\_lb\_deregistration\_delay | Draining phase delay for graceful shutdown. | string | `"60"` | no |
| aws\_lb\_enable\_stickiness | Defines ALB should be routed to the same target. | bool | `false` | no |
| aws\_lb\_cookie\_duration | The time period in seconds for stickiness cookie. | number | `60` | no |
| aws\_instance\_type | AWS EC2 instance type. | string | `"t3.medium"` | no |
| aws\_instance\_web\_port | Port mapped from the ALB to target instance. | string | `"8080"` | no |
| aws\_instance\_web\_protocol | Protocol mapped from the ALB to target instance. | string | `"HTTP"` | no |
| aws\_deployment\_config | AWS CodeDeploy deployment config. | string | `"CodeDeployDefault.OneAtATime"` | no |
| aws\_deployment\_group | AWS CodeDeploy deployment group. | string | `"default"` | no |
| aws\_asg\_instances\_desired | Desired number of instances on the ASG. | string | `"2"` | no |
| aws\_asg\_instances\_min | Minimum number of instances on the ASG. | string | `"2"` | no |
| aws\_asg\_instances\_max | Maximum number of instances on the ASG. | string | `"3"` | no |
| environment | An environment deployment identifier. | string | `""` | no |
| name | Optional name used as suffix for AWS resources. | string | `""` | no |
| config\_prefix | Optional prefix for SSM Parameter Store. | string | `""` | no |
| custom\_script | Custom script path run on instance startup. | string | `""` | no |
| ssh\_public\_key\_ssm\_name | SSM Parameter name containing the SSH public key. | string | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| aws\_asg\_arn | The Auto Scaling Group ARN |
| aws\_iam\_role\_arn | The IAM Role ARN |
| aws\_iam\_role\_name | The IAM Role Name |
| aws\_route53\_record | The Route53 record name |
| aws\_alb\_listener\_https | The HTTPS listener ARN (created or shared) |
| aws\_alb\_arn | The ALB ARN in use (created or shared) |
| aws\_alb\_dns\_name | The ALB DNS name in use (created or shared) |
