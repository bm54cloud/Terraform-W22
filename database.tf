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

resource "aws_kms_key" "secret-key" {
  description = "DB secret key"
}

resource "random_password" "db-password" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
  keepers = {
    pass_version = 1
  }
}

#Launch one RDS MySQL instance in a private subnet 
resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  max_allocated_storage  = 50
  db_subnet_group_name   = aws_db_subnet_group.rds-mysql-subnet-group.id
  db_name                = "terraformmysql"
  engine                 = "mysql"
  engine_version         = "8.0.32"
  instance_class         = "db.t3.micro"
  port                   = "3306"
  username               = "admin"
  password               = random_password.db-password.result
  vpc_security_group_ids = [aws_security_group.terraform-data-tier-sg.id]
  availability_zone      = "us-east-2a"
  storage_encrypted      = true
  deletion_protection    = false
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