provider "aws" {
	region = var.aws_region
}

data "aws_availability_zones" "all" {}

resource "aws_launch_configuration" "asg-grafana-influxdb" {
	image_id = var.ami_id
	instance_type = var.instance_type
	security_groups = [aws_security_group.instance.id]
	user_data = data.template_file.user_data.rendered

	lifecycle {
		create_before_destroy = true
	}

	root_block_device {
		volume_size = var.ebs_volume_system_size
		delete_on_termination = var.delete_on_termination
	}
	ebs_block_device {
		device_name = var.ebs_device_name
		volume_size = var.ebs_volume_data_size
		delete_on_termination = false
	}	
}	

resource "aws_security_group" "elb-sg" {
	name = "grafana-elb-sg"
	#allow all outbound
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress {
		from_port = var.elb_port
		to_port = var.elb_port
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_autoscaling_group" "asg-grafana" {
	launch_configuration = aws_launch_configuration.asg-grafana-influxdb.id
	availability_zones = data.aws_availability_zones.all.names
	min_size = 1
	max_size = 1
	
	load_balancers = [aws_elb.grafana-elb.name]
	health_check_type = "ELB"
}

resource "aws_elb" "grafana-elb" {
	name = "grafana-asg-elb"
	security_groups = [aws_security_group.elb-sg.id]
	availability_zones = data.aws_availability_zones.all.names
	
	health_check {
		target = "TCP:${var.server_port}"
		interval = 150
		timeout = 10
		healthy_threshold = 2
		unhealthy_threshold = 2
	}
	
	listener {
		lb_port = var.server_port
		lb_protocol = "http"
		instance_port = var.server_port
		instance_protocol = "http"
	}
}

output "elb_dns_name" {
	value = aws_elb.grafana-elb.dns_name
}		

