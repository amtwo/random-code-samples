Param (
    [string] $secret,
    [string] $identity = "Shared Access Signature",
    [int] $credCount = 500
)

Import-Module .\Get-MSSQLCredentialPasswords.psm1

for ($i = 1; $i -le $credCount; $i++) {
    Invoke-Sqlcmd -ServerInstance localhost -Query "CREATE CREDENTIAL AM2_$($i) WITH IDENTITY='$($identity)',SECRET='$($secret)';"
}

Get-MSSQLCredentialPasswords | Where-Object Password -ne $secret

for ($i = 1; $i -le $credCount; $i++) {
    Invoke-Sqlcmd -ServerInstance localhost -Query "DROP CREDENTIAL AM2_$($i);"
    
