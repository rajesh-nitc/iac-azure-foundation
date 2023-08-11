resource "azurerm_consumption_budget_management_group" "budget" {
  name                = format("%s-%s", "budget", data.azurerm_management_group.root.display_name)
  management_group_id = data.azurerm_management_group.root.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  notification {
    enabled        = true
    threshold      = 75.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = var.budget_contact_emails
  }

  lifecycle {
    ignore_changes = [
      time_period,
    ]
  }
}