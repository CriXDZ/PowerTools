function Format-PTBreadcrumb {

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Position = 0)]
        [string] $Path = '',

        [int] $MaxLength = 55
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return '~'
    }

    $homeDir = if (Get-Command -Name 'Get-PTRootPath' -ErrorAction SilentlyContinue) {
        Get-PTRootPath -Location Home
    } elseif ($env:USERPROFILE) {
        $env:USERPROFILE
    } else {
        $HOME
    }
    $normalized = $Path.TrimEnd('\', '/')

    if ($normalized -like "$homeDir*") {
        $tail = $normalized.Substring($homeDir.Length).TrimStart('\', '/')
        $normalized = if ($tail) { "~/$tail" } else { "~" }
    }

    $segments = $normalized -split '[\\/]' | Where-Object { $_ -ne '' }
    if ($segments.Count -le 1) {
        return ($segments -join ' \ ')
    }

    $candidate = $segments -join ' \ '
    if ($candidate.Length -le $MaxLength) {
        return $candidate
    }

    $first = $segments[0]
    $last  = $segments[-1]

    if ($segments.Count -gt 2) {
        $secondLast = $segments[-2]
        $candidateWithTwo = "$first \ ... \ $secondLast \ $last"
        if ($candidateWithTwo.Length -le $MaxLength) {
            return $candidateWithTwo
        }
    }

    return "$first \ ... \ $last"
}
