output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_backend_repository_url" {
  description = "Registry to push the backend image to, e.g. <account_id>.dkr.ecr.eu-central-1.amazonaws.com/nudge-backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_web_repository_url" {
  description = "Registry to push the web image to, e.g. <account_id>.dkr.ecr.eu-central-1.amazonaws.com/nudge-web"
  value       = aws_ecr_repository.web.repository_url
}

output "get_credentials_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
