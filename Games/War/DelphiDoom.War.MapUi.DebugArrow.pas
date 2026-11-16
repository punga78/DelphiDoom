{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the head of an arrow of the debug drawing          }
{                                                                              }
{  Port of war1 (acoto87/war1), war_map.c (renderFlowField, renderRvoDebug: the }
{  two strokes of the head), (c) 2019 Alejandro Coto Gutierrez, zlib License    }
{  (see Games\War\LICENSE-war1.txt). This is an altered version, not the       }
{  original.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugArrow;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Render.Types, DelphiDoom.War.Render.Transform;

type
  /// <summary>
  ///   The head of an arrow of the debug drawing: from the point of the arrow two strokes of 3 pixels back at 30 degrees on each
  ///   side of the direction. Every operation in 32 bit floats, one at a time, as the C with atan2f, cosf and sinf
  /// </summary>
  TWarDebugArrow = class
  public
    /// <summary>The angle of a direction (atan2f)</summary>
    class function AngleOf(ADeltaX, ADeltaY: Single): Single; static;
    /// <summary>The two strokes of the head at the point (AEndX, AEndY) of an arrow that goes at the angle</summary>
    class procedure DrawHead(const ATransform: TWarRenderTransform; AEndX, AEndY, AAngle: Single;
      const AColor: TWarRgba); static;
  end;

implementation

uses
  System.Math;

const
  /// <summary>ARROW_HEAD_LEN and headLen of war_map.c</summary>
  HEAD_LENGTH: Single = 3.0;
  /// <summary>PI of war_math.h is a float literal</summary>
  SINGLE_PI: Single = 3.14159265358979323846;

{ TWarDebugArrow }

class function TWarDebugArrow.AngleOf(ADeltaX, ADeltaY: Single): Single;
begin
  Result := ArcTan2(ADeltaY, ADeltaX);
end;

class procedure TWarDebugArrow.DrawHead(const ATransform: TWarRenderTransform; AEndX, AEndY, AAngle: Single;
  const AColor: TWarRgba);
var
  LSixth: Single;
  LArgument: Single;
  LHeadX: Single;
  LHeadY: Single;
begin
  LSixth := SINGLE_PI / 6.0;
  LArgument := AAngle - LSixth;
  LHeadX := HEAD_LENGTH * Cos(LArgument);
  LHeadX := AEndX - LHeadX;
  LHeadY := HEAD_LENGTH * Sin(LArgument);
  LHeadY := AEndY - LHeadY;
  ATransform.StrokeLine(AEndX, AEndY, LHeadX, LHeadY, AColor);
  LArgument := AAngle + LSixth;
  LHeadX := HEAD_LENGTH * Cos(LArgument);
  LHeadX := AEndX - LHeadX;
  LHeadY := HEAD_LENGTH * Sin(LArgument);
  LHeadY := AEndY - LHeadY;
  ATransform.StrokeLine(AEndX, AEndY, LHeadX, LHeadY, AColor);
end;

end.
