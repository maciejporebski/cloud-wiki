param(
    [string]$OutputDirectory = 'policyDefinitions'
)

$resources = Search-AzGraph -Query 'Resources | project id, type, kind'
$resourcesByType = $resources | Group-Object -Property type, kind
$token = Get-AzAccessToken
$headers = @{ Authorization = "Bearer $($token.Token)" }

foreach ($resourceType in $resourcesByType) {

    $getDiagnosticTypesReq = Invoke-WebRequest `
        -Uri "https://management.azure.com/$($resourceType.Group[0].id)/providers/Microsoft.Insights/diagnosticSettingsCategories?api-version=2021-05-01-preview" `
        -Headers $headers -SkipHttpErrorCheck
    $diagnosticTypes = $getDiagnosticTypesReq.Content | ConvertFrom-Json

    if ($getDiagnosticTypesReq.StatusCode -eq 200) {

        $type = $resourceType.Group[0].type
        $kind = $resourceType.Group[0].kind
        $logTypes = $diagnosticTypes.value | Where-Object { $_.properties.categoryType -eq 'logs' }
        $metricTypes = $diagnosticTypes.value | Where-Object { $_.properties.categoryType -eq 'metrics' }

        if ($kind -ne '') {
            $typeDescription = "$($type) ($($kind))"
            $id = "$($type.Replace('/', '-').Replace('.','-'))-$($kind.Replace('/', '-').Replace(',', '-'))"
        }
        else {
            $typeDescription = $type
            $id = "$($type.Replace('/', '-').Replace('.','-'))"
        }

        $policy = [pscustomobject]@{
            "name"       = $id
            "type"       = "Microsoft.Authorization/policyDefinitions"
            "properties" = [pscustomobject]@{
                "displayName" = "Send $($typeDescription) logs to Log Analytics"
                "mode"        = "Indexed"
                "description" = "Send $($typeDescription) logs to Log Analytics"
                "metadata"    = [pscustomobject]@{
                    "category" = "Diagnostic Settings"
                }
                "parameters"  = [pscustomobject]@{
                    "effect"                = [pscustomobject]@{
                        "type"          = "String"
                        "metadata"      = [pscustomobject]@{
                            "displayName" = "Effect"
                            "description" = "Enable or disable the execution of the policy"
                        }
                        "allowedValues" = [pscustomobject]@(
                            "DeployIfNotExists",
                            "AuditIfNotExists",
                            "Disabled"
                        )
                        "defaultValue"  = "DeployIfNotExists"
                    }
                    "diagnosticSettingName" = [pscustomobject]@{
                        "type"         = "String"
                        "metadata"     = [pscustomobject]@{
                            "displayName" = "Diagnostic Setting Name"
                            "description" = "Diagnostic Setting Name"
                        }
                        "defaultValue" = "LogAnalytics"
                    }
                    "logAnalytics"          = [pscustomobject]@{
                        "type"     = "String"
                        "metadata" = [pscustomobject]@{
                            "displayName"       = "Log Analytics Workspace"
                            "description"       = "Log Analytics Workspace"
                            "strongType"        = "omsWorkspace"
                            "assignPermissions" = $true
                        }
                    }
                }
                "policyRule"  = [pscustomobject]@{
                    "if"   = [pscustomobject]@{
                        "allOf" = [pscustomobject]@(
                            [pscustomobject]@{
                                "field"  = "type"
                                "equals" = $type
                            }
                        )
                    }
                    "then" = [pscustomobject]@{
                        "effect"  = "[parameters('effect')]"
                        "details" = [pscustomobject]@{
                            "type"               = "Microsoft.Insights/diagnosticSettings"
                            "evaluationDelay"    = "AfterProvisioning"
                            "existenceCondition" = [pscustomobject]@{
                                "allOf" = [pscustomobject]@(
                                    [pscustomobject]@{
                                        "field"  = "Microsoft.Insights/diagnosticSettings/workspaceId"
                                        "equals" = "[parameters('logAnalytics')]"
                                    },
                                    [pscustomobject]@{
                                        "count"  = [pscustomobject]@{
                                            "field" = "Microsoft.Insights/diagnosticSettings/logs[*]"
                                            "where" = [pscustomobject]@{
                                                "field"  = "Microsoft.Insights/diagnosticSettings/logs[*].enabled"
                                                "equals" = $true
                                            }
                                        }
                                        "equals" = $logTypes.Count
                                    },
                                    [pscustomobject]@{
                                        "count"  = [pscustomobject]@{
                                            "field" = "Microsoft.Insights/diagnosticSettings/metrics[*]"
                                            "where" = [pscustomobject]@{
                                                "field"  = "Microsoft.Insights/diagnosticSettings/metrics[*].enabled"
                                                "equals" = $true
                                            }
                                        }
                                        "equals" = $metricTypes.Count
                                    }
                                )
                            }
                            "roleDefinitionIds"  = [pscustomobject]@(
                                "/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"
                            )
                            "deployment"         = [pscustomobject]@{
                                "properties" = [pscustomobject]@{
                                    "mode"       = "incremental"
                                    "template"   = [pscustomobject]@{
                                        "`$schema"       = "https://schema.management.azure.com/schemas/2019-08-01/deploymentTemplate.json#"
                                        "contentVersion" = "1.0.0.0"
                                        "parameters"     = [pscustomobject]@{
                                            "diagnosticSettingName" = [pscustomobject]@{
                                                "type" = "string"
                                            }
                                            "logAnalytics"          = [pscustomobject]@{
                                                "type" = "string"
                                            }
                                            "resourceName"          = [pscustomobject]@{
                                                "type" = "string"
                                            }
                                        }
                                        "variables"      = [pscustomobject]@{}
                                        "resources"      = [pscustomobject]@(
                                            [pscustomobject]@{
                                                "type"       = "$($type)/providers/diagnosticSettings"
                                                "apiVersion" = "2021-05-01-preview"
                                                "name"       = "[concat(parameters('resourceName'),'/','Microsoft.Insights/',parameters('diagnosticSettingName'))]"
                                                "properties" = [pscustomobject]@{
                                                    "workspaceId" = "[parameters('logAnalytics')]"
                                                    "logs"        = [pscustomobject]@()
                                                    "metrics"     = [pscustomobject]@()
                                                }
                                            }
                                        )
                                    }
                                    "parameters" = [pscustomobject]@{
                                        "diagnosticSettingName" = [pscustomobject]@{
                                            "value" = "[parameters('diagnosticSettingName')]"
                                        }
                                        "logAnalytics"          = [pscustomobject]@{
                                            "value" = "[parameters('logAnalytics')]"
                                        }
                                        "resourceName"          = [pscustomobject]@{
                                            "value" = "[field('name')]"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        foreach ($logType in $logTypes) {
            $policy.properties.policyRule.then.details.deployment.properties.template.resources[0].properties.logs += [pscustomobject]@{
                category = $logType.name
                enabled  = $true
            }
        }
        foreach ($metricType in $metricTypes) {
            $policy.properties.policyRule.then.details.deployment.properties.template.resources[0].properties.metrics += [pscustomobject]@{
                category = $metricType.name
                enabled  = $true
            }
        }

        $policy | ConvertTo-Json -Depth 15 | Out-File -FilePath "$($OutputDirectory)/$($id).json" -Encoding utf8
        Write-Host "Policy definition for $($typeDescription) created." -ForegroundColor Cyan
    }

    if ($diagnosticTypes.code -eq 'ResourceTypeNotSupported') {
        Write-Host $diagnosticTypes.message -ForegroundColor DarkYellow
    }
}
