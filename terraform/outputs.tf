# ===========================
# Outputs
# ===========================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS Name"
  value       = aws_lb.main.dns_name
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_lb.main.dns_name}"
}

