{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSfxAttenuation                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.SfxAttenuation;

// Angles and seeds wrap around, as in the engine (Doom32.inc has no overflow checks)
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Math, DUnitX.TestFramework, DelphiDoom.Audio.SfxAttenuation,
  DelphiDoom.Tests.Audio.OldSound;

type
  [TestFixture]
  [Category('audio')]
  TTestAudioSfxAttenuation = class(TObject)
  private
    FRules: TSfxAttenuationRules;
    FSines: TSfxSineTable;
    FOld: TOldSound;
    FSeed: Cardinal;
    function Next(ARange: Integer): Integer;
    function Units(AValue: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLoStessoDelVecchioCodiceSuCasiCasuali;
    [Test]
    procedure DovrebbeDareIlPitchDelVecchioCodicePerOgniValore;
    [Test]
    procedure DovrebbeDareCentroEVolumePienoADistanzaZero;
    [Test]
    procedure DovrebbeDareFalsoConVolumeZeroADistanzaZero;
    [Test]
    procedure DovrebbeDareFalsoELasciareIValoriSeTroppoLontano;
    [Test]
    procedure DovrebbeDareVolumePienoEntroLaDistanzaVicina;
    [Test]
    procedure DovrebbeAbbassareIlVolumeConLaDistanza;
    [Test]
    procedure DovrebbeSpostareASinistraUnSuonoAllaSinistraDiChiAscolta;
    [Test]
    procedure DovrebbeSpostareADestraUnSuonoAllaDestraDiChiAscolta;
    [Test]
    procedure DovrebbeSentireTuttoNelLivelloAVolumePieno;
    [Test]
    procedure DovrebbeTenereIlVolumeAlmenoAQuindiciNelLivelloAVolumePieno;
    [Test]
    [TestCase('uguali', '0,0,0,0,0')]
    [TestCase('solo x', '0,0,10,0,10')]
    [TestCase('solo y', '0,0,0,-10,10')]
    [TestCase('lato corto a meta', '0,0,30,40,55')]
    [TestCase('negativi', '-30,-40,0,0,55')]
    procedure DovrebbeCalcolareLaDistanzaApprossimata(AX1, AY1, AX2, AY2, AExpected: Integer);
    [Test]
    procedure DovrebbeTenereIlPitchTraZeroEDuecentocinquantacinque;
  end;

implementation

function TestPointToAngle(const AX1: Integer; const AY1: Integer; const AX2: Integer;
  const AY2: Integer): Cardinal;
var
  LAngle: Double;
begin
  LAngle := ArcTan2(Double(AY2) - Double(AY1), Double(AX2) - Double(AX1));
  if LAngle < 0 then
    LAngle := LAngle + 2 * Pi;
  Result := Cardinal(Trunc(LAngle / (2 * Pi) * 4294967296.0) and $FFFFFFFF);
end;

{ TTestAudioSfxAttenuation }

procedure TTestAudioSfxAttenuation.Setup;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FSines) do
    FSines[LIndex] := Round(Sin((LIndex + 0.5) * 2 * Pi / 8192) * 65536);
  FRules.ClippingDistance := OLD_S_CLIPPING_DIST;
  FRules.CloseDistance := OLD_S_CLOSE_DIST;
  FRules.Attenuator := OLD_S_ATTENUATOR;
  FRules.NormalSeparation := OLD_NORM_SEP;
  FRules.StereoSwing := OLD_S_STEREO_SWING;
  FRules.PointToAngle := TestPointToAngle;
  FRules.FineSine := @FSines;

  FOld := TOldSound.Create;
  FOld.R_PointToAngle2 := TestPointToAngle;
  for LIndex := 0 to High(FSines) do
    FOld.finesine[LIndex] := FSines[LIndex];
  FSeed := 12345;
end;

procedure TTestAudioSfxAttenuation.TearDown;
begin
  FOld.Free;
end;

function TTestAudioSfxAttenuation.Next(ARange: Integer): Integer;
var
  LHigh: UInt64;
begin
{$Q-}
  FSeed := FSeed * 1664525 + 1013904223;
  LHigh := FSeed shr 8;
  FSeed := FSeed * 1664525 + 1013904223;
  // 48 bits: the ranges of the positions are wider than one draw
  Result := Integer(((LHigh shl 24) or (FSeed shr 8)) mod UInt64(ARange));
end;

function TTestAudioSfxAttenuation.Units(AValue: Integer): Integer;
begin
  Result := AValue * 65536;
end;

procedure TTestAudioSfxAttenuation.DovrebbeDareLoStessoDelVecchioCodiceSuCasiCasuali;
const
  CASES = 200000;
  // how far the source may be: on the listener, close, inside the clipping, around it, far
  RANGES: array[0..4] of Integer = (1, 150, 1100, 1300, 8000);
var
  LCase: Integer;
  LListener, LSource: TOldMobj;
  LRange: Integer;
  LGame: Integer;
  LOldVolume, LOldSeparation, LOldPitch: Integer;
  LNewVolume, LNewSeparation: Integer;
  LOldResult, LNewResult: Boolean;
  LFull: Boolean;
  LWhere: string;
begin
  for LCase := 1 to CASES do
  begin
    LGame := Next(3);
    FOld.Game := TOldSoundGame(LGame);
    FOld.gamemap := 6 + Next(4);
    FOld.NeedsCompatibilityMode := Next(2) = 1;
    FOld.snd_SfxVolume := Next(16);

    LListener.x := Units(Next(6000) - 3000) + Next(65536);
    LListener.y := Units(Next(6000) - 3000) + Next(65536);
    LListener.angle := Cardinal(Next(65536)) shl 16 or Cardinal(Next(65536));
    LListener.viewangle := 0;
    if Next(4) = 0 then
      LListener.viewangle := Cardinal(Next(65536)) shl 16;
    LRange := RANGES[Next(Length(RANGES))];
    LSource.x := LListener.x + Next(2 * Units(LRange) - 1) - Units(LRange) + 1;
    LSource.y := LListener.y + Next(2 * Units(LRange) - 1) - Units(LRange) + 1;
    if LRange = 1 then
    begin
      LSource.x := LListener.x;
      LSource.y := LListener.y;
    end;

    LOldVolume := 1000 + LCase;
    LOldSeparation := -1000 - LCase;
    LOldPitch := 128;
    LNewVolume := LOldVolume;
    LNewSeparation := LOldSeparation;

    LOldResult := FOld.S_AdjustSoundParams(@LListener, @LSource, @LOldVolume, @LOldSeparation,
      @LOldPitch);
    case FOld.Game of
      osgDoom: LFull := (FOld.gamemap = 8) and FOld.NeedsCompatibilityMode;
      osgHeretic: LFull := FOld.gamemap = 8;
    else
      LFull := False;
    end;
    LNewResult := TSfxAttenuation.Adjust(FRules, LListener.x, LListener.y,
      LListener.angle + LListener.viewangle, LSource.x, LSource.y, FOld.snd_SfxVolume, LFull,
      LNewVolume, LNewSeparation);

    if (LOldResult <> LNewResult) or (LOldVolume <> LNewVolume) or
      (LOldSeparation <> LNewSeparation) then
    begin
      LWhere := Format('caso %d: gioco %d mappa %d volume %d ascolta (%d,%d) angolo %u suono (%d,%d)',
        [LCase, LGame, FOld.gamemap, FOld.snd_SfxVolume, LListener.x, LListener.y,
         LListener.angle + LListener.viewangle, LSource.x, LSource.y]);
      Assert.AreEqual(LOldResult, LNewResult, 'dovrebbe sentirsi come nel vecchio: ' + LWhere);
      Assert.AreEqual(LOldVolume, LNewVolume, 'dovrebbe avere il volume del vecchio: ' + LWhere);
      Assert.AreEqual(LOldSeparation, LNewSeparation,
        'dovrebbe avere la separazione del vecchio: ' + LWhere);
    end;
  end;
  Assert.Pass;
end;

procedure TTestAudioSfxAttenuation.DovrebbeDareIlPitchDelVecchioCodicePerOgniValore;
var
  LPitch: Integer;
  LRandom: Integer;
begin
  for LPitch := -40 to 300 do
    for LRandom := 0 to 255 do
    begin
      if FOld.PitchSaw(LPitch, LRandom) <> TSfxAttenuation.PerturbPitch(LPitch, LRandom, 15) then
        Assert.Fail(Format('dovrebbe dare il pitch della sega: pitch %d casuale %d',
          [LPitch, LRandom]));
      if FOld.PitchOther(LPitch, LRandom) <> TSfxAttenuation.PerturbPitch(LPitch, LRandom, 31) then
        Assert.Fail(Format('dovrebbe dare il pitch degli altri suoni: pitch %d casuale %d',
          [LPitch, LRandom]));
    end;
  Assert.Pass;
end;

procedure TTestAudioSfxAttenuation.DovrebbeDareCentroEVolumePienoADistanzaZero;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := -1;
  LSeparation := -1;
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, Units(10), Units(20), $40000000, Units(10),
    Units(20), 12, False, LVolume, LSeparation), 'dovrebbe sentirsi');
  Assert.AreEqual(12, LVolume, 'dovrebbe avere il volume del menu');
  Assert.AreEqual(128, LSeparation, 'dovrebbe stare al centro');
end;

procedure TTestAudioSfxAttenuation.DovrebbeDareFalsoConVolumeZeroADistanzaZero;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := -1;
  LSeparation := -1;
  Assert.IsFalse(TSfxAttenuation.Adjust(FRules, 0, 0, 0, 0, 0, 0, False, LVolume, LSeparation),
    'con il volume a zero non dovrebbe sentirsi');
  Assert.AreEqual(0, LVolume, 'dovrebbe comunque scrivere il volume');
  Assert.AreEqual(128, LSeparation, 'dovrebbe comunque scrivere la separazione');
end;

procedure TTestAudioSfxAttenuation.DovrebbeDareFalsoELasciareIValoriSeTroppoLontano;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := 77;
  LSeparation := 99;
  Assert.IsFalse(TSfxAttenuation.Adjust(FRules, 0, 0, 0, Units(1201), 0, 15, False, LVolume,
    LSeparation), 'oltre 1200 unita'' non dovrebbe sentirsi');
  Assert.AreEqual(77, LVolume, 'non dovrebbe toccare il volume');
  Assert.AreEqual(99, LSeparation, 'non dovrebbe toccare la separazione');
end;

procedure TTestAudioSfxAttenuation.DovrebbeDareVolumePienoEntroLaDistanzaVicina;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := 0;
  LSeparation := 0;
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, 0, 0, 0, Units(159), 0, 9, False, LVolume,
    LSeparation), 'dovrebbe sentirsi');
  Assert.AreEqual(9, LVolume, 'entro 160 unita'' il volume dovrebbe essere quello del menu');
end;

procedure TTestAudioSfxAttenuation.DovrebbeAbbassareIlVolumeConLaDistanza;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := 0;
  LSeparation := 0;
  // 680 units: half way between 160 and 1200
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, 0, 0, 0, Units(680), 0, 14, False, LVolume,
    LSeparation), 'dovrebbe sentirsi');
  Assert.AreEqual(7, LVolume, 'a meta'' strada il volume dovrebbe essere la meta''');
  // 1199 units: (15 * 1) div 1040 = 0
  Assert.IsFalse(TSfxAttenuation.Adjust(FRules, 0, 0, 0, Units(1199), 0, 15, False, LVolume,
    LSeparation), 'al bordo il volume scende a zero e non dovrebbe sentirsi');
  Assert.AreEqual(0, LVolume, 'al bordo il volume dovrebbe essere zero');
end;

procedure TTestAudioSfxAttenuation.DovrebbeSpostareASinistraUnSuonoAllaSinistraDiChiAscolta;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := 0;
  LSeparation := 0;
  // the listener looks east (angle 0): north is at its left
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, 0, 0, 0, 0, Units(100), 15, False, LVolume,
    LSeparation), 'dovrebbe sentirsi');
  Assert.IsTrue(LSeparation < 40, 'dovrebbe stare a sinistra: ' + IntToStr(LSeparation));
  Assert.IsTrue(LSeparation >= 32, 'non dovrebbe passare lo swing: ' + IntToStr(LSeparation));
end;

procedure TTestAudioSfxAttenuation.DovrebbeSpostareADestraUnSuonoAllaDestraDiChiAscolta;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := 0;
  LSeparation := 0;
  // the listener looks north ($40000000): east is at its right
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, 0, 0, $40000000, Units(100), 0, 15, False,
    LVolume, LSeparation), 'dovrebbe sentirsi');
  Assert.IsTrue(LSeparation > 216, 'dovrebbe stare a destra: ' + IntToStr(LSeparation));
  Assert.IsTrue(LSeparation <= 224, 'non dovrebbe passare lo swing: ' + IntToStr(LSeparation));
end;

procedure TTestAudioSfxAttenuation.DovrebbeSentireTuttoNelLivelloAVolumePieno;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := 0;
  LSeparation := 0;
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, 0, 0, 0, Units(5000), 0, 10, True, LVolume,
    LSeparation), 'nel livello del boss dovrebbe sentirsi anche da lontano');
  Assert.AreEqual(15, LVolume, 'oltre il limite dovrebbe avere il volume di base');
end;

procedure TTestAudioSfxAttenuation.DovrebbeTenereIlVolumeAlmenoAQuindiciNelLivelloAVolumePieno;
var
  LVolume, LSeparation: Integer;
begin
  LVolume := 0;
  LSeparation := 0;
  // 680 units, menu volume 5: 15 + (5 - 15) * 520 div 1040 = 10
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, 0, 0, 0, Units(680), 0, 5, True, LVolume,
    LSeparation), 'dovrebbe sentirsi');
  Assert.AreEqual(10, LVolume, 'dovrebbe andare da 15 al volume del menu');
  Assert.IsTrue(TSfxAttenuation.Adjust(FRules, 0, 0, 0, Units(100), 0, 5, True, LVolume,
    LSeparation), 'dovrebbe sentirsi');
  Assert.AreEqual(5, LVolume, 'da vicino dovrebbe avere il volume del menu');
end;

procedure TTestAudioSfxAttenuation.DovrebbeCalcolareLaDistanzaApprossimata(AX1, AY1, AX2, AY2,
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TSfxAttenuation.ApproximateDistance(AX1, AY1, AX2, AY2));
end;

procedure TTestAudioSfxAttenuation.DovrebbeTenereIlPitchTraZeroEDuecentocinquantacinque;
begin
  Assert.AreEqual(0, TSfxAttenuation.PerturbPitch(3, 31, 31), 'non dovrebbe scendere sotto zero');
  Assert.AreEqual(255, TSfxAttenuation.PerturbPitch(250, 0, 31), 'non dovrebbe passare 255');
  Assert.AreEqual(128, TSfxAttenuation.PerturbPitch(128, 16, 31), 'il valore di mezzo non lo sposta');
  Assert.AreEqual(136, TSfxAttenuation.PerturbPitch(128, 16, 15), 'la maschera sceglie l''ampiezza');
end;

end.
