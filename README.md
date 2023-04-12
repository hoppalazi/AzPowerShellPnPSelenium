# AzPowerShellPnPSelenium
[![Docker Repository on Quay](https://quay.io/repository/hoppalazi/azpowershellpnpselenium/status "Docker Repository on Quay")](https://quay.io/repository/hoppalazi/azpowershellpnpselenium)

Container image based on [Azure PowerShell](https://hub.docker.com/_/microsoft-azure-powershell) with [PnP.PowerShell](https://www.powershellgallery.com/packages/PnP.PowerShell) Module and [Selenium.WebDriver](https://www.nuget.org/packages/Selenium.WebDriver) package for use in Azure DevOps Pipeline as [self-hosted agent](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux).

This image is built to use with [PowerShell](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/powershell-v2?view=azure-pipelines) and [AzurePowerShell](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/azure-powershell-v5?view=azure-pipelines) tasks for browser automation.

Based on the PowerShell image following packages are added:
 - Microsoft Edge
 - Microsoft Edge Webdriver
 - git
 - Selenium.WebDriver
 - PnP.PowerShell
