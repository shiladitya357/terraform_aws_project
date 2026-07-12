output "public_alb_dns_name" { value = aws_lb.public.dns_name }
output "internal_alb_dns_name" { value = aws_lb.internal.dns_name }
