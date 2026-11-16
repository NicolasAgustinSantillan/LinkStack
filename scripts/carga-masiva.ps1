#!/usr/bin/env pwsh
# carga-masiva.ps1 — Generar el SQL de carga masiva de usuarios desde un Excel
#
# El Excel (o CSV) tiene 3 columnas: Nombre | Apellido | Correo
# Genera un .sql a partir de scripts/carga-masiva.sql para ejecutar en MySQL (DBeaver: Alt+X).
#
# Uso:
#   pwsh scripts/carga-masiva.ps1                      (abre una ventana para elegir el Excel)
#   pwsh scripts/carga-masiva.ps1 -Archivo personas.xlsx
#   pwsh scripts/carga-masiva.ps1 -Archivo personas.xlsx -Plantilla Antares -Password "OtraClave"

param(
    [string] $Archivo,                          # .xlsx o .csv (si se omite, se elige en una ventana)
    [string] $Plantilla = "Antares",            # nombre en Admin → Plantillas de usuarios
    [string] $Password,                         # contraseña inicial (default: la de carga-masiva.sql, Antares2026!)
    [string] $Salida                            # default: junto al Excel, carga-masiva-<fecha>.sql
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==================================="
Write-Host "  ANTARES-LINKSTACK — Carga masiva"
Write-Host "==================================="
Write-Host ""

if (-not $Archivo) {
    if ($IsWindows) {
        Add-Type -AssemblyName System.Windows.Forms
        $dialog = [System.Windows.Forms.OpenFileDialog]::new()
        $dialog.Title = "Excel con las personas a cargar (Nombre | Apellido | Correo)"
        $dialog.Filter = "Excel o CSV (*.xlsx;*.csv)|*.xlsx;*.csv"
        if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { Write-Host "  Cancelado."; exit 1 }
        $Archivo = $dialog.FileName
    } else {
        $Archivo = Read-Host "  Ruta del Excel o CSV"
    }
}
$Archivo = (Resolve-Path $Archivo.Trim('"', "'", ' ')).Path
$base = Join-Path $PSScriptRoot "carga-masiva.sql"
if (-not $Salida) {
    $Salida = Join-Path (Split-Path $Archivo -Parent) ("carga-masiva-{0:yyyyMMdd-HHmm}.sql" -f (Get-Date))
}

# — Leer el archivo
Write-Host "[ 1/4 ] Leyendo $Archivo..."
switch ([IO.Path]::GetExtension($Archivo).ToLower()) {
    ".xlsx" {
        if (-not (Get-Module -ListAvailable ImportExcel)) {
            $install = Read-Host "  Falta el modulo ImportExcel (lee Excel sin tener Office). Instalarlo? [S/n]"
            if ($install -match '^[nN]$') { Write-Host "  Guardá el Excel como CSV y volvé a correr el script." -ForegroundColor Yellow; exit 1 }
            Install-Module ImportExcel -Scope CurrentUser -Force
        }
        Import-Module ImportExcel
        $rows = @(Import-Excel -Path $Archivo)
    }
    ".csv" {
        # Excel en español guarda CSV con ';'
        $firstLine = Get-Content $Archivo -TotalCount 1
        $delimiter = if ($firstLine -like "*;*") { ";" } else { "," }
        $rows = @(Import-Csv -Path $Archivo -Delimiter $delimiter)
    }
    default { Write-Host "  ERROR: el archivo tiene que ser .xlsx o .csv" -ForegroundColor Red; exit 1 }
}

# — Columnas (sin importar mayúsculas ni acentos)
function Normalize([string]$s) {
    $d = $s.Trim().ToLower().Normalize([Text.NormalizationForm]::FormD)
    -join ($d.ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' })
}
$columns = @{}
foreach ($p in $rows[0].PSObject.Properties.Name) {
    switch -Regex (Normalize $p) {
        '^nombres?$'                          { $columns.nombre = $p }
        '^apellidos?$'                        { $columns.apellido = $p }
        '^(correo|email|e-mail|mail).*'       { $columns.correo = $p }
    }
}
foreach ($c in "nombre", "apellido", "correo") {
    if (-not $columns[$c]) { Write-Host "  ERROR: falta la columna '$c'. Columnas encontradas: $($rows[0].PSObject.Properties.Name -join ', ')" -ForegroundColor Red; exit 1 }
}

# — Validar y armar los usuarios
Write-Host "[ 2/4 ] Validando..."
$people = [System.Collections.Generic.List[object]]::new()
$emails = @{}; $handles = @{}; $errors = 0; $line = 1
foreach ($r in $rows) {
    $line++
    $nombre   = "$($r.($columns.nombre))".Trim()
    $apellido = "$($r.($columns.apellido))".Trim()
    $correo   = "$($r.($columns.correo))".Trim().ToLower()
    if (-not $nombre -and -not $apellido -and -not $correo) { continue }   # fila vacía

    if (-not $nombre -or -not $correo) {
        Write-Host "  Fila ${line}: falta nombre o correo, se omite." -ForegroundColor Yellow; $errors++; continue
    }
    if ($correo -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
        Write-Host "  Fila ${line}: correo invalido '$correo', se omite." -ForegroundColor Yellow; $errors++; continue
    }
    if ($emails.ContainsKey($correo)) {
        Write-Host "  Fila ${line}: correo repetido '$correo' (ya esta en la fila $($emails[$correo])), se omite." -ForegroundColor Yellow; $errors++; continue
    }
    $emails[$correo] = $line

    # /@usuario = parte del correo antes de la @ (LinkStack acepta letras, numeros, - y _)
    $handle = ((Normalize ($correo -split '@')[0]) -replace '[^a-z0-9_-]+', '-').Trim('-')
    if ($handle.Length -gt 45) { $handle = $handle.Substring(0, 45) }
    $candidate = $handle; $n = 2
    while ($handles.ContainsKey($candidate)) { $candidate = "$handle$n"; $n++ }
    $handles[$candidate] = $true

    $people.Add([pscustomobject]@{ Nombre = "$nombre $apellido".Trim(); Correo = $correo; Usuario = $candidate })
}
if ($people.Count -eq 0) { Write-Host "  ERROR: no hay personas validas para cargar." -ForegroundColor Red; exit 1 }
$people | Format-Table @{ n = "Fila"; e = { $emails[$_.Correo] } }, Nombre, Correo, @{ n = "/@usuario"; e = { $_.Usuario } } -AutoSize | Out-Host

# — Hash de la contraseña (bcrypt con el PHP de la imagen, no requiere PHP local)
$hash = $null
if ($Password) {
    Write-Host "[ 3/4 ] Generando hash de la contraseña..."
    $hash = (docker run --rm php:8.2-cli php -r 'echo password_hash($argv[1], PASSWORD_BCRYPT);' -- $Password)
    if ($LASTEXITCODE -ne 0 -or $hash -notmatch '^\$2y\$') { Write-Host "  ERROR: no se pudo generar el hash (¿Docker esta corriendo?)." -ForegroundColor Red; exit 1 }
} else {
    Write-Host "[ 3/4 ] Contraseña inicial: Antares2026!"
}

# — Generar el SQL a partir de carga-masiva.sql
Write-Host "[ 4/4 ] Generando SQL..."
function SqlString([string]$s) { "'" + $s.Replace('\', '\\').Replace("'", "''") + "'" }

$values = ($people | ForEach-Object {
    "  ($(SqlString $_.Nombre), $(SqlString $_.Correo), $(SqlString $_.Usuario), @plantilla)"
}) -join ",`n"

$sql = Get-Content $base -Raw
# Evaluadores en lugar de strings de reemplazo: el hash bcrypt contiene '$'
$sql = [regex]::Replace($sql, "SET @plantilla = '[^']*';", { "SET @plantilla = $(SqlString $Plantilla);" })
$sql = [regex]::Replace($sql, '(?s)(INSERT INTO carga \(name, email, littlelink_name, template\) VALUES\r?\n).*?;', { param($m) $m.Groups[1].Value + $values + ";" })
if ($hash) {
    $sql = [regex]::Replace($sql, "'\`$2y\`$[^']+',(\s*)-- .*", { param($m) "'$hash',$($m.Groups[1].Value)-- contraseña inicial indicada en -Password" })
    $sql = $sql -replace '(?m)^-- Contraseña inicial de todos: .*$', '-- Contraseña inicial: la indicada en -Password (pedirles que la cambien)'
}
$sql = $sql -replace '(?m)^-- scripts/carga-masiva\.ps1 genera.*$', "-- Generado por scripts/carga-masiva.ps1 desde $(Split-Path $Archivo -Leaf) el $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

[IO.File]::WriteAllText($Salida, $sql, [Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "==================================="
Write-Host "  SQL generado"
Write-Host "==================================="
Write-Host "  Personas:  $($people.Count)$(if ($errors) { "  (omitidas: $errors)" })"
Write-Host "  Plantilla: $Plantilla"
Write-Host "  Archivo:   $Salida"
Write-Host ""
Write-Host "  Abrilo en DBeaver sobre la base de LinkStack y ejecutalo como script (Alt+X)."
Write-Host "  La ultima consulta muestra quien se creo; user_id vacio = el /@usuario ya existia."
Write-Host ""
