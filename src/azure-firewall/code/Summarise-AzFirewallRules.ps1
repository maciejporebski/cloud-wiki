param(
    [string]$FirewallName,
    [string]$ResourceGroupName,
    [string]$OutputPath = 'firewall-rules-summary.csv'
)

$fw = Get-AzFirewall -Name $FirewallName -ResourceGroupName $ResourceGroupName

$ruleSummaries = [hashtable]@{}

if ($null -ne $fw.FirewallPolicy.Id) {
    $fwPolicy = Get-AzFirewallPolicy -ResourceId $fw.FirewallPolicy.Id
    
    foreach ($ruleCollectionId in $fwPolicy.RuleCollectionGroups.Id) {
        $rcgName = $ruleCollectionId -split '/' | Select-Object -Last 1
        $ruleCollectionGroups = Get-AzFirewallPolicyRuleCollectionGroup -AzureFirewallPolicy $fwPolicy -Name $rcgName

        foreach ($rule in $ruleCollectionGroups.Properties.RuleCollection.Rules | Where-Object { $_.RuleType -in ('NetworkRule', 'ApplicationRule') }) {

            $destinations = $rule.DestinationAddresses + $rule.TargetFqdns | Where-Object { $null -ne $_ }
            $ports = $rule.Protocols.Port + $rule.DestinationPorts | Where-Object { $null -ne $_ }
            $sources = $rule.SourceAddresses + $rule.SourceIpGroups | Where-Object { $null -ne $_ }

            foreach ($destination in $destinations) {

                foreach ($port in $ports) {
                    $destinationString = "$($destination):$($port)"

                    if ($destinationString -like ":*") {
                        Write-Host "TEST"
                    }

                    if (!$ruleSummaries.ContainsKey($destinationString)) {
                        $ruleSummaries.Add($destinationString, @())
                    }
                    foreach ($source in $sources) {
                        $ruleSummaries[$destinationString] += $source
                    }
                    
                }
            }
        }
    }
}
else {
    foreach ($arc in $fw.ApplicationRuleCollections) {
        foreach ($rule in $arc.Rules) {
    
            foreach ($destinationFqdn in $rule.TargetFqdns) {
    
                foreach ($port in $rule.Protocols.Port) {
    
                    $destinationString = "$($destinationFqdn):$($port)"
                    if (!$ruleSummaries.ContainsKey($destinationString)) {
                        $ruleSummaries.Add($destinationString, @())
                    }
                    foreach ($source in $rule.SourceAddresses) {
                        $ruleSummaries[$destinationString] += $source
                    }
                    foreach ($source in $rule.SourceIpGroups) {
                        $ruleSummaries[$destinationString] += $source
                    }
    
                }
            }
        }
    }
    
    foreach ($nrc in $fw.NetworkRuleCollections) {
        foreach ($rule in $nrc.Rules) {
            foreach ($destinationAddress in $rule.DestinationAddresses) {
    
                foreach ($port in ($rule.DestinationPorts)) {
    
                    $destinationString = "$($destinationAddress):$($port)"
                    if (!$ruleSummaries.ContainsKey($destinationString)) {
                        $ruleSummaries.Add($destinationString, @())
                    }
                    foreach ($source in $rule.SourceAddresses) {
                        $ruleSummaries[$destinationString] += $source
                    }
                    foreach ($source in $rule.SourceIpGroups) {
                        $ruleSummaries[$destinationString] += $source
                    }
    
                }
            }
        }
    }
}

$ruleOutputs = [pscustomobject]@()
foreach ($key in $ruleSummaries.Keys) {
    
    $destParts = $key -split ':'

    $ruleOutputs += [pscustomobject]@{
        sources                 = $ruleSummaries[$key] -join ", "
        destination             = $destParts[0]
        port                    = $destParts[1]
        hasWildcardSources      = ($ruleSummaries[$key] -match [regex]::Escape('*')).count -gt 0
        hasWildcardDestinations = $key -match [regex]::Escape('*')
        hasWildcardPorts        = $destParts[1] -match [regex]::Escape('*')
    }
}

$ruleOutputs | Export-Csv $OutputPath