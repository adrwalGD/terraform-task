output "image_id" {
  value       = azurerm_image.img_from_managed_disk.id
  description = "The ID of VM image."
}
