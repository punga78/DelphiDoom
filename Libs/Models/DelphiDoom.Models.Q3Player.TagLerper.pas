{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, the position of a  }
{  tag between two frames                                                      }
{                                                                              }
{  Port of R_GetTag and R_LerpTag of renderer\tr_model.c. Based on the Quake   }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.TagLerper;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Md3.Types,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>
  ///   Finds a tag by name in a frame of an MD3 (names are compared byte by byte, case matters)
  ///   and interpolates it between two frames: origin and axes by the fraction, then the axes
  ///   normalized.
  /// </summary>
  TQ3TagLerper = class(TInterfacedObject, IQ3TagLerper)
  strict private
    /// <summary>R_GetTag: the index of the tag in the frame, -1 if there is none</summary>
    function FindTag(const AModel: IMd3Model; const AFrame: Integer; const ATagName: AnsiString;
      out AClampedFrame: Integer): Integer;
  public
    function LerpTag(const AModel: IMd3Model; const AStartFrame, AEndFrame: Integer; const AFraction: Single;
      const ATagName: AnsiString; out ATag: TQ3Orientation): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Patch.VertexMath,
  DelphiDoom.Models.Q3Player.FloatMath;

function TQ3TagLerper.FindTag(const AModel: IMd3Model; const AFrame: Integer; const ATagName: AnsiString;
  out AClampedFrame: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  AClampedFrame := AFrame;
  // it is possible to have a bad frame while changing models, so don't error
  if AClampedFrame >= AModel.NumFrames then
    AClampedFrame := AModel.NumFrames - 1;
  // the original reads before the tags with a negative frame
  if AClampedFrame < 0 then
    raise EQ3PlayerException.CreateAtLine(Format(SQ3BadFrame, [AFrame]), 0);
  for LIndex := 0 to AModel.NumTags - 1 do
    if AModel.Tags[AClampedFrame, LIndex].Name = ATagName then
      Exit(LIndex);
end;

function TQ3TagLerper.LerpTag(const AModel: IMd3Model; const AStartFrame, AEndFrame: Integer;
  const AFraction: Single; const ATagName: AnsiString; out ATag: TQ3Orientation): Boolean;
var
  LStartFrame, LEndFrame, LStartTag, LEndTag, LAxisIndex: Integer;
  LStart, LEnd: TMd3Tag;
  LFrontLerp, LBackLerp, LFirst, LSecond: Single;
  LComponent: Integer;
begin
  Result := False;
  TQ3FloatMath.AxisClear(ATag.Axis);
  ATag.Origin.Zero;
  if not Assigned(AModel) then
    Exit;
  LStartTag := FindTag(AModel, AStartFrame, ATagName, LStartFrame);
  LEndTag := FindTag(AModel, AEndFrame, ATagName, LEndFrame);
  if (LStartTag < 0) or (LEndTag < 0) then
    Exit;
  LStart := AModel.Tags[LStartFrame, LStartTag];
  LEnd := AModel.Tags[LEndFrame, LEndTag];

  LFrontLerp := AFraction;
  LBackLerp := 1.0 - AFraction;

  for LComponent := 0 to 2 do
  begin
    LFirst := LStart.Origin[LComponent] * LBackLerp;
    LSecond := LEnd.Origin[LComponent] * LFrontLerp;
    ATag.Origin[LComponent] := LFirst + LSecond;
    for LAxisIndex := 0 to 2 do
    begin
      LFirst := LStart.Axis[LAxisIndex][LComponent] * LBackLerp;
      LSecond := LEnd.Axis[LAxisIndex][LComponent] * LFrontLerp;
      ATag.Axis[LAxisIndex][LComponent] := LFirst + LSecond;
    end;
  end;
  TPatchVertexMath.Normalize(ATag.Axis[0]);
  TPatchVertexMath.Normalize(ATag.Axis[1]);
  TPatchVertexMath.Normalize(ATag.Axis[2]);
  Result := True;
end;

end.
