{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the host of the respawn of a player in Doom            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PlayerRespawnHost;

interface

uses
  d_event,
  DelphiDoom.Thinkers.PlayerRespawn.Intf,
  DelphiDoom.Thinkers.SpawnSpot;

type
  /// <summary>G_PlayingEngineVersion of g_game: the unit cannot use g_game, so the function is given</summary>
  TPlayingEngineVersion = function: Integer;

  /// <summary>The pointer to gameaction of g_game</summary>
  PGameAction = ^gameaction_t;

  /// <summary>
  ///   Doom (and Radix and Speed, which take its code) for G_DoReborn, G_DeathMatchSpawnPlayer and
  ///   G_CheckSpot: the players, the starting points and the objects of the engine
  /// </summary>
  /// <remarks>
  ///   Doom passes the extra data of the deathmatch starts (udeathmatchstarts) also with the player
  ///   starts; the old code did so and it is kept
  /// </remarks>
  TPlayerRespawnHost = class(TInterfacedObject, IPlayerRespawnHost, ISpawnSpotHost)
  strict private
    FConsolePlayer: PInteger;
    FGameAction: PGameAction;
    FEngineVersion: TPlayingEngineVersion;
  public
    /// <summary>The links to what g_game owns; none can be nil</summary>
    constructor Create(const AConsolePlayer: PInteger; const AGameAction: PGameAction;
      const AEngineVersion: TPlayingEngineVersion);

    // IPlayerRespawnHost
    procedure ReloadLevel;
    procedure DetachCorpse(const APlayer: Integer);
    function CheckSpot(const APlayer: Integer; const AKind: TPlayerSpotKind;
      const AIndex: Integer): Boolean;
    procedure Spawn(const AKind: TPlayerSpotKind; const AIndex: Integer);
    procedure SetSpotType(const AKind: TPlayerSpotKind; const AIndex, AType: Integer);
    function DeathMatchSpotCount: Integer;
    function NextRandom: Integer;
    procedure TooFewDeathMatchSpots(const ACount: Integer);

    // ISpawnSpotHost
    function PlayerHasBody(const APlayer: Integer): Boolean;
    function PlayerBodyX(const APlayer: Integer): Integer;
    function PlayerBodyY(const APlayer: Integer): Integer;
    procedure BeginPositionTest(const APlayer: Integer);
    procedure EndPositionTest(const APlayer: Integer);
    function SpotHeight(const APlayer, AX, AY: Integer): Integer;
    function PositionFree(const APlayer, AX, AY: Integer): Boolean;
    procedure FlushCorpse(const APlayer: Integer);
    procedure SpawnFog(const AX, AY, AHeight, AFineAngle: Integer);
  end;

implementation

uses
  g_game,
  System.SysUtils,
  m_fixed,
  tables,
  doomdef,
  doomdata,
  doomstat,
  d_player,
  info_h,
  i_system,
  m_rnd,
  p_setup,
  p_tick,
  p_mobj_h,
  p_mobj,
  p_map,
  DelphiDoom.Engine.World.MapRules,
  r_defs,
  s_sound,
  sounddata;

{ TPlayerRespawnHost }

constructor TPlayerRespawnHost.Create(const AConsolePlayer: PInteger;
  const AGameAction: PGameAction; const AEngineVersion: TPlayingEngineVersion);
begin
  inherited Create;
  if not Assigned(AConsolePlayer) then
    raise EArgumentNilException.Create('AConsolePlayer');
  if not Assigned(AGameAction) then
    raise EArgumentNilException.Create('AGameAction');
  if not Assigned(AEngineVersion) then
    raise EArgumentNilException.Create('AEngineVersion');
  FConsolePlayer := AConsolePlayer;
  FGameAction := AGameAction;
  FEngineVersion := AEngineVersion;
end;

procedure TPlayerRespawnHost.ReloadLevel;
begin
  FGameAction^ := ga_loadlevel;
end;

procedure TPlayerRespawnHost.DetachCorpse(const APlayer: Integer);
begin
  TGameSession.Players[APlayer].mo.player := nil;
end;

function TPlayerRespawnHost.CheckSpot(const APlayer: Integer; const AKind: TPlayerSpotKind;
  const AIndex: Integer): Boolean;
var
  LThing: Pmapthing_t;
begin
  if AKind = pskPlayerStart then
    LThing := @playerstarts[AIndex]
  else
    LThing := @deathmatchstarts[AIndex];
  Result := TSpawnSpot.Check(Self, APlayer, LThing.x * FRACUNIT, LThing.y * FRACUNIT, LThing.angle);
end;

procedure TPlayerRespawnHost.Spawn(const AKind: TPlayerSpotKind; const AIndex: Integer);
begin
  if AKind = pskPlayerStart then
    P_SpawnPlayer(@playerstarts[AIndex], @udeathmatchstarts[AIndex])
  else
    P_SpawnPlayer(@deathmatchstarts[AIndex], @udeathmatchstarts[AIndex]);
end;

procedure TPlayerRespawnHost.SetSpotType(const AKind: TPlayerSpotKind; const AIndex, AType: Integer);
begin
  if AKind = pskPlayerStart then
    playerstarts[AIndex]._type := AType
  else
    deathmatchstarts[AIndex]._type := AType;
end;

function TPlayerRespawnHost.DeathMatchSpotCount: Integer;
begin
  Result := deathmatch_p; // JVAL - deathmatchstarts;
end;

function TPlayerRespawnHost.NextRandom: Integer;
begin
  Result := P_Random;
end;

procedure TPlayerRespawnHost.TooFewDeathMatchSpots(const ACount: Integer);
begin
  I_Warning('G_DeathMatchSpawnPlayer(): Only %d deathmatch spots, 4 required', [ACount]);
end;

function TPlayerRespawnHost.PlayerHasBody(const APlayer: Integer): Boolean;
begin
  Result := TGameSession.Players[APlayer].mo <> nil;
end;

function TPlayerRespawnHost.PlayerBodyX(const APlayer: Integer): Integer;
begin
  Result := TGameSession.Players[APlayer].mo.x;
end;

function TPlayerRespawnHost.PlayerBodyY(const APlayer: Integer): Integer;
begin
  Result := TGameSession.Players[APlayer].mo.y;
end;

procedure TPlayerRespawnHost.BeginPositionTest(const APlayer: Integer);
begin
  TGameSession.Players[APlayer].mo.flags2_ex := TGameSession.Players[APlayer].mo.flags2_ex and not MF2_EX_PASSMOBJ;
end;

procedure TPlayerRespawnHost.EndPositionTest(const APlayer: Integer);
begin
  if FEngineVersion > VERSION120 then
    TGameSession.Players[APlayer].mo.flags2_ex := TGameSession.Players[APlayer].mo.flags2_ex or MF2_EX_PASSMOBJ;
end;

function TPlayerRespawnHost.SpotHeight(const APlayer, AX, AY: Integer): Integer;
var
  LSector: Psector_t;
begin
  // JVAL: 3d floors
  LSector := P_PointInSector(AX, AY);
  Result := LSector.floorheight;
  if LSector.midsec >= 0 then
    if TGameSession.Players[APlayer].mo.spawnpoint.options and MTF_ONMIDSECTOR <> 0 then
      Result := sectors[LSector.midsec].ceilingheight;
end;

function TPlayerRespawnHost.PositionFree(const APlayer, AX, AY: Integer): Boolean;
begin
  Result := P_CheckPosition(TGameSession.Players[APlayer].mo, AX, AY);
end;

procedure TPlayerRespawnHost.FlushCorpse(const APlayer: Integer);
begin
  P_World.AddPlayerCorpse(TGameSession.Players[APlayer].mo);
end;

procedure TPlayerRespawnHost.SpawnFog(const AX, AY, AHeight, AFineAngle: Integer);
var
  LFog: Pmobj_t;
begin
  LFog := P_SpawnMobj(AX + 20 * finecosine[AFineAngle], AY + 20 * finesine[AFineAngle],
    AHeight, Ord(MT_TFOG));

  if TGameSession.Players[FConsolePlayer^].viewz <> 1 then
    S_StartSound(LFog, Ord(sfx_telept));  // don't start sound on first frame
end;

end.
