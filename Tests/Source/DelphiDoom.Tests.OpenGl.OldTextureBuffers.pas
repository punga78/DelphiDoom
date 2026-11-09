{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL texture buffers - the OLD routines          }
{                                                                              }
{  The text of gld_InitPalettedTextures, gld_SetTexturePalette,                }
{  gld_AddPatchToTexture(_UnTranslated), gld_RippleTransform,                  }
{  gld_AddFlatToTexture, gld_AddPatchForTransparencyCheck and the scan of      }
{  gld_CheckTextureTransparency of gl_tex.pas as they were before issue #177   }
{  (slice 5), with shims where they touched the engine (the zone memory, the   }
{  palette lump, the ripple table): the reference of the parity tests.         }
{  The pointer casts through Integer are the old ones: Win32 only.             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.OldTextureBuffers;

interface

type
  OldGLTexture = record
    realtexwidth: integer;
    realtexheight: integer;
    buffer_width: integer;
    buffer_height: integer;
  end;
  POldGLTexture = ^OldGLTexture;

  OldByteArray = array[0..MaxInt div 2] of byte;
  POldByteArray = ^OldByteArray;
  OldIntegerArray = array[0..MaxInt div 8] of integer;
  POldIntegerArray = ^OldIntegerArray;

var
  old_palmap: array[0..255] of byte;
  old_transparent_pal_index: integer;
  // the palette lump (V_ReadPalette) and the ripple row (r_defripple[ripple]) of the test
  old_playpal: POldByteArray;
  old_ripple: POldIntegerArray;

procedure Old_InitPalettedTextures;
procedure Old_SetTexturePalette(var pal: array of byte);
procedure Old_AddPatchToTexture_UnTranslated(gltexture: POldGLTexture; buffer: POldByteArray;
  const patch: pointer; originx, originy: integer; paletted: boolean);
procedure Old_AddPatchToTexture(gltexture: POldGLTexture; buffer: POldByteArray;
  const patch: pointer; originx, originy: integer; trans: POldByteArray; paletted: boolean);
procedure Old_RippleTransform(const buffer: pointer; const w, h: integer; const bytepp: integer);
procedure Old_AddFlatToTexture(gltexture: POldGLTexture; buffer: POldByteArray; const flat: POldByteArray;
  paletted: boolean; const ripple: boolean);
procedure Old_AddPatchForTransparencyCheck(gltexture: POldGLTexture; buffer: POldByteArray;
  const patch: pointer; originx, originy: integer);
/// <summary>The scan at the end of gld_CheckTextureTransparency</summary>
function Old_ScanTransparency(buffer: POldByteArray; bufsize: integer): boolean;

implementation

type
  PLongWord = ^LongWord;
  PLongWordArray = ^TLongWordArray;
  TLongWordArray = array[0..MaxInt div 8] of LongWord;
  Pcolumn_t = ^column_t;
  column_t = packed record
    topdelta: byte;
    length: byte;
  end;
  Ppatch_t = ^patch_t;
  patch_t = packed record
    width: smallint;
    height: smallint;
    leftoffset: smallint;
    topoffset: smallint;
    columnofs: array[0..7] of integer;
  end;

function _SHL(const x: integer; const bits: integer): integer;
begin
  Result := x shl bits;
end;

procedure Old_InitPalettedTextures;
var
  playpal: POldByteArray;
  pal: array[0..255] of LongWord;
  i, j: integer;
begin
  playpal := old_playpal;
  for i := 0 to 255 do
  begin
    pal[i] := _SHL(playpal[i * 3], 16) or _SHL(playpal[i * 3 + 1], 8) or playpal[i * 3 + 2];
    old_palmap[i] := i;
  end;
  old_transparent_pal_index := -1;
  for i := 0 to 255 do
  begin
    for j := i + 1 to 255 do
      if pal[i] = pal[j] then
      begin
        old_transparent_pal_index := j;
        old_palmap[j] := i;
        break;
      end;
    if old_transparent_pal_index >= 0 then
      break;
  end;
end;

// the old code wrote the transparent entry at index -1 when there was none: the test never asks for that
procedure Old_SetTexturePalette(var pal: array of byte);
var
  playpal: POldByteArray;
  pl, pp: PLongWord;
  i: integer;
begin
  playpal := old_playpal;
  pl := PLongWord(playpal);
  pp := PLongWord(@pal[0]);
  for i := 0 to 255 do
  begin
    pp^ := pl^ or $FF000000;
    pp := PLongWord(integer(pp) + 4);
    pl := PLongWord(integer(pl) + 3);
  end;
  PLongWordArray(@pal[0])[old_transparent_pal_index] := 0;
end;

procedure Old_AddPatchToTexture_UnTranslated(gltexture: POldGLTexture; buffer: POldByteArray;
  const patch: pointer; originx, originy: integer; paletted: boolean);
var
  x, y, j: integer;
  xs, xe: integer;
  js,je: integer;
  column: Pcolumn_t;
  source: POldByteArray;
  pos: integer;
  playpal: POldByteArray;
  ss: integer;
  delta, prevdelta: integer;
  tallpatch: boolean;
  p: Ppatch_t;
begin
  p := Ppatch_t(patch);
  if (gltexture = nil) or (patch = nil) then
    exit;

  playpal := old_playpal;
  xs := 0;
  xe := p.width;
  if (xs + originx) >= gltexture.realtexwidth then
    exit;
  if (xe + originx) <= 0 then
    exit;
  if (xs + originx) < 0 then
    xs := -originx;
  if (xe + originx) > gltexture.realtexwidth then
    xe := xe + gltexture.realtexwidth - (xe + originx);
  for x := xs to xe - 1 do
  begin
    delta := 0;
    tallpatch := false;
    column := Pcolumn_t(integer(patch) + p.columnofs[x]);
    while column.topdelta <> 255 do
    begin
      delta := delta + column.topdelta;
      y := (delta + originy);
      js := 0;
      je := column.length;
      if (js + y >= gltexture.realtexheight) or (je + y <= 0) then
      begin
        column := Pcolumn_t(integer(column) + column.length + 4);
        delta := 0;
        continue;
      end;
      if js + y < 0 then
        js := -y;
      if je + y > gltexture.realtexheight then
        je := je + gltexture.realtexheight - (je + y);
      source := POldByteArray(integer(column) + 3);
      if paletted then
      begin
        pos := (js + y) * gltexture.buffer_width + x + originx;
        j := js;
        while j < je do
        begin
          buffer[pos] := old_palmap[source[j]];
          inc(j);
          pos := pos + gltexture.buffer_width;
        end;
      end
      else
      begin
        pos := 4 * ((js + y) * gltexture.buffer_width + x + originx);
        j := js;
        while j < je do
        begin
          ss := source[j] * 3;
          buffer[pos] := playpal[ss];
          buffer[pos + 1] := playpal[ss + 1];
          buffer[pos + 2] := playpal[ss + 2];
          buffer[pos + 3] := 255;
          inc(j);
          pos := pos + 4 * gltexture.buffer_width;
        end;
      end;
      if not tallpatch then
      begin
        prevdelta := column.topdelta;
        column := Pcolumn_t(integer(column) + column.length + 4);
        if column.topdelta > prevdelta then
          delta := 0
        else
          tallpatch := true;
      end
      else
        column := Pcolumn_t(integer(column) + column.length + 4);
    end;
  end;
end;

procedure Old_AddPatchToTexture(gltexture: POldGLTexture; buffer: POldByteArray;
  const patch: pointer; originx, originy: integer; trans: POldByteArray; paletted: boolean);
var
  x, y, j: integer;
  xs, xe: integer;
  js,je: integer;
  column: Pcolumn_t;
  source: POldByteArray;
  pos: integer;
  playpal: POldByteArray;
  ss: integer;
  delta, prevdelta: integer;
  tallpatch: boolean;
  p: Ppatch_t;
begin
  p := Ppatch_t(patch);
  if (gltexture = nil) or (patch = nil) then
    exit;

  playpal := old_playpal;
  xs := 0;
  xe := p.width;
  if xs + originx >= gltexture.realtexwidth then
    exit;
  if xe + originx <= 0 then
    exit;
  if xs + originx < 0 then
    xs := -originx;
  if xe + originx > gltexture.realtexwidth then
    xe := xe + gltexture.realtexwidth - (xe + originx);
  for x := xs to xe - 1 do
  begin
    delta := 0;
    tallpatch := false;
    column := Pcolumn_t(integer(patch) + p.columnofs[x]);
    while column.topdelta <> 255 do
    begin
      delta := delta + column.topdelta;
      y := (delta + originy);
      js := 0;
      je := column.length;
      if (js + y >= gltexture.realtexheight) or (je + y <= 0) then
      begin
        column := Pcolumn_t(integer(column) + column.length + 4);
        delta := 0;
        continue;
      end;
      if js + y < 0 then
        js := -y;
      if je + y > gltexture.realtexheight then
        je := je + gltexture.realtexheight - (je + y);
      source := POldByteArray(integer(column) + 3);
      if paletted then
      begin
        pos := (js + y) * gltexture.buffer_width + x + originx;
        j := js;
        while j < je do
        begin
          buffer[pos] := old_palmap[trans[source[j]]];
          inc(j);
          pos := pos + gltexture.buffer_width;
        end;
      end
      else
      begin
        pos := 4 * ((js + y) * gltexture.buffer_width + x + originx);
        j := js;
        while j < je do
        begin
          ss := trans[source[j]] * 3;
          buffer[pos] := playpal[ss];
          buffer[pos + 1] := playpal[ss + 1];
          buffer[pos + 2] := playpal[ss + 2];
          buffer[pos + 3] := 255;
          inc(j);
          pos := pos + 4 * gltexture.buffer_width;
        end;
      end;
      if not tallpatch then
      begin
        prevdelta := column.topdelta;
        column := Pcolumn_t(integer(column) + column.length + 4);
        if column.topdelta > prevdelta then
          delta := 0
        else
          tallpatch := true;
      end
      else
        column := Pcolumn_t(integer(column) + column.length + 4);
    end;
  end;
end;

procedure Old_RippleTransform(const buffer: pointer; const w, h: integer; const bytepp: integer);
var
  t: POldIntegerArray;
  x, y, rx, ry, dx, dy: integer;
  newbuf: POldByteArray;
  srcbuf: POldByteArray;

  procedure _transformpixel;
  var
    newp, srcp: integer;
  begin
    srcp := rx + ry * w;
    newp := x + y * w;
    if bytepp = 1 then
    begin
      newbuf[newp] := srcbuf[srcp];
    end
    else if bytepp = 4 then
    begin
      newp := newp * 4;
      srcp := srcp * 4;
      PLongWord(@newbuf[newp])^ := PLongWord(@srcbuf[srcp])^;
    end
    else if bytepp = 3 then
    begin
      newp := newp * 3;
      srcp := srcp * 3;
      newbuf[newp] := srcbuf[srcp];
      newbuf[newp + 1] := srcbuf[srcp + 1];
      newbuf[newp + 2] := srcbuf[srcp + 2];
    end;
  end;

begin
  t:= old_ripple;
  GetMem(newbuf, w * h * bytepp);
  srcbuf := buffer;
  for x := 0 to w - 1 do
    for y := 0 to h - 1 do
    begin
      dx := Round((t[Round(y * 128 / h) and 127] / $10000) * h / 64);
      dy := Round((t[Round(x * 128 / w) and 127] / $10000) * w / 64);
      rx := (x + dx) mod w;
      while rx < 0 do
        rx := rx + w;
      while rx >= w do
        rx := rx - w;
      ry := (y + dy) mod h;
      while ry < 0 do
        ry := ry + h;
      while ry >= h do
        ry := ry + h;
      _transformpixel;
    end;
  Move(newbuf^, buffer^, w * h * bytepp);
  FreeMem(newbuf);
end;

procedure Old_AddFlatToTexture(gltexture: POldGLTexture; buffer: POldByteArray; const flat: POldByteArray;
  paletted: boolean; const ripple: boolean);
var
  x, y, pos: integer;
  yy: integer;
  playpal: POldByteArray;
begin
  if (gltexture = nil) or (flat = nil) then
    exit;

  if paletted then
  begin
    for y := 0 to gltexture.realtexheight - 1 do
    begin
      pos := y * gltexture.buffer_width;
      yy := y * gltexture.realtexwidth;
      for x := 0 to gltexture.realtexwidth - 1 do
      begin
        buffer[pos] := old_palmap[flat[yy + x]];
        inc(pos);
      end;
    end;
    if ripple then
      Old_RippleTransform(buffer, gltexture.buffer_width, gltexture.buffer_height, 1);
  end
  else
  begin
    playpal := old_playpal;
    for y := 0 to gltexture.realtexheight - 1 do
    begin
      pos := 4 * (y * gltexture.buffer_width);
      for x := 0 to gltexture.realtexwidth - 1 do
      begin
        yy := flat[y * gltexture.realtexwidth + x] * 3;
        buffer[pos] := playpal[yy];
        buffer[pos + 1] := playpal[yy + 1];
        buffer[pos + 2] := playpal[yy + 2];
        buffer[pos + 3] := 255;
        inc(pos, 4);
      end;
    end;
    if ripple then
      Old_RippleTransform(buffer, gltexture.buffer_width, gltexture.buffer_height, 4);
  end;
end;

procedure Old_AddPatchForTransparencyCheck(gltexture: POldGLTexture; buffer: POldByteArray;
  const patch: pointer; originx, originy: integer);
var
  x, y, j: integer;
  xs, xe: integer;
  js,je: integer;
  column: Pcolumn_t;
  pos: integer;
  delta, prevdelta: integer;
  tallpatch: boolean;
  p: Ppatch_t;
begin
  p := Ppatch_t(patch);
  xs := 0;
  xe := p.width;
  if xs + originx >= gltexture.realtexwidth then
    exit;
  if xe + originx <= 0 then
    exit;
  if xs + originx < 0 then
    xs := -originx;
  if xe + originx > gltexture.realtexwidth then
    xe := xe + gltexture.realtexwidth - (xe + originx);
  for x := xs to xe - 1 do
  begin
    delta := 0;
    tallpatch := false;
    column := Pcolumn_t(integer(patch) + p.columnofs[x]);
    while column.topdelta <> 255 do
    begin
      delta := delta + column.topdelta;
      y := (delta + originy);
      js := 0;
      je := column.length;
      if (js + y >= gltexture.realtexheight) or (je + y <= 0) then
      begin
        column := Pcolumn_t(integer(column) + column.length + 4);
        delta := 0;
        continue;
      end;
      if js + y < 0 then
        js := -y;
      if je + y > gltexture.realtexheight then
        je := je + gltexture.realtexheight - (je + y);
      pos := ((js + y) * gltexture.realtexwidth + x + originx);
      j := js;
      while j < je do
      begin
        buffer[pos] := 255;
        inc(j);
        pos := pos + gltexture.realtexwidth;
      end;
      if not tallpatch then
      begin
        prevdelta := column.topdelta;
        column := Pcolumn_t(integer(column) + column.length + 4);
        if column.topdelta > prevdelta then
          delta := 0
        else
          tallpatch := true;
      end
      else
        column := Pcolumn_t(integer(column) + column.length + 4);
    end;
  end;
end;

function Old_ScanTransparency(buffer: POldByteArray; bufsize: integer): boolean;
var
  pl: PLongWord;
  spot: integer;
  i: integer;
begin
  result := false;
  if bufsize > 3 then // JVAL: prevent extra small textures, unused ?
  begin
    spot := (bufsize - 3) and (not 3);
    pl := @buffer[spot];
    for i := 0 to (spot shr 2) - 1 do
    begin
      if pl^ <> $FFFFFFFF then
      begin
        result := true;
        break;
      end;
      dec(pl);
    end;

    for i := spot to bufsize - 1 do
    begin
      if buffer[i] <> 255 then
      begin
        result := true;
        break;
      end;
    end;
  end
  else
  begin
    for i := 0 to bufsize - 1 do
    begin
      if buffer[i] <> 255 then
      begin
        result := true;
        break;
      end;
    end;
  end;
end;

end.
