
$script:ModuleRoot = $PSScriptRoot;
$script:ModuleName = $MyInvocation.MyCommand.Name.Replace('.psm1', '');
$script:FeatureFlags = $MyInvocation.MyCommand.Module.PrivateData.FeatureFlags;
$script:RequiredModules = $MyInvocation.MyCommand.Module.RequiredModules;
$script:CurrentUserPrincipal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent());
$script:IsUserAdmin = $CurrentUserPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);

$script:TabWidth = 4;
$script:TabString = ' ' * $script:TabWidth;

# Make sure to double up on any ` (backtick) characters that exist in the ASCII art.
$script:ModuleASCIIArt = @"

$script:TabString _____     _ _____   _____
$script:TabString|  __ \   (_)  __ \ / ____|
$script:TabString| |__) |__ _| |__) | (___
$script:TabString|  ___/ __| |  ___/ \___ \                    _                        _   _
$script:TabString| | /\\__ \ | |     ____) |        /\        | |                      | | (_)
$script:TabString|_|/  \___/_|_|_   |_____/___     /  \  _   _| |_ ___  _ __ ___   __ _| |_ _  ___  _ __
$script:TabString  / /\ \  |_  / | | | '__/ _ \   / /\ \| | | | __/ _ \| '_ `` _ \ / _`` | __| |/ _ \| '_ \
$script:TabString / ____ \  / /| |_| | | |  __/  / ____ \ |_| | || (_) | | | | | | (_| | |_| | (_) | | | |
$script:TabString/_/    \_\/___|\__,_|_|  \___| /_/    \_\__,_|\__\___/|_| |_| |_|\__,_|\__|_|\___/|_| |_|

"@;
