{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the console commands of the server          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): SV_Map_f,       }
{  SV_MapRestart_f, SV_Status_f (sv_ccmds.c) and Com_Quit_f (common.c).        }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.ServerCommands;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Server;

type
  /// <summary>
  ///   The commands a dedicated server needs: map, map_restart, status and quit. "addbot" and the other commands
  ///   of the game are not here: they reach qagame as GAME_CONSOLE_COMMAND when nobody else takes the line.
  ///   The commands are methods because the registry takes a procedure of object
  /// </summary>
  TQ3ServerCommands = class
  strict private
    FRegistry: IQ3CommandRegistry;
    FArguments: IQ3CommandArguments;
    FCVars: IQ3CVarSystem;
    FServer: TQ3Server;
    FPrint: IQ3HostConsole;
    FQuitRequested: Boolean;
    FMapFailed: Boolean;
    FOnQuit: TProc;
  public
    /// <summary>The commands are registered at once; AOnQuit is called by "quit" (it may be nil)</summary>
    constructor Create(const ARegistry: IQ3CommandRegistry; const AArguments: IQ3CommandArguments;
      const ACVars: IQ3CVarSystem; const AServer: TQ3Server; const APrint: IQ3HostConsole; const AOnQuit: TProc);
    destructor Destroy; override;
    /// <summary>SV_Map_f: the server loads the level (the bots go); a level that is not there is a failure</summary>
    procedure Map;
    /// <summary>SV_MapRestart_f: with the delay in seconds that is the first argument (default 5)</summary>
    procedure MapRestart;
    /// <summary>SV_Status_f: the level and how many players and bots are in</summary>
    procedure Status;
    /// <summary>Com_Quit_f</summary>
    procedure Quit;
    property QuitRequested: Boolean read FQuitRequested;
    /// <summary>True when a "map" command named a level that is not in the game files</summary>
    property MapFailed: Boolean read FMapFailed;
  end;

implementation

uses
  System.Math, DelphiDoom.Q3Host.ServerSnapshots;

const
  // MAX_CLIENTS of the server
  MAX_CLIENTS = 64;

{ TQ3ServerCommands }

constructor TQ3ServerCommands.Create(const ARegistry: IQ3CommandRegistry; const AArguments: IQ3CommandArguments;
  const ACVars: IQ3CVarSystem; const AServer: TQ3Server; const APrint: IQ3HostConsole; const AOnQuit: TProc);
begin
  inherited Create;
  FRegistry := ARegistry;
  FArguments := AArguments;
  FCVars := ACVars;
  FServer := AServer;
  FPrint := APrint;
  FOnQuit := AOnQuit;
  FRegistry.AddCommand('map', Map);
  FRegistry.AddCommand('map_restart', MapRestart);
  FRegistry.AddCommand('status', Status);
  FRegistry.AddCommand('quit', Quit);
end;

destructor TQ3ServerCommands.Destroy;
begin
  FRegistry.RemoveCommand('map');
  FRegistry.RemoveCommand('map_restart');
  FRegistry.RemoveCommand('status');
  FRegistry.RemoveCommand('quit');
  inherited Destroy;
end;

procedure TQ3ServerCommands.Map;
begin
  if FArguments.Count < 2 then
  begin
    FPrint.Print('map <mapname> : start a new map'#10);
    Exit;
  end;
  if not FServer.Map(FArguments.Argv(1)) then
    FMapFailed := True;
end;

procedure TQ3ServerCommands.MapRestart;
var
  LDelay: Integer;
begin
  LDelay := 5;
  if FArguments.Count > 1 then
    LDelay := StrToIntDef(string(FArguments.Argv(1)), 0);
  FServer.MapRestart(LDelay);
end;

procedure TQ3ServerCommands.Status;
var
  LSlot, LPlayers, LBots: Integer;
begin
  if not FServer.IsRunning then
  begin
    FPrint.Print('Server is not running.'#10);
    Exit;
  end;
  LPlayers := 0;
  LBots := 0;
  for LSlot := 0 to Min(MAX_CLIENTS, FCVars.VariableIntegerValue('sv_maxclients')) - 1 do
    if FServer.ClientPhase[LSlot] >= TQ3ServerClientPhase.Connected then
      if FServer.ClientIsBot[LSlot] then
        Inc(LBots)
      else
        Inc(LPlayers);
  FPrint.Print(AnsiString(Format('map: %s'#10'players: %d, bots: %d'#10, [string(FServer.MapName), LPlayers,
    LBots])));
end;

procedure TQ3ServerCommands.Quit;
begin
  FQuitRequested := True;
  if Assigned(FOnQuit) then
    FOnQuit();
end;

end.
