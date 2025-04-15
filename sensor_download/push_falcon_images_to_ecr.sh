#!/bin/bash

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it before running this script."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install it before running this script."
    exit 1
fi

# Ask for the AWS ECR repository name
echo -n "Enter your AWS ECR repository URL (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com): "
read ECR_REPO

# Validate AWS authentication
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not authenticated. Please run 'aws configure' or authenticate your session."
    exit 1
fi

# Get local images
echo "Fetching local Docker images..."
docker images --format "{{.Repository}}:{{.Tag}}" | grep "registry.crowdstrike.com" > local_images.txt

# Display images
echo "Found the following images:"
cat -n local_images.txt

# Ask which images to push
echo "Enter the numbers of the images you want to push (separated by space):"
read -a SELECTION

# AWS ECR login
aws ecr get-login-password --region $(echo $ECR_REPO | cut -d'.' -f4) | docker login --username AWS --password-stdin $ECR_REPO
if [ $? -ne 0 ]; then
    echo "Error: Failed to authenticate with AWS ECR. Ensure you have the correct permissions."
    exit 1
fi

# Tag and push selected images
for INDEX in "${SELECTION[@]}"; do
    IMAGE=$(sed -n "${INDEX}p" local_images.txt)
    IMAGE_NAME=$(echo $IMAGE | awk -F'/' '{print $NF}')
    REMOTE_IMAGE="$ECR_REPO/$IMAGE_NAME"
    
    echo "Tagging $IMAGE as $REMOTE_IMAGE"
    docker tag $IMAGE $REMOTE_IMAGE
    
    echo "Pushing $REMOTE_IMAGE"
    docker push $REMOTE_IMAGE
    if [ $? -ne 0 ]; then
        echo "Error: Failed to push $REMOTE_IMAGE"
    fi
    
    echo "Done with $IMAGE_NAME"
done

rm local_images.txt
echo "Selected images have been pushed to ECR."
