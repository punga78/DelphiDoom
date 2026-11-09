# TEMPORARY HARNESS (issue #177): makes hook-gl.patch, the patch that hooks HarnessGl and the recorder
# into the four OpenGL games. It edits the files of this tree, writes the diff with `git diff` and puts the
# files back (git checkout). Run it from a clean tree; the patch is committed, the edits are not.
#
#   .\Tools\Verifica\opengl\Genera-Patch.ps1
#
# The patch touches only:
#   Doom\GLDoom32.dpr, Heretic\GLHeretic32.dpr, Hexen\GLHexen32.dpr, Strife\GLStrife32.dpr  (the harness units)
#   Libs\OpenGl\Legacy\gl_main.pas     one call after ReadImplementationProperties (installs the thunks)
#   Libs\OpenGl\Legacy\gl_render.pas   one call at the end of gld_Finish (end of a frame)
#   Base\DelphiDoom.Engine.Level.Loader.pas   one call at the end of SetupLevel (the level is loaded)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
Set-Location $root
$crlf = "`r`n"
$utf8 = New-Object System.Text.UTF8Encoding($false)

$dirty = git status --porcelain --untracked-files=no
if ($dirty) { throw "L'albero non e' pulito: $dirty" }

function Edit-File([string]$relative, [scriptblock]$edit) {
  $path = Join-Path $root $relative
  $bytes = [System.IO.File]::ReadAllBytes($path)
  $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
  $text = [System.IO.File]::ReadAllText($path)
  $text = & $edit $text
  $enc = New-Object System.Text.UTF8Encoding($hasBom)
  [System.IO.File]::WriteAllText($path, $text, $enc)
}

function Replace-Once([string]$text, [string]$old, [string]$new) {
  $index = $text.IndexOf($old)
  if ($index -lt 0) { throw "Testo non trovato: $old" }
  if ($text.IndexOf($old, $index + 1) -ge 0) { throw "Testo non unico: $old" }
  return $text.Substring(0, $index) + $new + $text.Substring($index + $old.Length)
}

$units = @(
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Types',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Intf',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Fnv',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.PixelFormats',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.ClientArrays',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Encoder',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.CallRecorder',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.HookTable',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Installer',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Session',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Thunks',
  'Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Hook'
)
$unitLines = ''
foreach ($u in $units) {
  $name = Split-Path $u -Leaf
  $unitLines += "  $name in '..\$u.pas',$crlf"
}
$unitLines += "  HarnessGl in '..\Tools\Verifica\opengl\HarnessGl.pas',$crlf"

foreach ($dpr in @('Doom\GLDoom32.dpr', 'Heretic\GLHeretic32.dpr', 'Hexen\GLHexen32.dpr', 'Strife\GLStrife32.dpr')) {
  Edit-File $dpr {
    param($t)
    Replace-Once $t "  gl_main in '..\Libs\OpenGl\Legacy\gl_main.pas'," ($unitLines + "  gl_main in '..\Libs\OpenGl\Legacy\gl_main.pas',")
  }
}

Edit-File 'Libs\OpenGl\Legacy\gl_main.pas' {
  param($t)
  $t = Replace-Once $t "implementation$crlf${crlf}uses$crlf" "implementation$crlf${crlf}uses$crlf  HarnessGl,$crlf"
  Replace-Once $t "  ReadImplementationProperties;$crlf" "  ReadImplementationProperties;$crlf  HarnessGl_AfterExtensions;$crlf"
}

Edit-File 'Libs\OpenGl\Legacy\gl_render.pas' {
  param($t)
  $t = Replace-Once $t "implementation$crlf${crlf}uses$crlf" "implementation$crlf${crlf}uses$crlf  HarnessGl,$crlf"
  Replace-Once $t "  SwapBuffers(h_DC);$crlf" "  SwapBuffers(h_DC);$crlf  HarnessGl_FrameEnd;$crlf"
}

Edit-File 'Base\DelphiDoom.Engine.Level.Loader.pas' {
  param($t)
  $t = Replace-Once $t "implementation$crlf${crlf}uses$crlf" "implementation$crlf${crlf}uses$crlf  HarnessGl,$crlf"
  Replace-Once $t "  FinishLevel;$crlf" "  FinishLevel;$crlf  HarnessGl_AfterLevel(LMapName);$crlf"
}

$patch = Join-Path $PSScriptRoot 'hook-gl.patch'
git diff --output=$patch
git checkout -- Doom Heretic Hexen Strife Libs\OpenGl\Legacy Base
Write-Host "Scritto $patch"
