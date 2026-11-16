{******************************************************************************}
{                                                                              }
{  DelphiDoom: converts any sound libsndfile reads into a 16 bit WAV file      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SoundConverter;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Turns the content of an OGG, FLAC, VOC, AU, WAV... file into a 16 bit
  ///   PCM WAV file, which is the only sound format the mixer understands
  /// </summary>
  TSoundConverter = class
  public
    /// <summary>
    ///   Raises ESndfileException if the sound cannot be read, or if it has
    ///   no samples
    /// </summary>
    /// <param name="ANormalize">
    ///   Scales the sound so that its loudest sample reaches the full range
    ///   (always done for floating point and Vorbis sounds)
    /// </param>
    class function ToWav(ASource: Pointer; ASourceSize: Cardinal;
      ANormalize: Boolean): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Sndfile.Provider,
  DelphiDoom.Audio.WavBuilder;

{ TSoundConverter }

class function TSoundConverter.ToWav(ASource: Pointer; ASourceSize: Cardinal;
  ANormalize: Boolean): TBytes;
var
  LInfo: TSoundFileInfo;
  LSamples: TArray<SmallInt>;
begin
  LSamples := TSndfileProvider.Client.Decode16(ASource, ASourceSize,
    ANormalize, LInfo);
  if Length(LSamples) = 0 then
    raise ESndfileException.CreateCode(SNDFILE_ERR_MALFORMED_FILE);

  Result := TWavBuilder.Build(LSamples, LInfo.Channels, LInfo.SampleRate);
end;

end.
