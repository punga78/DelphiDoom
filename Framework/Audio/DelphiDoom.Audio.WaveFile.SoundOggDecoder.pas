{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the OGG decoder of a wave file on Framework\Sound }
{                                                                              }
{  Written for this repository (GPL v2 or later). Not a second Vorbis reader:  }
{  it asks the one of Framework\Sound (TOggFormat).                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.WaveFile.SoundOggDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Audio.WaveFile.Intf;

type
  /// <summary>
  ///   <c>IWaveOggDecoder</c> on the Ogg Vorbis decoder of <c>Framework\Sound</c>: the decoded samples as 16-bit little
  ///   endian bytes, the way <c>ov_read</c> is called by <c>ReadOGG</c> (little endian, 2 bytes, signed)
  /// </summary>
  TWaveSoundOggDecoder = class(TInterfacedObject, IWaveOggDecoder)
  public
    function TryDecode(const AData: TBytes; out AChannels: Integer; out ASamplesPerSecond: Cardinal;
      out APcm: TBytes): Boolean;
  end;

implementation

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Samples, DelphiDoom.Sound.Format, DelphiDoom.Sound.Format.Ogg, DelphiDoom.Sound.SoundFile;

{ TWaveSoundOggDecoder }

function TWaveSoundOggDecoder.TryDecode(const AData: TBytes; out AChannels: Integer;
  out ASamplesPerSecond: Cardinal; out APcm: TBytes): Boolean;
var
  LFormat: ISoundFormat;
  LSamples: TSoundSamples;
  LFile: ISoundFile;
  LInfo: TSoundFileInfo;
  LRead: Int64;
begin
  Result := False;
  APcm := nil;
  AChannels := 0;
  ASamplesPerSecond := 0;
  LFormat := TOggFormat.Create;
  if LFormat.Decode(AData, LSamples) <> SNDFILE_OK then
    Exit;
  // the file takes the samples
  LFile := TSoundFile.Create(LSamples);
  if LFile.GetInfo(LInfo) <> SNDFILE_OK then
    Exit;
  if (LInfo.Channels < 1) or (LInfo.Frames < 0) or (LInfo.Frames * LInfo.Channels > 256 * 1024 * 1024) then
    Exit;
  SetLength(APcm, Integer(LInfo.Frames) * LInfo.Channels * SizeOf(SmallInt));
  LRead := 0;
  if Length(APcm) > 0 then
    if LFile.ReadShort(@APcm[0], LInfo.Frames, LRead) <> SNDFILE_OK then
      Exit;
  SetLength(APcm, Integer(LRead) * LInfo.Channels * SizeOf(SmallInt));
  AChannels := LInfo.Channels;
  ASamplesPerSecond := Cardinal(LInfo.SampleRate);
  Result := True;
end;

end.
