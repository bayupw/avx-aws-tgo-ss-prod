# ---------------------------------------------------------------------------------------------------------------------
# prd banking 1 ec2
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "prd_spoke1_instance_sg" {
  count       = var.create_ec2 ? 1 : 0
  name        = "prd-spoke1/sg-instance"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = module.prd_banking_vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.ingress_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "prd-spoke1/sg-instance"
  }
}

resource "aws_instance" "prd_spoke1_instance" {
  count                       = var.create_ec2 ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  key_name                    = var.key_name == null ? aws_key_pair.instance_key_pair[0].key_name : var.key_name
  subnet_id                   = module.prd_banking_vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.prd_spoke1_instance_sg[0].id]
  associate_public_ip_address = true

  tags = {
    Name = "prd-spoke1-instance"
  }
}


# ---------------------------------------------------------------------------------------------------------------------
# prd spoke 2 ec2
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "prd_it_service_instance_sg" {
  count       = var.create_ec2 ? 1 : 0
  name        = "prd-it-service/sg-instance"
  description = "Allow all traffic from VPCs inbound and all outbound"
  vpc_id      = module.prd_it_service.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.ingress_cidr_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "prd-it-service/sg-instance"
  }
}

resource "aws_instance" "prd_it_service_instance" {
  count                       = var.create_ec2 ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  key_name                    = var.key_name == null ? aws_key_pair.instance_key_pair[0].key_name : var.key_name
  subnet_id                   = module.prd_it_service.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.prd_it_service_instance_sg[0].id]
  associate_public_ip_address = true

  tags = {
    Name = "prd-it-service-instance"
  }
}