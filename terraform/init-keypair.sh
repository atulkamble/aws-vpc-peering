#!/bin/bash

# Script to handle AWS key pair creation or import
# This script checks if the key pair exists in AWS and imports it into Terraform state if needed

KEY_NAME="${1:-key}"
REGION="${2:-us-east-1}"

echo "Checking for existing key pair: $KEY_NAME in region: $REGION"

# Check if key pair exists in AWS
if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &> /dev/null; then
    echo "✓ Key pair '$KEY_NAME' already exists in AWS"
    
    # Check if it's already in Terraform state
    if terraform state show aws_key_pair.deployer_key &> /dev/null; then
        echo "✓ Key pair is already in Terraform state"
    else
        echo "→ Importing key pair into Terraform state..."
        terraform import aws_key_pair.deployer_key "$KEY_NAME"
        if [ $? -eq 0 ]; then
            echo "✓ Key pair successfully imported"
        else
            echo "✗ Failed to import key pair"
            exit 1
        fi
    fi
else
    echo "✗ Key pair '$KEY_NAME' does not exist in AWS"
    echo "→ Terraform will create a new key pair during apply"
fi

echo ""
echo "Ready to run: terraform apply"
