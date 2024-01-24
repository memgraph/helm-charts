# Memgraph Helm Charts
[![License: Apache-2.0](https://img.shields.io/github/license/memgraph/helm-charts)](https://github.com/memgraph/helm-charts/blob/main/LICENSE)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/memgraph)](https://artifacthub.io/packages/search?repo=memgraph)
[![Docs](https://img.shields.io/badge/documentation-Memgraph-orange)](https://memgraph.com/docs/)


Welcome to the Memgraph Helm Charts repository. This repository provides Helm charts for deploying Memgraph, an open-source in-memory graph database.

## Available charts
- [**Memgraph standalone**](#memgraph-standalone)
- [**Memgraph Platform**](#memgraph-platform)

## Prerequisites
Helm version 3 or above installed.

## Add the Helm repository
Add the Memgraph Helm chart repository to your local Helm setup by running the following command:

```
helm repo add memgraph https://memgraph.github.io/helm-charts
```

## Update the repository
Make sure to update the repository to fetch the latest Helm charts available:

```
helm repo update
```

## Memgraph Platform
Deploys Memgraph Platform.
For detailed information and usage instructions, please refer to the [chart's individual README file](./charts/memgraph-platform/README.md).

To install Memgraph Platform, run the following command:

```
helm install my-release memgraph/memgraph-platform
```
Replace `my-release` with a name of your choice for the release.

## Memgraph standalone
Deploys standalone Memgraph.
For detailed information and usage instructions, please refer to the [chart's individual README file](./charts/memgraph/README.md).

To install Memgraph standalone, run the following command:

```
helm install my-release memgraph/memgraph
```
Replace `my-release` with a name of your choice for the release.


Once Memgraph is installed, you can access it using the provided services and endpoints. Refer to the [Memgraph documentation](https://memgraph.com/docs/memgraph/connect-to-memgraph) for details on how to connect to and interact with Memgraph.

To upgrade or uninstall a deployed Memgraph release, you can use the `helm upgrade` or `helm uninstall` commands, respectively. Refer to the [Helm documentation](https://helm.sh/docs/) for more details on these commands.

## Contributing
Contributions are welcome! If you have any improvements, bug fixes, or new charts to add, please follow the contribution guidelines outlined in the [`CONTRIBUTING.md`](https://github.com/memgraph/helm-charts/blob/main/CONTRIBUTING.md) file. If you have questions and are unsure of how to contribute, please join our Discord server to get in touch with us.

<p align="center">
  <a href="https://memgr.ph/join-discord">
    <img src="https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white" alt="Discord"/>
  </a>
</p>

## License
This repository is licensed under the [Apache 2.0 License](https://github.com/memgraph/helm-charts/blob/main/LICENSE). 

