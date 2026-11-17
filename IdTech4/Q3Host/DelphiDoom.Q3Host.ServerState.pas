{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the state of the server the game asks  }
{  for                                                                         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_init.c       }
{  (SV_SetConfigstring, SV_GetConfigstring, SV_SetUserinfo, SV_GetUserinfo),   }
{  sv_game.c (SV_GetUsercmd), sv_bot.c (SV_BotAllocateClient,                  }
{  SV_BotFreeClient). Copyright (C) 1999-2005 Id Software, Inc. This unit is   }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ServerState;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>Told when a configstring changed (the server sends "cs index text" to the clients)</summary>
  TQ3ConfigstringChanged = reference to procedure(AIndex: Integer; const AValue: AnsiString);

  /// <summary>
  ///   sv.configstrings (1024), svs.clients[].userinfo and lastUsercmd and the slots of the bots. The clients
  ///   themselves (connection, snapshots) are the server's: it fills the user commands and the active slots with
  ///   SetUsercmd and SetClientActive. The name that SV_SetUserinfo copies from the info string is not kept: the
  ///   server reads it from the user info when it needs it
  /// </summary>
  TQ3HostServerState = class(TInterfacedObject, IQ3HostServerState)
  strict private
    const
      MAX_CONFIGSTRINGS = 1024;
      MAX_CLIENTS = 64;
      MAX_INFO_STRING = 1024;
      USERCMD_SIZE = 24;
    var
      FCVars: IQ3CVarSystem;
      FConfigstrings: array[0..MAX_CONFIGSTRINGS - 1] of AnsiString;
      FUserinfo: array[0..MAX_CLIENTS - 1] of AnsiString;
      FUsercmds: array[0..MAX_CLIENTS - 1] of TBytes;
      FActive: array[0..MAX_CLIENTS - 1] of Boolean;
      FHasEntity: array[0..MAX_CLIENTS - 1] of Boolean;
      FOnConfigstringChanged: TQ3ConfigstringChanged;
    procedure CheckClient(AClient: Integer; const AWhat: string);
  public
    constructor Create(const ACVars: IQ3CVarSystem);
    function MaxClients: Integer;
    procedure SetConfigstring(AIndex: Integer; const AValue: AnsiString);
    function GetConfigstring(AIndex: Integer): AnsiString;
    procedure SetUserinfo(AClient: Integer; const AValue: AnsiString);
    function GetUserinfo(AClient: Integer): AnsiString;
    function GetUsercmd(AClient: Integer): TBytes;
    function BotAllocateClient: Integer;
    function BotFreeClient(AClient: Integer): Boolean;
    /// <summary>The last command a client sent (24 bytes)</summary>
    procedure SetUsercmd(AClient: Integer; const ACommand: TBytes);
    /// <summary>A client slot in use (state not CS_FREE)</summary>
    procedure SetClientActive(AClient: Integer; AActive: Boolean);
    property OnConfigstringChanged: TQ3ConfigstringChanged read FOnConfigstringChanged
      write FOnConfigstringChanged;
  end;

implementation

uses
  DelphiDoom.Q3Host.Types;

resourcestring
  SBadConfigstringIndex = 'SV_SetConfigstring: bad index %d';
  SBadClient = '%s: bad index %d';

constructor TQ3HostServerState.Create(const ACVars: IQ3CVarSystem);
var
  LIndex: Integer;
begin
  inherited Create;
  FCVars := ACVars;
  for LIndex := 0 to MAX_CLIENTS - 1 do
    SetLength(FUsercmds[LIndex], USERCMD_SIZE);
end;

function TQ3HostServerState.MaxClients: Integer;
begin
  Result := FCVars.VariableIntegerValue('sv_maxclients');
  if Result > MAX_CLIENTS then
    Result := MAX_CLIENTS;
end;

procedure TQ3HostServerState.CheckClient(AClient: Integer; const AWhat: string);
begin
  if (AClient < 0) or (AClient >= MaxClients) then
    raise EQ3HostException.CreateFmt(SBadClient, [AWhat, AClient]);
end;

procedure TQ3HostServerState.SetConfigstring(AIndex: Integer; const AValue: AnsiString);
begin
  if (AIndex < 0) or (AIndex >= MAX_CONFIGSTRINGS) then
    raise EQ3HostException.CreateFmt(SBadConfigstringIndex, [AIndex]);
  // no update is broadcast when nothing changes
  if FConfigstrings[AIndex] = AValue then
    Exit;
  FConfigstrings[AIndex] := AValue;
  if Assigned(FOnConfigstringChanged) then
    FOnConfigstringChanged(AIndex, AValue);
end;

function TQ3HostServerState.GetConfigstring(AIndex: Integer): AnsiString;
begin
  if (AIndex < 0) or (AIndex >= MAX_CONFIGSTRINGS) then
    raise EQ3HostException.CreateFmt(SBadConfigstringIndex, [AIndex]);
  Result := FConfigstrings[AIndex];
end;

procedure TQ3HostServerState.SetUserinfo(AClient: Integer; const AValue: AnsiString);
begin
  CheckClient(AClient, 'SV_SetUserinfo');
  // Q_strncpyz( userinfo, val, sizeof( userinfo ) )
  FUserinfo[AClient] := Copy(AValue, 1, MAX_INFO_STRING - 1);
end;

function TQ3HostServerState.GetUserinfo(AClient: Integer): AnsiString;
begin
  CheckClient(AClient, 'SV_GetUserinfo');
  Result := FUserinfo[AClient];
end;

function TQ3HostServerState.GetUsercmd(AClient: Integer): TBytes;
begin
  CheckClient(AClient, 'SV_GetUsercmd');
  Result := Copy(FUsercmds[AClient]);
end;

function TQ3HostServerState.BotAllocateClient: Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MaxClients - 1 do
    if not FActive[LIndex] then
    begin
      FActive[LIndex] := True;
      FHasEntity[LIndex] := True;
      Exit(LIndex);
    end;
  Result := -1;
end;

function TQ3HostServerState.BotFreeClient(AClient: Integer): Boolean;
begin
  CheckClient(AClient, 'SV_BotFreeClient');
  FActive[AClient] := False;
  Result := FHasEntity[AClient];
end;

procedure TQ3HostServerState.SetUsercmd(AClient: Integer; const ACommand: TBytes);
begin
  CheckClient(AClient, 'SetUsercmd');
  FUsercmds[AClient] := Copy(ACommand, 0, USERCMD_SIZE);
  SetLength(FUsercmds[AClient], USERCMD_SIZE);
end;

procedure TQ3HostServerState.SetClientActive(AClient: Integer; AActive: Boolean);
begin
  CheckClient(AClient, 'SetClientActive');
  FActive[AClient] := AActive;
  if AActive then
    FHasEntity[AClient] := True;
end;

end.
