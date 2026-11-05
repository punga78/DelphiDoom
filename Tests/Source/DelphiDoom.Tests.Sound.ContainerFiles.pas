{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the sound decoder - builds AU and VOC files in memory  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Sound.ContainerFiles;

interface

uses
  System.SysUtils;

type
  TSoundTestAuOptions = record
    BigEndian: Boolean;
    /// <summary>Code of the encoding in the header (1 mu-law, 2..5 PCM, 6 float, 7 double, 27 A-law)</summary>
    Encoding: Cardinal;
    Channels: Cardinal;
    SampleRate: Cardinal;
    /// <summary>Zero bytes between the 24 byte header and the data</summary>
    Padding: Integer;
    /// <summary>Size written in the header; -2 for the real one</summary>
    DataSize: Int64;
    class function Plain(AEncoding, AChannels: Cardinal): TSoundTestAuOptions; static;
  end;

  TSoundTestVocOptions = record
    /// <summary>Block 8 before the sound (stereo or not, a rate of its own)</summary>
    Extended: Boolean;
    Stereo: Boolean;
    /// <summary>Block 9 instead of block 1: with this encoding, bits and channels</summary>
    ExtendedII: Boolean;
    Encoding: Word;
    BitsPerSample: Byte;
    Channels: Byte;
    TextBlockFirst: Boolean;
    OmitTerminator: Boolean;
    Version: Word;
    class function Plain: TSoundTestVocOptions; static;
  end;

  TSoundTestContainerFile = class
  public
    class function BuildAu(const AOptions: TSoundTestAuOptions;
      const APayload: TBytes): TBytes; static;
    class function BuildVoc(const AOptions: TSoundTestVocOptions;
      const APayload: TBytes): TBytes; static;
  end;

implementation

type
  TSink = record
    Bytes: TBytes;
    procedure Add(AValue: Byte);
    procedure AddText(const AText: AnsiString);
    procedure AddNumber(AValue: Cardinal; AByteCount: Integer; ABigEndian: Boolean);
    procedure AddBytes(const AValues: TBytes);
  end;

{ TSink }

procedure TSink.Add(AValue: Byte);
begin
  SetLength(Bytes, Length(Bytes) + 1);
  Bytes[High(Bytes)] := AValue;
end;

procedure TSink.AddText(const AText: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 1 to Length(AText) do
    Add(Byte(AText[LIndex]));
end;

procedure TSink.AddNumber(AValue: Cardinal; AByteCount: Integer;
  ABigEndian: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AByteCount - 1 do
    if ABigEndian then
      Add(Byte(AValue shr (8 * (AByteCount - 1 - LIndex))))
    else
      Add(Byte(AValue shr (8 * LIndex)));
end;

procedure TSink.AddBytes(const AValues: TBytes);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AValues) do
    Add(AValues[LIndex]);
end;

{ TSoundTestAuOptions }

class function TSoundTestAuOptions.Plain(AEncoding,
  AChannels: Cardinal): TSoundTestAuOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Encoding := AEncoding;
  Result.Channels := AChannels;
  Result.SampleRate := 8000;
  Result.DataSize := -2;
end;

{ TSoundTestVocOptions }

class function TSoundTestVocOptions.Plain: TSoundTestVocOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Version := $010A;
  Result.Channels := 1;
  Result.BitsPerSample := 8;
end;

{ TSoundTestContainerFile }

class function TSoundTestContainerFile.BuildAu(const AOptions: TSoundTestAuOptions;
  const APayload: TBytes): TBytes;
var
  LSink: TSink;
  LSize: Cardinal;
  LIndex: Integer;
begin
  if AOptions.BigEndian then
    LSink.AddText('.snd')
  else
    LSink.AddText('dns.');
  LSink.AddNumber(Cardinal(24 + AOptions.Padding), 4, AOptions.BigEndian);
  if AOptions.DataSize = -2 then
    LSize := Cardinal(Length(APayload))
  else
    LSize := Cardinal(AOptions.DataSize);
  LSink.AddNumber(LSize, 4, AOptions.BigEndian);
  LSink.AddNumber(AOptions.Encoding, 4, AOptions.BigEndian);
  LSink.AddNumber(AOptions.SampleRate, 4, AOptions.BigEndian);
  LSink.AddNumber(AOptions.Channels, 4, AOptions.BigEndian);
  for LIndex := 1 to AOptions.Padding do
    LSink.Add(0);
  LSink.AddBytes(APayload);
  Result := LSink.Bytes;
end;

class function TSoundTestContainerFile.BuildVoc(const AOptions: TSoundTestVocOptions;
  const APayload: TBytes): TBytes;
var
  LSink: TSink;
begin
  LSink.AddText('Creative Voice File');
  LSink.Add($1A);
  LSink.AddNumber(26, 2, False);
  LSink.AddNumber(AOptions.Version, 2, False);
  LSink.AddNumber($1234 + (not AOptions.Version and $FFFF), 2, False);

  if AOptions.TextBlockFirst then
  begin
    LSink.Add(5);
    LSink.AddNumber(6, 3, False);
    LSink.AddText('hello!');
  end;

  if AOptions.ExtendedII then
  begin
    LSink.Add(9);
    LSink.AddNumber(Cardinal(Length(APayload) + 12), 3, False);
    LSink.AddNumber(22050, 4, False);
    LSink.Add(AOptions.BitsPerSample);
    LSink.Add(AOptions.Channels);
    LSink.AddNumber(AOptions.Encoding, 2, False);
    LSink.AddNumber(0, 4, False);
  end
  else
  begin
    if AOptions.Extended then
    begin
      LSink.Add(8);
      LSink.AddNumber(4, 3, False);
      LSink.AddNumber(65536 - 1000000 div 11025 * 2 div 2, 2, False);
      LSink.Add(0);
      if AOptions.Stereo then
        LSink.Add(1)
      else
        LSink.Add(0);
    end;
    LSink.Add(1);
    LSink.AddNumber(Cardinal(Length(APayload) + 2), 3, False);
    LSink.Add(206);                                          // 1000000 / (256 - 206)
    LSink.Add(0);
  end;

  LSink.AddBytes(APayload);
  if not AOptions.OmitTerminator then
    LSink.Add(0);
  Result := LSink.Bytes;
end;

end.
