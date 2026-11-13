{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of ResampleSfx of the Quake III sound and of TQ3Math      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.Q3.Resampler;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Resampler = class
  public
    [Test]
    procedure DovrebbeCopiareUnSuonoGiaAlRateDelDispositivo;
    [Test]
    procedure DovrebbeLeggereISedociBitInLittleEndian;
    [Test]
    procedure DovrebbePortareGliOttoBitSenzaSegnoASedici;
    [Test]
    procedure DovrebbeRipetereOgniCampioneQuandoIlRateEMeta;
    [Test]
    procedure DovrebbeSaltareUnCampioneSuDueQuandoIlRateERaddoppiato;
    [Test]
    procedure DovrebbeUsareIlPassoTroncatoACentoNovantaDueDiUnRapportoNonIntero;
    [Test]
    procedure DovrebbeLimitareLaLunghezzaAiDatiPresenti;
    [Test]
    procedure DovrebbeRifiutareUnRateNonPositivo;
    [Test]
    procedure DovrebbeRifiutareUnSuonoChePortaAUnMilioneDiCampioniInPiu;
  end;

  [TestFixture]
  [Category('Audio.Q3')]
  TTestQ3Math = class
  public
    [Test]
    procedure DovrebbeScorrereAritmeticamenteUnNegativo;
    [Test]
    procedure DovrebbeScorrereUnPositivoComeUnoShiftLogico;
    [Test]
    procedure DovrebbeTroncareVersoZero;
    [Test]
    procedure DovrebbeDareIlValoreIndefinitoFuoriIntervalloENonNumerico;
  end;

implementation

uses
  System.Math, DelphiDoom.Audio.Q3.Types, DelphiDoom.Audio.Q3.Resampler;

{ TTestQ3Resampler }

procedure TTestQ3Resampler.DovrebbeCopiareUnSuonoGiaAlRateDelDispositivo;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TQ3Resampler.ResampleShorts([10, -20, 30], 3, 22050, 22050);
  Assert.AreEqual<Integer>(3, Length(LSamples));
  Assert.AreEqual(10, Integer(LSamples[0]));
  Assert.AreEqual(-20, Integer(LSamples[1]));
  Assert.AreEqual(30, Integer(LSamples[2]));
end;

procedure TTestQ3Resampler.DovrebbeLeggereISedociBitInLittleEndian;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TQ3Resampler.ResampleBytes(TBytes.Create(1, 0, 2, 0, $FF, $FF, $00, $80), 0, 4,
    22050, 2, 22050);
  Assert.AreEqual<Integer>(4, Length(LSamples));
  Assert.AreEqual(1, Integer(LSamples[0]));
  Assert.AreEqual(2, Integer(LSamples[1]));
  Assert.AreEqual(-1, Integer(LSamples[2]));
  Assert.AreEqual(-32768, Integer(LSamples[3]));
end;

procedure TTestQ3Resampler.DovrebbePortareGliOttoBitSenzaSegnoASedici;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TQ3Resampler.ResampleBytes(TBytes.Create(9, 128, 129, 0, 255), 1, 4, 22050, 1,
    22050);
  Assert.AreEqual<Integer>(4, Length(LSamples));
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(256, Integer(LSamples[1]));
  Assert.AreEqual(-32768, Integer(LSamples[2]));
  Assert.AreEqual(32512, Integer(LSamples[3]));
end;

procedure TTestQ3Resampler.DovrebbeRipetereOgniCampioneQuandoIlRateEMeta;
var
  LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  LSamples := TQ3Resampler.ResampleShorts([5, 6, 7, 8], 4, 11025, 22050);
  Assert.AreEqual<Integer>(8, Length(LSamples));
  for LIndex := 0 to 7 do
    Assert.AreEqual(5 + LIndex div 2, Integer(LSamples[LIndex]));
end;

procedure TTestQ3Resampler.DovrebbeSaltareUnCampioneSuDueQuandoIlRateERaddoppiato;
var
  LSamples: TArray<SmallInt>;
begin
  LSamples := TQ3Resampler.ResampleShorts([0, 1, 2, 3, 4, 5, 6, 7], 8, 44100, 22050);
  Assert.AreEqual<Integer>(4, Length(LSamples));
  Assert.AreEqual(0, Integer(LSamples[0]));
  Assert.AreEqual(2, Integer(LSamples[1]));
  Assert.AreEqual(4, Integer(LSamples[2]));
  Assert.AreEqual(6, Integer(LSamples[3]));
end;

procedure TTestQ3Resampler.DovrebbeUsareIlPassoTroncatoACentoNovantaDueDiUnRapportoNonIntero;
var
  LSource, LSamples: TArray<SmallInt>;
  LIndex: Integer;
begin
  // 33075 / 22050 = 1.5: 100 samples give 66, the step is 384 / 256 per output sample
  SetLength(LSource, 100);
  for LIndex := 0 to 99 do
    LSource[LIndex] := LIndex;
  LSamples := TQ3Resampler.ResampleShorts(LSource, 100, 33075, 22050);
  Assert.AreEqual<Integer>(66, Length(LSamples));
  for LIndex := 0 to 65 do
    Assert.AreEqual(LIndex * 384 div 256, Integer(LSamples[LIndex]));
end;

procedure TTestQ3Resampler.DovrebbeLimitareLaLunghezzaAiDatiPresenti;
var
  LSamples: TArray<SmallInt>;
begin
  // the header of a file can promise more than it holds: the C reads past the buffer
  LSamples := TQ3Resampler.ResampleBytes(TBytes.Create(1, 0, 2, 0), 0, 1000, 22050, 2, 22050);
  Assert.AreEqual<Integer>(2, Length(LSamples));
  LSamples := TQ3Resampler.ResampleShorts([1, 2], 50, 22050, 22050);
  Assert.AreEqual<Integer>(2, Length(LSamples));
  LSamples := TQ3Resampler.ResampleShorts([1, 2], -5, 22050, 22050);
  Assert.AreEqual<Integer>(0, Length(LSamples));
  LSamples := TQ3Resampler.ResampleBytes(nil, -3, 4, 22050, 1, 22050);
  Assert.AreEqual<Integer>(0, Length(LSamples));
  // an offset beyond the end of the data
  LSamples := TQ3Resampler.ResampleBytes(TBytes.Create(1, 2), 10, 4, 22050, 1, 22050);
  Assert.AreEqual<Integer>(0, Length(LSamples));
end;

procedure TTestQ3Resampler.DovrebbeRifiutareUnRateNonPositivo;
begin
  Assert.WillRaise(
    procedure
    begin
      TQ3Resampler.ResampleShorts([1], 1, 0, 22050);
    end, EQ3SoundException);
  Assert.WillRaise(
    procedure
    begin
      TQ3Resampler.ResampleShorts([1], 1, 22050, 0);
    end, EQ3SoundException);
end;

procedure TTestQ3Resampler.DovrebbeRifiutareUnSuonoChePortaAUnMilioneDiCampioniInPiu;
var
  LSource: TArray<SmallInt>;
begin
  // rate 1 on a device of 22050: the output would have 22050 times the samples
  SetLength(LSource, 4000);
  Assert.WillRaise(
    procedure
    begin
      TQ3Resampler.ResampleShorts(LSource, 4000, 1, 22050);
    end, EQ3SoundException);
end;

{ TTestQ3Math }

procedure TTestQ3Math.DovrebbeScorrereAritmeticamenteUnNegativo;
begin
  Assert.AreEqual(-4, TQ3Math.Sar(-16, 2));
  Assert.AreEqual(-1, TQ3Math.Sar(-1, 8));
  Assert.AreEqual(-1, TQ3Math.Sar(-255, 8));
  Assert.AreEqual(-2, TQ3Math.Sar(Integer($80000000), 30));
end;

procedure TTestQ3Math.DovrebbeScorrereUnPositivoComeUnoShiftLogico;
begin
  Assert.AreEqual(125, TQ3Math.Sar(1000, 3));
  Assert.AreEqual(0, TQ3Math.Sar(255, 8));
end;

procedure TTestQ3Math.DovrebbeTroncareVersoZero;
begin
  Assert.AreEqual(1, TQ3Math.TruncToInt(1.9));
  Assert.AreEqual(-1, TQ3Math.TruncToInt(-1.9));
  Assert.AreEqual(0, TQ3Math.TruncToInt(-0.5));
end;

procedure TTestQ3Math.DovrebbeDareIlValoreIndefinitoFuoriIntervalloENonNumerico;
begin
  Assert.AreEqual(Integer($80000000), TQ3Math.TruncToInt(3.0E9));
  Assert.AreEqual(Integer($80000000), TQ3Math.TruncToInt(-3.0E9));
  Assert.AreEqual(Integer($80000000), TQ3Math.TruncToInt(Infinity));
  Assert.AreEqual(Integer($80000000), TQ3Math.TruncToInt(NaN));
end;

end.
