{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL automap - the OLD buffer of gl_automap.pas  }
{                                                                              }
{  The text of gld_ClearAMBuffer, gld_AddAutomapLine, gld_AddAutomapPatch and  }
{  gld_AddAutomapTriangle as it was before issue #177 (slice 8), kept here     }
{  only to compare the new class with it. Changed only: the sector is a        }
{  record of the test with the fields the old code read, the constants of      }
{  the engine (FRACUNIT, ANGLE_MAX, FLATUVSCALE) are copied, the buffer is     }
{  inside a record instead of unit variables and grows with ReallocMem.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.OldAutomapBuffer;

interface

const
  FRACUNIT = 1 shl 16;
  ANGLE_MAX = $FFFFFFFF;
  FLATUVSCALE = FRACUNIT * 64.0;

  GL_AM_QUAD = 0;
  GL_AM_LINE = 1;
  GL_AM_TRIANGLE = 2;
  GL_AM_PATCH = 3;

type
  float = Single;
  fixed_t = Integer;
  angle_t = LongWord;

  /// <summary>The fields of sector_t that the old buffer read</summary>
  old_sector_t = record
    floorpic: SmallInt;
    floorangle: angle_t;
    flooranglex: fixed_t;
    floorangley: fixed_t;
  end;
  Pold_sector_t = ^old_sector_t;

  glamrenderitem_t = record
    itemtype: integer;
    x1, y1, x2, y2, x3, y3: integer;
    u1, v1, u2, v2, u3, v3: float;
    lump: integer;
    flat: integer;
    hasangle: boolean;
    angle: float;
    anglex, angley: float;
    r, g, b: float;
    sec: Pold_sector_t;
  end;
  Pglamrenderitem_t = ^glamrenderitem_t;
  glamrenderitem_tArray = array[0..$FFF] of glamrenderitem_t;
  Pglamrenderitem_tArray = ^glamrenderitem_tArray;

  /// <summary>The three unit variables of the old gl_automap.pas</summary>
  TOldAutomapBuffer = record
    amrenderitems: Pglamrenderitem_tArray;
    numamitems: integer;
    realnumamitems: integer;
  end;

procedure old_InitAutomap(var buf: TOldAutomapBuffer);

procedure old_ShutDownAutomap(var buf: TOldAutomapBuffer);

procedure old_ClearAMBuffer(var buf: TOldAutomapBuffer; const fw, fh: integer; const cc: LongWord);

procedure old_AddAutomapLine(var buf: TOldAutomapBuffer; const x1, y1, x2, y2: integer; const cc: LongWord);

procedure old_AddAutomapPatch(var buf: TOldAutomapBuffer; const x, y: integer; const lump: integer);

procedure old_AddAutomapTriangle(var buf: TOldAutomapBuffer;
  const x1, y1, u1, v1: integer;
  const x2, y2, u2, v2: integer;
  const x3, y3, u3, v3: integer;
  const cc: LongWord; const lump: integer; const sec: Pold_sector_t);

implementation

procedure old_InitAutomap(var buf: TOldAutomapBuffer);
begin
  buf.amrenderitems := nil;
  buf.numamitems := 0;
  buf.realnumamitems := 0;
end;

procedure old_ShutDownAutomap(var buf: TOldAutomapBuffer);
begin
  FreeMem(buf.amrenderitems);
  buf.amrenderitems := nil;
  buf.numamitems := 0;
  buf.realnumamitems := 0;
end;

procedure old_GrowAutomapLines(var buf: TOldAutomapBuffer);
const
  GROWSTEP = 64;
begin
  if buf.numamitems >= buf.realnumamitems then
  begin
    ReallocMem(buf.amrenderitems, (buf.realnumamitems + GROWSTEP) * SizeOf(glamrenderitem_t));
    buf.realnumamitems := buf.realnumamitems + GROWSTEP;
  end;
end;

procedure old_ClearAMBuffer(var buf: TOldAutomapBuffer; const fw, fh: integer; const cc: LongWord);
var
  l: Pglamrenderitem_t;
begin
  old_GrowAutomapLines(buf);

  l := @buf.amrenderitems[buf.numamitems];
  l.itemtype := GL_AM_QUAD;
  l.x1 := 0;
  l.y1 := 0;
  l.x2 := fw;
  l.y2 := fh;
  l.r := ((cc shr 16) and $FF) / 255;
  l.g := ((cc shr 8) and $FF) / 255;
  l.b := (cc and $FF) / 255;

  inc(buf.numamitems);
end;

procedure old_AddAutomapLine(var buf: TOldAutomapBuffer; const x1, y1, x2, y2: integer; const cc: LongWord);
var
  l: Pglamrenderitem_t;
begin
  old_GrowAutomapLines(buf);

  l := @buf.amrenderitems[buf.numamitems];
  l.itemtype := GL_AM_LINE;
  l.x1 := x1;
  l.y1 := y1;
  l.x2 := x2;
  l.y2 := y2;
  l.r := ((cc shr 16) and $FF) / 255;
  l.g := ((cc shr 8) and $FF) / 255;
  l.b := (cc and $FF) / 255;

  inc(buf.numamitems);
end;

procedure old_AddAutomapPatch(var buf: TOldAutomapBuffer; const x, y: integer; const lump: integer);
var
  l: Pglamrenderitem_t;
begin
  old_GrowAutomapLines(buf);

  l := @buf.amrenderitems[buf.numamitems];
  l.itemtype := GL_AM_PATCH;
  l.x1 := x;
  l.y1 := y;
  l.lump := lump;

  inc(buf.numamitems);
end;

procedure old_AddAutomapTriangle(var buf: TOldAutomapBuffer;
  const x1, y1, u1, v1: integer;
  const x2, y2, u2, v2: integer;
  const x3, y3, u3, v3: integer;
  const cc: LongWord; const lump: integer; const sec: Pold_sector_t);
var
  l: Pglamrenderitem_t;
begin
  old_GrowAutomapLines(buf);

  l := @buf.amrenderitems[buf.numamitems];
  l.itemtype := GL_AM_TRIANGLE;

  l.x1 := x1;
  l.y1 := y1;
  l.u1 := u1 / FRACUNIT / 64;
  l.v1 := v1 / FRACUNIT / 64;

  l.x2 := x2;
  l.y2 := y2;
  l.u2 := u2 / FRACUNIT / 64;
  l.v2 := v2 / FRACUNIT / 64;

  l.x3 := x3;
  l.y3 := y3;
  l.u3 := u3 / FRACUNIT / 64;
  l.v3 := v3 / FRACUNIT / 64;

  l.r := ((cc shr 16) and $FF) / 255;
  l.g := ((cc shr 8) and $FF) / 255;
  l.b := (cc and $FF) / 255;

  l.lump := lump;
  l.flat := sec.floorpic;
  l.sec := sec;

  l.hasangle := sec.floorangle <> 0;
  if l.hasangle then
  begin
    l.angle := (sec.floorangle / ANGLE_MAX) * 360.0;
    l.anglex := sec.flooranglex / FLATUVSCALE;
    l.angley := sec.floorangley / FLATUVSCALE;
  end;

  inc(buf.numamitems);
end;

end.
