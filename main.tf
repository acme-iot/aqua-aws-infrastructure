provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {

  key_public_path = "./keys/master.pub"
  hive_ami        = data.aws_ami.hivemq.id
  name_prefix     = "aqua_"
  subnets         = cidrsubnets(var.vpc_cidr, 8, 8, 8, 8)

  tags = {
    environment = "prod"
  }

}

data "aws_availability_zones" "this" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags       = merge(local.tags, map("Name", "${local.name_prefix}vpc"))
}

resource "aws_subnet" "private" {
  count = length(local.subnets) / 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnets[count.index]
  availability_zone = data.aws_availability_zones.this.names[count.index]
  tags              = merge(local.tags, map("Name", "${local.name_prefix}private_${data.aws_availability_zones.this.names[count.index]}"))
}

resource "aws_subnet" "public" {
  count = length(local.subnets) / 2

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnets[count.index + (length(local.subnets) / 2)]
  availability_zone = data.aws_availability_zones.this.names[count.index]
  tags              = merge(local.tags, map("Name", "${local.name_prefix}public_${data.aws_availability_zones.this.names[count.index]}"))
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, map("Name", "${local.name_prefix}igw"))
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, map("Name", "${local.name_prefix}public"))

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, map("Name", "${local.name_prefix}private"))
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_security_group" "hivemq" {
  name        = "hivemq"
  description = "Allow MQTT inbound traffic"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 1883
    to_port     = 1883
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, map("Name", "${local.name_prefix}hivemq"))

}

resource "aws_key_pair" "this" {
  key_name   = "master_key"
  public_key = file(local.key_public_path)
}

// just provision one
resource "aws_instance" "hivemq" {
  ami           = local.hive_ami
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.hivemq.id]
  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true

  ebs_block_device {
    device_name           = "/dev/xvda"
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = merge(local.tags, map("Name", "${local.name_prefix}hivemq"))

}

/* resource "aws_eip" "hivemq" {
  vpc  = true
  tags = merge(local.tags, map("Name", "${local.name_prefix}hivemq"))

}

resource "aws_eip_association" "hivmq" {
  instance_id   = aws_instance.hivemq.id
  allocation_id = aws_eip.hivemq.id
} */
