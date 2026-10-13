param([Parameter(Mandatory = $true)][string]$ManifestPath)
$ErrorActionPreference = 'Stop'
[xml]$manifest = Get-Content -LiteralPath $ManifestPath -Raw
$foundation = 'http://schemas.microsoft.com/appx/manifest/foundation/windows10'
$desktop = 'http://schemas.microsoft.com/appx/manifest/desktop/windows10'
$uap10 = 'http://schemas.microsoft.com/appx/manifest/uap/windows10/10'
$manager = [Xml.XmlNamespaceManager]::new($manifest.NameTable)
$manager.AddNamespace('f', $foundation)
$manager.AddNamespace('desktop', $desktop)
$application = $manifest.SelectSingleNode('/f:Package/f:Applications/f:Application', $manager)
if (-not $application) { throw 'MSIX Huda application was not found.' }
$package = $manifest.DocumentElement
$package.SetAttribute('xmlns:desktop', $desktop)
$package.SetAttribute('xmlns:uap10', $uap10)
$ignored = @($package.GetAttribute('IgnorableNamespaces') -split '\s+' | Where-Object { $_ })
$package.SetAttribute('IgnorableNamespaces', (($ignored + @('desktop', 'uap10') | Select-Object -Unique) -join ' '))
$extensions = $application.SelectSingleNode('f:Extensions', $manager)
if (-not $extensions) {
    $extensions = $manifest.CreateElement('Extensions', $foundation)
    $application.AppendChild($extensions) | Out-Null
}
$existing = $extensions.SelectSingleNode('desktop:Extension[desktop:StartupTask[@TaskId="HudaPrayerTaskbar"]]', $manager)
if ($existing) { $extensions.RemoveChild($existing) | Out-Null }
$extension = $manifest.CreateElement('desktop', 'Extension', $desktop)
$extension.SetAttribute('Category', 'windows.startupTask')
$extension.SetAttribute('Executable', 'prayer_taskbar\Huda.PrayerTaskbar.exe')
$extension.SetAttribute('EntryPoint', 'Windows.FullTrustApplication')
$parameters = $manifest.CreateAttribute('uap10', 'Parameters', $uap10)
$parameters.Value = '--startup'
$extension.Attributes.Append($parameters) | Out-Null
$task = $manifest.CreateElement('desktop', 'StartupTask', $desktop)
$task.SetAttribute('TaskId', 'HudaPrayerTaskbar')
$task.SetAttribute('Enabled', 'false')
$task.SetAttribute('DisplayName', 'Huda')
$extension.AppendChild($task) | Out-Null
$extensions.AppendChild($extension) | Out-Null
$settings = [Xml.XmlWriterSettings]::new()
$settings.Indent = $true
$settings.Encoding = [Text.UTF8Encoding]::new($false)
$writer = [Xml.XmlWriter]::Create([IO.Path]::GetFullPath($ManifestPath), $settings)
try { $manifest.Save($writer) } finally { $writer.Dispose() }
