output "databricks_workspaces" {
  value = {
    for k, v in azurerm_databricks_workspace.ws : k => {
      id                        = v.id
      managed_resource_group_id = v.managed_resource_group_id
      workspace_url             = v.workspace_url
      workspace_id              = v.workspace_id
    }
  }
}

