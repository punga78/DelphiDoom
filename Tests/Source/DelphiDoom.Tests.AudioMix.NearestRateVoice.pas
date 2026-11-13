{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the voice that takes the   }
{  nearest sample (the parity with the old mixer of xGreed is in the tests of   }
{  Greed, which run the whole mixer)                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.NearestRateVoice;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.AudioMix.Intf, DelphiDoom.AudioMix.NearestRateVoice;

type
  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixNearestRateVoice = class
  strict private
    function Wave16(const ASamples: array of SmallInt): TBytes;
    function Make(const ASamples: array of SmallInt; AChannels, AWaveRate, AMixerRate: Integer): TPcmNearestRateVoice;
  public
    [Test]
    procedure DovrebbeSommareUnSuonoMonoSuEntrambiILati;
    [Test]
    procedure DovrebbeFinireAlBloccoDopoLUltimoFrame;
    [Test]
    procedure DovrebbeSommareAQuelloCheCeGia;
    [Test]
    procedure DovrebbeSpostareILatiConIlPan;
    [Test]
    procedure DovrebbeLimitarePanEVolume;
    [Test]
    procedure DovrebbeScalareConIlVolumeTroncandoVersoZero;
    [Test]
    procedure DovrebbeLeggereGliOttoBitSenzaSegno;
    [Test]
    procedure DovrebbeLeggereUnSuonoStereo;
    [Test]
    procedure DovrebbeRipetereIFrameQuandoIlRateDelMixerEPiuAlto;
    [Test]
    procedure DovrebbeSaltareIFrameQuandoIlRateDelMixerEPiuBasso;
    [Test]
    procedure DovrebbeNonSommareUnaVoceFermata;
    [Test]
    procedure DovrebbeEssereUnaIPcmVoice;
  end;

implementation

function TTestAudioMixNearestRateVoice.Wave16(const ASamples: array of SmallInt): TBytes;
var
  LIndex: Integer;
begin
  // two bytes in front that are not samples: the offset of the data is not 0
  SetLength(Result, 2 + Length(ASamples) * 2);
  Result[0] := $AA;
  Result[1] := $55;
  for LIndex := 0 to High(ASamples) do
  begin
    Result[2 + LIndex * 2] := Byte(ASamples[LIndex] and $FF);
    Result[3 + LIndex * 2] := Byte((ASamples[LIndex] shr 8) and $FF);
  end;
end;

function TTestAudioMixNearestRateVoice.Make(const ASamples: array of SmallInt; AChannels, AWaveRate,
  AMixerRate: Integer): TPcmNearestRateVoice;
begin
  Result := TPcmNearestRateVoice.Create(Wave16(ASamples), 2, Length(ASamples) div AChannels, AChannels, 16,
    AWaveRate, AMixerRate);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeSommareUnSuonoMonoSuEntrambiILati;
var
  LVoice: IPcmVoice;
  LSums: array[0..7] of Integer;
begin
  FillChar(LSums, SizeOf(LSums), 0);
  LVoice := Make([100, -200, 300, -400], 1, 22050, 22050);
  LVoice.Mix(@LSums[0], 4);
  Assert.AreEqual(100, LSums[0]);
  Assert.AreEqual(100, LSums[1]);
  Assert.AreEqual(-200, LSums[2]);
  Assert.AreEqual(-200, LSums[3]);
  Assert.AreEqual(300, LSums[4]);
  Assert.AreEqual(-400, LSums[7]);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeFinireAlBloccoDopoLUltimoFrame;
var
  LVoice: IPcmVoice;
  LSums: array[0..7] of Integer;
begin
  FillChar(LSums, SizeOf(LSums), 0);
  LVoice := Make([1, 2], 1, 22050, 22050);
  Assert.IsFalse(LVoice.Mix(@LSums[0], 2), 'two frames asked, two frames played');
  Assert.IsTrue(LVoice.Mix(@LSums[0], 2), 'the next block finds no frame');
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeSommareAQuelloCheCeGia;
var
  LVoice: IPcmVoice;
  LSums: array[0..1] of Integer;
begin
  LSums[0] := 1000;
  LSums[1] := -1000;
  LVoice := Make([50], 1, 22050, 22050);
  LVoice.Mix(@LSums[0], 1);
  Assert.AreEqual(1050, LSums[0]);
  Assert.AreEqual(-950, LSums[1]);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeSpostareILatiConIlPan;
var
  LVoice: TPcmNearestRateVoice;
  LHold: IPcmVoice;
  LSums: array[0..1] of Integer;
begin
  LVoice := Make([100, 100], 1, 22050, 22050);
  LHold := LVoice;
  FillChar(LSums, SizeOf(LSums), 0);
  LHold.Mix(@LSums[0], 1);
  Assert.AreEqual(100, LSums[0], 'centro, sinistra');
  Assert.AreEqual(100, LSums[1], 'centro, destra');
  LVoice.SetPan(-1);
  FillChar(LSums, SizeOf(LSums), 0);
  LHold.Mix(@LSums[0], 1);
  Assert.AreEqual(100, LSums[0], 'tutto a sinistra');
  Assert.AreEqual(0, LSums[1], 'tutto a sinistra');
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeLimitarePanEVolume;
var
  LVoice: TPcmNearestRateVoice;
  LHold: IPcmVoice;
  LSums: array[0..1] of Integer;
begin
  LVoice := Make([100], 1, 22050, 22050);
  LHold := LVoice;
  LVoice.SetPan(5);
  LVoice.SetVolume(2);
  FillChar(LSums, SizeOf(LSums), 0);
  LHold.Mix(@LSums[0], 1);
  Assert.AreEqual(0, LSums[0], 'pan limitato a 1: la sinistra tace');
  Assert.AreEqual(100, LSums[1], 'volume limitato a 1');
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeScalareConIlVolumeTroncandoVersoZero;
var
  LVoice: TPcmNearestRateVoice;
  LHold: IPcmVoice;
  LSums: array[0..3] of Integer;
begin
  LVoice := Make([100, -201], 1, 22050, 22050);
  LHold := LVoice;
  LVoice.SetVolume(0.5);
  FillChar(LSums, SizeOf(LSums), 0);
  LHold.Mix(@LSums[0], 2);
  Assert.AreEqual(50, LSums[0]);
  Assert.AreEqual(-100, LSums[2], '(-201 * 128) div 256 cut toward zero');
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeLeggereGliOttoBitSenzaSegno;
var
  LVoice: IPcmVoice;
  LSums: array[0..3] of Integer;
begin
  FillChar(LSums, SizeOf(LSums), 0);
  LVoice := TPcmNearestRateVoice.Create(TBytes.Create(0, 192, 64), 1, 2, 1, 8, 22050, 22050);
  LVoice.Mix(@LSums[0], 2);
  Assert.AreEqual(16384, LSums[0]);
  Assert.AreEqual(-16384, LSums[2]);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeLeggereUnSuonoStereo;
var
  LVoice: IPcmVoice;
  LSums: array[0..3] of Integer;
begin
  FillChar(LSums, SizeOf(LSums), 0);
  LVoice := Make([10, 20, 30, 40], 2, 22050, 22050);
  LVoice.Mix(@LSums[0], 2);
  Assert.AreEqual(10, LSums[0]);
  Assert.AreEqual(20, LSums[1]);
  Assert.AreEqual(30, LSums[2]);
  Assert.AreEqual(40, LSums[3]);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeRipetereIFrameQuandoIlRateDelMixerEPiuAlto;
var
  LVoice: IPcmVoice;
  LSums: array[0..7] of Integer;
begin
  FillChar(LSums, SizeOf(LSums), 0);
  LVoice := Make([100, 200], 1, 11025, 22050);
  LVoice.Mix(@LSums[0], 4);
  Assert.AreEqual(100, LSums[0]);
  Assert.AreEqual(100, LSums[2]);
  Assert.AreEqual(200, LSums[4]);
  Assert.AreEqual(200, LSums[6]);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeSaltareIFrameQuandoIlRateDelMixerEPiuBasso;
var
  LVoice: IPcmVoice;
  LSums: array[0..3] of Integer;
begin
  FillChar(LSums, SizeOf(LSums), 0);
  LVoice := Make([1, 2, 3, 4], 1, 44100, 22050);
  LVoice.Mix(@LSums[0], 2);
  Assert.AreEqual(1, LSums[0]);
  Assert.AreEqual(3, LSums[2]);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeNonSommareUnaVoceFermata;
var
  LVoice: TPcmNearestRateVoice;
  LHold: IPcmVoice;
  LSums: array[0..1] of Integer;
begin
  LVoice := Make([100, 100], 1, 22050, 22050);
  LHold := LVoice;
  LSums[0] := 0;
  LSums[1] := 0;
  LVoice.Stop;
  Assert.IsFalse(LVoice.IsActive);
  Assert.IsTrue(LHold.Mix(@LSums[0], 1));
  Assert.AreEqual(0, LSums[0]);
end;

procedure TTestAudioMixNearestRateVoice.DovrebbeEssereUnaIPcmVoice;
var
  LVoice: TPcmNearestRateVoice;
  LAsInterface: IPcmVoice;
begin
  LVoice := Make([1], 1, 22050, 22050);
  Assert.IsTrue(Supports(LVoice, IPcmVoice, LAsInterface));
  Assert.IsTrue(LVoice.IsActive);
end;

end.
