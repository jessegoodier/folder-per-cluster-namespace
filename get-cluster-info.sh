#!/bin/bash
BASE_DIR=$(pwd)
# Define the base directory
CLOUD_PROVIDERS="gcp aws azure"
KUBECONFIG=".kubeconfig"
# Loop through each CLUSTER in the base directory

for CLOUD_PROVIDER in $CLOUD_PROVIDERS; do
    if [ ! -d "$BASE_DIR/$CLOUD_PROVIDER" ]; then
        echo "Directory $BASE_DIR/$CLOUD_PROVIDER does not exist. Skipping..."
        continue
    fi
    cd "$BASE_DIR/$CLOUD_PROVIDER"
    # get a list of all subdirs
    CLUSTERS=$(ls -d */)
    for CLUSTER in $CLUSTERS; do
        cd "$BASE_DIR/$CLOUD_PROVIDER/$CLUSTER"

        # get ingress list and add to readme
        # printf "kubectl get ingress -A -o jsonpath='{.items[*].spec.rules[*].host}' | sed 's/[^ ]*/<https:\/\/&>/g' | sed 's/</\n- /g' > README.md\n"
        kubectl get ingress -A -o jsonpath='{.items[*].spec.rules[*].host}'\
          | sed 's/[^ ]*/<https:\/\/&>/g' | sed 's/</\n- </g' > "README.md"

        # get all namespaces, create directories and find basic info
        NAMESPACES=$(kubectl get ns -o jsonpath='{.items[*].metadata.name}')
        for NAMESPACE in $NAMESPACES; do
            mkdir -p "$BASE_DIR/$CLOUD_PROVIDER/$CLUSTER/$NAMESPACE"
            cd "$BASE_DIR/$CLOUD_PROVIDER/$CLUSTER/$NAMESPACE"
            echo -e "\e[36m$(pwd)\e[0m"
            cp ../.kubeconfig .
            chmod 600 .kubeconfig
            kubectl config set-context --current --namespace="$NAMESPACE"

            HELM_RELEASES=$(helm ls --output json |jq -r '.[].name')
            for RELEASE in $HELM_RELEASES; do
                echo "$RELEASE"
                helm get values "$RELEASE" > "helmValues-$RELEASE.yaml"
                sed -i '/^USER-SUPPLIED VALUES:/d' "helmValues-$RELEASE.yaml"
                sed -i '/^null$/d' "helmValues-$RELEASE.yaml"
                if [ "$(wc -l < "helmValues-$RELEASE.yaml")" -lt 3 ]; then
                    continue
                fi

                # example of getting secrets and putting some information into a label
                FEDERATED_STORE=$(yq .kubecostModel.federatedStorageConfigSecret "helmValues-$RELEASE.yaml")
                if [ ${#FEDERATED_STORE} -gt 6 ]; then
                    # printf "\e[32mfederated-store secret found: %s\e[0m\n" "$FEDERATED_STORE"
                    kubectl get secret "$FEDERATED_STORE" -o yaml > "federated-store.yaml"
                    BUCKET_VALUE=$(ksd < "federated-store.yaml" | grep bucket: | head -n 1 |sed 's/bucket: //' | sed 's/ //g' | sed 's/"//g')
                    PROVIDER_TYPE=$(ksd < "federated-store.yaml" | grep type: | head -n 1 | sed 's/type: //' | sed 's/ //g' | sed 's/"//g')
                    printf "\e[32mfederated-store bucket: %s\e[0m\n" "$PROVIDER_TYPE/$BUCKET_VALUE"
                    yq eval '.metadata.labels.bucket = "'$BUCKET_VALUE'"' -i "federated-store.yaml"
                    yq eval '.metadata.labels.provider = "'$PROVIDER_TYPE'"' -i "federated-store.yaml"
                fi
            done #HELM_RELEASES
        done #NAMESPACES
    done #CLUSTERS
done #CLOUD_PROVIDERS

# find . -name "federated-store.yaml" -exec grep -H -E "bucket:" {} \;