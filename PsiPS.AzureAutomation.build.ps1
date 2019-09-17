
Task . Clean, Build, Import;

Task Build Compile, CreateManifest;
Task CreateManifest CopyPSD, UpdatePublicFunctionsToExport;
Task Stats RemoveStats, WriteStats;

$script:ModuleRoot = "$PSScriptRoot\src";
$script:ModuleName = $MyInvocation.MyCommand.Name.Replace('.build.ps1', '');
$script:ModulePSDPath = "$script:ModuleRoot\$($script:ModuleName).psd1";

$script:PublicFolder = "$script:ModuleRoot\public";
$script:ImportFolders = @(
    "$script:ModuleRoot\startup",
    "$script:ModuleRoot\private",
    $script:PublicFolder
);

$script:OutputFolderName = 'release';
$script:OutPutFolder = "$PSScriptRoot\$script:OutputFolderName";
$script:OutPutModuleFolder = "$($script:OutPutFolder)\$($script:ModuleName)";
$script:OutputPSMPath = "$($script:OutPutModuleFolder)\$($script:ModuleName).psm1";
$script:OutputPSDPath = "$($script:OutPutModuleFolder)\$($script:ModuleName).psd1";

Task Clean `
{
    if (-not (Test-Path $script:OutPutFolder))
    {
        New-Item -ItemType Directory -Path $script:OutPutFolder | Out-Null;
    }

    Remove-Item -Path "$($script:OutPutFolder)\*" -Recurse -Force | Out-Null;
}

Task CopyPSD -if (Test-Path -Path $script:ModulePSDPath) `
{
    Copy-Item $script:ModulePSDPath -Destination $script:OutputPSDPath -Force;
}

Task Compile `
{
    if (Test-Path -Path $script:OutputPSMPath)
    {
        Remove-Item -Path $script:OutputPSMPath -Force;
    }

    New-Item -Path $script:OutputPSMPath -ItemType File -Force | Out-Null;

    foreach ($importFolder in $script:ImportFolders)
    {
        Write-Verbose -Message "Checking folder '$importFolder'";

        if (Test-Path -Path $importFolder)
        {
            $files = Get-ChildItem -Path $importFolder -Filter '*.ps1' -Recurse;

            foreach ($file in $files)
            {
                Write-Verbose -Message "Adding $($file.FullName)";

                Get-Content -Path $file.FullName | Out-File $script:OutputPSMPath -Append -Confirm:$false -Force;
            }
        }
    }
}

Task UpdatePublicFunctionsToExport -if (Test-Path -Path $script:PublicFolder) `
{
    $publicFunctions = Get-ChildItem -Path $script:PublicFolder -Filter *.ps1 -Recurse;

    $Tab = ' ' * 4;

    if ($publicFunctions.count -gt 0)
    {
        $publicFunctionsString = ($publicFunctions | Select-Object -ExpandProperty BaseName) -join "',`n${Tab}${Tab}'";

        $publicFunctionsString = "FunctionsToExport = @(`n${Tab}${Tab}'{0}'`n${Tab})" -f $publicFunctionsString;

        (Get-Content -Path $script:OutputPSDPath) -replace "FunctionsToExport = '\*'", $publicFunctionsString `
            | Set-Content -Path $script:OutputPSDPath;
    }
}

Task Import -if (Test-Path -Path $script:OutputPSMPath) `
{
    Get-Module -Name $script:ModuleName | Remove-Module -Force;
    Import-Module -Name $script:OutputPSDPath -Force;
}
