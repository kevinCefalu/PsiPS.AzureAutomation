
function Publish-Runbook
{
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([Microsoft.Azure.Commands.Automation.Model.Runbook])]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string] $AutomationAccountName,

        [Parameter(Mandatory)]
        [ValidateScript({
            if (-not ($_ | Test-Path))
            {
                throw 'File does not exist';

                return $false;
            }
            elseif ($_ -notmatch "(\.ps1)")
            {
                throw 'If passing a file to the Path argument, it must be a powershell script (ps1).';

                return $false;
            }
            else
            {
                return $true;
            }
        })]
        [IO.FileInfo] $Path,

        [Parameter()]
        [string] $Name,

        [Parameter()]
        [ValidateSet('PowerShell', 'PowerShellWorkflow')]
        [string] $Type = 'PowerShell',

        [Parameter()]
        [string] $Description,

        [Parameter()]
        [HashTable] $Tags,

        [Parameter()]
        [switch] $LogVerbose,

        [Parameter()]
        [switch] $LogProgress,

        [Parameter()]
        [switch] $AsDraft,

        [Parameter()]
        [switch] $Force
    );

    begin
    {
        if (-not $PSBoundParameters.ContainsKey('Confirm'))
        {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference');
        }

        if (-not $PSBoundParameters.ContainsKey('WhatIf'))
        {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference');
        }
    }

    process
    {
        $ImportAzureRmAutomationRunbookParameters = @{
            ResourceGroupName = $ResourceGroupName;
            AutomationAccountName = $AutomationAccountName;
            Path = $Path.FullName;
            Name = $Name;
            Type = $Type;
            LogVerbose = $LogVerbose.IsPresent;
            LogProgress = $LogProgress.IsPresent;
            Published = (-not $AsDraft.IsPresent);
            Force = $Force.IsPresent;
        };

        if ([String]::IsNullOrEmpty($Name))
        {
            $ImportAzureRmAutomationRunbookParameters.Name = $Path.BaseName;
        }

        if (-not [String]::IsNullOrEmpty($Description))
        {
            $ImportAzureRmAutomationRunbookParameters.Description = $Description;
        }

        if ($null -ne $Tags)
        {
            $ImportAzureRmAutomationRunbookParameters.Tags = $Tags.Clone();
        }

        return (
            Import-AzureRmAutomationRunbook @ImportAzureRmAutomationRunbookParameters `
                -WhatIf:(-not ($Force -or $PSCmdlet.ShouldProcess("ShouldProcess?")))
        );
    }
}
