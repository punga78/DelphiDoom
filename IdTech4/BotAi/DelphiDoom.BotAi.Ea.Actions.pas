{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotElementaryActions, the elementary actions          }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\botlib\        }
{  be_ea.c. Based on the Quake III Arena GPL Source Code (id Software).        }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Ea.Actions;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Ea.Types, DelphiDoom.BotAi.Ea.Intf;

type
  /// <summary>
  ///   <c>botinputs</c> (one bot_input_t for each client, made by EA_Setup) is a field. The original does not check
  ///   the client number; here a number outside the table is an <c>EBotAiException</c> (the original writes outside
  ///   its memory). <c>EA_EndRegular</c> is empty in the original and is not ported.
  /// </summary>
  TBotElementaryActions = class(TInterfacedObject, IBotElementaryActions)
  strict private
    FImport: IBotImport;
    FInputs: TArray<TBotInput>;
    procedure CheckClient(const AClient: Integer);
  public
    /// <summary>EA_Setup: the inputs of AMaxClients clients, all zero</summary>
    constructor Create(const AImport: IBotImport; const AMaxClients: Integer);
    procedure Say(const AClient: Integer; const AText: AnsiString);
    procedure SayTeam(const AClient: Integer; const AText: AnsiString);
    procedure Tell(const AClient, AClientTo: Integer; const AText: AnsiString);
    procedure UseItem(const AClient: Integer; const AItem: AnsiString);
    procedure DropItem(const AClient: Integer; const AItem: AnsiString);
    procedure UseInv(const AClient: Integer; const AInventory: AnsiString);
    procedure DropInv(const AClient: Integer; const AInventory: AnsiString);
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
    procedure Gesture(const AClient: Integer);
    procedure SelectWeapon(const AClient, AWeapon: Integer);
    procedure Attack(const AClient: Integer);
    procedure Talk(const AClient: Integer);
    procedure Use(const AClient: Integer);
    procedure Respawn(const AClient: Integer);
    procedure Jump(const AClient: Integer);
    procedure DelayedJump(const AClient: Integer);
    procedure Crouch(const AClient: Integer);
    procedure Walk(const AClient: Integer);
    procedure Action(const AClient, AAction: Integer);
    procedure MoveUp(const AClient: Integer);
    procedure MoveDown(const AClient: Integer);
    procedure MoveForward(const AClient: Integer);
    procedure MoveBack(const AClient: Integer);
    procedure MoveLeft(const AClient: Integer);
    procedure MoveRight(const AClient: Integer);
    procedure Move(const AClient: Integer; const ADir: TVec3; const ASpeed: Single);
    procedure View(const AClient: Integer; const AViewAngles: TVec3);
    function GetInput(const AClient: Integer; const AThinkTime: Single): TBotInput;
    procedure ResetInput(const AClient: Integer);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Exceptions, DelphiDoom.BotAi.Text.CFormat;

resourcestring
  SClientOutOfRange = 'The elementary actions have no input for the client %d';

{ TBotElementaryActions }

constructor TBotElementaryActions.Create(const AImport: IBotImport; const AMaxClients: Integer);
begin
  inherited Create;
  FImport := AImport;
  if AMaxClients > 0 then
    SetLength(FInputs, AMaxClients);
end;

procedure TBotElementaryActions.CheckClient(const AClient: Integer);
begin
  if (AClient < 0) or (AClient >= Length(FInputs)) then
    raise EBotAiException.CreateFmt(SClientOutOfRange, [AClient]);
end;

procedure TBotElementaryActions.Say(const AClient: Integer; const AText: AnsiString);
begin
  FImport.Command(AClient, 'say ' + AText);
end;

procedure TBotElementaryActions.SayTeam(const AClient: Integer; const AText: AnsiString);
begin
  FImport.Command(AClient, 'say_team ' + AText);
end;

procedure TBotElementaryActions.Tell(const AClient, AClientTo: Integer; const AText: AnsiString);
begin
  FImport.Command(AClient, 'tell ' + TBotCFormat.Int(AClientTo) + ', ' + AText);
end;

procedure TBotElementaryActions.UseItem(const AClient: Integer; const AItem: AnsiString);
begin
  FImport.Command(AClient, 'use ' + AItem);
end;

procedure TBotElementaryActions.DropItem(const AClient: Integer; const AItem: AnsiString);
begin
  FImport.Command(AClient, 'drop ' + AItem);
end;

procedure TBotElementaryActions.UseInv(const AClient: Integer; const AInventory: AnsiString);
begin
  FImport.Command(AClient, 'invuse ' + AInventory);
end;

procedure TBotElementaryActions.DropInv(const AClient: Integer; const AInventory: AnsiString);
begin
  FImport.Command(AClient, 'invdrop ' + AInventory);
end;

procedure TBotElementaryActions.Command(const AClient: Integer; const ACommand: AnsiString);
begin
  FImport.Command(AClient, ACommand);
end;

procedure TBotElementaryActions.Gesture(const AClient: Integer);
begin
  Action(AClient, ACTION_GESTURE);
end;

procedure TBotElementaryActions.SelectWeapon(const AClient, AWeapon: Integer);
begin
  CheckClient(AClient);
  FInputs[AClient].Weapon := AWeapon;
end;

procedure TBotElementaryActions.Attack(const AClient: Integer);
begin
  Action(AClient, ACTION_ATTACK);
end;

procedure TBotElementaryActions.Talk(const AClient: Integer);
begin
  Action(AClient, ACTION_TALK);
end;

procedure TBotElementaryActions.Use(const AClient: Integer);
begin
  Action(AClient, ACTION_USE);
end;

procedure TBotElementaryActions.Respawn(const AClient: Integer);
begin
  Action(AClient, ACTION_RESPAWN);
end;

procedure TBotElementaryActions.Jump(const AClient: Integer);
begin
  CheckClient(AClient);
  if (FInputs[AClient].ActionFlags and ACTION_JUMPEDLASTFRAME) <> 0 then
    FInputs[AClient].ActionFlags := FInputs[AClient].ActionFlags and not ACTION_JUMP
  else
    FInputs[AClient].ActionFlags := FInputs[AClient].ActionFlags or ACTION_JUMP;
end;

procedure TBotElementaryActions.DelayedJump(const AClient: Integer);
begin
  CheckClient(AClient);
  if (FInputs[AClient].ActionFlags and ACTION_JUMPEDLASTFRAME) <> 0 then
    FInputs[AClient].ActionFlags := FInputs[AClient].ActionFlags and not ACTION_DELAYEDJUMP
  else
    FInputs[AClient].ActionFlags := FInputs[AClient].ActionFlags or ACTION_DELAYEDJUMP;
end;

procedure TBotElementaryActions.Crouch(const AClient: Integer);
begin
  Action(AClient, ACTION_CROUCH);
end;

procedure TBotElementaryActions.Walk(const AClient: Integer);
begin
  Action(AClient, ACTION_WALK);
end;

procedure TBotElementaryActions.Action(const AClient, AAction: Integer);
begin
  CheckClient(AClient);
  FInputs[AClient].ActionFlags := FInputs[AClient].ActionFlags or AAction;
end;

procedure TBotElementaryActions.MoveUp(const AClient: Integer);
begin
  Action(AClient, ACTION_MOVEUP);
end;

procedure TBotElementaryActions.MoveDown(const AClient: Integer);
begin
  Action(AClient, ACTION_MOVEDOWN);
end;

procedure TBotElementaryActions.MoveForward(const AClient: Integer);
begin
  Action(AClient, ACTION_MOVEFORWARD);
end;

procedure TBotElementaryActions.MoveBack(const AClient: Integer);
begin
  Action(AClient, ACTION_MOVEBACK);
end;

procedure TBotElementaryActions.MoveLeft(const AClient: Integer);
begin
  Action(AClient, ACTION_MOVELEFT);
end;

procedure TBotElementaryActions.MoveRight(const AClient: Integer);
begin
  Action(AClient, ACTION_MOVERIGHT);
end;

procedure TBotElementaryActions.Move(const AClient: Integer; const ADir: TVec3; const ASpeed: Single);
var
  LSpeed: Single;
begin
  CheckClient(AClient);
  FInputs[AClient].Dir := ADir;
  // cap speed
  LSpeed := ASpeed;
  if LSpeed > MAX_USERMOVE then
    LSpeed := MAX_USERMOVE
  else if LSpeed < -MAX_USERMOVE then
    LSpeed := -MAX_USERMOVE;
  FInputs[AClient].Speed := LSpeed;
end;

procedure TBotElementaryActions.View(const AClient: Integer; const AViewAngles: TVec3);
begin
  CheckClient(AClient);
  FInputs[AClient].ViewAngles := AViewAngles;
end;

function TBotElementaryActions.GetInput(const AClient: Integer; const AThinkTime: Single): TBotInput;
begin
  CheckClient(AClient);
  FInputs[AClient].ThinkTime := AThinkTime;
  Result := FInputs[AClient];
end;

procedure TBotElementaryActions.ResetInput(const AClient: Integer);
var
  LJumped: Boolean;
begin
  CheckClient(AClient);
  FInputs[AClient].ActionFlags := FInputs[AClient].ActionFlags and not ACTION_JUMPEDLASTFRAME;
  FInputs[AClient].ThinkTime := 0;
  FInputs[AClient].Dir[0] := 0;
  FInputs[AClient].Dir[1] := 0;
  FInputs[AClient].Dir[2] := 0;
  FInputs[AClient].Speed := 0;
  LJumped := (FInputs[AClient].ActionFlags and ACTION_JUMP) <> 0;
  FInputs[AClient].ActionFlags := 0;
  if LJumped then
    FInputs[AClient].ActionFlags := FInputs[AClient].ActionFlags or ACTION_JUMPEDLASTFRAME;
end;

end.
