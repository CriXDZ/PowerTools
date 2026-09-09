function New-PythonProject {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    if (-not (Test-Path -Path $ProjectPath -PathType Container)) {
        $null = New-Item -Path $ProjectPath -ItemType Directory -Force
    }

    $directories = @("src", "tests")
    foreach ($dir in $directories) {
        $path = Join-Path -Path $ProjectPath -ChildPath $dir
        if (-not (Test-Path -Path $path -PathType Container)) {
            $null = New-Item -Path $path -ItemType Directory -Force
        }
    }

    $mainContent = @"
#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""$ProjectName - Módulo principal"""

def main():
    """Función principal del programa"""
    print(f"Iniciando {__name__}...")

    # Tu código aquí

    print("Finalizado")

if __name__ == "__main__":
    main()
"@

    $treeFiles = @{
        'src/main.py'      = $mainContent
        'src/__init__.py'  = $initContent
        'README.md'        = $readmeContent
        'requirements.txt' = $requirementsContent
        '.gitignore'       = $gitignoreContent
    }

    Invoke-PTScaffoldTree -BasePath $ProjectPath -Directories @('src', 'tests') -Files $treeFiles

    if (Test-CommandAvailability -CommandName 'python') {
        $currentLocation = Get-Location
        Set-Location -Path $ProjectPath
        python -m venv venv 2>$null
        Set-Location -Path $currentLocation
    }
}
