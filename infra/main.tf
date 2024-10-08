terraform {
  backend "s3" {
    bucket = "govuk-fe-demo-terraform-state-backend"
    key = "terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "terraform_state"
  }
}


provider "aws" {
  region = var.aws_region
}


#VPC
resource "aws_vpc" "tf_vpc_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "tf_vpc_main"
  }
}


#Subnets
resource "aws_subnet" "tf_subnet_main" {
  vpc_id     = aws_vpc.tf_vpc_main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_subnet_main"
  }
}

resource "aws_subnet" "tf_subnet_secondary" {
  vpc_id     = aws_vpc.tf_vpc_main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_subnet_secondary"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "tf_gw" {
  vpc_id = aws_vpc.tf_vpc_main.id

  tags = {
    Name = "tf_gw"
  }
}

# Routing Table
resource "aws_route_table" "tf_route_tb" {
  vpc_id = aws_vpc.tf_vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_gw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = {
    Name = "tf_route_tb"
  }
}

# Routing Table Assoc
resource "aws_route_table_association" "tf_rta" {
  subnet_id      = aws_subnet.tf_subnet_main.id
  route_table_id = aws_route_table.tf_route_tb.id
}


resource "aws_route_table_association" "tf_rtb" {
  subnet_id      = aws_subnet.tf_subnet_secondary.id
  route_table_id = aws_route_table.tf_route_tb.id
}



# Security Group
resource "aws_security_group" "tf_sg_main" {
  name        = "tf_sg_main"
  description = "Allow HTTP/HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.tf_vpc_main.id
  lifecycle {
    create_before_destroy = true
    # Reference the security group as a whole or individual attributes like `name`
    #replace_triggered_by = [aws_security_group.tf_sg_main]
  }
  tags = {
    Name = "tf_sg_main"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.tf_sg_main.id
  cidr_ipv4         = "0.0.0.0/0" #aws_vpc.tf_vpc_main.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

# resource "aws_vpc_security_group_ingress_rule" "https" {
#   security_group_id = aws_security_group.tf_sg_main.id
#   cidr_ipv4         = aws_vpc.tf_vpc_main.cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tf_sg_main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#VPC -  Security Group
# module "vpc" {
#   source = "./modules/vpc"
#   aws_cidr_blocks = var.aws_cidr_blocks
#   #aws_subnet_cidr_blocks = var.aws_subnet_cidr_blocks
#   aws_availability_zones = var.aws_availability_zones
# }

#ALB
resource "aws_lb" "tf_lb_test" {
  name               = "tf-lb-test"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_sg_main.id]
  subnets = [aws_subnet.tf_subnet_main.id, aws_subnet.tf_subnet_secondary.id]
  #subnets            = [for subnet in aws_subnet.tf_subnet_main : subnet.id]


  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "dev"
  }
}

#Target Group
resource "aws_lb_target_group" "tf_tg_main" {
  name     = "tf-tg-main"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.tf_vpc_main.id
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.tf_lb_test.arn
  port              = 80
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_tg_main.arn
  }
}

#ECR
resource "aws_ecr_repository" "tf_govuk_fe_wtf_demo_ecr_repo" {
  name = var.aws_ecr_repo_name
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

data "aws_ecr_repository" "repo_details" {
  name = aws_ecr_repository.tf_govuk_fe_wtf_demo_ecr_repo.name
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
      image     = "${data.aws_ecr_repository.repo_details.repository_url}:latest"
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
  force_delete = true
  
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

# module "ecr-ecs" {
#   source = "./modules/ecr-ecs"
# }