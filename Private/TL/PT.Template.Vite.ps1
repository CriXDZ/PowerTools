function New-ViteProject {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    if (-not (Test-Path -Path $ProjectPath -PathType Container)) {
        Write-PTMessage -Level Info -Message "Creando directorio del proyecto: $ProjectPath"
        New-Item -Path $ProjectPath -ItemType Directory -Force | Out-Null
    }

    if ((Get-Location).Path -ne $ProjectPath) {
        Set-Location -Path $ProjectPath
    }

    if (Test-CommandAvailability -CommandName 'yarn') {
        Write-PTMessage -Level Info -Message "Iniciando creación con Yarn ('yarn create vite .'). El asistente de Vite es interactivo."

        yarn create vite .
        if ($LASTEXITCODE -ne 0) {
            throw "yarn create vite falló con código de salida $LASTEXITCODE"
        }
    }
    else {
        Write-PTMessage -Level Warn -Message "Yarn no está disponible. Se intentará con npm."

        if (-not (Test-CommandAvailability -CommandName 'npm')) {
            throw "No se encontraron gestores de paquetes (yarn o npm) para crear el proyecto Vite"
        }

        Write-PTMessage -Level Info -Message "Iniciando creación con npm ('npm create vite@latest .'). El asistente de Vite es interactivo."
        npm create vite@latest .
        if ($LASTEXITCODE -ne 0) {
            throw "npm create vite falló con código de salida $LASTEXITCODE"
        }
    }

    $gitignorePath = Join-Path -Path $ProjectPath -ChildPath ".gitignore"
    if (-not (Test-Path $gitignorePath)) {
        $gitignoreContent = @"
node_modules/
dist/
.env
.DS_Store
*.local

# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
"@

        Set-Content -Path $gitignorePath -Value $gitignoreContent -Encoding utf8 -Force
    }
}
