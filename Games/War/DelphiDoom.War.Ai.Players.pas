{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the computer players of a game                     }
{                                                                              }
{  Port of war1 (acoto87/war1), war_ai.c (wai_initAIPlayers,                    }
{  wai_updateAIPlayers), (c) 2019 Alejandro Coto Gutierrez, zlib License (see   }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ai.Players;

interface

uses
  System.Generics.Collections, DelphiDoom.War.Ai.Intf, DelphiDoom.War.Ai.Player, DelphiDoom.War.Ai.Registry,
  DelphiDoom.War.Model.World;

type
  /// <summary>
  ///   The players the computer plays (the original assumes the player 1 is the only one: TWarModelFactory.AttachComputerPlayers
  ///   gives it a list), the registry of the kinds of command they share, and what the world asks of them. It belongs to the
  ///   world that holds it (as an interface, so it lives as long as the world and the training states can still call it)
  /// </summary>
  TWarComputerPlayers = class(TInterfacedObject, IWarAiProgress, IWarComputerUpdate)
  strict private
    FWorld: TWarModelWorld;
    FRegistry: TWarAiCommandRegistry;
    FPlayers: TObjectList<TWarComputerPlayer>;
    function GetCount: Integer;
    function GetPlayer(AIndex: Integer): TWarComputerPlayer;
  public
    constructor Create(const AWorld: TWarModelWorld; const ARegistry: TWarAiCommandRegistry);
    destructor Destroy; override;
    /// <summary>wai_initAIPlayer: the player plays by the script of its race (EWarException if it is already a computer player)</summary>
    function AddPlayer(APlayerIndex: Integer): TWarComputerPlayer;
    /// <summary>The player of the AI for that player of the game, nil if a person plays it</summary>
    function FindPlayer(APlayerIndex: Integer): TWarComputerPlayer;
    /// <summary>wai_updateAIPlayers (IWarComputerUpdate)</summary>
    procedure UpdateComputerPlayers;
    /// <summary>IWarAiProgress: a training state paid; an unknown handle is ignored</summary>
    procedure UnitRequestProgress(AHandle: Cardinal);
    /// <summary>The kinds of command: register another handler to give the AI a new kind of command</summary>
    property Registry: TWarAiCommandRegistry read FRegistry;
    property Count: Integer read GetCount;
    property Players[AIndex: Integer]: TWarComputerPlayer read GetPlayer; default;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment;

{ TWarComputerPlayers }

constructor TWarComputerPlayers.Create(const AWorld: TWarModelWorld; const ARegistry: TWarAiCommandRegistry);
begin
  inherited Create;
  if not Assigned(AWorld) or not Assigned(ARegistry) then
    raise EWarException.Create('The computer players need a world and a registry of commands');
  FWorld := AWorld;
  FRegistry := ARegistry;
  FPlayers := TObjectList<TWarComputerPlayer>.Create(True);
end;

destructor TWarComputerPlayers.Destroy;
begin
  FPlayers.Free;
  FRegistry.Free;
  inherited;
end;

function TWarComputerPlayers.GetCount: Integer;
begin
  Result := FPlayers.Count;
end;

function TWarComputerPlayers.GetPlayer(AIndex: Integer): TWarComputerPlayer;
begin
  if (AIndex < 0) or (AIndex >= FPlayers.Count) then
    raise EWarException.CreateFmt('Computer player %d does not exist', [AIndex]);
  Result := FPlayers[AIndex];
end;

function TWarComputerPlayers.FindPlayer(APlayerIndex: Integer): TWarComputerPlayer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FPlayers.Count - 1 do
    if FPlayers[LIndex].Environment.PlayerIndex = APlayerIndex then
      Exit(FPlayers[LIndex]);
  Result := nil;
end;

function TWarComputerPlayers.AddPlayer(APlayerIndex: Integer): TWarComputerPlayer;
var
  LEnvironment: TWarAiEnvironment;
begin
  if (APlayerIndex < 0) or (APlayerIndex >= FWorld.Context.PlayersCount) then
    raise EWarException.CreateFmt('Player %d does not exist', [APlayerIndex]);
  if Assigned(FindPlayer(APlayerIndex)) then
    raise EWarException.CreateFmt('Player %d is a computer player already', [APlayerIndex]);
  // the player owns the environment from here, also when its constructor fails
  LEnvironment := TWarAiEnvironment.Create(FWorld, APlayerIndex);
  Result := TWarComputerPlayer.Create(LEnvironment, FRegistry);
  FPlayers.Add(Result);
end;

procedure TWarComputerPlayers.UpdateComputerPlayers;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FPlayers.Count - 1 do
    FPlayers[LIndex].Update;
end;

procedure TWarComputerPlayers.UnitRequestProgress(AHandle: Cardinal);
var
  LPlayer: TWarComputerPlayer;
begin
  LPlayer := FindPlayer(TWarAiCommand.HandlePlayer(AHandle));
  if Assigned(LPlayer) then
    LPlayer.UnitRequestProgress(TWarAiCommand.HandleId(AHandle));
end;

end.
