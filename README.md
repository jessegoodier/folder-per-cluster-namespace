# folder-per-cluster-namespace

This project is a collection of scripts and configurations to help manage Kubernetes clusters and namespaces.

The goal is to store the KUBECONFIG for each namespace in a directory that is named after the namespace.

By setting the KUBECONFIG environment variable to the relative path current directory for the namespace, you can easily switch between contexts by `cd`ing into the directory.

## Setup

Set the KUBECONFIG environment variable to point to the kubeconfig in the current directory.

You will likely want this in your .zsrc.

```sh
export KUBECONFIG=./.kubeconfig
```

Highly recommend you use a tool like https://github.com/superbrothers/zsh-kubectl-prompt to show what context you are in, though it SHOULD be redundant.

## Why This Approach?

### Benefits:

1. **Context-Specific Terminals**: Each terminal will be in the expected context based on the directory, reducing the risk of errors.
2. **Simplified Configuration**: No need to run lengthy cloud provider commands to obtain the `KUBECONFIG`; they are already available in each directory within this repository.
3. **Searchable Configurations**: Easily search through configurations without switching clusters.
4. **Backup Simplicity**: A straightforward method to back up all configurations. Refer to this script: [get-cluster-info.sh](./get-cluster-info.sh)
5. **Labeling**: You may have secrets that have base64 strings with metadata that would be useful to have in a label. This is optional and is done in the `get-cluster-info.sh` script.

## Get All Cluster Contexts

These scripts will build out the structure.

Each script will find all the clusters in the given cloud provider and add them to a .kubeconfig file in a directory with the name of the cluster.

Example `gcp/dev-1/.kubeconfig`

```sh
./get-gke-clusters.sh
./get-aks-clusters.sh
./get-eks-clusters.sh
```

## Get All Namespace Contexts

As new namespaces and/or clusters are added, this script can be run to build out the structure.

```sh
./get-cluster-info.sh
```

## Helpful Commands

If the .kubeconfig files are causing warning message:

```
WARNING: Kubernetes configuration file is group-readable. This is insecure. Location: .kubeconfig
```

Run this to fix it:

```sh
find . -name ".kubeconfig" -exec chmod 600 {} \;
```