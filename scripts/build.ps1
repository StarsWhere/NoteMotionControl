[CmdletBinding()]
param(
    [string]$GameRoot = $env:BEAT_SABER_DIR,
    [string]$BuildDirectory,
    [string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'build_local_paths.ps1')

if ((Get-Content -LiteralPath (Join-Path $GameRoot 'BeatSaberVersion.txt') -Raw).Trim() -ne '1.45.2_28848') {
    throw 'Unsupported Beat Saber build.'
}
if (!$BuildDirectory) { $BuildDirectory = Join-Path $RepoRoot '.tmp/build' }
if (!$OutputDirectory) { $OutputDirectory = Join-Path $RepoRoot '.tmp/package' }
$BuildDirectory = Resolve-RepoBuildPath $BuildDirectory
$OutputDirectory = Resolve-RepoBuildPath $OutputDirectory

$sharedRoot = Join-Path $RepoRoot 'vendor/LocalModUI'
$sharedBuild = Join-Path $sharedRoot 'scripts/build.ps1'
if (!(Test-Path -LiteralPath $sharedBuild -PathType Leaf)) {
    throw 'LocalModUI submodule is missing. Run git submodule update --init --recursive.'
}
& $sharedBuild -GameRoot $GameRoot -BuildDirectory (Join-Path $sharedRoot '.tmp/build') -OutputDirectory (Join-Path $sharedRoot '.tmp/package') | Out-Null

$project = Join-Path $PSScriptRoot 'training_mods/NoteMotionControl/NoteMotionControl.csproj'
$build = Join-Path $BuildDirectory 'NoteMotionControl'
& 'C:/Program Files/dotnet/dotnet.exe' build $project -c Release --nologo -v quiet ('-p:GameRoot='+$GameRoot) ('-p:RepoRoot='+$RepoRoot) ('-p:OutputPath='+$build+'/bin/') ('-p:BaseIntermediateOutputPath='+$build+'/obj/') '-p:AppendTargetFrameworkToOutputPath=false'
if ($LASTEXITCODE -ne 0) { throw 'NoteMotionControl compilation failed.' }
$plugins = Join-Path $OutputDirectory 'Plugins'
[IO.Directory]::CreateDirectory($plugins) | Out-Null
Copy-Item -LiteralPath (Join-Path $build 'bin/NoteMotionControl.dll') -Destination $plugins -Force
Write-Output $OutputDirectory
