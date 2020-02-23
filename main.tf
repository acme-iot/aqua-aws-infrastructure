provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {

  hive_ami = data.aws_ami.hivemq.id

  name_prefix = "aqua_"

  tags = {
    environment = "prod"
  }

  subnets = cidrsubnets(var.vpc_cidr, 8, 8, 8, 8)

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
