{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - Quake III sound, listener and spatialization    }
{  Based on the Quake III Arena GPL Source Code (id Software)                  }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Q3.Listener;

interface

uses
  DelphiDoom.Audio.Q3.Types;

type
  /// <summary>
  ///   The listener of the sound system (listener_number, listener_origin, listener_axis)
  ///   and S_SpatializeOrigin: left and right volume of a sound from its position
  /// </summary>
  /// <remarks>
  ///   Every float operation is rounded on its own and the double ones of the C (the
  ///   literals 0.5 and 1.0) are kept in Double, so the integer volumes are the ones of
  ///   the C compiled with SSE
  /// </remarks>
  TQ3Listener = class
  strict private
    FNumber: Integer;
    FOrigin: TQ3Vec3;
    FAxis: TQ3Axis;
  public
    constructor Create;
    /// <summary>The part of S_Respatialize that moves the listener</summary>
    procedure Place(AEntityNumber: Integer; const AOrigin: TQ3Vec3; const AAxis: TQ3Axis);
    /// <summary>
    ///   S_SpatializeOrigin. ADmaChannels is dma.channels: with 1 there is no
    ///   spatialization (both sides at the master volume, attenuated by distance)
    /// </summary>
    procedure SpatializeOrigin(const AOrigin: TQ3Vec3; AMasterVolume, ADmaChannels: Integer;
      out ALeftVolume, ARightVolume: Integer);
    property Number: Integer read FNumber;
    property Origin: TQ3Vec3 read FOrigin;
    property Axis: TQ3Axis read FAxis;
  end;

implementation

{$Q-}
{$R-}

{ TQ3Listener }

constructor TQ3Listener.Create;
begin
  inherited Create;
  FillChar(FOrigin, SizeOf(FOrigin), 0);
  FillChar(FAxis, SizeOf(FAxis), 0);
end;

procedure TQ3Listener.Place(AEntityNumber: Integer; const AOrigin: TQ3Vec3;
  const AAxis: TQ3Axis);
begin
  if (AEntityNumber < 0) or (AEntityNumber >= Q3_MAX_GENTITIES) then
    raise EQ3SoundException.CreateFmt(SQ3BadEntityNumber, [AEntityNumber]);
  FNumber := AEntityNumber;
  FOrigin := AOrigin;
  FAxis := AAxis;
end;

procedure TQ3Listener.SpatializeOrigin(const AOrigin: TQ3Vec3; AMasterVolume,
  ADmaChannels: Integer; out ALeftVolume, ARightVolume: Integer);
var
  LSource, LRotated: TQ3Vec3;
  LDistance, LRight, LLeft, LScale, LDot, LLength, LInverse, LTerm: Single;
  LProduct, LFactor: Double;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
    LSource[LIndex] := AOrigin[LIndex] - FOrigin[LIndex];

  // VectorNormalize: the length is summed in float, the root is the double sqrt
  LLength := LSource[0] * LSource[0];
  LTerm := LSource[1] * LSource[1];
  LLength := LLength + LTerm;
  LTerm := LSource[2] * LSource[2];
  LLength := LLength + LTerm;
  LLength := Single(Sqrt(Double(LLength)));
  if LLength <> 0 then
  begin
    LInverse := Single(1) / LLength;
    for LIndex := 0 to 2 do
      LSource[LIndex] := LSource[LIndex] * LInverse;
  end;
  LDistance := LLength;
  LDistance := LDistance - Q3_SOUND_FULLVOLUME;
  if LDistance < 0 then
    LDistance := 0;
  LDistance := LDistance * Q3_SOUND_ATTENUATE;

  // VectorRotate: only the second component is used
  LRotated[1] := LSource[0] * FAxis[1][0];
  LTerm := LSource[1] * FAxis[1][1];
  LRotated[1] := LRotated[1] + LTerm;
  LTerm := LSource[2] * FAxis[1][2];
  LRotated[1] := LRotated[1] + LTerm;
  LDot := -LRotated[1];

  if ADmaChannels = 1 then
  begin
    LRight := 1;
    LLeft := 1;
  end
  else
  begin
    LProduct := 1.0 + Double(LDot);
    LProduct := 0.5 * LProduct;
    LRight := Single(LProduct);
    LProduct := 1.0 - Double(LDot);
    LProduct := 0.5 * LProduct;
    LLeft := Single(LProduct);
    if LRight < 0 then
      LRight := 0;
    if LLeft < 0 then
      LLeft := 0;
  end;

  LFactor := 1.0 - Double(LDistance);
  LProduct := LFactor * Double(LRight);
  LScale := Single(LProduct);
  LTerm := Single(AMasterVolume) * LScale;
  ARightVolume := TQ3Math.TruncToInt(LTerm);
  if ARightVolume < 0 then
    ARightVolume := 0;

  LProduct := LFactor * Double(LLeft);
  LScale := Single(LProduct);
  LTerm := Single(AMasterVolume) * LScale;
  ALeftVolume := TQ3Math.TruncToInt(LTerm);
  if ALeftVolume < 0 then
    ALeftVolume := 0;
end;

end.
