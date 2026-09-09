function Get-PTSelectorSymbols {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        Pointer     = [string][char]0x276F
        CircleFull  = [string][char]0x25CF
        CircleOpen  = [string][char]0x25CB
        DiamondOpen = [string][char]0x25C7
        DiamondFull = [string][char]0x25C6
        Pipe        = [string][char]0x2502
        Corner      = [string][char]0x2514
        ArrowUp     = [string][char]0x2191
        ArrowDown   = [string][char]0x2193
        Bullet      = [string][char]0x2022
    }
}

function Get-PTSelectorPageWindow {

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [int] $TotalItems,

        [Parameter(Mandatory)]
        [int] $SelectedIndex,

        [int] $PageSize = 8
    )

    if ($TotalItems -le 0) {
        return [pscustomobject]@{
            StartIndex = 0
            EndIndex   = 0
            Count      = 0
            HasPrev    = $false
            HasNext    = $false
            PrevCount  = 0
            NextCount  = 0
        }
    }

    $effPageSize = [math]::Max(1, $PageSize)
    $clampedSelected = [math]::Min([math]::Max(0, $SelectedIndex), $TotalItems - 1)

    if ($TotalItems -le $effPageSize) {
        return [pscustomobject]@{
            StartIndex = 0
            EndIndex   = $TotalItems
            Count      = $TotalItems
            HasPrev    = $false
            HasNext    = $false
            PrevCount  = 0
            NextCount  = 0
        }
    }

    $half = [math]::Floor($effPageSize / 2)
    $start = $clampedSelected - $half
    if ($start + $effPageSize -gt $TotalItems) {
        $start = $TotalItems - $effPageSize
    }
    if ($start -lt 0) {
        $start = 0
    }
    $end = [math]::Min($TotalItems, $start + $effPageSize)

    return [pscustomobject]@{
        StartIndex = $start
        EndIndex   = $end
        Count      = ($end - $start)
        HasPrev    = ($start -gt 0)
        HasNext    = ($end -lt $TotalItems)
        PrevCount  = $start
        NextCount  = ($TotalItems - $end)
    }
}

function Get-PTSelectorNextIndex {

    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [int] $CurrentIndex,

        [Parameter(Mandatory)]
        [ValidateSet('Up', 'Down', 'PageUp', 'PageDown', 'Home', 'End')]
        [string] $Action,

        [Parameter(Mandatory)]
        [int] $TotalItems,

        [int] $PageSize = 8
    )

    if ($TotalItems -le 0) {
        return 0
    }

    switch ($Action) {
        'Up'       { return ($CurrentIndex - 1 + $TotalItems) % $TotalItems }
        'Down'     { return ($CurrentIndex + 1) % $TotalItems }
        'PageUp'   { return [math]::Max(0, $CurrentIndex - $PageSize) }
        'PageDown' { return [math]::Min($TotalItems - 1, $CurrentIndex + $PageSize) }
        'Home'     { return 0 }
        'End'      { return ($TotalItems - 1) }
    }
}

function Find-PTMatchingOptions {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array] $Options,

        [string] $FilterText = ''
    )

    if ([string]::IsNullOrWhiteSpace($FilterText)) {
        return @($Options)
    }

    $lower = $FilterText.Trim().ToLowerInvariant()
    return @($Options | Where-Object {
        $lbl  = if ($_.Label) { $_.Label } else { $_.Name }
        $desc = if ($_.Description) { $_.Description } else { $_.Metadata }
        ([string]$lbl).ToLowerInvariant().Contains($lower) -or ([string]$desc).ToLowerInvariant().Contains($lower)
    })
}

function Format-PTHighlightedText {

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $Text,

        [string] $SearchTerm = '',

        [string] $HighlightAnsi = '',

        [string] $NormalAnsi = '',

        [string] $ResetAnsi = "`e[0m"
    )

    if ([string]::IsNullOrEmpty($SearchTerm) -or [string]::IsNullOrEmpty($Text)) {
        return "$NormalAnsi$Text$ResetAnsi"
    }

    $idx = $Text.IndexOf($SearchTerm, [System.StringComparison]::InvariantCultureIgnoreCase)
    if ($idx -lt 0) {
        return "$NormalAnsi$Text$ResetAnsi"
    }

    $before = $Text.Substring(0, $idx)
    $match  = $Text.Substring($idx, $SearchTerm.Length)
    $after  = $Text.Substring($idx + $SearchTerm.Length)

    return "$NormalAnsi$before$ResetAnsi$HighlightAnsi$match$ResetAnsi$NormalAnsi$after$ResetAnsi"
}

function Format-PTSelectorFrame {

    [CmdletBinding()]
    [OutputType([string[]], [object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $Title,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array] $FilteredOptions,

        [Parameter(Mandatory)]
        [int] $SelectedIndex,

        [string] $FilterText = '',

        [int] $PageSize = 8,

        [bool] $AllowFilter = $false,

        [bool] $AllowNavigationKeys = $false,

        [hashtable] $Theme = @{}
    )

    $t = if ($Theme -and $Theme.Count -gt 0) { $Theme } else {
        if (Get-Command -Name 'Get-PTAnsiTheme' -ErrorAction SilentlyContinue) {
            Get-PTAnsiTheme
        } else {
            @{
                Reset = "`e[0m"; Bold = "`e[1m"; Accent = "`e[38;2;0;210;255m";
                Connector = "`e[38;2;120;120;120m"; HeaderIcon = "`e[38;2;0;210;255m";
                ItemActiveSymbol = "`e[38;2;0;210;255m"; ItemActiveLabel = "`e[1;97m"; ItemActiveDesc = "`e[38;2;170;170;170m";
                ItemInactiveSymbol = "`e[38;2;120;120;120m"; ItemInactiveLabel = "`e[38;2;200;200;200m"; ItemInactiveDesc = "`e[38;2;130;130;130m";
                MatchHighlight = "`e[1;38;2;0;210;255m`e[4m"; PaginationInfo = "`e[38;2;140;140;140m"; FaintGray = "`e[38;2;140;140;140m"
            }
        }
    }

    $sym = Get-PTSelectorSymbols
    $lines = [System.Collections.Generic.List[string]]::new()

    $filterDisplay = if ($AllowFilter -and $FilterText) {
        " $($t.Connector)(filtro: '$($t.Accent)$FilterText$($t.Connector)')$($t.Reset)"
    } else { "" }
    $lines.Add("$($t.HeaderIcon)$($sym.DiamondOpen)$($t.Reset)  $($t.Bold)$Title$($t.Reset)$filterDisplay")
    $lines.Add("$($t.Connector)$($sym.Pipe)$($t.Reset)")

    if ($FilteredOptions.Count -eq 0) {
        $lines.Add("$($t.Connector)$($sym.Pipe)$($t.Reset)  $($t.FaintGray)(No hay coincidencias)$($t.Reset)")
    }
    else {
        $window = Get-PTSelectorPageWindow -TotalItems $FilteredOptions.Count -SelectedIndex $SelectedIndex -PageSize $PageSize

        if ($window.HasPrev) {
            $lines.Add("$($t.Connector)$($sym.Pipe)$($t.Reset)  $($t.PaginationInfo)$($sym.ArrowUp) ($($window.PrevCount) mas arriba)$($t.Reset)")
        }

        $maxLabelLen = 0
        $sampleCount = [math]::Min($FilteredOptions.Count, 100)
        for ($k = 0; $k -lt $sampleCount; $k++) {
            $item = $FilteredOptions[$k]
            $itemLbl = if ($item.Label) { [string]$item.Label } elseif ($item.Name) { [string]$item.Name } else { '' }
            if ($itemLbl.Length -gt $maxLabelLen) {
                $maxLabelLen = $itemLbl.Length
            }
        }

        for ($i = $window.StartIndex; $i -lt $window.EndIndex; $i++) {
            $opt = $FilteredOptions[$i]
            $isActive = ($i -eq $SelectedIndex)

            $lbl  = if ($opt.Label) { [string]$opt.Label } else { [string]$opt.Name }
            $desc = if ($opt.Description) { [string]$opt.Description } else { [string]$opt.Metadata }

            $padLen = if ($desc) { [math]::Max(2, ($maxLabelLen - $lbl.Length + 2)) } else { 0 }
            $colPadding = ' ' * $padLen

            if ($isActive) {

                $prefix = "$($t.Connector)$($sym.Pipe)$($t.Reset) $($t.ItemActiveSymbol)$($sym.Pointer) $($sym.CircleFull)$($t.Reset) "
                $labelFormatted = if ($AllowFilter -and $FilterText) {
                    Format-PTHighlightedText -Text $lbl -SearchTerm $FilterText -HighlightAnsi $t.MatchHighlight -NormalAnsi $t.ItemActiveLabel -ResetAnsi $t.Reset
                } else {
                    "$($t.ItemActiveLabel)$lbl$($t.Reset)"
                }
                $descFormatted = if ($desc) { "$colPadding$($t.ItemActiveDesc)$desc$($t.Reset)" } else { "" }
                $lines.Add("$prefix$labelFormatted$descFormatted")
            }
            else {

                $prefix = "$($t.Connector)$($sym.Pipe)$($t.Reset)   $($t.ItemInactiveSymbol)$($sym.CircleOpen)$($t.Reset) "
                $labelFormatted = if ($AllowFilter -and $FilterText) {
                    Format-PTHighlightedText -Text $lbl -SearchTerm $FilterText -HighlightAnsi $t.MatchHighlight -NormalAnsi $t.ItemInactiveLabel -ResetAnsi $t.Reset
                } else {
                    "$($t.ItemInactiveLabel)$lbl$($t.Reset)"
                }
                $descFormatted = if ($desc) { "$colPadding$($t.ItemInactiveDesc)$desc$($t.Reset)" } else { "" }
                $lines.Add("$prefix$labelFormatted$descFormatted")
            }
        }

        if ($window.HasNext) {
            $lines.Add("$($t.Connector)$($sym.Pipe)$($t.Reset)  $($t.PaginationInfo)$($sym.ArrowDown) ($($window.NextCount) mas abajo)$($t.Reset)")
        }
    }

    $lines.Add("$($t.Connector)$($sym.Pipe)$($t.Reset)")

    $helpActions = [System.Collections.Generic.List[string]]::new()
    if ($AllowNavigationKeys) {
        $helpActions.Add("$($sym.ArrowUp)/$($sym.ArrowDown) Mover")
        $helpActions.Add("Enter/Tab Elegir")
        $helpActions.Add("<- Subir")
    } else {
        $helpActions.Add("$($sym.ArrowUp)/$($sym.ArrowDown) Navegar")
        $helpActions.Add("Enter Seleccionar")
    }

    if ($AllowFilter) {
        $helpActions.Add("Escribir para filtrar")
    }

    $helpActions.Add("Esc Cancelar")

    $helpBar = $helpActions -join "  $($sym.Bullet)  "
    $lines.Add("$($t.Connector)$($sym.Corner)$($t.Reset)  $($t.FaintGray)[$helpBar]$($t.Reset)")

    return , $lines.ToArray()
}

function Invoke-PTSelector {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Title,

        [Parameter(Position = 1)]
        [array] $Options = @(),

        [int] $PageSize = 8,

        [int] $SelectedIndex = 0,

        [switch] $AllowFilter,

        [switch] $AllowNavigationKeys
    )

    if (-not $Options -or $Options.Count -eq 0) {
        return $null
    }

    $theme = if (Get-Command -Name 'Get-PTAnsiTheme' -ErrorAction SilentlyContinue) {
        Get-PTAnsiTheme
    } else {
        @{
            Reset = "`e[0m"; Bold = "`e[1m"; Accent = "`e[38;2;0;210;255m";
            Connector = "`e[38;2;120;120;120m"; HeaderIcon = "`e[38;2;0;210;255m";
            SuccessIcon = "`e[1;32m"; FaintGray = "`e[38;2;140;140;140m"
        }
    }

    $sym = Get-PTSelectorSymbols

    $normalizedOptions = [System.Collections.Generic.List[pscustomobject]]::new()
    foreach ($opt in $Options) {
        if ($opt -is [string]) {
            $normalizedOptions.Add([pscustomobject]@{
                Label       = $opt
                Name        = $opt
                Description = ''
                Metadata    = ''
                Value       = $opt
                Type        = 'ACTION'
                Data        = $null
            })
        }
        else {
            $lbl  = if ($opt.Label) { $opt.Label } elseif ($opt.Name) { $opt.Name } elseif ($opt.Text) { $opt.Text } else { [string]$opt }
            $desc = if ($opt.Description) { $opt.Description } elseif ($opt.Metadata) { $opt.Metadata } else { '' }
            $val  = if ($null -ne $opt.Value) { $opt.Value } elseif ($null -ne $opt.Data) { $opt.Data } else { $lbl }
            $t    = if ($opt.Type) { $opt.Type } else { 'DIR' }
            $data = if ($null -ne $opt.Data) { $opt.Data } else { $val }

            $normalizedOptions.Add([pscustomobject]@{
                Label       = [string]$lbl
                Name        = [string]$lbl
                Description = [string]$desc
                Metadata    = [string]$desc
                Value       = $val
                Type        = [string]$t
                Data        = $data
            })
        }
    }

    $isInteractive = $false
    try {
        $isInteractive = [Environment]::UserInteractive -and -not [Console]::IsInputRedirected
    } catch { $null = $_ }

    if (-not $isInteractive) {
        Write-Host "`n$Title" -ForegroundColor Cyan
        for ($i = 0; $i -lt $normalizedOptions.Count; $i++) {
            $o = $normalizedOptions[$i]
            $d = if ($o.Description) { " ($($o.Description))" } else { "" }
            Write-Host "  [$($i + 1)] $($o.Label)$d"
        }
        $resp = Read-Host "Opcion (1-$($normalizedOptions.Count))"
        if ($resp -match '^\d+$' -and [int]$resp -ge 1 -and [int]$resp -le $normalizedOptions.Count) {
            return $normalizedOptions[[int]$resp - 1].Value
        }
        return $null
    }

    $origOutputEncoding = [Console]::OutputEncoding
    $origInputEncoding  = [Console]::InputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    } catch { $null = $_ }

    $filterText      = ""
    $filteredOptions = @($normalizedOptions)
    $currentSelected = [math]::Min([math]::Max(0, $SelectedIndex), [math]::Max(0, $filteredOptions.Count - 1))
    $renderedLines   = 0

    try {
        [Console]::Out.Write("`e[?25l")
        try { [Console]::CursorVisible = $false } catch { $null = $_ }

        $linesNeeded = [math]::Min($normalizedOptions.Count, $PageSize) + 6
        try {
            $windowHeight = $Host.UI.RawUI.WindowSize.Height
            $cursorY = [Console]::CursorTop
            $availableBelow = $windowHeight - 1 - $cursorY
            if ($availableBelow -lt $linesNeeded) {
                $scrollAmount = $linesNeeded - $availableBelow
                [Console]::Out.Write("`n" * $scrollAmount)
                [Console]::CursorTop = [Console]::CursorTop - $scrollAmount
            }
        } catch { $null = $_ }

        while ($true) {
            if ($AllowFilter) {
                $filteredOptions = Find-PTMatchingOptions -Options $normalizedOptions -FilterText $filterText
            } else {
                $filteredOptions = @($normalizedOptions)
            }

            if ($filteredOptions.Count -eq 0) {
                $currentSelected = 0
            } elseif ($currentSelected -ge $filteredOptions.Count) {
                $currentSelected = $filteredOptions.Count - 1
            }

            $frameLines = Format-PTSelectorFrame `
                -Title $Title `
                -FilteredOptions $filteredOptions `
                -SelectedIndex $currentSelected `
                -FilterText $filterText `
                -PageSize $PageSize `
                -AllowFilter $AllowFilter `
                -AllowNavigationKeys $AllowNavigationKeys `
                -Theme $theme

            $sb = [System.Text.StringBuilder]::new()
            if ($renderedLines -gt 0) {
                $canMoveUp = $renderedLines
                try {
                    $canMoveUp = [math]::Min($renderedLines, [Console]::CursorTop)
                } catch { $null = $_ }

                if ($canMoveUp -gt 0) {
                    $sb.Append("`r`e[${canMoveUp}A`e[J") | Out-Null
                } else {
                    $sb.Append("`r`e[J") | Out-Null
                }
            }

            foreach ($line in $frameLines) {
                $sb.AppendLine($line) | Out-Null
            }

            [Console]::Out.Write($sb.ToString())
            $renderedLines = $frameLines.Length

            $keyEvent = Read-PTSemanticKey

            switch ($keyEvent.Action) {
                'Up' {
                    if ($filteredOptions.Count -gt 0) {
                        $currentSelected = Get-PTSelectorNextIndex -CurrentIndex $currentSelected -Action 'Up' -TotalItems $filteredOptions.Count -PageSize $PageSize
                    }
                }
                'Down' {
                    if ($filteredOptions.Count -gt 0) {
                        $currentSelected = Get-PTSelectorNextIndex -CurrentIndex $currentSelected -Action 'Down' -TotalItems $filteredOptions.Count -PageSize $PageSize
                    }
                }
                'PageUp' {
                    if ($filteredOptions.Count -gt 0) {
                        $currentSelected = Get-PTSelectorNextIndex -CurrentIndex $currentSelected -Action 'PageUp' -TotalItems $filteredOptions.Count -PageSize $PageSize
                    }
                }
                'PageDown' {
                    if ($filteredOptions.Count -gt 0) {
                        $currentSelected = Get-PTSelectorNextIndex -CurrentIndex $currentSelected -Action 'PageDown' -TotalItems $filteredOptions.Count -PageSize $PageSize
                    }
                }
                'DrillDown' {
                    if ($AllowNavigationKeys -and $filteredOptions.Count -gt 0) {
                        $canMoveUp = [math]::Min($renderedLines, [Console]::CursorTop)
                        if ($canMoveUp -gt 0) { [Console]::Out.Write("`r`e[${canMoveUp}A`e[J") } else { [Console]::Out.Write("`r`e[J") }
                        $chosen = $filteredOptions[$currentSelected]
                        return [pscustomobject]@{
                            Action = 'DRILL_DOWN'
                            Value  = $chosen.Value
                            Type   = $chosen.Type
                            Label  = $chosen.Label
                            Data   = $chosen.Data
                        }
                    }
                }
                'Ascend' {
                    if ($AllowNavigationKeys) {
                        $canMoveUp = [math]::Min($renderedLines, [Console]::CursorTop)
                        if ($canMoveUp -gt 0) { [Console]::Out.Write("`r`e[${canMoveUp}A`e[J") } else { [Console]::Out.Write("`r`e[J") }
                        return [pscustomobject]@{
                            Action = 'ASCEND'
                        }
                    }
                }
                'Select' {
                    if ($filteredOptions.Count -gt 0) {
                        $chosen = $filteredOptions[$currentSelected]
                        $canMoveUp = [math]::Min($renderedLines, [Console]::CursorTop)
                        if ($canMoveUp -gt 0) { [Console]::Out.Write("`r`e[${canMoveUp}A`e[J") } else { [Console]::Out.Write("`r`e[J") }
                        [Console]::Out.WriteLine("$($theme.SuccessIcon)$($sym.DiamondFull)$($theme.Reset)  $Title  $($theme.Connector)$($sym.Pointer)$($theme.Reset)  $($theme.Bold)$($chosen.Label)$($theme.Reset)")
                        return $chosen.Value
                    }
                }
                'Cancel' {
                    $canMoveUp = [math]::Min($renderedLines, [Console]::CursorTop)
                    if ($canMoveUp -gt 0) { [Console]::Out.Write("`r`e[${canMoveUp}A`e[J") } else { [Console]::Out.Write("`r`e[J") }
                    [Console]::Out.WriteLine("$($theme.Connector)$($sym.DiamondOpen)$($theme.Reset)  $Title  $($theme.FaintGray)(Cancelado)$($theme.Reset)")
                    return $null
                }
                'Backspace' {
                    if ($AllowFilter -and $filterText.Length -gt 0) {
                        $filterText = $filterText.Substring(0, $filterText.Length - 1)
                        $currentSelected = 0
                    }
                }
                'Char' {
                    if ($AllowFilter) {
                        $filterText += $keyEvent.KeyChar
                        $currentSelected = 0
                    }
                }
            }
        }
    }
    finally {
        [Console]::Out.Write("`e[?25h")
        try { [Console]::CursorVisible = $true } catch { $null = $_ }
        try {
            [Console]::OutputEncoding = $origOutputEncoding
            [Console]::InputEncoding  = $origInputEncoding
        } catch { $null = $_ }
    }
}
