{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TWavBuilder                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.WavBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('audio')]
  TTestWavBuilder = class(TObject)
  private
    function WordAt(const AWav: TBytes; AOffset: Integer): Integer;
    function CardinalAt(const AWav: TBytes; AOffset: Integer): Cardinal;
    procedure BuildWithoutChannels;
    procedure BuildWithoutSampleRate;
  public
    [Test]
    procedure TestTagsOfTheHeader;
    [Test]
    procedure TestSizesIncludeTheSamples;
    [Test]
    procedure TestFormatFields;
    [Test]
    procedure TestSamplesFollowTheHeaderInOrder;
    [Test]
    procedure TestEmptySoundHasOnlyTheHeader;
    [Test]
    procedure TestInvalidChannelsRaise;
    [Test]
    procedure TestInvalidSampleRateRaise;
  end;

implementation

uses
  DelphiDoom.Audio.WavBuilder;

{ TTestWavBuilder }

function TTestWavBuilder.WordAt(const AWav: TBytes; AOffset: Integer): Integer;
begin
  Result := AWav[AOffset] or (AWav[AOffset + 1] shl 8);
end;

function TTestWavBuilder.CardinalAt(const AWav: TBytes;
  AOffset: Integer): Cardinal;
begin
  Result := Cardinal(WordAt(AWav, AOffset)) or
    (Cardinal(WordAt(AWav, AOffset + 2)) shl 16);
end;

procedure TTestWavBuilder.TestTagsOfTheHeader;
var
  LWav: TBytes;
begin
  LWav := TWavBuilder.Build(TArray<SmallInt>.Create(1, 2), 1, 11025);
  Assert.AreEqual('RIFF', string(AnsiString(PAnsiChar(@LWav[0]))).Substring(0, 4));
  Assert.AreEqual('WAVE', string(AnsiString(PAnsiChar(@LWav[8]))).Substring(0, 4));
  Assert.AreEqual('fmt ', string(AnsiString(PAnsiChar(@LWav[12]))).Substring(0, 4));
  Assert.AreEqual('data', string(AnsiString(PAnsiChar(@LWav[36]))).Substring(0, 4));
end;

procedure TTestWavBuilder.TestSizesIncludeTheSamples;
var
  LWav: TBytes;
begin
  LWav := TWavBuilder.Build(TArray<SmallInt>.Create(1, 2, 3, 4), 2, 22050);
  Assert.AreEqual<Integer>(WAV_HEADER_SIZE + 8, Length(LWav));
  Assert.AreEqual(Cardinal(Length(LWav) - 8), CardinalAt(LWav, 4));
  Assert.AreEqual(Cardinal(8), CardinalAt(LWav, 40));
end;

procedure TTestWavBuilder.TestFormatFields;
var
  LWav: TBytes;
begin
  LWav := TWavBuilder.Build(TArray<SmallInt>.Create(1, 2, 3, 4), 2, 22050);
  Assert.AreEqual(Cardinal(16), CardinalAt(LWav, 16));
  Assert.AreEqual(1, WordAt(LWav, 20));
  Assert.AreEqual(2, WordAt(LWav, 22));
  Assert.AreEqual(Cardinal(22050), CardinalAt(LWav, 24));
  Assert.AreEqual(Cardinal(22050 * 4), CardinalAt(LWav, 28));
  Assert.AreEqual(4, WordAt(LWav, 32));
  Assert.AreEqual(16, WordAt(LWav, 34));
end;

procedure TTestWavBuilder.TestSamplesFollowTheHeaderInOrder;
var
  LWav: TBytes;
begin
  LWav := TWavBuilder.Build(TArray<SmallInt>.Create(1, -2, 300), 1, 8000);
  Assert.AreEqual(1, Integer(SmallInt(WordAt(LWav, WAV_HEADER_SIZE))));
  Assert.AreEqual(-2, Integer(SmallInt(WordAt(LWav, WAV_HEADER_SIZE + 2))));
  Assert.AreEqual(300, Integer(SmallInt(WordAt(LWav, WAV_HEADER_SIZE + 4))));
end;

procedure TTestWavBuilder.TestEmptySoundHasOnlyTheHeader;
var
  LWav: TBytes;
begin
  LWav := TWavBuilder.Build(nil, 1, 8000);
  Assert.AreEqual<Integer>(WAV_HEADER_SIZE, Length(LWav));
  Assert.AreEqual(Cardinal(0), CardinalAt(LWav, 40));
end;

procedure TTestWavBuilder.BuildWithoutChannels;
begin
  TWavBuilder.Build(nil, 0, 8000);
end;

procedure TTestWavBuilder.BuildWithoutSampleRate;
begin
  TWavBuilder.Build(nil, 1, 0);
end;

procedure TTestWavBuilder.TestInvalidChannelsRaise;
begin
  Assert.WillRaise(BuildWithoutChannels, EArgumentException);
end;

procedure TTestWavBuilder.TestInvalidSampleRateRaise;
begin
  Assert.WillRaise(BuildWithoutSampleRate, EArgumentException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWavBuilder);

end.

