{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the radix library - the debriefing                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.Debriefing;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Radix.Debriefing;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixDebriefing = class(TObject)
  strict private
    FInput: TRadixDebriefingInput;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure UnLivelloSenzaNienteDaMisurareDovrebbeDareVotiPieni;
    [Test]
    procedure LObiettivoSecondarioNonRaggiuntoDovrebbeValereZero;
    [Test]
    procedure LObiettivoSecondarioRaggiuntoDovrebbeValereIlPieno;
    [Test]
    procedure IlRapportoDelleUccisioniDovrebbeEssereLaFrazioneDeiNemici;
    [Test]
    procedure IlTempoEntroIlParDovrebbeValereIlPieno;
    [Test]
    procedure IlTempoOltreIlParDovrebbeValereParDivisoTempo;
    [Test]
    procedure ISegretiDovrebberoEssereLaFrazioneDiQuelliTrovati;
    [Test]
    procedure GliUrtiDovrebberoTogliereLaLoroParteDelTempoPar;
    [Test]
    procedure GliUrtiPiuLunghiDelParNonDovrebberoDareUnVotoNegativo;
    [Test]
    procedure LaMediaDovrebbeEssereLaMediaDeiCinqueVoti;
    [Test]
    [TestCase('zero', '0,00:00:00')]
    [TestCase('un minuto e cinque', '65,00:01:05')]
    [TestCase('piu di un ora', '3725,01:02:05')]
    [TestCase('negativo', '-4,00:00:00')]
    procedure IlTempoDovrebbeEssereScrittoInOreMinutiSecondi(ASeconds: Integer; const AExpected: string);
    [Test]
    procedure LaPercentualeDovrebbeEssereDiTreCaratteri;
    [Test]
    procedure IlTestoDellObiettivoSecondarioDovrebbeDireITreCasi;
  end;

implementation

procedure TTestRadixDebriefing.Setup;
begin
  FInput := Default(TRadixDebriefingInput);
end;

procedure TTestRadixDebriefing.UnLivelloSenzaNienteDaMisurareDovrebbeDareVotiPieni;
var
  LScore: TRadixDebriefingScore;
begin
  LScore := TRadixDebriefing.Score(FInput);
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, LScore.Secondary);
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, LScore.KillRatio);
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, LScore.FlyingTime);
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, LScore.Secrets);
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, LScore.ProficientFlying);
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, LScore.Mean);
end;

procedure TTestRadixDebriefing.LObiettivoSecondarioNonRaggiuntoDovrebbeValereZero;
begin
  FInput.HasSecondaryObjective := True;
  Assert.AreEqual(0, TRadixDebriefing.Score(FInput).Secondary);
end;

procedure TTestRadixDebriefing.LObiettivoSecondarioRaggiuntoDovrebbeValereIlPieno;
begin
  FInput.HasSecondaryObjective := True;
  FInput.SecondaryObjectiveDone := True;
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, TRadixDebriefing.Score(FInput).Secondary);
end;

procedure TTestRadixDebriefing.IlRapportoDelleUccisioniDovrebbeEssereLaFrazioneDeiNemici;
begin
  FInput.Kills := 8;
  FInput.MaxKills := 32;
  Assert.AreEqual(16384, TRadixDebriefing.Score(FInput).KillRatio);
end;

procedure TTestRadixDebriefing.IlTempoEntroIlParDovrebbeValereIlPieno;
begin
  FInput.Tics := 1000;
  FInput.ParTics := 1000;
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, TRadixDebriefing.Score(FInput).FlyingTime);
end;

procedure TTestRadixDebriefing.IlTempoOltreIlParDovrebbeValereParDivisoTempo;
begin
  FInput.Tics := 4000;
  FInput.ParTics := 1000;
  Assert.AreEqual(16384, TRadixDebriefing.Score(FInput).FlyingTime);
  // a level without par time
  FInput.ParTics := 0;
  Assert.AreEqual(0, TRadixDebriefing.Score(FInput).FlyingTime);
end;

procedure TTestRadixDebriefing.ISegretiDovrebberoEssereLaFrazioneDiQuelliTrovati;
begin
  FInput.Secrets := 1;
  FInput.MaxSecrets := 2;
  Assert.AreEqual(32768, TRadixDebriefing.Score(FInput).Secrets);
end;

procedure TTestRadixDebriefing.GliUrtiDovrebberoTogliereLaLoroParteDelTempoPar;
begin
  // 10 seconds against the walls in a level of 40 seconds of par: a quarter less
  FInput.WallHitTics := 350;
  FInput.ParTics := 1400;
  Assert.AreEqual(49152, TRadixDebriefing.Score(FInput).ProficientFlying);
  // less than a second does not count
  FInput.WallHitTics := 34;
  Assert.AreEqual(TRadixDebriefing.FULL_MARK, TRadixDebriefing.Score(FInput).ProficientFlying);
end;

procedure TTestRadixDebriefing.GliUrtiPiuLunghiDelParNonDovrebberoDareUnVotoNegativo;
begin
  FInput.WallHitTics := 7000;
  FInput.ParTics := 1400;
  Assert.AreEqual(0, TRadixDebriefing.Score(FInput).ProficientFlying);
end;

procedure TTestRadixDebriefing.LaMediaDovrebbeEssereLaMediaDeiCinqueVoti;
var
  LScore: TRadixDebriefingScore;
begin
  LScore.Secondary := 65536;
  LScore.KillRatio := 32768;
  LScore.FlyingTime := 0;
  LScore.Secrets := 65536;
  LScore.ProficientFlying := 65536;
  Assert.AreEqual(45875, LScore.Mean);
end;

procedure TTestRadixDebriefing.IlTempoDovrebbeEssereScrittoInOreMinutiSecondi(ASeconds: Integer;
  const AExpected: string);
begin
  Assert.AreEqual(AExpected, TRadixDebriefing.TimeText(ASeconds));
end;

procedure TTestRadixDebriefing.LaPercentualeDovrebbeEssereDiTreCaratteri;
begin
  Assert.AreEqual('100', TRadixDebriefing.PercentText(65536));
  Assert.AreEqual(' 25', TRadixDebriefing.PercentText(16384));
  Assert.AreEqual('  0', TRadixDebriefing.PercentText(0));
  Assert.AreEqual(' 69', TRadixDebriefing.PercentText(45875));
  Assert.AreEqual('  7', TRadixDebriefing.CountText(7));
  Assert.AreEqual('132', TRadixDebriefing.CountText(132));
end;

procedure TTestRadixDebriefing.IlTestoDellObiettivoSecondarioDovrebbeDireITreCasi;
begin
  Assert.AreEqual('NOT APPLICABLE', TRadixDebriefing.SecondaryText(FInput));
  FInput.HasSecondaryObjective := True;
  Assert.AreEqual('INCOMPLETE', TRadixDebriefing.SecondaryText(FInput));
  FInput.SecondaryObjectiveDone := True;
  Assert.AreEqual('COMPLETE', TRadixDebriefing.SecondaryText(FInput));
end;

end.
