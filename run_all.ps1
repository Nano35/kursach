<#
run_all.ps1

Запускает backend (uvicorn) в фоне и затем запускает flutter run.
Для Windows. Предполагает, что проект имеет структуру с папкой `backend` и `mobile-flutter`.

Пример использования (PowerShell):
.\run_all.ps1

#>
Set-StrictMode -Version Latest

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $root 'backend'
$flutterDir = Join-Path $root 'mobile-flutter'

Write-Output "Working root: $root"

if (-not (Test-Path $backendDir)) {
    Write-Error "Backend folder not found: $backendDir"
    exit 1
}

# Determine python executable: prefer .venv, fallback to system python
$venvPython = Join-Path $backendDir '.venv\Scripts\python.exe'
$python = $null
if (Test-Path $venvPython) {
    $python = $venvPython
    Write-Output "Using venv python: $python"
} else {
    $python = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $python) {
        Write-Error "python not found in PATH and .venv not present. Please install Python or create .venv"
        exit 1
    }
    Write-Output "Using system python: $python"
}

# Start uvicorn as background process and capture PID
$uvicornArgs = '-m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --app-dir "' + $backendDir + '"'
Write-Output "Starting backend: $python $uvicornArgs"
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = $python
$startInfo.Arguments = $uvicornArgs
$startInfo.WorkingDirectory = $backendDir
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.UseShellExecute = $false

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $startInfo
$proc.Start() | Out-Null

# Write logs to files
$logOut = Join-Path $backendDir 'server_stdout.log'
$logErr = Join-Path $backendDir 'server_stderr.log'
[System.IO.File]::WriteAllText($logOut, "")
[System.IO.File]::WriteAllText($logErr, "")

# Async readers
[void][System.Threading.Tasks.Task]::Run({
    while (-not $proc.HasExited) {
        try { $line = $proc.StandardOutput.ReadLine(); if ($line -ne $null) { Add-Content -Path $logOut -Value $line } }
        catch { break }
    }
})
[void][System.Threading.Tasks.Task]::Run({
    while (-not $proc.HasExited) {
        try { $line = $proc.StandardError.ReadLine(); if ($line -ne $null) { Add-Content -Path $logErr -Value $line } }
        catch { break }
    }
})

Write-Output "Backend started (PID=$($proc.Id)). Logs: $logOut, $logErr"

try {
    # Run flutter in foreground
    if (-not (Test-Path $flutterDir)) {
        Write-Error "Flutter folder not found: $flutterDir"
        throw "missing flutter"
    }

    Push-Location $flutterDir
    Write-Output "Running: flutter run (in $flutterDir)"
    & flutter run
    $exitCode = $LASTEXITCODE
    Pop-Location
    Write-Output "flutter run exited with code $exitCode"
} finally {
    if ($proc -and -not $proc.HasExited) {
        Write-Output "Stopping backend (PID=$($proc.Id))..."
        try { $proc.Kill(); $proc.WaitForExit(3000) } catch {}
        Write-Output "Backend stopped."
    }
}

exit 0
