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
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )
    Write-Host "Evaluating the NetworkTopologyandConnectivity design area..."
    Measure-ExecutionTime -ScriptBlock {
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
            #Exception for D01.03 since there's 2 of them in the checklist
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.03") -and ($_.subcategory -eq "Hub and spoke") }) | Test-QuestionD0103HS
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.04") }) | Test-QuestionD0104
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.06") }) | Test-QuestionD0106
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.07") }) | Test-QuestionD0107

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
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.03") -and ($_.subcategory -eq "App delivery") }) | Test-QuestionD0103

        # Encryption
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D02.01") }) | Test-QuestionD0201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D02.02") }) | Test-QuestionD0202
        # Hybrid
        # Internet
        # IP plan
        # PaaS
        # Segmentation

        $graphItems = $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -notin @("Firewall", "Hub and spoke", "Virtual WAN")) -and $_.graph } | ForEach-Object {
            $results += $_ | Test-QuestionAzureResourceGraph
        }

        $script:FunctionResult = $results
    } -FunctionName "Invoke-NetworkTopologyandConnectivityAssessment"

    return $script:FunctionResult
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
        elseif ($expressRouteGatewayPresent -or $vpnGatewayPresent -or $azureFirewallPresent -or $nvaPresent -or $privateDnsResolverPresent) {
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

function Test-QuestionD0103 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        $publicIPs = Search-AzGraph -Query "Resources | where type == 'microsoft.network/publicIPAddresses' | project name, id, ddosSettings = properties.ddosSettings.protectionMode, ipConfigurationId = properties.ipConfiguration.id"

        $protectedIPs = 0

        foreach ($ip in $publicIPs) {
            if ($ip.ddosSettings -eq 'Enabled') {
                $protectedIPs++
            }
            elseif ($ip.ddosSettings -eq 'VirtualNetworkInherited') {
                $ipConfiguration = Search-AzGraph -Query "Resources | where id == '$($ip.ipConfigurationId)' | project virtualNetworkId = properties.subnet.id"
                if ($ipConfiguration) {
                    $virtualNetwork = Search-AzGraph -Query "Resources | where id == '$($ipConfiguration.virtualNetworkId)' | project ddosProtection = properties.enableDdosProtection"
                    if ($virtualNetwork.ddosProtection) {
                        $protectedIPs++
                    }
                }
            }
        }

        if ($totalIPs -gt 0) { 
            $estimatedPercentageApplied = ($protectedIPs / $publicIPs.Count) * 100 
        } 

        $rawData = @{
            "PublicIPs"                  = $publicIPs
            "TotalIPs"                   = $publicIPs.Count
            "ProtectedIPs"               = $protectedIPs
            "estimatedPercentageApplied" = $estimatedPercentageApplied
        }

        if ($estimatedPercentageApplied -eq 100) {
            $status = [Status]::Implemented
        }
        elseif ($estimatedPercentageApplied -gt 0) {
            $status = [Status]::PartiallyImplemented
        }
        else {
            $status = [Status]::NotImplemented
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

function Test-QuestionD0103HS {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0

        $nvaPresent = $resources | Where-Object { $_.type -eq 'Microsoft.Network/networkInterfaces' -and $_.properties.enableIPForwarding } | Measure-Object | Select-Object -ExpandProperty Count -gt 0

        if ($nvaPresent) {
            $status = [Status]::ManualVerificationRequired
        }
        else {
            $status = [Status]::NotImplemented
        }

        $rawData = @{
            "nvaPresent" = $nvaPresent
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

function Test-QuestionD0104 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0

        $expressRouteGateways = Search-AzGraph -Query "Resources | where type == 'Microsoft.Network/expressRouteGateways' | project name, properties.virtualNetwork.id"
        $vpnGateways = Search-AzGraph -Query "Resources | where type == 'Microsoft.Network/vpnGateways' | project name, properties.virtualNetwork.id"

        $routeServerPotentialVnets = @()

        foreach ($expressRouteGateway in $expressRouteGateways) {
            foreach ($vpnGateway in $vpnGateways) {
                if ($expressRouteGateway.'properties.virtualNetwork.id' -eq $vpnGateway.'properties.virtualNetwork.id') {
                    $routeServerPotentialVnets += $expressRouteGateway.'properties.virtualNetwork.id'
                }
            }
        }

        if ($routeServerPotentialVnets.Count -gt 0) {
            $status = [Status]::ManualVerificationRequired
        }
        else {
            $status = [Status]::NotApplicable
        }

        $rawData = @{
            "routeServerPotentialVnets" = $routeServerPotentialVnets
            "expressRouteGateways"      = $expressRouteGateways
            "vpnGateways"               = $vpnGateways
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

function Test-QuestionD0106 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        $virtualNetworks = Search-AzGraph -Query "Resources | where type == 'microsoft.network/virtualnetworks'"
        $vnetPairs = @()
        foreach ($vnet in $virtualNetworks) {
            # Check if the virtual network has peerings
            $peerings = $vnet.properties.virtualNetworkPeerings
            if ($null -ne $peerings) {
                foreach ($peering in $peerings) {

                    $peeredVnetId = $peering.properties.remoteVirtualNetwork.id
                    $peeredVnet = Search-AzGraph -Query "Resources | where id == '$peeredVnetId' | project location"
                    if ($peeredVnet.location -eq $vnet.location) {
                        $vnetPairs += @{
                            "Vnet1" = $vnet
                            "Vnet2" = $peeredVnet
                        }
                        $status = [Status]::ManualVerificationRequired
                        break
                    }
                    else {
                        $status = [Status]::NotApplicable
                    }
                }
            }
        }
        $rawData = @{
            "VirtualNetworks" = $virtualNetworks
            "VnetPairs"       = $vnetPairs
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

function Test-QuestionD0107 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        $virtualNetworks = Search-AzGraph -Query "Resources | where type == 'microsoft.network/virtualnetworks'"
        $nsgs = Search-AzGraph -Query "Resources | where type == 'microsoft.network/networksecuritygroups'"
        $flowLogs = Search-AzGraph -Query "resources | where type =~ 'microsoft.network/networkwatchers/flowlogs' and isnotnull(properties) | extend targetResourceId = tostring(properties.targetResourceId) | extend storageId = tostring(properties.storageId) | extend status = iff(properties.enabled =~ 'true', 'Enabled', 'Disabled') | extend flowLogType = iff(properties.targetResourceId contains 'Microsoft.Network/networkSecurityGroups', 'NSG', 'VNet')| project name,resourceGroup,status,flowLogType,targetResourceId,storageId,id,type,kind,location,subscriptionId,tags"

        $enabledFlowLogsResources = @()
        $disabledFlowLogsResources = @()

        foreach ($vnet in $virtualNetworks) {
            $vnetFlowLog = $flowLogs | Where-Object { $_.targetResourceId -eq $vnet.id }
            if ($vnetFlowLog.status -eq 'Enabled') {
                $enabledFlowLogsResources += $vnet.id
            }
            else {
                $disabledFlowLogsResources += $vnet.id
            }
        }

        foreach ($nsg in $nsgs) {
            $nsgFlowLog = $flowLogs | Where-Object { $_.targetResourceId -eq $nsg.id }
            if ($nsgFlowLog.status -eq 'Enabled') {
                $enabledFlowLogsResources += $nsg
            }
            else {
                $disabledFlowLogsResources += $nsg
            }
        }

        $estimatedPercentageApplied = ($enabledFlowLogsResources.Count / ($virtualNetworks.Count + $nsgs.Count)) * 100

        $rawData = @{
            "EnabledFlowLogs"  = $enabledFlowLogs
            "DisabledFlowLogs" = $disabledFlowLogs
            "flowLogs"         = $flowLogs
        }

        if ($estimatedPercentageApplied -eq 100) {
            $status = [Status]::Implemented
        }
        elseif ($estimatedPercentageApplied -gt 0) {
            $status = [Status]::PartiallyImplemented
        }
        else {
            $status = [Status]::NotImplemented
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

function Test-QuestionD0201 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    ) 

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $estimatedPercentageApplied = 0
    $status = [Status]::NotDeveloped
    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $_

    return $result
}

function Test-QuestionD0202 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    ) 

    Write-Host "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $estimatedPercentageApplied = 0
    try {
        $expressRouteDirectCircuits = Search-AzGraph -Query "resources | where type == 'microsoft.network/expressrouteports' | project name"
        if ($expressRouteDirectCircuits.Count -eq 0) {
            $expressRouteGateways = Search-AzGraph -Query "Resources | where type == 'Microsoft.Network/expressRouteGateways' | project name, properties.virtualNetwork.id"
            if ($expressRouteGateways.Count -gt 0) {
                $vpnGateways = Search-AzGraph -Query "Resources | where type == 'Microsoft.Network/vpnGateways' | project name, properties.virtualNetwork.id"
                $vpnGatewayPresent = $vpnGateways | Where-Object { $_.'properties.virtualNetwork.id' -eq $expressRouteGateways[0].'properties.virtualNetwork.id' } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
                if ($vpnGatewayPresent) {
                    $status = [Status]::ManualVerificationRequired
                    $estimatedPercentageApplied = 50
                }
                else {
                    $status = [Status]::NotImplemented
                }
            }
            else {
                $status = [Status]::NotImplemented
            }
        }
        else {
            $status = [Status]::NotApplicable
        }

        $rawData = @{
            "ExpressRouteDirectCircuits" = $expressRouteDirectCircuits
            "ExpressRouteGateways"       = $expressRouteGateways
            "VpnGateways"                = $vpnGateways
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