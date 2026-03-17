Set-StrictMode -Version Latest

. "$PSScriptRoot\..\start-dev.ps1" -NoExecute

Describe "start-dev helpers" {
    It "returns the expected fixed tool paths" {
        $paths = Get-ToolPaths

        $paths.DevEcoSdkHome | Should Be "D:\Program Files\Huawei\DevEco Studio\sdk"
        $paths.NodeHome | Should Be "C:\Program Files\nodejs"
        $paths.JavaHome | Should Be "D:\Program Files\Huawei\DevEco Studio\jbr"
        $paths.HvigorBat | Should Be "D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat"
        $paths.OhpmBat | Should Be "D:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin\ohpm.bat"
        $paths.HdcExe | Should Be "D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
    }

    It "reads a valid ipv4 host from ApiConfig.ets" {
        $apiHost = Get-ConfiguredApiHost -ApiConfigPath "$PSScriptRoot\..\..\commons\datastore\src\main\ets\ApiConfig.ets"

        $apiHost | Should Match '^\d{1,3}(\.\d{1,3}){3}$'
    }

    It "returns the expected follow-up commands" {
        $commands = Get-NextStepCommands

        $commands.Build | Should Match "assembleApp --no-daemon"
        $commands.Install | Should Match "hdc install -r"
        $commands.Start | Should Match "aa start -a EntryAbility -b com.example.machine_control"
    }

    It "normalizes a single emulator target into a countable array" {
        $targets = Normalize-TargetList -Targets '127.0.0.1:5555'

        $targets.Count | Should Be 1
        $targets[0] | Should Be '127.0.0.1:5555'
    }
}
