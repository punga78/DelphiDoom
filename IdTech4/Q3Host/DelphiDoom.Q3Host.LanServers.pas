{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the server lists of the menus           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_ui.c          }
{  (LAN_AddServer, LAN_RemoveServer, LAN_GetServerCount,                        }
{  LAN_GetServerAddressString, LAN_GetServerInfo, LAN_GetServerPing,            }
{  LAN_MarkServerVisible, LAN_ServerIsVisible, LAN_CompareServers,              }
{  LAN_ResetPings, LAN_LoadCachedServers) and cl_main.c (the empty ping         }
{  queue). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from  }
{  the Quake III Arena source code and is therefore available under the GNU     }
{  General Public License, version 2 or (at your option) any later version.     }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Q3Host.LanServers;

interface

uses
  System.SysUtils, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.NetAddress;

type
  /// <summary>serverInfo_t of client.h (the strings are 32 characters with the terminator)</summary>
  TQ3LanServer = record
    Address: TQ3NetAddress;
    HostName: AnsiString;
    MapName: AnsiString;
    Game: AnsiString;
    NetType: Integer;
    GameType: Integer;
    Clients: Integer;
    MaxClients: Integer;
    MinPing: Integer;
    MaxPing: Integer;
    Ping: Integer;
    Visible: Boolean;
    PunkBuster: Integer;
  end;

  /// <summary>
  ///   cls.localServers, mplayerServers, globalServers and favoriteServers with the LAN_* calls of the menus. The
  ///   servers are filled by the one that answers the queries (SetServer: the tests, and later the client that
  ///   receives the replies of the master server). There is no network here: the ping queue is always empty, no
  ///   ping is ever sent and no server status ever arrives; the cache file servercache.dat is not read or written
  ///   (LoadCachedServers finds it absent: every count goes to 0)
  /// </summary>
  TQ3LanServers = class(TInterfacedObject, IQ3HostLan)
  strict private
    FLists: array[Q3_AS_LOCAL..Q3_AS_FAVORITES] of TArray<TQ3LanServer>;
    FCounts: array[Q3_AS_LOCAL..Q3_AS_FAVORITES] of Integer;
    function Capacity(ASource: Integer): Integer;
    function Slot(ASource, AIndex: Integer): Integer;
  public
    constructor Create;
    /// <summary>The slot of a list (the C keeps all of them, used or not); a source or index out of range raises</summary>
    procedure SetServer(ASource, AIndex: Integer; const AServer: TQ3LanServer);
    function GetServer(ASource, AIndex: Integer): TQ3LanServer;
    procedure SetServerCount(ASource, ACount: Integer);
    procedure LoadCachedServers;
    procedure SaveCachedServers;
    function AddServer(ASource: Integer; const AName, AAddress: AnsiString): Integer;
    procedure RemoveServer(ASource: Integer; const AAddress: AnsiString);
    function GetServerCount(ASource: Integer): Integer;
    function GetServerAddressString(ASource, AIndex: Integer): AnsiString;
    function GetServerInfo(ASource, AIndex: Integer): AnsiString;
    function GetServerPing(ASource, AIndex: Integer): Integer;
    procedure MarkServerVisible(ASource, AIndex: Integer; AVisible: Boolean);
    function ServerIsVisible(ASource, AIndex: Integer): Boolean;
    function UpdateVisiblePings(ASource: Integer): Boolean;
    procedure ResetPings(ASource: Integer);
    function CompareServers(ASource, ASortKey, ASortDirection, AServer1, AServer2: Integer): Integer;
    function GetPingQueueCount: Integer;
    procedure ClearPing(AIndex: Integer);
    procedure GetPing(AIndex: Integer; out AAddress: AnsiString; out APingTime: Integer);
    function GetPingInfo(AIndex: Integer): AnsiString;
    function ServerStatus(const AAddress: AnsiString; out AStatus: AnsiString): Integer;
  end;

implementation

uses
  DelphiDoom.Net.Q3.InfoString, DelphiDoom.Q3Host.Types;

resourcestring
  SBadServerSlot = 'The server slot %d of the list %d does not exist';

// Q_strncpyz into a char[32]
function Cut(const AText: AnsiString): AnsiString; inline;
begin
  Result := Copy(AText, 1, Q3_MAX_NAME_LENGTH - 1);
end;

// Q_stricmp: ASCII case folding, byte by byte; the sign of the first difference
function CompareNoCase(const AText, AOther: AnsiString): Integer;
var
  LIndex, LA, LB: Integer;
begin
  LIndex := 1;
  while True do
  begin
    if LIndex > Length(AText) then
      LA := 0
    else
      LA := Ord(AText[LIndex]);
    if LIndex > Length(AOther) then
      LB := 0
    else
      LB := Ord(AOther[LIndex]);
    if (LA >= Ord('A')) and (LA <= Ord('Z')) then
      Inc(LA, 32);
    if (LB >= Ord('A')) and (LB <= Ord('Z')) then
      Inc(LB, 32);
    if LA <> LB then
    begin
      if LA < LB then
        Exit(-1);
      Exit(1);
    end;
    if LA = 0 then
      Exit(0);
    Inc(LIndex);
  end;
end;

{ TQ3LanServers }

constructor TQ3LanServers.Create;
var
  LSource: Integer;
begin
  inherited Create;
  for LSource := Q3_AS_LOCAL to Q3_AS_FAVORITES do
    SetLength(FLists[LSource], Capacity(LSource));
end;

function TQ3LanServers.Capacity(ASource: Integer): Integer;
begin
  if ASource = Q3_AS_GLOBAL then
    Result := Q3_MAX_GLOBAL_SERVERS
  else
    Result := Q3_MAX_OTHER_SERVERS;
end;

// the index of the slot, or -1 when the source is unknown or the index is outside the whole list (the checks of
// LAN_GetServerPtr: the whole list, not the servers counted)
function TQ3LanServers.Slot(ASource, AIndex: Integer): Integer;
begin
  Result := -1;
  if (ASource < Q3_AS_LOCAL) or (ASource > Q3_AS_FAVORITES) then
    Exit;
  if (AIndex >= 0) and (AIndex < Capacity(ASource)) then
    Result := AIndex;
end;

procedure TQ3LanServers.SetServer(ASource, AIndex: Integer; const AServer: TQ3LanServer);
begin
  if Slot(ASource, AIndex) < 0 then
    raise EQ3HostException.CreateFmt(SBadServerSlot, [AIndex, ASource]);
  FLists[ASource][AIndex] := AServer;
end;

function TQ3LanServers.GetServer(ASource, AIndex: Integer): TQ3LanServer;
begin
  if Slot(ASource, AIndex) < 0 then
    raise EQ3HostException.CreateFmt(SBadServerSlot, [AIndex, ASource]);
  Result := FLists[ASource][AIndex];
end;

procedure TQ3LanServers.SetServerCount(ASource, ACount: Integer);
begin
  if (ASource < Q3_AS_LOCAL) or (ASource > Q3_AS_FAVORITES) or (ACount < 0) or (ACount > Capacity(ASource)) then
    raise EQ3HostException.CreateFmt(SBadServerSlot, [ACount, ASource]);
  FCounts[ASource] := ACount;
end;

procedure TQ3LanServers.LoadCachedServers;
begin
  // the cache file is not there: cls.numglobalservers = cls.nummplayerservers = cls.numfavoriteservers = 0 (the
  // local list is not touched)
  FCounts[Q3_AS_GLOBAL] := 0;
  FCounts[Q3_AS_MPLAYER] := 0;
  FCounts[Q3_AS_FAVORITES] := 0;
end;

procedure TQ3LanServers.SaveCachedServers;
begin
  // nothing is written: the host has no file for the cache of the server lists
end;

function TQ3LanServers.AddServer(ASource: Integer; const AName, AAddress: AnsiString): Integer;
var
  LAddress: TQ3NetAddress;
  LIndex: Integer;
begin
  if (ASource < Q3_AS_LOCAL) or (ASource > Q3_AS_FAVORITES) or (FCounts[ASource] >= Capacity(ASource)) then
    Exit(-1);
  // NET_StringToAdr: a bad address is still added (type NA_BAD, never equal to another one)
  TQ3NetAddresses.Parse(AAddress, LAddress);
  for LIndex := 0 to FCounts[ASource] - 1 do
    if TQ3NetAddresses.Same(FLists[ASource][LIndex].Address, LAddress) then
      Exit(0);
  LIndex := FCounts[ASource];
  FLists[ASource][LIndex].Address := LAddress;
  FLists[ASource][LIndex].HostName := Cut(AName);
  FLists[ASource][LIndex].Visible := True;
  Inc(FCounts[ASource]);
  Result := 1;
end;

procedure TQ3LanServers.RemoveServer(ASource: Integer; const AAddress: AnsiString);
var
  LAddress: TQ3NetAddress;
  LIndex, LMove: Integer;
begin
  if (ASource < Q3_AS_LOCAL) or (ASource > Q3_AS_FAVORITES) then
    Exit;
  TQ3NetAddresses.Parse(AAddress, LAddress);
  for LIndex := 0 to FCounts[ASource] - 1 do
    if TQ3NetAddresses.Same(LAddress, FLists[ASource][LIndex].Address) then
    begin
      for LMove := LIndex to FCounts[ASource] - 2 do
        FLists[ASource][LMove] := FLists[ASource][LMove + 1];
      Dec(FCounts[ASource]);
      Break;
    end;
end;

function TQ3LanServers.GetServerCount(ASource: Integer): Integer;
begin
  if (ASource < Q3_AS_LOCAL) or (ASource > Q3_AS_FAVORITES) then
    Exit(0);
  Result := FCounts[ASource];
end;

function TQ3LanServers.GetServerAddressString(ASource, AIndex: Integer): AnsiString;
begin
  if Slot(ASource, AIndex) < 0 then
    Exit('');
  Result := TQ3NetAddresses.ToText(FLists[ASource][AIndex].Address);
end;

function TQ3LanServers.GetServerInfo(ASource, AIndex: Integer): AnsiString;
var
  LServer: TQ3LanServer;
begin
  Result := '';
  if Slot(ASource, AIndex) < 0 then
    Exit;
  LServer := FLists[ASource][AIndex];
  // Info_SetValueForKey puts the new pair first and drops an empty value
  TQ3InfoString.SetValueForKey(Result, 'hostname', LServer.HostName);
  TQ3InfoString.SetValueForKey(Result, 'mapname', LServer.MapName);
  TQ3InfoString.SetValueForKey(Result, 'clients', AnsiString(IntToStr(LServer.Clients)));
  TQ3InfoString.SetValueForKey(Result, 'sv_maxclients', AnsiString(IntToStr(LServer.MaxClients)));
  TQ3InfoString.SetValueForKey(Result, 'ping', AnsiString(IntToStr(LServer.Ping)));
  TQ3InfoString.SetValueForKey(Result, 'minping', AnsiString(IntToStr(LServer.MinPing)));
  TQ3InfoString.SetValueForKey(Result, 'maxping', AnsiString(IntToStr(LServer.MaxPing)));
  TQ3InfoString.SetValueForKey(Result, 'game', LServer.Game);
  TQ3InfoString.SetValueForKey(Result, 'gametype', AnsiString(IntToStr(LServer.GameType)));
  TQ3InfoString.SetValueForKey(Result, 'nettype', AnsiString(IntToStr(LServer.NetType)));
  TQ3InfoString.SetValueForKey(Result, 'addr', TQ3NetAddresses.ToText(LServer.Address));
  TQ3InfoString.SetValueForKey(Result, 'punkbuster', AnsiString(IntToStr(LServer.PunkBuster)));
end;

function TQ3LanServers.GetServerPing(ASource, AIndex: Integer): Integer;
begin
  if Slot(ASource, AIndex) < 0 then
    Exit(-1);
  Result := FLists[ASource][AIndex].Ping;
end;

procedure TQ3LanServers.MarkServerVisible(ASource, AIndex: Integer; AVisible: Boolean);
var
  LIndex: Integer;
begin
  if (ASource < Q3_AS_LOCAL) or (ASource > Q3_AS_FAVORITES) then
    Exit;
  if AIndex = -1 then
  begin
    // the whole list, used or not
    for LIndex := 0 to Capacity(ASource) - 1 do
      FLists[ASource][LIndex].Visible := AVisible;
  end
  else if Slot(ASource, AIndex) >= 0 then
    FLists[ASource][AIndex].Visible := AVisible;
end;

function TQ3LanServers.ServerIsVisible(ASource, AIndex: Integer): Boolean;
begin
  Result := (Slot(ASource, AIndex) >= 0) and FLists[ASource][AIndex].Visible;
end;

function TQ3LanServers.UpdateVisiblePings(ASource: Integer): Boolean;
begin
  // CL_UpdateVisiblePings_f sends "getinfo" to the visible servers that have no ping; nothing is sent here
  Result := False;
end;

procedure TQ3LanServers.ResetPings(ASource: Integer);
var
  LIndex: Integer;
begin
  if (ASource < Q3_AS_LOCAL) or (ASource > Q3_AS_FAVORITES) then
    Exit;
  for LIndex := 0 to Capacity(ASource) - 1 do
    FLists[ASource][LIndex].Ping := -1;
end;

function TQ3LanServers.CompareServers(ASource, ASortKey, ASortDirection, AServer1, AServer2: Integer): Integer;
var
  LFirst, LSecond: Integer;
  LServer1, LServer2: TQ3LanServer;

  function Order(AValue, AOther: Integer): Integer;
  begin
    if AValue < AOther then
      Result := -1
    else if AValue > AOther then
      Result := 1
    else
      Result := 0;
  end;

begin
  LFirst := Slot(ASource, AServer1);
  LSecond := Slot(ASource, AServer2);
  if (LFirst < 0) or (LSecond < 0) then
    Exit(0);
  LServer1 := FLists[ASource][LFirst];
  LServer2 := FLists[ASource][LSecond];
  Result := 0;
  case ASortKey of
    Q3_SORT_HOST:
      Result := CompareNoCase(LServer1.HostName, LServer2.HostName);
    Q3_SORT_MAP:
      Result := CompareNoCase(LServer1.MapName, LServer2.MapName);
    Q3_SORT_CLIENTS:
      Result := Order(LServer1.Clients, LServer2.Clients);
    Q3_SORT_GAME:
      Result := Order(LServer1.GameType, LServer2.GameType);
    Q3_SORT_PING:
      Result := Order(LServer1.Ping, LServer2.Ping);
  end;
  if ASortDirection <> 0 then
  begin
    if Result < 0 then
      Exit(1);
    if Result > 0 then
      Exit(-1);
    Exit(0);
  end;
end;

function TQ3LanServers.GetPingQueueCount: Integer;
begin
  Result := 0;
end;

procedure TQ3LanServers.ClearPing(AIndex: Integer);
begin
  // every slot of the queue is empty already
end;

procedure TQ3LanServers.GetPing(AIndex: Integer; out AAddress: AnsiString; out APingTime: Integer);
begin
  // an empty slot
  AAddress := '';
  APingTime := 0;
end;

function TQ3LanServers.GetPingInfo(AIndex: Integer): AnsiString;
begin
  Result := '';
end;

function TQ3LanServers.ServerStatus(const AAddress: AnsiString; out AStatus: AnsiString): Integer;
begin
  // the request would go out and the answer come later: nothing comes
  AStatus := '';
  Result := 0;
end;

end.
