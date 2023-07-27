data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "maintenance" {
  count                  = var.maintenance_mode ? 1 : 0
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.0.id
  vpc_security_group_ids = [aws_security_group.web-ecs.id, aws_security_group.maintenance[count.index].id]
  key_name               = aws_key_pair.maintenance[count.index].key_name
  root_block_device {
    encrypted   = true
    kms_key_id  = var.kms ? aws_kms_key.ashirt[count.index].arn : null
    volume_size = 50
  }

  associate_public_ip_address = true
  tags = {
    Name = "${var.app_name}-maintenance"
  }
}

resource "tls_private_key" "maintenance" {
  count     = var.maintenance_mode ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "maintenance" {
  count      = var.maintenance_mode ? 1 : 0
  key_name   = "${var.app_name}-maintenance" # Create "myKey" to AWS!!
  public_key = tls_private_key.maintenance[count.index].public_key_openssh
  provisioner "local-exec" {
    command = "echo '${tls_private_key.maintenance[count.index].private_key_pem}' > ./maintenance-${var.app_name}.pem; chmod 400 maintenance.pem"
  }
}

resource "aws_security_group" "maintenance" {
  count       = var.maintenance_mode ? 1 : 0
  name        = "maintenance-ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.ashirt.id
  tags = {
    Name = "ashirt-maintenance-ssh"
  }
}

resource "aws_security_group_rule" "allow-egress-maintenance" {
  count             = var.maintenance_mode ? 1 : 0
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  security_group_id = aws_security_group.maintenance[count.index].id
}

resource "aws_security_group_rule" "allow-ingress-maintenance" {
  count             = var.maintenance_mode ? 1 : 0
  type              = "ingress"
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = var.allow_maintenance_cidrs
  from_port         = 22
  security_group_id = aws_security_group.maintenance[count.index].id
}

output "maintenance_ssh" {
  value = var.maintenance_mode ? "ssh -fN -i maintenance-${var.app_name}.pem -L 127.0.0.1:3306:${aws_rds_cluster.ashirt.endpoint}:3306 ubuntu@${aws_instance.maintenance.0.public_ip}" : null
}
