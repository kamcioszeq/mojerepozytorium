data "template_file" "user_data" {
	template = file("user_data.sh")

	vars = {
	  ebs_volume_name = var.ebs_device_name
        }
}

