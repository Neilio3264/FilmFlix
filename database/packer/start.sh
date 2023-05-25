#!/usr/bin/bash

function buildImage {
    cloud=$2
    export MACHINE_TYPE=$1
    /usr/bin/packer build -force filmflix_${cloud}_ec2_config.json
}

buildImage mongodb aws