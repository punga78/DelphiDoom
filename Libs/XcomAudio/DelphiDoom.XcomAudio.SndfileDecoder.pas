{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - WAV, OGG Vorbis, FLAC and the other sound   }
{  files as samples of the mixer, on the decoders of Libs\Sound                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.SndfileDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Sndfile.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   IXcomSampleDecoder on an ISndfile (Libs\Sound): the file is opened by its content as SDL_mixer does, read as
  ///   16 bit, mono is played on both sides, more than two channels keep the first two, and the rate becomes the one
  ///   of the mixer (TXcomResampler)
  /// </summary>
  TXcomSndfileDecoder = class(TInterfacedObject, IXcomSampleDecoder)
  strict private
    FEngine: ISndfile;
    class function StartsWith(const AData: TBytes; AOffset: Integer; const ATag: AnsiString): Boolean; static;
  public
    /// <param name="AEngine">The decoder of the sound files; EArgumentNilException when nil</param>
    constructor Create(const AEngine: ISndfile);
    function Accepts(const AData: TBytes): Boolean;
    function TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
  end;

implementation

uses
  DelphiDoom.XcomAudio.Resampler;

constructor TXcomSndfileDecoder.Create(const AEngine: ISndfile);
begin
  inherited Create;
  if not Assigned(AEngine) then
    raise EArgumentNilException.Create('AEngine');
  FEngine := AEngine;
end;

class function TXcomSndfileDecoder.StartsWith(const AData: TBytes; AOffset: Integer; const ATag: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(AData) >= AOffset + Length(ATag);
  if Result then
    for LIndex := 1 to Length(ATag) do
      if AData[AOffset + LIndex - 1] <> Byte(ATag[LIndex]) then
        Exit(False);
end;

function TXcomSndfileDecoder.Accepts(const AData: TBytes): Boolean;
var
  LSkip: Integer;
begin
  // an ID3v2 tag before a FLAC file
  if StartsWith(AData, 0, 'ID3') and (Length(AData) >= 10) then
  begin
    LSkip := 10 +((AData[6] and $7F) shl 21) + ((AData[7] and $7F) shl 14) + ((AData[8] and $7F) shl 7) +
      (AData[9] and $7F);
    Exit(StartsWith(AData, LSkip, 'fLaC'));
  end;
  Result := (StartsWith(AData, 0, 'RIFF') and StartsWith(AData, 8, 'WAVE')) or StartsWith(AData, 0, 'RIFX') or
    StartsWith(AData, 0, 'RF64') or StartsWith(AData, 0, 'OggS') or StartsWith(AData, 0, 'fLaC') or
    (StartsWith(AData, 0, 'FORM') and (StartsWith(AData, 8, 'AIFF') or StartsWith(AData, 8, 'AIFC'))) or
    StartsWith(AData, 0, '.snd');
end;

function TXcomSndfileDecoder.TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
var
  LFile: ISoundFile;
  LInfo: TSoundFileInfo;
  LRaw: TArray<SmallInt>;
  LRead: Int64;
  LFrame: Integer;
  LChannel: Integer;
begin
  ASamples := nil;
  Result := False;
  if (Length(AData) = 0) or (ARate <= 0) then
    Exit;
  if FEngine.OpenMemory(@AData[0], Cardinal(Length(AData)), LFile) <> SNDFILE_OK then
    Exit;
  if (LFile.GetInfo(LInfo) <> SNDFILE_OK) or (LInfo.Channels < 1) or (LInfo.SampleRate <= 0) or (LInfo.Frames < 0) then
    Exit;
  SetLength(LRaw, Integer(LInfo.Frames) * LInfo.Channels);
  LRead := 0;
  if Length(LRaw) > 0 then
    if LFile.ReadShort(@LRaw[0], LInfo.Frames, LRead) <> SNDFILE_OK then
      Exit;
  SetLength(ASamples, Integer(LRead) * 2);
  for LFrame := 0 to Integer(LRead) - 1 do
  begin
    ASamples[LFrame * 2] := LRaw[LFrame * LInfo.Channels];
    if LInfo.Channels > 1 then
      LChannel := 1
    else
      LChannel := 0;
    ASamples[LFrame * 2 + 1] := LRaw[LFrame * LInfo.Channels + LChannel];
  end;
  ASamples := TXcomResampler.Convert(ASamples, LInfo.SampleRate, ARate);
  Result := True;
end;

end.
