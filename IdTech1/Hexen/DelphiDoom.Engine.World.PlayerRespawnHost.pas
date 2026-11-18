{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the host of the respawn of a player in Hexen           }
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
  DelphiDoom.Thinkers.PlayerRespawn.Intf,
  DelphiDoom.Thinkers.SpawnSpot;

type
  /// <summary>
  ///   Hexen for G_DeathMatchSpawnPlayer and G_CheckSpot: the players, the starting
  ///   points and the objects of the engine
  /// </summary>
  /// <remarks>
  ///   Hexen keeps its own G_DoReborn (it carries keys and weapons over), so only the deathmatch
  ///   respawn uses this host: ReloadLevel, DetachCorpse and the player start spots are not supported.
  ///   The fallback of a deathmatch respawn passes the row playernum of the 2D table playerstarts (its first
  ///   column): a defect of the old code, kept
  /// </remarks>
  TPlayerRespawnHost = class(TInterfacedObject, IPlayerRespawnHost, ISpawnSpotHost)
  strict private
    FConsolePlayer: PInteger;
  public
    /// <summary>The link to consoleplayer of g_game; it cannot be nil</summary>
    constructor Create(const AConsolePlayer: PInteger);

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
  d_player,
  info_h,
  i_system,
  m_rnd,
  p_setup,
  p_tick,
  p_mobj_h,
  p_mobj,
  p_map,
  udmf_telept,
  r_defs,
  r_main,
  s_sound,
  sounddata;

{ TPlayerRespawnHost }

constructor TPlayerRespawnHost.Create(const AConsolePlayer: PInteger);
begin
  inherited Create;
  if not Assigned(AConsolePlayer) then
    raise EArgumentNilException.Create('AConsolePlayer');
  FConsolePlayer := AConsolePlayer;
end;

procedure TPlayerRespawnHost.ReloadLevel;
begin
  raise ENotSupportedException.Create('ReloadLevel: G_DoReborn of Hexen is not in the class');
end;

procedure TPlayerRespawnHost.DetachCorpse(const APlayer: Integer);
begin
  raise ENotSupportedException.Create('DetachCorpse: G_DoReborn of Hexen is not in the class');
end;

function TPlayerRespawnHost.CheckSpot(const APlayer: Integer; const AKind: TPlayerSpotKind;
  const AIndex: Integer): Boolean;
var
  LThing: Pmapthing_t;
begin
  if AKind = pskPlayerStart then
    raise ENotSupportedException.Create('CheckSpot: the player starts of Hexen are not in the class');
  LThing := @deathmatchstarts[AIndex];
  Result := TSpawnSpot.Check(Self, APlayer, LThing.x * FRACUNIT, LThing.y * FRACUNIT, LThing.angle);
end;

procedure TPlayerRespawnHost.Spawn(const AKind: TPlayerSpotKind; const AIndex: Integer);
begin
  if AKind = pskPlayerStart then
    P_SpawnPlayer(@playerstarts[AIndex], @uplayerstarts[AIndex])
  else
    P_SpawnPlayer(@deathmatchstarts[AIndex], @udeathmatchstarts[AIndex]);
end;

procedure TPlayerRespawnHost.SetSpotType(const AKind: TPlayerSpotKind; const AIndex, AType: Integer);
begin
  if AKind = pskPlayerStart then
    raise ENotSupportedException.Create('SetSpotType: the player starts of Hexen are not in the class');
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
  I_Error('G_DeathMatchSpawnPlayer(): Only %d deathmatch spots, 4 required', [ACount]);
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
  TGameSession.Players[APlayer].mo.flags2 := TGameSession.Players[APlayer].mo.flags2 and not MF2_PASSMOBJ;
end;

procedure TPlayerRespawnHost.EndPositionTest(const APlayer: Integer);
begin
  TGameSession.Players[APlayer].mo.flags2 := TGameSession.Players[APlayer].mo.flags2 or MF2_PASSMOBJ;
end;

function TPlayerRespawnHost.SpotHeight(const APlayer, AX, AY: Integer): Integer;
var
  LSubsector: Psubsector_t;
begin
  // JVAL: 3d floors
  LSubsector := TRendererMain.R_PointInSubsector(AX, AY);
  Result := LSubsector.sector.floorheight;
  if LSubsector.sector.midsec >= 0 then
    if TGameSession.Players[APlayer].mo.spawnpoint.options and MTF_ONMIDSECTOR <> 0 then
      Result := sectors[LSubsector.sector.midsec].ceilingheight;
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
    AHeight + TELEFOGHEIGHT, Ord(MT_TFOG));

  if TGameSession.Players[FConsolePlayer^].viewz <> 1 then
    TSoundRoutines.S_StartSound(LFog, Ord(SFX_TELEPORT));  // don't start sound on first frame
end;

end.
