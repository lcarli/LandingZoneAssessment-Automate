# NetworkTopologyandConnectivity.ps1

<#
.SYNOPSIS
    Functions related to NetworkTopologyandConnectivity assessment.

.DESCRIPTION
    This script contains functions to evaluate the NetworkTopologyandConnectivity area of Azure Landing Zone.

.LICENSE
    MIT License

.AUTHOR
    maximeroy@microsoft.com
#>

# Import shared modules
Import-Module "$PSScriptRoot/../shared/Enums.ps1"
Import-Module "$PSScriptRoot/../shared/ErrorHandling.ps1"
Import-Module "$PSScriptRoot/../shared/SharedFunctions.ps1"

function Invoke-NetworkTopologyandConnectivityAssessment {
    [CmdletBinding()]
    param (
        [object]$Checklist
    )
    Write-Host "Evaluating the NetworkTopologyandConnectivity design area..."

    $results = @()


    $virtualWANPresent = (Search-AzGraph -Query "Resources | where type =~ 'Microsoft.Network/virtualWans' | project name").Count -gt 0
    $azureFirewallPresent = (Search-AzGraph -Query "Resources | where type =~ 'Microsoft.Network/azureFirewalls' | project name").Count -gt 0

    #Virtual WAN subcategory
    if ($virtualWANPresent) {
        $graphItems = $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -eq "Virtual WAN") -and $_.graph } | ForEach-Object {
            $results += $_ | Test-QuestionAzureResourceGraph
        }
    }
    #Hub and Spoke subcategory
    else {
        #Exception for D01.01 since there's 2 of them in the checklist
        $d0101Results += ($Checklist.items | Where-Object { ($_.id -eq "D01.01") -and ($_.subcategory -eq "Hub and spoke") }) | Test-QuestionD0101
        $results += $d0101Results

        $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.02") }) | Test-QuestionD0102 -rawDataD0101 $($d0101Results.rawData)

        $graphItems = $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -eq "Hub and spoke") -and $_.graph } | ForEach-Object {
            $results += $_ | Test-QuestionAzureResourceGraph
        }
    }

    #Firewall subcategory
    if ($azureFirewallPresent) {
        $graphItems = $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -eq "Firewall") -and $_.graph } | ForEach-Object {
            $results += $_ | Test-QuestionAzureResourceGraph
        }
    }

    # App delivery subcategory

    # Encryption
    # Hybrid
    # Internet
    # IP plan
    # PaaS
    # Segmentation

    $graphItems = $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -notin @("Firewall", "Hub and spoke", "Virtual WAN")) -and $_.graph } | ForEach-Object {
        $results += $_ | Test-QuestionAzureResourceGraph
    }

    return $results
}

function Test-QuestionD0101 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    # Based on assumption that usually a hub and spoke can be identified if there's a vnet with 2 or more peering 
    # that have also either a vpn gateway or an expressroute gateway and if there's an azure firewall or an nva with IP forwarding in this vnet
    try {
        $estimatedPercentageApplied = 0
        $virtualNetworks = Search-AzGraph -Query "Resources | where type == 'microsoft.network/virtualnetworks'"
        foreach ($vnet in $virtualNetworks) {
            # Check if the virtual network has peerings
            $peerings = $vnet.properties.virtualNetworkPeerings
            if ($null -ne $peerings) {
                # Get the number of peerings in this VNet
                $peeringsCount = $peerings.Count
                
                # Compare with the current max count
                if ($peeringsCount -gt $maxPeeringsCount) {
                    $maxPeeringsCount = $peeringsCount
                    $maxPeeringsVnet = $vnet
                }
            }
        }
        if ($maxPeeringsCount -ge 2) {
            $vnetSpecialSubnets = $vnet.Properties.subnets | Where-Object { $_.Name -eq "GatewaySubnet" -or $_.Name -eq "AzureFirewallSubnet" }
            $vnetDevicesWithIPForwarding = Search-AzGraph -Query 'Resources | where type == "microsoft.network/networkinterfaces" | where properties.enableIPForwarding == true | project nicName = name, vmId = tostring(properties.virtualMachine.id), subnetId = tostring(properties.ipConfigurations[0].properties.subnet.id)| extend vnetId = substring(subnetId, 0, indexof(subnetId, "/subnets/")) | join kind=inner ( Resources | where type == "microsoft.compute/virtualmachines" | project vmName = name, vmId = id, resourceGroup, subscriptionId) on $left.vmId == $right.vmId | project vmName, nicName, resourceGroup, subscriptionId, vnetId, subnetId'
            
            if ($vnetSpecialSubnets -or $vnetDevicesWithIPForwarding ) {
                $estimatedPercentageApplied = 100
                $status = [Status]::Implemented
            }
            else {
                $estimatedPercentageApplied = 50
                $status = [Status]::PartiallyImplemented
            }
        }
        else {
            $status = [Status]::NotImplemented
        }
        $rawData = @{
            "MaxPeeringsCount"            = $maxPeeringsCount
            "MaxPeeringsVnet"             = $maxPeeringsVnet
            "VnetSpecialSubnets"          = $vnetSpecialSubnets
            "VnetDevicesWithIPForwarding" = $vnetDevicesWithIPForwarding
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $_ -rawData $rawData

    return $result
}

function Test-QuestionD0102 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem, 
        [Object]$rawDataD0101
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    # 
    try {
        $estimatedPercentageApplied = 0
        $hubVirtualNetworkId = $rawDataD0101.MaxPeeringsVnet.id
        $resourceGraphQuery = "Resources | where type in~ ('Microsoft.Network/expressRouteGateways', 'Microsoft.Network/vpnGateways', 'Microsoft.Network/azureFirewalls', 'Microsoft.Network/networkInterfaces', 'Microsoft.Network/privateDnsResolvers') | where properties.virtualNetwork.id == '$hubVirtualNetworkId' | project type, name, properties.enableIPForwarding"
        $resources = Search-AzGraph -Query $resourceGraphQuery
        $expressRouteGatewayPresent = $resources | Where-Object { $_.type -eq 'Microsoft.Network/expressRouteGateways' } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
        $vpnGatewayPresent = $resources | Where-Object { $_.type -eq 'Microsoft.Network/vpnGateways' } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
        $azureFirewallPresent = $resources | Where-Object { $_.type -eq 'Microsoft.Network/azureFirewalls' } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
        $nvaPresent = $resources | Where-Object { $_.type -eq 'Microsoft.Network/networkInterfaces' -and $_.properties.enableIPForwarding } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
        $privateDnsResolverPresent = $resources | Where-Object { $_.type -eq 'Microsoft.Network/privateDnsResolvers' } | Measure-Object | Select-Object -ExpandProperty Count -gt 0

        if (($expressRouteGatewayPresent -or $vpnGatewayPresent) -and ($azureFirewallPresent -or $nvaPresent) -and $privateDnsResolverPresent) {
            $status = [Status]::Implemented
            $estimatedPercentageApplied = 100
        } 
        elseif($expressRouteGatewayPresent -or $vpnGatewayPresent -or $azureFirewallPresent -or $nvaPresent -or $privateDnsResolverPresent) {
            $trueCount = 0
            if ($expressRouteGatewayPresent -or $vpnGatewayPresent) {
                $trueCount++
            }
            if ($azureFirewallPresent -or $nvaPresent) {
                $trueCount++
            }
            if ($privateDnsResolverPresent) {
                $trueCount++
            }

            $estimatedPercentageApplied = ($trueCount / 3) * 100
            $status = [Status]::PartiallyImplemented
        }
        else {
            $status = [Status]::NotImplemented
            $estimatedPercentageApplied = 0
        }

        $rawData = @{
            "HubVirtualNetworkId"        = $hubVirtualNetworkId
            "ExpressRouteGatewayPresent" = $expressRouteGatewayPresent
            "VpnGatewayPresent"          = $vpnGatewayPresent
            "AzureFirewallPresent"       = $azureFirewallPresent
            "NvaPresent"                 = $nvaPresent
            "PrivateDnsResolverPresent"  = $privateDnsResolverPresent
        }

    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $_ -rawData $rawData

    return $result
}