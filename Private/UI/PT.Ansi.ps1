function Get-PTAnsiTheme {

    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        Reset              = "`e[0m"
        Bold               = "`e[1m"
        Dim                = "`e[2m"
        Underline          = "`e[4m"

        Accent             = "`e[38;2;0;210;255m"
        Connector          = "`e[38;2;120;120;120m"
        HeaderIcon         = "`e[38;2;0;210;255m"
        SuccessIcon        = "`e[1;32m"
        PaginationInfo     = "`e[38;2;140;140;140m"

        ItemActiveSymbol   = "`e[38;2;0;210;255m"
        ItemActiveLabel    = "`e[1;97m"
        ItemActiveDesc     = "`e[38;2;170;170;170m"

        ItemInactiveSymbol = "`e[38;2;100;100;100m"
        ItemInactiveLabel  = "`e[38;2;200;200;200m"
        ItemInactiveDesc   = "`e[38;2;120;120;120m"

        MatchHighlight     = "`e[1;38;2;0;210;255m`e[4m"

        FaintGray          = "`e[38;2;140;140;140m"
        Gray               = "`e[38;2;170;170;170m"
        Cyan               = "`e[36m"
        ActiveRow          = "`e[1;38;2;0;210;255m"
        NormalText         = "`e[38;2;200;200;200m"
        TagDir             = "`e[34m"
        TagMark            = "`e[33m"
        TagParent          = "`e[35m"
        TagAction          = "`e[32m"
        Border             = "`e[38;2;120;120;120m"
        Success            = "`e[1;32m"
        Warn               = "`e[1;33m"
        Error              = "`e[1;31m"
    }
}
