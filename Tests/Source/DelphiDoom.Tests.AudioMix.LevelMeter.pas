{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the level meter            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.LevelMeter;

// The generator of the random samples wraps around on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.AudioMix.LevelMeter;

type
  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixLevelMeter = class
  strict private
    FMeter: TPcmLevelMeter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure PrimaDiMisurareTuttoEZero;
    [Test]
    procedure IlPiccoEIlMassimoInValoreAssoluto;
    [Test]
    procedure IlPiccoDiMenoTrentaduemilaSettecentosessantottoEDi32768;
    [Test]
    procedure LaRmsEQuellaDiTuttiICampioni;
    [Test]
    procedure ContaIFrameConSuonoEQuelliMisurati;
    [Test]
    procedure LeMisureSiSommanoTraUnBloccoEUnAltro;
    [Test]
    procedure ZeroFrameNonCambiaNulla;
    [Test]
    procedure LaRmsDiUnBloccoDiMilleCampioniCasualiEQuellaDelCalcoloDiretto;
  end;

implementation

procedure TTestAudioMixLevelMeter.Setup;
begin
  FMeter := TPcmLevelMeter.Create;
end;

procedure TTestAudioMixLevelMeter.TearDown;
begin
  FMeter.Free;
end;

procedure TTestAudioMixLevelMeter.PrimaDiMisurareTuttoEZero;
begin
  Assert.AreEqual(0, FMeter.Peak);
  Assert.AreEqual(0.0, FMeter.Rms, 0);
  Assert.AreEqual<Int64>(0, FMeter.FrameCount);
  Assert.AreEqual<Int64>(0, FMeter.FramesWithSound);
end;

procedure TTestAudioMixLevelMeter.IlPiccoEIlMassimoInValoreAssoluto;
var
  LSamples: array[0..5] of SmallInt;
begin
  LSamples[0] := 10;
  LSamples[1] := -300;
  LSamples[2] := 200;
  LSamples[3] := 5;
  LSamples[4] := -20;
  LSamples[5] := 0;
  FMeter.Measure(@LSamples[0], 3);
  Assert.AreEqual(300, FMeter.Peak);
end;

procedure TTestAudioMixLevelMeter.IlPiccoDiMenoTrentaduemilaSettecentosessantottoEDi32768;
var
  LSamples: array[0..1] of SmallInt;
begin
  LSamples[0] := -32768;
  LSamples[1] := 1;
  FMeter.Measure(@LSamples[0], 1);
  // a game that wants 32767 cuts it itself
  Assert.AreEqual(32768, FMeter.Peak);
end;

procedure TTestAudioMixLevelMeter.LaRmsEQuellaDiTuttiICampioni;
var
  LSamples: array[0..3] of SmallInt;
begin
  LSamples[0] := 3;
  LSamples[1] := 4;
  LSamples[2] := 0;
  LSamples[3] := 0;
  FMeter.Measure(@LSamples[0], 2);
  // (9 + 16) / 4 samples
  Assert.AreEqual(2.5, FMeter.Rms, 1e-12);
end;

procedure TTestAudioMixLevelMeter.ContaIFrameConSuonoEQuelliMisurati;
var
  LSamples: array[0..7] of SmallInt;
begin
  LSamples[0] := 0;
  LSamples[1] := 0;
  LSamples[2] := 1;
  LSamples[3] := 0;
  LSamples[4] := 0;
  LSamples[5] := -1;
  LSamples[6] := 0;
  LSamples[7] := 0;
  FMeter.Measure(@LSamples[0], 4);
  Assert.AreEqual<Int64>(4, FMeter.FrameCount);
  Assert.AreEqual<Int64>(2, FMeter.FramesWithSound);
end;

procedure TTestAudioMixLevelMeter.LeMisureSiSommanoTraUnBloccoEUnAltro;
var
  LFirst: array[0..1] of SmallInt;
  LSecond: array[0..1] of SmallInt;
begin
  LFirst[0] := 100;
  LFirst[1] := 0;
  LSecond[0] := 0;
  LSecond[1] := 200;
  FMeter.Measure(@LFirst[0], 1);
  FMeter.Measure(@LSecond[0], 1);
  Assert.AreEqual(200, FMeter.Peak);
  Assert.AreEqual<Int64>(2, FMeter.FrameCount);
  Assert.AreEqual<Int64>(2, FMeter.FramesWithSound);
  // (10000 + 40000) / 4 samples
  Assert.AreEqual(Sqrt(12500.0), FMeter.Rms, 1e-9);
end;

procedure TTestAudioMixLevelMeter.ZeroFrameNonCambiaNulla;
var
  LSamples: array[0..1] of SmallInt;
begin
  LSamples[0] := 7;
  LSamples[1] := 7;
  FMeter.Measure(@LSamples[0], 0);
  Assert.AreEqual(0, FMeter.Peak);
  Assert.AreEqual<Int64>(0, FMeter.FrameCount);
  Assert.AreEqual(0.0, FMeter.Rms, 0);
end;

procedure TTestAudioMixLevelMeter.LaRmsDiUnBloccoDiMilleCampioniCasualiEQuellaDelCalcoloDiretto;
var
  LSamples: array[0..1999] of SmallInt;
  LIndex: Integer;
  LState: Cardinal;
  LSum: Double;
begin
  LState := 12345;
  LSum := 0;
  for LIndex := 0 to High(LSamples) do
  begin
    LState := LState * 1664525 + 1013904223;
    LSamples[LIndex] := SmallInt(Integer(LState shr 16) - 32768);
    LSum := LSum + Double(LSamples[LIndex]) * LSamples[LIndex];
  end;
  FMeter.Measure(@LSamples[0], 1000);
  // the same sum, in the same order, as the loop that the Xcom mixer had: the same bits
  Assert.AreEqual(Sqrt(LSum / 2000), FMeter.Rms, 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAudioMixLevelMeter);

end.
