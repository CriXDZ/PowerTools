function Write-PTMessage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Message,

        [ValidateSet('Info', 'Warn', 'Error', 'Success')]
        [string] $Level = 'Info',

        [string] $ColorName,

        [switch] $NoNewline
    )

    if ($env:PT_SILENT -eq '1') {
        return
    }

    $theme = if (Get-Command -Name 'Get-PTAnsiTheme' -ErrorAction SilentlyContinue) {
        Get-PTAnsiTheme
    } else {
        @{
            Reset       = "`e[0m"
            Accent      = "`e[38;2;0;210;255m"
            HeaderIcon  = "`e[38;2;0;210;255m"
            SuccessIcon = "`e[1;32m"
            Success     = "`e[1;32m"
            Warn        = "`e[1;33m"
            Error       = "`e[1;31m"
            NormalText  = "`e[38;2;200;200;200m"
        }
    }

    if ($env:PT_NO_COLOR -eq '1') {
        if ($NoNewline) {
            Write-Host -NoNewline $Message
        } else {
            Write-Host $Message
        }
        return
    }

    $prefixColor = switch ($Level) {
        'Success' { if ($theme.SuccessIcon) { $theme.SuccessIcon } else { $theme.Success } }
        'Warn'    { $theme.Warn }
        'Error'   { $theme.Error }
        'Info'    { if ($theme.HeaderIcon) { $theme.HeaderIcon } else { $theme.Accent } }
        default   { $theme.Accent }
    }

    if ($ColorName -and $theme.ContainsKey($ColorName)) {
        $prefixColor = $theme[$ColorName]
    }

    $symbol = switch ($Level) {
        'Error'   { [string][char]0x2716 + ' ' }
        'Warn'    { [string][char]0x25B2 + ' ' }
        'Success' { [string][char]0x25C6 + ' ' }
        'Info'    { [string][char]0x25C7 + ' ' }
        default   { '' }
    }

    $formatted = "$prefixColor$symbol$($theme.Reset)$($theme.NormalText)$Message$($theme.Reset)"

    if ($NoNewline) {
        Write-Host -NoNewline $formatted
    } else {
        Write-Host $formatted
    }
}
