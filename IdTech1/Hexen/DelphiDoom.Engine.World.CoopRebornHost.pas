{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the host of the reborn of a player in Hexen            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.CoopRebornHost;

interface

uses
  DelphiDoom.Thinkers.CoopReborn.Intf;

type
  /// <summary>
  ///   Hexen for G_DoReborn: the players, the saved hub position and the starting points of the
  ///   current hub position (RebornPosition of g_game, given as a pointer)
  /// </summary>
  TCoopRebornHost = class(TInterfacedObject, ICoopRebornHost)
  strict private
    FRebornPosition: PInteger;
    FConsolePlayer: PInteger;
  public
    /// <summary>The links to RebornPosition and to consoleplayer of g_game; they cannot be nil</summary>
    constructor Create(const ARebornPosition, AConsolePlayer: PInteger);

    function RebornSlotAvailable: Boolean;
    procedure RequestGameAction(const ALoadHubPosition: Boolean);
    procedure DetachCorpse(const APlayer: Integer);
    procedure SpawnDeathMatch(const APlayer: Integer);
    function CheckSpot(const APlayer, AIndex: Integer): Boolean;
    procedure Spawn(const AIndex: Integer);
    procedure SetSpotType(const AIndex, AType: Integer);
    function Keys(const APlayer: Integer): Integer;
    procedure SetKeys(const APlayer, AKeys: Integer);
    function Pieces(const APlayer: Integer): Integer;
    procedure SetPieces(const APlayer, APieces: Integer);
    function WeaponCount: Integer;
    function WeaponOwned(const APlayer, AWeapon: Integer): Boolean;
    procedure GiveWeapon(const APlayer, AWeapon: Integer);
    procedure SetMana(const APlayer, AAmount: Integer);
    procedure SetPendingWeapon(const APlayer, AWeapon: Integer);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Thinkers.SpawnSpot,
  DelphiDoom.Engine.World.PlayerRespawnHost,
  m_fixed,
  doomdef,
  doomdata,
  d_event,
  g_game,
  p_mobj,
  p_setup,
  sv_save;

{ TCoopRebornHost }

constructor TCoopRebornHost.Create(const ARebornPosition, AConsolePlayer: PInteger);
begin
  inherited Create;
  if not Assigned(ARebornPosition) then
    raise EArgumentNilException.Create('ARebornPosition');
  if not Assigned(AConsolePlayer) then
    raise EArgumentNilException.Create('AConsolePlayer');
  FRebornPosition := ARebornPosition;
  FConsolePlayer := AConsolePlayer;
end;

function TCoopRebornHost.RebornSlotAvailable: Boolean;
begin
  Result := SV_RebornSlotAvailable;
end;

procedure TCoopRebornHost.RequestGameAction(const ALoadHubPosition: Boolean);
begin
  if ALoadHubPosition then
    TGameSession.GameAction := ga_singlereborn
  else
    TGameSession.GameAction := ga_newgame;
end;

procedure TCoopRebornHost.DetachCorpse(const APlayer: Integer);
begin
  TGameSession.Players[APlayer].mo.player := nil;
end;

procedure TCoopRebornHost.SpawnDeathMatch(const APlayer: Integer);
begin
  G_DeathMatchSpawnPlayer(APlayer);
end;

function TCoopRebornHost.CheckSpot(const APlayer, AIndex: Integer): Boolean;
var
  LThing: Pmapthing_t;
begin
  // G_CheckSpot of g_game
  LThing := @playerstarts[FRebornPosition^, AIndex];
  Result := TSpawnSpot.Check(TPlayerRespawnHost.Create(FConsolePlayer), APlayer,
    LThing.x * FRACUNIT, LThing.y * FRACUNIT, LThing.angle);
end;

procedure TCoopRebornHost.Spawn(const AIndex: Integer);
begin
  P_SpawnPlayer(@playerstarts[FRebornPosition^, AIndex], @uplayerstarts[FRebornPosition^, AIndex]);
end;

procedure TCoopRebornHost.SetSpotType(const AIndex, AType: Integer);
begin
  playerstarts[FRebornPosition^, AIndex]._type := AType;
end;

function TCoopRebornHost.Keys(const APlayer: Integer): Integer;
begin
  Result := TGameSession.Players[APlayer].keys;
end;

procedure TCoopRebornHost.SetKeys(const APlayer, AKeys: Integer);
begin
  TGameSession.Players[APlayer].keys := AKeys;
end;

function TCoopRebornHost.Pieces(const APlayer: Integer): Integer;
begin
  Result := TGameSession.Players[APlayer].pieces;
end;

procedure TCoopRebornHost.SetPieces(const APlayer, APieces: Integer);
begin
  TGameSession.Players[APlayer].pieces := APieces;
end;

function TCoopRebornHost.WeaponCount: Integer;
begin
  Result := Ord(NUMWEAPONS);
end;

function TCoopRebornHost.WeaponOwned(const APlayer, AWeapon: Integer): Boolean;
begin
  Result := TGameSession.Players[APlayer].weaponowned[AWeapon];
end;

procedure TCoopRebornHost.GiveWeapon(const APlayer, AWeapon: Integer);
begin
  TGameSession.Players[APlayer].weaponowned[AWeapon] := True;
end;

procedure TCoopRebornHost.SetMana(const APlayer, AAmount: Integer);
begin
  TGameSession.Players[APlayer].mana[Ord(MANA_1)] := AAmount;
  TGameSession.Players[APlayer].mana[Ord(MANA_2)] := AAmount;
end;

procedure TCoopRebornHost.SetPendingWeapon(const APlayer, AWeapon: Integer);
begin
  TGameSession.Players[APlayer].pendingweapon := weapontype_t(AWeapon);
end;

end.
