{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the elementary actions of the bots (be_ea.c)           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Ea;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi.Ea')]
  TTestBotElementaryActions = class
  public
    [Test]
    procedure DovrebbeInviareICommandiDiTestoAlGioco;
    [Test]
    procedure DovrebbeImpostareIFlagDelleAzioniSemplici;
    [Test]
    procedure DovrebbeImpostareIFlagDelMovimento;
    [Test]
    procedure DovrebbeSaltareSoloSeNonHaSaltatoNelFotogrammaPrecedente;
    [Test]
    procedure DovrebbeSaltareInRitardoSoloSeNonHaSaltatoNelFotogrammaPrecedente;
    [Test]
    procedure DovrebbeLimitareLaVelocita;
    [Test]
    procedure DovrebbeRicordareArmaEDirezioneDellosguardo;
    [Test]
    procedure DovrebbeAzzerareGliIngressiRicordandoIlSalto;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIlClienteEFuoriTabella;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Exceptions, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.BotAi.Ea.Types, DelphiDoom.BotAi.Ea.Intf, DelphiDoom.BotAi.Ea.Actions;

type
  TCommandLog = class(TInterfacedObject, IBotImport)
  strict private
    FLines: TStringList;
  public
    constructor Create(const ALines: TStringList);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

constructor TCommandLog.Create(const ALines: TStringList);
begin
  inherited Create;
  FLines := ALines;
end;

procedure TCommandLog.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
end;

procedure TCommandLog.LogWrite(const AMessage: AnsiString);
begin
end;

function TCommandLog.Time: Single;
begin
  Result := 0;
end;

procedure TCommandLog.Command(const AClient: Integer; const ACommand: AnsiString);
begin
  FLines.Add(IntToStr(AClient) + ':' + string(ACommand));
end;

function Vec(const X, Y, Z: Single): TVec3;
begin
  Result[0] := X;
  Result[1] := Y;
  Result[2] := Z;
end;

{ TTestBotElementaryActions }

procedure TTestBotElementaryActions.DovrebbeInviareICommandiDiTestoAlGioco;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 4);
    LActions.Say(1, 'ciao');
    LActions.SayTeam(1, 'squadra');
    LActions.Tell(2, 3, 'sotto voce');
    LActions.UseItem(0, 'medkit');
    LActions.DropItem(0, 'flag');
    LActions.UseInv(0, 'teleporter');
    LActions.DropInv(0, 'holdable');
    LActions.Command(3, 'kill');
    LLines.Delimiter := '|';
    LLines.QuoteChar := '"';
    LLines.StrictDelimiter := True;
    Assert.AreEqual('1:say ciao|1:say_team squadra|2:tell 3, sotto voce|0:use medkit|0:drop flag|' +
      '0:invuse teleporter|0:invdrop holdable|3:kill', LLines.DelimitedText.Replace('"', ''), 'comandi');
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeImpostareIFlagDelleAzioniSemplici;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 2);
    LActions.Gesture(0);
    LActions.Attack(0);
    LActions.Talk(0);
    LActions.Use(0);
    LActions.Respawn(0);
    LActions.Crouch(0);
    LActions.Walk(0);
    Assert.AreEqual(ACTION_GESTURE or ACTION_ATTACK or ACTION_TALK or ACTION_USE or ACTION_RESPAWN or ACTION_CROUCH or
      ACTION_WALK, LActions.GetInput(0, 0.5).ActionFlags);
    Assert.AreEqual(0, LActions.GetInput(1, 0.5).ActionFlags, 'l''altro cliente non cambia');
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeImpostareIFlagDelMovimento;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 1);
    LActions.MoveUp(0);
    LActions.MoveDown(0);
    LActions.MoveForward(0);
    LActions.MoveBack(0);
    LActions.MoveLeft(0);
    LActions.MoveRight(0);
    Assert.AreEqual(ACTION_MOVEUP or ACTION_MOVEDOWN or ACTION_MOVEFORWARD or ACTION_MOVEBACK or ACTION_MOVELEFT or
      ACTION_MOVERIGHT, LActions.GetInput(0, 0).ActionFlags);
    LActions.Action(0, ACTION_ATTACK);
    Assert.IsTrue((LActions.GetInput(0, 0).ActionFlags and ACTION_ATTACK) <> 0);
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeSaltareSoloSeNonHaSaltatoNelFotogrammaPrecedente;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 1);
    LActions.Jump(0);
    Assert.IsTrue((LActions.GetInput(0, 0).ActionFlags and ACTION_JUMP) <> 0, 'salta');
    // ResetInput remembers the jump: in the next frame it must be released
    LActions.ResetInput(0);
    Assert.IsTrue((LActions.GetInput(0, 0).ActionFlags and ACTION_JUMPEDLASTFRAME) <> 0, 'ricorda il salto');
    LActions.Jump(0);
    Assert.AreEqual(0, LActions.GetInput(0, 0).ActionFlags and ACTION_JUMP, 'non salta due volte');
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeSaltareInRitardoSoloSeNonHaSaltatoNelFotogrammaPrecedente;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 1);
    LActions.DelayedJump(0);
    Assert.IsTrue((LActions.GetInput(0, 0).ActionFlags and ACTION_DELAYEDJUMP) <> 0, 'salto ritardato');
    LActions.Jump(0);
    LActions.ResetInput(0);
    LActions.DelayedJump(0);
    Assert.AreEqual(0, LActions.GetInput(0, 0).ActionFlags and ACTION_DELAYEDJUMP, 'non lo ripete');
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeLimitareLaVelocita;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 1);
    LActions.Move(0, Vec(1, 0, 0), 1000);
    Assert.AreEqual(Single(MAX_USERMOVE), LActions.GetInput(0, 0).Speed, 'in alto');
    LActions.Move(0, Vec(0, 1, 0), -1000);
    Assert.AreEqual(Single(-MAX_USERMOVE), LActions.GetInput(0, 0).Speed, 'in basso');
    LActions.Move(0, Vec(0, 0, 1), 10);
    Assert.AreEqual(Single(10), LActions.GetInput(0, 0).Speed, 'invariata');
    Assert.AreEqual(Single(1), LActions.GetInput(0, 0).Dir[2]);
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeRicordareArmaEDirezioneDellosguardo;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
  LInput: TBotInput;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 1);
    LActions.SelectWeapon(0, 7);
    LActions.View(0, Vec(10, 20, 30));
    LInput := LActions.GetInput(0, 0.25);
    Assert.AreEqual(7, LInput.Weapon);
    Assert.AreEqual(Single(20), LInput.ViewAngles[1]);
    Assert.AreEqual(Single(0.25), LInput.ThinkTime);
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeAzzerareGliIngressiRicordandoIlSalto;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
  LInput: TBotInput;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 1);
    LActions.Attack(0);
    LActions.Move(0, Vec(1, 1, 1), 50);
    LActions.ResetInput(0);
    LInput := LActions.GetInput(0, 0);
    Assert.AreEqual(0, LInput.ActionFlags, 'nessun salto: nessun flag');
    Assert.AreEqual(Single(0), LInput.Speed);
    Assert.AreEqual(Single(0), LInput.Dir[1]);
    LActions.Jump(0);
    LActions.ResetInput(0);
    Assert.AreEqual(ACTION_JUMPEDLASTFRAME, LActions.GetInput(0, 0).ActionFlags);
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

procedure TTestBotElementaryActions.DovrebbeSollevareEccezioneSeIlClienteEFuoriTabella;
var
  LLines: TStringList;
  LActions: IBotElementaryActions;
begin
  LLines := TStringList.Create;
  try
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 2);
    Assert.WillRaise(procedure begin LActions.Attack(2); end, EBotAiException);
    Assert.WillRaise(procedure begin LActions.Jump(-1); end, EBotAiException);
    Assert.WillRaise(procedure begin LActions.GetInput(5, 0); end, EBotAiException);
    LActions := TBotElementaryActions.Create(TCommandLog.Create(LLines), 0);
    Assert.WillRaise(procedure begin LActions.Attack(0); end, EBotAiException, 'nessun cliente');
  finally
    LActions := nil;
    LLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBotElementaryActions);

end.
