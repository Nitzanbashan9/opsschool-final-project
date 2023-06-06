resource "aws_db_subnet_group" "elephant" {
  name       = "elephant"
  subnet_ids = [aws_subnet.eks_private_subnet[0].id,aws_subnet.eks_private_subnet[1].id]

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "elephant" {
  identifier           = "finalproject"
  allocated_storage    = 10
  db_name              = "finalproject"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "Aa123456"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.elephant.id
  depends_on = [
    aws_security_group.db_sg
  ]
}