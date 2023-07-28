#!/bin/bash
#--- bastion user data
yum update -y
yum install -y mysql 
yum install -y git tmux 
yum install -y ansible