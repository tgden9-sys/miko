param([string]$Blender = 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe')
$taskRoot = $PSScriptRoot
$taskBaseline = Join-Path $taskRoot 'source_assets_v28\master_before_swap.blend'
if (-not (Test-Path -LiteralPath $taskBaseline)) { throw 'Missing preserved source master.' }
& $Blender -b $taskBaseline --python (Join-Path $taskRoot 'build_neckerchief_robot_v27.py') --python (Join-Path $taskRoot 'bake_neckerchief_animation_library_v27.py') --python (Join-Path $taskRoot 'align_neckerchief_head_v28.py')
if ($LASTEXITCODE -ne 0) { throw "Blender build failed: $LASTEXITCODE" }
