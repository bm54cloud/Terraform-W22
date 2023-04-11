#Create custom VPC
resource "aws_vpc" "vpc-tf" {
  cidr_block           = var.vpc-cidr
  instance_tenancy     = var.tenancy
  enable_dns_hostnames = var.true
  enable_dns_support   = var.true

  tags = {
    Name = "terraform-vpc"
  }
}

#Obtain availability zones
data "aws_availability_zones" "available-azs" {
  state = "available"
}

#Create 2 public subnets for webserver tier
resource "aws_subnet" "public-subnets-tf" {
  for_each                = var.public-subnets
  vpc_id                  = aws_vpc.vpc-tf.id
  cidr_block              = cidrsubnet(var.vpc-cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available-azs.names)[each.value - 1]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-subnet-public-${each.key}"
    Tier = "public"
  }
}

#Create 2 private subnets for RDS MySQL tier
resource "aws_subnet" "private-subnets-tf" {
  for_each                = var.private-subnets
  vpc_id                  = aws_vpc.vpc-tf.id
  cidr_block              = cidrsubnet(var.vpc-cidr, 8, each.value)
  availability_zone       = tolist(data.aws_availability_zones.available-azs.names)[each.value - 1]
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-subnet-private-${each.key}"
    Tier = "private"
  }
}

#Create route table for public subnets
resource "aws_route_table" "public-rtb" {
  vpc_id = aws_vpc.vpc-tf.id

  route {
    cidr_block = var.cidr
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "terraform_public_rtb"
    Tier = "public"
  }
}

#Create route table for private subnets 
resource "aws_route_table" "private-rtb" {
  vpc_id = aws_vpc.vpc-tf.id

  route {
    cidr_block     = var.cidr
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }
  tags = {
    Name = "terraform-private-rtb"
    Tier = "private"
  }
}

#Create public route table associations
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public-subnets-tf]
  route_table_id = aws_route_table.public-rtb.id
  for_each       = aws_subnet.public-subnets-tf
  subnet_id      = each.value.id
}

#Create private route table associations
resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private-subnets-tf]
  route_table_id = aws_route_table.private-rtb.id
  for_each       = aws_subnet.private-subnets-tf
  subnet_id      = each.value.id
}

#Create Internet Gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc-tf.id
  tags = {
    Name = "terraform-igw"
  }
}

#Create EIP for NAT Gateway
resource "aws_eip" "nat-gateway-eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.internet-gateway]
  tags = {
    Name = "terraform-nat-gw-eip"
  }
}

#Create NAT Gateway
resource "aws_nat_gateway" "nat-gateway" {
  depends_on    = [aws_subnet.public-subnets-tf]
  allocation_id = aws_eip.nat-gateway-eip.id
  subnet_id     = aws_subnet.public-subnets-tf["public-subnet-1"].id
  tags = {
    Name = "terraform-nat-gw"
  }
}

# #Create EC2 instance with bootstrap Apache in each public subnet
# resource "aws_instance" "web-server" {
#   ami           = var.ami
#   instance_type = var.instance_type
#   key_name      = var.key_name
#   depends_on     = [aws_subnet.private-subnets-tf]
#   for_each                = var.public-subnets
#   availability_zone       = tolist(data.aws_availability_zones.available-azs.names)[each.value - 1]
#   vpc_security_group_ids = [aws_security_group.terraform-sg.id]
#   user_data                   = file("apache-install.sh")
#   user_data_replace_on_change = true
#   associate_public_ip_address = true

#   tags = {
#     Name        = "web-server"
#     Environment = "dev"
#   }
# }

#Create a security group that allows traffic from the internet 
resource "aws_security_group" "terraform-web-tier-sg" {
  name   = "terraform-sg-web"
  vpc_id = aws_vpc.vpc-tf.id

  ingress {
    description = "Allow all SSH"
    from_port   = var.SSH
    to_port     = var.SSH
    protocol    = var.tcp
    cidr_blocks = [var.cidr]
  }

  ingress {
    description = "Allow all HTTP"
    from_port   = var.HTTP
    to_port     = var.HTTP
    protocol    = var.tcp
    cidr_blocks = [var.cidr]
  }

  ingress {
    description = "Allow all HTTPS"
    from_port   = var.HTTPS
    to_port     = var.HTTPS
    protocol    = var.tcp
    cidr_blocks = [var.cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = var.egress-all
    to_port     = var.egress-all
    protocol    = var.egress
    cidr_blocks = [var.cidr]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Terraform SG"
  }
}



#Deploy infrastructure using Terraform Cloud


#Push code to GitHub


#Obtain public subnets created in VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc-tf.id]
  }

  tags = {
    Tier = "public"
  }
}

#Obtain private subnets created in VPC
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc-tf.id]
  }

  tags = {
    Tier = "private"
  }
}

#Launch an EC2 instance with bootstrapped Apache in each public subnet
resource "aws_instance" "web-server" {
  for_each                    = toset(data.aws_subnets.public.ids)
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = each.value
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.terraform-web-tier-sg.id]
  user_data                   = file("apache-install.sh")
  user_data_replace_on_change = true
  associate_public_ip_address = true

  tags = {
    Name        = "web-server"
    Environment = "dev"
  }
}

resource "aws_kms_key" "secret-key" {
  description = "DB secret key"
}

# resource "random_password" "db-password" {
#   length = 16
#   special = true
#   override_special = "_****"
# }

#Launch one RDS MySQL instance in a private subnet 
resource "aws_db_instance" "mysql" {
  allocated_storage     = 20
  max_allocated_storage = 50
  db_subnet_group_name  = aws_db_subnet_group.rds-mysql-subnet-group.id 
  db_name               = "terraformmysql"
  engine                = "mysql"
  engine_version        = "8.0.32"
  instance_class        = "db.t3.micro"
  port                  = "3306"
  username              = "admin"
  password              = "dbpassword-test"
  # manage_master_user_password = true
  # master_user_secret_kms_key_id = aws_kms_key.secret-key.key_id
  vpc_security_group_ids = [aws_security_group.terraform-data-tier-sg.id]
  availability_zone      = "us-east-2a"
  storage_encrypted      = true
  deletion_protection    = true
  skip_final_snapshot    = true

  tags = {
    name = "terraform-rds-mysql"
  }
}

resource "aws_db_subnet_group" "rds-mysql-subnet-group" {
  name       = "terraform-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private-subnets-tf : subnet.id]

  tags = {
    Name = "terraform-db-subnet-group"
  }
}

# availability_zone       = tolist(data.aws_availability_zones.available-azs.names)[each.value - 1]

#Create security group for database tier from the web-server tier
resource "aws_security_group" "terraform-data-tier-sg" {
  name   = "terraform-sg-data"
  vpc_id = aws_vpc.vpc-tf.id

  ingress {
    description     = "Allow mySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = var.tcp
    security_groups = [aws_security_group.terraform-web-tier-sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = var.egress-all
    to_port     = var.egress-all
    protocol    = var.egress
    cidr_blocks = [var.cidr]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "Terraform DB SG"
  }
}





# #Create ALB security group with permissions to web server SG
# resource "aws_security_group" "alb-sg" {
#   name = "terraform-alb-sg"

#   ingress {
#     description = "Allow all HTTP"
#     from_port   = var.HTTP
#     to_port     = var.HTTP
#     protocol    = var.tcp
#     cidr_blocks = [var.cidr]
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = var.egress-all
#     to_port     = var.egress-all
#     protocol    = var.egress
#     cidr_blocks = [var.cidr]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "Terraform ALB SG"
#   }
# }

# #Create internet-facing ALB targeting web servers
# resource "aws_lb" "web-server-alb" {
#   name               = "terraform-web-server-alb"
#   load_balancer_type = "application"
#   subnets            = data.aws_subnets.public.ids
#   security_groups    = [aws_security_group.alb-sg.id]
# }

# #Create ALB listener on port 80 with protocol HTTP
# resource "aws_lb_listener" "web-server-alb" {
#   load_balancer_arn = aws_lb.web-server-alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.web-server-alb.arn
#   }
# }

# #Create ALB target group
# resource "aws_lb_target_group" "web-server-alb" {
#   name     = "terraform-alb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.vpc-tf.id
# }

# #Create ALB listener rules
# resource "aws_lb_listener_rule" "alb-lg" {
#   listener_arn = aws_lb_listener.http.arn
#   priority     = 100

#   condition {
#     path_pattern {
#       values = ["*"]
#     }
#   }
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web-server-instances.arn
#   }
# }