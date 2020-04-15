resource "aws_security_group" "instance" {
        name = var.security_group_instance_name
        description = "Security group for grafana and influx instance"
  	egress {
    		from_port   = 0
    		to_port     = 0
    		protocol    = "-1"
    		cidr_blocks = ["0.0.0.0/0"]
  	}
  	ingress {
    		from_port   = 22
    		to_port     = 22
    		protocol    = "tcp"
    		cidr_blocks = ["0.0.0.0/0"]
  	}	
}

resource "aws_security_group_rule" "grafana" {
	type = "ingress"
	from_port = var.server_port
	to_port = var.server_port
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
	security_group_id = aws_security_group.instance.id
}
resource "aws_security_group_rule" "influxdb" {
	type = "ingress"
	from_port = 8086
	to_port = 8086
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
	security_group_id = aws_security_group.instance.id
}

