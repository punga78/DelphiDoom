$ref = Join-Path $PSScriptRoot '..\..\..\Reference\DD_VOXEL'
$out = Join-Path $PSScriptRoot 'build'
$enc = [Text.Encoding]::GetEncoding(28591)
$lines = [IO.File]::ReadAllLines("$ref\vxe_export.pas", $enc)
$head = @(
'unit oldexport;',
'// verbatim extract of vxe_export.pas of DD_VOXEL: the rotations and the Slab6 VOX export',
'interface',
'uses voxels;',
'procedure VXE_RotateVoxelBuffer(const voxelbuffer: voxelbuffer_p; const fvoxelsize: Integer; const theta: double; const tmpbuffer: voxelbuffer_p);',
'procedure VXE_RotateVoxelBufferHQ(const voxelbuffer: voxelbuffer_p; const fvoxelsize: Integer; const theta: double; const tmpbuffer: voxelbuffer_p);',
'procedure VXE_ExportVoxelToSlab6VOX(const voxelbuffer: voxelbuffer_p; const voxelsize: Integer; const fname: string);',
'implementation',
'uses Windows, SysUtils, Classes, vxe_multithreading, vxe_palette, vxe_quantize, vxe_utils;'
)
$body = $lines[192..404] + $lines[1530..1607]
$all = $head + $body + @('end.')
[IO.File]::WriteAllLines("$out\oldexport.pas", $all, $enc)
$lines[192]
$lines[404]
$lines[1530]
$lines[1607]
