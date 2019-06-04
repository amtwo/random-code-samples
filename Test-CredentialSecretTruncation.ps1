<#
.SYNOPSIS
    This script will create credentials & test the secret to see that they are equal to the intended value.
.DESCRIPTION
    This script will create an arbitrary number of credentials using the name format of AM2_xxx and validate that the secret 
    saved in the database matches the value passed as a parameter. After testing, all created credentials will be deleted. 
    
    This script depends on having Get-MSSQLCredentialPasswords saved in the same directory as this script. 
    Get-MSSQLCredentialPasswords can be downloaded from GitHub:
    https://github.com/NetSPI/Powershell-Modules/blob/master/Get-MSSQLCredentialPasswords.psm1
    
.PARAMETER secret
    String to be used as the Secret in a series of CREATE CREDENTIAL statements.
.PARAMETER identity
    String to be used as the Indentity in a series of CREATE CREDENTIAL statements.
.PARAMETER credCount
    Number of CREATE CREDENTIAL statements to use

.EXAMPLE
    .\Test-CredentialSecretTruncation.ps1 -secret "SomePassword()123" -credCount 100
    This will create 100 credentials using the secret "SomePassword()123", and the default identity of "Shared Access Signature".
.NOTES
#>

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
    
