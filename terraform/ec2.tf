#INSTANCES
resource "aws_instance" "Jenkins_Master" {
  root_block_device {
    volume_size           = "50"
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = false
  }
  availability_zone = "us-east-1a"
  ami           = "ami-00ccf49481882aefc"
  instance_type = "t3.micro"
  associate_public_ip_address = true
  subnet_id   = aws_subnet.public_subnet[0].id
  security_groups = [aws_security_group.jenkins-sg.id]
  key_name = "jenkins_ec2_key"

  lifecycle {
   ignore_changes = all
  }

  tags = {
    Name = "Jenkins_Master"
    Environment = "final project"
  }
}

resource "aws_instance" "Jenkins_Slave" {
  root_block_device {
    volume_size           = "10"
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = false
  }
  availability_zone = "us-east-1a"
  ami           = "ami-098fa70e5cb70c1db"
  instance_type = "t3.micro"
  count = 2
  subnet_id   = aws_subnet.public_subnet[0].id
  security_groups = [aws_security_group.jenkins-sg.id]
  key_name = "jenkins_ec2_key"

  lifecycle {
   ignore_changes = all
  }

  tags = {
    Name = "Jenkins_Slave_${count.index}"
    Environment = "final project"
  }
}

resource "aws_instance" "elk" {
  root_block_device {
    volume_size           = "50"
    volume_type           = "gp2"
    encrypted             = false
    delete_on_termination = false
  }
  ami           = "ami-0c8d8fdd6dd249869"
  instance_type = "t3.large"
  subnet_id   = aws_subnet.eks_private_subnet[0].id
  security_groups = [aws_security_group.elk-sg.id]
  key_name = "jenkins_ec2_key"

  lifecycle {
   ignore_changes = all
  }

  tags = {
    Name = "elk"
    Environment = "final project"
  }
}