#ECR
resource "aws_ecr_repository" "tf_govuk_fe_wtf_demo_ecr_repo" {
  name = "tf_govuk_fe_wtf_demo_ecr_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecr_lifecycle_policy" "tf_private_ecr_life_pol" {
  repository = aws_ecr_repository.tf_govuk_fe_wtf_demo_ecr_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# data "aws_iam_user" "user" {
#   user_name = "adeolu"
# }


#ECS Cluster
resource "aws_ecs_cluster" "tf_ecs_cluster" {
  name = "tf_ecs_cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging    = "NONE"

      
      # logging    = "OVERRIDE"

      # log_configuration {
      #   cloud_watch_encryption_enabled = true
      #   cloud_watch_log_group_name     = aws_cloudwatch_log_group.tf_cloud_watch.name
      # }
    }
  }
}

#Task Definition
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "tf_task_def" {
  family                   = "tf_task_def"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name      = "govuk-fe-wtf-demo"
      image     = "637423624556.dkr.ecr.us-west-1.amazonaws.com/tf_govuk_fe_wtf_demo_ecr_repo:latest"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

}


#ECS Service
resource "aws_ecs_service" "tf_govuk_service" {
  name            = "tf_govuk_service"
  cluster         = aws_ecs_cluster.tf_ecs_cluster.id
  task_definition = aws_ecs_task_definition.tf_task_def.arn
  launch_type = "FARGATE"
  platform_version = "LATEST"
  desired_count   = 2
  network_configuration {
    security_groups    = [aws_security_group.tf_sg_main.id]
    subnets = [aws_subnet.tf_subnet_main.id, aws_subnet.tf_subnet_secondary.id]
    assign_public_ip = true
}

  load_balancer {
    target_group_arn = aws_lb_target_group.tf_tg_main.arn
    container_name   = "govuk-fe-wtf-demo"
    container_port   = 80
  }
}