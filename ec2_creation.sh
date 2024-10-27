#!/bin/bash
set -euo pipefail

check_awscli(){
	if ! command -v aws &> /dev/null; then
		echo "AWS CLI not found"
		return 1
	fi
}

install_awscli(){
	echo "Installing AWS CLI"

   	 # Download and install AWS CLI v2
    	sudo apt-get install -y unzip &> /dev/null
	curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
	unzip awscliv2.zip
	sudo ./aws/install

    	# Verify installation
    	aws --version

    	# Clean up
    	rm -rf awscliv2.zip ./aws
	
	#configure aws cli after installation
	aws configure
}

create_ec2_instance() {
    	local ami_id="$1"
    	local instance_type="$2"
    	local key_name="$3"
    	local subnet_id="$4"
    	local security_group_ids="$5"
    	local instance_name="$6"

    	# Run AWS CLI command to create EC2 instance
    	instance_id=$(aws ec2 run-instances \
        	--image-id "$ami_id" \
        	--instance-type "$instance_type" \
        	--key-name "$key_name" \
        	--subnet-id "$subnet_id" \
        	--security-group-ids "$security_group_ids" \
        	--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
		--query 'Instances[0].InstanceId' \
		--output text
	)
	
	if [[ -z "$instance_id" ]]; then
		echo "Failed to create EC2 instance" >&2
		exit 1
	fi

	echo "EC2 instance $instance_id  created successfully"

}

main(){
	if ! check_awscli; then
		install_awscli
	fi
	
	read -p "Enter AMI ID: " ami_id
	read -p "Enter Instance Type: " instance_type
	read -p "Enter Key Name: " key_name
	read -p "Enter Subnet ID: " subnet_id
	read -p "Enter Security Groups ID: " security_groups
	read -p "Instance Name: " instance_name

	if ! create_ec2_instance "$ami_id" "$instance_type" "$key_name" "$subnet_id" "$security_groups" "$instance_name"; then
		echo "Failed to create EC2 instance"
		exit 1
	fi

	echo "Wait few seconds to get instance in running state"

}

main "$@"
