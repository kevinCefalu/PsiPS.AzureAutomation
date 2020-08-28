
<#
    Use the PowerShell extension setting `powershell.scriptAnalysis.settingsPath` to get the current workspace
    to use this PSScriptAnalyzerSettings.psd1 file to configure code analysis in Visual Studio Code.
    This setting is configured in the workspace's `.vscode\settings.json`.

    For more information on PSScriptAnalyzer settings see:
    https://github.com/PowerShell/PSScriptAnalyzer/blob/master/README.md#settings-support-in-scriptanalyzer

    You can see the predefined PSScriptAnalyzer settings here:
    https://github.com/PowerShell/PSScriptAnalyzer/tree/master/Engine/Settings
#>

@{
    # Use Severity when you want to limit the generated diagnostic records to a subset of: Error, Warning and Information.
    # Uncomment the following line if you only want Errors and Warnings but not Information diagnostic records.
    Severity = @(
        'Error',
        'Warning'
    );

    # Use IncludeRules when you want to run only a subset of the default rule set.
    # IncludeRules = @(
    #    'PSAvoidDefaultValueSwitchParameter',
    #    'PSMisleadingBacktick',
    #    'PSMissingModuleManifestField',
    #    'PSReservedCmdletChar',
    #    'PSReservedParams',
    #    'PSShouldProcess',
    #    'PSUseApprovedVerbs',
    #    'PSAvoidUsingCmdletAliases',
    #    'PSUseDeclaredVarsMoreThanAssignments'
    # );

    # Use ExcludeRules when you want to run most of the default set of rules except for a few rules you wish to "exclude".
    # Note: if a rule is in both IncludeRules and ExcludeRules, the rule will be excluded.
    ExcludeRules = @(
        'PSAvoidGlobalVars',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingWriteHost',
        'PSShouldProcess',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns'
    );

    # ExcludeRules = @(
    #     'PSAvoidUsingPlainTextForPassword',
    #     'PSAvoidUsingUserNameAndPassWordParams'
    # );

    # You can use the following entry to supply parameters to rules that take parameters.
    # For instance, the PSAvoidUsingCmdletAliases rule takes a whitelist for aliases you want to allow.
    Rules = @{
        # Do not flag 'cd' alias.
        # PSAvoidUsingCmdletAliases = @{Whitelist = @('cd')}

        # Check if your script uses cmdlets that are compatible on PowerShell Core, version 6.0.0-alpha, on Linux.
        # PSUseCompatibleCmdlets = @{Compatibility = @("core-6.0.0-alpha-linux")}

        PSUseConsistentWhitespace = @{
            Enable = $true;
            CheckInnerBrace = $true;
            CheckOpenBrace = $false;
            CheckOpenParen = $true;
            CheckOperator = $true;
            CheckPipe = $true;
            CheckSeparator = $true;
        };
    }
}
