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

