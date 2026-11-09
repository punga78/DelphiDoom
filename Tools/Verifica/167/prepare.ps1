New-Item -ItemType Directory -Force (Join-Path $PSScriptRoot 'build') | Out-Null
$ref = Join-Path $PSScriptRoot '..\..\..\Reference\DD_VOXEL'
$out = Join-Path $PSScriptRoot 'build'
$enc = [Text.Encoding]::GetEncoding(28591)

# vxe_quantize: node_free must reset nodeslen (otherwise the second use crashes)
$q = [IO.File]::ReadAllText("$ref\vxe_quantize.pas", $enc)
$q2 = [regex]::Replace($q, '(pool := p;\s*end;)', '$1' + "`r`n  nodeslen := 0;", 1)
if ($q2 -eq $q) { throw 'quantize patch failed' }
[IO.File]::WriteAllText("$out\vxe_quantize.pas", $q2, $enc)

# vxe_mesh: counter of the defective compaction and a switch for the corrected one
$m = [IO.File]::ReadAllText("$ref\vxe_mesh.pas", $enc)
$m2 = $m.Replace("implementation`r`n", "var`r`n  VoxelMeshFixCompaction: Boolean = False;`r`n  VoxelMeshLegacyHits: Integer = 0;`r`n`r`nimplementation`r`n")
if ($m2 -eq $m) { throw 'mesh patch 1 failed' }
$old = "  if fnewrealnumquads = frealnumquads then`r`n  begin`r`n    j := 0;"
$new = "  if fnewrealnumquads = frealnumquads then`r`n  begin`r`n    if VoxelMeshFixCompaction then`r`n    begin`r`n      j := 0;`r`n      for i := 0 to fnumquads - 1 do`r`n      begin`r`n        q1 := @fquads[i];`r`n        if q1.valid then`r`n        begin`r`n          if i <> j then`r`n            fquads[j] := q1^;`r`n          SortQuadVertexes(@fquads[j]);`r`n          Inc(j);`r`n        end;`r`n      end;`r`n      fnumquads := fnewnumquads;`r`n      Exit;`r`n    end;`r`n    Inc(VoxelMeshLegacyHits);`r`n    j := 0;"
$m3 = $m2.Replace($old, $new)
if ($m3 -eq $m2) { throw 'mesh patch 2 failed' }
[IO.File]::WriteAllText("$out\vxe_mesh.pas", $m3, $enc)
# vxe_script: Delphi 7 code (a string of bytes) that copied Length(tx) bytes of a UTF-16 string: the buffer is Length(tx) characters
$s = [IO.File]::ReadAllText("$ref\vxe_script.pas", $enc)
$s2 = $s.Replace("GetMem(p, size);`r`n  Move(tx[1], p^, size);", "GetMem(p, size * SizeOf(Char));`r`n  Move(tx[1], p^, size * SizeOf(Char));")
if ($s2 -eq $s) { throw 'script patch failed' }
[IO.File]::WriteAllText("$out\vxe_script.pas", $s2, $enc)
'prepared'
