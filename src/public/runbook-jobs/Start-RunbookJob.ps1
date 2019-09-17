
function Start-RunbookJob
{
    [CmdletBinding()]
    [OutputType([Microsoft.Azure.Commands.Automation.Model.Job])]
    param (
        [Parameter(Mandatory)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory)]
        [string] $AutomationAccountName,

        [Parameter(Mandatory)]
        [string] $RunbookName,

        [Parameter()]
        [string] $HybridWorkerName,

        [Parameter()]
        [Hashtable] $RunbookArguments,

        [Parameter()]
        [int] $PollingInterval = 5,

        [Parameter()]
        [switch] $ShowProgress
    );

    #region Parameter Splatting(s)

    $GenericParameters = @{
        ResourceGroupName = $ResourceGroupName;
        AutomationAccountName = $AutomationAccountName;
    };

    $GetRunbookJobHistoryParameters = $GenericParameters.Clone();
    $GetRunbookJobHistoryParameters.RunbookName = $RunbookName;

    $StartRunbookJobParameters = $GenericParameters.Clone();
    $StartRunbookJobParameters.Name = $RunbookName;

    if (-not [String]::IsNullOrEmpty($HybridWorkerName))
    {
        $StartRunbookJobParameters.RunOn = $HybridWorkerName;
    }

    if ($null -ne $RunbookArguments)
    {
        $StartRunbookJobParameters.Parameters = $RunbookArguments;
    }

    #endregion Parameter Splatting(s)

    $JobHistory = Get-RunbookJobHistory `
        @GetRunbookJobHistoryParameters -Status 'Completed';

    if ($null -ne $JobHistory)
    {
        $AverageRunTime = ($JobHistory.RunTime `
            | Measure-Object -Average -Property TotalSeconds).Average;

        Write-Verbose "Average RunTime for '$RunbookName'" +
            "is $([Math]::Round($AverageRunTime, 2))";
    }

    if ($ShowProgress.IsPresent)
    {
        $RemainingProgress = 100;
        $IndefiniteDenominator = 1.1;

        $WriteProgressParameters = @{
            Activity = "Executing Runbook: $RunbookName";
            StatusMessage = { "JobId: $($RunbookJob.JobId); " +
                "Time Elapsed: $(Format-TimeSpan $Stopwatch.Elapsed)" };
            PercentComplete = { (100 - $RemainingProgress) };
        };
    }

    $Stopwatch = [Diagnostics.Stopwatch]::StartNew();
    $StartDateTime = [DateTimeOffset]::new((Get-Date).AddMinutes(-1));

    $RunbookJob = Start-AzureRmAutomationRunbook @StartRunbookJobParameters;

    do
    {
        Start-Sleep -Seconds $PollingInterval;

        if ($null -eq $RunbookJob.JobId)
        {
            $RetryCount = 1;
            $MaxRetryCount = 5

            do
            {
                Write-Warning ("Failed to query for the current" +
                    "Job. Retrying ($RetryIndex of $MaxRetryCount).");

                $RunbookJob = Get-RunbookJobHistory `
                        @GetRunbookJobHistoryParameters `
                        -StartDateTime $StartDateTime `
                    | Sort-Object CreationTime -Descending `
                    | Select-Object -First 1;

                $RetryCount++;
            }
            while (
                $null -ne $RunbookJob -or
                $RetryCount -le $MaxRetryCount
            );

            if ($null -eq $RunbookJob)
            {
                Write-Error ("An error has occurred, while" +
                    "retrieving the runbook job from Azure.");

                return $null;
            }
        }

        if ($ShowProgress.IsPresent)
        {
            Write-Progress `
                -Activity $WriteProgressParameters.Activity `
                -Status (& $WriteProgressParameters.StatusMessage) `
                -PercentComplete (& $WriteProgressParameters.PercentComplete);

            $RemainingProgress /= $IndefiniteDenominator;
        }

        $RunbookJob = Get-RunbookJobHistory @GenericParameters `
            -JobId $RunbookJob.JobId;
    }
    while (@('Suspended', 'Completed', 'Failed',
        'Stopped') -notcontains $RunbookJob.Status)

    $Stopwatch.Stop();

    if ($ShowProgress.IsPresent)
    {
        Write-Progress `
            -Activity $WriteProgressParameters.Activity `
            -PercentComplete 100 -Completed;
    }

    return $RunbookJob;
}
