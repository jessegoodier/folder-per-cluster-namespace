#!/bin/bash
if [ "$KUBECONFIG" != ".kubeconfig" ]; then
    printf "\033[34mKUBECONFIG is not set to .kubeconfig\nConsider adding 'export KUBECONFIG=\".kubeconfig\"' to your .bashrc or .zshrc file\033[0m\n"
fi
BASE_DIR=$(pwd)
export KUBECONFIG=".kubeconfig"

PROJECT_ID="GCP_PROJECT_ID"
# Get a list of all regions using gcloud

regions=$(gcloud container clusters list --project=$PROJECT_ID --format="[no-heading](location)"|sort -u)

# Loop through each region
for region in $regions; do
    # Get a list of clusters in the current region
    echo "Getting clusters in region $region"
    clusters=$(gcloud container clusters list --zone="$region" --project=$PROJECT_ID --format="value(name)" )

    # Loop through each cluster and add it to kubeconfig
    for cluster in $clusters
      do
        mkdir -p "$BASE_DIR/gcp/$cluster"
        cd "$BASE_DIR/gcp/$cluster" || exit
        echo "Adding cluster $cluster in region $region to kubeconfig"
        gcloud container clusters get-credentials "$cluster" --zone="$region" --project=$PROJECT_ID
        echo "gcloud container clusters get-credentials $cluster --zone=$region --project=$PROJECT_ID"
        kubectl config rename-context "$(kubectl config current-context)" "$cluster"
    done
done

echo "All clusters from all regions added to kubeconfig!"
