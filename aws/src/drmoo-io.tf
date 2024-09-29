resource "aws_route53_zone" "drmoo_io" {
  name    = "drmoo.io"
  comment = "HostedZone managed by Terraform from the ProfMoo/home repo"
}

resource "aws_route53_record" "drmoo_io_ns" {
  zone_id = aws_route53_zone.drmoo_io.zone_id
  name    = "drmoo.io"
  type    = "NS"
  ttl     = 172800

  records = [
    "camilo.ns.cloudflare.com",
    "gloria.ns.cloudflare.com"
  ]
}
