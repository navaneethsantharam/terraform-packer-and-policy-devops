# About Project
A policy has been created to deny creation of any resource without tags(Refer azurepolicy.rules.json)
Packer image has been built(Refer server.json)
Terraform script has been used to provision a loadbalancer with virtual machine scale set on the backend. VMs will use the image build using packer

***Steps to define and assign the policy***

Use below commands

***Create Policy-**

  az policy definition create --name tagging-policy --display-name "Deny all resources without tags defined" --description "This policy denies creation of a resource if tags is not added" --rules azurepolicy.rules.json --mode All

***Assign the Policy-**

  az policy assignment create --name "tagging-policy" --display-name "Deny all resources without tags defined" --scope /subscriptions/<subscription-id>/resourceGroups/<resource-group-name> --policy /subscriptions/<subscription-id>/providers/Microsoft.Authorization/policyDefinitions/tagging-policy

Screenshot for reference-

 ![Policy_Screenshot](https://user-images.githubusercontent.com/108083391/192880100-d45c01ce-c15b-4014-8bdc-9e3607d451e9.jpg)
 
and describes how to customize it for use.


***Run packer template to build custom image***

*Install Packer

*Login into Azure CLI using service principle

*Run the command-packer build server.json

*To verify if image is available run the command-az image list

![Packer_Image](https://user-images.githubusercontent.com/108083391/192880974-f6cb9a52-7227-4da2-a6c3-81c723835c8c.jpg)


***Using Teraform to create the VM scale set witterraform inith a Load balancer and a public IP***

*Install teraform

*Run below commands 
  
  a)terraform init
  
  b)terraform plan -out solution.plan
  
  c)terraform apply solution.plan
  
  d)terraform show
  
  c)terraform destroy (to destroy resources created)
 
 
 Screenshot for reference-
 
![tf1](https://user-images.githubusercontent.com/108083391/192887476-2e18a0be-b04b-4415-8df1-b19074bd658f.jpg)
![tf2](https://user-images.githubusercontent.com/108083391/192887483-d26a19f2-0cfa-4f2d-b0df-184aec653d4c.jpg)

 **Please note-
 
 1)main.tf has the terraform configuration to create azure resources and vars.tf has the variables. The variables has been given default value. if any values needs changes please modify default value or remove default value(so that the parameter will be prompted during terraform plan step)
 Eg-location is by default set to South Central US. We can change it to suitable value or remove default value
 
 2)any new variable can be added in vars.tf and can be used in main.tf by referencing as var.<variable_name>
 
 3)Here resource group already exists in cloud environment. Else resource group can be created adding the below block before azurerm_virtual_network block(line number 23)
 resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags = var.tags
}
 
4)Only variable without default value is location. The values needs to be passed during terraform plan step
