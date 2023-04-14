@{
        Root = 'C:\Users\Michaelsoft Binbows\Desktop\test\app_rewrite.ps1'
        OutputPath = 'C:\Users\Michaelsoft Binbows\Desktop\test'
        Package = @{
            Enabled = $true
            Obfuscate = $False
            HideConsoleWindow = $true
            DotNetVersion = 'netcoreapp31'
            FileVersion = '2.0.0'
            FileDescription = 'osu!NP for osu!lazer'
            ProductName = 'osu!NP'
            ProductVersion = '2023.414.0'
            Copyright = 'Hexality'
            RequireElevation = $false
            ApplicationIconPath = 'C:\Users\Michaelsoft Binbows\Desktop\test\app.ico' 
            HighDPISupport = $false
            PowerShellArguments = '-ExecutionPolicy Bypass'
            Platform = 'x64'
            PowerShellVersion = '7.3.2'
            RuntimeIdentifier = 'win-x64'
            DisableQuickEdit = $false
            Resources = [string[]]@()
        }
        Bundle = @{
            Enabled = $true
            Modules = $false
        }
    }
    