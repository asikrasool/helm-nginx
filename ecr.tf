
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my-ecr-repo"

#   image_scanning_configuration {
#     scan_on_push = true
#   }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# This assumes you have the Docker CLI installed on your machine

# Use local-exec provisioner to execute AWS CLI commands
resource "null_resource" "push_nginx_image" {
  triggers = {
    ecr_repo_url = aws_ecr_repository.my_ecr_repo.repository_url
  }

  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password | docker login --username AWS --password-stdin ${aws_ecr_repository.my_ecr_repo.repository_url}
      docker pull nginx:1.14.2
      docker tag nginx:1.14.2 ${aws_ecr_repository.my_ecr_repo.repository_url}:1.14.2
      docker push ${aws_ecr_repository.my_ecr_repo.repository_url}:1.14.2

    EOT
  }
}
