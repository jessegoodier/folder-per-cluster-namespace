#!/bin/bash
if [ "$KUBECONFIG" != ".kubeconfig" ]; then
    printf "\033[34mKUBECONFIG is not set to .kubeconfig\nConsider adding 'export KUBECONFIG=\".kubeconfig\"' to your .bashrc or .zshrc file\033[0m\n"
fi
BASE_DIR=$(pwd)
export KUBECONFIG=".kubeconfig"

# List of tenant IDs to iterate over
# tenants=("72faf3ff-7a3f-4597-b0d9-7b0b201bb23a" "0bb99d84-39d8-4221-9917-59f51dbf106c" "5935a4a6-4b63-47b6-9b5c-42f340be9e7a")
subscriptions=("XXXX")
for subscription in "${subscriptions[@]}"
do
    echo "Switching to subscription $subscription"
    az account set --subscription "$subscription"

    # Get all resource groups in the current tenant
    clusterList=$(az aks list --query '[].{name:name, resourceGroup:resourceGroup}')
    # Loop through each resource group
    for row in $(echo "${clusterList}" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }

        cluster=$(_jq '.name')
        rg=$(_jq '.resourceGroup')

        echo "Adding AKS cluster: $cluster from resource group: $rg in subscription: $subscription to kubeconfig"
        mkdir -p "$BASE_DIR/azure/$cluster"
        cd "$BASE_DIR/azure/$cluster" || exit
        az aks get-credentials --resource-group "$rg" --name "$cluster" --overwrite-existing --context "$cluster"
    done
done