output "resource_group_name" {
  value = azurerm_resource_group.mg.name
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.memgraph_ha.name
}

output "kube_config_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.mg.name} --name ${azurerm_kubernetes_cluster.memgraph_ha.name} --overwrite-existing"
}
