
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