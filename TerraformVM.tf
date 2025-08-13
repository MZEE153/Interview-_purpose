8 Resources block will be created.
resource "azurerm_resource_group" "rg" { ... }
resource "azurerm_virtual_network" "vnet" { ... }
resource "azurerm_subnet" "subnet" { ... }
resource "azurerm_network_interface" "nic" { ... }
resource "azurerm_public_ip" "public_ip" { ... }
resource "azurerm_network_security_group" "nsg" { ... }
resource "azurerm_linux_virtual_machine" "vm" { ... }


#Main_RG
resource "azurerm_resource_group" "bk-rg-Proj-Dev-002" {
  for_each = var.rg
  name     = each.value.resource_group_name
  location = each.value.location  }
  variable "rg" { }

#Vnet
resource "azurerm_virtual_network" "bk-rg-Proj-Dev-002" {
 for_each = var.vnetvar
  name                = each.value.virtual_network_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  address_space       = each.value.address_space }

#subnet
resource "azurerm_subnet" "endpoint" {
    for_each = var.csubnet
  name                 = each.value.subnet_name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
  address_prefixes     = each.value.address_prefixes }
#NIC
resource "azurerm_network_interface" "nic" {
  for_each            = var.NIC
  name                = each.value.nic_name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  ip_configuration {
    name                          = each.value.ip_configuration_name
    subnet_id                     = data.azurerm_subnet.subnetdata[each.key].id
    private_ip_address_allocation = each.value.private_ip_address_allocation
    public_ip_address_id          = data.azurerm_public_ip.publicIpdata[each.key].id  }  }

#Data_NIC
data "azurerm_subnet" "subnetdata" {
  for_each = var.NIC
  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}
data "azurerm_public_ip" "publicIpdata" {
  for_each = var.NIC
  name                = each.value.pip_name
  resource_group_name = each.value.resource_group_name
}

#VM
resource "azurerm_virtual_machine" "main" {
  for_each                      = var.vvm
  name                          = each.value.VM_name
  location                      = each.value.location
  resource_group_name           = each.value.resource_group_name
  network_interface_ids         = [data.azurerm_network_interface.datanic[each.key].id]
  vm_size                       = "Standard_B1s"
  availability_set_id           = data.azurerm_availability_set.data_Availset[each.key].id
  delete_os_disk_on_termination = true

  #   boot_diagnostics {
  #   enabled = true
  # }


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "Azeemvmdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    disk_size_gb      = 64

  }
  os_profile {
    computer_name  = each.value.computer_name
    admin_username = each.value.admin_username
    admin_password = each.value.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }


  tags = {
    environment = "Dev"
    Owner       = "azeem"
    Created_on  = "22/june/2025"
  }
}

#Module 
module "Rgmodule" {
  source = "./module/RG"
  rg     = var.main_rg

}

module "vnetmodule" {
  source     = "./module/Vnet"
  vnetvar    = var.main_Vnet
  depends_on = [module.Rgmodule]
}
