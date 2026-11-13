{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library - the channel of 16 bit      }
{  stereo samples (the parity with the old mixer of OpenXcom is in the tests    }
{  of XcomEngine, which run the whole mixer)                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.AudioMix.StereoChannelVoice;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.AudioMix.StereoChannelVoice;

type
  [TestFixture]
  [Category('audiomix')]
  TTestAudioMixStereoChannelVoice = class
  strict private
    FVoice: TPcmStereoChannelVoice;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereInattivoPrimaDelloStart;
    [Test]
    procedure DovrebbeApplicareIlVolumeDelCanale;
    [Test]
    procedure DovrebbeApplicareIGuadagniASinistraEDestra;
    [Test]
    procedure DovrebbeSommareConSaturazione;
    [Test]
    procedure DovrebbeSuonareUnaVoltaESpegnersi;
    [Test]
    procedure DovrebbeRipeterePerIlNumeroDiGiri;
    [Test]
    procedure DovrebbeRipetereSempreConUnNumeroNegativo;
    [Test]
    procedure DovrebbeFinireSubitoUnSuonoVuoto;
    [Test]
    procedure DovrebbeSommareUnSuonoConIlVolumeGiaDentro;
    [Test]
    procedure DovrebbeZittireUnSuonoConIlVolumeGiaDentroSeSilenziato;
    [Test]
    procedure DovrebbeFermarsiConHalt;
    [Test]
    procedure DovrebbeRiportareIGuadagniAUnoConStart;
    [Test]
    procedure DovrebbeContinuareDaDoveEraInUnSecondoBlocco;
  end;

implementation

procedure TTestAudioMixStereoChannelVoice.Setup;
begin
  FVoice := TPcmStereoChannelVoice.Create;
end;

procedure TTestAudioMixStereoChannelVoice.TearDown;
begin
  FVoice.Free;
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeEssereInattivoPrimaDelloStart;
begin
  Assert.IsFalse(FVoice.Active);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeApplicareIlVolumeDelCanale;
var
  LOutput: array[0..3] of SmallInt;
begin
  FillChar(LOutput, SizeOf(LOutput), 0);
  FVoice.Start(TArray<SmallInt>.Create(1000, -1000, 2000, -2000), 0, False);
  FVoice.Render(@LOutput[0], 4, 0.5, False);
  Assert.AreEqual<Integer>(500, LOutput[0]);
  Assert.AreEqual<Integer>(-500, LOutput[1]);
  Assert.AreEqual<Integer>(1000, LOutput[2]);
  Assert.AreEqual<Integer>(-1000, LOutput[3]);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeApplicareIGuadagniASinistraEDestra;
var
  LOutput: array[0..3] of SmallInt;
begin
  FillChar(LOutput, SizeOf(LOutput), 0);
  FVoice.Start(TArray<SmallInt>.Create(1000, 1000, 1000, 1000), 0, False);
  FVoice.SetGains(1, 0.25);
  FVoice.Render(@LOutput[0], 4, 1, False);
  Assert.AreEqual<Integer>(1000, LOutput[0]);
  Assert.AreEqual<Integer>(250, LOutput[1]);
  Assert.AreEqual<Integer>(1000, LOutput[2]);
  Assert.AreEqual<Integer>(250, LOutput[3]);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeSommareConSaturazione;
var
  LOutput: array[0..1] of SmallInt;
begin
  LOutput[0] := 30000;
  LOutput[1] := -30000;
  FVoice.Start(TArray<SmallInt>.Create(10000, -10000), 0, False);
  FVoice.Render(@LOutput[0], 2, 1, False);
  Assert.AreEqual<Integer>(32767, LOutput[0]);
  Assert.AreEqual<Integer>(-32768, LOutput[1]);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeSuonareUnaVoltaESpegnersi;
var
  LOutput: array[0..3] of SmallInt;
begin
  FillChar(LOutput, SizeOf(LOutput), 0);
  FVoice.Start(TArray<SmallInt>.Create(5, 6), 0, False);
  FVoice.Render(@LOutput[0], 4, 1, False);
  Assert.AreEqual<Integer>(5, LOutput[0]);
  Assert.AreEqual<Integer>(6, LOutput[1]);
  Assert.AreEqual<Integer>(0, LOutput[2]);
  Assert.IsFalse(FVoice.Active);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeRipeterePerIlNumeroDiGiri;
var
  LOutput: array[0..5] of SmallInt;
begin
  FillChar(LOutput, SizeOf(LOutput), 0);
  // one loop: it plays twice
  FVoice.Start(TArray<SmallInt>.Create(10, 20), 1, False);
  FVoice.Render(@LOutput[0], 6, 1, False);
  Assert.AreEqual<Integer>(10, LOutput[0]);
  Assert.AreEqual<Integer>(20, LOutput[1]);
  Assert.AreEqual<Integer>(10, LOutput[2]);
  Assert.AreEqual<Integer>(20, LOutput[3]);
  Assert.AreEqual<Integer>(0, LOutput[4]);
  Assert.IsFalse(FVoice.Active);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeRipetereSempreConUnNumeroNegativo;
var
  LOutput: array[0..9] of SmallInt;
  LIndex: Integer;
begin
  FillChar(LOutput, SizeOf(LOutput), 0);
  FVoice.Start(TArray<SmallInt>.Create(1, 2), -1, False);
  FVoice.Render(@LOutput[0], 10, 1, False);
  for LIndex := 0 to 9 do
    Assert.AreEqual<Integer>(1 + (LIndex and 1), LOutput[LIndex]);
  Assert.IsTrue(FVoice.Active);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeFinireSubitoUnSuonoVuoto;
var
  LOutput: SmallInt;
begin
  LOutput := 9;
  FVoice.Start(nil, 0, False);
  Assert.IsTrue(FVoice.Active);
  FVoice.Render(@LOutput, 1, 1, False);
  Assert.IsFalse(FVoice.Active);
  Assert.AreEqual<Integer>(9, LOutput);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeSommareUnSuonoConIlVolumeGiaDentro;
var
  LOutput: array[0..1] of SmallInt;
begin
  LOutput[0] := 100;
  LOutput[1] := 32000;
  // the volume of the channel is not applied twice
  FVoice.Start(TArray<SmallInt>.Create(1000, 1000), 0, True);
  FVoice.Render(@LOutput[0], 2, 0.1, False);
  Assert.AreEqual<Integer>(1100, LOutput[0]);
  Assert.AreEqual<Integer>(32767, LOutput[1]);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeZittireUnSuonoConIlVolumeGiaDentroSeSilenziato;
var
  LOutput: array[0..1] of SmallInt;
begin
  LOutput[0] := 100;
  LOutput[1] := 200;
  FVoice.Start(TArray<SmallInt>.Create(1000, 1000), 0, True);
  FVoice.Render(@LOutput[0], 2, 1, True);
  Assert.AreEqual<Integer>(100, LOutput[0]);
  Assert.AreEqual<Integer>(200, LOutput[1]);
  Assert.IsFalse(FVoice.Active, 'the sound goes on in silence');
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeFermarsiConHalt;
begin
  FVoice.Start(TArray<SmallInt>.Create(1, 2), -1, False);
  FVoice.Halt;
  Assert.IsFalse(FVoice.Active);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeRiportareIGuadagniAUnoConStart;
var
  LOutput: array[0..1] of SmallInt;
begin
  FVoice.Start(TArray<SmallInt>.Create(1, 1), 0, False);
  FVoice.SetGains(0, 0);
  FVoice.Start(TArray<SmallInt>.Create(800, 800), 0, False);
  FillChar(LOutput, SizeOf(LOutput), 0);
  FVoice.Render(@LOutput[0], 2, 1, False);
  Assert.AreEqual<Integer>(800, LOutput[0]);
  Assert.AreEqual<Integer>(800, LOutput[1]);
end;

procedure TTestAudioMixStereoChannelVoice.DovrebbeContinuareDaDoveEraInUnSecondoBlocco;
var
  LFirst: array[0..1] of SmallInt;
  LSecond: array[0..1] of SmallInt;
begin
  FillChar(LFirst, SizeOf(LFirst), 0);
  FillChar(LSecond, SizeOf(LSecond), 0);
  FVoice.Start(TArray<SmallInt>.Create(1, 2, 3, 4), 0, False);
  FVoice.Render(@LFirst[0], 2, 1, False);
  Assert.IsTrue(FVoice.Active);
  FVoice.Render(@LSecond[0], 2, 1, False);
  Assert.AreEqual<Integer>(1, LFirst[0]);
  Assert.AreEqual<Integer>(2, LFirst[1]);
  Assert.AreEqual<Integer>(3, LSecond[0]);
  Assert.AreEqual<Integer>(4, LSecond[1]);
  Assert.IsFalse(FVoice.Active);
end;

end.
