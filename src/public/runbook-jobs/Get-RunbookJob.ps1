
function Get-RunbookJob
{
    [CmdletBinding()]

    [OutputType([object])]

    param (
        [Parameter(Mandatory)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory)]
        [string] $AutomationAccountName,

        [Parameter(Mandatory)]
        [string] $JobId,

        [Parameter()]
        [ValidateSet('Any', 'Error', 'Output', 'Progress', 'Verbose', 'Warning')]
        [string] $StreamType = 'Any'
    );

    $AutomationAccountParams = @{
        ResourceGroupName = $ResourceGroupName;
        AutomationAccountName = $AutomationAccountName;
    }

    $Job = Get-AzureRmAutomationJob `
        @AutomationAccountParams -Id $JobId;

    $Output = Get-AzureRmAutomationJobOutput `
        @AutomationAccountParams -Id $JobId `
        -Stream $StreamType;

    $Output.ForEach({
        $_ | Add-Member `
            -NotePropertyName 'Timestamp' `
            -NotePropertyValue $_.Time.LocalDateTime;
    })

    $Output `
        | Group-Object -Property 'Type' `
        | ForEach-Object -Process `
            {
                $_.Group.ForEach({
                    $Record = Get-AzureRmAutomationJobOutputRecord `
                        @AutomationAccountParams -JobId $JobId `
                        -Id $_.StreamRecordId;

                    $Record | Add-Member `
                        -NotePropertyName 'Timestamp' `
                        -NotePropertyValue $_.Time.LocalDateTime;

                    $_ | Add-Member `
                        -NotePropertyName 'Record' `
                        -NotePropertyValue $Record;
                });

                $Job | Add-Member `
                    -NotePropertyName $_.Name `
                    -NotePropertyValue ($_.Group);
            };

    return $Job;
}
