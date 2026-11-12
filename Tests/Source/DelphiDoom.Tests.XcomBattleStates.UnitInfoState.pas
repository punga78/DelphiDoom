{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape states library - the screen   }
{  of the statistics of a unit (TXcomUnitInfoState) over a real saved battle    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.UnitInfoState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Shared.Skip, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattleStates.UnitInfoState,
  DelphiDoom.Tests.XcomBattleStates.BattleWorld;

type
  [TestFixture]
  [Category('XcomBattleStates')]
  TTestXcomUnitInfoState = class
  strict private
    FWorld: TBattleTestWorld;
    function Open(AMindProbe: Boolean = False): TXcomUnitInfoState;
    function Available: Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeMostrareINumeriELeBarreDellUnita;
    [Test]
    procedure DovrebbeScalareLaMiraConLaSalute;
    [Test]
    procedure DovrebbeMostrareLeCorazzeDeiCinqueLati;
    [Test]
    procedure DovrebbeNascondereLeRighePsiSenzaAbilita;
    [Test]
    procedure DovrebbePassareAlSoldatoSuccessivoEPrecedente;
    [Test]
    procedure DovrebbeNonAvereIPulsantiConLaSondaMentale;
    [Test]
    procedure DovrebbeChiudersiConUnClic;
    [Test]
    procedure DovrebbeChiudersiColPulsanteDestro;
    [Test]
    procedure DovrebbeChiudersiColTastoAnnulla;
  end;

implementation

procedure TTestXcomUnitInfoState.Setup;
begin
  FWorld := TBattleTestWorld.TryCreate;
end;

procedure TTestXcomUnitInfoState.TearDown;
begin
  FWorld.Free;
end;

function TTestXcomUnitInfoState.Available: Boolean;
begin
  Result := Assigned(FWorld);
  if not Result then
    TTestSkip.Ignore('The data of the real game are not on this machine');
end;

function TTestXcomUnitInfoState.Open(AMindProbe: Boolean): TXcomUnitInfoState;
begin
  Result := FWorld.Parent.Screens.UnitInfo(FWorld.Parent, FWorld.Battle.SelectedUnit, False,
    AMindProbe) as TXcomUnitInfoState;
  FWorld.World.Game.PushState(Result);
  FWorld.World.Wait(40);
end;

procedure TTestXcomUnitInfoState.DovrebbeMostrareINumeriELeBarreDellUnita;
var
  LState: TXcomUnitInfoState;
  LUnit: TXcomBattleUnit;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LState := Open;
  LUnit := FWorld.Battle.SelectedUnit;
  Assert.AreSame(LUnit, LState.CurrentUnit);
  Assert.AreEqual(IntToStr(LUnit.TimeUnits), LState.Numbers[uirTimeUnits].GetText);
  Assert.AreEqual(Double(LUnit.Stats.TimeUnits), LState.Bars[uirTimeUnits].GetMax, 0.001);
  Assert.AreEqual(Double(LUnit.TimeUnits), LState.Bars[uirTimeUnits].GetValue, 0.001);
  Assert.AreEqual(IntToStr(LUnit.Energy), LState.Numbers[uirEnergy].GetText);
  Assert.AreEqual(Double(LUnit.Stats.Stamina), LState.Bars[uirEnergy].GetMax, 0.001);
  Assert.AreEqual(IntToStr(LUnit.Health), LState.Numbers[uirHealth].GetText);
  Assert.AreEqual(Double(LUnit.StunLevel), LState.Bars[uirHealth].GetValue2, 0.001);
  Assert.AreEqual(IntToStr(LUnit.GetFatalWounds), LState.Numbers[uirFatalWounds].GetText);
  Assert.AreEqual(IntToStr(LUnit.Stats.Bravery), LState.Numbers[uirBravery].GetText);
  Assert.AreEqual(IntToStr(LUnit.Morale), LState.Numbers[uirMorale].GetText);
  Assert.AreEqual(Double(100), LState.Bars[uirMorale].GetMax, 0.001);
  Assert.AreEqual(IntToStr(LUnit.Stats.Reactions), LState.Numbers[uirReactions].GetText);
  Assert.AreEqual(IntToStr(LUnit.Stats.Strength), LState.Numbers[uirStrength].GetText);
  Assert.IsTrue(LState.TxtName.GetText <> '', 'the name of the unit');
end;

procedure TTestXcomUnitInfoState.DovrebbeScalareLaMiraConLaSalute;
var
  LState: TXcomUnitInfoState;
  LUnit: TXcomBattleUnit;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LState := Open;
  LUnit := FWorld.Battle.SelectedUnit;
  Assert.AreEqual(IntToStr((LUnit.Stats.Firing * LUnit.Health) div LUnit.Stats.Health),
    LState.Numbers[uirFiring].GetText);
  Assert.AreEqual(Double(LUnit.Stats.Firing), LState.Bars[uirFiring].GetMax, 0.001);
  Assert.AreEqual(IntToStr((LUnit.Stats.Throwing * LUnit.Health) div LUnit.Stats.Health),
    LState.Numbers[uirThrowing].GetText);
  Assert.AreEqual(IntToStr((LUnit.Stats.Melee * LUnit.Health) div LUnit.Stats.Health),
    LState.Numbers[uirMelee].GetText);
end;

procedure TTestXcomUnitInfoState.DovrebbeMostrareLeCorazzeDeiCinqueLati;
const
  ROWS: array[SIDE_FRONT..SIDE_UNDER] of TXcomUnitInfoRow = (uirFrontArmor, uirLeftArmor, uirRightArmor,
    uirRearArmor, uirUnderArmor);
var
  LState: TXcomUnitInfoState;
  LUnit: TXcomBattleUnit;
  LSide: Integer;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LState := Open;
  LUnit := FWorld.Battle.SelectedUnit;
  for LSide := SIDE_FRONT to SIDE_UNDER do
  begin
    Assert.AreEqual(IntToStr(LUnit.GetArmor(LSide)), LState.Numbers[ROWS[LSide]].GetText);
    Assert.AreEqual(Double(LUnit.GetMaxArmor(LSide)), LState.Bars[ROWS[LSide]].GetMax, 0.001);
    Assert.AreEqual(Double(LUnit.GetArmor(LSide)), LState.Bars[ROWS[LSide]].GetValue, 0.001);
  end;
end;

procedure TTestXcomUnitInfoState.DovrebbeNascondereLeRighePsiSenzaAbilita;
var
  LState: TXcomUnitInfoState;
  LSkilled: Boolean;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LState := Open;
  // psiStrengthEval is off: both rows follow the psionic skill of the unit
  LSkilled := FWorld.Battle.SelectedUnit.Stats.PsiSkill > 0;
  Assert.AreEqual(LSkilled, LState.RowLabels[uirPsiSkill].Visible);
  Assert.AreEqual(LSkilled, LState.Numbers[uirPsiSkill].Visible);
  Assert.AreEqual(LSkilled, LState.Bars[uirPsiSkill].Visible);
  Assert.AreEqual(LSkilled, LState.RowLabels[uirPsiStrength].Visible);
  Assert.AreEqual(LSkilled, LState.Bars[uirPsiStrength].Visible);
end;

procedure TTestXcomUnitInfoState.DovrebbePassareAlSoldatoSuccessivoEPrecedente;
var
  LState: TXcomUnitInfoState;
  LFirst: TXcomBattleUnit;
  LNext: TXcomBattleUnit;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LState := Open;
  LFirst := LState.CurrentUnit;
  FWorld.ClickButton(310, 10, XCOM_BUTTON_LEFT);
  LNext := LState.CurrentUnit;
  Assert.AreNotSame(LFirst, LNext, 'the next soldier');
  Assert.AreSame(FWorld.Battle.SelectedUnit, LNext);
  Assert.AreEqual(IntToStr(LNext.TimeUnits), LState.Numbers[uirTimeUnits].GetText);
  Assert.IsTrue(FWorld.World.Game.IsState(LState), 'the screen stays open');
  FWorld.ClickButton(8, 10, XCOM_BUTTON_LEFT);
  Assert.AreSame(LFirst, LState.CurrentUnit, 'back to the first soldier');
end;

procedure TTestXcomUnitInfoState.DovrebbeNonAvereIPulsantiConLaSondaMentale;
var
  LState: TXcomUnitInfoState;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  LState := Open(True);
  Assert.IsNull(LState.BtnPrev);
  Assert.IsNull(LState.BtnNext);
end;

procedure TTestXcomUnitInfoState.DovrebbeChiudersiConUnClic;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  Open;
  FWorld.ClickButton(160, 100, XCOM_BUTTON_LEFT);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
end;

procedure TTestXcomUnitInfoState.DovrebbeChiudersiColPulsanteDestro;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  Open;
  // on the row of the name, where the surface of the exit does not reach
  FWorld.ClickButton(160, 10, XCOM_BUTTON_RIGHT);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
end;

procedure TTestXcomUnitInfoState.DovrebbeChiudersiColTastoAnnulla;
begin
  if not Available then
    TTestSkip.Ignore('the data of the game is not on this machine');
  Open;
  FWorld.PressKey(FWorld.World.Game.Options.KeyCancel);
  Assert.IsTrue(FWorld.World.Game.IsState(FWorld.Parent));
end;

end.
