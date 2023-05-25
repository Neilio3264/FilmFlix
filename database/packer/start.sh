# /bin/bash

export AWS_ACCESS_KEY_ID=$1
export AWS_SECRET_ACCESS_KEY=$2
export AWS_DEFAULT_REGION="us-east-2"

function buildImage {
    cloud=$2
    export MACHINE_TYPE=$1
    /usr/bin/packer init filmflix_${cloud}_ec2_config.pkr.hcl
    /usr/bin/packer build -force filmflix_${cloud}_ec2_config.pkr.hcl
}

buildImage mongodb aws