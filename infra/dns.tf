resource "aws_route53_zone" "app_dns" {
    name = "${local.dns}"
}
