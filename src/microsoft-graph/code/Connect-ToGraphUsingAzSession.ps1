# On older versions of Microsoft.Graph use:
Connect-MgGraph -AccessToken (Get-AzAccessToken -ResourceTypeName MSGraph).Token

# On latest version of Microsoft.Graph use:
Connect-MgGraph -AccessToken (ConvertTo-SecureString -String (Get-AzAccessToken -ResourceTypeName MSGraph).Token -AsPlainText)
