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