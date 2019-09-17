
function Get-RunbookJobOutput
{
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $AutomationAccountName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $JobId,

        [Parameter()]
        [switch] $IncludeVerboseStreams,

        [Parameter()]
        [switch] $ShowProgress
    );

    $RequestedStreams = @('Error', 'Output', 'Warning');

    #region Parameter Splatting(s)

    $GetJobStreamParameters = @{
        ResourceGroupName = $ResourceGroupName;
        AutomationAccountName = $AutomationAccountName;
        Id = $JobId;
    };

    if ($ShowProgress.IsPresent)
    {
        $WriteProgressParameters = @{
            Id = 1;
            Activity = 'Getting Job Output';
        }
    }

    #endregion Parameter Splatting(s)

    $Stopwatch = [Diagnostics.Stopwatch]::StartNew();
    $JobStreams = [Collections.Generic.List[JobStream]]::new();
    $JobStreamRecords = [Collections.Generic.List[JobStreamRecord]]::new();

    if ($IncludeVerboseStreams.IsPresent)
    {
        $RequestedStreams += 'Verbose';
        $StatusMessage = 'Fetching all job streams...';

        Write-Verbose $StatusMessage;

        if ($ShowProgress.IsPresent)
        {
            Write-Progress @WriteProgressParameters -Status $StatusMessage `
                -CurrentOperation "Time Elapsed: $(Format-TimeSpan $Stopwatch.Elapsed)";
        }

        $JobStreams_Temp = Get-AzureRmAutomationJobOutput `
            @GetJobStreamParameters `
            -Stream 'Any';

        if ($null -ne $JobStreams_Temp -and $JobStreams_Temp.Count -gt 0)
        {
            $JobStreams.AddRange(([JobStream[]] $JobStreams_Temp));
        }
    }
    else
    {
        $TotalRequestedStreamCount = $RequestedStreams.Count;

        if ($ShowProgress.IsPresent)
        {
            $RequestedStreamsString = $RequestedStreams -Join ', ';
            $RequestedStreamsString = $RequestedStreamsString.Insert(
                $RequestedStreamsString.LastIndexOf(','), ' and');

            $StatusMessage = "Fetching $RequestedStreamsString job streams...";
        }

        for ($StreamIndex = 0; $StreamIndex -lt $TotalRequestedStreamCount; $StreamIndex++)
        {
            $OperationMessage = "Fetching $($RequestedStreams[$StreamIndex]) job streams...";

            Write-Verbose $OperationMessage;

            if ($ShowProgress.IsPresent)
            {
                Write-Progress @WriteProgressParameters -Status $StatusMessage `
                    -CurrentOperation ("Time Elapsed: $(Format-TimeSpan $Stopwatch.Elapsed); " +
                        "$($StreamIndex + 1) of ${TotalRequestedStreamCount}: $OperationMessage") `
                    -PercentComplete ([Math]::Round((($StreamIndex / $TotalRequestedStreamCount) * 100), 2));
            }

            $JobStreams_Temp = Get-AzureRmAutomationJobOutput `
                @GetJobStreamParameters -Stream $RequestedStreams[$StreamIndex];

            if ($null -ne $JobStreams_Temp -and $JobStreams_Temp.Count -gt 0)
            {
                $JobStreams.AddRange(([JobStream[]] $JobStreams_Temp));
            }
        }
    }

    Remove-Variable 'JobStreams_Temp' -Scope 'Local' -Force -ErrorAction:SilentlyContinue;
    [GC]::Collect();

    $TotalJobStreamCount = $JobStreams.Count;
    $StatusMessage = "Fetching $TotalJobStreamCount job stream records...";

    Write-Verbose $StatusMessage;

    $GetJobStreamRecordParameters = $GetJobStreamParameters.Clone();
    $GetJobStreamRecordParameters.JobId = $GetJobStreamRecordParameters.Id;
    $CurrentOperationMessage = [String]::Empty;
    $MaxTotalJobStreamCountStringLength = $TotalJobStreamCount.ToString().Length;

    for ($JobStreamIndex = 0; $JobStreamIndex -lt $TotalJobStreamCount; $JobStreamIndex++)
    {
        $GetJobStreamRecordParameters.Id = $JobStreams[$JobStreamIndex].StreamRecordId;

        $CurrentOperationMessage = (
            "Time Elapsed: $(Format-TimeSpan $Stopwatch.Elapsed); " +
            "$(($JobStreamIndex + 1).ToString().PadLeft($MaxTotalJobStreamCountStringLength, '0')) " +
            "of ${TotalJobStreamCount}: Fetching job stream $($JobStreams[$JobStreamIndex].Type.ToLower()) " +
            "record Id: $($GetJobStreamRecordParameters.Id)"
        );

        Write-Verbose $CurrentOperationMessage;

        if ($ShowProgress.IsPresent)
        {
            Write-Progress @WriteProgressParameters -ParentId ($WriteProgressParameters.Id + 1) `
                -Status $StatusMessage -CurrentOperation $CurrentOperationMessage `
                -PercentComplete ([Math]::Round((($JobStreamIndex / $TotalJobStreamCount) * 100), 2));
        }

        $JobStreamRecords_Temp = Get-AzureRmAutomationJobOutputRecord `
            @GetJobStreamRecordParameters;

        if ($null -ne $JobStreamRecords_Temp)
        {
            $JobStreamRecords.Add($JobStreamRecords_Temp);
        }

        Remove-Variable 'JobStreamRecords_Temp' -Scope 'Local' -Force -ErrorAction:SilentlyContinue;
        [GC]::Collect();
    }

    if ($ShowProgress.IsPresent)
    {
        # Write-Progress @WriteProgressParameters `
        #     -ParentId ($WriteProgressParameters.Id + 1) `
        #     -PercentComplete 100 -Completed;

        Write-Progress @WriteProgressParameters `
            -PercentComplete 100 -Completed;
    }

    $RequestedJobStreamRecords = @{ };

    foreach ($RequestedStream in $RequestedStreams)
    {
        $RequestedJobStreamRecords.$RequestedStream =
            $JobStreamRecords.Where({ $_.Type -eq $RequestedStream });
    }

    Remove-Variable 'JobStreams' -Scope 'Local' -Force -ErrorAction:SilentlyContinue;
    Remove-Variable 'JobStreamRecords' -Scope 'Local' -Force -ErrorAction:SilentlyContinue;
    [GC]::Collect();

    return (New-Object -TypeName 'PSCustomObject' -Property $RequestedJobStreamRecords);
}
