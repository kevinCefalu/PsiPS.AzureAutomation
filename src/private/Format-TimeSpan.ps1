
function Format-TimeSpan
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [TimeSpan] $Elapsed
    );

    $StringBuilder = [Text.StringBuilder]::new();

    if ($Elapsed.Hours -gt 0)
    {
        $StringBuilder.Append("$($Elapsed.Hours.ToString().PadLeft(2, '0'))h ") | Out-Null;
    }

    if ($Elapsed.Minutes -gt 0)
    {
        $StringBuilder.Append("$($Elapsed.Minutes.ToString().PadLeft(2, '0'))m ") | Out-Null;
    }

    if ($Elapsed.Seconds -gt 0 -and $Elapsed.Milliseconds -gt 0)
    {
        $StringBuilder.Append("$($Elapsed.Seconds.ToString().PadLeft(2, '0')).") | Out-Null;
        $StringBuilder.Append("$($Elapsed.Milliseconds.ToString().PadRight(4, '0'))s") | Out-Null;
    }
    elseif ($Elapsed.Seconds -eq 0 -and $Elapsed.Milliseconds -gt 0)
    {
        $StringBuilder.Append("00.$($Elapsed.Milliseconds.ToString().PadRight(4, '0'))s") | Out-Null;
    }
    elseif ($Elapsed.Seconds -gt 0 -and $Elapsed.Milliseconds -eq 0)
    {
        $StringBuilder.Append("$($Elapsed.Seconds.ToString().PadLeft(2, '0'))s") | Out-Null;
    }

    return $StringBuilder.ToString().Trim();
}
