{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: overbright       }
{  shift of the vertex colours                                                 }
{                                                                              }
{  Port of R_ColorShiftLightingBytes (tr_bsp.c). Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.ColorShift;

{$Q-}
{$R-}

interface

type
  /// <summary>The colour of a vertex: red, green, blue, alpha</summary>
  TBspColor = array[0..3] of Byte;

  /// <summary>
  ///   Shifts the colour of a vertex by r_mapOverBrightBits - overbrightBits bits, and
  ///   normalises by colour (not by saturating to white) if a channel goes over 255. A shift
  ///   below 0 is undefined in C (x86 masks the count, giving garbage); it is a right shift here.
  /// </summary>
  TBspColorShift = class
  public
    class procedure Apply(const AShift: Integer; const AColor: TBspColor;
      out AResult: TBspColor); static;
  end;

implementation

class procedure TBspColorShift.Apply(const AShift: Integer; const AColor: TBspColor;
  out AResult: TBspColor);
var
  LRed, LGreen, LBlue, LMax: Integer;
begin
  if AShift >= 0 then
  begin
    LRed := AColor[0] shl AShift;
    LGreen := AColor[1] shl AShift;
    LBlue := AColor[2] shl AShift;
  end
  else
  begin
    LRed := AColor[0] shr -AShift;
    LGreen := AColor[1] shr -AShift;
    LBlue := AColor[2] shr -AShift;
  end;
  // normalize by color instead of saturating to white
  if (LRed or LGreen or LBlue) > 255 then
  begin
    if LRed > LGreen then
      LMax := LRed
    else
      LMax := LGreen;
    if not (LMax > LBlue) then
      LMax := LBlue;
    LRed := LRed * 255 div LMax;
    LGreen := LGreen * 255 div LMax;
    LBlue := LBlue * 255 div LMax;
  end;
  AResult[0] := Byte(LRed);
  AResult[1] := Byte(LGreen);
  AResult[2] := Byte(LBlue);
  AResult[3] := AColor[3];
end;

end.
