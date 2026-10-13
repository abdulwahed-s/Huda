param(
    [string]$OutputDirectory,
    [string]$DotnetPath = 'dotnet',
    [string]$Version
)
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '../..'))
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $repositoryRoot 'build/windows/x64/runner/Release/prayer_taskbar'
}
if (-not $Version) {
    $pubspec = Get-Content -LiteralPath (Join-Path $repositoryRoot 'pubspec.yaml') -Raw
    if ($pubspec -notmatch '(?m)^version:\s*(\d+\.\d+\.\d+)') { throw 'Huda version is missing.' }
    $Version = $Matches[1]
}
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw 'A Huda semantic release version is required.' }
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$project = Join-Path $projectRoot 'Huda.PrayerTaskbar/Huda.PrayerTaskbar.csproj'
$previousLibraryPaths = $env:LIB
# Visual Studio can pass stale SDK paths to this C# build. Retain the existing
# native search directories without passing nonexistent paths to csc.
if ($env:LIB) {
    $env:LIB = (($env:LIB -split ';' | Where-Object {
        $_ -and (Test-Path -LiteralPath $_.Trim('"') -PathType Container)
    }) -join ';')
}
Push-Location -LiteralPath $projectRoot
try {
    & $DotnetPath restore $project --locked-mode -p:Platform=x64
    if ($LASTEXITCODE -ne 0) { throw 'Windows companion dependency restore failed.' }
    & $DotnetPath publish $project -c Release -p:Platform=x64 "-p:HudaVersion=$Version" --no-restore -o $OutputDirectory
    if ($LASTEXITCODE -ne 0) { throw 'Windows companion publish failed.' }
    if (-not (Test-Path -LiteralPath (Join-Path $OutputDirectory 'Huda.PrayerTaskbar.exe'))) {
        throw 'The Windows companion executable was not published.'
    }
    foreach ($asset in @('resources.pri', 'App.xbf', 'Microsoft.UI.Xaml.dll', 'coreclr.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $OutputDirectory $asset))) {
            throw "The self-contained companion is missing $asset."
        }
    }
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'xv/windows/prayer_taskbar/THIRD_PARTY_NOTICES.md') -Destination $OutputDirectory
    Copy-Item -LiteralPath (Join-Path $repositoryRoot 'xv/windows/prayer_taskbar/Licenses') -Destination $OutputDirectory -Recurse -Force
    $assetsPath = Join-Path $projectRoot 'Huda.PrayerTaskbar/obj/project.assets.json'
    $assets = Get-Content -LiteralPath $assetsPath -Raw | ConvertFrom-Json
    foreach ($library in $assets.libraries.PSObject.Properties) {
        if ($library.Value.type -ne 'package') { continue }
        foreach ($folder in $assets.packageFolders.PSObject.Properties.Name) {
            $packagePath = Join-Path $folder $library.Value.path
            if (-not (Test-Path -LiteralPath $packagePath)) { continue }
            $notices = Get-ChildItem -LiteralPath $packagePath -File |
                Where-Object { $_.Name -match '(?i)license|notice' }
            if ($notices) {
                $noticePath = Join-Path $OutputDirectory ('Licenses/nuget/' + $library.Name.Replace('/', '-'))
                New-Item -ItemType Directory -Path $noticePath -Force | Out-Null
                foreach ($notice in $notices) {
                    Copy-Item -LiteralPath $notice.FullName -Destination $noticePath -Force
                }
            }
            break
        }
    }
} finally { Pop-Location; $env:LIB = $previousLibraryPaths }
