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

# Dot-source shared modules
. "$PSScriptRoot/../shared/Enums.ps1"
. "$PSScriptRoot/../shared/ErrorHandling.ps1"
. "$PSScriptRoot/../shared/SharedFunctions.ps1"

function Invoke-NetworkTopologyandConnectivityAssessment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Checklist
    )
    Measure-ExecutionTime -ScriptBlock {
        Write-AssessmentHeader "Evaluating the NetworkTopologyandConnectivity design area..."

        $results = @()

        # Use cached data instead of direct Search-AzGraph calls
        $virtualWans = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualWans' }
        $azureFirewalls = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/azureFirewalls' }
        
        $virtualWANPresent = ($virtualWans | Measure-Object).Count -gt 0
        $azureFirewallPresent = ($azureFirewalls | Measure-Object).Count -gt 0

        #Virtual WAN subcategory
        if ($virtualWANPresent) {
            $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -eq "Virtual WAN") -and $_.graph } | ForEach-Object {
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
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.08") }) | Test-QuestionD0108
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.09") }) | Test-QuestionD0109
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.10") }) | Test-QuestionD0110
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.11") }) | Test-QuestionD0111
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.12") }) | Test-QuestionD0112
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.13") }) | Test-QuestionD0113
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.14") }) | Test-QuestionD0114
            $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.15") }) | Test-QuestionD0115

            $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -eq "Hub and spoke") -and $_.graph } | ForEach-Object {
                $results += $_ | Test-QuestionAzureResourceGraph
            }
        }

        #Firewall subcategory
        if ($azureFirewallPresent) {
            $Checklist.items | Where-Object { ($_.category -eq "Network Topology and Connectivity") -and ($_.subcategory -eq "Firewall") -and $_.graph } | ForEach-Object {
                $results += $_ | Test-QuestionAzureResourceGraph
            }
        }

        # App delivery subcategory
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D01.03") -and ($_.subcategory -eq "App delivery") }) | Test-QuestionD0103

        # Encryption
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D02.01") }) | Test-QuestionD0201
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D02.02") }) | Test-QuestionD0202
        
        # IP plan
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D03.01") }) | Test-QuestionD0301
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D03.02") }) | Test-QuestionD0302
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D03.03") }) | Test-QuestionD0303
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D03.04") }) | Test-QuestionD0304
        $results += ($Checklist.items | Where-Object { ($_.id -eq "D03.05") }) | Test-QuestionD0305

        # Handle all remaining Network subcategories with graph queries
        $Checklist.items | Where-Object { 
            ($_.category -eq "Network Topology and Connectivity") -and 
            ($_.subcategory -notin @("Firewall", "Hub and spoke", "Virtual WAN", "App delivery", "Encryption", "IP plan")) -and 
            $_.graph 
        } | ForEach-Object {
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

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    # Based on assumption that usually a hub and spoke can be identified if there's a vnet with 2 or more peering 
    # that have also either a vpn gateway or an expressroute gateway and if there's an azure firewall or an nva with IP forwarding in this vnet
    try {
        $maxPeeringsCount = 0
        $maxPeeringsVnet = $null
        $estimatedPercentageApplied = 0
        
        # Use cached data instead of direct Search-AzGraph call
        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/virtualnetworks' }
        
        foreach ($vnet in $virtualNetworks) {
            # Check if the virtual network has peerings
            $peerings = $vnet.Properties.virtualNetworkPeerings
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
            $vnetSpecialSubnets = $maxPeeringsVnet.Properties.subnets | Where-Object { $_.Name -eq "GatewaySubnet" -or $_.Name -eq "AzureFirewallSubnet" }
            
            # Check for devices with IP forwarding using cached data
            $networkInterfaces = $global:AzData.Resources | Where-Object { $_.Type -eq "microsoft.network/networkinterfaces" -and $_.Properties.enableIPForwarding -eq $true }
            $vnetDevicesWithIPForwarding = @()
            
            foreach ($nic in $networkInterfaces) {
                if ($nic.Properties.ipConfigurations -and $nic.Properties.ipConfigurations[0].Properties.subnet.id) {
                    $subnetId = $nic.Properties.ipConfigurations[0].Properties.subnet.id
                    $vnetId = $subnetId.Substring(0, $subnetId.IndexOf("/subnets/"))
                    
                    if ($vnetId -eq $maxPeeringsVnet.Id) {
                        $vnetDevicesWithIPForwarding += $nic
                    }
                }
            }
            
            if ($vnetSpecialSubnets -or $vnetDevicesWithIPForwarding) {
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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0102 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem, 
        [Object]$rawDataD0101
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        $hubVirtualNetworkId = $rawDataD0101.MaxPeeringsVnet.id
        
        # Use cached data instead of direct Search-AzGraph call
        $expressRouteGateways = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/expressRouteGateways' -and $_.Properties.virtualNetwork.id -eq $hubVirtualNetworkId }
        $vpnGateways = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/vpnGateways' -and $_.Properties.virtualNetwork.id -eq $hubVirtualNetworkId }
        $azureFirewalls = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/azureFirewalls' -and $_.Properties.virtualNetwork.id -eq $hubVirtualNetworkId }
        $networkInterfaces = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/networkInterfaces' -and $_.Properties.enableIPForwarding -eq $true }
        $privateDnsResolvers = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/privateDnsResolvers' -and $_.Properties.virtualNetwork.id -eq $hubVirtualNetworkId }
        
        # Filter NICs that are in the hub VNet
        $nvasInHub = @()
        foreach ($nic in $networkInterfaces) {
            if ($nic.Properties.ipConfigurations -and $nic.Properties.ipConfigurations[0].Properties.subnet.id) {
                $subnetId = $nic.Properties.ipConfigurations[0].Properties.subnet.id
                $vnetId = $subnetId.Substring(0, $subnetId.IndexOf("/subnets/"))
                
                if ($vnetId -eq $hubVirtualNetworkId) {
                    $nvasInHub += $nic
                }
            }
        }
        
        $expressRouteGatewayPresent = ($expressRouteGateways | Measure-Object).Count -gt 0
        $vpnGatewayPresent = ($vpnGateways | Measure-Object).Count -gt 0
        $azureFirewallPresent = ($azureFirewalls | Measure-Object).Count -gt 0
        $nvaPresent = ($nvasInHub | Measure-Object).Count -gt 0
        $privateDnsResolverPresent = ($privateDnsResolvers | Measure-Object).Count -gt 0

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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0103 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        
        # Use cached data instead of direct Search-AzGraph call
        $publicIPs = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/publicIPAddresses' }

        $protectedIPs = 0
        $totalIPs = $publicIPs.Count

        foreach ($ip in $publicIPs) {
            if ($ip.Properties.ddosSettings.protectionMode -eq 'Enabled') {
                $protectedIPs++
            }
            elseif ($ip.Properties.ddosSettings.protectionMode -eq 'VirtualNetworkInherited' -and $ip.Properties.ipConfiguration.id) {
                # Find the VNet this IP belongs to and check if DDoS protection is enabled
                $ipConfigId = $ip.Properties.ipConfiguration.id
                $subnetId = $ipConfigId.Substring(0, $ipConfigId.LastIndexOf("/"))
                $vnetId = $subnetId.Substring(0, $subnetId.IndexOf("/subnets/"))
                
                $virtualNetwork = $global:AzData.Resources | Where-Object { $_.Id -eq $vnetId -and $_.Type -eq 'microsoft.network/virtualnetworks' } | Select-Object -First 1
                if ($virtualNetwork -and $virtualNetwork.Properties.enableDdosProtection -eq $true) {
                    $protectedIPs++
                }
            }
        }

        if ($totalIPs -gt 0) { 
            $estimatedPercentageApplied = ($protectedIPs / $totalIPs) * 100 
        } 

        $rawData = @{
            "PublicIPs"                  = $publicIPs
            "TotalIPs"                   = $totalIPs
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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0103HS {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0

        # Use cached data to check for NVAs (Network Virtual Appliances)
        $networkInterfaces = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/networkInterfaces' -and $_.Properties.enableIPForwarding -eq $true }
        $nvaPresent = ($networkInterfaces | Measure-Object).Count -gt 0

        if ($nvaPresent) {
            # Manual verification is required as we cannot automatically determine NVA filtering capabilities
            $status = [Status]::ManualVerificationRequired
        }
        else {
            $status = [Status]::NotImplemented
        }

        $rawData = @{
            "nvaPresent" = $nvaPresent
            "NetworkInterfaces" = $networkInterfaces
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0104 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0

        # Use cached data instead of direct Search-AzGraph call
        $expressRouteGateways = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/expressRouteGateways' }
        $vpnGateways = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/vpnGateways' }

        $routeServerPotentialVnets = @()

        foreach ($expressRouteGateway in $expressRouteGateways) {
            foreach ($vpnGateway in $vpnGateways) {
                if ($expressRouteGateway.Properties.virtualNetwork.id -eq $vpnGateway.Properties.virtualNetwork.id) {
                    $routeServerPotentialVnets += $expressRouteGateway.Properties.virtualNetwork.id
                }
            }
        }

        if ($routeServerPotentialVnets.Count -gt 0) {
            # Manual verification is required to check if Route Server is actually deployed
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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0106 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        
        # Use cached data instead of direct Search-AzGraph call
        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/virtualnetworks' }
        $vnetPairs = @()
        
        foreach ($vnet in $virtualNetworks) {
            # Check if the virtual network has peerings
            $peerings = $vnet.Properties.virtualNetworkPeerings
            if ($null -ne $peerings) {
                foreach ($peering in $peerings) {

                    $peeredVnetId = $peering.Properties.remoteVirtualNetwork.id
                    $peeredVnet = $global:AzData.Resources | Where-Object { $_.Id -eq $peeredVnetId -and $_.Type -eq 'microsoft.network/virtualnetworks' } | Select-Object -First 1
                    
                    if ($peeredVnet -and $peeredVnet.Location -eq $vnet.Location) {
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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0107 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    )

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        
        # Use cached data instead of direct Search-AzGraph call
        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/virtualnetworks' }
        $nsgs = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/networksecuritygroups' }
        $flowLogs = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/networkwatchers/flowlogs' }

        $enabledFlowLogsResources = @()
        $disabledFlowLogsResources = @()

        foreach ($vnet in $virtualNetworks) {
            $vnetFlowLog = $flowLogs | Where-Object { $_.Properties.targetResourceId -eq $vnet.Id -and $_.Properties.enabled -eq $true }
            if ($vnetFlowLog) {
                $enabledFlowLogsResources += $vnet.Id
            }
            else {
                $disabledFlowLogsResources += $vnet.Id
            }
        }

        foreach ($nsg in $nsgs) {
            $nsgFlowLog = $flowLogs | Where-Object { $_.Properties.targetResourceId -eq $nsg.Id -and $_.Properties.enabled -eq $true }
            if ($nsgFlowLog) {
                $enabledFlowLogsResources += $nsg.Id
            }
            else {
                $disabledFlowLogsResources += $nsg.Id
            }
        }

        $totalResources = $virtualNetworks.Count + $nsgs.Count
        if ($totalResources -gt 0) {
            $estimatedPercentageApplied = ($enabledFlowLogsResources.Count / $totalResources) * 100
        }

        $rawData = @{
            "EnabledFlowLogsResources"  = $enabledFlowLogsResources
            "DisabledFlowLogsResources" = $disabledFlowLogsResources
            "FlowLogs"                  = $flowLogs
            "TotalResources"            = $totalResources
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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0201 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    ) 

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"
    $status = [Status]::Unknown

    try {
        $estimatedPercentageApplied = 0
        
        # Check for ExpressRoute Direct circuits with MACsec configuration
        $expressRouteDirectCircuits = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/expressrouteports' }
        
        if ($expressRouteDirectCircuits.Count -gt 0) {
            $macsecEnabledCount = 0
            
            foreach ($circuit in $expressRouteDirectCircuits) {
                # Check if MACsec is enabled
                if ($circuit.Properties.links) {
                    $hasActiveMacsec = $false
                    foreach ($link in $circuit.Properties.links) {
                        if ($link.properties.macSecConfig -and $link.properties.macSecConfig.cipherSuite -and $link.properties.macSecConfig.cknSecretIdentifier) {
                            $hasActiveMacsec = $true
                            break
                        }
                    }
                    if ($hasActiveMacsec) {
                        $macsecEnabledCount++
                    }
                }
            }
            
            if ($macsecEnabledCount -gt 0) {
                $estimatedPercentageApplied = ($macsecEnabledCount / $expressRouteDirectCircuits.Count) * 100
                if ($estimatedPercentageApplied -eq 100) {
                    $status = [Status]::Implemented
                } else {
                    $status = [Status]::PartiallyImplemented
                }
            } else {
                $status = [Status]::NotImplemented
            }
            
            $rawData = @{
                "ExpressRouteDirectCircuits" = $expressRouteDirectCircuits
                "MacsecEnabledCount" = $macsecEnabledCount
                "TotalCircuits" = $expressRouteDirectCircuits.Count
            }
        } else {
            # No ExpressRoute Direct circuits found
            $status = [Status]::NotApplicable
            $rawData = @{
                "ExpressRouteDirectCircuits" = @()
                "Note" = "No ExpressRoute Direct circuits found - MACsec not applicable"
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0202 {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Object]$checklistItem
    ) 

    Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

    $estimatedPercentageApplied = 0
    try {
        # Use cached data instead of direct Search-AzGraph call
        $expressRouteDirectCircuits = $global:AzData.Resources | Where-Object { $_.Type -eq 'microsoft.network/expressrouteports' }
        
        if ($expressRouteDirectCircuits.Count -eq 0) {
            $expressRouteGateways = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/expressRouteGateways' }
            
            if ($expressRouteGateways.Count -gt 0) {
                $vpnGateways = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/vpnGateways' }
                $vpnGatewayPresent = $vpnGateways | Where-Object { $_.Properties.virtualNetwork.id -eq $expressRouteGateways[0].Properties.virtualNetwork.id } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
                
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

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# Hub and Spoke Functions for missing D01.08-D01.15

function Test-QuestionD0108 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        # Get all virtual networks with Route Server subnets
        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            $routeServerSubnets = @()
            $compliantSubnets = 0
            $totalRouteServerSubnets = 0

            foreach ($vnet in $virtualNetworks) {
                $subnets = $vnet.Properties.subnets
                if ($subnets) {
                    foreach ($subnet in $subnets) {
                        if ($subnet.name -eq "RouteServerSubnet") {
                            $totalRouteServerSubnets++
                            $addressPrefix = $subnet.properties.addressPrefix
                            $prefixLength = [int]($addressPrefix -split '/')[1]
                            
                            $isCompliant = $prefixLength -le 27
                            if ($isCompliant) {
                                $compliantSubnets++
                            }

                            $routeServerSubnets += @{
                                VNetName = $vnet.Name
                                VNetId = $vnet.Id
                                SubnetName = $subnet.name
                                AddressPrefix = $addressPrefix
                                PrefixLength = $prefixLength
                                IsCompliant = $isCompliant
                            }
                        }
                    }
                }
            }

            if ($totalRouteServerSubnets -eq 0) {
                $status = [Status]::NotAvailable
                $rawData = "No Route Server subnets found"
            }
            else {
                $estimatedPercentageApplied = [math]::Round(($compliantSubnets / $totalRouteServerSubnets) * 100, 2)
                
                if ($compliantSubnets -eq $totalRouteServerSubnets) {
                    $status = [Status]::Passed
                }
                elseif ($compliantSubnets -gt 0) {
                    $status = [Status]::Warning
                }
                else {
                    $status = [Status]::Failed
                }

                $rawData = @{
                    "RouteServerSubnets" = $routeServerSubnets
                    "TotalRouteServerSubnets" = $totalRouteServerSubnets
                    "CompliantSubnets" = $compliantSubnets
                }
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0109 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::Manual
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        # This requires manual verification as it involves architectural decisions
        # about multi-region hub-and-spoke topologies
        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            # Analyze VNet peerings to identify potential hub networks
            $hubCandidates = @()
            $regionGroups = $virtualNetworks | Group-Object -Property Location

            foreach ($vnet in $virtualNetworks) {
                $peerings = $vnet.Properties.virtualNetworkPeerings
                if ($peerings -and ($peerings | Measure-Object).Count -gt 2) {
                    # Networks with multiple peerings are likely hub candidates
                    $hubCandidates += @{
                        VNetName = $vnet.Name
                        VNetId = $vnet.Id
                        Location = $vnet.Location
                        PeeringCount = ($peerings | Measure-Object).Count
                        Peerings = $peerings
                    }
                }
            }

            $rawData = @{
                "HubCandidates" = $hubCandidates
                "RegionCount" = ($regionGroups | Measure-Object).Count
                "RegionGroups" = $regionGroups | ForEach-Object { 
                    @{
                        Region = $_.Name
                        VNetCount = $_.Count
                    }
                }
                "ManualVerificationRequired" = "Review hub-and-spoke architecture across regions and verify global VNet peerings between hub VNets"
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0110 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::Manual
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        # Check for Network Watcher and related monitoring resources
        $networkWatchers = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/networkWatchers' }
        $connectionMonitors = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/networkWatchers/connectionMonitors' }
        $trafficAnalytics = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/networkSecurityGroups' -and $_.Properties.flowLogs }

        if (($networkWatchers | Measure-Object).Count -eq 0) {
            $status = [Status]::Failed
            $rawData = "No Network Watcher resources found. Azure Monitor for Networks requires Network Watcher to be enabled."
        }
        else {
            $rawData = @{
                "NetworkWatchers" = $networkWatchers | ForEach-Object {
                    @{
                        Name = $_.Name
                        Id = $_.Id
                        Location = $_.Location
                        ProvisioningState = $_.Properties.provisioningState
                    }
                }
                "ConnectionMonitors" = $connectionMonitors | Measure-Object | Select-Object -ExpandProperty Count
                "ManualVerificationRequired" = "Verify Azure Monitor for Networks is configured and being used for end-to-end network monitoring"
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0111 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            $vnetPeeringCounts = @()
            $compliantVNets = 0
            $totalVNets = 0

            foreach ($vnet in $virtualNetworks) {
                $peerings = $vnet.Properties.virtualNetworkPeerings
                $peeringCount = if ($peerings) { ($peerings | Measure-Object).Count } else { 0 }
                
                # Check if VNet has high peering count (potential hub)
                if ($peeringCount -gt 10) {  # Only check VNets that might be hubs
                    $totalVNets++
                    $isCompliant = $peeringCount -lt 450  # Set threshold at 450 (below 500 limit)
                    
                    if ($isCompliant) {
                        $compliantVNets++
                    }

                    $vnetPeeringCounts += @{
                        VNetName = $vnet.Name
                        VNetId = $vnet.Id
                        Location = $vnet.Location
                        PeeringCount = $peeringCount
                        IsCompliant = $isCompliant
                        IsHubCandidate = $peeringCount -gt 10
                    }
                }
            }

            if ($totalVNets -eq 0) {
                $status = [Status]::NotAvailable
                $rawData = "No hub VNet candidates found (VNets with >10 peerings)"
            }
            else {
                $estimatedPercentageApplied = [math]::Round(($compliantVNets / $totalVNets) * 100, 2)
                
                if ($compliantVNets -eq $totalVNets) {
                    $status = [Status]::Passed
                }
                elseif ($compliantVNets -gt 0) {
                    $status = [Status]::Warning
                }
                else {
                    $status = [Status]::Failed
                }

                $rawData = @{
                    "VNetPeeringCounts" = $vnetPeeringCounts
                    "TotalHubCandidates" = $totalVNets
                    "CompliantVNets" = $compliantVNets
                    "PeeringLimit" = 500
                    "RecommendedThreshold" = 450
                }
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0112 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
         Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $routeTables = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/routeTables' }
        
        if (($routeTables | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No route tables found"
        }
        else {
            $routeTableCounts = @()
            $compliantRouteTables = 0
            $totalRouteTables = ($routeTables | Measure-Object).Count

            foreach ($routeTable in $routeTables) {
                $routes = $routeTable.Properties.routes
                $routeCount = if ($routes) { ($routes | Measure-Object).Count } else { 0 }
                
                $isCompliant = $routeCount -lt 360  # Recommended threshold below 400 limit
                
                if ($isCompliant) {
                    $compliantRouteTables++
                }

                $routeTableCounts += @{
                    RouteTableName = $routeTable.Name
                    RouteTableId = $routeTable.Id
                    Location = $routeTable.Location
                    RouteCount = $routeCount
                    IsCompliant = $isCompliant
                }
            }

            $estimatedPercentageApplied = [math]::Round(($compliantRouteTables / $totalRouteTables) * 100, 2)
            
            if ($compliantRouteTables -eq $totalRouteTables) {
                $status = [Status]::Passed
            }
            elseif ($compliantRouteTables -gt 0) {
                $status = [Status]::Warning
            }
            else {
                $status = [Status]::Failed
            }

            $rawData = @{
                "RouteTableCounts" = $routeTableCounts
                "TotalRouteTables" = $totalRouteTables
                "CompliantRouteTables" = $compliantRouteTables
                "RouteLimit" = 400
                "RecommendedThreshold" = 360
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0113 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            $peeringConfigurations = @()
            $compliantPeerings = 0
            $totalPeerings = 0

            foreach ($vnet in $virtualNetworks) {
                $peerings = $vnet.Properties.virtualNetworkPeerings
                if ($peerings) {
                    foreach ($peering in $peerings) {
                        $totalPeerings++
                        $allowVirtualNetworkAccess = $peering.properties.allowVirtualNetworkAccess
                        
                        $isCompliant = $allowVirtualNetworkAccess -eq $true
                        if ($isCompliant) {
                            $compliantPeerings++
                        }

                        $peeringConfigurations += @{
                            VNetName = $vnet.Name
                            VNetId = $vnet.Id
                            PeeringName = $peering.name
                            AllowVirtualNetworkAccess = $allowVirtualNetworkAccess
                            RemoteVirtualNetwork = $peering.properties.remoteVirtualNetwork.id
                            IsCompliant = $isCompliant
                        }
                    }
                }
            }

            if ($totalPeerings -eq 0) {
                $status = [Status]::NotAvailable
                $rawData = "No VNet peerings found"
            }
            else {
                $estimatedPercentageApplied = [math]::Round(($compliantPeerings / $totalPeerings) * 100, 2)
                
                if ($compliantPeerings -eq $totalPeerings) {
                    $status = [Status]::Passed
                }
                elseif ($compliantPeerings -gt 0) {
                    $status = [Status]::Warning
                }
                else {
                    $status = [Status]::Failed
                }

                $rawData = @{
                    "PeeringConfigurations" = $peeringConfigurations
                    "TotalPeerings" = $totalPeerings
                    "CompliantPeerings" = $compliantPeerings
                }
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0114 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $loadBalancers = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/loadBalancers' }
        
        if (($loadBalancers | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No load balancers found"
        }
        else {
            $loadBalancerConfigurations = @()
            $compliantLoadBalancers = 0
            $totalLoadBalancers = ($loadBalancers | Measure-Object).Count

            foreach ($lb in $loadBalancers) {
                $skuName = $lb.sku.name
                $isStandardSku = $skuName -eq "Standard"
                
                # Check zone redundancy for frontend IP configurations
                $frontendConfigs = $lb.Properties.frontendIPConfigurations
                $zoneRedundantConfigs = 0
                $totalConfigs = 0
                
                if ($frontendConfigs) {
                    foreach ($feConfig in $frontendConfigs) {
                        $totalConfigs++
                        
                        # Check if it's zone redundant (has multiple zones or no zones specified for Standard LB)
                        $zones = $feConfig.zones
                        $isZoneRedundant = $false
                        
                        if ($isStandardSku) {
                            if (!$zones -or ($zones -and ($zones | Measure-Object).Count -gt 1)) {
                                $isZoneRedundant = $true
                                $zoneRedundantConfigs++
                            }
                        }
                    }
                }
                
                $isCompliant = $isStandardSku -and ($totalConfigs -eq 0 -or $zoneRedundantConfigs -eq $totalConfigs)
                if ($isCompliant) {
                    $compliantLoadBalancers++
                }

                $loadBalancerConfigurations += @{
                    LoadBalancerName = $lb.Name
                    LoadBalancerId = $lb.Id
                    Location = $lb.Location
                    SkuName = $skuName
                    IsStandardSku = $isStandardSku
                    TotalFrontendConfigs = $totalConfigs
                    ZoneRedundantConfigs = $zoneRedundantConfigs
                    IsCompliant = $isCompliant
                }
            }

            $estimatedPercentageApplied = [math]::Round(($compliantLoadBalancers / $totalLoadBalancers) * 100, 2)
            
            if ($compliantLoadBalancers -eq $totalLoadBalancers) {
                $status = [Status]::Passed
            }
            elseif ($compliantLoadBalancers -gt 0) {
                $status = [Status]::Warning
            }
            else {
                $status = [Status]::Failed
            }

            $rawData = @{
                "LoadBalancerConfigurations" = $loadBalancerConfigurations
                "TotalLoadBalancers" = $totalLoadBalancers
                "CompliantLoadBalancers" = $compliantLoadBalancers
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0115 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $loadBalancers = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/loadBalancers' }
        
        if (($loadBalancers | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No load balancers found"
        }
        else {
            $loadBalancerBackendPools = @()
            $compliantLoadBalancers = 0
            $totalLoadBalancers = ($loadBalancers | Measure-Object).Count

            foreach ($lb in $loadBalancers) {
                $backendPools = $lb.Properties.backendAddressPools
                $hasValidBackendPools = $false
                
                if ($backendPools) {
                    foreach ($pool in $backendPools) {
                        $backendAddresses = $pool.properties.loadBalancerBackendAddresses
                        $addressCount = if ($backendAddresses) { ($backendAddresses | Measure-Object).Count } else { 0 }
                        
                        if ($addressCount -ge 2) {
                            $hasValidBackendPools = $true
                        }
                        
                        $loadBalancerBackendPools += @{
                            LoadBalancerName = $lb.Name
                            LoadBalancerId = $lb.Id
                            PoolName = $pool.name
                            BackendAddressCount = $addressCount
                            IsCompliant = $addressCount -ge 2
                        }
                    }
                }
                else {
                    $loadBalancerBackendPools += @{
                        LoadBalancerName = $lb.Name
                        LoadBalancerId = $lb.Id
                        PoolName = "No backend pools"
                        BackendAddressCount = 0
                        IsCompliant = $false
                    }
                }
                
                if ($hasValidBackendPools) {
                    $compliantLoadBalancers++
                }
            }

            $estimatedPercentageApplied = [math]::Round(($compliantLoadBalancers / $totalLoadBalancers) * 100, 2)
            
            if ($compliantLoadBalancers -eq $totalLoadBalancers) {
                $status = [Status]::Passed
            }
            elseif ($compliantLoadBalancers -gt 0) {
                $status = [Status]::Warning
            }
            else {
                $status = [Status]::Failed
            }

            $rawData = @{
                "LoadBalancerBackendPools" = $loadBalancerBackendPools
                "TotalLoadBalancers" = $totalLoadBalancers
                "CompliantLoadBalancers" = $compliantLoadBalancers
                "MinimumBackendInstances" = 2
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

# IP Plan Functions for D03.01-D03.05

function Test-QuestionD0301 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::Manual
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            $vnetAddressSpaces = @()
            $overlappingPairs = @()

            # Collect all VNet address spaces
            foreach ($vnet in $virtualNetworks) {
                $addressPrefixes = $vnet.Properties.addressSpace.addressPrefixes
                if ($addressPrefixes) {
                    foreach ($prefix in $addressPrefixes) {
                        $vnetAddressSpaces += @{
                            VNetName = $vnet.Name
                            VNetId = $vnet.Id
                            Location = $vnet.Location
                            AddressPrefix = $prefix
                        }
                    }
                }
            }

            # Check for potential overlaps (this is a simplified check)
            for ($i = 0; $i -lt $vnetAddressSpaces.Count; $i++) {
                for ($j = $i + 1; $j -lt $vnetAddressSpaces.Count; $j++) {
                    $space1 = $vnetAddressSpaces[$i]
                    $space2 = $vnetAddressSpaces[$j]
                    
                    # Simple overlap detection - same prefix or very similar
                    if ($space1.AddressPrefix -eq $space2.AddressPrefix) {
                        $overlappingPairs += @{
                            VNet1 = $space1.VNetName
                            VNet1Location = $space1.Location
                            VNet2 = $space2.VNetName
                            VNet2Location = $space2.Location
                            OverlappingPrefix = $space1.AddressPrefix
                        }
                    }
                }
            }

            $rawData = @{
                "VNetAddressSpaces" = $vnetAddressSpaces
                "PotentialOverlaps" = $overlappingPairs
                "ManualVerificationRequired" = "Manual verification required to ensure no overlapping IP address spaces across Azure regions and on-premises locations"
                "TotalVNets" = ($virtualNetworks | Measure-Object).Count
                "TotalAddressSpaces" = $vnetAddressSpaces.Count
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0302 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            $vnetAddressAnalysis = @()
            $compliantVNets = 0
            $totalVNets = 0

            foreach ($vnet in $virtualNetworks) {
                $addressPrefixes = $vnet.Properties.addressSpace.addressPrefixes
                if ($addressPrefixes) {
                    $vnetCompliant = $true
                    $prefixAnalysis = @()
                    
                    foreach ($prefix in $addressPrefixes) {
                        $totalVNets++
                        
                        # Check if address is in RFC 1918 ranges
                        # 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
                        $isRFC1918 = $false
                        
                        if ($prefix -match '^10\.') {
                            $isRFC1918 = $true
                        }
                        elseif ($prefix -match '^172\.(1[6-9]|2[0-9]|3[01])\.') {
                            $isRFC1918 = $true
                        }
                        elseif ($prefix -match '^192\.168\.') {
                            $isRFC1918 = $true
                        }
                        
                        if (!$isRFC1918) {
                            $vnetCompliant = $false
                        }
                        
                        $prefixAnalysis += @{
                            AddressPrefix = $prefix
                            IsRFC1918 = $isRFC1918
                        }
                    }
                    
                    if ($vnetCompliant) {
                        $compliantVNets++
                    }
                    
                    $vnetAddressAnalysis += @{
                        VNetName = $vnet.Name
                        VNetId = $vnet.Id
                        Location = $vnet.Location
                        PrefixAnalysis = $prefixAnalysis
                        IsCompliant = $vnetCompliant
                    }
                }
            }

            if ($totalVNets -eq 0) {
                $status = [Status]::NotAvailable
                $rawData = "No VNet address prefixes found"
            }
            else {
                $estimatedPercentageApplied = [math]::Round(($compliantVNets / ($vnetAddressAnalysis | Measure-Object).Count) * 100, 2)
                
                if ($compliantVNets -eq ($vnetAddressAnalysis | Measure-Object).Count) {
                    $status = [Status]::Passed
                }
                elseif ($compliantVNets -gt 0) {
                    $status = [Status]::Warning
                }
                else {
                    $status = [Status]::Failed
                }

                $rawData = @{
                    "VNetAddressAnalysis" = $vnetAddressAnalysis
                    "TotalVNets" = ($vnetAddressAnalysis | Measure-Object).Count
                    "CompliantVNets" = $compliantVNets
                    "RFC1918Ranges" = @("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16")
                }
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0303 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            $vnetSizeAnalysis = @()
            $compliantVNets = 0
            $totalVNets = 0

            foreach ($vnet in $virtualNetworks) {
                $addressPrefixes = $vnet.Properties.addressSpace.addressPrefixes
                if ($addressPrefixes) {
                    $vnetCompliant = $true
                    $prefixAnalysis = @()
                    
                    foreach ($prefix in $addressPrefixes) {
                        $totalVNets++
                        
                        # Extract subnet mask
                        $maskBits = [int]($prefix -split '/')[1]
                        
                        # Check if mask is appropriate (not unnecessarily large like /16)
                        # /16 provides 65536 addresses, which is often too large
                        $isAppropriateSize = $maskBits -gt 16
                        
                        if (!$isAppropriateSize) {
                            $vnetCompliant = $false
                        }
                        
                        $prefixAnalysis += @{
                            AddressPrefix = $prefix
                            MaskBits = $maskBits
                            AddressCount = [math]::Pow(2, (32 - $maskBits))
                            IsAppropriateSize = $isAppropriateSize
                        }
                    }
                    
                    if ($vnetCompliant) {
                        $compliantVNets++
                    }
                    
                    $vnetSizeAnalysis += @{
                        VNetName = $vnet.Name
                        VNetId = $vnet.Id
                        Location = $vnet.Location
                        PrefixAnalysis = $prefixAnalysis
                        IsCompliant = $vnetCompliant
                    }
                }
            }

            if ($totalVNets -eq 0) {
                $status = [Status]::NotAvailable
                $rawData = "No VNet address prefixes found"
            }
            else {
                $estimatedPercentageApplied = [math]::Round(($compliantVNets / ($vnetSizeAnalysis | Measure-Object).Count) * 100, 2)
                
                if ($compliantVNets -eq ($vnetSizeAnalysis | Measure-Object).Count) {
                    $status = [Status]::Passed
                }
                elseif ($compliantVNets -gt 0) {
                    $status = [Status]::Warning
                }
                else {
                    $status = [Status]::Failed
                }

                $rawData = @{
                    "VNetSizeAnalysis" = $vnetSizeAnalysis
                    "TotalVNets" = ($vnetSizeAnalysis | Measure-Object).Count
                    "CompliantVNets" = $compliantVNets
                    "RecommendedMinMask" = 17
                    "LargeSizeThreshold" = 16
                }
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0304 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::Manual
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $virtualNetworks = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/virtualNetworks' }
        
        if (($virtualNetworks | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No virtual networks found"
        }
        else {
            # Group VNets by region to identify potential prod/DR pairs
            $regionGroups = $virtualNetworks | Group-Object -Property Location
            $vnetsByRegion = @{
            }

            foreach ($group in $regionGroups) {
                $vnetsByRegion[$group.Name] = $group.Group
            }

            $regionalAnalysis = @()
            foreach ($region in $vnetsByRegion.Keys) {
                $vnetsInRegion = $vnetsByRegion[$region]
                $addressSpaces = @()
                
                foreach ($vnet in $vnetsInRegion) {
                    $addressPrefixes = $vnet.Properties.addressSpace.addressPrefixes
                    if ($addressPrefixes) {
                        foreach ($prefix in $addressPrefixes) {
                            $addressSpaces += @{
                                VNetName = $vnet.Name
                                VNetId = $vnet.Id
                                AddressPrefix = $prefix
                            }
                        }
                    }
                }
                
                $regionalAnalysis += @{
                    Region = $region
                    VNetCount = $vnetsInRegion.Count
                    AddressSpaces = $addressSpaces
                }
            }

            $rawData = @{
                "RegionalAnalysis" = $regionalAnalysis
                "TotalRegions" = $regionGroups.Count
                "ManualVerificationRequired" = "Manual verification required to ensure no overlapping IP address ranges between production and disaster recovery sites"
                "Recommendations" = @(
                    "Review IP address allocation across regions",
                    "Ensure production and DR sites use different IP ranges",
                    "Consider Site Recovery networking requirements",
                    "Document IP allocation strategy"
                )
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}

function Test-QuestionD0305 {
    [CmdletBinding()
    ]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [object]$checklistItem
    )

    $status = [Status]::NotAvailable
    $estimatedPercentageApplied = 0
    $rawData = $null

    try {
        Write-AssessmentProgress "Assessing question: $($checklistItem.id) - $($checklistItem.text)"

        $publicIPs = $global:AzData.Resources | Where-Object { $_.Type -eq 'Microsoft.Network/publicIPAddresses' }
        
        if (($publicIPs | Measure-Object).Count -eq 0) {
            $status = [Status]::NotAvailable
            $rawData = "No public IP addresses found"
        }
        else {
            $publicIPAnalysis = @()
            $compliantPublicIPs = 0
            $totalPublicIPs = ($publicIPs | Measure-Object).Count

            foreach ($pip in $publicIPs) {
                $skuName = $pip.sku.name
                $skuTier = $pip.sku.tier
                $zones = $pip.zones
                
                $isStandardSku = $skuName -eq "Standard"
                $isRegionalTier = $skuTier -eq "Regional"
                
                # Check zone redundancy
                $isZoneRedundant = $false
                $zoneConfig = "Non-zonal"
                
                if ($zones) {
                    if (($zones | Measure-Object).Count -gt 1) {
                        $isZoneRedundant = $true
                        $zoneConfig = "Zone-redundant"
                    }
                    else {
                        $zoneConfig = "Zonal ($($zones -join ','))"
                    }
                }
                
                # For Standard SKU regional tier, zone-redundant is preferred
                $isCompliant = $isStandardSku -and (!$isRegionalTier -or $isZoneRedundant)
                
                if ($isCompliant) {
                    $compliantPublicIPs++
                }

                $publicIPAnalysis += @{
                    PublicIPName = $pip.Name
                    PublicIPId = $pip.Id
                    Location = $pip.Location
                    SkuName = $skuName
                    SkuTier = $skuTier
                    ZoneConfiguration = $zoneConfig
                    IsStandardSku = $isStandardSku
                    IsZoneRedundant = $isZoneRedundant
                    IsCompliant = $isCompliant
                }
            }

            $estimatedPercentageApplied = [math]::Round(($compliantPublicIPs / $totalPublicIPs) * 100, 2)
            
            if ($compliantPublicIPs -eq $totalPublicIPs) {
                $status = [Status]::Passed
            }
            elseif ($compliantPublicIPs -gt 0) {
                $status = [Status]::Warning
            }
            else {
                $status = [Status]::Failed
            }

            $rawData = @{
                "PublicIPAnalysis" = $publicIPAnalysis
                "TotalPublicIPs" = $totalPublicIPs
                "CompliantPublicIPs" = $compliantPublicIPs
                "RecommendedConfiguration" = "Standard SKU with zone-redundant deployment"
            }
        }
    }
    catch {
        Write-ErrorLog -QuestionID $checklistItem.id -QuestionText $checklistItem.text -FunctionName $MyInvocation.MyCommand -ErrorMessage $_.Exception.Message
        $status = [Status]::Error
        $estimatedPercentageApplied = 0
        $rawData = $_.Exception.Message
    }

    $result = Set-EvaluationResultObject -status $status.ToString() -estimatedPercentageApplied $estimatedPercentageApplied -checklistItem $checklistItem -rawData $rawData

    return $result
}
