<div align="center">

# PowerTools v2.0.0

### Suite de Alta Productividad y Scaffolding Interactivo para PowerShell 7

![PowerShell](https://img.shields.io/badge/PowerShell-7.x-0078D4?style=for-the-badge&logo=powershell&logoColor=white)
![Plataforma](https://img.shields.io/badge/Plataforma-Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white)
![Licencia](https://img.shields.io/badge/Licencia-MIT-2ea44f?style=for-the-badge)

</div>

---

## Propuesta de Valor

**PowerTools** es un modulo modular de PowerShell 7 diseñado para optimizar la experiencia de desarrollo en la consola de Windows, reducir la friccion al inicializar proyectos y automatizar tareas de mantenimiento comunes mediante interfaces modernas, simples y rapidas de usar.

El modulo sustituye comandos largos y repetitivos por un conjunto de alias intuitivos y selectores interactivos que priorizan la velocidad de ejecucion, la elegancia visual y la seguridad operativa.

---

## Caracteristicas Principales

- **Scaffolding Declarativo**: Inicializacion rapida de proyectos a partir de plantillas preconfiguradas (HTML, Node.js, Python, Vite) con apertura automatica en el editor de codigo del sistema.
- **Navegacion Determinista**: Saltos instantaneos a ubicaciones clave del sistema (`home`, `desk`, `docs`, `down`, `proj`) o marcadores personalizados persistentes con selector interactivo.
- **Hub de Historial**: Interfaz interactiva para inspeccionar, deduplicar o limpiar el historial de comandos de PSReadLine de forma rapida y sin residuos.
- **Mantenimiento Inteligente**: Asistente seguro para purgar temporales obsoletos (>24h), vaciar la Papelera de Reciclaje y limpiar caches de herramientas de desarrollo (`npm`, `pip`, `dotnet`).
- **Busqueda Web Asistida**: Enrutamiento rapido a motores y documentacion tecnica (Google, YouTube directo, GitHub, StackOverflow, MDN, DevDocs, Perplexity).
- **Audio y Enfoque**: Entornos acusticos y musica para concentracion profunda (lluvia suave, ruido marron, lo-fi beats, synthwave, ondas alfa) con inicio automatico en YouTube Music y streaming.
- **Catalogo Contextual**: Guia visual organizada por dominios funcionales con alineacion concisa de comandos y atajos de teclado.
- **Persistencia Desacoplada**: Configuracion determinista almacenada en `%LOCALAPPDATA%\PowerTools`.

---

## Instalacion y Configuracion

### 1. Clonar el repositorio

```powershell
Set-Location "$HOME\Documents\PowerShell\Modules"
git clone https://github.com/CriXDZ/PowerTools.git
```

### 2. Importar en el perfil de PowerShell

Agrega la siguiente instruccion a tu perfil (`$PROFILE`):

```powershell
Import-Module PowerTools -Force
```

---

## Catalogo de Comandos

| Comando | Descripcion |
| :--- | :--- |
| `pt-new` (`ptn`) | Scaffolding interactivo de proyectos en blanco o basados en plantillas. |
| `pt-go` (`ptg`) | Navegacion rapida por marcadores deterministas y selector interactivo. |
| `pt-mark` (`ptm`) | Guarda el directorio actual o especificado como marcador personalizado. |
| `pt-unmark` (`ptum`) | Elimina un marcador personalizado de la configuracion persistente. |
| `pt-search` (`pts`) | Busqueda web asistida con enrutamiento por prefijos y selector interactivo. |
| `pt-music` (`ptmu`) | Entornos acusticos y musica para concentracion profunda y sesion de trabajo. |
| `pt-hist` (`pth`) | Selector para deduplicar, inspeccionar o vaciar el historial de comandos. |
| `pt-clean` (`ptc`) | Asistente de mantenimiento seguro de temporales y caches (User/Dev/System/Full). |
| `pt-help` (`phlp`) | Guia contextual de ayuda visual organizada por categorias de comandos. |

---

## Compatibilidad de Entorno

PowerTools esta optimizado para Windows y es compatible con las siguientes herramientas:

- **Terminales**: Windows Terminal, ConEmu, WezTerm, Alacritty.
- **Editores e IDEs**: Antigravity IDE, Cursor, VS Code, Windsurf, Neovim, Notepad.

---

## Licencia

Este proyecto esta licenciado bajo los terminos de la Licencia **MIT**. Consulta el archivo [LICENSE](LICENSE) para obtener mas detalles.
