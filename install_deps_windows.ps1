$SDL3_version="3.4.4"

$u="https://github.com/libsdl-org/SDL/releases/download/release-${SDL3_version}/SDL3-devel-${SDL3_version}-VC.zip"
$z="$PWD\SDL3.zip"
$d="$PWD\SDL3"


Invoke-WebRequest $u -OutFile $z
Expand-Archive $z -DestinationPath $d -Force


$inner=Get-ChildItem $d | Where-Object {$_.PSIsContainer} | Select-Object -First 1
Get-ChildItem $inner.FullName | Move-Item -Destination $d -Force
Remove-Item $inner.FullName -Recurse -Force
Remove-Item $z
