Set-StrictMode -Version Latest

Describe "Login page copy" {
    It "does not expose built-in test accounts in the UI source" {
        $content = Get-Content "$PSScriptRoot\..\..\entry\src\main\ets\pages\LoginPage.ets" -Raw

        $content | Should Not Match "测试账号"
        $content | Should Not Match "admin / admin123"
        $content | Should Not Match "operator / operator123"
    }
}
