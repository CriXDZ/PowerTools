function New-PTProject {
    <#
    .SYNOPSIS
        Crea, inicializa y configura un nuevo entorno de desarrollo.
    .DESCRIPTION
        Orquestador de alto nivel para la creacion de proyectos de desarrollo:
        valida argumentos, permite seleccion interactiva de plantillas, delega el scaffolding
        al motor declarativo de plantillas y abre opcionalmente el proyecto
        en el editor configurado.
    .PARAMETER Name
        Nombre del proyecto. Se valida contra caracteres invalidos y nombres reservados del sistema operativo.
    .PARAMETER Type
        Tipo de plantilla ('Node', 'Python', 'HTML', 'Vite', 'Default'). Si se omite, se despliega el selector interactivo.
    .PARAMETER Path
        Ruta base o directorio destino. Si se omite, utiliza la ruta configurada por defecto o el workspace actual.
    .PARAMETER OpenIDE
        Abre el proyecto recien creado en el editor de codigo predeterminado.
    .PARAMETER Force
        Sobrescribe el directorio destino si ya existe previo a la ejecucion.
    .PARAMETER PassThru
        Devuelve el objeto estructurado [PSCustomObject] con la metadata del proyecto creado al pipeline.
    .EXAMPLE
        New-PTProject -Name "mi-api" -Type Node -OpenIDE
    .EXAMPLE
        New-PTProject -Name "mi-web" -Type HTML -Path "./proyectos"
    .EXAMPLE
        pt-new -Name "script-demo" -Type Python -PassThru
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Name,

        [Parameter(Position = 1)]
        [string] $Type,

        [Parameter(Position = 2)]
        [Alias('BasePath')]
        [string] $Path,

        [switch] $OpenIDE,

        [switch] $Force,

        [switch] $PassThru
    )

    begin {
        $e = [string][char]0x1B
        $theme = if (Get-Command -Name 'Get-PTAnsiTheme' -ErrorAction SilentlyContinue) {
            Get-PTAnsiTheme
        } else {
            @{
                Reset       = "$e[0m"
                Bold        = "$e[1m"
                Accent      = "$e[38;2;0;210;255m"
                Connector   = "$e[38;2;120;120;120m"
                HeaderIcon  = "$e[38;2;0;210;255m"
                FaintGray   = "$e[38;2;140;140;140m"
                Success     = "$e[38;2;46;204;113m"
            }
        }

        $sDiamond = [string][char]0x25C7
        $sPipe    = [string][char]0x2502
        $sCorner  = [string][char]0x2514
    }

    process {
        $cConn = $theme.Connector
        $cRst  = $theme.Reset
        $cHdr  = $theme.HeaderIcon
        $cBld  = $theme.Bold
        $cFnt  = $theme.FaintGray
        $cAcc  = $theme.Accent

        if ([string]::IsNullOrWhiteSpace($Name)) {
            Write-Host ""
            Write-Host "$cHdr$sDiamond$cRst  ${cBld}Nuevo Proyecto$cRst"
            Write-Host "$cConn$sPipe$cRst"
            Write-Host "$cConn$sPipe$cRst  ${cFnt}Ingrese el nombre del proyecto:$cRst " -NoNewline
            $Name = Read-Host
            if ([string]::IsNullOrWhiteSpace($Name)) {
                Write-Host "$cConn$sCorner$cRst  Operacion cancelada por el usuario." -ForegroundColor Yellow
                return
            }
            Write-Host "$cConn$sPipe$cRst"
        }

        $Name = $Name.Trim()

        if ($Name -notmatch '^[a-zA-Z0-9_\-\.]+$') {
            $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord(
                (New-Object System.ArgumentException("El nombre del proyecto no contiene caracteres validos.")),
                'InvalidProjectName',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Name
            )))
            return
        }

        $reservedNames = @('CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9')
        if ($reservedNames -contains $Name.ToUpperInvariant()) {
            $PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord(
                (New-Object System.ArgumentException("El nombre especificado es un nombre reservado del sistema operativo.")),
                'ReservedProjectName',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Name
            )))
            return
        }

        if ([string]::IsNullOrWhiteSpace($Type)) {
            $templates = if (Get-Command -Name 'Get-PTProjectTemplate' -ErrorAction SilentlyContinue) {
                Get-PTProjectTemplate
            } else { @() }

            if ($templates.Count -eq 0) {
                Write-Error "No se encontraron plantillas registradas en el sistema."
                return
            }

            $templateOptions = @($templates | ForEach-Object {
                [PSCustomObject]@{
                    Label       = $_.Label
                    Value       = $_.Id
                    Description = $_.Description
                }
            })

            $selectedType = Invoke-PTSelector -Title "Seleccione la plantilla del proyecto:" -Options $templateOptions -PageSize 6

            if ([string]::IsNullOrWhiteSpace($selectedType)) {
                Write-Host "$cConn$sCorner$cRst  Creacion de proyecto cancelada." -ForegroundColor Yellow
                return
            }
            $Type = $selectedType
        }

        $targetTemplate = if (Get-Command -Name 'Get-PTProjectTemplate' -ErrorAction SilentlyContinue) {
            Get-PTProjectTemplate -Id $Type
        } else { $null }

        if (-not $targetTemplate) {
            Write-Error "La plantilla especificada no esta registrada en el motor de plantillas."
            return
        }

        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = if (Get-Command -Name 'Get-PTDefaultProjectPath' -ErrorAction SilentlyContinue) {
                Get-PTDefaultProjectPath
            } else {
                $PWD.ProviderPath
            }
        }

        $parentPath = if (Get-Command -Name 'Resolve-PTWorkspacePath' -ErrorAction SilentlyContinue) {
            Resolve-PTWorkspacePath -Path $Path
        } else {
            $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        }
        $projectPath = [System.IO.Path]::Combine($parentPath, $Name)

        if ((Test-Path -Path $projectPath) -and -not $Force) {
            Write-Error "El proyecto ya existe en el directorio destino. Utilice -Force para sobrescribir."
            return
        }

        $actionDesc = "Crear proyecto con plantilla"
        if ($PSCmdlet.ShouldProcess($projectPath, $actionDesc)) {
            $createdAt = [DateTime]::Now

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            & $targetTemplate.Build $projectPath $Name
            $sw.Stop()

            $elapsedSec = ($sw.ElapsedMilliseconds / 1000).ToString('F2')

            $displayPath = if (Get-Command -Name 'Format-PTBreadcrumb' -ErrorAction SilentlyContinue) {
                Format-PTBreadcrumb -Path $projectPath
            } else {
                $projectPath
            }

            $tplDesc = $targetTemplate.Description

            Write-Host ""
            Write-Host "$cConn$sPipe$cRst"
            Write-Host "$cHdr$sDiamond$cRst  ${cBld}Proyecto '$Name' inicializado con exito$cRst ${cFnt}($elapsedSec s)$cRst"
            Write-Host "$cConn$sPipe$cRst"
            Write-Host "$cConn$sPipe$cRst  ${cFnt}Plantilla:$cRst  ${cBld}$Type$cRst ${cFnt}($tplDesc)$cRst"
            Write-Host "$cConn$sPipe$cRst  ${cFnt}Ubicacion:$cRst  $cAcc$displayPath$cRst"
            Write-Host "$cConn$sPipe$cRst"
            Write-Host "$cConn$sCorner$cRst  ${cBld}Siguientes pasos:$cRst"
            if ($targetTemplate.NextSteps) {
                foreach ($step in $targetTemplate.NextSteps) {
                    Write-Host "     $cAcc$step$cRst"
                }
            }
            Write-Host ""

            if ($OpenIDE) {
                if (Get-Command -Name 'Invoke-PTEditor' -ErrorAction SilentlyContinue) {
                    Invoke-PTEditor -Path $projectPath
                }
            }

            $result = [PSCustomObject]@{
                Name      = $Name
                Path      = $projectPath
                Type      = $Type
                CreatedAt = $createdAt
            }

            if ($PassThru) {
                return $result
            }
        }
    }
}

New-Alias -Name 'pt-new' -Value New-PTProject -Force
New-Alias -Name 'ptn'    -Value New-PTProject -Force
