{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the arithmetic of the teleports                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.TeleportGeometry;

// The old formulas are written in the tests as they were in p_telept.pas and udmf_telept.pas,
// with wrapping arithmetic as in the engine
{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersTeleportGeometry = class(TObject)
  public
    [Test]
    procedure DovrebbePorreLaNebbiaVentiUnitaAvantiNellaDirezioneDellUscita;
    [Test]
    procedure DovrebbeAlzareLaNebbiaSoloSeNonEUnMissile;
    [Test]
    procedure DovrebbeDareLaStessaNebbiaDelVecchioCodice;
    [Test]
    procedure DovrebbeDareLaQuantitaDiMotoDelMissileDelVecchioCodice;
    [Test]
    procedure DovrebbeGirareLaQuantitaDiMotoComeFaceva;
    [Test]
    procedure DovrebbeDareLaStessaRotazioneDelleTabelle;
    [Test]
    procedure DovrebbeSommareUnQuartoDiGiroALAngoloDellUscitaSilenziosa;
    [Test]
    procedure DovrebbeScegliereLaDestinazioneConUnSoloNumeroCasuale;
    [Test]
    procedure DovrebbeDareLaStessaDestinazioneDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.Intf, DelphiDoom.MathCore.FixedMath,
  DelphiDoom.MathCore.Trigonometry, DelphiDoom.Thinkers.Teleport.Geometry,
  DelphiDoom.Tests.Thinkers.Fakes;

const
  FRACUNIT = 65536;

var
  GSeed: Cardinal;

function NextValue: Cardinal;
begin
  GSeed := GSeed * 1664525 + 1013904223;
  Result := GSeed;
end;

{ TTestThinkersTeleportGeometry }

procedure TTestThinkersTeleportGeometry.DovrebbePorreLaNebbiaVentiUnitaAvantiNellaDirezioneDellUscita;
begin
  // the tables of Doom are sampled half a step after the angle, so the values are read from them
  Assert.AreEqual(100 * FRACUNIT + 20 * TTrigonometry.FineCosine(0),
    TTeleportGeometry.FogX(100 * FRACUNIT, 0));
  Assert.AreEqual(50 * FRACUNIT + 20 * TTrigonometry.FineSine(0),
    TTeleportGeometry.FogY(50 * FRACUNIT, 0));
  // a quarter of a turn: the other way round
  Assert.AreEqual(100 * FRACUNIT + 20 * TTrigonometry.FineCosine(2048),
    TTeleportGeometry.FogX(100 * FRACUNIT, ANG90));
  Assert.AreEqual(50 * FRACUNIT + 20 * TTrigonometry.FineSine(2048),
    TTeleportGeometry.FogY(50 * FRACUNIT, ANG90));
  Assert.IsTrue(TTeleportGeometry.FogX(0, 0) > 19 * FRACUNIT, 'forward is along x at angle 0');
  Assert.IsTrue(TTeleportGeometry.FogY(0, ANG90) > 19 * FRACUNIT, 'forward is along y at 90 degrees');
end;

procedure TTestThinkersTeleportGeometry.DovrebbeAlzareLaNebbiaSoloSeNonEUnMissile;
begin
  Assert.AreEqual(0, TTeleportGeometry.FogHeight(True));
  Assert.AreEqual(32 * FRACUNIT, TTeleportGeometry.FogHeight(False));
end;

procedure TTestThinkersTeleportGeometry.DovrebbeDareLaStessaNebbiaDelVecchioCodice;
var
  LIndex: Integer;
  LX, LY: Integer;
  LAngle: Cardinal;
  LAn: Cardinal;
begin
  GSeed := 7;
  for LIndex := 1 to 20000 do
  begin
    LX := Integer(NextValue);
    LY := Integer(NextValue);
    LAngle := NextValue;
    LAn := LAngle shr ANGLETOFINESHIFT;
    Assert.AreEqual(LX + 20 * TTrigonometry.FineCosine(LAn), TTeleportGeometry.FogX(LX, LAngle));
    Assert.AreEqual(LY + 20 * TTrigonometry.FineSine(LAn), TTeleportGeometry.FogY(LY, LAngle));
  end;
end;

procedure TTestThinkersTeleportGeometry.DovrebbeDareLaQuantitaDiMotoDelMissileDelVecchioCodice;
var
  LIndex: Integer;
  LSpeed: Integer;
  LAngle: Cardinal;
  LAn: Cardinal;
begin
  GSeed := 11;
  for LIndex := 1 to 20000 do
  begin
    LSpeed := Integer(NextValue) shr 6;
    LAngle := NextValue;
    LAn := LAngle shr ANGLETOFINESHIFT;
    Assert.AreEqual(TFixedMath.Mul(LSpeed, TTrigonometry.FineCosine(LAn)),
      TTeleportGeometry.MissileMomentumX(LSpeed, LAngle));
    Assert.AreEqual(TFixedMath.Mul(LSpeed, TTrigonometry.FineSine(LAn)),
      TTeleportGeometry.MissileMomentumY(LSpeed, LAngle));
  end;
end;

procedure TTestThinkersTeleportGeometry.DovrebbeGirareLaQuantitaDiMotoComeFaceva;
var
  LIndex: Integer;
  LMomX, LMomY, LSine, LCosine: Integer;
begin
  GSeed := 13;
  for LIndex := 1 to 20000 do
  begin
    LMomX := Integer(NextValue) shr 8;
    LMomY := Integer(NextValue) shr 8;
    LSine := TTeleportGeometry.SineOf(NextValue);
    LCosine := TTeleportGeometry.CosineOf(NextValue);
    Assert.AreEqual(TFixedMath.Mul(LMomX, LCosine) - TFixedMath.Mul(LMomY, LSine),
      TTeleportGeometry.RotatedMomentumX(LMomX, LMomY, LSine, LCosine));
    Assert.AreEqual(TFixedMath.Mul(LMomY, LCosine) + TFixedMath.Mul(LMomX, LSine),
      TTeleportGeometry.RotatedMomentumY(LMomX, LMomY, LSine, LCosine));
  end;
end;

procedure TTestThinkersTeleportGeometry.DovrebbeDareLaStessaRotazioneDelleTabelle;
begin
  Assert.AreEqual(TTrigonometry.FineSine(1000), TTeleportGeometry.SineOf(1000 shl ANGLETOFINESHIFT));
  Assert.AreEqual(TTrigonometry.FineCosine(1000),
    TTeleportGeometry.CosineOf(1000 shl ANGLETOFINESHIFT));
  Assert.AreEqual(0, TTeleportGeometry.RotatedMomentumX(0, 0, 123, 456));
  Assert.AreEqual(0, TTeleportGeometry.RotatedMomentumY(0, 0, 123, 456));
end;

procedure TTestThinkersTeleportGeometry.DovrebbeSommareUnQuartoDiGiroALAngoloDellUscitaSilenziosa;
var
  LIndex: Integer;
  LLine, LExit: Cardinal;
begin
  Assert.AreEqual(Cardinal(ANG90), TTeleportGeometry.SilentExitAngle(0, 0));
  GSeed := 17;
  for LIndex := 1 to 2000 do
  begin
    LLine := NextValue;
    LExit := NextValue;
    Assert.AreEqual(Cardinal(LLine - LExit + ANG90), TTeleportGeometry.SilentExitAngle(LLine, LExit));
  end;
end;

procedure TTestThinkersTeleportGeometry.DovrebbeScegliereLaDestinazioneConUnSoloNumeroCasuale;
var
  LRandom: IGameRandom;
  LChoice: Integer;
begin
  LRandom := CreateTestRandom(30);
  LChoice := TTeleportGeometry.PickDestination(5, LRandom);
  Assert.IsTrue((LChoice >= 1) and (LChoice <= 5));
  Assert.AreEqual(31, LRandom.PlayIndex);
  Assert.AreEqual(1, TTeleportGeometry.PickDestination(1, LRandom));
end;

procedure TTestThinkersTeleportGeometry.DovrebbeDareLaStessaDestinazioneDelVecchioCodice;
var
  LOld, LNew: IGameRandom;
  LIndex, LCount: Integer;
begin
  LOld := CreateTestRandom(3);
  LNew := CreateTestRandom(3);
  for LIndex := 1 to 3000 do
  begin
    LCount := 1 + LIndex mod 9;
    Assert.AreEqual(1 + (LOld.NextPlay mod LCount), TTeleportGeometry.PickDestination(LCount, LNew));
  end;
  Assert.AreEqual(LOld.PlayIndex, LNew.PlayIndex);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersTeleportGeometry);

end.
