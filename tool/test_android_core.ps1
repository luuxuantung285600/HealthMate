param(
  [Parameter(Mandatory=$true)]
  [ValidatePattern('^emulator-[0-9]+$')]
  [string]$DeviceId,
  [string]$FlutterSdk = 'D:\Flutter\flutter',
  [string]$AndroidSdk = "$env:LOCALAPPDATA\Android\sdk",
  [string]$JavaHome = 'C:\Program Files\Android\Android Studio\jbr',
  [switch]$CrossDriveBuild,
  [ValidateSet('core','wellness','nutrition','daily')]
  [string]$Suite = 'core'
)

$ErrorActionPreference = 'Stop'
$flutter = Join-Path $FlutterSdk 'bin\flutter.bat'
$adb = Join-Path $AndroidSdk 'platform-tools\adb.exe'
$firebase = (Get-Command firebase.cmd -ErrorAction Stop).Source
foreach ($required in @($flutter, $adb, (Join-Path $JavaHome 'bin\java.exe'))) {
  if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
    throw "Missing QA tool: $required"
  }
}
$avd = @(& $adb -s $DeviceId emu avd name)
if ($LASTEXITCODE -ne 0 -or $avd[0].Trim() -ne 'HealthMateMaintenanceQA') {
  throw 'Only the dedicated HealthMateMaintenanceQA AVD is allowed. No phone, uninstall, clear-data or production fallback.'
}
if ((& $adb -s $DeviceId shell getprop sys.boot_completed).Trim() -ne '1') {
  throw 'QA emulator is not booted yet.'
}

# Preserve PNG bytes on both Windows PowerShell and PowerShell 7.
function Export-QAImage([string]$Name, [bool]$Cache = $true) {
  $start = [System.Diagnostics.ProcessStartInfo]::new()
  $start.FileName = $adb
  $start.Arguments = if ($Cache) {
    "-s $DeviceId exec-out run-as com.example.healthmate cat cache/$Name.png"
  } else { "-s $DeviceId exec-out screencap -p" }
  $start.UseShellExecute = $false
  $start.CreateNoWindow = $true
  $start.RedirectStandardOutput = $true
  $start.RedirectStandardError = $true
  $process = [System.Diagnostics.Process]::Start($start)
  $buffer = [System.IO.MemoryStream]::new()
  try {
    $process.StandardOutput.BaseStream.CopyTo($buffer)
    $null = $process.StandardError.ReadToEnd()
    $process.WaitForExit()
    if ($process.ExitCode -eq 0 -and $buffer.Length -gt 0) {
      [System.IO.File]::WriteAllBytes((Join-Path $output "$Name.png"), $buffer.ToArray())
    }
  } finally { $buffer.Dispose(); $process.Dispose() }
}

$savedPath = $env:Path
$savedJava = $env:JAVA_HOME
$incrementalKey = 'ORG_GRADLE_PROJECT_kotlin.incremental'
$savedIncremental = [Environment]::GetEnvironmentVariable($incrementalKey, 'Process')
$qaProperties = $null
Push-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
try {
  $output = Join-Path (Get-Location).Path 'build\c6-android'
  New-Item -ItemType Directory -Path $output -Force | Out-Null
  $env:JAVA_HOME = $JavaHome
  $env:Path = "$JavaHome\bin;$env:Path"
  if ($CrossDriveBuild) {
    # Kotlin's relative incremental cache fails when pub cache and build roots
    # are on different Windows volumes. Scope this override to this QA run.
    [Environment]::SetEnvironmentVariable($incrementalKey, 'false', 'Process')
    $propertiesPath = Join-Path (Get-Location).Path 'android\gradle.properties'
    $qaProperties = [System.IO.File]::ReadAllBytes($propertiesPath)
    [System.IO.File]::AppendAllText($propertiesPath, "`nkotlin.incremental=false`n", [System.Text.UTF8Encoding]::new($false))
  }
  $target = switch ($Suite) {
    'daily' { 'integration_test/daily_reliability_acceptance_test.dart' }
    'wellness' { 'integration_test/wellness_acceptance_test.dart' }
    'nutrition' { 'integration_test/nutrition_acceptance_test.dart' }
    default { 'integration_test/core_acceptance_test.dart' }
  }
  # The API30 SwiftShader AVD exceeds an Impeller GLES uniform limit. Use Skia
  # only for this guarded QA device; production build settings stay unchanged.
  $command = '"' + $flutter + '" drive --no-pub -d ' + $DeviceId + ' --no-enable-impeller --keep-app-running --driver=test_driver/core_acceptance_driver.dart --target=' + $target + ' --dart-define=HEALTHMATE_CORE_EMULATOR_TESTS=true --dart-define=HEALTHMATE_ENABLE_CHATBOT=false --dart-define=HEALTHMATE_ENABLE_FOOD_SCANNER=false'
  # Explicit demo project/config: never use .firebaserc's production selection.
  & $firebase emulators:exec --config firebase.emulators.json --only auth,firestore --project demo-healthmate-rules $command
  $result = $LASTEXITCODE
  Export-QAImage 'c6-last-screen' $false
} finally {
  if ($null -ne $qaProperties) { [System.IO.File]::WriteAllBytes($propertiesPath, $qaProperties) }
  $env:Path = $savedPath
  $env:JAVA_HOME = $savedJava
  [Environment]::SetEnvironmentVariable($incrementalKey, $savedIncremental, 'Process')
  Pop-Location
}
exit $result
