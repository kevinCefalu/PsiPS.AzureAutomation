
function Get-ModuleInformation
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch] $IncludeFunctions
    );

    process
    {
        Write-Host $script:ModuleASCIIArt;

        $ModuleInfo = Get-Module -Name $script:ModuleName `
            | Select-Object -Property Name, Version, Author, CompanyName, Description, ExportedFunctions;

        Write-Host "$($script:TabString)Name:        $($ModuleInfo.Name) v$($ModuleInfo.Version)";
        Write-Host "$($script:TabString)Author:      $($ModuleInfo.Author), $($ModuleInfo.CompanyName)";
        Write-Host "$($script:TabString)Description: $($ModuleInfo.Description)`n";

        if ($IncludeFunctions.IsPresent)
        {
            $ExportedFunctions = ($ModuleInfo.ExportedFunctions.Keys | Sort-Object) -join "`n$($script:TabString * 2)";
            Write-Host "$($script:TabString)Functions:`n$($script:TabString * 2)$ExportedFunctions";
        }
    }
}

