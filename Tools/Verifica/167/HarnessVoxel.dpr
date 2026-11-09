program HarnessVoxel;

// Runs the OLD code of DD_VOXEL (units of Reference\DD_VOXEL, with the two small patches of prepare.ps1) on the scenarios of
// DelphiDoom.Tests.VoxelEditor.Scenarios and writes the golden file Tests\Data\VoxelEditor\voxel.golden.txt.

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, Windows, Graphics, Math,
  voxels in '..\..\..\Reference\DD_VOXEL\voxels.pas',
  vxe_utils in '..\..\..\Reference\DD_VOXEL\vxe_utils.pas',
  vxe_threads in '..\..\..\Reference\DD_VOXEL\vxe_threads.pas',
  vxe_multithreading in '..\..\..\Reference\DD_VOXEL\vxe_multithreading.pas',
  vxe_palette in '..\..\..\Reference\DD_VOXEL\vxe_palette.pas',
  vxe_quantize,
  vxe_mesh,
  vxe_rotate in '..\..\..\Reference\DD_VOXEL\vxe_rotate.pas',
  vxe_script,
  vxe_kvx in '..\..\..\Reference\DD_VOXEL\vxe_kvx.pas',
  oldexport,
  progressfrm,
  DelphiDoom.Tests.VoxelEditor.Scenarios in '..\..\..\Tests\Source\DelphiDoom.Tests.VoxelEditor.Scenarios.pas';

var
  Golden: TStringList;
  Buf, Tmp: voxelbuffer_p;
  TempFile: string;

procedure Emit(const S: string);
begin
  Golden.Add(S);
end;

procedure LoadModel(AIndex: Integer; const ABuf: voxelbuffer_p);
var
  Cells: TArray<Cardinal>;
  Size, X, Y, Z: Integer;
begin
  FillChar(ABuf^, SizeOf(voxelbuffer_t), 0);
  Size := TVoxelScenarios.ModelSize(AIndex);
  Cells := TVoxelScenarios.ModelCells(AIndex);
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
      for Z := 0 to Size - 1 do
        ABuf[X, Y, Z] := Cells[(X * Size + Y) * Size + Z];
end;

function BufCells(const ABuf: voxelbuffer_p; ASize: Integer): TArray<Cardinal>;
var
  X, Y, Z: Integer;
begin
  SetLength(Result, ASize * ASize * ASize);
  for X := 0 to ASize - 1 do
    for Y := 0 to ASize - 1 do
      for Z := 0 to ASize - 1 do
        Result[(X * ASize + Y) * ASize + Z] := ABuf[X, Y, Z];
end;

function BufHash(const ABuf: voxelbuffer_p; ASize: Integer): string;
begin
  Result := TVoxelScenarios.Digest(BufCells(ABuf, ASize));
end;

function Img2Hash(const P: voxelbuffer2d_p; ASize: Integer): string;
var
  A: TArray<Cardinal>;
  I, J: Integer;
begin
  SetLength(A, ASize * ASize);
  for I := 0 to ASize - 1 do
    for J := 0 to ASize - 1 do
      A[I * ASize + J] := P[I, J];
  Result := TVoxelScenarios.Digest(A);
end;

function ViewName(V: voxelview_t): string;
begin
  Result := IntToStr(Ord(V));
end;

function PtrIndex(P: voxelitem_p; ABuf: voxelbuffer_p; ASize: Integer): Integer;
var
  Off: Integer;
  X, Y, Z: Integer;
begin
  if P = nil then
  begin
    Result := -1;
    Exit;
  end;
  // the old buffer has a stride of 256: the index of the library is of a cube of the size of the voxel
  Off := (PByte(P) - PByte(ABuf)) div 4;
  Z := Off mod 256;
  Y := (Off div 256) mod 256;
  X := Off div 65536;
  Result := (X * ASize + Y) * ASize + Z;
end;

function FileBytes(const AFileName: string): TBytes;
var
  S: TFileStream;
begin
  S := TFileStream.Create(AFileName, fmOpenRead);
  try
    SetLength(Result, S.Size);
    if S.Size > 0 then
      S.ReadBuffer(Result[0], S.Size);
  finally
    S.Free;
  end;
end;

procedure PutBytes(const AFileName: string; const ABytes: TBytes);
var
  S: TFileStream;
begin
  S := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(ABytes) > 0 then
      S.WriteBuffer(ABytes[0], Length(ABytes));
  finally
    S.Free;
  end;
end;

// ---- planes (verbatim loops of main.pas) --------------------------------------------------------------------------

procedure GetPlane(const ABuf: voxelbuffer_p; ASize: Integer; AKind: Integer; ALevel: Integer; const P: voxelbuffer2d_p);
var
  i, j: Integer;
begin
  case AKind of
    0: for i := 0 to ASize - 1 do for j := 0 to ASize - 1 do P[i, j] := ABuf[ALevel, i, j];
    1: for i := 0 to ASize - 1 do for j := 0 to ASize - 1 do P[i, j] := ABuf[i, ALevel, j];
    2: for i := 0 to ASize - 1 do for j := 0 to ASize - 1 do P[i, j] := ABuf[i, j, ALevel];
  else
    vox_getviewbuffer(ABuf, ASize, P, voxelview_t(AKind - 2));
  end;
end;

procedure SetPlane(const ABuf: voxelbuffer_p; ASize: Integer; AKind: Integer; ALevel: Integer; const P: voxelbuffer2d_p);
var
  i, j: Integer;
begin
  case AKind of
    0: for i := 0 to ASize - 1 do for j := 0 to ASize - 1 do ABuf[ALevel, i, j] := P[i, j];
    1: for i := 0 to ASize - 1 do for j := 0 to ASize - 1 do ABuf[i, ALevel, j] := P[i, j];
    2: for i := 0 to ASize - 1 do for j := 0 to ASize - 1 do ABuf[i, j, ALevel] := P[i, j];
  else
    vox_setviewbuffer(ABuf, ASize, P, voxelview_t(AKind - 2));
  end;
end;

function PlaneName(AKind: Integer): string;
begin
  case AKind of
    0: Result := 'x';
    1: Result := 'y';
    2: Result := 'z';
  else
    Result := 'view' + IntToStr(AKind - 2);
  end;
end;

procedure FlipHorz(const P: voxelbuffer2d_p; ASize: Integer);
var
  i, j: integer;
  c: voxelitem_t;
begin
  for i := 0 to (ASize div 2) - 1 do
    for j := 0 to ASize - 1 do
    begin
      c := P[ASize - i - 1, j];
      P[ASize - i - 1, j] := P[i, j];
      P[i, j] := c;
    end;
end;

procedure FlipVert(const P: voxelbuffer2d_p; ASize: Integer);
var
  i, j: integer;
  c: voxelitem_t;
begin
  for i := 0 to ASize - 1 do
    for j := 0 to (ASize div 2) - 1 do
    begin
      c := P[i, ASize - j - 1];
      P[i, ASize - j - 1] := P[i, j];
      P[i, j] := c;
    end;
end;

procedure RotatePlane(const P: voxelbuffer2d_p; ASize: Integer; ACounterClockwise: Boolean);
var
  b: TBitmap;
  i, j: Integer;
begin
  b := TBitmap.Create;
  b.PixelFormat := pf32bit;
  b.Width := ASize;
  b.Height := ASize;
  for i := 0 to ASize - 1 do
    for j := 0 to ASize - 1 do
      b.Canvas.Pixels[i, j] := P[i, j];
  if ACounterClockwise then
    RotateBitmap90DegreesCounterClockwise(b)
  else
    RotateBitmap90DegreesClockwise(b);
  for i := 0 to ASize - 1 do
    for j := 0 to ASize - 1 do
      P[i, j] := b.Canvas.Pixels[i, j];
  b.Free;
end;

// ---- loaders (verbatim from main.pas / kvx2mesh.pas, DoNewVoxel replaced by the size) -------------------------------------

function OldLoadKVX(const fname: string; const ABuf: voxelbuffer_p; var fvoxelsize: integer): boolean;
var
  strm: TFileStream;
  pal: array[0..255] of LongWord;
  i: integer;
  r, g, b: byte;
  numbytes: integer;
  xsiz, ysiz, zsiz, xpivot, ypivot, zpivot: integer;
  xoffset: PIntegerArray;
  xyoffset: PSmallIntPArray;
  offs: integer;
  voxdatasize: integer;
  voxdata: PByteArray;
  size: integer;
  xx, yy, zz: integer;
  x1, y1, z1: integer;
  endptr: PByte;
  slab: kvxslab_p;
  kvxbuffer: kvxbuffer_p;
  maxpal: integer;
  cc: integer;
  palfactor: double;
begin
  FillChar(ABuf^, SizeOf(voxelbuffer_t), 0);
  strm := TFileStream.Create(fname, fmOpenRead or fmShareDenyWrite);

  strm.Seek(strm.size - 768, soFromBeginning);
  maxpal := 0;
  for i := 0 to 255 do
  begin
    strm.Read(b, SizeOf(Byte));
    if b > maxpal then
      maxpal := b;
    strm.Read(g, SizeOf(Byte));
    if g > maxpal then
      maxpal := g;
    strm.Read(r, SizeOf(Byte));
    if r > maxpal then
      maxpal := r;
    pal[i] := r shl 16 + g shl 8 + b;
    if pal[i] = 0 then
      pal[i] := $01;
  end;
  if (maxpal < 255) and (maxpal > 0) then
  begin
    palfactor := 255 / maxpal;
    if palfactor > 4.0 then
      palfactor := 4.0;
    for i := 0 to 255 do
    begin
      r := pal[i] shr 16;
      g := pal[i] shr 8;
      b := pal[i];
      cc := round(palfactor * r);
      if cc < 0 then
        cc := 0
      else if cc > 255 then
        cc := 255;
      r := cc;
      cc := round(palfactor * g);
      if cc < 0 then
        cc := 0
      else if cc > 255 then
        cc := 255;
      g := cc;
      cc := round(palfactor * b);
      if cc < 0 then
        cc := 0
      else if cc > 255 then
        cc := 255;
      b := cc;
      pal[i] := r shl 16 + g shl 8 + b;
    end;
  end;

  strm.Seek(0, soFromBeginning);
  strm.Read(numbytes, SizeOf(Integer));
  strm.Read(xsiz, SizeOf(Integer));
  strm.Read(ysiz, SizeOf(Integer));
  strm.Read(zsiz, SizeOf(Integer));

  size := 1;

  while xsiz > size do
    size := size * 2;
  while ysiz > size do
    size := size * 2;
  while zsiz > size do
    size := size * 2;

  if size < 256 then
    size := size * 2;

  fvoxelsize := size;

  strm.Read(xpivot, SizeOf(Integer));
  strm.Read(ypivot, SizeOf(Integer));
  strm.Read(zpivot, SizeOf(Integer));

  GetMem(xoffset, (xsiz + 1) * SizeOf(Integer));
  GetMem(xyoffset, xsiz * SizeOf(PSmallIntArray));
  for i := 0 to xsiz - 1 do
    GetMem(xyoffset[i], (ysiz + 1) * SizeOf(SmallInt));

  strm.Read(xoffset^, (xsiz + 1) * SizeOf(Integer));

  for i := 0 to xsiz - 1 do
    strm.Read(xyoffset[i]^, (ysiz + 1) * SizeOf(SmallInt));

  offs := xoffset[0];

  voxdatasize := numbytes - 24 - (xsiz + 1) * 4 - xsiz * (ysiz + 1) * 2;
  GetMem(voxdata, voxdatasize);
  strm.Read(voxdata^, voxdatasize);
  strm.Free;

  GetMem(kvxbuffer, SizeOf(kvxbuffer_t));
  for xx := 0 to xsiz - 1 do
    for yy := 0 to ysiz - 1 do
       for zz := 0 to zsiz - 1 do
         kvxbuffer[xx, yy, zz] := $FFFF;

  for xx := 0 to xsiz - 1 do
  begin
    for yy := 0 to ysiz - 1 do
    begin
      endptr := @voxdata[xoffset[xx] + xyoffset[xx][yy + 1] - offs];
      slab := @voxdata[xoffset[xx] + xyoffset[xx][yy] - offs];
      while Integer(slab) < integer(endptr) do
      begin
        for zz := slab.ztop to slab.zleng + slab.ztop - 1 do
          kvxbuffer[xx, yy, zz] := slab.col[zz - slab.ztop];
        slab := kvxslab_p(integer(slab) + slab.zleng + 3);
      end;
    end;
  end;

  x1 := size div 2 - xpivot div 256;
  y1 := size div 2 - ypivot div 256;
  z1 := size{ div 2} - zpivot div 256;
  if x1 < 0 then
    x1 := 0;
  if y1 < 0 then
    y1 := 0;
  if z1 < 0 then
    z1 := 0;
  while x1 + xsiz > size do
    dec(x1);
  while y1 + ysiz > size do
    dec(y1);
  while z1 + zsiz > size do
    dec(z1);
  for xx := x1 to x1 + xsiz - 1 do
    for yy := y1 to y1 + ysiz - 1 do
      for zz := z1 to z1 + zsiz - 1 do
        if kvxbuffer[xx - x1, yy - y1, zz - z1] <> $FFFF then
          ABuf[xx, zz, size - yy - 1] := pal[kvxbuffer[xx - x1, yy - y1, zz - z1]];

  FreeMem(xoffset, (xsiz + 1) * SizeOf(Integer));
  for i := 0 to xsiz - 1 do
    FreeMem(xyoffset[i], (ysiz + 1) * SizeOf(SmallInt));
  FreeMem(xyoffset, xsiz * SizeOf(PSmallIntArray));
  FreeMem(voxdata, voxdatasize);
  FreeMem(kvxbuffer, SizeOf(kvxbuffer_t));
  Result := True;
end;

function OldLoadVOX(const fname: string; const ABuf: voxelbuffer_p; var fvoxelsize: integer): boolean;
var
  strm: TFileStream;
  pal: array[0..255] of LongWord;
  i: integer;
  r, g, b: byte;
  xsiz, ysiz, zsiz: integer;
  voxdatasize: integer;
  voxdata: PByteArray;
  size: integer;
  xx, yy, zz: integer;
  x1, y1, z1: integer;
  maxpal: integer;
  cc: integer;
  palfactor: double;
begin
  FillChar(ABuf^, SizeOf(voxelbuffer_t), 0);
  strm := TFileStream.Create(fname, fmOpenRead or fmShareDenyWrite);

  strm.Seek(strm.size - 768, soFromBeginning);
  maxpal := 0;
  for i := 0 to 255 do
  begin
    strm.Read(b, SizeOf(Byte));
    if b > maxpal then
      maxpal := b;
    strm.Read(g, SizeOf(Byte));
    if g > maxpal then
      maxpal := g;
    strm.Read(r, SizeOf(Byte));
    if r > maxpal then
      maxpal := r;
    pal[i] := r shl 16 + g shl 8 + b;
    if pal[i] = 0 then
      pal[i] := $01;
  end;
  if (maxpal < 255) and (maxpal > 0) then
  begin
    palfactor := 255 / maxpal;
    if palfactor > 4.0 then
      palfactor := 4.0;
    for i := 0 to 255 do
    begin
      r := pal[i] shr 16;
      g := pal[i] shr 8;
      b := pal[i];
      cc := round(palfactor * r);
      if cc < 0 then
        cc := 0
      else if cc > 255 then
        cc := 255;
      r := cc;
      cc := round(palfactor * g);
      if cc < 0 then
        cc := 0
      else if cc > 255 then
        cc := 255;
      g := cc;
      cc := round(palfactor * b);
      if cc < 0 then
        cc := 0
      else if cc > 255 then
        cc := 255;
      b := cc;
      pal[i] := r shl 16 + g shl 8 + b;
    end;
  end;

  strm.Seek(0, soFromBeginning);
  strm.Read(xsiz, SizeOf(Integer));
  strm.Read(ysiz, SizeOf(Integer));
  strm.Read(zsiz, SizeOf(Integer));

  size := xsiz;
  if size < ysiz then
    size := ysiz;
  if size < zsiz then
    size := zsiz;
  fvoxelsize := size;

  voxdatasize := xsiz * ysiz * zsiz;
  GetMem(voxdata, voxdatasize);
  strm.Read(voxdata^, voxdatasize);
  strm.Free;

  x1 := (size - xsiz) div 2;
  y1 := (size - ysiz) div 2;
  z1 := (size - zsiz) div 2;
  i := 0;
  for xx := x1 to x1 + xsiz - 1 do
    for yy := y1 to y1 + ysiz - 1 do
      for zz := z1 to z1 + zsiz - 1 do
      begin
        if voxdata[i] <> 255 then
          ABuf[xx, zz, size - yy - 1] := pal[voxdata[i]];
        inc(i);
      end;
  FreeMem(voxdata, voxdatasize);
  Result := True;
end;

procedure OldSaveDdvox(const fname: string; const ABuf: voxelbuffer_p; fvoxelsize: integer);
var
  t: TextFile;
  xx, yy, zz: integer;
  skip: integer;
  fvoxelbuffer: voxelbuffer_p;
begin
  fvoxelbuffer := ABuf;
  AssignFile(t, fname);
  Rewrite(t);
  Writeln(t, fvoxelsize);
  for xx := 0 to fvoxelsize - 1 do
    for yy := 0 to fvoxelsize - 1 do
    begin
      skip := 0;
      for zz := 0 to fvoxelsize - 1 do
      begin
        if fvoxelbuffer[xx, yy, zz] = 0 then
        begin
          Inc(skip);
          if zz = fvoxelsize - 1 then
            Writeln(t, 'skip ', skip);
        end
        else
        begin
          if skip > 0 then
          begin
            Write(t, 'skip ', skip, ', ');
            skip := 0;
          end;
          if zz = fvoxelsize - 1 then
            Writeln(t, fvoxelbuffer[xx, yy, zz])
          else
            Write(t, fvoxelbuffer[xx, yy, zz], ', ');
        end;
      end;
    end;
  CloseFile(t);
end;

function OldLoadDdvox(const fname: string; const ABuf: voxelbuffer_p; var fvoxelsize: integer): boolean;
var
  buf: TStringList;
  sc: TScriptEngine;
  xx, yy, zz: integer;
begin
  FillChar(ABuf^, SizeOf(voxelbuffer_t), 0);
  buf := TStringList.Create;
  try
    buf.LoadFromFile(fname);
    sc := TScriptEngine.Create(buf.Text);
    sc.MustGetInteger;
    fvoxelsize := sc._Integer;
    xx := 0;
    yy := 0;
    zz := 0;
    while sc.GetString do
    begin
      if sc.MatchString('skip') then
      begin
        sc.MustGetInteger;
        inc(zz, sc._Integer);
      end
      else
      begin
        sc.UnGet;
        sc.MustGetInteger;
        ABuf[xx, yy, zz] := sc._Integer;
        Inc(zz);
      end;
      if zz = fvoxelsize then
      begin
        zz := 0;
        Inc(yy);
        if yy = fvoxelsize then
        begin
          yy := 0;
          Inc(xx);
          if xx = fvoxelsize then
            Break;
        end;
      end;
    end;
    sc.Free;
  finally
    buf.Free;
  end;
  Result := True;
end;

function OldLoadDdmesh(const fname: string; const ABuf: voxelbuffer_p; var size: integer): boolean;
var
  strm: TFileStream;
  i: integer;
  xb, yb, zb: byte;
  HDR: LongWord;
  version: integer;
  quads: integer;
  fnumvoxels: Integer;
  c: LongWord;
begin
  FillChar(ABuf^, SizeOf(voxelbuffer_t), 0);
  strm := TFileStream.Create(fname, fmOpenRead or fmShareDenyWrite);
  strm.Read(HDR, SizeOf(LongWord));
  strm.Read(version, SizeOf(integer));
  strm.Read(size, SizeOf(integer));
  strm.Read(quads, SizeOf(integer));
  strm.Position := 16 + quads * (4 * SizeOf(voxelvertex_t) + SizeOf(LongWord));
  strm.Read(fnumvoxels, SizeOf(integer));
  for i := 0 to fnumvoxels - 1 do
  begin
    strm.Read(xb, SizeOf(byte));
    strm.Read(yb, SizeOf(byte));
    strm.Read(zb, SizeOf(byte));
    strm.Read(c, SizeOf(LongWord));
    ABuf[xb, yb, zb] := c;
  end;
  strm.Free;
  Result := True;
end;

// ---- the scenarios ---------------------------------------------------------------------------------------------------

procedure RunViews(AModel: Integer);
var
  Size, V, X, Y, Z, Step, Count: Integer;
  P: voxelbuffer2d_p;
  Depth: depthvoxelbuffer2d_p;
  Probe: TArray<Cardinal>;
  Idx: TArray<Integer>;
  Items: TArray<Cardinal>;
  Name: string;
  W: voxelbuffer_p;
  I, J: Integer;
begin
  Size := TVoxelScenarios.ModelSize(AModel);
  Name := TVoxelScenarios.ModelName(AModel);
  LoadModel(AModel, Buf);
  GetMem(P, SizeOf(voxelbuffer2d_t));
  GetMem(Depth, SizeOf(depthvoxelbuffer2d_t));
  for V := 1 to 6 do
  begin
    vox_getviewbuffer(Buf, Size, P, voxelview_t(V));
    Emit(Format('view %s %d %s', [Name, V, Img2Hash(P, Size)]));

    vox_getdepthviewbuffer(Buf, Size, Depth, voxelview_t(V));
    SetLength(Items, Size * Size * 3);
    for I := 0 to Size - 1 do
      for J := 0 to Size - 1 do
      begin
        Items[(I * Size + J) * 3] := Depth[I, J].color;
        Items[(I * Size + J) * 3 + 1] := Depth[I, J].depth;
        Items[(I * Size + J) * 3 + 2] := Cardinal(PtrIndex(Depth[I, J].prev, Buf, Size) + 1);
      end;
    Emit(Format('depth %s %d %s', [Name, V, TVoxelScenarios.Digest(Items)]));

    // the pointers of the probes
    Step := 1;
    if Size > 64 then
      Step := 5;
    SetLength(Idx, 0);
    X := -3;
    while X < Size + 6 do
    begin
      Y := -2;
      while Y < Size + 5 do
      begin
        Count := Length(Idx);
        SetLength(Idx, Count + 1 + 3);
        Idx[Count] := PtrIndex(vox_getdepthpointerAtXY(Buf, Size, X, Y, voxelview_t(V)), Buf, Size);
        for Z := 0 to 2 do
          Idx[Count + 1 + Z] := PtrIndex(vox_getdepthpointerAtXYZ(Buf, Size, X, Y, (Z * (Size - 1)) div 2, voxelview_t(V)), Buf, Size);
        Inc(Y, Step * 3 + 1);
      end;
      Inc(X, Step * 3 + 2);
    end;
    Emit(Format('probe %s %d %s', [Name, V, TVoxelScenarios.DigestIntegers(Idx)]));

    // painting a picture on the view
    LoadModel(AModel, Buf);
    Probe := TVoxelScenarios.ProbeImage(Size, V);
    for I := 0 to Size - 1 do
      for J := 0 to Size - 1 do
        P[I, J] := Probe[I * Size + J];
    vox_setviewbuffer(Buf, Size, P, voxelview_t(V));
    Emit(Format('setview %s %d %s', [Name, V, BufHash(Buf, Size)]));
    LoadModel(AModel, Buf);
  end;
  FreeMem(P);
  FreeMem(Depth);
  W := nil;
  if W <> nil then
    Exit;
end;

procedure RunPlanes(AModel: Integer);
var
  Size, Kind, Level: Integer;
  P: voxelbuffer2d_p;
  Name: string;
  Op: Integer;
  OpNames: array[0..3] of string;
  Probe: TArray<Cardinal>;
  I, J: Integer;
begin
  Size := TVoxelScenarios.ModelSize(AModel);
  if Size > 64 then
    Exit;
  Name := TVoxelScenarios.ModelName(AModel);
  OpNames[0] := 'flipH';
  OpNames[1] := 'flipV';
  OpNames[2] := 'rotL';
  OpNames[3] := 'rotR';
  GetMem(P, SizeOf(voxelbuffer2d_t));
  for Kind := 0 to 8 do
  begin
    if Kind = 0 then Level := Size div 2
    else if Kind = 1 then Level := Size div 3
    else Level := 1;
    for Op := 0 to 3 do
    begin
      LoadModel(AModel, Buf);
      GetPlane(Buf, Size, Kind, Level, P);
      case Op of
        0: FlipHorz(P, Size);
        1: FlipVert(P, Size);
        2: RotatePlane(P, Size, True);
      else
        RotatePlane(P, Size, False);
      end;
      SetPlane(Buf, Size, Kind, Level, P);
      Emit(Format('plane %s %s %s %s', [Name, PlaneName(Kind), OpNames[Op], BufHash(Buf, Size)]));
    end;
    // the picture of the plane as it is, and cleared
    LoadModel(AModel, Buf);
    GetPlane(Buf, Size, Kind, Level, P);
    Emit(Format('getplane %s %s %s', [Name, PlaneName(Kind), Img2Hash(P, Size)]));
    Probe := TVoxelScenarios.ProbeImage(Size, 50 + Kind, 0);
    for I := 0 to Size - 1 do
      for J := 0 to Size - 1 do
        P[I, J] := 0;
    SetPlane(Buf, Size, Kind, Level, P);
    Emit(Format('erase %s %s %s', [Name, PlaneName(Kind), BufHash(Buf, Size)]));
  end;
  FreeMem(P);
end;

procedure RunWholeOperations(AModel: Integer);
const
  CROPS: array[0..5, 0..1] of Integer = ((0, 255), (10, 200), (64, 128), (100, 100), (200, 50), (255, 255));
  SHRINKS: array[0..6, 0..1] of Integer = ((10, 200), (64, 128), (0, 100), (50, 255), (200, 50), (0, 0), (255, 255));
var
  Size, I, X, Y, Z, J: Integer;
  Name: string;
  Changed: Boolean;
  C, Cn: LongWord;
  R, G, B: Byte;
  Grey: Integer;
  A: array[0..255] of TDNumberList;
  Total: Integer;
  Pal: TPaletteArray;
  RawPal: pointer;
  PalNames: array[0..1] of string;
  Image: TArray<Cardinal>;
begin
  Size := TVoxelScenarios.ModelSize(AModel);
  Name := TVoxelScenarios.ModelName(AModel);

  LoadModel(AModel, Buf);
  vox_removenonvisiblecells(Buf, Size);
  Emit(Format('nonvisible %s %s', [Name, BufHash(Buf, Size)]));

  for I := 0 to High(CROPS) do
  begin
    LoadModel(AModel, Buf);
    vox_cropyaxis(Buf, Size, CROPS[I, 0], CROPS[I, 1]);
    Emit(Format('crop %s %d-%d %s', [Name, CROPS[I, 0], CROPS[I, 1], BufHash(Buf, Size)]));
  end;
  for I := 0 to High(SHRINKS) do
  begin
    // the old shrink wrote one cell past the cube when the heights were both near 255 in a cube smaller than 256
    if (Size < 256) and (SHRINKS[I, 0] >= 255) then
      Continue;
    LoadModel(AModel, Buf);
    vox_shrinkyaxis(Buf, Size, SHRINKS[I, 0], SHRINKS[I, 1]);
    Emit(Format('shrink %s %d-%d %s', [Name, SHRINKS[I, 0], SHRINKS[I, 1], BufHash(Buf, Size)]));
  end;

  // greyscale (Greyscale1Click)
  LoadModel(AModel, Buf);
  Changed := False;
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
      for Z := 0 to Size - 1 do
      begin
        C := Buf[X, Y, Z];
        if C <> 0 then
        begin
          R := GetRValue(C);
          G := GetRValue(C);
          B := GetRValue(C);
          Grey := GetIntegerInRange(Round(0.3 * R + 0.59 * G + 0.11 * B), 0, 255);
          if Grey = 0 then
            Grey := 1;
          Cn := RGB(Grey, Grey, Grey);
          if Cn <> C then
          begin
            Changed := True;
            Buf[X, Y, Z] := Cn;
          end;
        end;
      end;
  Emit(Format('gray %s %d %s', [Name, Ord(Changed), BufHash(Buf, Size)]));

  // count colors (Countcolorsused1Click)
  LoadModel(AModel, Buf);
  for X := 0 to 255 do
    A[X] := TDNumberList.Create;
  for X := 0 to Size - 1 do
    for Y := 0 to Size - 1 do
      for Z := 0 to Size - 1 do
      begin
        C := Buf[X, Y, Z];
        if C <> 0 then
        begin
          R := GetRValue(C);
          if A[R].IndexOf(C) < 0 then
            A[R].Add(C);
        end;
      end;
  Total := 0;
  for X := 0 to 255 do
  begin
    Total := Total + A[X].Count;
    A[X].Free;
  end;
  Emit(Format('count %s %d', [Name, Total]));

  // reduction to a palette (Convertto256colorspalette1Click)
  PalNames[0] := 'DOOM';
  PalNames[1] := 'HERETIC';
  for J := 0 to 1 do
  begin
    LoadModel(AModel, Buf);
    RawPal := VXE_GetRowPalette(PalNames[J]);
    VXE_RawPalette2PaletteArray(RawPal, Pal);
    Changed := False;
    for X := 0 to Size - 1 do
      for Y := 0 to Size - 1 do
        for Z := 0 to Size - 1 do
        begin
          C := Buf[X, Y, Z];
          if C <> 0 then
          begin
            Cn := Pal[VXE_FindAproxColorIndex(@Pal, C, 0, 255)];
            if Cn = 0 then
              Cn := $1;
            if Cn <> C then
            begin
              Changed := True;
              Buf[X, Y, Z] := Cn;
            end;
          end;
        end;
    Emit(Format('applypal %s %s %d %s', [Name, PalNames[J], Ord(Changed), BufHash(Buf, Size)]));
  end;

  // the terrain texture (ApplyTerrainTexture11Click, the picture already stretched and flipped)
  LoadModel(AModel, Buf);
  Image := TVoxelScenarios.ProbeImage(Size, 77, 10);
  for X := 0 to Size - 1 do
    for Z := 0 to Size - 1 do
      for Y := 0 to Size - 1 do
        if Buf[X, Y, Z] <> 0 then
        begin
          Buf[X, Y, Z] := Image[X * Size + Z] and $FFFFFF;
          if Buf[X, Y, Z] = 0 then
            Buf[X, Y, Z] := $1;
        end;
  Emit(Format('terrain %s %s', [Name, BufHash(Buf, Size)]));
end;

procedure RunHeightmap(ASize: Integer);
var
  hmap, vmap: array[0..255, 0..255] of Integer;
  b: Integer;
  i, j, k: Integer;
  c: LongWord;
  fscale1: Extended;
  Image: TArray<Cardinal>;
  Pix: LongWord;
begin
  FillChar(Buf^, SizeOf(voxelbuffer_t), 0);
  Image := TVoxelScenarios.ProbeImage(ASize, 31, 15);
  if ASize = 256 then
  begin
    for i := 0 to 255 do
      for j := 0 to 255 do
      begin
        Pix := Image[i * ASize + j];
        k := GetGray256Color(Pix);
        hmap[i, j] := k;
        vmap[i, j] := k;
      end;
  end
  else
  begin
    fscale1 := ASize / 256;
    for i := 0 to ASize - 1 do
      for j := 0 to ASize - 1 do
      begin
        Pix := Image[i * ASize + j];
        k := GetGray256Color(Pix);
        hmap[i, j] := k;
        vmap[i, j] := round(k * fscale1);
        if vmap[i, j] >= ASize then
          vmap[i, j] := ASize - 1
        else if vmap[i, j] < 0 then
          vmap[i, j] := 0;
      end;
  end;
  for i := 0 to ASize - 1 do
    for j := 0 to ASize - 1 do
    begin
      c := RGB(hmap[i, j], hmap[i, j], hmap[i, j]);
      if c = 0 then
        c := $1;
      for k := 0 to vmap[i, j] do
        Buf[i, ASize - k - 1, j] := c;
    end;
  vox_removenonvisiblecells(Buf, ASize);
  b := ASize;
  Emit(Format('heightmap %d %s', [b, BufHash(Buf, ASize)]));
end;

procedure RunRotations(AModel: Integer);
const
  DEGREES: array[0..5] of Integer = (0, 30, 45, 90, 133, -20);
var
  Size, I: Integer;
  Name: string;
  Theta: Double;
  T: voxelbuffer_p;
  X, Y, Z: Integer;
begin
  Size := TVoxelScenarios.ModelSize(AModel);
  if Size > 64 then
    Exit;
  Name := TVoxelScenarios.ModelName(AModel);
  T := vox_getbuffer;
  for I := 0 to High(DEGREES) do
  begin
    Theta := DEGREES[I] / 360 * (2 * pi);
    LoadModel(AModel, Buf);
    VXE_RotateVoxelBuffer(Buf, Size, Theta, T);
    for X := 0 to Size - 1 do
      for Y := 0 to Size - 1 do
        for Z := 0 to Size - 1 do
          Buf[X, Y, Z] := T[X, Y, Z];
    Emit(Format('rotate %s %d %s', [Name, DEGREES[I], BufHash(Buf, Size)]));
    if Size <= 32 then
    begin
      LoadModel(AModel, Buf);
      VXE_RotateVoxelBufferHQ(Buf, Size, Theta, T);
      for X := 0 to Size - 1 do
        for Y := 0 to Size - 1 do
          for Z := 0 to Size - 1 do
            Buf[X, Y, Z] := T[X, Y, Z];
      Emit(Format('rotatehq %s %d %s', [Name, DEGREES[I], BufHash(Buf, Size)]));
    end;
  end;
  vox_freebuffer(T);
end;

procedure RunQuantizer(AModel: Integer);
const
  COUNTS: array[0..2] of Integer = (255, 100, 16);
var
  Size, I, J: Integer;
  Name: string;
  Pal: TPaletteArray;
  Flag: Boolean;
  Hash: TArray<Cardinal>;
begin
  Size := TVoxelScenarios.ModelSize(AModel);
  Name := TVoxelScenarios.ModelName(AModel);
  for I := 0 to High(COUNTS) do
  begin
    LoadModel(AModel, Buf);
    for J := 0 to 255 do
      Pal[J] := 0;
    Flag := vxe_getquantizevoxelpalette(Buf, Size, Pal, COUNTS[I]);
    SetLength(Hash, 256);
    for J := 0 to 255 do
      Hash[J] := Pal[J];
    Emit(Format('quantpal %s %d %d %s', [Name, COUNTS[I], Ord(Flag), TVoxelScenarios.Digest(Hash)]));
    LoadModel(AModel, Buf);
    vxe_quantizevoxeldata(Buf, Size, COUNTS[I]);
    Emit(Format('quantize %s %d %s', [Name, COUNTS[I], BufHash(Buf, Size)]));
  end;
end;

procedure RunMesh(AModel: Integer);
var
  Size, Pass: Integer;
  Name: string;
  Legacy, Fixed: TBytes;
  Hits, Quads: Integer;
  Mesh: TVoxelMeshOptimizer;
  M: TMemoryStream;

  function Make(AFix: Boolean; out ACount: Integer): TBytes;
  begin
    VoxelMeshFixCompaction := AFix;
    Mesh := TVoxelMeshOptimizer.Create;
    Mesh.LoadVoxel(Size, Buf);
    Mesh.passcount := Pass;
    Mesh.Optimize;
    ACount := Mesh.numquads;
    M := TMemoryStream.Create;
    Mesh.SaveToStream(M);
    SetLength(Result, M.Size);
    Move(M.Memory^, Result[0], M.Size);
    M.Free;
    Mesh.Free;
  end;

var
  QL, QF: Integer;
  NewSize: Integer;
begin
  Size := TVoxelScenarios.ModelSize(AModel);
  if (Size > 64) or (AModel = 0) then
    Exit;
  Name := TVoxelScenarios.ModelName(AModel);
  for Pass := 1 to 3 do
  begin
    LoadModel(AModel, Buf);
    VoxelMeshLegacyHits := 0;
    Legacy := Make(False, QL);
    Hits := VoxelMeshLegacyHits;
    Fixed := Make(True, QF);
    Quads := QF;
    Emit(Format('mesh %s %d %s %d %s %d %d', [Name, Pass, TVoxelScenarios.DigestBytes(Legacy), Hits,
      TVoxelScenarios.DigestBytes(Fixed), QF, QL]));
    if Pass = 3 then
    begin
      PutBytes(TempFile, Fixed);
      OldLoadDdmesh(TempFile, Tmp, NewSize);
      Emit(Format('meshread %s %d %s', [Name, NewSize, BufHash(Tmp, NewSize)]));
    end;
  end;
  VoxelMeshFixCompaction := False;
end;

procedure RunFormats(AModel: Integer);
var
  Size, NewSize: Integer;
  Name: string;
  Bytes: TBytes;
begin
  Size := TVoxelScenarios.ModelSize(AModel);
  Name := TVoxelScenarios.ModelName(AModel);
  LoadModel(AModel, Buf);
  OldSaveDdvox(TempFile, Buf, Size);
  Bytes := FileBytes(TempFile);
  Emit(Format('ddvoxwrite %s %s', [Name, TVoxelScenarios.DigestBytes(Bytes)]));
  OldLoadDdvox(TempFile, Tmp, NewSize);
  Emit(Format('ddvoxread %s %d %s', [Name, NewSize, BufHash(Tmp, NewSize)]));
LoadModel(AModel, Buf);
  VXE_ExportVoxelToSlab6VOX(Buf, Size, TempFile);
  Bytes := FileBytes(TempFile);
  Emit(Format('voxwrite %s %s', [Name, TVoxelScenarios.DigestBytes(Bytes)]));
end;

procedure RunFiles;
var
  I, NewSize: Integer;
begin
  for I := 0 to TVoxelScenarios.KVX_COUNT - 1 do
  begin
    PutBytes(TempFile, TVoxelScenarios.KvxBytes(I));
    OldLoadKVX(TempFile, Buf, NewSize);
    Emit(Format('kvx %d %d %s', [I, NewSize, BufHash(Buf, NewSize)]));
  end;
  for I := 0 to TVoxelScenarios.VOX_COUNT - 1 do
  begin
    PutBytes(TempFile, TVoxelScenarios.VoxBytes(I));
    OldLoadVOX(TempFile, Buf, NewSize);
    Emit(Format('vox %d %d %s', [I, NewSize, BufHash(Buf, NewSize)]));
  end;
end;

procedure RunPalettes;
const
  NAMES: array[0..4] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE', 'RADIX');
var
  I: Integer;
  Bytes: TBytes;
begin
  for I := 0 to 4 do
  begin
    SetLength(Bytes, 768);
    Move(VXE_GetRowPalette(NAMES[I])^, Bytes[0], 768);
    Emit(Format('palraw %s %s', [NAMES[I], TVoxelScenarios.DigestBytes(Bytes)]));
  end;
end;

var
  M: Integer;

begin
  Golden := TStringList.Create;
  MT_Init;
  vox_initbuffers;
  vox_initthreads;
  Buf := vox_getbuffer;
  Tmp := vox_getbuffer;
  TempFile := ChangeFileExt(ParamStr(0), '.tmp');
  RunPalettes;
  for M := 0 to TVoxelScenarios.MODEL_COUNT - 1 do
  begin
    Writeln('model ', TVoxelScenarios.ModelName(M));
    RunViews(M);
    RunPlanes(M);
    RunWholeOperations(M);
    RunRotations(M);
    RunQuantizer(M);
    RunMesh(M);
    RunFormats(M);
  end;
  RunHeightmap(16);
  RunHeightmap(32);
  RunHeightmap(64);
  RunHeightmap(256);
  RunFiles;
  Golden.SaveToFile(ParamStr(1));
  Writeln(Golden.Count, ' lines');
  vox_shutdownthreads;
  MT_ShutDown;
end.
