<#
.SYNOPSIS
    This script will generate CPU load, attempting to push CPU utilization to the requested percent.
.DESCRIPTION
    This script will generate CPU load, attempting to push CPU utilization to the requested percent.

    It will determine the total number of cores on the machine, and calculate the UtilizeCorePercent.
    The resulting number will be the number of workerthreads spawned.  For example, on a 16-core machine, 
    supplying 50 for UtilizeCorePercent will result in spawning 8 worker threads. Supplying a value
    greater than 100 is totally OK if you want more threads than logical cores. This can be useful if 
    you want to push CPU to 100%.

    If the percent does not result in a whole number for worker thread count, the script will round DOWN.
    Ex) On a 4-core system, a parameter value of 60 UtilizeCorePercent will generate only 2 worker threads.

    Once executed, it will prompt you to hit 'Y' to confirm that you want to run the script.

.PARAMETER UtilizeCorePercent
    Whole-number value representing a percentage (ex, "75" for 75%). This percent will be applied to the
    number of cores on the machine, and spawn that many threads.

.PARAMETER Cleanup
    instead of burning CPU, cleans up jobs from prior executions.


.INPUTS
    None.

.EXAMPLE
    .\Invoke-CPUWorkload.ps1 -UtilizeCorePercent 50

    This will execute a number of worker threads equal to 50% of the number of cores on the machine. On a 
    16-core machine, this will result in spawning 8 worker threads.

.NOTES

#>

[cmdletbinding(
        SupportsShouldProcess=$True,
        ConfirmImpact = 'High',
        DefaultParameterSetName='SpinUp'
)]

param(
    [parameter(
            mandatory=$true,
            ParameterSetName='SpinUp'
    )]
    [int]$UtilizeCorePercent,
    [parameter(
            mandatory=$false,
            ParameterSetName='SpinDown'
    )]
    [switch]$Cleanup
)

if ($Cleanup) {
    Write-Verbose "Stopping jobs"
    Stop-Job -Name "CPUWorkload*"
    $jobList = Get-Job -Name "CPUWorkload*"
    Get-Job  -Name "CPUWorkload*" | Receive-Job -AutoRemoveJob -Wait
    return $jobList
}

$cpuCount = (Get-WmiObject -class Win32_processor).NumberOfLogicalProcessors
$threadCount = [math]::floor($cpuCount*($UtilizeCorePercent/100))

Write-Verbose "Utilize Core Percent:  $UtilizeCorePercent"
Write-Verbose "Logical Core Count:    $cpuCount"
Write-Verbose "Worker Thread Count:   $threadCount"

Write-Warning "This script may generate significant CPU workload. This may cause the system to become unstable."
Write-Warning "Using CTRL+C will not end background execution of worker threads."
Write-Warning "To kill worker threads, close this host window, or use .\Submit-CPUWorkload.ps1 -Cleanup"

If ($PSCmdlet.ShouldProcess($UtilizeCorePercent)) {
    for ($t = 1; $t -le $threadCount; $t++) {
        $nul = Start-Job -Name "CPUWorkload_$t" -ScriptBlock {
            $result = 1
            for ($i = 0; $i -lt 2147483647; $i++) {
                $result *= $i
            }
        }
    }
    Write-Verbose "$threadCount jobs started!"
    $jobList = Get-Job -Name "CPUWorkload*"
}
return $jobList
