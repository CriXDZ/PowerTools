function Read-PTSemanticKey {

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $rawKey = [Console]::ReadKey($true)

    $action = switch ($rawKey.Key) {
        'UpArrow'    { 'Up' }
        'DownArrow'  { 'Down' }
        'PageUp'     { 'PageUp' }
        'PageDown'   { 'PageDown' }
        'Enter'      { 'Select' }
        'RightArrow' { 'DrillDown' }
        'Tab'        { 'DrillDown' }
        'LeftArrow'  { 'Ascend' }
        'Escape'     { 'Cancel' }
        'Backspace'  { 'Backspace' }
        default {
            if ($rawKey.KeyChar -eq 'q' -or $rawKey.KeyChar -eq 'Q') {
                'Cancel'
            }
            elseif (-not [char]::IsControl($rawKey.KeyChar)) {
                'Char'
            }
            else {
                'None'
            }
        }
    }

    return [PSCustomObject]@{
        Action  = $action
        KeyChar = $rawKey.KeyChar
        RawKey  = $rawKey.Key
    }
}
