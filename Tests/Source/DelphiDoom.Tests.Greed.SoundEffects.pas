{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSoundEffects                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SoundEffects;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.SoundEffects, DelphiDoom.Tests.Greed.SoundFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSoundEffects = class(TObject)
  private
    FDevice: TFakeSoundDevice;
    FDeviceIntf: IGreedSoundDevice;
    FListener: TFakeListener;
    FListenerIntf: IGreedListener;
    FVolumes: IGreedSoundVolumes;
    FEffects: IGreedSoundEffects;
    function Archive: IGreedArchive;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSuonareLaWavDelLumpDopoSoundEffects;
    [Test]
    procedure DovrebbeIgnorareUnSuonoTroppoLontano;
    [Test]
    procedure DovrebbeIgnorareUnLumpVuoto;
    [Test]
    procedure DovrebbeImpostarePanEVolumeAllAvvio;
    [Test]
    procedure DovrebbeRiusareUnCanaleQuandoIlSuonoFinisce;
    [Test]
    procedure DovrebbeFermarsiQuandoISessantaQuattroCanaliSonoPieni;
    [Test]
    procedure DovrebbeSeguireIlMovimentoDelGiocatoreInUpdate;
    [Test]
    procedure DovrebbeLasciareLibertoIlCanaleSeIlDispositivoRifiuta;
    [Test]
    procedure DovrebbeFermareTuttiISuoni;
    [Test]
    procedure DovrebbeSollevareSenzaIlLumpSoundEffects;
    [Test]
    procedure DovrebbeTrovareFileWavNeiLumpDegliEffettiDelleDemo;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.Builders, DelphiDoom.Tests.Greed.RealData, DelphiDoom.Greed.SoundVolumes;

{ TTestGreedSoundEffects }

function TTestGreedSoundEffects.Archive: IGreedArchive;
var
  LBlo: TGreedBlo;
begin
  LBlo := TGreedBlo.Create;
  try
    LBlo.Add('SOUNDEFFECTS', nil);
    LBlo.Add('fx0', TGreedLumps.Bytes([1, 2, 3]));
    LBlo.Add('fx1', TGreedLumps.Bytes([4, 5]));
    LBlo.Add('fx2', nil);
    Result := LBlo.Open;
  finally
    LBlo.Free;
  end;
end;

procedure TTestGreedSoundEffects.Setup;
begin
  FDevice := TFakeSoundDevice.Create;
  FDeviceIntf := FDevice;
  FListener := TFakeListener.Create;
  FListenerIntf := FListener;
  FVolumes := TGreedSoundVolumes.Create;
  FEffects := TGreedSoundEffects.Create(FDeviceIntf, Archive, FListenerIntf, FVolumes);
end;

procedure TTestGreedSoundEffects.TearDown;
begin
  FEffects := nil;
  FVolumes := nil;
  FListenerIntf := nil;
  FDeviceIntf := nil;
end;

procedure TTestGreedSoundEffects.DovrebbeSuonareLaWavDelLumpDopoSoundEffects;
begin
  FEffects.Start(1, 0, 0, 0);
  Assert.AreEqual(1, FDevice.Effects.Count);
  Assert.AreEqual<Integer>(2, Length(FDevice.EffectWaves[0]));
  Assert.AreEqual<Integer>(4, FDevice.EffectWaves[0][0]);
end;

procedure TTestGreedSoundEffects.DovrebbeIgnorareUnSuonoTroppoLontano;
begin
  FEffects.Start(0, 0, 30 * GREED_FRACTILEUNIT, 0);
  Assert.AreEqual(0, FDevice.Effects.Count);
end;

procedure TTestGreedSoundEffects.DovrebbeIgnorareUnLumpVuoto;
begin
  FEffects.Start(2, 0, 0, 0);
  Assert.AreEqual(0, FDevice.Effects.Count);
end;

procedure TTestGreedSoundEffects.DovrebbeImpostarePanEVolumeAllAvvio;
begin
  FVolumes.SetVolumes(100, 255);
  FEffects.Start(0, 0, 2 * GREED_FRACTILEUNIT, 0);
  Assert.AreEqual(1, FDevice.Effects[0].PanCalls);
  Assert.IsTrue(FDevice.Effects[0].Pan > 0);
  Assert.IsTrue((FDevice.Effects[0].Volume > 0) and (FDevice.Effects[0].Volume < 1));
end;

procedure TTestGreedSoundEffects.DovrebbeRiusareUnCanaleQuandoIlSuonoFinisce;
var
  LIndex: Integer;
begin
  for LIndex := 1 to GREED_SFX_CHANNELS do
    FEffects.Start(0, 0, 0, 0);
  Assert.AreEqual(GREED_SFX_CHANNELS, FDevice.Effects.Count);
  FDevice.Effects[10].Active := False;
  FEffects.Start(0, 0, 0, 0);
  Assert.AreEqual(GREED_SFX_CHANNELS + 1, FDevice.Effects.Count);
end;

procedure TTestGreedSoundEffects.DovrebbeFermarsiQuandoISessantaQuattroCanaliSonoPieni;
var
  LIndex: Integer;
begin
  for LIndex := 1 to GREED_SFX_CHANNELS + 20 do
    FEffects.Start(0, 0, 0, 0);
  Assert.AreEqual(GREED_SFX_CHANNELS, FDevice.Effects.Count);
end;

procedure TTestGreedSoundEffects.DovrebbeSeguireIlMovimentoDelGiocatoreInUpdate;
var
  LVolume: Single;
begin
  FEffects.Start(0, 0, 4 * GREED_FRACTILEUNIT, 0);
  LVolume := FDevice.Effects[0].Volume;
  FListener.X := 4 * GREED_FRACTILEUNIT;
  FEffects.Update;
  Assert.IsTrue(FDevice.Effects[0].Volume > LVolume);
end;

procedure TTestGreedSoundEffects.DovrebbeLasciareLibertoIlCanaleSeIlDispositivoRifiuta;
begin
  FDevice.RefuseEffects := True;
  FEffects.Start(0, 0, 0, 0);
  FEffects.Start(0, 0, 0, 0);
  Assert.AreEqual(0, FDevice.Effects.Count);
  FDevice.RefuseEffects := False;
  FEffects.Start(0, 0, 0, 0);
  Assert.AreEqual(1, FDevice.Effects.Count);
end;

procedure TTestGreedSoundEffects.DovrebbeFermareTuttiISuoni;
begin
  FEffects.Start(0, 0, 0, 0);
  FEffects.Start(1, 0, 0, 0);
  FEffects.StopAll;
  Assert.IsTrue(FDevice.Effects[0].Stopped);
  Assert.IsTrue(FDevice.Effects[1].Stopped);
end;

procedure TTestGreedSoundEffects.DovrebbeSollevareSenzaIlLumpSoundEffects;
var
  LBlo: TGreedBlo;
  LArchive: IGreedArchive;
begin
  LBlo := TGreedBlo.Create;
  try
    LBlo.Add('other', nil);
    LArchive := LBlo.Open;
  finally
    LBlo.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      TGreedSoundEffects.Create(FDeviceIntf, LArchive, FListenerIntf, FVolumes);
    end, EGreedNotFoundException);
end;

procedure TTestGreedSoundEffects.DovrebbeTrovareFileWavNeiLumpDegliEffettiDelleDemo;
var
  LFolder: string;
  LArchive: IGreedArchive;
  LFirst, LIndex, LPlayable: Integer;
  LBytes: TBytes;
begin
  for LFolder in [TGreedRealData.Demo1016Folder, TGreedRealData.Demo20Folder] do
  begin
    if LFolder = '' then
      Continue;
    LArchive := TGreedRealData.OpenArchive(LFolder);
    LFirst := LArchive.RequireIndexOf(GREED_LUMP_SOUND_EFFECTS) + 1;
    // the demo 1.016 has the marker as its last lump: its effects are not in the archive
    if LFirst + 89 >= LArchive.LumpCount then
      Continue;
    // SN_MON8_WAKE (0) .. SN_BULLET17 (89)
    LPlayable := 0;
    // from the effect 52 (SN_MON1_WAKE) the demo has other data after the effects
    for LIndex := LFirst to LFirst + 51 do
    begin
      LBytes := LArchive.ReadLump(LIndex);
      // the demo has some effects empty (the game does not play them: datalen <= 0)
      if Length(LBytes) = 0 then
        Continue;
      Inc(LPlayable);
      Assert.IsTrue(Length(LBytes) > 44, 'lump ' + IntToStr(LIndex));
      Assert.AreEqual('52494646', IntToHex(LBytes[0], 2) + IntToHex(LBytes[1], 2) + IntToHex(LBytes[2], 2) +
        IntToHex(LBytes[3], 2), Format('lump %d (effect %d) size %d', [LIndex, LIndex - LFirst, Length(LBytes)]));
    end;
    Assert.IsTrue(LPlayable > 20, 'effects in ' + LFolder);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedSoundEffects);

end.
