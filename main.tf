# ---------------------------------------------------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.2"
    }
    aviatrix = {
      source  = "AviatrixSystems/aviatrix"
      version = "2.19.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Private Key & EC2 Key Pair
# ---------------------------------------------------------------------------------------------------------------------

resource "tls_private_key" "ss_key" {
  count = var.key_name == null ? 1 : 0
  algorithm = "RSA"
}

resource "local_file" "private_key" {
  count = var.key_name == null ? 1 : 0  
  content         = tls_private_key.ss_key[0].private_key_pem
  filename        = "ss-key.pem"
  file_permission = "0600"
}

resource "aws_key_pair" "instance_key_pair" {
  count      = var.key_name == null ? 1 : 0
  key_name   = "ss-key"
  public_key = tls_private_key.ss_key.public_key_openssh

  lifecycle {
    ignore_changes = [tags]
  }
}