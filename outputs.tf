output "aws_lb_name" {
  description = "The unique name of the theone.com load balancer"
  value       = aws_lb.main.name
}

