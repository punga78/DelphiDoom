{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the colors of the voxel files                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Colors;

interface

type
  /// <summary>The one operation on the colors that the readers share</summary>
  TVoxelColors = class
  public
    /// <summary>
    ///   The color with the red and the blue swapped (the old SwapRGB, one copy in each
    ///   loader): the upper byte is lost. The DDVOX and DDMESH files write blue-green-red.
    /// </summary>
    class function SwapRgb(const AColor: Cardinal): Cardinal; static;
  end;

implementation

{ TVoxelColors }

class function TVoxelColors.SwapRgb(const AColor: Cardinal): Cardinal;
var
  LRed, LGreen, LBlue: Byte;
begin
  LRed := AColor shr 16;
  LGreen := AColor shr 8;
  LBlue := AColor;
  Result := (LBlue shl 16) + (LGreen shl 8) + LRed;
end;

end.
