{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the world of a level (thinkers, time, random)          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World;

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.BodyQueue,
  DelphiDoom.Thinkers.List,
  DelphiDoom.Thinkers.LevelTotals,
  DelphiDoom.Thinkers.RespawnQueue,
  doomdata,
  d_think,
  p_mobj_h;

type
  /// <summary>
  ///   The time of the level, as references to the memory where the engine keeps it (the saved
  ///   games write it there): the classes read and write through these, never the globals
  /// </summary>
  TEngineWorldTime = record
    /// <summary>The tics of the level (leveltime)</summary>
    LevelTime: PInteger;
    /// <summary>The thinkers that are not of a player stand still (isgamefreezed)</summary>
    IsFrozen: PBoolean;
    /// <summary>The last tic did not run: pause, menu, console (isgamesuspended)</summary>
    IsSuspended: PBoolean;
    /// <summary>The tics left of a timed game; nil in the games that have none (only Hexen has it)</summary>
    TimerGame: PInteger;
  end;

  /// <summary>
  ///   The deterministic state of the level: the one owner of the list of the thinkers, of the
  ///   time and of the random numbers of the game
  /// </summary>
  /// <remarks>
  ///   The turn of the thinkers is the hot path: no method here is virtual and the list is called
  ///   as an object, not through an interface
  /// </remarks>
  TEngineWorld = class sealed
  strict private
    FThinkers: TThinkerList;
    FTime: TEngineWorldTime;
    FRandom: IGameRandom;
    FItemRespawn: TRespawnQueue<mapthing_t>;
    FPlayerCorpses: TBodyQueue;
    FTotals: TLevelTotals;
    FEnemyCorpses: TBodyQueue;
  public
    /// <param name="AThinkerCap">The head of the list of the thinkers (it stays where the saved games look for it)</param>
    /// <param name="ATime">Where the time of the level is kept; only TimerGame may be nil</param>
    /// <param name="ARandom">The random numbers of the game (the ones of P_Random)</param>
    /// <exception cref="EArgumentNilException">A required argument is nil</exception>
    constructor Create(AThinkerCap: Pthinker_t; const ATime: TEngineWorldTime;
      const ARandom: IGameRandom);
    destructor Destroy; override;

    /// <summary>The turn of the thinkers of a tic, all of them or only the ones that run while frozen</summary>
    procedure RunThinkers;

    property Thinkers: TThinkerList read FThinkers;
    property Time: TEngineWorldTime read FTime;
    property Random: IGameRandom read FRandom;
    /// <summary>The items that come back in a deathmatch 2 game (not written in the saved games)</summary>
    property ItemRespawn: TRespawnQueue<mapthing_t> read FItemRespawn;
    /// <summary>The corpses of the players left on the spawn spots (bodyque of g_game); emptied when the things of a level are spawned</summary>
    property PlayerCorpses: TBodyQueue read FPlayerCorpses;
    /// <summary>The corpses added by A_AddPlayerCorpse (Heretic and Hexen): a queue of its own, never emptied between levels, as before</summary>
    property EnemyCorpses: TBodyQueue read FEnemyCorpses;
    /// <summary>The monsters, items and secret sectors of the level (totalkills, totalitems, totalsecret; not written in the saved games)</summary>
    property Totals: TLevelTotals read FTotals;

    /// <summary>Keeps the corpse of a player left on a spawn spot and removes the oldest one if the queue is full</summary>
    procedure AddPlayerCorpse(AMobj: Pmobj_t);
    /// <summary>Keeps a corpse added by an action and removes the oldest one if the queue is full</summary>
    procedure AddEnemyCorpse(AMobj: Pmobj_t);
    /// <summary>Forgets the corpses of the spawn spots (the things of a new level are spawned)</summary>
    procedure ClearPlayerCorpses;
  end;

implementation

uses
  System.SysUtils,
  p_mobj,
  p_mobjlist,
  z_zone;

// The index of the map objects by key follows the list: it is emptied with it

procedure WorldThinkersCleared;
begin
  mobjlist.Clear;
end;

procedure WorldThinkerAdded(ANode: PThinkerNode);
begin
  if @ANode.Think = @P_MobjThinker then
    mobjlist.Add(Pmobj_t(ANode));
end;

procedure WorldThinkerRemoved(ANode: PThinkerNode);
begin
  if @ANode.Think = @P_MobjThinker then
    mobjlist.Remove(Pmobj_t(ANode));
end;

// The thinkers are blocks of the zone memory
procedure WorldThinkerRelease(ANode: PThinkerNode);
begin
  Z_Free(ANode);
end;

// While the game is frozen only the players and the objects that ignore the freeze think
function WorldThinkerRunsWhenFrozen(ANode: PThinkerNode): Boolean;
begin
  Result := False;
  if @ANode.Think = @P_MobjThinker then
    if (Pmobj_t(ANode).player <> nil) or (Pmobj_t(ANode).flags3_ex and MF3_EX_NOTIMEFREEZE <> 0) then
      Result := True;
end;

{ TEngineWorld }

constructor TEngineWorld.Create(AThinkerCap: Pthinker_t; const ATime: TEngineWorldTime;
  const ARandom: IGameRandom);
var
  LHooks: TThinkerListHooks;
begin
  inherited Create;
  if not Assigned(ATime.LevelTime) then
    raise EArgumentNilException.Create('ATime.LevelTime');
  if not Assigned(ATime.IsFrozen) then
    raise EArgumentNilException.Create('ATime.IsFrozen');
  if not Assigned(ATime.IsSuspended) then
    raise EArgumentNilException.Create('ATime.IsSuspended');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FTime := ATime;
  FRandom := ARandom;
  LHooks.Cleared := WorldThinkersCleared;
  LHooks.Added := WorldThinkerAdded;
  LHooks.Removed := WorldThinkerRemoved;
  LHooks.Release := WorldThinkerRelease;
  LHooks.RunsWhenFrozen := WorldThinkerRunsWhenFrozen;
  // thinker_t and TThinkerNode have the same layout: three pointers
  FThinkers := TThinkerList.Create(PThinkerNode(AThinkerCap), LHooks);
  FItemRespawn := TRespawnQueue<mapthing_t>.Create;
  FPlayerCorpses := TBodyQueue.Create;
  FEnemyCorpses := TBodyQueue.Create;
  FTotals := TLevelTotals.Create;
end;

destructor TEngineWorld.Destroy;
begin
  FTotals.Free;
  FEnemyCorpses.Free;
  FPlayerCorpses.Free;
  FItemRespawn.Free;
  FThinkers.Free;
  inherited;
end;

procedure TEngineWorld.AddPlayerCorpse(AMobj: Pmobj_t);
var
  LEvicted: Pointer;
begin
  // too many corpses: remove an old one
  LEvicted := FPlayerCorpses.Add(AMobj);
  if LEvicted <> nil then
    P_RemoveMobj(LEvicted);
end;

procedure TEngineWorld.AddEnemyCorpse(AMobj: Pmobj_t);
var
  LEvicted: Pointer;
begin
  LEvicted := FEnemyCorpses.Add(AMobj);
  if LEvicted <> nil then
    P_RemoveMobj(LEvicted);
end;

procedure TEngineWorld.ClearPlayerCorpses;
begin
  FPlayerCorpses.Clear;
end;

procedure TEngineWorld.RunThinkers;
begin
  if FTime.IsFrozen^ then
    FThinkers.RunFrozen
  else
    FThinkers.Run;
end;

end.
