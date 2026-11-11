//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Pascal Script RTL - Game Definitions
//  Actors - Vertexes - Lines - Sides - Sectors - Players - Mobjinfo
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit psi_game;

interface

uses
  d_delphi,
  p_mobj_h,
  p_mobjlist,
  psi_system,
  DelphiDoom.Engine.Script.ActorContext.Intf,
  DelphiDoom.ScriptHost.Actors.Intf,
  DelphiDoom.ScriptHost.MobjInfo.Intf,
  DelphiDoom.ScriptHost.Players.Intf,
  DelphiDoom.ScriptHost.World.Intf,
  ps_compiler,
  ps_runtime;

//==============================================================================
//
// PS_ConfigureMobjFunctions
// The classes of the mobjinfo and player functions (the properties of the
// classes of the scripts call the first)
//
//==============================================================================
procedure PS_ConfigureMobjFunctions(const AMobjInfo: IScriptMobjInfo;
  const APlayers: IScriptPlayers);

//==============================================================================
//
// PS_MobjInfo
//
//==============================================================================
function PS_MobjInfo: IScriptMobjInfo;

//==============================================================================
//
// PS_Players
//
//==============================================================================
function PS_Players: IScriptPlayers;

//==============================================================================
//
// PS_ConfigureWorldFunctions
// The classes of the vertex, side, line and sector functions (the properties
// of the classes of the scripts call them)
//
//==============================================================================
procedure PS_ConfigureWorldFunctions(const AVertices: IScriptVertices;
  const ASides: IScriptSides; const ALines: IScriptLines;
  const ASectors: IScriptSectors);

//==============================================================================
//
// PS_Vertices
//
//==============================================================================
function PS_Vertices: IScriptVertices;

//==============================================================================
//
// PS_Sides
//
//==============================================================================
function PS_Sides: IScriptSides;

//==============================================================================
//
// PS_Lines
//
//==============================================================================
function PS_Lines: IScriptLines;

//==============================================================================
//
// PS_Sectors
//
//==============================================================================
function PS_Sectors: IScriptSectors;

//==============================================================================
//
// PS_ConfigureActorFunctions
// The class of the actor functions and the implicit actor of the scripts (the
// properties of the classes of the scripts call the first; PS_Event* and
// A_RunScript enter and leave the second)
//
//==============================================================================
procedure PS_ConfigureActorFunctions(const AActors: IScriptActors;
  const AContext: IEngineScriptActorContext);

//==============================================================================
//
// PS_Actors
//
//==============================================================================
function PS_Actors: IScriptActors;

//==============================================================================
//
// PS_ActorContext
//
//==============================================================================
function PS_ActorContext: IEngineScriptActorContext;

// ---------------------------- ACTORS -----------------------------------------

//==============================================================================
//
// PS_KeyFromMobj
//
//==============================================================================
function PS_KeyFromMobj(const mo: Pmobj_t): LongWord;

type
  TActorArray = array of LongWord;

// ------------------------------- MAP -----------------------------------------

//==============================================================================
//
// PS_P_PointOnLineSide
//
//==============================================================================
function PS_P_PointOnLineSide(x: Integer; y: Integer; line: integer): Integer;

//==============================================================================
//
// PS_R_PointInSector
//
//==============================================================================
function PS_R_PointInSector(const x: Integer; const y: Integer): Integer;

//==============================================================================
//
// PS_R_PointInSubSector
//
//==============================================================================
function PS_R_PointInSubSector(const x: Integer; const y: Integer): Integer;

// -------------------------- VERTEXES -----------------------------------------

// ----------------------------- SIDES -----------------------------------------

// ----------------------------- LINES -----------------------------------------

// --------------------------- SECTORS -----------------------------------------

// --------------------------- PLAYERS -----------------------------------------


// -------------------------- TEXTURES -----------------------------------------

//==============================================================================
//
// _textureidfromname
// The number of a texture by name (the texture functions of the scripts are
// TScriptTextures, the keyboard ones TScriptKeys, the game ones TScriptGameInfo)
//
//==============================================================================
function _textureidfromname(const name: string): Integer;

// ----------------------------- MOBJS -----------------------------------------

//==============================================================================
//
// PS_GetMobjInfoFlag
//
//==============================================================================
function PS_GetMobjInfoFlag(const typ: Integer; const flg: integer): Boolean;

// ---------------------- REGISTRATION -----------------------------------------

//==============================================================================
//
// SIRegister_Game
//
//==============================================================================
procedure SIRegister_Game(C: TPSPascalCompiler);

//==============================================================================
//
// RIRegister_Game
//
//==============================================================================
procedure RIRegister_Game(CLI: TPSRuntimeClassImporter);

//==============================================================================
//
// RIRegisterRTL_Game
//
//==============================================================================
procedure RIRegisterRTL_Game(Exec: TPSExec);

//==============================================================================
//
// PS_InitGameImport
//
//==============================================================================
procedure PS_InitGameImport;

//==============================================================================
//
// PS_ShutDownGameImport
//
//==============================================================================
procedure PS_ShutDownGameImport;

const
  ACTOR_INVALID = MAXKEY;
  PLAYER_INVALID = MAXKEY;
  MOBJTYPE_INVALID = MAXKEY;
  STATE_INVALID = MAXKEY;
  EDITORNUMBER_INVALID = MAXKEY;
  EDITORNUMBER_UNKNOWN = -1;
  TEXTURE_INVALID = MAXKEY;
  FLAT_INVALID = MAXKEY;
  SECTOR_INVALID = MAXKEY;
  LINE_INVALID = MAXKEY;
  SIDE_INVALID = MAXKEY;
  VERTEX_INVALID = MAXKEY;
  LIGHTLEVEL_INVALID = MAXKEY;

type
  TRTLActor = class(TObject)
  public
    procedure PlaySound(const snd: string);
    procedure Remove;
    procedure SetPosition(const x, y, z: Integer);
  end;

  TRTLActors = class(TObject)
  protected
    function GetActorKey(key: LongWord): LongWord;
  public
    function AllActors: TActorArray;
    function AllMonstersAlive: TActorArray;
    function AllMonstersDead: TActorArray;
    function AllMonsters: TActorArray;
    function AllMissiles: TActorArray;
    function AllAtSector(const sec: Integer): TActorArray;
    function AllAtSectorTag(const tag: Integer): TActorArray;
    function AllEditorNumber(const dn: Integer): TActorArray;
    function AllType(const typ: Integer): TActorArray;
    property Actor[key: LongWord]: LongWord read GetActorKey; default;
  end;

type
  TRTLVertex = class(TObject);

  TRTLVertexes = class(TObject)
  protected
    function GetVertex(id: Integer): TRTLVertex;
  public
    property Vertex[id: Integer]: TRTLVertex read GetVertex; default;
  end;

type
  TRTLSide = class(TObject);

  TRTLSides = class(TObject)
  protected
    function GetSide(id: Integer): TRTLSide;
  public
    property Side[id: Integer]: TRTLSide read GetSide; default;
  end;

type
  TRTLLine = class(TObject);

  TRTLLines = class(TObject)
  protected
    function GetLine(id: Integer): TRTLLine;
  public
    property Line[id: Integer]: TRTLLine read GetLine; default;
  end;

type
  TRTLSector = class(TObject)
  public
    procedure PlaySound(const snd: string);
    procedure MoveZ(const dz: Integer);
    procedure SetFloorSlope(const x1, y1, z1: Integer; const x2, y2, z2: Integer; const x3, y3, z3: Integer);
    procedure SetCeilingSlope(const x1, y1, z1: Integer; const x2, y2, z2: Integer; const x3, y3, z3: Integer);
  end;

  TRTLSectors = class(TObject)
  protected
    function GetSector(id: Integer): TRTLSector;
  public
    property Sector[id: Integer]: TRTLSector read GetSector; default;
  end;

type
  TRTLMobjInfoItem = class(TObject);

  TRTLMobjInfo = class(TObject)
  protected
    function GetItem(id: Integer): TRTLMobjInfoItem;
  public
    property Item[id: Integer]: TRTLMobjInfoItem read GetItem; default;
  end;

implementation

uses
  doomdef,
  doomdata,
  d_player,
  g_game,
  i_system,
  info_h,
  info,
  m_base,
  m_fixed,
  p_local,
  p_map,
  p_maputl,
  p_mobj,
  p_setup,
  p_slopes,
  r_data,
  r_defs,
  r_main,
  r_sky,
  tables,
  w_wad;

var
  // given by the composition root
  ps_vertices_ref: IScriptVertices = nil;
  ps_sides_ref: IScriptSides = nil;
  ps_lines_ref: IScriptLines = nil;
  ps_sectors_ref: IScriptSectors = nil;
  ps_mobjinfo_ref: IScriptMobjInfo = nil;
  ps_players_ref: IScriptPlayers = nil;
  ps_actors_ref: IScriptActors = nil;
  ps_actorcontext_ref: IEngineScriptActorContext = nil;

//==============================================================================
//
// PS_ConfigureMobjFunctions
//
//==============================================================================
procedure PS_ConfigureMobjFunctions(const AMobjInfo: IScriptMobjInfo;
  const APlayers: IScriptPlayers);
begin
  ps_mobjinfo_ref := AMobjInfo;
  ps_players_ref := APlayers;
end;

//==============================================================================
//
// PS_MobjInfo
//
//==============================================================================
function PS_MobjInfo: IScriptMobjInfo;
begin
  if ps_mobjinfo_ref = nil then
    I_Error('PS_ConfigureMobjFunctions() was not called: the mobjinfo functions are missing');
  Result := ps_mobjinfo_ref;
end;

//==============================================================================
//
// PS_Players
//
//==============================================================================
function PS_Players: IScriptPlayers;
begin
  if ps_players_ref = nil then
    I_Error('PS_ConfigureMobjFunctions() was not called: the player functions are missing');
  Result := ps_players_ref;
end;

//==============================================================================
//
// PS_ConfigureWorldFunctions
//
//==============================================================================
procedure PS_ConfigureWorldFunctions(const AVertices: IScriptVertices;
  const ASides: IScriptSides; const ALines: IScriptLines;
  const ASectors: IScriptSectors);
begin
  ps_vertices_ref := AVertices;
  ps_sides_ref := ASides;
  ps_lines_ref := ALines;
  ps_sectors_ref := ASectors;
end;

//==============================================================================
//
// PS_Sectors
//
//==============================================================================
function PS_Sectors: IScriptSectors;
begin
  if ps_sectors_ref = nil then
    I_Error('PS_ConfigureWorldFunctions() was not called: the sector functions are missing');
  Result := ps_sectors_ref;
end;

//==============================================================================
//
// PS_Vertices
//
//==============================================================================
function PS_Vertices: IScriptVertices;
begin
  if ps_vertices_ref = nil then
    I_Error('PS_ConfigureWorldFunctions() was not called: the vertex functions are missing');
  Result := ps_vertices_ref;
end;

//==============================================================================
//
// PS_Sides
//
//==============================================================================
function PS_Sides: IScriptSides;
begin
  if ps_sides_ref = nil then
    I_Error('PS_ConfigureWorldFunctions() was not called: the side functions are missing');
  Result := ps_sides_ref;
end;

//==============================================================================
//
// PS_Lines
//
//==============================================================================
function PS_Lines: IScriptLines;
begin
  if ps_lines_ref = nil then
    I_Error('PS_ConfigureWorldFunctions() was not called: the line functions are missing');
  Result := ps_lines_ref;
end;

//==============================================================================
//
// PS_ConfigureActorFunctions
//
//==============================================================================
procedure PS_ConfigureActorFunctions(const AActors: IScriptActors;
  const AContext: IEngineScriptActorContext);
begin
  ps_actors_ref := AActors;
  ps_actorcontext_ref := AContext;
end;

//==============================================================================
//
// PS_Actors
//
//==============================================================================
function PS_Actors: IScriptActors;
begin
  if ps_actors_ref = nil then
    I_Error('PS_ConfigureActorFunctions() was not called: the actor functions are missing');
  Result := ps_actors_ref;
end;

//==============================================================================
//
// PS_ActorContext
//
//==============================================================================
function PS_ActorContext: IEngineScriptActorContext;
begin
  if ps_actorcontext_ref = nil then
    I_Error('PS_ConfigureActorFunctions() was not called: the actor context is missing');
  Result := ps_actorcontext_ref;
end;

var
  rtlactors: TRTLActors;
  rtlvertexes: TRTLVertexes;
  rtlsides: TRTLSides;
  rtllines: TRTLLines;
  rtlsectors: TRTLSectors;
  rtlmobjinfo: TRTLMobjInfo;

// ---------------------------- ACTORS -----------------------------------------

//==============================================================================
//
// PS_KeyFromMobj
//
//==============================================================================
function PS_KeyFromMobj(const mo: Pmobj_t): LongWord;
begin
  if mo = nil then
    Result := ACTOR_INVALID
  else
    Result := mo.key;
end;

// ------------------------ TRTLActor ------------------------------------------

//==============================================================================
//
// TRTLActor.PlaySound
//
//==============================================================================
procedure TRTLActor.PlaySound(const snd: string);
begin
  PS_Actors.ActorPlaySound(LongWord(self), snd);
end;

//==============================================================================
//
// TRTLActor.Remove
//
//==============================================================================
procedure TRTLActor.Remove;
begin
  PS_Actors.RemoveActor(LongWord(self));
end;

//==============================================================================
//
// TRTLActor.SetPosition
//
//==============================================================================
procedure TRTLActor.SetPosition(const x, y, z: Integer);
begin
  PS_Actors.SetActorPosition(LongWord(self), x, y, z);
end;

// ------------------------ TRTLActors -----------------------------------------

//==============================================================================
//
// TRTLActors.GetActorKey
//
//==============================================================================
function TRTLActors.GetActorKey(key: LongWord): LongWord;
begin
  Result := PS_Actors.TActor(key);
end;

//==============================================================================
//
// TRTLActors.AllActors
//
//==============================================================================
function TRTLActors.AllActors: TActorArray;
begin
  Result := TActorArray(PS_Actors.AllActors);
end;

//==============================================================================
//
// TRTLActors.AllMonstersAlive
//
//==============================================================================
function TRTLActors.AllMonstersAlive: TActorArray;
begin
  Result := TActorArray(PS_Actors.AllMonstersAlive);
end;

//==============================================================================
//
// TRTLActors.AllMonstersDead
//
//==============================================================================
function TRTLActors.AllMonstersDead: TActorArray;
begin
  Result := TActorArray(PS_Actors.AllMonstersDead);
end;

//==============================================================================
//
// TRTLActors.AllMonsters
//
//==============================================================================
function TRTLActors.AllMonsters: TActorArray;
begin
  Result := TActorArray(PS_Actors.AllMonsters);
end;

//==============================================================================
//
// TRTLActors.AllMissiles
//
//==============================================================================
function TRTLActors.AllMissiles: TActorArray;
begin
  Result := TActorArray(PS_Actors.AllMissiles);
end;

//==============================================================================
//
// TRTLActors.AllAtSector
//
//==============================================================================
function TRTLActors.AllAtSector(const sec: Integer): TActorArray;
begin
  Result := TActorArray(PS_Actors.AllAtSector(sec));
end;

//==============================================================================
//
// TRTLActors.AllAtSectorTag
//
//==============================================================================
function TRTLActors.AllAtSectorTag(const tag: Integer): TActorArray;
begin
  Result := TActorArray(PS_Actors.AllAtSectorTag(tag));
end;

//==============================================================================
//
// TRTLActors.AllEditorNumber
//
//==============================================================================
function TRTLActors.AllEditorNumber(const dn: Integer): TActorArray;
begin
  Result := TActorArray(PS_Actors.AllEditorNumber(dn));
end;

//==============================================================================
//
// TRTLActors.AllType
//
//==============================================================================
function TRTLActors.AllType(const typ: Integer): TActorArray;
begin
  Result := TActorArray(PS_Actors.AllType(typ));
end;

//
// RTLActors Runtime Registration
//

//==============================================================================
//
// TRTLActorkey_R
//
//==============================================================================
procedure TRTLActorkey_R(Self: TRTLActor; var T: LongWord);
begin
  T := LongWord(Self);
end;

//==============================================================================
//
// TRTLActorTarget_W
//
//==============================================================================
procedure TRTLActorTarget_W(Self: TRTLActor; const T: TRTLActor);
begin
  PS_Actors.SetRelation(LongWord(Self), acrTarget, LongWord(T));
end;

//==============================================================================
//
// TRTLActorTarget_R
//
//==============================================================================
procedure TRTLActorTarget_R(Self: TRTLActor; var T: TRTLActor);
begin
  T := TRTLActor(PS_Actors.GetRelation(LongWord(Self), acrTarget));
end;

//==============================================================================
//
// TRTLActorTracer_W
//
//==============================================================================
procedure TRTLActorTracer_W(Self: TRTLActor; const T: TRTLActor);
begin
  PS_Actors.SetRelation(LongWord(Self), acrTracer, LongWord(T));
end;

//==============================================================================
//
// TRTLActorTracer_R
//
//==============================================================================
procedure TRTLActorTracer_R(Self: TRTLActor; var T: TRTLActor);
begin
  T := TRTLActor(PS_Actors.GetRelation(LongWord(Self), acrTracer));
end;

//==============================================================================
//
// TRTLActorMaster_W
//
//==============================================================================
procedure TRTLActorMaster_W(Self: TRTLActor; const T: TRTLActor);
begin
  PS_Actors.SetRelation(LongWord(Self), acrMaster, LongWord(T));
end;

//==============================================================================
//
// TRTLActorMaster_R
//
//==============================================================================
procedure TRTLActorMaster_R(Self: TRTLActor; var T: TRTLActor);
begin
  T := TRTLActor(PS_Actors.GetRelation(LongWord(Self), acrMaster));
end;

//==============================================================================
//
// TRTLActorX_W
//
//==============================================================================
procedure TRTLActorX_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfX, T);
end;

//==============================================================================
//
// TRTLActorX_R
//
//==============================================================================
procedure TRTLActorX_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfX);
end;

//==============================================================================
//
// TRTLActorY_W
//
//==============================================================================
procedure TRTLActorY_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfY, T);
end;

//==============================================================================
//
// TRTLActorY_R
//
//==============================================================================
procedure TRTLActorY_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfY);
end;

//==============================================================================
//
// TRTLActorZ_W
//
//==============================================================================
procedure TRTLActorZ_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfZ, T);
end;

//==============================================================================
//
// TRTLActorZ_R
//
//==============================================================================
procedure TRTLActorZ_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfZ);
end;

//==============================================================================
//
// TRTLActorMOMX_W
//
//==============================================================================
procedure TRTLActorMOMX_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfMomX, T);
end;

//==============================================================================
//
// TRTLActorMOMX_R
//
//==============================================================================
procedure TRTLActorMOMX_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfMomX);
end;

//==============================================================================
//
// TRTLActorMOMY_W
//
//==============================================================================
procedure TRTLActorMOMY_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfMomY, T);
end;

//==============================================================================
//
// TRTLActorMOMY_R
//
//==============================================================================
procedure TRTLActorMOMY_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfMomY);
end;

//==============================================================================
//
// TRTLActorMOMZ_W
//
//==============================================================================
procedure TRTLActorMOMZ_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfMomZ, T);
end;

//==============================================================================
//
// TRTLActorMOMZ_R
//
//==============================================================================
procedure TRTLActorMOMZ_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfMomZ);
end;

//==============================================================================
//
// TRTLActorFloorZ_W
//
//==============================================================================
procedure TRTLActorFloorZ_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfFloorZ, T);
end;

//==============================================================================
//
// TRTLActorFloorZ_R
//
//==============================================================================
procedure TRTLActorFloorZ_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfFloorZ);
end;

//==============================================================================
//
// TRTLActorCeilingZ_W
//
//==============================================================================
procedure TRTLActorCeilingZ_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfCeilingZ, T);
end;

//==============================================================================
//
// TRTLActorCeilingZ_R
//
//==============================================================================
procedure TRTLActorCeilingZ_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfCeilingZ);
end;

//==============================================================================
//
// TRTLActorSpeed_W
//
//==============================================================================
procedure TRTLActorSpeed_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfSpeed, T);
end;

//==============================================================================
//
// TRTLActorSpeed_R
//
//==============================================================================
procedure TRTLActorSpeed_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfSpeed);
end;

//==============================================================================
//
// TRTLActorAngle_W
//
//==============================================================================
procedure TRTLActorAngle_W(Self: TRTLActor; const T: LongWord);
begin
  PS_Actors.SetNumber(LongWord(Self), acfAngle, T);
end;

//==============================================================================
//
// TRTLActorAngle_R
//
//==============================================================================
procedure TRTLActorAngle_R(Self: TRTLActor; var T: LongWord);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfAngle);
end;

//==============================================================================
//
// TRTLActorSector_R
//
//==============================================================================
procedure TRTLActorSector_R(Self: TRTLActor; var T: TRTLSector);
begin
  T := rtlsectors[PS_Actors.GetNumber(LongWord(Self), acfSector)];
end;

//==============================================================================
//
// TRTLActorHealth_W
//
//==============================================================================
procedure TRTLActorHealth_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfHealth, T);
end;

//==============================================================================
//
// TRTLActorHealth_R
//
//==============================================================================
procedure TRTLActorHealth_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfHealth);
end;

//==============================================================================
//
// TRTLActorHeight_W
//
//==============================================================================
procedure TRTLActorHeight_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfHeight, T);
end;

//==============================================================================
//
// TRTLActorHeight_R
//
//==============================================================================
procedure TRTLActorHeight_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfHeight);
end;

//==============================================================================
//
// TRTLActorSpawnHealth_R
//
//==============================================================================
procedure TRTLActorSpawnHealth_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfSpawnHealth);
end;

//==============================================================================
//
// TRTLActorMass_W
//
//==============================================================================
procedure TRTLActorMass_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfMass, T);
end;

//==============================================================================
//
// TRTLActorMass_R
//
//==============================================================================
procedure TRTLActorMass_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfMass);
end;

//==============================================================================
//
// TRTLActorCustomParams_W
//
//==============================================================================
procedure TRTLActorCustomParams_W(Self: TRTLActor; const T: Integer; const t1: string);
begin
  PS_Actors.SetActorCustomParam(LongWord(Self), t1, T);
end;

//==============================================================================
//
// TRTLActorCustomParams_R
//
//==============================================================================
procedure TRTLActorCustomParams_R(Self: TRTLActor; var T: Integer; const t1: string);
begin
  T := PS_Actors.GetActorCustomParam(LongWord(Self), t1);
end;

//==============================================================================
//
// TRTLActorCustomDropItem_W
//
//==============================================================================
procedure TRTLActorCustomDropItem_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfCustomDropItem, T);
end;

//==============================================================================
//
// TRTLActorCustomDropItem_R
//
//==============================================================================
procedure TRTLActorCustomDropItem_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfCustomDropItem);
end;

//==============================================================================
//
// TRTLActorPushFactor_W
//
//==============================================================================
procedure TRTLActorPushFactor_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfPushFactor, T);
end;

//==============================================================================
//
// TRTLActorPushFactor_R
//
//==============================================================================
procedure TRTLActorPushFactor_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfPushFactor);
end;

//==============================================================================
//
// TRTLActorScale_W
//
//==============================================================================
procedure TRTLActorScale_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfScale, T);
end;

//==============================================================================
//
// TRTLActorScale_R
//
//==============================================================================
procedure TRTLActorScale_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfScale);
end;

//==============================================================================
//
// TRTLActorGravity_W
//
//==============================================================================
procedure TRTLActorGravity_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfGravity, T);
end;

//==============================================================================
//
// TRTLActorGravity_R
//
//==============================================================================
procedure TRTLActorGravity_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfGravity);
end;

//==============================================================================
//
// TRTLActorSpecial_W
//
//==============================================================================
procedure TRTLActorSpecial_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfSpecial, T);
end;

//==============================================================================
//
// TRTLActorSpecial_R
//
//==============================================================================
procedure TRTLActorSpecial_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfSpecial);
end;

//==============================================================================
//
// TRTLActorArg1_W
//
//==============================================================================
procedure TRTLActorArg1_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfArg1, T);
end;

//==============================================================================
//
// TRTLActorArg1_R
//
//==============================================================================
procedure TRTLActorArg1_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfArg1);
end;

//==============================================================================
//
// TRTLActorArg2_W
//
//==============================================================================
procedure TRTLActorArg2_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfArg2, T);
end;

//==============================================================================
//
// TRTLActorArg2_R
//
//==============================================================================
procedure TRTLActorArg2_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfArg2);
end;

//==============================================================================
//
// TRTLActorArg3_W
//
//==============================================================================
procedure TRTLActorArg3_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfArg3, T);
end;

//==============================================================================
//
// TRTLActorArg3_R
//
//==============================================================================
procedure TRTLActorArg3_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfArg3);
end;

//==============================================================================
//
// TRTLActorArg4_W
//
//==============================================================================
procedure TRTLActorArg4_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfArg4, T);
end;

//==============================================================================
//
// TRTLActorArg4_R
//
//==============================================================================
procedure TRTLActorArg4_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfArg4);
end;

//==============================================================================
//
// TRTLActorArg5_W
//
//==============================================================================
procedure TRTLActorArg5_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfArg5, T);
end;

//==============================================================================
//
// TRTLActorArg5_R
//
//==============================================================================
procedure TRTLActorArg5_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfArg5);
end;

//==============================================================================
//
// TRTLActorWeaveIndexXY_W
//
//==============================================================================
procedure TRTLActorWeaveIndexXY_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfWeaveIndexXY, T);
end;

//==============================================================================
//
// TRTLActorWeaveIndexXY_R
//
//==============================================================================
procedure TRTLActorWeaveIndexXY_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfWeaveIndexXY);
end;

//==============================================================================
//
// TRTLActorWeaveIndexZ_W
//
//==============================================================================
procedure TRTLActorWeaveIndexZ_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfWeaveIndexXY, T); // the old code wrote the XY index
end;

//==============================================================================
//
// TRTLActorWeaveIndexZ_R
//
//==============================================================================
procedure TRTLActorWeaveIndexZ_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfWeaveIndexZ);
end;

//==============================================================================
//
// TRTLActorFriction_W
//
//==============================================================================
procedure TRTLActorFriction_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfFriction, T);
end;

//==============================================================================
//
// TRTLActorFriction_R
//
//==============================================================================
procedure TRTLActorFriction_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfFriction);
end;

//==============================================================================
//
// TRTLActorPainChance_W
//
//==============================================================================
procedure TRTLActorPainChance_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfPainChance, T);
end;

//==============================================================================
//
// TRTLActorPainChance_R
//
//==============================================================================
procedure TRTLActorPainChance_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfPainChance);
end;

//==============================================================================
//
// TRTLActorSpriteDX_W
//
//==============================================================================
procedure TRTLActorSpriteDX_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfSpriteDX, T);
end;

//==============================================================================
//
// TRTLActorSpriteDX_R
//
//==============================================================================
procedure TRTLActorSpriteDX_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfSpriteDX);
end;

//==============================================================================
//
// TRTLActorSpriteDY_W
//
//==============================================================================
procedure TRTLActorSpriteDY_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfSpriteDY, T);
end;

//==============================================================================
//
// TRTLActorSpriteDY_R
//
//==============================================================================
procedure TRTLActorSpriteDY_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfSpriteDY);
end;

//==============================================================================
//
// TRTLActorInfightingGroup_W
//
//==============================================================================
procedure TRTLActorInfightingGroup_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfInfightingGroup, T);
end;

//==============================================================================
//
// TRTLActorInfightingGroup_R
//
//==============================================================================
procedure TRTLActorInfightingGroup_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfInfightingGroup);
end;

//==============================================================================
//
// TRTLActorProjectileGroup_W
//
//==============================================================================
procedure TRTLActorProjectileGroup_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfProjectileGroup, T);
end;

//==============================================================================
//
// TRTLActorProjectileGroup_R
//
//==============================================================================
procedure TRTLActorProjectileGroup_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfProjectileGroup);
end;

//==============================================================================
//
// TRTLActorSplashGroup_W
//
//==============================================================================
procedure TRTLActorSplashGroup_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfSplashGroup, T);
end;

//==============================================================================
//
// TRTLActorSplashGroup_R
//
//==============================================================================
procedure TRTLActorSplashGroup_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfSplashGroup);
end;

//==============================================================================
//
// TRTLActorTranslation_W
//
//==============================================================================
procedure TRTLActorTranslation_W(Self: TRTLActor; const T: string);
begin
  PS_Actors.SetText(LongWord(Self), actTranslation, T);
end;

//==============================================================================
//
// TRTLActorTranslation_R
//
//==============================================================================
procedure TRTLActorTranslation_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actTranslation);
end;

//==============================================================================
//
// TRTLActorBloodColor_W
//
//==============================================================================
procedure TRTLActorBloodColor_W(Self: TRTLActor; const T: string);
begin
  PS_Actors.SetText(LongWord(Self), actBloodColor, T);
end;

//==============================================================================
//
// TRTLActorBloodColor_R
//
//==============================================================================
procedure TRTLActorBloodColor_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actBloodColor);
end;

//==============================================================================
//
// TRTLActorFlags_W
//
//==============================================================================
procedure TRTLActorFlags_W(Self: TRTLActor; const T: Boolean; const t1: LongWord);
begin
  if T then
    PS_Actors.SetActorFlag(LongWord(Self), t1)
  else
    PS_Actors.UnSetActorFlag(LongWord(Self), t1)
end;

//==============================================================================
//
// TRTLActorFlags_R
//
//==============================================================================
procedure TRTLActorFlags_R(Self: TRTLActor; var T: Boolean; const t1: LongWord);
begin
  T := PS_Actors.CheckActorFlag(LongWord(Self), t1);
end;

//==============================================================================
//
// TRTLActorName_R
//
//==============================================================================
procedure TRTLActorName_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actName);
end;

{$IFDEF STRIFE}

//==============================================================================
//
// TRTLActorName2_R
//
//==============================================================================
procedure TRTLActorName2_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actName2);
end;
{$ENDIF}

//==============================================================================
//
// TRTLActorPlayer_R
//
//==============================================================================
procedure TRTLActorPlayer_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetActorPlayer(LongWord(Self));
end;

//==============================================================================
//
// TRTLActorMobjType_R
//
//==============================================================================
procedure TRTLActorMobjType_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfMobjType);
end;

//==============================================================================
//
// TRTLActorEditorNumber_R
//
//==============================================================================
procedure TRTLActorEditorNumber_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfEditorNumber);
end;

//==============================================================================
//
// TRTLActorSeeSound_R
//
//==============================================================================
procedure TRTLActorSeeSound_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actSeeSound);
end;

//==============================================================================
//
// TRTLActorAttackSound_R
//
//==============================================================================
procedure TRTLActorAttackSound_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actAttackSound);
end;

//==============================================================================
//
// TRTLActorPainSound_R
//
//==============================================================================
procedure TRTLActorPainSound_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actPainSound);
end;

//==============================================================================
//
// TRTLActorDeathSound_R
//
//==============================================================================
procedure TRTLActorDeathSound_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actDeathSound);
end;

//==============================================================================
//
// TRTLActorActiveSound_R
//
//==============================================================================
procedure TRTLActorActiveSound_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actActiveSound);
end;

//==============================================================================
//
// TRTLActorCustomSound1_R
//
//==============================================================================
procedure TRTLActorCustomSound1_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actCustomSound1);
end;

//==============================================================================
//
// TRTLActorCustomSound2_R
//
//==============================================================================
procedure TRTLActorCustomSound2_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actCustomSound2);
end;

//==============================================================================
//
// TRTLActorCustomSound3_R
//
//==============================================================================
procedure TRTLActorCustomSound3_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actCustomSound3);
end;

//==============================================================================
//
// TRTLActorMeleeSound_R
//
//==============================================================================
procedure TRTLActorMeleeSound_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actMeleeSound);
end;

//==============================================================================
//
// TRTLActorRipSound_R
//
//==============================================================================
procedure TRTLActorRipSound_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actMeleeSound);
end;

//==============================================================================
//
// TRTLActorState_R
//
//==============================================================================
procedure TRTLActorState_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Actors.GetNumber(LongWord(Self), acfState);
end;

//==============================================================================
//
// TRTLActorState_W
//
//==============================================================================
procedure TRTLActorState_W(Self: TRTLActor; const T: Integer);
begin
  PS_Actors.SetNumber(LongWord(Self), acfState, T);
end;

//==============================================================================
//
// TRTLActorsActor_R
//
//==============================================================================
procedure TRTLActorsActor_R(Self: TRTLActors; var T: TRTLActor; const t1: LongWord);
begin
  T := TRTLActor(Self.Actor[t1]);
end;

// ------------------------------- MAP -----------------------------------------

//==============================================================================
//
// PS_P_PointOnLineSide
//
//==============================================================================
function PS_P_PointOnLineSide(x: Integer; y: Integer; line: integer): Integer;
begin
  if (line >= 0) and (line < numlines) then
    Result := P_PointOnLineSide(x, y, @lines[line])
  else
    Result := 0;
end;

//==============================================================================
//
// PS_R_PointInSector
//
//==============================================================================
function PS_R_PointInSector(const x: Integer; const y: Integer): Integer;
begin
  Result := R_PointInSubsector(x, y).sector.iSectorID;
end;

//==============================================================================
//
// PS_R_PointInSubSector
//
//==============================================================================
function PS_R_PointInSubSector(const x: Integer; const y: Integer): Integer;
begin
  Result := pdiff(pointer(R_PointInSubsector(x, y)), subsectors, SizeOf(subsector_t));
end;

// -------------------------- VERTEXES -----------------------------------------

//==============================================================================
//
// TRTLVertexes.GetVertex
//
//==============================================================================
function TRTLVertexes.GetVertex(id: Integer): TRTLVertex;
begin
  if PS_Vertices.IsValidVertex(id) then
    Result := TRTLVertex(id + 1)
  else
    Result := TRTLVertex(VERTEX_INVALID);
end;

//==============================================================================
//
// TRTLVertexX_R
//
//==============================================================================
procedure TRTLVertexX_R(Self: TRTLVertex; var T: Integer);
begin
  T := PS_Vertices.GetVertexX(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLVertexY_R
//
//==============================================================================
procedure TRTLVertexY_R(Self: TRTLVertex; var T: Integer);
begin
  T := PS_Vertices.GetVertexY(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLVertexID_R
//
//==============================================================================
procedure TRTLVertexID_R(Self: TRTLVertex; var T: Integer);
begin
  T := Integer(Self) - 1;
  if not PS_Vertices.IsValidVertex(T) then
    T := VERTEX_INVALID;
end;

//==============================================================================
//
// TRTLVertexesVertex_R
//
//==============================================================================
procedure TRTLVertexesVertex_R(Self: TRTLVertexes; var T: TRTLVertex; const t1: Integer);
begin
  T := Self[t1];
end;

//==============================================================================
//
// TRTLVertexesCount_R
//
//==============================================================================
procedure TRTLVertexesCount_R(Self: TRTLActor; var T: Integer);
begin
  T := PS_Vertices.GetVertexCount;
end;

// ----------------------------- SIDES -----------------------------------------

//==============================================================================
//
// _textureidfromname
//
//==============================================================================
function _textureidfromname(const name: string): Integer;
begin
  if (name = '') or (name = '-') then
  begin
    Result := 0;
    Exit;
  end;

  Result := R_CheckTextureNumForName(name);
  if Result < 0 then
    Result := TEXTURE_INVALID;
end;

//==============================================================================
//
// TRTLSides.GetSide
//
//==============================================================================
function TRTLSides.GetSide(id: Integer): TRTLSide;
begin
  if PS_Sides.IsValidSide(id) then
    Result := TRTLSide(id + 1)
  else
    Result := TRTLSide(SIDE_INVALID);
end;

//==============================================================================
//
// TRTLSideTextureOffset_W
//
//==============================================================================
procedure TRTLSideTextureOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofTexture, T);
end;

//==============================================================================
//
// TRTLSideTextureOffset_R
//
//==============================================================================
procedure TRTLSideTextureOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofTexture);
end;

//==============================================================================
//
// TRTLSideTopTextureOffset_W
//
//==============================================================================
procedure TRTLSideTopTextureOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofTopTexture, T);
end;

//==============================================================================
//
// TRTLSideTopTextureOffset_R
//
//==============================================================================
procedure TRTLSideTopTextureOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofTopTexture);
end;

//==============================================================================
//
// TRTLSideBottomTextureOffset_W
//
//==============================================================================
procedure TRTLSideBottomTextureOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofBottomTexture, T);
end;

//==============================================================================
//
// TRTLSideBottomTextureOffset_R
//
//==============================================================================
procedure TRTLSideBottomTextureOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofBottomTexture);
end;

//==============================================================================
//
// TRTLSideMidTextureOffset_W
//
//==============================================================================
procedure TRTLSideMidTextureOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofMiddleTexture, T);
end;

//==============================================================================
//
// TRTLSideMidTextureOffset_R
//
//==============================================================================
procedure TRTLSideMidTextureOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofMiddleTexture);
end;

//==============================================================================
//
// TRTLSideRowOffset_W
//
//==============================================================================
procedure TRTLSideRowOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofRow, T);
end;

//==============================================================================
//
// TRTLSideRowOffset_R
//
//==============================================================================
procedure TRTLSideRowOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofRow);
end;

//==============================================================================
//
// TRTLSideTopRowOffset_W
//
//==============================================================================
procedure TRTLSideTopRowOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofTopRow, T);
end;

//==============================================================================
//
// TRTLSideTopRowOffset_R
//
//==============================================================================
procedure TRTLSideTopRowOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofTopRow);
end;

//==============================================================================
//
// TRTLSideBottomRowOffset_W
//
//==============================================================================
procedure TRTLSideBottomRowOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofBottomRow, T);
end;

//==============================================================================
//
// TRTLSideBottomRowOffset_R
//
//==============================================================================
procedure TRTLSideBottomRowOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofBottomRow);
end;

//==============================================================================
//
// TRTLSideMidRowOffset_W
//
//==============================================================================
procedure TRTLSideMidRowOffset_W(Self: TRTLSide; const T: fixed_t);
begin
  PS_Sides.SetOffset(Integer(Self) - 1, sofMidRow, T);
end;

//==============================================================================
//
// TRTLSideMidRowOffset_R
//
//==============================================================================
procedure TRTLSideMidRowOffset_R(Self: TRTLSide; var T: fixed_t);
begin
  T := PS_Sides.GetOffset(Integer(Self) - 1, sofMidRow);
end;

//==============================================================================
//
// TRTLSideTopTexture_W
//
//==============================================================================
procedure TRTLSideTopTexture_W(Self: TRTLSide; const T: string);
begin
  PS_Sides.SetTexture(Integer(Self) - 1, sspTop, T);
end;

//==============================================================================
//
// TRTLSideTopTexture_R
//
//==============================================================================
procedure TRTLSideTopTexture_R(Self: TRTLSide; var T: string);
begin
  T := PS_Sides.GetTexture(Integer(Self) - 1, sspTop);
end;

//==============================================================================
//
// TRTLSideBottomTexture_W
//
//==============================================================================
procedure TRTLSideBottomTexture_W(Self: TRTLSide; const T: string);
begin
  PS_Sides.SetTexture(Integer(Self) - 1, sspBottom, T);
end;

//==============================================================================
//
// TRTLSideBottomTexture_R
//
//==============================================================================
procedure TRTLSideBottomTexture_R(Self: TRTLSide; var T: string);
begin
  T := PS_Sides.GetTexture(Integer(Self) - 1, sspBottom);
end;

//==============================================================================
//
// TRTLSideMiddleTexture_W
//
//==============================================================================
procedure TRTLSideMiddleTexture_W(Self: TRTLSide; const T: string);
begin
  PS_Sides.SetTexture(Integer(Self) - 1, sspMiddle, T);
end;

//==============================================================================
//
// TRTLSideMiddleTexture_R
//
//==============================================================================
procedure TRTLSideMiddleTexture_R(Self: TRTLSide; var T: string);
begin
  T := PS_Sides.GetTexture(Integer(Self) - 1, sspMiddle);
end;

//==============================================================================
//
// TRTLSideSector_R
//
//==============================================================================
procedure TRTLSideSector_R(Self: TRTLSide; var T: TRTLSector);
begin
  T := rtlsectors[PS_Sides.GetSideSector(Integer(Self) - 1)];
end;

//==============================================================================
//
// TRTLSideID_R
//
//==============================================================================
procedure TRTLSideID_R(Self: TRTLSide; var T: Integer);
begin
  T := Integer(Self) - 1;
  if not PS_Sides.IsValidSide(T) then
    T := SIDE_INVALID;
end;

//==============================================================================
//
// TRTLSidesCount_R
//
//==============================================================================
procedure TRTLSidesCount_R(Self: TRTLSides; var T: Integer);
begin
  T := PS_Sides.GetSideCount;
end;

//==============================================================================
//
// TRTLSidesSides_R
//
//==============================================================================
procedure TRTLSidesSides_R(Self: TRTLSides; var T: TRTLSide; const t1: Integer);
begin
  // When side = 0 returns null and the script makes runtime error !
  T := Self[t1];
end;

// ----------------------------- LINES -----------------------------------------

//==============================================================================
//
// TRTLLines.GetLine
//
//==============================================================================
function TRTLLines.GetLine(id: Integer): TRTLLine;
begin
  if PS_Lines.IsValidLine(id) then
    Result := TRTLLine(id + 1)
  else
    Result := TRTLLine(LINE_INVALID);
end;

//==============================================================================
//
// TRTLLineBackSector_R
//
//==============================================================================
procedure TRTLLineBackSector_R(Self: TRTLLine; var T: TRTLSector);
begin
  T := rtlsectors[PS_Lines.GetLineBackSector(Integer(Self) - 1)];
end;

//==============================================================================
//
// TRTLLineFrontSector_R
//
//==============================================================================
procedure TRTLLineFrontSector_R(Self: TRTLLine; var T: TRTLSector);
begin
  T := rtlsectors[PS_Lines.GetLineFrontSector(Integer(Self) - 1)];
end;

//==============================================================================
//
// TRTLLineBackSide_R
//
//==============================================================================
procedure TRTLLineBackSide_R(Self: TRTLLine; var T: TRTLSide);
begin
  T := rtlsides[PS_Lines.GetLineBackSide(Integer(Self) - 1)];
end;

//==============================================================================
//
// TRTLLineFrontSide_R
//
//==============================================================================
procedure TRTLLineFrontSide_R(Self: TRTLLine; var T: TRTLSide);
begin
  T := rtlsides[PS_Lines.GetLineFrontSide(Integer(Self) - 1)];
end;

{$IFNDEF HEXEN}

//==============================================================================
//
// TRTLLineTag_W
//
//==============================================================================
procedure TRTLLineTag_W(Self: TRTLLine; const T: Integer);
begin
  PS_Lines.SetLineTag(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLLineTag_R
//
//==============================================================================
procedure TRTLLineTag_R(Self: TRTLLine; var T: Integer);
begin
  T := PS_Lines.GetLineTag(Integer(Self) - 1);
end;

{$ENDIF}

//==============================================================================
//
// TRTLLineArg5_W
//
//==============================================================================
procedure TRTLLineArg5_W(Self: TRTLLine; const T: byte);
begin
  PS_Lines.SetLineArgument(Integer(Self) - 1, 4, T);
end;

//==============================================================================
//
// TRTLLineArg5_R
//
//==============================================================================
procedure TRTLLineArg5_R(Self: TRTLLine; var T: byte);
begin
  T := PS_Lines.GetLineArgument(Integer(Self) - 1, 4);
end;

//==============================================================================
//
// TRTLLineArg4_W
//
//==============================================================================
procedure TRTLLineArg4_W(Self: TRTLLine; const T: byte);
begin
  PS_Lines.SetLineArgument(Integer(Self) - 1, 3, T);
end;

//==============================================================================
//
// TRTLLineArg4_R
//
//==============================================================================
procedure TRTLLineArg4_R(Self: TRTLLine; var T: byte);
begin
  T := PS_Lines.GetLineArgument(Integer(Self) - 1, 3);
end;

//==============================================================================
//
// TRTLLineArg3_W
//
//==============================================================================
procedure TRTLLineArg3_W(Self: TRTLLine; const T: byte);
begin
  PS_Lines.SetLineArgument(Integer(Self) - 1, 2, T);
end;

//==============================================================================
//
// TRTLLineArg3_R
//
//==============================================================================
procedure TRTLLineArg3_R(Self: TRTLLine; var T: byte);
begin
  T := PS_Lines.GetLineArgument(Integer(Self) - 1, 2);
end;

//==============================================================================
//
// TRTLLineArg2_W
//
//==============================================================================
procedure TRTLLineArg2_W(Self: TRTLLine; const T: byte);
begin
  PS_Lines.SetLineArgument(Integer(Self) - 1, 1, T);
end;

//==============================================================================
//
// TRTLLineArg2_R
//
//==============================================================================
procedure TRTLLineArg2_R(Self: TRTLLine; var T: byte);
begin
  T := PS_Lines.GetLineArgument(Integer(Self) - 1, 1);
end;

//==============================================================================
//
// TRTLLineArg1_W
//
//==============================================================================
procedure TRTLLineArg1_W(Self: TRTLLine; const T: byte);
begin
  PS_Lines.SetLineArgument(Integer(Self) - 1, 0, T);
end;

//==============================================================================
//
// TRTLLineArg1_R
//
//==============================================================================
procedure TRTLLineArg1_R(Self: TRTLLine; var T: byte);
begin
  T := PS_Lines.GetLineArgument(Integer(Self) - 1, 0);
end;

{$IFNDEF HEXEN}

//==============================================================================
//
// TRTLLineTransparent_W
//
//==============================================================================
procedure TRTLLineTransparent_W(Self: TRTLLine; const T: Boolean);
begin
  PS_Lines.SetLineFlag(Integer(Self) - 1, slfTransparent, T);
end;

//==============================================================================
//
// TRTLLineTransparent_R
//
//==============================================================================
procedure TRTLLineTransparent_R(Self: TRTLLine; var T: Boolean);
begin
  T := PS_Lines.GetLineFlag(Integer(Self) - 1, slfTransparent);
end;
{$ENDIF}

//==============================================================================
//
// TRTLLineIsBlocking_W
//
//==============================================================================
procedure TRTLLineIsBlocking_W(Self: TRTLLine; const T: Boolean);
begin
  PS_Lines.SetLineFlag(Integer(Self) - 1, slfBlocking, T);
end;

//==============================================================================
//
// TRTLLineIsBlocking_R
//
//==============================================================================
procedure TRTLLineIsBlocking_R(Self: TRTLLine; var T: Boolean);
begin
  T := PS_Lines.GetLineFlag(Integer(Self) - 1, slfBlocking);
end;

//==============================================================================
//
// TRTLLineIsBlockingMonsters_W
//
//==============================================================================
procedure TRTLLineIsBlockingMonsters_W(Self: TRTLLine; const T: Boolean);
begin
  PS_Lines.SetLineFlag(Integer(Self) - 1, slfBlockMonsters, T);
end;

//==============================================================================
//
// TRTLLineIsBlockingMonsters_R
//
//==============================================================================
procedure TRTLLineIsBlockingMonsters_R(Self: TRTLLine; var T: Boolean);
begin
  T := PS_Lines.GetLineFlag(Integer(Self) - 1, slfBlockMonsters);
end;

//==============================================================================
//
// TRTLLineTriggerScripts_W
//
//==============================================================================
procedure TRTLLineTriggerScripts_W(Self: TRTLLine; const T: Boolean);
begin
  PS_Lines.SetLineFlag(Integer(Self) - 1, slfTriggerScripts, T);
end;

//==============================================================================
//
// TRTLLineTriggerScripts_R
//
//==============================================================================
procedure TRTLLineTriggerScripts_R(Self: TRTLLine; var T: Boolean);
begin
  T := PS_Lines.GetLineFlag(Integer(Self) - 1, slfTriggerScripts);
end;

//==============================================================================
//
// TRTLLineSpecial_W
//
//==============================================================================
procedure TRTLLineSpecial_W(Self: TRTLLine; const T: Integer);
begin
  PS_Lines.SetLineSpecial(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLLineSpecial_R
//
//==============================================================================
procedure TRTLLineSpecial_R(Self: TRTLLine; var T: Integer);
begin
  T := PS_Lines.GetLineSpecial(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLLineDY_R
//
//==============================================================================
procedure TRTLLineDY_R(Self: TRTLLine; var T: fixed_t);
begin
  T := PS_Lines.GetLineDY(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLLineDX_R
//
//==============================================================================
procedure TRTLLineDX_R(Self: TRTLLine; var T: fixed_t);
begin
  T := PS_Lines.GetLineDX(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLLineVertex2_R
//
//==============================================================================
procedure TRTLLineVertex2_R(Self: TRTLLine; var T: TRTLVertex);
begin
  T := rtlvertexes[PS_Lines.GetLineVertex2(Integer(Self) - 1)];
end;

//==============================================================================
//
// TRTLLineVertex1_R
//
//==============================================================================
procedure TRTLLineVertex1_R(Self: TRTLLine; var T: TRTLVertex);
begin
  T := rtlvertexes[PS_Lines.GetLineVertex1(Integer(Self) - 1)];
end;

//==============================================================================
//
// TRTLLineID_R
//
//==============================================================================
procedure TRTLLineID_R(Self: TRTLLine; var T: Integer);
begin
  T := Integer(Self) - 1;
  if not PS_Lines.IsValidLine(T) then
    T := LINE_INVALID;
end;

//==============================================================================
//
// TRTLLinesCount_R
//
//==============================================================================
procedure TRTLLinesCount_R(Self: TRTLLines; var T: Integer);
begin
  T := PS_Lines.GetLineCount;
end;

//==============================================================================
//
// TRTLLinesLine_R
//
//==============================================================================
procedure TRTLLinesLine_R(Self: TRTLLines; var T: TRTLLine; const t1: Integer);
begin
  T := Self[t1];
end;

// --------------------------- SECTORS -----------------------------------------

// ----------------------- TRTLSector ------------------------------------------

//==============================================================================
//
// TRTLSector.PlaySound
//
//==============================================================================
procedure TRTLSector.PlaySound(const snd: string);
begin
  PS_Sectors.SectorPlaySound(Integer(self) - 1, snd);
end;

//==============================================================================
//
// TRTLSector.MoveZ
//
//==============================================================================
procedure TRTLSector.MoveZ(const dz: Integer);
begin
  PS_Sectors.SectorMoveZ(Integer(self) - 1, dz);
end;

//==============================================================================
//
// TRTLSector.SetFloorSlope
//
//==============================================================================
procedure TRTLSector.SetFloorSlope(const x1, y1, z1: Integer; const x2, y2, z2: Integer; const x3, y3, z3: Integer);
begin
  PS_Sectors.SetSectorFloorSlope(Integer(self) - 1, x1, y1, z1, x2, y2, z2, x3, y3, z3);
end;

//==============================================================================
//
// TRTLSector.SetCeilingSlope
//
//==============================================================================
procedure TRTLSector.SetCeilingSlope(const x1, y1, z1: Integer; const x2, y2, z2: Integer; const x3, y3, z3: Integer);
begin
  PS_Sectors.SetSectorCeilingSlope(Integer(self) - 1, x1, y1, z1, x2, y2, z2, x3, y3, z3);
end;

// ---------------------- TRTLSectors ------------------------------------------

//==============================================================================
//
// TRTLSectors.GetSector
//
//==============================================================================
function TRTLSectors.GetSector(id: Integer): TRTLSector;
begin
  if (id >= 0) and (id < numsectors) then
    Result := TRTLSector(id + 1)
  else
    Result := TRTLSector(SECTOR_INVALID);
end;

//==============================================================================
//
// TRTLSectorSlopeSector_R
//
//==============================================================================
procedure TRTLSectorSlopeSector_R(Self: TRTLSector; var T: TRTLSector);
begin
  T := rtlsectors[PS_Sectors.GetSectorSlopeSector(Integer(Self) - 1)];
end;

//==============================================================================
//
// TRTLSectorMidSector_R
//
//==============================================================================
procedure TRTLSectorMidSector_R(Self: TRTLSector; var T: TRTLSector);
begin
  T := rtlsectors[PS_Sectors.GetSectorMidSector(Integer(Self) - 1)];
end;

{$IFDEF DOOM_OR_STRIFE}

//==============================================================================
//
// TRTLSectorCeilingYOffset_W
//
//==============================================================================
procedure TRTLSectorCeilingYOffset_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorCeilingYOffset(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorCeilingYOffset_R
//
//==============================================================================
procedure TRTLSectorCeilingYOffset_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorCeilingYOffset(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorCeilingXOffset_W
//
//==============================================================================
procedure TRTLSectorCeilingXOffset_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorCeilingXOffset(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorCeilingXOffset_R
//
//==============================================================================
procedure TRTLSectorCeilingXOffset_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorCeilingXOffset(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorFloorYOffset_W
//
//==============================================================================
procedure TRTLSectorFloorYOffset_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorFloorYOffset(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFloorYOffset_R
//
//==============================================================================
procedure TRTLSectorFloorYOffset_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorFloorYOffset(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorFloorXOffset_W
//
//==============================================================================
procedure TRTLSectorFloorXOffset_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorFloorXOffset(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFloorXOffset_R
//
//==============================================================================
procedure TRTLSectorFloorXOffset_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorFloorXOffset(Integer(Self) - 1);
end;
{$ENDIF}

//==============================================================================
//
// TRTLSectorNumLines_R
//
//==============================================================================
procedure TRTLSectorNumLines_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorNumLines(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorLines_R
//
//==============================================================================
procedure TRTLSectorLines_R(Self: TRTLSector; var T: TDynamicIntegerArray);
begin
  T := TDynamicIntegerArray(PS_Sectors.GetSectorLines(Integer(Self) - 1));
end;

//==============================================================================
//
// TRTLSectorNumActors_R
//
//==============================================================================
procedure TRTLSectorNumActors_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorNumActors(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorActors_R
//
//==============================================================================
procedure TRTLSectorActors_R(Self: TRTLSector; var T: TActorArray);
begin
  T := TActorArray(PS_Sectors.GetSectorActors(Integer(Self) - 1));
end;

//==============================================================================
//
// TRTLSectorTag_W
//
//==============================================================================
procedure TRTLSectorTag_W(Self: TRTLSector; const T: Integer);
begin
  PS_Sectors.SetSectorTag(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorTag_R
//
//==============================================================================
procedure TRTLSectorTag_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorTag(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorSpecial_R
//
//==============================================================================
procedure TRTLSectorSpecial_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorSpecial(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorLightLevel_W
//
//==============================================================================
procedure TRTLSectorLightLevel_W(Self: TRTLSector; const T: Integer);
begin
  PS_Sectors.SetSectorLightLevel(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorLightLevel_R
//
//==============================================================================
procedure TRTLSectorLightLevel_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorLightLevel(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorCeilingPicture_W
//
//==============================================================================
procedure TRTLSectorCeilingPicture_W(Self: TRTLSector; const T: string);
begin
  PS_Sectors.SetSectorCeilingPicture(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorCeilingPicture_R
//
//==============================================================================
procedure TRTLSectorCeilingPicture_R(Self: TRTLSector; var T: string);
begin
  T := PS_Sectors.GetSectorCeilingPicture(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorFloorPicture_W
//
//==============================================================================
procedure TRTLSectorFloorPicture_W(Self: TRTLSector; const T: string);
begin
  PS_Sectors.SetSectorFloorPicture(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFloorPicture_R
//
//==============================================================================
procedure TRTLSectorFloorPicture_R(Self: TRTLSector; var T: string);
begin
  T := PS_Sectors.GetSectorFloorPicture(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorCeilingHeight_W
//
//==============================================================================
procedure TRTLSectorCeilingHeight_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorCeilingHeight(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorCeilingHeight_R
//
//==============================================================================
procedure TRTLSectorCeilingHeight_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorCeilingHeight(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorFloorHeight_W
//
//==============================================================================
procedure TRTLSectorFloorHeight_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorFloorHeight(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFloorHeight_R
//
//==============================================================================
procedure TRTLSectorFloorHeight_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorFloorHeight(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorFloorAngle_W
//
//==============================================================================
procedure TRTLSectorFloorAngle_W(Self: TRTLSector; const T: LongWord);
begin
  PS_Sectors.SetSectorFloorAngle(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFloorAngle_R
//
//==============================================================================
procedure TRTLSectorFloorAngle_R(Self: TRTLSector; var T: LongWord);
begin
  T := PS_Sectors.GetSectorFloorAngle(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorFloorAngleX_W
//
//==============================================================================
procedure TRTLSectorFloorAngleX_W(Self: TRTLSector; const T: Integer);
begin
  PS_Sectors.SetSectorFloorAngleX(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFloorAngleX_R
//
//==============================================================================
procedure TRTLSectorFloorAngleX_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorFloorAngleX(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorFloorAngleY_W
//
//==============================================================================
procedure TRTLSectorFloorAngleY_W(Self: TRTLSector; const T: Integer);
begin
  PS_Sectors.SetSectorFloorAngleY(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFloorAngleY_R
//
//==============================================================================
procedure TRTLSectorFloorAngleY_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorFloorAngleY(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorCeilingAngle_W
//
//==============================================================================
procedure TRTLSectorCeilingAngle_W(Self: TRTLSector; const T: LongWord);
begin
  PS_Sectors.SetSectorCeilingAngle(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorCeilingAngle_R
//
//==============================================================================
procedure TRTLSectorCeilingAngle_R(Self: TRTLSector; var T: LongWord);
begin
  T := PS_Sectors.GetSectorCeilingAngle(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorCeilingAngleX_W
//
//==============================================================================
procedure TRTLSectorCeilingAngleX_W(Self: TRTLSector; const T: Integer);
begin
  PS_Sectors.SetSectorCeilingAngleX(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorCeilingAngleX_R
//
//==============================================================================
procedure TRTLSectorCeilingAngleX_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorCeilingAngleX(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorCeilingAngleY_W
//
//==============================================================================
procedure TRTLSectorCeilingAngleY_W(Self: TRTLSector; const T: Integer);
begin
  PS_Sectors.SetSectorCeilingAngleY(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorCeilingAngleY_R
//
//==============================================================================
procedure TRTLSectorCeilingAngleY_R(Self: TRTLSector; var T: Integer);
begin
  T := PS_Sectors.GetSectorCeilingAngleY(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorRippleFloor_W
//
//==============================================================================
procedure TRTLSectorRippleFloor_W(Self: TRTLSector; const T: Boolean);
begin
  PS_Sectors.SetSectorRippleFloor(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorRippleFloor_R
//
//==============================================================================
procedure TRTLSectorRippleFloor_R(Self: TRTLSector; var T: Boolean);
begin
  T := PS_Sectors.GetSectorRippleFloor(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorRippleCeiling_W
//
//==============================================================================
procedure TRTLSectorRippleCeiling_W(Self: TRTLSector; const T: Boolean);
begin
  PS_Sectors.SetSectorRippleCeiling(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorRippleCeiling_R
//
//==============================================================================
procedure TRTLSectorRippleCeiling_R(Self: TRTLSector; var T: Boolean);
begin
  T := PS_Sectors.GetSectorRippleCeiling(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorInterpolate_W
//
//==============================================================================
procedure TRTLSectorInterpolate_W(Self: TRTLSector; const T: Boolean);
begin
  PS_Sectors.SetSectorInterpolate(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorInterpolate_R
//
//==============================================================================
procedure TRTLSectorInterpolate_R(Self: TRTLSector; var T: Boolean);
begin
  T := PS_Sectors.GetSectorInterpolate(Integer(Self) - 1);
end;

//==============================================================================
// TRTLSectorFog_W
//
// JVAL: Sector fog (VERSION 207)
//
//==============================================================================
procedure TRTLSectorFog_W(Self: TRTLSector; const T: Boolean);
begin
  PS_Sectors.SetSectorFog(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorFog_R
//
//==============================================================================
procedure TRTLSectorFog_R(Self: TRTLSector; var T: Boolean);
begin
  T := PS_Sectors.GetSectorFog(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorGravity_W
//
// JVAL: sector gravity (VERSION 204)
//
//==============================================================================
procedure TRTLSectorGravity_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorGravity(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorGravity_R
//
// JVAL: sector gravity (VERSION 204)
//
//==============================================================================
procedure TRTLSectorGravity_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorGravity(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorWindThrust_W
//
// JVAL: 20220223 - Sector WindThrust
//
//==============================================================================
procedure TRTLSectorWindThrust_W(Self: TRTLSector; const T: fixed_t);
begin
  PS_Sectors.SetSectorWindThrust(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorWindThrust_R
//
// JVAL: 20220223 - Sector WindThrust
//
//==============================================================================
procedure TRTLSectorWindThrust_R(Self: TRTLSector; var T: fixed_t);
begin
  T := PS_Sectors.GetSectorWindThrust(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorWindAngle_W
//
// JVAL: 20220223 - Sector WindAngle
//
//==============================================================================
procedure TRTLSectorWindAngle_W(Self: TRTLSector; const T: angle_t);
begin
  PS_Sectors.SetSectorWindAngle(Integer(Self) - 1, T);
end;

//==============================================================================
//
// TRTLSectorWindAngle_R
//
// JVAL: 20220223 - Sector WindAngle
//
//==============================================================================
procedure TRTLSectorWindAngle_R(Self: TRTLSector; var T: angle_t);
begin
  T := PS_Sectors.GetSectorWindAngle(Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLSectorID_R
//
//==============================================================================
procedure TRTLSectorID_R(Self: TRTLSector; var T: Integer);
begin
  T := Integer(Self) - 1;
  if (T < 0) or (T >= numsectors) then
    T := SECTOR_INVALID;
end;

//==============================================================================
//
// TRTLSectorsCount_R
//
//==============================================================================
procedure TRTLSectorsCount_R(Self: TRTLSectors; var T: Integer);
begin
  T := numsectors;
end;

//==============================================================================
//
// TRTLSectorsSector_R
//
//==============================================================================
procedure TRTLSectorsSector_R(Self: TRTLSectors; var T: TRTLSector; const t1: Integer);
begin
  T := Self[t1];
end;

// --------------------------- PLAYERS -----------------------------------------


// ----------------------------- MOBJS -----------------------------------------

type
  TFlagResult = record
    flags: PInteger;
    flag: Integer;
  end;

//==============================================================================
//==============================================================================
//
// _info_flag_result
//
//==============================================================================
function _info_flag_result(const inf: Pmobjinfo_t; const flag: LongWord): TFlagResult;
begin
  if flag < 32 then
  begin
    Result.flags := @inf.flags;
    Result.flag := (1 shl flag);
    Exit;
  end;

  if flag < 64 then
  begin
  {$IFDEF HERETIC_OR_HEXEN}
    Result.flags := @inf.flags2;
    Result.flag := (1 shl (flag - 32));
  {$ELSE}
    Result.flags := nil;
    Result.flag := 0;
  {$ENDIF}
    Exit;
  end;

  if flag < 96 then
  begin
    Result.flags := @inf.flags_ex;
    Result.flag := (1 shl (flag - 64));
    Exit;
  end;

  if flag < 128 then
  begin
    Result.flags := @inf.flags2_ex;
    Result.flag := (1 shl (flag - 96));
    Exit;
  end;

  if flag < 160 then
  begin
    Result.flags := @inf.flags3_ex;
    Result.flag := (1 shl (flag - 128));
    Exit;
  end;

  if flag < 192 then
  begin
    Result.flags := @inf.flags4_ex;
    Result.flag := (1 shl (flag - 160));
    Exit;
  end;

  if flag < 224 then
  begin
    Result.flags := @inf.flags5_ex;
    Result.flag := (1 shl (flag - 192));
    Exit;
  end;

  if flag < 256 then
  begin
    Result.flags := @inf.flags6_ex;
    Result.flag := (1 shl (flag - 224));
    Exit;
  end;

  Result.flags := nil;
  Result.flag := 0;
end;

//==============================================================================
//
// PS_GetMobjInfoFlag
//
//==============================================================================
function PS_GetMobjInfoFlag(const typ: Integer; const flg: integer): Boolean;
var
  flgresult: TFlagResult;
begin
  if (typ < 0) or (typ >= nummobjtypes) then
  begin
    Result := False;
    Exit;
  end;

  flgresult := _info_flag_result(@mobjinfo[typ], flg);
  if flgresult.flags = nil then
  begin
    Result := False;
    Exit;
  end;

  Result := flgresult.flags^ and flgresult.flag <> 0;
end;

// --------------------- TRTLMobjInfo ------------------------------------------

//==============================================================================
//
// TRTLMobjInfo.GetItem
//
//==============================================================================
function TRTLMobjInfo.GetItem(id: Integer): TRTLMobjInfoItem;
begin
  if (id >= 0) and (id < nummobjtypes) then
    Result := TRTLMobjInfoItem(id + 1)
  else
    Result := TRTLMobjInfoItem(MOBJTYPE_INVALID);
end;

//==============================================================================
//
// TRTLMobjInfoItem_R
//
//==============================================================================
procedure TRTLMobjInfoItem_R(Self: TRTLMobjInfo; var T: TRTLMobjInfoItem; const t1: integer);
begin
  T := Self[t1];
end;

//==============================================================================
//
// TRTLMobjInfoCount_R
//
//==============================================================================
procedure TRTLMobjInfoCount_R(Self: TRTLMobjInfo; var T: Integer);
begin
  T := nummobjtypes;
end;

//==============================================================================
//
// TRTLMobjInfoItemName_R
//
//==============================================================================
procedure TRTLMobjInfoItemName_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifName, Integer(Self) - 1);
end;

{$IFDEF STRIFE}

//==============================================================================
//
// TRTLMobjInfoItemName2_R
//
//==============================================================================
procedure TRTLMobjInfoItemName2_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifName, Integer(Self) - 1);
end;
{$ENDIF}

//==============================================================================
//
// TRTLMobjInfoItemInheritsFrom_R
//
//==============================================================================
procedure TRTLMobjInfoItemInheritsFrom_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifInheritsFrom, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemDoomEdNum_R
//
//==============================================================================
procedure TRTLMobjInfoItemDoomEdNum_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifDoomEdNum, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSpawnState_R
//
//==============================================================================
procedure TRTLMobjInfoItemSpawnState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifSpawnState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSpawnHealth_R
//
//==============================================================================
procedure TRTLMobjInfoItemSpawnHealth_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifSpawnHealth, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSeeState_R
//
//==============================================================================
procedure TRTLMobjInfoItemSeeState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifSeeState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSeeSound_R
//
//==============================================================================
procedure TRTLMobjInfoItemSeeSound_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifSeeSound, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemReactionTime_R
//
//==============================================================================
procedure TRTLMobjInfoItemReactionTime_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifReactionTime, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemAttackSound_R
//
//==============================================================================
procedure TRTLMobjInfoItemAttackSound_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifAttackSound, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemPainState_R
//
//==============================================================================
procedure TRTLMobjInfoItemPainState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifPainState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemPainChance_R
//
//==============================================================================
procedure TRTLMobjInfoItemPainChance_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifPainChance, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemPainSound_R
//
//==============================================================================
procedure TRTLMobjInfoItemPainSound_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifPainSound, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMeleeState_R
//
//==============================================================================
procedure TRTLMobjInfoItemMeleeState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMeleeState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMissileState_R
//
//==============================================================================
procedure TRTLMobjInfoItemMissileState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMissileState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemDeathState_R
//
//==============================================================================
procedure TRTLMobjInfoItemDeathState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifDeathState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemXdeathState_R
//
//==============================================================================
procedure TRTLMobjInfoItemXdeathState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifXdeathState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemDeathSound_R
//
//==============================================================================
procedure TRTLMobjInfoItemDeathSound_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifDeathSound, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSpeed_R
//
//==============================================================================
procedure TRTLMobjInfoItemSpeed_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifSpeed, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemVSpeed_R
//
//==============================================================================
procedure TRTLMobjInfoItemVSpeed_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifVSpeed, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMinMissileChance_R
//
//==============================================================================
procedure TRTLMobjInfoItemMinMissileChance_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMinMissileChance, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemPushFactor_R
//
//==============================================================================
procedure TRTLMobjInfoItemPushFactor_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifPushFactor, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemScale_R
//
//==============================================================================
procedure TRTLMobjInfoItemScale_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifScale, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemGravity_R
//
//==============================================================================
procedure TRTLMobjInfoItemGravity_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifGravity, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemRadius_R
//
//==============================================================================
procedure TRTLMobjInfoItemRadius_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifRadius, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemHeight_R
//
//==============================================================================
procedure TRTLMobjInfoItemHeight_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifHeight, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMass_R
//
//==============================================================================
procedure TRTLMobjInfoItemMass_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMass, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemDamage_R
//
//==============================================================================
procedure TRTLMobjInfoItemDamage_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifDamage, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemActiveSound_R
//
//==============================================================================
procedure TRTLMobjInfoItemActiveSound_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifActiveSound, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemFlag_R
//
//==============================================================================
procedure TRTLMobjInfoItemFlag_R(Self: TRTLMobjInfoItem; var T: Boolean; const t1: integer);
begin
  T := PS_MobjInfo.GetMobjInfoFlag(Integer(Self) - 1, t1);
end;

//==============================================================================
//
// TRTLMobjInfoItemRaiseState_R
//
//==============================================================================
procedure TRTLMobjInfoItemRaiseState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifRaiseState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemCustomSound1_R
//
//==============================================================================
procedure TRTLMobjInfoItemCustomSound1_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifCustomSound1, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemCustomSound2_R
//
//==============================================================================
procedure TRTLMobjInfoItemCustomSound2_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifCustomSound2, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemCustomSound3_R
//
//==============================================================================
procedure TRTLMobjInfoItemCustomSound3_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifCustomSound3, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMeleeSound_R
//
//==============================================================================
procedure TRTLMobjInfoItemMeleeSound_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifMeleeSound, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemDropItem_R
//
//==============================================================================
procedure TRTLMobjInfoItemDropItem_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifDropItem, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMissileType_R
//
//==============================================================================
procedure TRTLMobjInfoItemMissileType_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMissiletype, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemExplosionDamage_R
//
//==============================================================================
procedure TRTLMobjInfoItemExplosionDamage_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifExplosionDamage, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemExplosionRadius_R
//
//==============================================================================
procedure TRTLMobjInfoItemExplosionRadius_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifExplosionRadius, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMeleeDamage_R
//
//==============================================================================
procedure TRTLMobjInfoItemMeleeDamage_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMeleeDamage, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemRenderStyle_R
//
//==============================================================================
procedure TRTLMobjInfoItemRenderStyle_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifRenderStyle, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemAlpha_R
//
//==============================================================================
procedure TRTLMobjInfoItemAlpha_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifAlpha, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemHealState_R
//
//==============================================================================
procedure TRTLMobjInfoItemHealState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifHealState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemCrashState_R
//
//==============================================================================
procedure TRTLMobjInfoItemCrashState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifCrashState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemCrushState_R
//
//==============================================================================
procedure TRTLMobjInfoItemCrushState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifCrushState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemFloatSpeed_R
//
//==============================================================================
procedure TRTLMobjInfoItemFloatSpeed_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifFloatSpeed, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemNormalSpeed_R
//
//==============================================================================
procedure TRTLMobjInfoItemNormalSpeed_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifNormalSpeed, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemFastSpeed_R
//
//==============================================================================
procedure TRTLMobjInfoItemFastSpeed_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifFastSpeed, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemObituary_R
//
//==============================================================================
procedure TRTLMobjInfoItemObituary_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifObituary, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemHitObituary_R
//
//==============================================================================
procedure TRTLMobjInfoItemHitObituary_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifHitObituary, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemGender_R
//
//==============================================================================
procedure TRTLMobjInfoItemGender_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifGender, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMeleeRange_R
//
//==============================================================================
procedure TRTLMobjInfoItemMeleeRange_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMeleeRange, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMaxStepHeight_R
//
//==============================================================================
procedure TRTLMobjInfoItemMaxStepHeight_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMaxStepHeight, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMaxDropOffHeight_R
//
//==============================================================================
procedure TRTLMobjInfoItemMaxDropOffHeight_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMaxDropOffHeight, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemGibHealth_R
//
//==============================================================================
procedure TRTLMobjInfoItemGibHealth_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifGibHealth, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMaxTargetRange_R
//
//==============================================================================
procedure TRTLMobjInfoItemMaxTargetRange_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMaxTargetRange, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemWeaveIndexXY_R
//
//==============================================================================
procedure TRTLMobjInfoItemWeaveIndexXY_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifWeaveIndexXY, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemWeaveIndexZ_R
//
//==============================================================================
procedure TRTLMobjInfoItemWeaveIndexZ_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifWeaveIndexZ, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemFriction_R
//
//==============================================================================
procedure TRTLMobjInfoItemFriction_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifFriction, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSpriteDX_R
//
//==============================================================================
procedure TRTLMobjInfoItemSpriteDX_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifSpriteDX, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSpriteDY_R
//
//==============================================================================
procedure TRTLMobjInfoItemSpriteDY_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifSpriteDY, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemInfightingGroup_R
//
//==============================================================================
procedure TRTLMobjInfoItemInfightingGroup_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifInfightingGroup, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemProjectileGroup_R
//
//==============================================================================
procedure TRTLMobjInfoItemProjectileGroup_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifProjectileGroup, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemSplashGroup_R
//
//==============================================================================
procedure TRTLMobjInfoItemSplashGroup_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifSplashGroup, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemRipSound_R
//
//==============================================================================
procedure TRTLMobjInfoItemRipSound_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifRipSound, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemInteractState_R
//
//==============================================================================
procedure TRTLMobjInfoItemInteractState_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifInteractState, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMissileHeight_R
//
//==============================================================================
procedure TRTLMobjInfoItemMissileHeight_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMissileHeight, Integer(Self) - 1);
end;

//==============================================================================
//
// TRTLMobjInfoItemMeleeThreshold_R
//
//==============================================================================
procedure TRTLMobjInfoItemMeleeThreshold_R(Self: TRTLMobjInfoItem; var T: integer);
begin
  T := PS_MobjInfo.GetNumber(mifMeleeThreshold, Integer(Self) - 1);
end;


// ---------------------- REGISTRATION -----------------------------------------

//==============================================================================
//
// SIRegister_Game
//
// Compiler Registration
//
//==============================================================================
procedure SIRegister_Game(C: TPSPascalCompiler);
var
  cactor: TPSCompileTimeClass;
  cactors: TPSCompileTimeClass;
  cvertex: TPSCompileTimeClass;
  cvertexes: TPSCompileTimeClass;
  cside: TPSCompileTimeClass;
  csides: TPSCompileTimeClass;
  cline: TPSCompileTimeClass;
  clines: TPSCompileTimeClass;
  csector: TPSCompileTimeClass;
  csectors: TPSCompileTimeClass;
  cmobjinfoitem: TPSCompileTimeClass;
  cmobjinfo: TPSCompileTimeClass;
begin
  cactor := C.AddClassN(C.FindClass('!TOBJECT'), '!TActor');
  cactors := C.AddClassN(C.FindClass('!TOBJECT'), '!TActors');
  cvertex := C.AddClassN(C.FindClass('!TOBJECT'), '!TVertex');
  cvertexes := C.AddClassN(C.FindClass('!TOBJECT'), '!TVertexes');
  cside := C.AddClassN(C.FindClass('!TOBJECT'), '!TSide');
  csides := C.AddClassN(C.FindClass('!TOBJECT'), '!TSides');
  cline := C.AddClassN(C.FindClass('!TOBJECT'), '!TLine');
  clines := C.AddClassN(C.FindClass('!TOBJECT'), '!TLines');
  csector := C.AddClassN(C.FindClass('!TOBJECT'), '!TSector');
  csectors := C.AddClassN(C.FindClass('!TOBJECT'), '!TSectors');
  cmobjinfoitem := C.AddClassN(C.FindClass('!TOBJECT'),'!TMobjInfoItem');
  cmobjinfo := C.AddClassN(C.FindClass('!TOBJECT'),'!TMobjInfo');

  cactor.RegisterProperty('key', 'LongWord', iptR);
  cactor.RegisterProperty('Target', '!TActor', iptRW);
  cactor.RegisterProperty('Tracer', '!TActor', iptRW);
  cactor.RegisterProperty('Master', '!TActor', iptRW);
  cactor.RegisterProperty('X', 'fixed_t', iptRW);
  cactor.RegisterProperty('Y', 'fixed_t', iptRW);
  cactor.RegisterProperty('Z', 'fixed_t', iptRW);
  cactor.RegisterProperty('MOMX', 'fixed_t', iptRW);
  cactor.RegisterProperty('MOMY', 'fixed_t', iptRW);
  cactor.RegisterProperty('MOMZ', 'fixed_t', iptRW);
  cactor.RegisterProperty('FloorZ', 'fixed_t', iptRW);
  cactor.RegisterProperty('CeilingZ', 'fixed_t', iptRW);
  cactor.RegisterProperty('Speed', 'fixed_t', iptRW);
  cactor.RegisterProperty('Angle', 'angle_t', iptRW);
  cactor.RegisterProperty('Sector', '!TSector', iptR);
  cactor.RegisterProperty('Health', 'Integer', iptRW);
  cactor.RegisterProperty('SpawnHealth', 'Integer', iptR);
  cactor.RegisterProperty('Mass', 'Integer', iptRW);
  cactor.RegisterProperty('Gravity', 'fixed_t', iptRW);
  cactor.RegisterProperty('Special', 'Integer', iptRW);
  cactor.RegisterProperty('Arg1', 'Integer', iptRW);
  cactor.RegisterProperty('Arg2', 'Integer', iptRW);
  cactor.RegisterProperty('Arg3', 'Integer', iptRW);
  cactor.RegisterProperty('Arg4', 'Integer', iptRW);
  cactor.RegisterProperty('Arg5', 'Integer', iptRW);
  cactor.RegisterProperty('Height', 'fixed_t', iptRW);
  cactor.RegisterProperty('WeaveIndexXY', 'Integer', iptRW);
  cactor.RegisterProperty('WeaveIndexZ', 'Integer', iptRW);
  cactor.RegisterProperty('Friction', 'fixed_t', iptRW);
  cactor.RegisterProperty('PainChance', 'fixed_t', iptRW);
  cactor.RegisterProperty('SpriteDX', 'fixed_t', iptRW);
  cactor.RegisterProperty('SpriteDY', 'fixed_t', iptRW);
  cactor.RegisterProperty('InfightingGroup', 'Integer', iptRW);
  cactor.RegisterProperty('ProjectileGroup', 'Integer', iptRW);
  cactor.RegisterProperty('SplashGroup', 'Integer', iptRW);
  cactor.RegisterProperty('Translation', 'string', iptRW);
  cactor.RegisterProperty('BloodColor', 'string', iptRW);
  cactor.RegisterProperty('CustomDropItem', 'Integer', iptRW);
  cactor.RegisterProperty('CustomParams', 'Integer String', iptRW);
  cactor.RegisterProperty('Flag', 'Boolean LongWord', iptRW);
  cactor.RegisterProperty('Name', 'String', iptR);
  {$IFDEF STRIFE}
  cactor.RegisterProperty('Name2', 'String', iptR);
  {$ENDIF}
  cactor.RegisterProperty('Player', 'Integer', iptR);
  cactor.RegisterProperty('MobjType', 'Integer', iptR);
  cactor.RegisterProperty('EditorNumber', 'Integer', iptR);
  cactor.RegisterProperty('SeeSound', 'string', iptR);
  cactor.RegisterProperty('AttackSound', 'string', iptR);
  cactor.RegisterProperty('PainSound', 'string', iptR);
  cactor.RegisterProperty('DeathSound', 'string', iptR);
  cactor.RegisterProperty('ActiveSound', 'string', iptR);
  cactor.RegisterProperty('CustomSound1', 'string', iptR);
  cactor.RegisterProperty('CustomSound2', 'string', iptR);
  cactor.RegisterProperty('CustomSound3', 'string', iptR);
  cactor.RegisterProperty('MeleeSound', 'string', iptR);
  cactor.RegisterProperty('RipSound', 'string', iptR);
  cactor.RegisterProperty('State', 'Integer', iptRW);

  cactor.RegisterMethod('procedure PlaySound(const snd: string);');
  cactor.RegisterMethod('procedure Remove;');
  cactor.RegisterMethod('procedure SetPosition(const x, y, z: fixed_t)');

  cactors.RegisterMethod('function AllActors: TActorArray;');
  cactors.RegisterMethod('function AllMonstersAlive: TActorArray;');
  cactors.RegisterMethod('function AllMonstersDead: TActorArray;');
  cactors.RegisterMethod('function AllMonsters: TActorArray;');
  cactors.RegisterMethod('function AllMissiles: TActorArray;');
  cactors.RegisterMethod('function AllAtSector(const sec: Integer): TActorArray;');
  cactors.RegisterMethod('function AllAtSectorTag(const tag: Integer): TActorArray;');
  cactors.RegisterMethod('function AllEditorNumber(const dn: Integer): TActorArray;');
  cactors.RegisterMethod('function AllType(const typ: Integer): TActorArray;');
  cactors.RegisterProperty('Actor', '!TActor LongWord', iptR);
  cactors.SetDefaultPropery('Actor');

  cvertex.RegisterProperty('X', 'Integer', iptR);
  cvertex.RegisterProperty('Y', 'Integer', iptR);
  cvertex.RegisterProperty('ID', 'Integer', iptR);

  cvertexes.RegisterProperty('Vertex', '!TVertex Integer', iptR);
  cvertexes.SetDefaultPropery('Vertex');
  cvertexes.RegisterProperty('Count', 'Integer', iptR);

  cside.RegisterProperty('TextureOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('TopTextureOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('BottomTextureOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('MidTextureOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('RowOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('TopRowOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('BottomRowOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('MidRowOffset', 'fixed_t', iptRW);
  cside.RegisterProperty('TopTexture', 'string', iptRW);
  cside.RegisterProperty('BottomTexture', 'string', iptRW);
  cside.RegisterProperty('MiddleTexture', 'string', iptRW);
  cside.RegisterProperty('Sector', '!TSector', iptR);
  cside.RegisterProperty('ID', 'Integer', iptR);

  csides.RegisterProperty('Side', '!TSide Integer', iptR);
  csides.SetDefaultPropery('Side');
  csides.RegisterProperty('Count', 'Integer', iptR);

  cline.RegisterProperty('Vertex1', '!TVertex', iptR);
  cline.RegisterProperty('Vertex2', '!TVertex', iptR);
  cline.RegisterProperty('DX', 'fixed_t', iptR);
  cline.RegisterProperty('DY', 'fixed_t', iptR);
  cline.RegisterProperty('Special', 'Integer', iptRW);
  cline.RegisterProperty('Arg1', 'byte', iptRW);
  cline.RegisterProperty('Arg2', 'byte', iptRW);
  cline.RegisterProperty('Arg3', 'byte', iptRW);
  cline.RegisterProperty('Arg4', 'byte', iptRW);
  cline.RegisterProperty('Arg5', 'byte', iptRW);
  {$IFNDEF HEXEN}
  cline.RegisterProperty('Tag', 'Integer', iptRW);
  cline.RegisterProperty('Transparent', 'Boolean', iptRW);
  {$ENDIF}
  cline.RegisterProperty('IsBlocking', 'Boolean', iptRW);
  cline.RegisterProperty('IsBlockingMonsters', 'Boolean', iptRW);
  cline.RegisterProperty('TriggerScripts', 'Boolean', iptRW);
  cline.RegisterProperty('FrontSide', '!TSide', iptR);
  cline.RegisterProperty('BackSide', '!TSide', iptR);
  cline.RegisterProperty('FrontSector', '!TSector', iptR);
  cline.RegisterProperty('BackSector', '!TSector', iptR);
  cline.RegisterProperty('ID', 'Integer', iptR);

  clines.RegisterProperty('Line', '!TLine Integer', iptR);
  clines.SetDefaultPropery('Line');
  clines.RegisterProperty('Count', 'Integer', iptR);

  csector.RegisterProperty('FloorHeight', 'fixed_t', iptRW);
  csector.RegisterProperty('CeilingHeight', 'fixed_t', iptRW);
  csector.RegisterProperty('FloorPicture', 'string', iptRW);
  csector.RegisterProperty('CeilingPicture', 'string', iptRW);
  csector.RegisterProperty('LightLevel', 'Integer', iptRW);
  csector.RegisterProperty('Special', 'Integer', iptR);
  csector.RegisterProperty('Tag', 'Integer', iptRW);
  csector.RegisterProperty('Actors', 'TActorArray', iptR);
  csector.RegisterProperty('NumActors', 'Integer', iptR);
  csector.RegisterProperty('Lines', 'TIntegerArray', iptR);
  csector.RegisterProperty('NumLines', 'Integer', iptR);
  {$IFDEF DOOM_OR_STRIFE}
  csector.RegisterProperty('FloorXOffset', 'fixed_t', iptRW);
  csector.RegisterProperty('FloorYOffset', 'fixed_t', iptRW);
  csector.RegisterProperty('CeilingXOffset', 'fixed_t', iptRW);
  csector.RegisterProperty('CeilingYOffset', 'fixed_t', iptRW);
  {$ENDIF}
  csector.RegisterProperty('MidSector', '!TSector', iptR);
  csector.RegisterProperty('SlopeSector', '!TSector', iptR);
  csector.RegisterProperty('ID', 'Integer', iptR);
  csector.RegisterProperty('FloorAngle', 'angle_t', iptRW);
  csector.RegisterProperty('FloorAngleX', 'fixed_t', iptRW);
  csector.RegisterProperty('FloorAngleY', 'fixed_t', iptRW);
  csector.RegisterProperty('CeilingAngle', 'angle_t', iptRW);
  csector.RegisterProperty('CeilingAngleX', 'fixed_t', iptRW);
  csector.RegisterProperty('CeilingAngleY', 'fixed_t', iptRW);
  csector.RegisterProperty('RippleFloor', 'boolean', iptRW);
  csector.RegisterProperty('RippleCeiling', 'boolean', iptRW);
  csector.RegisterProperty('Interpolate', 'boolean', iptRW);
  csector.RegisterProperty('Fog', 'boolean', iptRW);
  csector.RegisterProperty('Gravity', 'fixed_t', iptRW);
  csector.RegisterProperty('WindThrust', 'fixed_t', iptRW);
  csector.RegisterProperty('WindAngle', 'angle_t', iptRW);
  csector.RegisterMethod('procedure PlaySound(const snd: string);');
  csector.RegisterMethod('procedure MoveZ(const dz: fixed_t);');
  csector.RegisterMethod('procedure SetFloorSlope(const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);');
  csector.RegisterMethod('procedure SetCeilingSlope(const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);');

  csectors.RegisterProperty('Sector', '!TSector Integer', iptR);
  csectors.SetDefaultPropery('Sector');
  csectors.RegisterProperty('Count', 'Integer', iptR);

  cmobjinfoitem.RegisterProperty('Name', 'string', iptR);
  cmobjinfoitem.RegisterProperty('Name2', 'string', iptR);
  cmobjinfoitem.RegisterProperty('InheritsFrom', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('DoomEdNum', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('SpawnState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('SpawnHealth', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('SeeState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('SeeSound', 'string', iptR);
  cmobjinfoitem.RegisterProperty('ReactionTime', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('AttackSound', 'string', iptR);
  cmobjinfoitem.RegisterProperty('PainState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('PainChance', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('PainSound', 'string', iptR);
  cmobjinfoitem.RegisterProperty('MeleeState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MissileState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('DeathState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('XdeathState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('DeathSound', 'string', iptR);
  cmobjinfoitem.RegisterProperty('Speed', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Radius', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Height', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Mass', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Damage', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('ActiveSound', 'string', iptR);
  cmobjinfoitem.RegisterProperty('Flag', 'Boolean Integer', iptR);
  cmobjinfoitem.RegisterProperty('RaiseState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('CustomSound1', 'string', iptR);
  cmobjinfoitem.RegisterProperty('CustomSound2', 'string', iptR);
  cmobjinfoitem.RegisterProperty('CustomSound3', 'string', iptR);
  cmobjinfoitem.RegisterProperty('MeleeSound', 'string', iptR);
  cmobjinfoitem.RegisterProperty('DropItem', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MissileType', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('ExplosionDamage', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('ExplosionRadius', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MeleeDamage', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('RenderStyle', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Alpha', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('HealState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('CrashState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('CrushState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('InteractState', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MissileHeight', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('VSpeed', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MinMissileChance', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('PushFactor', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Scale', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Gravity', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('FloatSpeed', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('NormalSpeed', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('FastSpeed', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Obituary', 'String', iptR);
  cmobjinfoitem.RegisterProperty('HitObituary', 'String', iptR);
  cmobjinfoitem.RegisterProperty('Gender', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MeleeRange', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MaxStepHeight', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MaxDropOffHeight', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('GibHealth', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('MaxTargetRange', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('WeaveIndexXY', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('WeaveIndexZ', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('Friction', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('SpriteDX', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('SpriteDY', 'Integer', iptR);
  cmobjinfoitem.RegisterProperty('InfightingGroup', 'Integer', iptRW);
  cmobjinfoitem.RegisterProperty('ProjectileGroup', 'Integer', iptRW);
  cmobjinfoitem.RegisterProperty('SplashGroup', 'Integer', iptRW);
  cmobjinfoitem.RegisterProperty('RipSound', 'string', iptRW);
  cmobjinfoitem.RegisterProperty('MeleeThreshold', 'Integer', iptRW);

  cmobjinfo.RegisterProperty('Item', '!TMobjInfoItem integer', iptR);
  cmobjinfo.SetDefaultPropery('Item');
  cmobjinfo.RegisterProperty('Count', 'Integer', iptR);

  AddImportedClassVariable(C, 'Actors', '!TActors');
  AddImportedClassVariable(C, 'Vertexes', '!TVertexes');
  AddImportedClassVariable(C, 'Sides', '!TSides');
  AddImportedClassVariable(C, 'Lines', '!TLines');
  AddImportedClassVariable(C, 'Sectors', '!TSectors');
  AddImportedClassVariable(C, 'MobjInfo', '!TMobjInfo');
end;

//==============================================================================
// RIRegister_Game
//
// Runtime Registration
//
//==============================================================================
procedure RIRegister_Game(CLI: TPSRuntimeClassImporter);
var
  ractor: TPSRuntimeClass;
  ractors: TPSRuntimeClass;
  rvertex: TPSRuntimeClass;
  rvertexes: TPSRuntimeClass;
  rside: TPSRuntimeClass;
  rsides: TPSRuntimeClass;
  rline: TPSRuntimeClass;
  rlines: TPSRuntimeClass;
  rsector: TPSRuntimeClass;
  rsectors: TPSRuntimeClass;
  rmobjinfoitem: TPSRuntimeClass;
  rmobjinfo: TPSRuntimeClass;
begin
  ractor := CLI.Add2(TRTLActor, '!TACTOR');
  ractors := CLI.Add2(TRTLActors, '!TACTORS');
  rvertex := CLI.Add2(TRTLVertex, '!TVERTEX');
  rvertexes := CLI.Add2(TRTLVertexes, '!TVERTEXES');
  rside := CLI.Add2(TRTLSide, '!TSIDE');
  rsides := CLI.Add2(TRTLSides, '!TSIDES');
  rline := CLI.Add2(TRTLLine, '!TLINE');
  rlines := CLI.Add2(TRTLLines, '!TLINES');
  rsector := CLI.Add2(TRTLLine, '!TSECTOR');
  rsectors := CLI.Add2(TRTLLines, '!TSECTORS');
  rmobjinfoitem := CLI.Add2(TRTLMobjInfoItem, '!TMOBJINFOITEM');
  rmobjinfo := CLI.Add2(TRTLMobjInfo, '!TMOBJINFO');

  ractor.RegisterPropertyHelper(@TRTLActorkey_R, nil, 'key');
  ractor.RegisterPropertyHelper(@TRTLActorTarget_R, @TRTLActorTarget_W, 'Target');
  ractor.RegisterPropertyHelper(@TRTLActorTracer_R, @TRTLActorTracer_W, 'Tracer');
  ractor.RegisterPropertyHelper(@TRTLActorMaster_R, @TRTLActorMaster_W, 'Master');
  ractor.RegisterPropertyHelper(@TRTLActorX_R, @TRTLActorX_W, 'X');
  ractor.RegisterPropertyHelper(@TRTLActorY_R, @TRTLActorY_W, 'Y');
  ractor.RegisterPropertyHelper(@TRTLActorZ_R, @TRTLActorZ_W, 'Z');
  ractor.RegisterPropertyHelper(@TRTLActorMOMX_R, @TRTLActorMOMX_W, 'MOMX');
  ractor.RegisterPropertyHelper(@TRTLActorMOMY_R, @TRTLActorMOMY_W, 'MOMY');
  ractor.RegisterPropertyHelper(@TRTLActorMOMZ_R, @TRTLActorMOMZ_W, 'MOMZ');
  ractor.RegisterPropertyHelper(@TRTLActorFloorZ_R, @TRTLActorFloorZ_W, 'FloorZ');
  ractor.RegisterPropertyHelper(@TRTLActorCeilingZ_R, @TRTLActorCeilingZ_W, 'CeilingZ');
  ractor.RegisterPropertyHelper(@TRTLActorSpeed_R, @TRTLActorSpeed_W, 'Speed');
  ractor.RegisterPropertyHelper(@TRTLActorAngle_R, @TRTLActorAngle_W, 'Angle');
  ractor.RegisterPropertyHelper(@TRTLActorSector_R, nil, 'Sector');
  ractor.RegisterPropertyHelper(@TRTLActorHealth_R, @TRTLActorHealth_W, 'Health');
  ractor.RegisterPropertyHelper(@TRTLActorSpawnHealth_R, nil, 'SpawnHealth');
  ractor.RegisterPropertyHelper(@TRTLActorMass_R, @TRTLActorMass_W, 'Mass');
  ractor.RegisterPropertyHelper(@TRTLActorHeight_R, @TRTLActorHeight_W, 'Height');
  ractor.RegisterPropertyHelper(@TRTLActorCustomDropItem_R, @TRTLActorCustomDropItem_W, 'CustomDropItem');
  ractor.RegisterPropertyHelper(@TRTLActorPushFactor_R, @TRTLActorPushFactor_W, 'PushFactor');
  ractor.RegisterPropertyHelper(@TRTLActorScale_R, @TRTLActorScale_W, 'Scale');
  ractor.RegisterPropertyHelper(@TRTLActorGravity_R, @TRTLActorGravity_W, 'Gravity');
  ractor.RegisterPropertyHelper(@TRTLActorSpecial_R, @TRTLActorSpecial_W, 'Special');
  ractor.RegisterPropertyHelper(@TRTLActorArg1_R, @TRTLActorArg1_W, 'Arg1');
  ractor.RegisterPropertyHelper(@TRTLActorArg2_R, @TRTLActorArg2_W, 'Arg2');
  ractor.RegisterPropertyHelper(@TRTLActorArg3_R, @TRTLActorArg3_W, 'Arg3');
  ractor.RegisterPropertyHelper(@TRTLActorArg4_R, @TRTLActorArg4_W, 'Arg4');
  ractor.RegisterPropertyHelper(@TRTLActorArg5_R, @TRTLActorArg5_W, 'Arg5');
  ractor.RegisterPropertyHelper(@TRTLActorWeaveIndexXY_R, @TRTLActorWeaveIndexXY_W, 'WeaveIndexXY');
  ractor.RegisterPropertyHelper(@TRTLActorWeaveIndexZ_R, @TRTLActorWeaveIndexZ_W, 'WeaveIndexZ');
  ractor.RegisterPropertyHelper(@TRTLActorFriction_R, @TRTLActorFriction_W, 'Friction');
  ractor.RegisterPropertyHelper(@TRTLActorPainChance_R, @TRTLActorPainChance_W, 'PainChance');
  ractor.RegisterPropertyHelper(@TRTLActorSpriteDX_R, @TRTLActorSpriteDX_W, 'SpriteDX');
  ractor.RegisterPropertyHelper(@TRTLActorSpriteDY_R, @TRTLActorSpriteDY_W, 'SpriteDY');
  ractor.RegisterPropertyHelper(@TRTLActorInfightingGroup_R, @TRTLActorInfightingGroup_W, 'InfightingGroup');
  ractor.RegisterPropertyHelper(@TRTLActorProjectileGroup_R, @TRTLActorProjectileGroup_W, 'ProjectileGroup');
  ractor.RegisterPropertyHelper(@TRTLActorSplashGroup_R, @TRTLActorSplashGroup_W, 'SplashGroup');
  ractor.RegisterPropertyHelper(@TRTLActorTranslation_R, @TRTLActorTranslation_W, 'Translation');
  ractor.RegisterPropertyHelper(@TRTLActorBloodColor_R, @TRTLActorBloodColor_W, 'BloodColor');
  ractor.RegisterPropertyHelper(@TRTLActorCustomParams_R, @TRTLActorCustomParams_W, 'CustomParams');
  ractor.RegisterPropertyHelper(@TRTLActorFlags_R, @TRTLActorFlags_W, 'Flag');
  ractor.RegisterPropertyHelper(@TRTLActorName_R, nil, 'Name');
  {$IFDEF STRIFE}
  ractor.RegisterPropertyHelper(@TRTLActorName2_R, nil, 'Name2');
  {$ENDIF}
  ractor.RegisterPropertyHelper(@TRTLActorPlayer_R, nil, 'Player');
  ractor.RegisterPropertyHelper(@TRTLActorMobjType_R, nil, 'MobjType');
  ractor.RegisterPropertyHelper(@TRTLActorEditorNumber_R, nil, 'EditorNumber');
  ractor.RegisterPropertyHelper(@TRTLActorSeeSound_R, nil, 'SeeSound');
  ractor.RegisterPropertyHelper(@TRTLActorAttackSound_R, nil, 'AttackSound');
  ractor.RegisterPropertyHelper(@TRTLActorPainSound_R, nil, 'PainSound');
  ractor.RegisterPropertyHelper(@TRTLActorDeathSound_R, nil, 'DeathSound');
  ractor.RegisterPropertyHelper(@TRTLActorActiveSound_R, nil, 'ActiveSound');
  ractor.RegisterPropertyHelper(@TRTLActorCustomSound1_R, nil, 'CustomSound1');
  ractor.RegisterPropertyHelper(@TRTLActorCustomSound2_R, nil, 'CustomSound2');
  ractor.RegisterPropertyHelper(@TRTLActorCustomSound3_R, nil, 'CustomSound3');
  ractor.RegisterPropertyHelper(@TRTLActorMeleeSound_R, nil, 'MeleeSound');
  ractor.RegisterPropertyHelper(@TRTLActorRipSound_R, nil, 'RipSound');
  ractor.RegisterPropertyHelper(@TRTLActorState_R, @TRTLActorState_W, 'State');
  ractor.RegisterMethod(@TRTLActor.PlaySound, 'PlaySound');
  ractor.RegisterMethod(@TRTLActor.Remove, 'Remove');
  ractor.RegisterMethod(@TRTLActor.SetPosition, 'SetPosition');

  ractors.RegisterMethod(@TRTLActors.AllActors, 'AllActors');
  ractors.RegisterMethod(@TRTLActors.AllMonstersAlive, 'AllMonstersAlive');
  ractors.RegisterMethod(@TRTLActors.AllMonstersDead, 'AllMonstersDead');
  ractors.RegisterMethod(@TRTLActors.AllMonsters, 'AllMonsters');
  ractors.RegisterMethod(@TRTLActors.AllMissiles, 'AllMissiles');
  ractors.RegisterMethod(@TRTLActors.AllAtSector, 'AllAtSector');
  ractors.RegisterMethod(@TRTLActors.AllAtSectorTag, 'AllAtSectorTag');
  ractors.RegisterMethod(@TRTLActors.AllEditorNumber, 'AllEditorNumber');
  ractors.RegisterMethod(@TRTLActors.AllType, 'AllType');
  ractors.RegisterPropertyHelper(@TRTLActorsActor_R, nil, 'actor');

  rvertex.RegisterPropertyHelper(@TRTLVertexX_R, nil, 'X');
  rvertex.RegisterPropertyHelper(@TRTLVertexY_R, nil, 'Y');
  rvertex.RegisterPropertyHelper(@TRTLVertexID_R, nil, 'ID');

  rvertexes.RegisterPropertyHelper(@TRTLVertexesVertex_R, nil, 'Vertex');
  rvertexes.RegisterPropertyHelper(@TRTLVertexesCount_R, nil, 'Count');

  rside.RegisterPropertyHelper(@TRTLSideTextureOffset_R, @TRTLSideTextureOffset_W, 'TextureOffset');
  rside.RegisterPropertyHelper(@TRTLSideTopTextureOffset_R, @TRTLSideTopTextureOffset_W, 'TopTextureOffset');
  rside.RegisterPropertyHelper(@TRTLSideBottomTextureOffset_R, @TRTLSideBottomTextureOffset_W, 'BottomTextureOffset');
  rside.RegisterPropertyHelper(@TRTLSideMidTextureOffset_R, @TRTLSideMidTextureOffset_W, 'MidTextureOffset');
  rside.RegisterPropertyHelper(@TRTLSideRowOffset_R, @TRTLSideRowOffset_W, 'RowOffset');
  rside.RegisterPropertyHelper(@TRTLSideTopRowOffset_R, @TRTLSideTopRowOffset_W, 'TopRowOffset');
  rside.RegisterPropertyHelper(@TRTLSideBottomRowOffset_R, @TRTLSideBottomRowOffset_W, 'BottomRowOffset');
  rside.RegisterPropertyHelper(@TRTLSideMidRowOffset_R, @TRTLSideMidRowOffset_W, 'MidRowOffset');
  rside.RegisterPropertyHelper(@TRTLSideTopTexture_R, @TRTLSideTopTexture_W, 'TopTexture');
  rside.RegisterPropertyHelper(@TRTLSideBottomTexture_R, @TRTLSideBottomTexture_W, 'BottomTexture');
  rside.RegisterPropertyHelper(@TRTLSideMiddleTexture_R, @TRTLSideMiddleTexture_W, 'MiddleTexture');
  rside.RegisterPropertyHelper(@TRTLSideSector_R, nil, 'Sector');
  rside.RegisterPropertyHelper(@TRTLSideID_R, nil, 'ID');

  rsides.RegisterPropertyHelper(@TRTLSidesSides_R, nil, 'Side');
  rsides.RegisterPropertyHelper(@TRTLSidesCount_R, nil, 'Count');

  rline.RegisterPropertyHelper(@TRTLLineVertex1_R, nil, 'Vertex1');
  rline.RegisterPropertyHelper(@TRTLLineVertex2_R, nil, 'Vertex2');
  rline.RegisterPropertyHelper(@TRTLLineDX_R, nil, 'DX');
  rline.RegisterPropertyHelper(@TRTLLineDY_R, nil, 'DY');
  rline.RegisterPropertyHelper(@TRTLLineSpecial_R, @TRTLLineSpecial_W, 'Special');
  rline.RegisterPropertyHelper(@TRTLLineArg1_R, @TRTLLineArg1_W, 'Arg1');
  rline.RegisterPropertyHelper(@TRTLLineArg2_R, @TRTLLineArg2_W, 'Arg2');
  rline.RegisterPropertyHelper(@TRTLLineArg3_R, @TRTLLineArg3_W, 'Arg3');
  rline.RegisterPropertyHelper(@TRTLLineArg4_R, @TRTLLineArg4_W, 'Arg4');
  rline.RegisterPropertyHelper(@TRTLLineArg5_R, @TRTLLineArg5_W, 'Arg5');
  {$IFNDEF HEXEN}
  rline.RegisterPropertyHelper(@TRTLLineTag_R, @TRTLLineTag_W, 'Tag');
  rline.RegisterPropertyHelper(@TRTLLineTransparent_R, @TRTLLineTransparent_W, 'Transparent');
  {$ENDIF}
  rline.RegisterPropertyHelper(@TRTLLineIsBlocking_R, @TRTLLineIsBlocking_W, 'IsBlocking');
  rline.RegisterPropertyHelper(@TRTLLineIsBlockingMonsters_R, @TRTLLineIsBlockingMonsters_W, 'IsBlockingMonsters');
  rline.RegisterPropertyHelper(@TRTLLineTriggerScripts_R, @TRTLLineTriggerScripts_W, 'TriggerScripts');
  rline.RegisterPropertyHelper(@TRTLLineFrontSide_R, nil, 'FrontSide');
  rline.RegisterPropertyHelper(@TRTLLineBackSide_R, nil, 'BackSide');
  rline.RegisterPropertyHelper(@TRTLLineFrontSector_R, nil, 'FrontSector');
  rline.RegisterPropertyHelper(@TRTLLineBackSector_R, nil, 'BackSector');
  rline.RegisterPropertyHelper(@TRTLLineID_R, nil, 'ID');

  rlines.RegisterPropertyHelper(@TRTLLinesLine_R, nil, 'Line');
  rlines.RegisterPropertyHelper(@TRTLLinesCount_R, nil, 'Count');

  rsector.RegisterPropertyHelper(@TRTLSectorFloorHeight_R, @TRTLSectorFloorHeight_W, 'FloorHeight');
  rsector.RegisterPropertyHelper(@TRTLSectorCeilingHeight_R, @TRTLSectorCeilingHeight_W, 'CeilingHeight');
  rsector.RegisterPropertyHelper(@TRTLSectorFloorPicture_R, @TRTLSectorFloorPicture_W, 'FloorPicture');
  rsector.RegisterPropertyHelper(@TRTLSectorCeilingPicture_R, @TRTLSectorCeilingPicture_W, 'CeilingPicture');
  rsector.RegisterPropertyHelper(@TRTLSectorLightLevel_R, @TRTLSectorLightLevel_W, 'LightLevel');
  rsector.RegisterPropertyHelper(@TRTLSectorSpecial_R, nil, 'Special');
  rsector.RegisterPropertyHelper(@TRTLSectorTag_R, @TRTLSectorTag_W, 'Tag');
  rsector.RegisterPropertyHelper(@TRTLSectorActors_R, nil, 'Actors');
  rsector.RegisterPropertyHelper(@TRTLSectorNumActors_R, nil, 'NumActors');
  rsector.RegisterPropertyHelper(@TRTLSectorLines_R, nil, 'Lines');
  rsector.RegisterPropertyHelper(@TRTLSectorNumLines_R, nil, 'NumLines');
  {$IFDEF DOOM_OR_STRIFE}
  rsector.RegisterPropertyHelper(@TRTLSectorFloorXOffset_R, @TRTLSectorFloorXOffset_W, 'FloorXOffset');
  rsector.RegisterPropertyHelper(@TRTLSectorFloorYOffset_R, @TRTLSectorFloorYOffset_W, 'FloorYOffset');
  rsector.RegisterPropertyHelper(@TRTLSectorCeilingXOffset_R, @TRTLSectorCeilingXOffset_W, 'CeilingXOffset');
  rsector.RegisterPropertyHelper(@TRTLSectorCeilingYOffset_R, @TRTLSectorCeilingYOffset_W, 'CeilingYOffset');
  {$ENDIF}
  rsector.RegisterPropertyHelper(@TRTLSectorMidSector_R, nil, 'MidSector');
  rsector.RegisterPropertyHelper(@TRTLSectorSlopeSector_R, nil, 'SlopeSector');
  rsector.RegisterPropertyHelper(@TRTLSectorID_R, nil, 'ID');
  rsector.RegisterPropertyHelper(@TRTLSectorFloorAngle_R, @TRTLSectorFloorAngle_W, 'FloorAngle');
  rsector.RegisterPropertyHelper(@TRTLSectorFloorAngleX_R, @TRTLSectorFloorAngleX_W, 'FloorAngleX');
  rsector.RegisterPropertyHelper(@TRTLSectorFloorAngleY_R, @TRTLSectorFloorAngleY_W, 'FloorAngleY');
  rsector.RegisterPropertyHelper(@TRTLSectorCeilingAngle_R, @TRTLSectorCeilingAngle_W, 'CeilingAngle');
  rsector.RegisterPropertyHelper(@TRTLSectorCeilingAngleX_R, @TRTLSectorCeilingAngleX_W, 'CeilingAngleX');
  rsector.RegisterPropertyHelper(@TRTLSectorCeilingAngleY_R, @TRTLSectorCeilingAngleY_W, 'CeilingAngleY');
  rsector.RegisterPropertyHelper(@TRTLSectorRippleFloor_R, @TRTLSectorRippleFloor_W, 'RippleFloor');
  rsector.RegisterPropertyHelper(@TRTLSectorRippleCeiling_R, @TRTLSectorRippleCeiling_W, 'RippleCeiling');
  rsector.RegisterPropertyHelper(@TRTLSectorInterpolate_R, @TRTLSectorInterpolate_W, 'Interpolate');
  rsector.RegisterPropertyHelper(@TRTLSectorFog_R, @TRTLSectorFog_W, 'Fog');
  rsector.RegisterPropertyHelper(@TRTLSectorGravity_R, @TRTLSectorGravity_W, 'Gravity');
  rsector.RegisterPropertyHelper(@TRTLSectorWindThrust_R, @TRTLSectorWindThrust_W, 'WindThrust');
  rsector.RegisterPropertyHelper(@TRTLSectorWindAngle_R, @TRTLSectorWindAngle_W, 'WindAngle');
  rsector.RegisterMethod(@TRTLSector.PlaySound, 'PlaySound');
  rsector.RegisterMethod(@TRTLSector.MoveZ, 'MoveZ');
  rsector.RegisterMethod(@TRTLSector.SetFloorSlope, 'SetFloorSlope');
  rsector.RegisterMethod(@TRTLSector.SetCeilingSlope, 'SetCeilingSlope');

  rsectors.RegisterPropertyHelper(@TRTLSectorsSector_R, nil, 'Sector');
  rsectors.RegisterPropertyHelper(@TRTLSectorsCount_R, nil, 'Count');

  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemName_R, nil, 'Name');
  {$IFDEF STRIFE}
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemName2_R, nil, 'Name2');
  {$ENDIF}
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemInheritsFrom_R, nil, 'InheritsFrom');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemDoomEdNum_R, nil, 'DoomEdNum');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSpawnState_R, nil, 'SpawnState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSpawnHealth_R, nil, 'SpawnHealth');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSeeState_R, nil, 'SeeState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSeeSound_R, nil, 'SeeSound');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemReactionTime_R, nil, 'ReactionTime');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemAttackSound_R, nil, 'AttackSound');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemPainState_R, nil, 'PainState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemPainChance_R, nil, 'PainChance');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemPainSound_R, nil, 'PainSound');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMeleeState_R, nil, 'MeleeState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMissileState_R, nil, 'MissileState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemDeathState_R, nil, 'DeathState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemXdeathState_R, nil, 'XdeathState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemDeathSound_R, nil, 'DeathSound');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSpeed_R, nil, 'Speed');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemVSpeed_R, nil, 'VSpeed');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMinMissileChance_R, nil, 'MinMissileChance');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemPushFactor_R, nil, 'PushFactor');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemScale_R, nil, 'Scale');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemGravity_R, nil, 'Gravity');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemRadius_R, nil, 'Radius');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemHeight_R, nil, 'Height');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMass_R, nil, 'Mass');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemDamage_R, nil, 'Damage');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemActiveSound_R, nil, 'ActiveSound');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemFlag_R, nil, 'Flag');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemRaiseState_R, nil, 'RaiseState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemCustomSound1_R, nil, 'CustomSound1');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemCustomSound2_R, nil, 'CustomSound2');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemCustomSound3_R, nil, 'CustomSound3');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMeleeSound_R, nil, 'MeleeSound');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemDropItem_R, nil, 'DropItem');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMissileType_R, nil, 'MissileType');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemExplosionDamage_R, nil, 'ExplosionDamage');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemExplosionRadius_R, nil, 'ExplosionRadius');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMeleeDamage_R, nil, 'MeleeDamage');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemRenderStyle_R, nil, 'RenderStyle');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemAlpha_R, nil, 'Alpha');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemHealState_R, nil, 'HealState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemCrashState_R, nil, 'CrashState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemCrushState_R, nil, 'CrushState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemFloatSpeed_R, nil, 'FloatSpeed');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemNormalSpeed_R, nil, 'NormalSpeed');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemFastSpeed_R, nil, 'FastSpeed');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemObituary_R, nil, 'Obituary');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemHitObituary_R, nil, 'HitObituary');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemGender_R, nil, 'Gender');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMeleeRange_R, nil, 'MeleeRange');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMaxStepHeight_R, nil, 'MaxStepHeight');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMaxDropOffHeight_R, nil, 'MaxDropOffHeight');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemGibHealth_R, nil, 'GibHealth');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMaxTargetRange_R, nil, 'MaxTargetRange');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemWeaveIndexXY_R, nil, 'WeaveIndexXY');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemWeaveIndexZ_R, nil, 'WeaveIndexZ');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemFriction_R, nil, 'Friction');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSpriteDX_R, nil, 'SpriteDX');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSpriteDY_R, nil, 'SpriteDY');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemInfightingGroup_R, nil, 'InfightingGroup');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemProjectileGroup_R, nil, 'ProjectileGroup');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemSplashGroup_R, nil, 'SplashGroup');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemRipSound_R, nil, 'RipSound');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemInteractState_R, nil, 'InteractState');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMissileHeight_R, nil, 'MissileHeight');
  rmobjinfoitem.RegisterPropertyHelper(@TRTLMobjInfoItemMeleeThreshold_R, nil, 'MeleeThreshold');

  rmobjinfo.RegisterPropertyHelper(@TRTLMobjInfoItem_R, nil, 'Item');
  rmobjinfo.RegisterPropertyHelper(@TRTLMobjInfoCount_R, nil, 'Count');

end;

//==============================================================================
//
// RIRegisterRTL_Game
//
//==============================================================================
procedure RIRegisterRTL_Game(Exec: TPSExec);
begin
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('Actors')), rtlactors);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('Vertexes')), rtlvertexes);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('Sides')), rtlsides);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('Lines')), rtllines);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('Sectors')), rtlsectors);
  SetVariantToClass(Exec.GetVarNo(Exec.GetVar('MobjInfo')), rtlmobjinfo);
end;

//==============================================================================
//
// PS_InitGameImport
//
//==============================================================================
procedure PS_InitGameImport;
begin
  rtlactors := TRTLActors.Create;
  rtlvertexes := TRTLVertexes.Create;
  rtlsides := TRTLSides.Create;
  rtllines := TRTLLines.Create;
  rtlsectors := TRTLSectors.Create;
  rtlmobjinfo := TRTLMobjInfo.Create;
end;

//==============================================================================
//
// PS_ShutDownGameImport
//
//==============================================================================
procedure PS_ShutDownGameImport;
begin
  rtlactors.Free;
  rtlvertexes.Free;
  rtlsides.Free;
  rtllines.Free;
  rtlsectors.Free;
  rtlmobjinfo.Free;
end;

end.

