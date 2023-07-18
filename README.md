# Memgraph Helm Charts Repository

Welcome to the Memgraph Helm Charts Repository. This repository provides Helm charts for deploying Memgraph, an open-source in-memory graph database.

## Prerequisites
Helm version 3 or above installed.

## Usage
To use this Helm chart repository, follow the steps below:

### Step 1: Add the Helm repository
Add the Memgraph Helm chart repository to your local Helm setup by running the following command:

```
helm repo add memgraph https://memgraph.github.io/helm-charts
```

### Step 2: Update the repository
Make sure to update the repository to fetch the latest Helm charts available:

```
helm repo update
```

### Step 3: Install Memgraph
To install Memgraph, run the following command:

```
helm install my-release memgraph/memgraph
```
Replace my-release with a name of your choice for the release.

### Step 4: Accessing Memgraph
Once Memgraph is installed, you can access it using the provided services and endpoints. Refer to the Memgraph documentation for details on how to connect to and interact with Memgraph.

### Step 5: Customizing the chart values
You can customize the default chart values by creating a `values.yaml` file and overriding the desired values. For example:

```
helm install my-release memgraph/memgraph -f values.yaml
```

### Step 6: Upgrade or uninstall
To upgrade or uninstall a deployed Memgraph release, you can use the helm upgrade or helm uninstall commands, respectively. Refer to the Helm documentation for more details on these commands.

## Chart Details
Here are the Helm charts available in this repository:

1. Memgraph
Chart Description: Deploys standalone Memgraph.
Chart Version: 0.1.0 
App Version: 2.8.0
For detailed information and usage instructions for each chart, please refer to the chart's individual README file.

## Contributing
Contributions are welcome! If you have any improvements, bug fixes, or new charts to add, please follow the contribution guidelines outlined in the [`CONTRIBUTING.md`](https://github.com/memgraph/helm-charts/blob/main/CONTRIBUTING.md) file.

## License
This repository is licensed under the [Apache 2.0 License](https://github.com/memgraph/helm-charts/blob/main/LICENSE). 
