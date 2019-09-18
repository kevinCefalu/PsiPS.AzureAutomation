
function Get-RunbookJobHistory
{
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [OutputType([Collections.Generic.List[Microsoft.Azure.Commands.Automation.Model.Job]], ParameterSetName = 'All')]
    [OutputType([Collections.Generic.List[Microsoft.Azure.Commands.Automation.Model.Job]], ParameterSetName = 'ByName')]
    [OutputType([Microsoft.Azure.Commands.Automation.Model.Job], ParameterSetName = 'ById')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [string] $ResourceGroupName,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [string] $AutomationAccountName,

        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string] $RunbookName,

        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [string] $JobId,

        [Parameter(ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [ValidateSet('Activating', 'Completed', 'Failed', 'Queued', 'Resuming',
            'Running', 'Starting', 'Stopped', 'Stopping', 'Suspended', 'Suspending')]
        [string] $Status,

        [Parameter(ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [ValidateScript({
            $ThirtyDaysAgo = [DateTimeOffset]::new((Get-Date).AddDays(-30));

            if ($ThirtyDaysAgo -gt $_)
            {
                throw ("StartDateTime must be greater than, or equal to, 30 days ago.`n" +
                    "Received: $($_.ToString()); Expected >=: $($ThirtyDaysAgo.ToString())");

                return $false;
            }

            return $true;
        })]
        [DateTimeOffset] $StartDateTime,

        [Parameter(ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [ValidateScript({
            $Now = [DateTimeOffset]::new((Get-Date));

            if ($Now -lt $_)
            {
                throw ("EndDateTime must be less than, or equal to, now.`n" +
                    "Received: $($_.ToString()); Expected >=: $($Now.ToString())");

                return $false;
            }

            return $true;
        })]
        [DateTimeOffset] $EndDateTime,

        [Parameter(ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [switch] $FullDetails,

        [Parameter(ParameterSetName = 'All')]
        [Parameter(ParameterSetName = 'ByName')]
        [switch] $ShowProgress
    );

    $RunbookJobs = [Collections.Generic.List[Microsoft.Azure.Commands.Automation.Model.Job]]::new();

    $BaseParameterKeys = @('ResourceGroupName', 'AutomationAccountName');

    $GetAzureRmAutomationJobParameters = @{
        ResourceGroupName = $ResourceGroupName;
        AutomationAccountName = $AutomationAccountName;
    };

    switch ($PSCmdlet.ParameterSetName)
    {
        'ById' `
        {
            $GetAzureRmAutomationJobParameters.Id = $JobId;

            $RunbookJobs = Get-AzureRmAutomationJob @GetAzureRmAutomationJobParameters;
        }

        'ByName' `
        {
            $GetAzureRmAutomationJobParameters.RunbookName = $RunbookName;

            if (-not [String]::IsNullOrEmpty($Status))
            {
                $GetAzureRmAutomationJobParameters.Status = $Status;
            }

            if ($null -ne $StartDateTime)
            {
                $GetAzureRmAutomationJobParameters.StartTime = $StartDateTime;
            }

            if ($null -ne $EndDateTime)
            {
                $GetAzureRmAutomationJobParameters.EndTime = $EndDateTime;
            }

            $RunbookJobs = Get-AzureRmAutomationJob @GetAzureRmAutomationJobParameters;
        }

        Default `
        {
            if (-not [String]::IsNullOrEmpty($Status))
            {
                $GetAzureRmAutomationJobParameters.Status = $Status;
            }

            if ($null -ne $StartDateTime)
            {
                $GetAzureRmAutomationJobParameters.StartTime = $StartDateTime;
            }

            if ($null -ne $EndDateTime)
            {
                $GetAzureRmAutomationJobParameters.EndTime = $EndDateTime;
            }

            $RunbookJobs = Get-AzureRmAutomationJob @GetAzureRmAutomationJobParameters;
        }
    }

    if ($FullDetails.IsPresent)
    {
        if ($ShowProgress.IsPresent)
        {
            $WriteProgressParameters = @{
                Activity = "Getting Runbook Job History Details...";
                StatusMessage = { "Querying '$($RunbookJobs[$RunbookJobIndex].RunbookName)' (Id: $($RunbookJobs[$RunbookJobIndex].JobId.Guid))"; };
                PercentComplete = { [Math]::Round((100 * ($RunbookJobIndex / $RunbookJobs.Count)), 2); };
            };
        }

        for ($RunbookJobIndex = 0; $RunbookJobIndex -lt $RunbookJobs.Count; $RunbookJobIndex++)
        {
            if ($ShowProgress.IsPresent)
            {
                Write-Progress `
                    -Activity $WriteProgressParameters.Activity `
                    -Status (& $WriteProgressParameters.StatusMessage) `
                    -PercentComplete (& $WriteProgressParameters.PercentComplete);
            }

            # TODO: Recurse this function instead of calling the base azurerm.automation cmdlet, again

            $GetAzureRmAutomationJobParameters.Keys.Where({ $BaseParameterKeys -notcontains $_ }) `
                | ForEach-Object { $GetAzureRmAutomationJobParameters.Remove($_) };

            $GetAzureRmAutomationJobParameters.Id = $RunbookJobs[$RunbookJobIndex].JobId;
            $RunbookJobs[$RunbookJobIndex] = Get-AzureRmAutomationJob @GetAzureRmAutomationJobParameters;
        }

        if ($ShowProgress.IsPresent)
        {
            Write-Progress `
                -Activity $WriteProgressParameters.Activity `
                -PercentComplete 100 -Completed;
        }
    }

    $RunbookJobs | ForEach-Object -Process `
    {
        if ($null -ne $_.EndTime -and $null -ne $_.StartTime)
        {
            Add-Member -InputObject $_ `
                -MemberType NoteProperty `
                -Name 'RunTime' `
                -Value ($_.EndTime - $_.StartTime);
        }
    };

    return [Collections.Generic.List[Microsoft.Azure.Commands.Automation.Model.Job]] $RunbookJobs;
}
