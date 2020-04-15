data "template_file" "user_data" {
	template = file("user_data.sh")

	vars = {
	  device_name = var.ebs_device_name
        }
}

