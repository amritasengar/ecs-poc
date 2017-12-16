# set up the aws provider to work with our credentials in the London region
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

# create the main VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "172.24.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "myorg-vpc"
  }
}

# create a private DNS zone for naming things inside
resource "aws_route53_zone" "myorg_local" {
  name   = "myorg.local."
  vpc_id = "${aws_vpc.vpc.id}"
}

# make the internet visible
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.vpc.id}"
}

# make a route to the internet via the gateway
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# create public and private subnets
resource "aws_subnet" "private_subnet_eu_west_2a" {
  availability_zone = "eu-west-2a"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "172.24.0.0/24"

  tags = {
    Name = "private-subnet-eu-west-2a"
  }
}

resource "aws_subnet" "private_subnet_eu_west_2b" {
  availability_zone = "eu-west-2b"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "172.24.1.0/24"

  tags = {
    Name = "private-subnet-eu-west-2a"
  }
}

resource "aws_subnet" "public_subnet_eu_west_2a" {
  availability_zone = "eu-west-2a"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "172.24.2.0/24"

  tags = {
    Name = "public-subnet-eu-west-2a"
  }
}

resource "aws_subnet" "public_subnet_eu_west_2b" {
  availability_zone = "eu-west-2b"
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "172.24.3.0/24"

  tags = {
    Name = "public-subnet-eu-west-2b"
  }
}

# create a NAT in a public subnet and attach an EIP
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.default"]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${aws_subnet.public_subnet_eu_west_2a.id}"
  depends_on    = ["aws_internet_gateway.default"]
}

# create a route table for the private subnets
resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "Private route table"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = "${aws_route_table.private_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.id}"
}

# Associate public subnets to the main route table
resource "aws_route_table_association" "public_eu_west_2a_association" {
  subnet_id      = "${aws_subnet.public_subnet_eu_west_2a.id}"
  route_table_id = "${aws_vpc.vpc.main_route_table_id}"
}

resource "aws_route_table_association" "public_eu_west_2b_association" {
  subnet_id      = "${aws_subnet.public_subnet_eu_west_2b.id}"
  route_table_id = "${aws_vpc.vpc.main_route_table_id}"
}

# Associate private subnets to private route table
resource "aws_route_table_association" "private_eu_west_2a_association" {
  subnet_id      = "${aws_subnet.private_subnet_eu_west_2a.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}

resource "aws_route_table_association" "private_eu_west_2b_association" {
  subnet_id      = "${aws_subnet.private_subnet_eu_west_2b.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}
