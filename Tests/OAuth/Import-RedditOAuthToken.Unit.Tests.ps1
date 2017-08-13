<#	
    .NOTES
    
     Created with:  VSCode
     Created on:    05/11/2017 4:41 AM
     Edited on:     05/20/2017
     Created by:    Mark Kraus
     Organization: 	
     Filename:      Import-RedditOAuthToken.Unit.Tests.ps1
    
    .DESCRIPTION
        Import-RedditOAuthToken Function unit tests
#>

$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."
$ModuleRoot = Split-Path (Resolve-Path "$ProjectRoot\*\*.psd1")
$ModuleName = Split-Path $ModuleRoot -Leaf
Remove-Module -Force $ModuleName  -ErrorAction SilentlyContinue
Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -force
$Module = Get-Module -Name $ModuleName

$Command = 'Import-RedditOAuthToken'
$TypeName = 'RedditOAuthToken'

function InitVariables {
    $ClientId = '54321'
    $ClientSecret = '12345'
    $SecClientSecret = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force 
    $ClientCredential = [pscredential]::new($ClientId, $SecClientSecret)

    $UserId = 'reddituser'
    $UserSecret = 'password12345'
    $SecUserSecret = $UserSecret | ConvertTo-SecureString -AsPlainText -Force 
    $UserCredential = [pscredential]::new($UserId, $SecUserSecret)

    $TokenId = 'access_token'
    $TokenSecret = '34567'
    $SecTokenSecret = $TokenSecret | ConvertTo-SecureString -AsPlainText -Force 
    $TokenCredential = [pscredential]::new($TokenId, $SecTokenSecret)

    $ExportFile = '{0}\RedditApplicationExport-{1}.xml' -f $TestDrive, [guid]::NewGuid().toString()
    $TokenExportFile = '{0}\RedditTokenExport-{1}.xml' -f $TestDrive, [guid]::NewGuid().toString()

    $Application = [RedditApplication]@{
        Name             = 'TestApplication'
        Description      = 'This is only a test'
        RedirectUri      = 'https://localhost/'
        UserAgent        = 'windows:PSRAW-Unit-Tests:v1.0.0.0'
        Scope            = 'read'
        ClientCredential = $ClientCredential
        UserCredential   = $UserCredential
        Type             = 'Script'
        ExportPath       = $ExportFile 
    }

    $TokenScript = [RedditOAuthToken]@{
        Application        = $Application
        IssueDate          = Get-Date
        ExpireDate         = (Get-Date).AddHours(1)
        LastApiCall        = Get-Date
        ExportPath         = $TokenExportFile
        Scope              = $Application.Scope
        GUID               = [guid]::NewGuid()
        Notes              = 'This is a test token'
        TokenType          = 'bearer'
        GrantType          = 'Password'
        RateLimitUsed      = 0
        RateLimitRemaining = 60
        RateLimitRest      = 60
        TokenCredential    = $TokenCredential
    }

    $TokenScript | Export-Clixml -Path $TokenExportFile 

    $ParameterSets = @(
        @{
            Name   = 'Path'
            Params = @{
                Path = $TokenExportFile
            }
        }
        @{
            Name   = 'LiteralPath'
            Params = @{
                LiteralPath = $TokenExportFile
            }
        }
        @{
            Name   = 'Path PassThru'
            Params = @{
                Path     = $TokenExportFile
                PassThru = $true
            }
        }
        @{
            Name   = 'LiteralPath PassThru'
            Params = @{
                LiteralPath = $TokenExportFile
                PassThru    = $true
            }
        }
    )
}

function MyTest {
    foreach ($ParameterSet in $ParameterSets) {
        It "'$($ParameterSet.Name)' Parameter set does not have errors" {
            $LocalParams = $ParameterSet.Params
            { & $Command @LocalParams -ErrorAction Stop } | Should not throw
        }
    }
    It "Emits a $TypeName Object" {
        (Get-Command $Command).OutputType.Name.where( { $_ -eq $TypeName }) | Should be $TypeName
    }
    It "Returns a $TypeName Object with -PassThru" {
        $LocalParams = $ParameterSets[-1].Params.psobject.Copy()
        $Object = & $Command @LocalParams | Select-Object -First 1
        $Object.psobject.typenames.where( { $_ -eq $TypeName }) | Should be $TypeName
    }
    It "Sets the imported token as the default token" {
        & $Module { $PsrawSettings.AccessToken = $null }
        & $Module { $PsrawSettings.AccessToken } | Should BeNullOrEmpty
        $LocalParams = $ParameterSet.Params
        { & $Command @LocalParams -ErrorAction Stop } | Should not throw
        & $Module { $PsrawSettings.AccessToken.GUID } |Should Be $TokenScript.GUID
    }
}

Describe "$command Unit" -Tags Unit {
    $CommandPresent = Get-Command -Name $Command -Module $ModuleName -ErrorAction SilentlyContinue
    if (-not $CommandPresent) {
        Write-Warning "'$command' was not found in '$ModuleName' during pre-build tests. It may not yet have been added the module. Unit tests will be skipped until after build."
        return
    }
    . InitVariables
    MyTest
}

Describe "$command Build" -Tags Build {
    . InitVariables
    MyTest
}