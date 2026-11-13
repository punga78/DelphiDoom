{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - PCM resampler                                     }
{                                                                              }
{  Port of mv_resample_pcm and mw_resample_pcm (the same code twice) of        }
{  shl/voc.h and shl/wav.h of war1 (acoto87/war1), MIT License, (c) 2026       }
{  Alejandro Coto Gutierrez; war1 is under the zlib License (see Libs\War\     }
{  LICENSE-war1.txt). This is an altered version, not the original.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Resampler;

interface

uses
  System.SysUtils, DelphiDoom.War.Audio.Types;

type
  /// <summary>
  ///   The resampler of the sounds of the game: the strategy TPcmFixedPointResampler of Libs\AudioMix (which holds
  ///   the code), with the errors as EWarException
  /// </summary>
  TWarPcmResampler = class
  public
    /// <summary>
    ///   The samples at ATargetRate. EWarException where the original returns 0 (no samples, rate 0) and for a
    ///   sample format it cannot interpolate (not 8 or 16 bits, no channels), which the original would read as
    ///   a division by zero or leave unwritten
    /// </summary>
    class function Resample(const ASource: TWarPcmBuffer; ATargetRate: Cardinal): TWarPcmBuffer; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.AudioMix.Types, DelphiDoom.AudioMix.FixedPointResampler;

{ TWarPcmResampler }

class function TWarPcmResampler.Resample(const ASource: TWarPcmBuffer; ATargetRate: Cardinal): TWarPcmBuffer;
begin
  try
    Result := TPcmFixedPointResampler.Convert(ASource, ATargetRate);
  except
    on E: EAudioMixException do
      raise EWarException.Create(E.Message);
  end;
end;

end.
