{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - one computer player                                }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (WarAI, wai_createAI, wai_initAI,      }
{  wai_getNextAICommand, wai_updateAICurrentCommands, wai_updateAINextCommands, }
{  wai_removeCompletedAICommands, wai_updateAIPlayer), (c) 2019 Alejandro Coto   }
{  Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Player;

interface

uses
  System.Generics.Collections, DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment, DelphiDoom.War.Ai.Registry;

type
  /// <summary>
  ///   The state of one computer player (WarAI and its customData): the script of its race as commands, how far it has got,
  ///   the commands that are running and the queue of the next. Two players share nothing; the registry of the kinds of
  ///   command is the one of the system. Update is wai_updateAIPlayer and is run once per tic
  /// </summary>
  TWarComputerPlayer = class
  strict private
    FEnvironment: TWarAiEnvironment;
    FRegistry: TWarAiCommandRegistry;
    FStaticCommandId: Cardinal;
    FScript: TObjectList<TWarAiCommand>;
    FScriptIndex: Integer;
    FCurrent: TList<TWarAiCommand>;
    FNext: TList<TWarAiCommand>;
    function CreateCommand(ACommandType: Integer): TWarAiCommand;
    function GetNextCommand: TWarAiCommand;
    function UpdateCurrentCommands: Boolean;
    procedure UpdateNextCommands;
    procedure RemoveCompletedCommands;
    function GetCurrentCount: Integer;
    function GetCurrent(AIndex: Integer): TWarAiCommand;
    function GetNextCount: Integer;
  public
    /// <summary>
    ///   wai_initAIPlayer: the environment is owned by the player; the registry is not. The script is made from the race of the
    ///   player at this moment (wai_initAI)
    /// </summary>
    constructor Create(const AEnvironment: TWarAiEnvironment; const ARegistry: TWarAiCommandRegistry);
    destructor Destroy; override;
    /// <summary>wai_updateAIPlayer</summary>
    procedure Update;
    /// <summary>wai_applyUnitRequestProgress for the command with that id (a training that was ordered by it has been paid)</summary>
    procedure UnitRequestProgress(ACommandId: Cardinal);
    /// <summary>The running or scripted command with that id, nil if there is none</summary>
    function FindCommand(ACommandId: Cardinal): TWarAiCommand;
    /// <summary>wai_createWaitForUnit, wai_createUnitRequest and wai_createSleepForTime are made by the script; this adds a command by hand to the queue (a handler of another kind may)</summary>
    procedure Enqueue(const ACommand: TWarAiCommand);
    /// <summary>A new command of a kind with the next id (ids count from 1; wai_createAICommand). The player owns it once it is enqueued</summary>
    function NewCommand(ACommandType: Integer): TWarAiCommand;
    property Environment: TWarAiEnvironment read FEnvironment;
    /// <summary>staticCommandId: the id of the last command made</summary>
    property StaticCommandId: Cardinal read FStaticCommandId;
    /// <summary>The index of the next command of the script (customData->index)</summary>
    property ScriptIndex: Integer read FScriptIndex;
    property CurrentCount: Integer read GetCurrentCount;
    property Current[AIndex: Integer]: TWarAiCommand read GetCurrent;
    property NextCount: Integer read GetNextCount;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Ai.Types, DelphiDoom.War.Ai.Tables.Data, DelphiDoom.War.Model.Context;

{ TWarComputerPlayer }

constructor TWarComputerPlayer.Create(const AEnvironment: TWarAiEnvironment; const ARegistry: TWarAiCommandRegistry);
var
  LIndex: Integer;
  LEntry: TWarAiScriptEntry;
  LCommand: TWarAiCommand;
  LRace: Integer;
begin
  inherited Create;
  if not Assigned(AEnvironment) or not Assigned(ARegistry) then
    raise EWarException.Create('A computer player needs its environment and its registry');
  FEnvironment := AEnvironment;
  FRegistry := ARegistry;
  FScript := TObjectList<TWarAiCommand>.Create(True);
  FCurrent := TList<TWarAiCommand>.Create;
  FNext := TList<TWarAiCommand>.Create;
  LRace := Ord(FEnvironment.Player^.Race);
  for LIndex := 0 to WAR_AI_SCRIPT_LENGTH - 1 do
  begin
    LEntry := WAR_AI_SCRIPT[LRace, LIndex];
    LCommand := CreateCommand(LEntry.Kind);
    LCommand.UnitType := LEntry.UnitType;
    LCommand.Count := LEntry.Count;
    FScript.Add(LCommand);
  end;
end;

destructor TWarComputerPlayer.Destroy;
var
  LIndex: Integer;
begin
  // the commands of the script belong to FScript; the others (the sleeps) to whoever holds them (the lists do not exist if
  // the constructor refused its arguments)
  if Assigned(FCurrent) and Assigned(FScript) then
    for LIndex := 0 to FCurrent.Count - 1 do
      if FScript.IndexOf(FCurrent[LIndex]) < 0 then
        FCurrent[LIndex].Free;
  if Assigned(FNext) and Assigned(FScript) then
    for LIndex := 0 to FNext.Count - 1 do
      if FScript.IndexOf(FNext[LIndex]) < 0 then
        FNext[LIndex].Free;
  FNext.Free;
  FCurrent.Free;
  FScript.Free;
  FEnvironment.Free;
  inherited;
end;

function TWarComputerPlayer.CreateCommand(ACommandType: Integer): TWarAiCommand;
begin
  Inc(FStaticCommandId);
  Result := TWarAiCommand.Create(FStaticCommandId, ACommandType);
end;

function TWarComputerPlayer.NewCommand(ACommandType: Integer): TWarAiCommand;
begin
  Result := CreateCommand(ACommandType);
end;

procedure TWarComputerPlayer.Enqueue(const ACommand: TWarAiCommand);
begin
  FNext.Add(ACommand);
end;

function TWarComputerPlayer.GetNextCommand: TWarAiCommand;
begin
  if FScriptIndex < FScript.Count then
  begin
    Result := FScript[FScriptIndex];
    Inc(FScriptIndex);
    Exit;
  end;
  // wai_createSleepForTime(10): the script is over, the player sleeps and then asks again
  Result := CreateCommand(WAR_AI_COMMAND_SLEEP);
  Result.EndRealTime := FEnvironment.World.Context.RealTime + WAR_AI_IDLE_SLEEP_SECONDS;
end;

function TWarComputerPlayer.UpdateCurrentCommands: Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to FCurrent.Count - 1 do
    if not FRegistry.Execute(FEnvironment, FCurrent[LIndex]) then
      Result := False;
end;

procedure TWarComputerPlayer.UpdateNextCommands;
var
  LCommand: TWarAiCommand;
begin
  if FNext.Count = 0 then
    Exit;
  repeat
    LCommand := FNext[0];
    FNext.Delete(0);
    FCurrent.Add(LCommand);
    // a wait or a sleep ends the burst: what follows waits for it
  until (FNext.Count = 0) or (LCommand.CommandType = WAR_AI_COMMAND_WAIT) or
    (LCommand.CommandType = WAR_AI_COMMAND_SLEEP);
end;

procedure TWarComputerPlayer.RemoveCompletedCommands;
var
  LIndex: Integer;
  LCommand: TWarAiCommand;
begin
  for LIndex := FCurrent.Count - 1 downto 0 do
  begin
    LCommand := FCurrent[LIndex];
    if LCommand.Status = WAR_AI_STATUS_COMPLETED then
    begin
      FCurrent.Delete(LIndex);
      // the original never frees them: the sleeps would pile up for the whole game
      if FScript.IndexOf(LCommand) < 0 then
        LCommand.Free;
    end;
  end;
end;

procedure TWarComputerPlayer.Update;
begin
  if UpdateCurrentCommands then
  begin
    Enqueue(GetNextCommand);
    UpdateNextCommands;
  end;
  RemoveCompletedCommands;
end;

function TWarComputerPlayer.FindCommand(ACommandId: Cardinal): TWarAiCommand;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FScript.Count - 1 do
    if FScript[LIndex].Id = ACommandId then
      Exit(FScript[LIndex]);
  for LIndex := 0 to FCurrent.Count - 1 do
    if FCurrent[LIndex].Id = ACommandId then
      Exit(FCurrent[LIndex]);
  Result := nil;
end;

procedure TWarComputerPlayer.UnitRequestProgress(ACommandId: Cardinal);
var
  LCommand: TWarAiCommand;
begin
  LCommand := FindCommand(ACommandId);
  if Assigned(LCommand) then
    LCommand.ApplyUnitRequestProgress;
end;

function TWarComputerPlayer.GetCurrentCount: Integer;
begin
  Result := FCurrent.Count;
end;

function TWarComputerPlayer.GetCurrent(AIndex: Integer): TWarAiCommand;
begin
  if (AIndex < 0) or (AIndex >= FCurrent.Count) then
    raise EWarException.CreateFmt('AI command %d is not running', [AIndex]);
  Result := FCurrent[AIndex];
end;

function TWarComputerPlayer.GetNextCount: Integer;
begin
  Result := FNext.Count;
end;

end.
