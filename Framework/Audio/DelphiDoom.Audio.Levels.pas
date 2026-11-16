{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - volume and pan of the game to those of the device }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.Levels;

interface

type
  TSfxLevels = class
  public
    /// <summary>Separation 0..255 (128 is the centre) to a pan of the device</summary>
    class function SeparationToPan(ASeparation: Integer): Integer; static;
    /// <summary>Volume 0..15 to a volume of the device</summary>
    class function VolumeToAttenuation(AVolume: Integer): Integer; static;
  end;

implementation

uses
  DelphiDoom.Audio.Types;

const
  VOLUME_CURVE: array[0..15] of Integer = (
      0,  96, 128, 168, 186, 200, 212, 222,
    230, 237, 243, 248, 250, 252, 254, 255
  );
  VOLUME_CURVE_SHIFT = 8;

{ TSfxLevels }

class function TSfxLevels.SeparationToPan(ASeparation: Integer): Integer;
begin
  Result := AUDIO_PAN_CENTER +
    (AUDIO_PAN_RIGHT - AUDIO_PAN_LEFT) * (ASeparation * ASeparation - 128 * 128) div
      (16 * 128 * 128);
end;

class function TSfxLevels.VolumeToAttenuation(AVolume: Integer): Integer;
begin
  Result := AUDIO_VOLUME_MIN +
    ((AUDIO_VOLUME_MAX - AUDIO_VOLUME_MIN) * (VOLUME_CURVE[AVolume] + 1)) shr VOLUME_CURVE_SHIFT;
end;

end.
