{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - pan and volume of an effect by its distance      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): modplay.pas                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SoundGeometry;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Types;

const
  /// <summary>MAXSOUNDDIST: the squared distance, in tiles, over which an effect is not heard</summary>
  GREED_MAX_SOUND_DISTANCE = 384;

type
  /// <summary>
  ///   The formulas of SoundEffect and UpdateChannelParams. The wraparound of the fixed point products is
  ///   wanted, as in the original
  /// </summary>
  TGreedSoundGeometry = class
  public
    /// <summary>False when the source is too far to be played at all (the test of SoundEffect: z >= 384)</summary>
    class function IsInRange(ADeltaX, ADeltaY: TGreedFixed): Boolean; static;
    /// <summary>The pan of the original as an integer -64..64 (the channel gets it divided by 64)</summary>
    class function PanUnits(ADeltaX, ADeltaY: TGreedFixed; AListenerAngle: Integer): Integer; static;
    /// <summary>The pan for the device, -1.0 .. 1.0</summary>
    class function Pan(ADeltaX, ADeltaY: TGreedFixed; AListenerAngle: Integer): Single; static;
    /// <summary>(384 - d) / 384 * sfxvol / 255, with d the squared distance in tiles clamped to 384</summary>
    class function Volume(ADeltaX, ADeltaY: TGreedFixed; ASfxVolume: Integer): Single; static;
  end;

implementation

uses
  DelphiDoom.Greed.FixedMath, DelphiDoom.Greed.TrigTables;

const
  MAX_SOUND_DISTANCE_FIXED = GREED_MAX_SOUND_DISTANCE * GREED_FRACUNIT;

{ TGreedSoundGeometry }

class function TGreedSoundGeometry.IsInRange(ADeltaX, ADeltaY: TGreedFixed): Boolean;
var
  LX, LY: Integer;
begin
  LX := ADeltaX div GREED_FRACTILEUNIT;
  LY := ADeltaY div GREED_FRACTILEUNIT;
  Result := LX * LX + LY * LY < GREED_MAX_SOUND_DISTANCE;
end;

class function TGreedSoundGeometry.PanUnits(ADeltaX, ADeltaY: TGreedFixed; AListenerAngle: Integer): Integer;
begin
  Result := TGreedFixedMath.Mul(ADeltaX, TGreedTrigTables.Cosine(AListenerAngle)) +
    TGreedFixedMath.Mul(ADeltaY, TGreedTrigTables.Sine(AListenerAngle));
  Result := TGreedFixedMath.Divide(Result, MAX_SOUND_DISTANCE_FIXED) * $40;
  Result := Result div GREED_FRACUNIT;
  if Result < -64 then
    Result := -64
  else if Result > 64 then
    Result := 64;
end;

class function TGreedSoundGeometry.Pan(ADeltaX, ADeltaY: TGreedFixed; AListenerAngle: Integer): Single;
begin
  Result := PanUnits(ADeltaX, ADeltaY, AListenerAngle) / 64;
end;

class function TGreedSoundGeometry.Volume(ADeltaX, ADeltaY: TGreedFixed; ASfxVolume: Integer): Single;
var
  LX, LY, LDistance: Integer;
begin
  LX := ADeltaX div GREED_FRACTILEUNIT;
  LY := ADeltaY div GREED_FRACTILEUNIT;
  LDistance := LX * LX + LY * LY;
  if LDistance > GREED_MAX_SOUND_DISTANCE then
    LDistance := GREED_MAX_SOUND_DISTANCE;
  Result := (GREED_MAX_SOUND_DISTANCE - LDistance) / GREED_MAX_SOUND_DISTANCE * ASfxVolume / 255;
end;

end.
