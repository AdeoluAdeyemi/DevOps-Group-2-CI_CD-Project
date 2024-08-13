variable "aws_cidr_blocks" {
  description = "value"
  type = object({
    vpc = string,
    subnet_main = string,
    subnet_secondary = string,
    route_table = string,
    ipv4_ingress = string,
    ipv4_egress = string
  })
}

# variable "aws_subnet_cidr_blocks" {
#   description = "value"
#   type = string
# }

variable "aws_availability_zones" {
  description = "value"
  type = list(string)
}

variable "port" {
  description = "value"
  type = number
}
