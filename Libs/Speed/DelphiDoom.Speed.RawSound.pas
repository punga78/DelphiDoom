{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedRawSound                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of SH_RawToWAV (speed_sounds.pas)                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.RawSound;

// the samples wrap around the byte, as they did
{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils;

const
  /// <summary>One in the fixed point of the engine (the volume of a sound)</summary>
  SPEED_FRACUNIT = 65536;
  WAV_HEADER_SIZE = 44;

type
  /// <summary>The sounds of the game are samples of one byte, without a header</summary>
  TSpeedRawSound = class
  public
    /// <summary>
    ///   A WAV file of one channel and 8 bits: the 44 bytes of the header (the size of the RIFF is the
    ///   size of the file, as the old code wrote it) and the samples, each multiplied by AVolume
    ///   (16.16) and moved by 128
    /// </summary>
    class function ToWav(const ARaw: TBytes; AHertz, AVolume: Integer): TBytes; static;
  end;

implementation

{ TSpeedRawSound }

class function TSpeedRawSound.ToWav(const ARaw: TBytes; AHertz, AVolume: Integer): TBytes;
var
  LHeader: array[0..10] of Cardinal;
  LIndex: Integer;
  LSample: Integer;
begin
  SetLength(Result, Length(ARaw) + WAV_HEADER_SIZE);
  LHeader[0] := $46464952; // RIFF
  LHeader[1] := Cardinal(Length(Result));
  LHeader[2] := $45564157; // WAVE
  LHeader[3] := $20746D66; // fmt_
  LHeader[4] := $00000010;
  LHeader[5] := $00010001;
  LHeader[6] := Cardinal(AHertz);
  LHeader[7] := Cardinal(AHertz);
  LHeader[8] := $00080001;
  LHeader[9] := $61746164; // data
  LHeader[10] := Cardinal(Length(ARaw));
  Move(LHeader[0], Result[0], WAV_HEADER_SIZE);
  for LIndex := 0 to High(ARaw) do
  begin
    LSample := ARaw[LIndex];
    LSample := (LSample * AVolume) div SPEED_FRACUNIT;
    Result[WAV_HEADER_SIZE + LIndex] := Byte(128 + LSample);
  end;
end;

end.
