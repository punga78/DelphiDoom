{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - the effects of the four formats, in one set           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Effects;

interface

uses
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   What an effect does, whatever the format: MOD, S3M, XM and IT write
  ///   the same things with different codes
  /// </summary>
  TTrackerEffectKind = (
    ekNone,
    ekArpeggio,
    ekPortamentoUp,
    ekPortamentoDown,
    ekTonePortamento,
    ekVibrato,
    ekTonePortamentoVolumeSlide,
    ekVibratoVolumeSlide,
    ekTremolo,
    ekSetPanning,
    ekSampleOffset,
    ekVolumeSlide,
    ekSetVolume,
    ekFinePortamentoUp,
    ekFinePortamentoDown,
    ekExtraFinePortamentoUp,
    ekExtraFinePortamentoDown,
    ekFineVolumeSlideUp,
    ekFineVolumeSlideDown,
    ekRetrigger,
    ekNoteCut,
    ekNoteDelay,
    ekKeyOff,
    ekSetGlobalVolume,
    // Song flow, done by the player
    ekPositionJump,
    ekPatternBreak,
    ekSetSpeed,
    ekSetTempo,
    ekPatternLoop,
    ekPatternDelay);

  /// <summary>An effect, as the executors understand it</summary>
  TTrackerEffect = record
    Kind: TTrackerEffectKind;
    /// <summary>
    ///   The parameter of the effect. For the pattern break it is the row
    ///   (the decimal digits of MOD, S3M and XM are already converted); for
    ///   the extended effects (E, S) it is the value of the low nibble
    /// </summary>
    Param: Byte;
  end;

  /// <summary>
  ///   Translates the effect and parameter of a cell, and its volume column,
  ///   to the common set
  /// </summary>
  TTrackerEffectMapper = class
  private
    class function FromProTracker(const AEffect, AParam: Byte;
      const AIsXm: Boolean): TTrackerEffect; static;
    class function FromScreamTracker(const AEffect, AParam: Byte;
      const AIsImpulse: Boolean): TTrackerEffect; static;
    class function Make(const AKind: TTrackerEffectKind; const AParam: Byte): TTrackerEffect; static;
    class function DecimalRow(const AParam: Byte): Byte; static;
  public
    /// <summary>The effect of a cell</summary>
    class function Map(const AFormat: TTrackerFormat; const AEffect, AParam: Byte): TTrackerEffect; static;

    /// <summary>
    ///   The effect that the volume column of a cell asks for (a set volume
    ///   is also an effect here); ekNone if the column is empty or has a
    ///   command that is not supported
    /// </summary>
    class function MapVolumeColumn(const AFormat: TTrackerFormat;
      const AVolume: Integer): TTrackerEffect; static;
  end;

implementation

uses
  System.Math;

const
  // Letters of S3M and IT (A = 1)
  LETTER_A = 1;
  LETTER_B = 2;
  LETTER_C = 3;
  LETTER_D = 4;
  LETTER_E = 5;
  LETTER_F = 6;
  LETTER_G = 7;
  LETTER_H = 8;
  LETTER_J = 10;
  LETTER_K = 11;
  LETTER_L = 12;
  LETTER_O = 15;
  LETTER_Q = 17;
  LETTER_R = 18;
  LETTER_S = 19;
  LETTER_T = 20;
  LETTER_V = 22;
  LETTER_X = 24;

  // Numbers of the XM effects that are not hexadecimal digits
  XM_SET_GLOBAL_VOLUME = 16;
  XM_GLOBAL_VOLUME_SLIDE = 17;
  XM_KEY_OFF = 20;
  XM_EXTRA_FINE = 33;

{ TTrackerEffectMapper }

class function TTrackerEffectMapper.Make(const AKind: TTrackerEffectKind;
  const AParam: Byte): TTrackerEffect;
begin
  Result.Kind := AKind;
  Result.Param := AParam;
end;

class function TTrackerEffectMapper.DecimalRow(const AParam: Byte): Byte;
begin
  Result := (AParam shr 4) * 10 + (AParam and $0F);
end;

class function TTrackerEffectMapper.FromProTracker(const AEffect, AParam: Byte;
  const AIsXm: Boolean): TTrackerEffect;
var
  LLow: Byte;
begin
  LLow := AParam and $0F;
  case AEffect of
    $0:
      if AParam <> 0 then
        Result := Make(ekArpeggio, AParam)
      else
        Result := Make(ekNone, 0);
    $1: Result := Make(ekPortamentoUp, AParam);
    $2: Result := Make(ekPortamentoDown, AParam);
    $3: Result := Make(ekTonePortamento, AParam);
    $4: Result := Make(ekVibrato, AParam);
    $5: Result := Make(ekTonePortamentoVolumeSlide, AParam);
    $6: Result := Make(ekVibratoVolumeSlide, AParam);
    $7: Result := Make(ekTremolo, AParam);
    $8: Result := Make(ekSetPanning, AParam);
    $9: Result := Make(ekSampleOffset, AParam);
    $A: Result := Make(ekVolumeSlide, AParam);
    $B: Result := Make(ekPositionJump, AParam);
    $C: Result := Make(ekSetVolume, AParam);
    $D: Result := Make(ekPatternBreak, DecimalRow(AParam));
    $E:
      case AParam shr 4 of
        $1: Result := Make(ekFinePortamentoUp, LLow);
        $2: Result := Make(ekFinePortamentoDown, LLow);
        $6: Result := Make(ekPatternLoop, LLow);
        $8: Result := Make(ekSetPanning, LLow * 17);
        $9: Result := Make(ekRetrigger, LLow);
        $A: Result := Make(ekFineVolumeSlideUp, LLow);
        $B: Result := Make(ekFineVolumeSlideDown, LLow);
        $C: Result := Make(ekNoteCut, LLow);
        $D: Result := Make(ekNoteDelay, LLow);
        $E: Result := Make(ekPatternDelay, LLow);
      else
        Result := Make(ekNone, 0);
      end;
    $F:
      if AParam = 0 then
        Result := Make(ekNone, 0)
      else if AParam < 32 then
        Result := Make(ekSetSpeed, AParam)
      else
        Result := Make(ekSetTempo, AParam);
  else
    Result := Make(ekNone, 0);
  end;

  if AIsXm and (Result.Kind = ekNone) then
  begin
    case AEffect of
      XM_SET_GLOBAL_VOLUME: Result := Make(ekSetGlobalVolume, Min(AParam, 64));
      XM_KEY_OFF: Result := Make(ekKeyOff, AParam);
      XM_EXTRA_FINE:
        case AParam shr 4 of
          $1: Result := Make(ekExtraFinePortamentoUp, LLow);
          $2: Result := Make(ekExtraFinePortamentoDown, LLow);
        end;
    end;
  end;
end;

class function TTrackerEffectMapper.FromScreamTracker(const AEffect, AParam: Byte;
  const AIsImpulse: Boolean): TTrackerEffect;
var
  LLow: Byte;
begin
  LLow := AParam and $0F;
  case AEffect of
    LETTER_A:
      if AParam > 0 then
        Result := Make(ekSetSpeed, AParam)
      else
        Result := Make(ekNone, 0);
    LETTER_B: Result := Make(ekPositionJump, AParam);
    LETTER_C:
      // S3M writes the row in decimal digits, IT in binary
      if AIsImpulse then
        Result := Make(ekPatternBreak, AParam)
      else
        Result := Make(ekPatternBreak, DecimalRow(AParam));
    LETTER_D: Result := Make(ekVolumeSlide, AParam);
    LETTER_E: Result := Make(ekPortamentoDown, AParam);
    LETTER_F: Result := Make(ekPortamentoUp, AParam);
    LETTER_G: Result := Make(ekTonePortamento, AParam);
    LETTER_H: Result := Make(ekVibrato, AParam);
    LETTER_J: Result := Make(ekArpeggio, AParam);
    LETTER_K: Result := Make(ekVibratoVolumeSlide, AParam);
    LETTER_L: Result := Make(ekTonePortamentoVolumeSlide, AParam);
    LETTER_O: Result := Make(ekSampleOffset, AParam);
    LETTER_Q: Result := Make(ekRetrigger, AParam);
    LETTER_R: Result := Make(ekTremolo, AParam);
    LETTER_S:
      case AParam shr 4 of
        $8: Result := Make(ekSetPanning, LLow * 17);
        $B: Result := Make(ekPatternLoop, LLow);
        $C: Result := Make(ekNoteCut, LLow);
        $D: Result := Make(ekNoteDelay, LLow);
        $E: Result := Make(ekPatternDelay, LLow);
      else
        Result := Make(ekNone, 0);
      end;
    LETTER_T:
      if AParam >= 32 then
        Result := Make(ekSetTempo, AParam)
      else
        Result := Make(ekNone, 0);
    LETTER_V: Result := Make(ekSetGlobalVolume, Min(AParam, 128));
    LETTER_X:
      if AIsImpulse then
        Result := Make(ekSetPanning, AParam)
      else
        Result := Make(ekNone, 0);
  else
    Result := Make(ekNone, 0);
  end;
end;

class function TTrackerEffectMapper.Map(const AFormat: TTrackerFormat; const AEffect,
  AParam: Byte): TTrackerEffect;
begin
  case AFormat of
    tfMod: Result := FromProTracker(AEffect, AParam, False);
    tfXm: Result := FromProTracker(AEffect, AParam, True);
    tfS3m: Result := FromScreamTracker(AEffect, AParam, False);
    tfIt: Result := FromScreamTracker(AEffect, AParam, True);
  else
    Result := Make(ekNone, 0);
  end;
end;

class function TTrackerEffectMapper.MapVolumeColumn(const AFormat: TTrackerFormat;
  const AVolume: Integer): TTrackerEffect;
begin
  Result := Make(ekNone, 0);
  if AVolume < 0 then
    Exit;

  case AFormat of
    tfS3m:
      if AVolume <= 64 then
        Result := Make(ekSetVolume, AVolume);
    tfXm:
      case AVolume of
        $10..$50: Result := Make(ekSetVolume, AVolume - $10);
        $60..$6F: Result := Make(ekVolumeSlide, AVolume and $0F);
        $70..$7F: Result := Make(ekVolumeSlide, (AVolume and $0F) shl 4);
        $80..$8F: Result := Make(ekFineVolumeSlideDown, AVolume and $0F);
        $90..$9F: Result := Make(ekFineVolumeSlideUp, AVolume and $0F);
        $C0..$CF: Result := Make(ekSetPanning, (AVolume and $0F) * 17);
        $F0..$FF: Result := Make(ekTonePortamento, (AVolume and $0F) shl 4);
      end;
    tfIt:
      case AVolume of
        0..64: Result := Make(ekSetVolume, AVolume);
        65..74: Result := Make(ekFineVolumeSlideUp, AVolume - 65);
        75..84: Result := Make(ekFineVolumeSlideDown, AVolume - 75);
        85..94: Result := Make(ekVolumeSlide, (AVolume - 85) shl 4);
        95..104: Result := Make(ekVolumeSlide, AVolume - 95);
        105..114: Result := Make(ekPortamentoDown, (AVolume - 105) * 4);
        115..124: Result := Make(ekPortamentoUp, (AVolume - 115) * 4);
        128..192: Result := Make(ekSetPanning, Min((AVolume - 128) * 4, 255));
        193..202: Result := Make(ekTonePortamento, (AVolume - 193) * 4);
      end;
  end;
end;

end.
