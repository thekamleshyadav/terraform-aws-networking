resource "aws_vpc" "kamal" {
  count = var.vpc_enabled ? 1 : 0
  tags = {
    Name = "kamal-vpc"
  }
  cidr_block                       = var.cidr_block
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  enable_classiclink               = var.enable_classiclink
  enable_classiclink_dns_support   = var.enable_classiclink_dns_support
  ipv4_ipam_pool_id                = var.ipv4_ipam_pool_id
  ipv4_netmask_length              = var.ipv4_ipam_pool_id != "" ? var.ipv4_netmask_length : null
  assign_generated_ipv6_cidr_block = true
  lifecycle {
    # Ignore tags added by kubernetes
    ignore_changes = [
      tags,
      tags["kubernetes.io"],
      tags["SubnetType"],
    ]
  }
}




###################aws_subnet######################
resource "aws_subnet" "main" {
  count = var.subnet_enable ? 1 : 0
  availability_zone = element(var.availability_zone, count.index)
  vpc_id     =  join("", aws_vpc.kamal.*.id)
  cidr_block = var.subnet_cidr_block

  tags = {
    Name = "kamal-subnet"
  }
}



###################################aws-internet_gateway##########################################
resource "aws_internet_gateway" "my_gw" {
  count = var.enabled_internet_gateway ? 1 : 0
  vpc_id = join("", aws_vpc.kamal.*.id)
  tags = {
    Name = "kamal-int"
  }
}

########################################aws_route_table#################################

resource "aws_route_table" "my_route_table" {
  count = var.enabled_route_table ? 1 : 0
  vpc_id = join("", aws_vpc.kamal.*.id)

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = join("", aws_internet_gateway.my_gw.*.id)
  }
  tags = {
    Name = "kamal-rout"
  }
}

############################################aws_route_table_association############################
resource "aws_route_table_association" "a" {
  subnet_id      = join("", aws_subnet.main.*.id)
  route_table_id = join("", aws_route_table.my_route_table.*.id)
}

###############################aws_network_interface####################################

resource "aws_network_interface" "multi-ip" {
count = var.enabled_interface ? 1 : 0
subnet_id   = join("", aws_subnet.main.*.id)
private_ips = ["10.10.0.10", "10.10.0.11"]
  tags = {
    Name = "kamal-nic"
  }
}

################################aws_eip##########################################

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = join("", aws_network_interface.multi-ip.*.id)
  associate_with_private_ip = "10.10.0.10"
  tags = {
    Name = "kamal-eip"
  }
}

############################aws_nat_gateway################################

resource "aws_nat_gateway" "example" {
  connectivity_type = "private"
  subnet_id         = join("", aws_subnet.main.*.id)
  tags = {
    Name = "kamal-nat-gateway"
  }
}





