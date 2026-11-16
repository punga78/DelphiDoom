{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - volume, separation and pitch of a sound by      }
{  where it is heard from                                                      }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SfxAttenuation;

// The product of two 16.16 numbers keeps the low 32 bits of the shifted
// 64 bit result, as FixedMul does: no overflow or range checks here.
{$Q-}
{$R-}

interface

type
  /// <summary>The angle from the first point to the second (R_PointToAngle2 of the engine)</summary>
  TSfxAngleFunction = function(const AX1: Integer; const AY1: Integer; const AX2: Integer;
    const AY2: Integer): Cardinal;

  /// <summary>The table of the sines of the engine (finesine): 16.16 numbers</summary>
  TSfxSineTable = array[0..8191] of Integer;
  PSfxSineTable = ^TSfxSineTable;

  /// <summary>
  ///   The constants of the rule (S_CLIPPING_DIST, S_CLOSE_DIST, S_ATTENUATOR, NORM_SEP,
  ///   S_STEREO_SWING of s_sound.pas) and the two tables of the engine that it reads. Filled
  ///   once by the engine
  /// </summary>
  TSfxAttenuationRules = record
    /// <summary>16.16: farther than this a sound is not heard</summary>
    ClippingDistance: Integer;
    /// <summary>16.16: nearer than this a sound has the full volume</summary>
    CloseDistance: Integer;
    Attenuator: Integer;
    NormalSeparation: Integer;
    /// <summary>16.16: how far from the centre a sound at one side goes</summary>
    StereoSwing: Integer;
    PointToAngle: TSfxAngleFunction;
    FineSine: PSfxSineTable;
  end;

  /// <summary>
  ///   S_AdjustSoundParams of s_sound.pas and the "hacks to vary the sfx pitches" of
  ///   S_StartSoundAtVolume, without the globals: who listens, where the sound is and the
  ///   volume of the menu are arguments. No state: the engine calls the functions of the
  ///   class for each sound that starts and, once per tic, for each channel that plays
  /// </summary>
  TSfxAttenuation = class sealed
  public
    /// <summary>
    ///   The distance of GG1 p.428 (the longer side plus half of the shorter one), 16.16
    /// </summary>
    class function ApproximateDistance(AListenerX, AListenerY, ASourceX,
      ASourceY: Integer): Integer; static;
    /// <summary>
    ///   Volume and separation of a sound at (ASourceX, ASourceY) for a listener at
    ///   (AListenerX, AListenerY) that looks at AListenerAngle. False if it is not heard: then,
    ///   as in the old code, AVolume and ASeparation may be left as they were (too far) or
    ///   written (volume zero). AFullVolumeLevel is the rule of the level of the last boss
    ///   (map 8 of Doom and Heretic): nothing is too far and the volume never goes under 15
    /// </summary>
    class function Adjust(const ARules: TSfxAttenuationRules; AListenerX, AListenerY: Integer;
      AListenerAngle: Cardinal; ASourceX, ASourceY: Integer; ASfxVolume: Integer;
      AFullVolumeLevel: Boolean; var AVolume: Integer; var ASeparation: Integer): Boolean; static;
    /// <summary>
    ///   APitch moved by a random amount: ARandom is a byte of the generator, AMask (15 or 31)
    ///   says how wide; the result stays in 0..255
    /// </summary>
    class function PerturbPitch(APitch, ARandom, AMask: Integer): Integer; static;
  end;

implementation

const
  FRACUNIT = 1 shl 16;
  ANGLE_TO_FINE_SHIFT = 19;
  FULL_VOLUME_FLOOR = 15;

{ TSfxAttenuation }

class function TSfxAttenuation.ApproximateDistance(AListenerX, AListenerY, ASourceX,
  ASourceY: Integer): Integer;
var
  LDeltaX: Integer;
  LDeltaY: Integer;
  LShorter: Integer;
begin
  LDeltaX := Abs(AListenerX - ASourceX);
  LDeltaY := Abs(AListenerY - ASourceY);
  if LDeltaX < LDeltaY then
    LShorter := LDeltaX
  else
    LShorter := LDeltaY;
  Result := LDeltaX + LDeltaY - LShorter div 2;
end;

class function TSfxAttenuation.Adjust(const ARules: TSfxAttenuationRules; AListenerX,
  AListenerY: Integer; AListenerAngle: Cardinal; ASourceX, ASourceY: Integer;
  ASfxVolume: Integer; AFullVolumeLevel: Boolean; var AVolume: Integer;
  var ASeparation: Integer): Boolean;
var
  LDistance: Integer;
  LAngle: Cardinal;
  LSwing: Integer;
begin
  LDistance := ApproximateDistance(AListenerX, AListenerY, ASourceX, ASourceY);

  // killough 11/98: zero distance is a special case
  if LDistance = 0 then
  begin
    ASeparation := ARules.NormalSeparation;
    AVolume := ASfxVolume;
    Exit(AVolume > 0);
  end;

  if (not AFullVolumeLevel) and (LDistance > ARules.ClippingDistance) then
    Exit(False);

  // angle of the source as the listener sees it
  LAngle := ARules.PointToAngle(AListenerX, AListenerY, ASourceX, ASourceY);
  if LAngle > AListenerAngle then
    LAngle := LAngle - AListenerAngle
  else
    LAngle := LAngle + ($FFFFFFFF - AListenerAngle);
  LAngle := LAngle shr ANGLE_TO_FINE_SHIFT;

  // FixedMul: bits 16..47 of the 64 bit product
  LSwing := Integer(UInt64(Int64(ARules.StereoSwing) * Int64(ARules.FineSine[LAngle])) shr 16);
  ASeparation := ARules.NormalSeparation - (LSwing div FRACUNIT);

  if LDistance < ARules.CloseDistance then
    AVolume := ASfxVolume
  else if AFullVolumeLevel then
  begin
    if LDistance > ARules.ClippingDistance then
      LDistance := ARules.ClippingDistance;
    AVolume := FULL_VOLUME_FLOOR + ((ASfxVolume - FULL_VOLUME_FLOOR) *
      ((ARules.ClippingDistance - LDistance) div FRACUNIT)) div ARules.Attenuator;
  end
  else
    AVolume := (ASfxVolume * ((ARules.ClippingDistance - LDistance) div FRACUNIT)) div
      ARules.Attenuator;

  Result := AVolume > 0;
end;

class function TSfxAttenuation.PerturbPitch(APitch, ARandom, AMask: Integer): Integer;
begin
  Result := APitch + (AMask + 1) div 2 - (ARandom and AMask);
  if Result < 0 then
    Result := 0
  else if Result > 255 then
    Result := 255;
end;

end.
