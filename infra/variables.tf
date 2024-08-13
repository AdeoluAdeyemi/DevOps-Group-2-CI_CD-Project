variable "aws_region" {
  description = "AWS Region Name"
  type = string
}

variable "aws_vpc_cidr_block" {
  description = "CIDR Blocks Map for infrastructure"
  type = string
}

variable "aws_subnet_main_cidr_block" {
  description = "CIDR Blocks Map for infrastructure"
  type = string
}

variable "aws_subnet_secondary_cidr_block" {
  description = "CIDR Blocks Map for infrastructure"
  type = string
}

variable "aws_route_table_cidr_block" {
  description = "CIDR Blocks Map for infrastructure"
  type = string
}
variable "aws_security_group_ingress_cidr_block" {
  description = "CIDR Blocks Map for infrastructure"
  type = string
}
variable "aws_security_group_egress_cidr_block" {
  description = "CIDR Blocks Map for infrastructure"
  type = string
}

variable "availability_zones" {
  description = "AWS Availability Zones"
  type = list(string)
}

variable "port" {
  description = "Ports for all resources"
  type = number
}

variable "aws_elb_name" {
  description = "AWS Elastic Load Balancer Name"
  type = string
}

variable "aws_elb_target_group_name" {
  description = "AWS ELB Target Group Name"
  type = string
}

variable "aws_ecr_repo_name" {
  description = "AWS ECR Name"
  type = string
}

variable "aws_ecs_cluster_name" {
  description = "AWS ECS Cluster Name"
  type = string
}

variable "aws_ecs_name" {
  description = "AWS ECS Service Name"
  type = string
}

variable "aws_task_def" {
  description = "AWS Task Definition Name"
  type = string
}

variable "aws_ecs_task_df_container_name" {
  description = "AWS ECS Task Definition Container Name"
  type = string
}