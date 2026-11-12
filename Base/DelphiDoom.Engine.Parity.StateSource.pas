{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the state of the game for the parity tools             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.StateSource;

interface

uses
  System.Generics.Collections,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Parity.Intf,
  d_player,
  info_h,
  p_mobj_h,
  r_defs;

type
  /// <summary>
  ///   Reads the deterministic state of the game (mobjs in the order of the thinkers, sectors, lines, sides,
  ///   players, the time of the level and the indexes of the random numbers) and tells it to an
  ///   IParityStateSink. Pointers never go in: a mobj that another mobj points to (target, tracer) is told by
  ///   its number in the list of the mobjs. The fields of a record that differ from game to game are in
  ///   the blocks marked with the game: that is the only place of the tools that knows the games
  /// </summary>
  TEngineParityStateSource = class
  strict private
    FSink: IParityStateSink;
    FRandom: IGameRandom;
    FMobjIndexes: TDictionary<Pointer, Integer>;
    FRegistering: Boolean;
    FNames: TArray<string>;
    FFieldIndex: Integer;
    FMobjCategory: Integer;
    FSectorCategory: Integer;
    FSideCategory: Integer;
    FLineCategory: Integer;
    FPlayerCategory: Integer;
    procedure Put(const AName: string; AValue: Int64);
    procedure PutIndexed(const APrefix: string; AIndex: Integer; AValue: Int64);
    function StateIndex(AState: Pstate_t): Integer;
    function MobjIndex(AMobj: Pmobj_t): Integer;
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
    function MobjOrValue(AValue: Integer): Int64;
{$IFEND}
    procedure PutMobj(const AMobj: mobj_t);
    procedure PutSector(const ASector: sector_t);
    procedure PutSide(const ASide: side_t);
    procedure PutLine(const ALine: line_t);
    procedure PutPlayer(const APlayer: player_t);
    procedure RegisterCategories;
    function RegisterOne(const AName: string; AKind: Integer): Integer;
  public
    constructor Create(const ASink: IParityStateSink; const ARandom: IGameRandom);
    destructor Destroy; override;
    /// <summary>Tells the state after the tic ATic (call it at the end of P_Ticker)</summary>
    procedure Publish(ATic: Integer);
  end;

implementation

uses
  System.SysUtils,
  d_think,
  doomdef,
  g_game,
  info,
  m_fixed,
  p_mobj,
  p_setup,
  p_tick;

const
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  // a special that points to the mobj number N is told as -MOBJ_LINK_BASE - N (a real special is never so small)
  MOBJ_LINK_BASE = 1000000000;
{$IFEND}
  KIND_MOBJ = 0;
  KIND_SECTOR = 1;
  KIND_SIDE = 2;
  KIND_LINE = 3;
  KIND_PLAYER = 4;

{ TEngineParityStateSource }

constructor TEngineParityStateSource.Create(const ASink: IParityStateSink; const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FSink := ASink;
  FRandom := ARandom;
  FMobjIndexes := TDictionary<Pointer, Integer>.Create;
  RegisterCategories;
end;

destructor TEngineParityStateSource.Destroy;
begin
  FMobjIndexes.Free;
  inherited Destroy;
end;

procedure TEngineParityStateSource.Put(const AName: string; AValue: Int64);
begin
  if FRegistering then
  begin
    SetLength(FNames, Length(FNames) + 1);
    FNames[High(FNames)] := AName;
  end
  else
    FSink.Field(FFieldIndex, AValue);
  Inc(FFieldIndex);
end;

procedure TEngineParityStateSource.PutIndexed(const APrefix: string; AIndex: Integer; AValue: Int64);
begin
  if FRegistering then
    Put(APrefix + IntToStr(AIndex), AValue)
  else
  begin
    FSink.Field(FFieldIndex, AValue);
    Inc(FFieldIndex);
  end;
end;

function TEngineParityStateSource.StateIndex(AState: Pstate_t): Integer;
begin
  if (AState = nil) or (states = nil) then
    Result := -1
  else
    Result := Integer((NativeUInt(AState) - NativeUInt(states)) div SizeOf(state_t));
end;

function TEngineParityStateSource.MobjIndex(AMobj: Pmobj_t): Integer;
begin
  if AMobj = nil then
    Exit(-1);
  if not FMobjIndexes.TryGetValue(AMobj, Result) then
    Result := -2;
end;

{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
function TEngineParityStateSource.MobjOrValue(AValue: Integer): Int64;
var
  LIndex: Integer;
begin
  // the specials of Heretic and Hexen hold sometimes the address of a mobj (a 32 bit address as an integer):
  // an address changes from run to run, the number of the mobj does not
  if (AValue <> 0) and FMobjIndexes.TryGetValue(Pointer(AValue), LIndex) then
    Result := -MOBJ_LINK_BASE - LIndex
  else
    Result := AValue;
end;
{$IFEND}

procedure TEngineParityStateSource.PutMobj(const AMobj: mobj_t);
begin
  Put('type', AMobj._type);
  Put('x', AMobj.x);
  Put('y', AMobj.y);
  Put('z', AMobj.z);
  Put('angle', AMobj.angle);
  Put('momx', AMobj.momx);
  Put('momy', AMobj.momy);
  Put('momz', AMobj.momz);
  Put('floorz', AMobj.floorz);
  Put('ceilingz', AMobj.ceilingz);
  Put('radius', AMobj.radius);
  Put('height', AMobj.height);
  Put('health', AMobj.health);
  Put('state', StateIndex(AMobj.state));
  Put('tics', AMobj.tics);
  Put('flags', AMobj.flags);
  Put('flags_ex', AMobj.flags_ex);
  Put('flags2_ex', AMobj.flags2_ex);
  Put('flags3_ex', AMobj.flags3_ex);
  Put('flags4_ex', AMobj.flags4_ex);
  Put('movedir', AMobj.movedir);
  Put('movecount', AMobj.movecount);
  Put('reactiontime', AMobj.reactiontime);
  Put('threshold', AMobj.threshold);
  Put('lastlook', AMobj.lastlook);
  Put('gravity', AMobj.gravity);
  Put('tid', AMobj.tid);
  Put('special', AMobj.special);
  Put('target', MobjIndex(AMobj.target));
  Put('tracer', MobjIndex(AMobj.tracer));
{$IF DEFINED(HERETIC) OR DEFINED(HEXEN)}
  Put('flags2', AMobj.flags2);
  Put('special1', MobjOrValue(AMobj.special1));
  Put('special2', MobjOrValue(AMobj.special2));
{$ENDIF}
end;

procedure TEngineParityStateSource.PutSector(const ASector: sector_t);
begin
  Put('floorheight', ASector.floorheight);
  Put('ceilingheight', ASector.ceilingheight);
  Put('floorpic', ASector.floorpic);
  Put('ceilingpic', ASector.ceilingpic);
  Put('lightlevel', ASector.lightlevel);
  Put('special', ASector.special);
  Put('tag', ASector.tag);
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  Put('floor_xoffs', ASector.floor_xoffs);
  Put('floor_yoffs', ASector.floor_yoffs);
  Put('ceiling_xoffs', ASector.ceiling_xoffs);
  Put('ceiling_yoffs', ASector.ceiling_yoffs);
{$ENDIF}
end;

procedure TEngineParityStateSource.PutSide(const ASide: side_t);
begin
  Put('textureoffset', ASide.textureoffset);
  Put('rowoffset', ASide.rowoffset);
  Put('toptexture', ASide.toptexture);
  Put('bottomtexture', ASide.bottomtexture);
  Put('midtexture', ASide.midtexture);
end;

procedure TEngineParityStateSource.PutLine(const ALine: line_t);
begin
  Put('flags', ALine.flags);
  Put('special', ALine.special);
{$IFNDEF HEXEN}
  Put('tag', ALine.tag);
{$ENDIF}
end;

procedure TEngineParityStateSource.PutPlayer(const APlayer: player_t);
var
  LIndex: Integer;
begin
  Put('playerstate', Ord(APlayer.playerstate));
  Put('mo', MobjIndex(APlayer.mo));
  Put('viewz', APlayer.viewz);
  Put('viewheight', APlayer.viewheight);
  Put('deltaviewheight', APlayer.deltaviewheight);
  Put('bob', APlayer.bob);
  Put('lookdir', APlayer.lookdir);
  Put('health', APlayer.health);
  Put('readyweapon', Ord(APlayer.readyweapon));
  Put('pendingweapon', Ord(APlayer.pendingweapon));
  Put('attackdown', Ord(APlayer.attackdown));
  Put('usedown', Ord(APlayer.usedown));
  Put('cheats', APlayer.cheats);
  Put('refire', APlayer.refire);
  Put('killcount', APlayer.killcount);
{$IFNDEF STRIFE}
  Put('secretcount', APlayer.secretcount);
{$ENDIF}
  Put('damagecount', APlayer.damagecount);
  Put('bonuscount', APlayer.bonuscount);
  Put('extralight', APlayer.extralight);
  Put('fixedcolormap', APlayer.fixedcolormap);
  Put('cmd_forwardmove', APlayer.cmd.forwardmove);
  Put('cmd_sidemove', APlayer.cmd.sidemove);
  Put('cmd_angleturn', APlayer.cmd.angleturn);
  Put('cmd_buttons', APlayer.cmd.buttons);
  for LIndex := 0 to High(APlayer.powers) do
    PutIndexed('power', LIndex, APlayer.powers[LIndex]);
  for LIndex := 0 to High(APlayer.weaponowned) do
    PutIndexed('weaponowned', LIndex, Ord(APlayer.weaponowned[LIndex]));
  for LIndex := 0 to High(APlayer.frags) do
    PutIndexed('frags', LIndex, APlayer.frags[LIndex]);
  for LIndex := 0 to High(APlayer.psprites) do
  begin
    PutIndexed('psprite_state', LIndex, StateIndex(APlayer.psprites[LIndex].state));
    PutIndexed('psprite_tics', LIndex, APlayer.psprites[LIndex].tics);
    PutIndexed('psprite_sx', LIndex, APlayer.psprites[LIndex].sx);
    PutIndexed('psprite_sy', LIndex, APlayer.psprites[LIndex].sy);
  end;
{$IF DEFINED(HEXEN)}
  Put('class', Ord(APlayer._class));
  for LIndex := 0 to High(APlayer.armorpoints) do
    PutIndexed('armorpoints', LIndex, APlayer.armorpoints[LIndex]);
  for LIndex := 0 to High(APlayer.mana) do
    PutIndexed('mana', LIndex, APlayer.mana[LIndex]);
  Put('keys', APlayer.keys);
  Put('pieces', APlayer.pieces);
  Put('itemcount', APlayer.itemcount);
{$ELSE}
  Put('armorpoints', APlayer.armorpoints);
  Put('armortype', APlayer.armortype);
  for LIndex := 0 to High(APlayer.ammo) do
    PutIndexed('ammo', LIndex, APlayer.ammo[LIndex]);
  for LIndex := 0 to High(APlayer.maxammo) do
    PutIndexed('maxammo', LIndex, APlayer.maxammo[LIndex]);
{$IF DEFINED(HERETIC)}
  for LIndex := 0 to High(APlayer.keys) do
    PutIndexed('keys', LIndex, Ord(APlayer.keys[LIndex]));
  Put('itemcount', APlayer.itemcount);
{$ELSE}
  for LIndex := 0 to High(APlayer.cards) do
    PutIndexed('cards', LIndex, Ord(APlayer.cards[LIndex]));
{$IFNDEF STRIFE}
  Put('itemcount', APlayer.itemcount);
{$ENDIF}
{$IFEND}
{$IFEND}
end;

function TEngineParityStateSource.RegisterOne(const AName: string; AKind: Integer): Integer;
var
  LMobj: mobj_t;
  LSector: sector_t;
  LSide: side_t;
  LLine: line_t;
  LPlayer: player_t;
begin
  // a record of zeros tells the names of the fields: the same code that later tells the values
  FRegistering := True;
  FFieldIndex := 0;
  SetLength(FNames, 0);
  case AKind of
    KIND_MOBJ:
      begin
        FillChar(LMobj, SizeOf(LMobj), 0);
        PutMobj(LMobj);
      end;
    KIND_SECTOR:
      begin
        FillChar(LSector, SizeOf(LSector), 0);
        PutSector(LSector);
      end;
    KIND_SIDE:
      begin
        FillChar(LSide, SizeOf(LSide), 0);
        PutSide(LSide);
      end;
    KIND_LINE:
      begin
        FillChar(LLine, SizeOf(LLine), 0);
        PutLine(LLine);
      end;
    KIND_PLAYER:
      begin
        FillChar(LPlayer, SizeOf(LPlayer), 0);
        PutPlayer(LPlayer);
      end;
  end;
  FRegistering := False;
  Result := FSink.RegisterCategory(AName, FNames);
end;

procedure TEngineParityStateSource.RegisterCategories;
begin
  FMobjCategory := RegisterOne('mobj', KIND_MOBJ);
  FSectorCategory := RegisterOne('sector', KIND_SECTOR);
  FSideCategory := RegisterOne('side', KIND_SIDE);
  FLineCategory := RegisterOne('line', KIND_LINE);
  FPlayerCategory := RegisterOne('player', KIND_PLAYER);
end;

procedure TEngineParityStateSource.Publish(ATic: Integer);
var
  LThinker: Pthinker_t;
  LThinkerCount: Integer;
  LMobjCount: Integer;
  LIndex: Integer;
begin
  FSink.BeginTic(ATic);

  // first the numbers of the mobjs (in the order of the thinkers), then their fields
  FMobjIndexes.Clear;
  LThinkerCount := 0;
  LMobjCount := 0;
  LThinker := thinkercap.next;
  while LThinker <> @thinkercap do
  begin
    if not P_ThinkerIsRemoved(LThinker) then
    begin
      Inc(LThinkerCount);
      if @LThinker._function.acp1 = @P_MobjThinker then
      begin
        FMobjIndexes.Add(LThinker, LMobjCount);
        Inc(LMobjCount);
      end;
    end;
    LThinker := LThinker.next;
  end;

  FFieldIndex := 0;
  LIndex := 0;
  LThinker := thinkercap.next;
  while LThinker <> @thinkercap do
  begin
    if not P_ThinkerIsRemoved(LThinker) and (@LThinker._function.acp1 = @P_MobjThinker) then
    begin
      FSink.BeginObject(FMobjCategory, LIndex);
      FFieldIndex := 0;
      PutMobj(Pmobj_t(LThinker)^);
      FSink.EndObject;
      Inc(LIndex);
    end;
    LThinker := LThinker.next;
  end;

  for LIndex := 0 to numsectors - 1 do
  begin
    FSink.BeginObject(FSectorCategory, LIndex);
    FFieldIndex := 0;
    PutSector(sectors[LIndex]);
    FSink.EndObject;
  end;
  for LIndex := 0 to numsides - 1 do
  begin
    FSink.BeginObject(FSideCategory, LIndex);
    FFieldIndex := 0;
    PutSide(sides[LIndex]);
    FSink.EndObject;
  end;
  for LIndex := 0 to numlines - 1 do
  begin
    FSink.BeginObject(FLineCategory, LIndex);
    FFieldIndex := 0;
    PutLine(lines[LIndex]);
    FSink.EndObject;
  end;
  for LIndex := 0 to MAXPLAYERS - 1 do
    if playeringame[LIndex] then
    begin
      FSink.BeginObject(FPlayerCategory, LIndex);
      FFieldIndex := 0;
      PutPlayer(players[LIndex]);
      FSink.EndObject;
    end;

  // where the first player is and how he is: it makes the logs readable and tells what a demo has visited
  LIndex := 0;
  while (LIndex < MAXPLAYERS - 1) and not playeringame[LIndex] do
    Inc(LIndex);
  if playeringame[LIndex] and (players[LIndex].mo <> nil) then
  begin
    FSink.Scalar('px', players[LIndex].mo.x div FRACUNIT);
    FSink.Scalar('py', players[LIndex].mo.y div FRACUNIT);
    FSink.Scalar('hp', players[LIndex].health);
  end
  else
  begin
    FSink.Scalar('px', 0);
    FSink.Scalar('py', 0);
    FSink.Scalar('hp', 0);
  end;
  FSink.Scalar('lt', leveltime);
  FSink.Scalar('th', LThinkerCount);
  FSink.Scalar('mo', LMobjCount);
  FSink.Scalar('rnd', FRandom.MenuIndex);
  FSink.Scalar('prnd', FRandom.PlayIndex);
  FSink.EndTic;
end;

end.
