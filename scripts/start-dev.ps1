[CmdletBinding()]
param(
    [switch]$NoExecute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ToolPaths {
    [PSCustomObject]@{
        DevEcoSdkHome = 'D:\Program Files\Huawei\DevEco Studio\sdk'
        NodeHome      = 'C:\Program Files\nodejs'
        JavaHome      = 'D:\Program Files\Huawei\DevEco Studio\jbr'
        HvigorBat     = 'D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat'
        OhpmBat       = 'D:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat'
        HdcExe        = 'D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
        NodeExe       = 'C:\Program Files\nodejs\node.exe'
        NpmCmd        = 'C:\Program Files\nodejs\npm.cmd'
    }
}

function Set-DevelopmentEnvironment {
    param(
        [Parameter(Mandatory = $true)]
        [object]$ToolPaths
    )

    $env:DEVECO_SDK_HOME = $ToolPaths.DevEcoSdkHome
    $env:NODE_HOME = $ToolPaths.NodeHome
    $env:JAVA_HOME = $ToolPaths.JavaHome

    $pathEntries = @(
        $ToolPaths.NodeHome,
        (Join-Path $ToolPaths.JavaHome 'bin'),
        (Split-Path $ToolPaths.HvigorBat -Parent),
        (Split-Path $ToolPaths.OhpmBat -Parent),
        (Split-Path $ToolPaths.HdcExe -Parent)
    )

    $existingEntries = $env:PATH -split ';'
    foreach ($entry in $pathEntries) {
        if ($existingEntries -notcontains $entry) {
            $env:PATH = "$entry;$env:PATH"
            $existingEntries = $env:PATH -split ';'
        }
    }
}

function Get-RepoRoot {
    Split-Path -Parent $PSScriptRoot
}

function Get-BackendPaths {
    $repoRoot = Get-RepoRoot
    $backendDir = Join-Path $repoRoot 'backend'
    [PSCustomObject]@{
        BackendDir = $backendDir
        PidFile    = Join-Path $backendDir '.dev-backend.pid'
        StdOutLog  = Join-Path $backendDir '.dev-backend.stdout.log'
        StdErrLog  = Join-Path $backendDir '.dev-backend.stderr.log'
        EnvFile    = Join-Path $backendDir '.env'
    }
}

function Get-ConfiguredApiHost {
    param(
        [string]$ApiConfigPath = (Join-Path (Get-RepoRoot) 'commons\datastore\src\main\ets\ApiConfig.ets')
    )

    $content = Get-Content $ApiConfigPath -Raw
    $match = [regex]::Match($content, "DEFAULT_HOST:\s*string\s*=\s*'([^']+)'")
    if (-not $match.Success) {
        throw "Failed to read DEFAULT_HOST from $ApiConfigPath"
    }
    $match.Groups[1].Value
}

function Get-ActualPrimaryIPv4 {
    try {
        $config = Get-NetIPConfiguration | Where-Object {
            $_.IPv4DefaultGateway -and $_.IPv4Address -and $_.NetAdapter.Status -eq 'Up'
        } | Select-Object -First 1
        if ($config -and $config.IPv4Address) {
            return $config.IPv4Address[0].IPv4Address
        }
    } catch {
    }

    $ipconfigOutput = ipconfig
    $candidate = $null
    $hasGateway = $false
    foreach ($line in $ipconfigOutput) {
        if ($line -match 'IPv4 Address[^\:]*:\s*([0-9\.]+)') {
            $candidate = $matches[1]
            $hasGateway = $false
            continue
        }
        if ($candidate -and $line -match 'Default Gateway[^\:]*:\s*([0-9\.]+)') {
            if ($matches[1]) {
                $hasGateway = $true
                break
            }
        }
    }

    if ($candidate -and $hasGateway) {
        return $candidate
    }

    $null
}

function Normalize-TargetList {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Targets
    )

    return ,@($Targets | Where-Object { $_ -and $_.Trim() })
}

function Get-NextStepCommands {
    $repoRoot = Get-RepoRoot
    $signedHap = Join-Path $repoRoot 'entry\build\default\outputs\default\entry-default-signed.hap'
    [PSCustomObject]@{
        Build   = 'hvigorw.bat assembleApp --no-daemon'
        Install = "hdc install -r '$signedHap'"
        Start   = 'hdc shell aa start -a EntryAbility -b com.example.machine_control'
    }
}

function Invoke-VersionCheck {
    param(
        [Parameter(Mandatory = $true)]
        [object]$ToolPaths
    )

    Write-Host 'Tool versions:'
    Write-Host "  node   : $(& $ToolPaths.NodeExe -v)"
    Write-Host "  hvigor : $(& $ToolPaths.HvigorBat -v)"
    Write-Host "  ohpm   : $(& $ToolPaths.OhpmBat -v)"
    Write-Host "  hdc    : $(& $ToolPaths.HdcExe version)"
}

function Ensure-MySqlServiceRunning {
    $service = Get-Service -Name 'MySQL80' -ErrorAction Stop
    if ($service.Status -eq 'Running') {
        Write-Host 'MySQL80 service is already running.'
        return
    }

    Write-Host 'Starting MySQL80 service...'
    try {
        Start-Service -Name 'MySQL80' -ErrorAction Stop
        $service.WaitForStatus('Running', '00:00:10')
        Write-Host 'MySQL80 service started.'
    } catch {
        throw 'Failed to start MySQL80. Try running this script in an elevated terminal.'
    }
}

function Ensure-BackendDependencies {
    param(
        [Parameter(Mandatory = $true)]
        [object]$BackendPaths,
        [Parameter(Mandatory = $true)]
        [object]$ToolPaths
    )

    $nodeModules = Join-Path $BackendPaths.BackendDir 'node_modules'
    if (Test-Path $nodeModules) {
        Write-Host 'Backend dependencies already installed.'
        return
    }

    Write-Host 'Installing backend dependencies...'
    Push-Location $BackendPaths.BackendDir
    try {
        & $ToolPaths.NpmCmd install | Out-Host
    } finally {
        Pop-Location
    }
}

function Stop-ExistingBackendProcess {
    param(
        [Parameter(Mandatory = $true)]
        [object]$BackendPaths
    )

    if (-not (Test-Path $BackendPaths.PidFile)) {
        return
    }

    $pidValue = (Get-Content $BackendPaths.PidFile -Raw).Trim()
    if (-not $pidValue) {
        Remove-Item $BackendPaths.PidFile -Force -ErrorAction SilentlyContinue
        return
    }

    $existingProcess = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
    if ($existingProcess) {
        Write-Host "Stopping previous backend process $pidValue..."
        Stop-Process -Id $existingProcess.Id -Force
    }

    Remove-Item $BackendPaths.PidFile -Force -ErrorAction SilentlyContinue
}

function Wait-BackendReady {
    param(
        [int]$Port = 3000,
        [int]$TimeoutSeconds = 20
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/devices" -Method Get | Out-Null
            return $true
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }

    $false
}

function Start-BackendProcess {
    param(
        [Parameter(Mandatory = $true)]
        [object]$BackendPaths,
        [Parameter(Mandatory = $true)]
        [object]$ToolPaths
    )

    Stop-ExistingBackendProcess -BackendPaths $BackendPaths

    if (-not (Test-Path $BackendPaths.EnvFile)) {
        throw "Backend env file is missing: $($BackendPaths.EnvFile)"
    }

    $process = Start-Process -FilePath $ToolPaths.NodeExe `
        -ArgumentList 'src/server.js' `
        -WorkingDirectory $BackendPaths.BackendDir `
        -WindowStyle Hidden `
        -RedirectStandardOutput $BackendPaths.StdOutLog `
        -RedirectStandardError $BackendPaths.StdErrLog `
        -PassThru

    Set-Content $BackendPaths.PidFile -Value $process.Id -Encoding ASCII

    if (-not (Wait-BackendReady)) {
        throw "Backend failed to become ready. Check logs: $($BackendPaths.StdOutLog), $($BackendPaths.StdErrLog)"
    }

    Write-Host "Backend started. PID: $($process.Id)"
    Write-Host 'API URL: http://127.0.0.1:3000/api'
}

function Get-EmulatorTargets {
    param(
        [Parameter(Mandatory = $true)]
        [object]$ToolPaths
    )

    $targets = & $ToolPaths.HdcExe list targets
    @($targets | Where-Object { $_ -and $_.Trim() })
}

function Show-HostConsistencyWarning {
    $configuredHost = Get-ConfiguredApiHost
    $actualHost = Get-ActualPrimaryIPv4

    if (-not $actualHost) {
        Write-Warning 'Could not detect a primary IPv4 address automatically.'
        return
    }

    if ($configuredHost -ne $actualHost) {
        Write-Warning "ApiConfig host ($configuredHost) does not match current primary IPv4 ($actualHost)."
        Write-Warning 'Update commons/datastore/src/main/ets/ApiConfig.ets before running the app if needed.'
        return
    }

    Write-Host "ApiConfig host matches current IPv4: $actualHost"
}

function Show-NextSteps {
    $commands = Get-NextStepCommands
    Write-Host ''
    Write-Host 'Next commands:'
    Write-Host "  Build   : $($commands.Build)"
    Write-Host "  Install : $($commands.Install)"
    Write-Host "  Start   : $($commands.Start)"
}

function Start-DevelopmentEnvironment {
    $toolPaths = Get-ToolPaths
    $backendPaths = Get-BackendPaths

    Set-DevelopmentEnvironment -ToolPaths $toolPaths
    Invoke-VersionCheck -ToolPaths $toolPaths
    Ensure-MySqlServiceRunning
    Ensure-BackendDependencies -BackendPaths $backendPaths -ToolPaths $toolPaths
    Start-BackendProcess -BackendPaths $backendPaths -ToolPaths $toolPaths
    Show-HostConsistencyWarning

    $targets = @(Get-EmulatorTargets -ToolPaths $toolPaths)
    if ($targets.Count -gt 0) {
        Write-Host "Connected emulator/device targets: $($targets -join ', ')"
    } else {
        Write-Warning 'No HarmonyOS emulator/device detected. Open the emulator before installing the app.'
    }

    Show-NextSteps
}

if (-not $NoExecute) {
    Start-DevelopmentEnvironment
}


