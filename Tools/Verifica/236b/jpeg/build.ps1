# Builds jpegfast.exe: the real jpeg-6 of Doom 3 (decompression part) with bcc32c, and runs it on a pack.
#   powershell -NoProfile -File Tools\Verifica\236b\jpeg\build.ps1 -Out C:\ddparity_236b\jpeg [-Pack Tests\Data\Jpeg\doom3\cases.pack]
param(
  [string]$Out = 'C:\ddparity_236b\jpeg',
  [string]$Pack = '',
  [string]$Doom3 = 'C:\Progetti\DelphiDoom\Reference\doom3'
)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Resolve-Path (Join-Path $here '..\..\..\..')
$jpeg = Join-Path $Doom3 'neo\renderer\jpeg-6'
New-Item -ItemType Directory -Force $Out | Out-Null
$cc = 'C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\bcc32c.exe'
$files = 'jcomapi','jdapimin','jdapistd','jdcoefct','jdcolor','jddctmgr','jdhuff','jdinput','jdmainct','jdmarker',
  'jdmaster','jdmerge','jdphuff','jdpostct','jdsample','jerror','jidctflt','jidctfst','jidctint','jidctred',
  'jmemmgr','jmemnobs','jutils','jquant1','jquant2','jdtrans' | ForEach-Object { Join-Path $jpeg "$_.c" }
$objs = @()
foreach ($f in $files) {
  $o = Join-Path $Out ([IO.Path]::GetFileNameWithoutExtension($f) + '.o')
  & $cc -c -w- "-I$jpeg" "-o$o" $f
  if ($LASTEXITCODE -ne 0) { throw "compile $f" }
  $objs += $o
}
& $cc -w- "-I$jpeg" "-o$(Join-Path $Out jpegfast.exe)" (Join-Path $here jpegfast.c) @objs
if ($LASTEXITCODE -ne 0) { throw 'link' }
if ($Pack -ne '') {
  & (Join-Path $Out 'jpegfast.exe') (Resolve-Path $Pack)
}
