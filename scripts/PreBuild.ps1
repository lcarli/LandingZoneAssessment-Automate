function Export-AzureTenantInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "scripts/tenant_info.json"
    )

    try {
        Write-Host "Getting info from tenant..."
        $tenant = Get-AzTenant -TenantId $TenantId

        $tenantInfo = @{
            Tenant = $tenant
            Subscriptions = @()
        }

        Write-Host "Getting subscriptions..."
        $subscriptions = Get-AzSubscription -TenantId $TenantId

        foreach ($subscription in $subscriptions) {
            Write-Host "Processing subscription: $($subscription.Name)..."
            $subscriptionInfo = @{
                Subscription = $subscription
                ResourceGroups = @()
            }

            Set-AzContext -SubscriptionId $subscription.Id -TenantId $TenantId

            $resourceGroups = Get-AzResourceGroup

            foreach ($rg in $resourceGroups) {
                Write-Host "Processing resource group: $($rg.ResourceGroupName)..."
                $rgInfo = @{
                    ResourceGroup = $rg
                    Resources = @()
                }

                $resources = Get-AzResource -ResourceGroupName $rg.ResourceGroupName

                foreach ($resource in $resources) {
                    $rgInfo.Resources += $resource
                }

                $subscriptionInfo.ResourceGroups += $rgInfo
            }

            $tenantInfo.Subscriptions += $subscriptionInfo
        }

        Write-Host "Saving JSON..."
        $json = $tenantInfo | ConvertTo-Json -Depth 100
        Set-Content -Path $OutputPath -Value $json -Encoding UTF8

        Write-Host "Exporting with success. File saved: $OutputPath"

    } catch {
        Write-Error "Error: $_"
    }
}