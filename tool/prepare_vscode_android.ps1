param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))

# Debug only. Keep App Check credentials out of launch.json and command lines.
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'android_app_arguments.ps1')
$project = [IO.Path]::GetFullPath($ProjectRoot)
$privateDirectory = Join-Path $env:LOCALAPPDATA 'HealthMate'
$destination = [IO.Path]::GetFullPath((Join-Path $privateDirectory 'vscode-android-debug.json'))
if ($destination.StartsWith($project + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
  throw 'The VS Code debug configuration must stay outside the repository.'
}

$arguments = @(Get-HealthMateAndroidArguments -ProjectRoot $project)
$configuration = [ordered]@{}
$filePrefix = '--dart-define-from-file='
$tokenPrefix = '--dart-define=HEALTHMATE_APP_CHECK_DEBUG_TOKEN='
foreach ($argument in $arguments) {
  if ($argument.StartsWith($filePrefix, [StringComparison]::Ordinal)) {
    $source = Get-Content -LiteralPath $argument.Substring($filePrefix.Length) -Raw | ConvertFrom-Json
    foreach ($property in $source.PSObject.Properties) {
      if ($configuration.Contains($property.Name)) {
        throw 'Duplicate Android debug configuration field.'
      }
      $configuration[$property.Name] = $property.Value
    }
  } elseif ($argument.StartsWith($tokenPrefix, [StringComparison]::Ordinal)) {
    $configuration['HEALTHMATE_APP_CHECK_DEBUG_TOKEN'] = $argument.Substring($tokenPrefix.Length)
  } else {
    throw 'Unsupported Android debug argument.'
  }
}

[IO.Directory]::CreateDirectory($privateDirectory) | Out-Null
[IO.File]::WriteAllText($destination, ($configuration | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
Write-Output 'HealthMate Android debug configuration prepared.'
