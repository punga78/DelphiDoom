{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - MP3 files as samples of the mixer, on the   }
{  decoder of Libs\Mp3                                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.Mp3Decoder;

interface

uses
  System.SysUtils, DelphiDoom.Mp3.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   IXcomSampleDecoder on an IMp3 (Libs\Mp3): a file with an ID3 tag or with the sync of a layer III frame is
  ///   decoded whole to 16 bit stereo at the rate of the mixer
  /// </summary>
  TXcomMp3Decoder = class(TInterfacedObject, IXcomSampleDecoder)
  strict private
    FMp3: IMp3;
  public
    /// <param name="AMp3">The factory of decoders; EArgumentNilException when nil</param>
    constructor Create(const AMp3: IMp3);
    function Accepts(const AData: TBytes): Boolean;
    function TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
  end;

implementation

uses
  DelphiDoom.Mp3.Client, DelphiDoom.XcomAudio.Resampler;

constructor TXcomMp3Decoder.Create(const AMp3: IMp3);
begin
  inherited Create;
  if not Assigned(AMp3) then
    raise EArgumentNilException.Create('AMp3');
  FMp3 := AMp3;
end;

function TXcomMp3Decoder.Accepts(const AData: TBytes): Boolean;
begin
  if Length(AData) < 4 then
    Exit(False);
  if (AData[0] = Ord('I')) and (AData[1] = Ord('D')) and (AData[2] = Ord('3')) then
    Exit(True);
  // sync of 11 bits, a version that is not reserved, layer III
  Result := (AData[0] = $FF) and ((AData[1] and $E0) = $E0) and ((AData[1] and $18) <> $08) and
    ((AData[1] and $06) = $02);
end;

function TXcomMp3Decoder.TryDecode(const AData: TBytes; ARate: Integer; out ASamples: TArray<SmallInt>): Boolean;
var
  LClient: TMp3Client;
  LPcm: TBytes;
  LRaw: TArray<SmallInt>;
  LChannels: Integer;
  LFrequency: Integer;
  LFrames: Integer;
  LFrame: Integer;
begin
  ASamples := nil;
  Result := False;
  if (Length(AData) = 0) or (ARate <= 0) then
    Exit;
  try
    LClient := TMp3Client.Create(FMp3);
    try
      LPcm := LClient.DecodeAll(AData);
      LChannels := Integer(LClient.Channels);
      LFrequency := Integer(LClient.Frequency);
    finally
      LClient.Free;
    end;
  except
    on EMp3Exception do
      Exit;
  end;
  if (LChannels < 1) or (LChannels > 2) or (LFrequency <= 0) or (Length(LPcm) < 2 * LChannels) then
    Exit;
  LFrames := Length(LPcm) div (2 * LChannels);
  SetLength(LRaw, LFrames * LChannels);
  Move(LPcm[0], LRaw[0], Length(LRaw) * 2);
  SetLength(ASamples, LFrames * 2);
  for LFrame := 0 to LFrames - 1 do
  begin
    ASamples[LFrame * 2] := LRaw[LFrame * LChannels];
    ASamples[LFrame * 2 + 1] := LRaw[LFrame * LChannels + LChannels - 1];
  end;
  ASamples := TXcomResampler.Convert(ASamples, LFrequency, ARate);
  Result := True;
end;

end.
