#!/bin/bash
if [ "$KUBECONFIG" != ".kubeconfig" ]; then
    printf "\033[34mKUBECONFIG is not set to .kubeconfig\nConsider adding 'export KUBECONFIG=\".kubeconfig\"' to your .bashrc or .zshrc file\033[0m\n"
fi
BASE_DIR=$(pwd)
export KUBECONFIG=".kubeconfig"

OUTPUT_CLUSTER_CONFIGS="no"
if [ "$OUTPUT_CLUSTER_CONFIGS" == "yes" ]; then
    printf "\033[32mOutputting cluster configs to README-cluster-configs.md\033[0m\n"
    echo "AWS Cluster Configs" > README-cluster-configs.md
fi
profiles=("EngineeringDeveloper")

for profile in "${profiles[@]}"
do
    echo "Switching to AWS_PROFILE=$profile"
    export AWS_PROFILE=$profile
    # Get all AWS regions
    regions=$(aws ec2 describe-regions --region us-east-2 --profile "$AWS_PROFILE" --query 'Regions[].RegionName' --output text)

    # Loop through each region
    for region in $regions
    do
        echo "Checking region $region"

        # Get all EKS cluster names in the current region
        clusters=$(aws eks list-clusters --profile "$AWS_PROFILE" --region "$region" --query 'clusters' --output text)

        # Loop through each cluster
        for cluster in $clusters
        do
            mkdir -p "$BASE_DIR/aws/$cluster"
            cd "$BASE_DIR/aws/$cluster" || exit
            if [ "$OUTPUT_CLUSTER_CONFIGS" == "yes" ]; then
                echo "aws eks update-kubeconfig --profile $AWS_PROFILE --region $region --name $cluster --alias $cluster"
            fi
            aws eks update-kubeconfig --profile $AWS_PROFILE --region $region --name $cluster --alias $cluster
        done # clusters
    done # regions
done # profiles
unset AWS_PROFILE