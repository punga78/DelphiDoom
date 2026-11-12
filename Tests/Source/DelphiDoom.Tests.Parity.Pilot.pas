{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the automatic pilot               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.Pilot;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Pilot,
  DelphiDoom.Parity.Types;

type
  [TestFixture]
  [Category('parity')]
  TTestParityPilot = class(TObject)
  strict private
    function MovingView(ATic: Integer): TParityPilotView;
    function Run(ASeed: Cardinal; ATics: Integer): TArray<TParityPilotCommand>;
  public
    [Test]
    procedure LoStessoSemeEGliStessiTicDovrebberoDareGliStessiComandi;
    [Test]
    procedure SemiDiversiDovrebberoDareComandiDiversi;
    [Test]
    procedure NonDovrebbeEssereFinitoPrimaDeiTicRichiesti;
    [Test]
    procedure DovrebbeEssereFinitoDopoITicRichiesti;
    [Test]
    procedure IComandiDovrebberoRestareNeiLimitiDelTiccmd;
    [Test]
    procedure LeSterzateDovrebberoEssereMultipliDi256;
    [Test]
    procedure DovrebbeUsareTuttiIComportamenti;
    [Test]
    procedure DovrebbeSparareEUsareNelCorsoDelGioco;
    [Test]
    procedure DovrebbeCambiareArmaOgniTanto;
    [Test]
    procedure ConIlGiocatoreMortoDovrebbeSoloPremereUso;
    [Test]
    procedure SeLaPosizioneNonCambiaDovrebbeGirareSuSeStesso;
  end;

implementation

function TTestParityPilot.MovingView(ATic: Integer): TParityPilotView;
begin
  Result := Default(TParityPilotView);
  Result.Tic := ATic;
  Result.Alive := True;
  // a player that always goes on: never stuck
  Result.X := ATic * 20 * 65536;
  Result.Y := ATic * 7 * 65536;
end;

function TTestParityPilot.Run(ASeed: Cardinal; ATics: Integer): TArray<TParityPilotCommand>;
var
  LPilot: IParityPilot;
  LIndex: Integer;
begin
  LPilot := TParityPilot.Create(ASeed, ATics);
  SetLength(Result, ATics);
  for LIndex := 0 to ATics - 1 do
    Result[LIndex] := LPilot.NextCommand(MovingView(LIndex));
end;

procedure TTestParityPilot.LoStessoSemeEGliStessiTicDovrebberoDareGliStessiComandi;
var
  LFirst: TArray<TParityPilotCommand>;
  LSecond: TArray<TParityPilotCommand>;
  LIndex: Integer;
begin
  LFirst := Run(5, 800);
  LSecond := Run(5, 800);
  for LIndex := 0 to 799 do
  begin
    Assert.AreEqual(LFirst[LIndex].Forward, LSecond[LIndex].Forward);
    Assert.AreEqual(LFirst[LIndex].Side, LSecond[LIndex].Side);
    Assert.AreEqual(LFirst[LIndex].Turn, LSecond[LIndex].Turn);
    Assert.AreEqual(LFirst[LIndex].Fire, LSecond[LIndex].Fire);
    Assert.AreEqual(LFirst[LIndex].Use, LSecond[LIndex].Use);
    Assert.AreEqual(LFirst[LIndex].Weapon, LSecond[LIndex].Weapon);
  end;
end;

procedure TTestParityPilot.SemiDiversiDovrebberoDareComandiDiversi;
var
  LFirst: TArray<TParityPilotCommand>;
  LSecond: TArray<TParityPilotCommand>;
  LIndex: Integer;
  LDifferent: Boolean;
begin
  LFirst := Run(1, 400);
  LSecond := Run(2, 400);
  LDifferent := False;
  for LIndex := 0 to 399 do
    if (LFirst[LIndex].Forward <> LSecond[LIndex].Forward) or (LFirst[LIndex].Turn <> LSecond[LIndex].Turn) then
      LDifferent := True;
  Assert.IsTrue(LDifferent);
end;

procedure TTestParityPilot.NonDovrebbeEssereFinitoPrimaDeiTicRichiesti;
var
  LPilot: IParityPilot;
begin
  LPilot := TParityPilot.Create(1, 100);
  Assert.IsFalse(LPilot.IsFinished(0));
  Assert.IsFalse(LPilot.IsFinished(99));
end;

procedure TTestParityPilot.DovrebbeEssereFinitoDopoITicRichiesti;
var
  LPilot: IParityPilot;
begin
  LPilot := TParityPilot.Create(1, 100);
  Assert.IsTrue(LPilot.IsFinished(100));
  Assert.IsTrue(LPilot.IsFinished(5000));
end;

procedure TTestParityPilot.IComandiDovrebberoRestareNeiLimitiDelTiccmd;
var
  LCommands: TArray<TParityPilotCommand>;
  LCommand: TParityPilotCommand;
begin
  LCommands := Run(31, 3000);
  for LCommand in LCommands do
  begin
    Assert.IsTrue((LCommand.Forward >= -50) and (LCommand.Forward <= 50), 'forward');
    Assert.IsTrue((LCommand.Side >= -40) and (LCommand.Side <= 40), 'side');
    Assert.IsTrue((LCommand.Turn >= -1280) and (LCommand.Turn <= 1280), 'turn');
    Assert.IsTrue((LCommand.Weapon >= 0) and (LCommand.Weapon <= 7), 'weapon');
  end;
end;

procedure TTestParityPilot.LeSterzateDovrebberoEssereMultipliDi256;
var
  LCommands: TArray<TParityPilotCommand>;
  LCommand: TParityPilotCommand;
begin
  LCommands := Run(8, 3000);
  for LCommand in LCommands do
    Assert.AreEqual(0, LCommand.Turn mod 256);
end;

procedure TTestParityPilot.DovrebbeUsareTuttiIComportamenti;
var
  LCommands: TArray<TParityPilotCommand>;
  LCommand: TParityPilotCommand;
  LForward, LBackward, LStrafe, LTurn, LStill: Boolean;
begin
  LForward := False;
  LBackward := False;
  LStrafe := False;
  LTurn := False;
  LStill := False;
  LCommands := Run(3, 4000);
  for LCommand in LCommands do
  begin
    LForward := LForward or (LCommand.Forward > 0);
    LBackward := LBackward or (LCommand.Forward < 0);
    LStrafe := LStrafe or (LCommand.Side <> 0);
    LTurn := LTurn or (LCommand.Turn <> 0);
    LStill := LStill or ((LCommand.Forward = 0) and (LCommand.Side = 0) and (LCommand.Turn = 0));
  end;
  Assert.IsTrue(LForward, 'forward');
  Assert.IsTrue(LBackward, 'backward');
  Assert.IsTrue(LStrafe, 'strafe');
  Assert.IsTrue(LTurn, 'turn');
  Assert.IsTrue(LStill, 'standing');
end;

procedure TTestParityPilot.DovrebbeSparareEUsareNelCorsoDelGioco;
var
  LCommands: TArray<TParityPilotCommand>;
  LCommand: TParityPilotCommand;
  LFire: Integer;
  LUse: Integer;
begin
  LFire := 0;
  LUse := 0;
  LCommands := Run(12, 4000);
  for LCommand in LCommands do
  begin
    if LCommand.Fire then
      Inc(LFire);
    if LCommand.Use then
      Inc(LUse);
  end;
  Assert.IsTrue((LFire > 200) and (LFire < 3800), 'fire ' + IntToStr(LFire));
  Assert.IsTrue((LUse > 100) and (LUse < 2000), 'use ' + IntToStr(LUse));
end;

procedure TTestParityPilot.DovrebbeCambiareArmaOgniTanto;
var
  LCommands: TArray<TParityPilotCommand>;
  LCommand: TParityPilotCommand;
  LChanges: Integer;
begin
  LChanges := 0;
  LCommands := Run(12, 4000);
  for LCommand in LCommands do
    if LCommand.Weapon > 0 then
      Inc(LChanges);
  Assert.IsTrue((LChanges > 3) and (LChanges < 400), IntToStr(LChanges));
end;

procedure TTestParityPilot.ConIlGiocatoreMortoDovrebbeSoloPremereUso;
var
  LPilot: IParityPilot;
  LView: TParityPilotView;
  LCommand: TParityPilotCommand;
  LUses: Integer;
  LIndex: Integer;
begin
  LPilot := TParityPilot.Create(4, 1000);
  LView := Default(TParityPilotView);
  LUses := 0;
  for LIndex := 0 to 99 do
  begin
    LView.Tic := LIndex;
    LCommand := LPilot.NextCommand(LView);
    Assert.AreEqual(0, LCommand.Forward);
    Assert.AreEqual(0, LCommand.Side);
    Assert.AreEqual(0, LCommand.Turn);
    Assert.IsFalse(LCommand.Fire);
    if LCommand.Use then
      Inc(LUses);
  end;
  Assert.IsTrue(LUses > 10, 'use ' + IntToStr(LUses));
end;

procedure TTestParityPilot.SeLaPosizioneNonCambiaDovrebbeGirareSuSeStesso;
var
  LPilot: IParityPilot;
  LView: TParityPilotView;
  LCommand: TParityPilotCommand;
  LIndex: Integer;
  LFullTurns: Integer;
begin
  LPilot := TParityPilot.Create(6, 1000);
  LView := Default(TParityPilotView);
  LView.Alive := True;
  LFullTurns := 0;
  // always at the same place: after some tics the pilot is against a wall and turns away at full speed
  for LIndex := 0 to 299 do
  begin
    LView.Tic := LIndex;
    LCommand := LPilot.NextCommand(LView);
    if Abs(LCommand.Turn) = 1280 then
      Inc(LFullTurns);
  end;
  Assert.IsTrue(LFullTurns >= 10, 'full turns ' + IntToStr(LFullTurns));
end;

end.
