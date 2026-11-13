{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - UnitStats, the kills and  }
{  the statistics of a unit, SoldierDeath (what the corpus cannot say)          }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Soldiers;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomSave.UnitEnums, DelphiDoom.XcomMod.UnitStats, DelphiDoom.XcomSave.UnitStats, DelphiDoom.XcomSave.NodeIteration,
  DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomSave.BattleUnitStatistics, DelphiDoom.XcomSave.GameTime,
  DelphiDoom.XcomSave.SoldierDeath;

type
  [TestFixture]
  [Category('xcom-save')]
  TTestXcomSaveSoldiers = class(TObject)
  private
    function Load(const AText: string): IYamlNode;
  public
    [Test]
    procedure DovrebbeSommareESottrarreLeStatistiche;
    [Test]
    procedure DovrebbeSostituireSoloICampiDiversiDaZeroNellaFusione;
    [Test]
    procedure DovrebbeDecodificareLeStatisticheInUnaNuovaStrutturaAZero;
    [Test]
    procedure DovrebbeDareIlPredefinitoSeLeStatisticheNonSonoUnaMappa;
    [Test]
    procedure DovrebbeRendereUniciITurniDelleUccisioni;
    [Test]
    procedure DovrebbeDareITestiDiErroreFuoriDallEnumerazione;
    [Test]
    procedure DovrebbeRichiedereLoStatoDellUccisione;
    [Test]
    procedure DovrebbeTrovareLeVociDuplicateEIlFuocoAmico;
    [Test]
    procedure DovrebbeAggiungereLeUccisioniAQuelleGiaPresenti;
    [Test]
    procedure DovrebbeRifiutareUnaMappaUsataComeSequenza;
    [Test]
    procedure DovrebbeLasciareVuotaLaMorteSenzaCausa;
    [Test]
    procedure DovrebbeTenereUnaCopiaDelTempoDellaMorte;
  end;

implementation

{ TTestXcomSaveSoldiers }

function TTestXcomSaveSoldiers.Load(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

procedure TTestXcomSaveSoldiers.DovrebbeSommareESottrarreLeStatistiche;
var
  LFirst, LSecond, LResult: TXcomUnitStats;
begin
  LFirst := Default(TXcomUnitStats);
  LSecond := Default(TXcomUnitStats);
  LFirst.TimeUnits := 50;
  LFirst.Melee := High(Integer);
  LSecond.TimeUnits := 7;
  LSecond.Melee := 1;
  LResult := LFirst + LSecond;
  Assert.AreEqual(57, LResult.TimeUnits);
  // 32 bit wrap around, like the C++
  Assert.AreEqual(Low(Integer), LResult.Melee);
  LResult := LFirst - LSecond;
  Assert.AreEqual(43, LResult.TimeUnits);
  LResult := -LFirst;
  Assert.AreEqual(-50, LResult.TimeUnits);
end;

procedure TTestXcomSaveSoldiers.DovrebbeSostituireSoloICampiDiversiDaZeroNellaFusione;
var
  LFirst, LSecond: TXcomUnitStats;
begin
  LFirst := Default(TXcomUnitStats);
  LSecond := Default(TXcomUnitStats);
  LFirst.TimeUnits := 50;
  LFirst.Health := 30;
  LSecond.Health := 40;
  LFirst.Merge(LSecond);
  Assert.AreEqual(50, LFirst.TimeUnits);
  Assert.AreEqual(40, LFirst.Health);
end;

procedure TTestXcomSaveSoldiers.DovrebbeDecodificareLeStatisticheInUnaNuovaStrutturaAZero;
var
  LDefault, LStats: TXcomUnitStats;
begin
  LDefault := Default(TXcomUnitStats);
  LDefault.Health := 99;
  LStats := TXcomUnitStatsCodec.Decode(Load('tu: 60'), LDefault);
  Assert.AreEqual(60, LStats.TimeUnits);
  Assert.AreEqual(0, LStats.Health);
end;

procedure TTestXcomSaveSoldiers.DovrebbeDareIlPredefinitoSeLeStatisticheNonSonoUnaMappa;
var
  LDefault, LStats: TXcomUnitStats;
begin
  LDefault := Default(TXcomUnitStats);
  LDefault.Health := 99;
  LStats := TXcomUnitStatsCodec.Decode(Load('[1, 2]'), LDefault);
  Assert.AreEqual(99, LStats.Health);
  LStats := TXcomUnitStatsCodec.Read(Load('other: 1'), 'stats', LDefault);
  Assert.AreEqual(99, LStats.Health);
end;

procedure TTestXcomSaveSoldiers.DovrebbeRendereUniciITurniDelleUccisioni;
var
  LKill: TXcomBattleUnitKills;
begin
  LKill := TXcomBattleUnitKills.Create;
  try
    LKill.Mission := 2;
    LKill.SetTurn(4, XcomFactionHostile);
    Assert.AreEqual(13, LKill.Turn);
    Assert.IsTrue(LKill.HostileTurn);
    Assert.AreEqual(613, LKill.MakeTurnUnique);
  finally
    LKill.Free;
  end;
end;

procedure TTestXcomSaveSoldiers.DovrebbeDareITestiDiErroreFuoriDallEnumerazione;
var
  LKill: TXcomBattleUnitKills;
begin
  LKill := TXcomBattleUnitKills.Create;
  try
    LKill.Status := 99;
    LKill.Faction := -1;
    LKill.Side := 7;
    LKill.BodyPart := 6;
    Assert.AreEqual('status error', LKill.KillStatusString);
    Assert.AreEqual('status error', LKill.UnitStatusString);
    Assert.AreEqual('faction error', LKill.UnitFactionString);
    Assert.AreEqual('side error', LKill.UnitSideString);
    Assert.AreEqual('body part error', LKill.UnitBodyPartString);
    LKill.Status := XcomStatusDead;
    LKill.BodyPart := XcomBodyPartLeftLeg;
    Assert.AreEqual('STR_KILLED', LKill.KillStatusString);
    Assert.AreEqual('BODYPART_LEFTLEG', LKill.UnitBodyPartString);
  finally
    LKill.Free;
  end;
end;

procedure TTestXcomSaveSoldiers.DovrebbeRichiedereLoStatoDellUccisione;
var
  LNode: IYamlNode;
begin
  LNode := Load('faction: 1' + #10 + 'side: 0' + #10 + 'bodypart: 0');
  Assert.WillRaise(
    procedure
    begin
      TXcomBattleUnitKills.Create(LNode).Free;
    end, EYamlInvalidNode);
end;

procedure TTestXcomSaveSoldiers.DovrebbeTrovareLeVociDuplicateEIlFuocoAmico;
var
  LStats: TXcomBattleUnitStatistics;
  LKill: TXcomBattleUnitKills;
begin
  LStats := TXcomBattleUnitStatistics.Create;
  try
    Assert.IsFalse(LStats.HasFriendlyFired);
    LKill := TXcomBattleUnitKills.Create;
    LKill.Id := 4;
    LKill.Status := XcomStatusDead;
    LKill.Faction := XcomFactionPlayer;
    LStats.Kills.Add(LKill);
    Assert.IsTrue(LStats.DuplicateEntry(XcomStatusDead, 4));
    Assert.IsFalse(LStats.DuplicateEntry(XcomStatusUnconscious, 4));
    Assert.IsFalse(LStats.DuplicateEntry(XcomStatusDead, 5));
    Assert.IsTrue(LStats.HasFriendlyFired);
  finally
    LStats.Free;
  end;
end;

procedure TTestXcomSaveSoldiers.DovrebbeAggiungereLeUccisioniAQuelleGiaPresenti;
var
  LStats: TXcomBattleUnitStatistics;
  LNode: IYamlNode;
begin
  LStats := TXcomBattleUnitStatistics.Create;
  try
    LNode := Load('kills:' + #10 + '  - {status: 6, faction: 1, side: 0, bodypart: 0}');
    LStats.Load(LNode);
    LStats.Load(LNode);
    Assert.AreEqual(2, LStats.Kills.Count);
  finally
    LStats.Free;
  end;
end;

procedure TTestXcomSaveSoldiers.DovrebbeRifiutareUnaMappaUsataComeSequenza;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomNodeIteration.Elements(Load('a: 1'));
    end, EYamlInvalidNode);
  Assert.AreEqual<Integer>(0, Length(TXcomNodeIteration.Elements(Load('{}'))));
  Assert.AreEqual<Integer>(0, Length(TXcomNodeIteration.Elements(Load('text'))));
  Assert.AreEqual<Integer>(2, Length(TXcomNodeIteration.Elements(Load('[1, 2]'))));
end;

procedure TTestXcomSaveSoldiers.DovrebbeLasciareVuotaLaMorteSenzaCausa;
var
  LDeath: TXcomSoldierDeath;
begin
  LDeath := TXcomSoldierDeath.Create;
  try
    LDeath.Load(Load('time: {second: 1, minute: 2, hour: 3, weekday: 4, day: 5, month: 6, year: 1999}'));
    Assert.IsNull(LDeath.Cause);
    Assert.AreEqual(1999, LDeath.Time.Year);
    Assert.AreEqual(1, LDeath.Save.Size);
  finally
    LDeath.Free;
  end;
end;

procedure TTestXcomSaveSoldiers.DovrebbeTenereUnaCopiaDelTempoDellaMorte;
var
  LTime: TXcomGameTime;
  LDeath: TXcomSoldierDeath;
begin
  LTime := TXcomGameTime.Create(3, 15, 7, 2001, 10, 20, 30);
  try
    LDeath := TXcomSoldierDeath.Create(LTime, TXcomBattleUnitKills.Create);
    try
      LTime.Free;
      LTime := nil;
      Assert.AreEqual(15, LDeath.Time.Day);
      Assert.IsNotNull(LDeath.Cause);
      Assert.AreEqual(2, LDeath.Save.Size);
    finally
      LDeath.Free;
    end;
  finally
    LTime.Free;
  end;
end;

end.
