output "lb_endpoint" {
  value = "http://${aws_lb.asg_ec2_instance.dns_name}"
}


output "asg_name" {
  value = aws_autoscaling_group.autoscaling_group.name
}