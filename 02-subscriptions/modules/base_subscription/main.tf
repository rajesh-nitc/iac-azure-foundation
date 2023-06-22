locals {
  mg_id    = data.azurerm_management_group.mg.id
  sub_name = data.azurerm_subscriptions.all.subscriptions[0].display_name
  sub_id   = data.azurerm_subscriptions.all.subscriptions[0].subscription_id
  id       = data.azurerm_subscriptions.all.subscriptions[0].id

  rg_name = azurerm_resource_group.rg.name

  uai_roles = flatten([
    for k, v in var.uai_roles : [
      for i in v : { member = k, role = i }
    ]
  ])

  group_roles = flatten([
    for k, v in var.group_roles : [
      for i in v : { member = k, role = i }
    ]
  ])
}