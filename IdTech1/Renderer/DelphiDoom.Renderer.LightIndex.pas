{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - index of the hi resolution light levels      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The clamp is the one of R_MapPlane, R_MapPlaneAngle and R_MapSlope* of the  }
{  software renderer                                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.LightIndex;

interface

type
  /// <summary>
  ///   The index of the table of hi resolution light levels (zlightlevels) of a span of a flat
  /// </summary>
  TRendererLightIndex = class
  public
    /// <summary>
    ///   The column of zlightlevels of a span, AColumn being the distance of the span already shifted
    ///   (_SHR(distance, HLL_ZDISTANCESHIFT)): clamped to 0..AColumns - 1. A negative value is the distance of a
    ///   span near the horizon that overflowed the 32 bits of fixed_t: like the 8 bit index (an unsigned value
    ///   that wraps to a huge one) it is the farthest column, AColumns - 1. Without the lower limit the table
    ///   was read tens of thousands of entries before its row, and what was found there (and so the pixel)
    ///   depended on where the linker put the variables: the 32 bit and the 64 bit executable drew a
    ///   different pixel (issue #40)
    /// </summary>
    class function Clamp(AColumn, AColumns: Integer): Integer; static; inline;
  end;

implementation

{ TRendererLightIndex }

//==============================================================================
//
// TRendererLightIndex.Clamp
//
//==============================================================================
class function TRendererLightIndex.Clamp(AColumn, AColumns: Integer): Integer;
begin
  if (AColumn >= AColumns) or (AColumn < 0) then
    Result := AColumns - 1
  else
    Result := AColumn;
end;

end.
