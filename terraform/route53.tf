resource "aws_route53_zone" "elephant_private_hosted_zone" {
  name = "elephant.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }
}
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.elephant_private_hosted_zone.zone_id
  name    = "elephant-db.elephant.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_db_instance.elephant.address]
}
resource "aws_route53_record" "elk" {
  zone_id = aws_route53_zone.elephant_private_hosted_zone.zone_id
  name    = "elasticsearch.elephant.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_instance.elk.address]
}
