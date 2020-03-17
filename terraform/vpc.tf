#Create a VPC 
resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = map(
    "Name", "${var.cluster-name}-node",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

#Create 2 subnets and add tag so they can be discovered
resource "aws_subnet" "test-subnet" {
  count = 2

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.test-vpc.id

  tags = map(
    "Name", "${var.cluster-name}-node",
    "kubernetes.io/cluster/${var.cluster-name}", "shared",
  )
}

#Create IG to allow internet access
resource "aws_internet_gateway" "test-ig" {
  vpc_id = aws_vpc.test-vpc.id

  tags = {
    Name = "${var.cluster-name}"
  }
}

#Create route table to connect subnet traffic to IG
resource "aws_route_table" "test-rt" {
  vpc_id = aws_vpc.test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-ig.id
  }
}

resource "aws_route_table_association" "test-rta" {
  count = 2

  subnet_id      = aws_subnet.test-subnet.*.id[count.index]
  route_table_id = aws_route_table.test-rt.id
}