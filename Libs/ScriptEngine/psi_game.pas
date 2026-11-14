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
  DelphiDoom.ScriptHost.Classes.Intf,
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
// PS_DescribeGameClasses
// The classes of the scripts of the game (Actors, Lines, Sectors...) for the
// compiler and the interpreter
//
//==============================================================================
procedure PS_DescribeGameClasses(const ACatalog: IScriptClassCatalog);

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
  w_wad,
  DelphiDoom.ScriptHost.Types;

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


//==============================================================================
//
// TRTLActorName2_R
//
//==============================================================================
procedure TRTLActorName2_R(Self: TRTLActor; var T: string);
begin
  T := PS_Actors.GetText(LongWord(Self), actName2);
end;

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


//==============================================================================
//
// TRTLMobjInfoItemName2_R
//
//==============================================================================
procedure TRTLMobjInfoItemName2_R(Self: TRTLMobjInfoItem; var T: string);
begin
  T := PS_MobjInfo.GetText(mifName, Integer(Self) - 1);
end;

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
// PS_DescribeGameClasses
//
// The classes of the scripts of the game (Actors, Lines...): one table for the
// compiler and the interpreter
//
//==============================================================================
procedure PS_DescribeGameClasses(const ACatalog: IScriptClassCatalog);
var
  cactor: IScriptClassDescriptor;
  cactors: IScriptClassDescriptor;
  cvertex: IScriptClassDescriptor;
  cvertexes: IScriptClassDescriptor;
  cside: IScriptClassDescriptor;
  csides: IScriptClassDescriptor;
  cline: IScriptClassDescriptor;
  clines: IScriptClassDescriptor;
  csector: IScriptClassDescriptor;
  csectors: IScriptClassDescriptor;
  cmobjinfoitem: IScriptClassDescriptor;
  cmobjinfo: IScriptClassDescriptor;
begin
  cactor := ACatalog.AddClass('!TActor', TRTLActor);
  cactors := ACatalog.AddClass('!TActors', TRTLActors);
  cvertex := ACatalog.AddClass('!TVertex', TRTLVertex);
  cvertexes := ACatalog.AddClass('!TVertexes', TRTLVertexes);
  cside := ACatalog.AddClass('!TSide', TRTLSide);
  csides := ACatalog.AddClass('!TSides', TRTLSides);
  cline := ACatalog.AddClass('!TLine', TRTLLine);
  clines := ACatalog.AddClass('!TLines', TRTLLines);
  csector := ACatalog.AddClass('!TSector', TRTLLine);
  csectors := ACatalog.AddClass('!TSectors', TRTLLines);
  cmobjinfoitem := ACatalog.AddClass('!TMobjInfoItem', TRTLMobjInfoItem);
  cmobjinfo := ACatalog.AddClass('!TMobjInfo', TRTLMobjInfo);

  cactor.AddProperty('key', 'LongWord', iptR, @TRTLActorkey_R, nil);
  cactor.AddProperty('Target', '!TActor', iptRW, @TRTLActorTarget_R, @TRTLActorTarget_W);
  cactor.AddProperty('Tracer', '!TActor', iptRW, @TRTLActorTracer_R, @TRTLActorTracer_W);
  cactor.AddProperty('Master', '!TActor', iptRW, @TRTLActorMaster_R, @TRTLActorMaster_W);
  cactor.AddProperty('X', 'fixed_t', iptRW, @TRTLActorX_R, @TRTLActorX_W);
  cactor.AddProperty('Y', 'fixed_t', iptRW, @TRTLActorY_R, @TRTLActorY_W);
  cactor.AddProperty('Z', 'fixed_t', iptRW, @TRTLActorZ_R, @TRTLActorZ_W);
  cactor.AddProperty('MOMX', 'fixed_t', iptRW, @TRTLActorMOMX_R, @TRTLActorMOMX_W);
  cactor.AddProperty('MOMY', 'fixed_t', iptRW, @TRTLActorMOMY_R, @TRTLActorMOMY_W);
  cactor.AddProperty('MOMZ', 'fixed_t', iptRW, @TRTLActorMOMZ_R, @TRTLActorMOMZ_W);
  cactor.AddProperty('FloorZ', 'fixed_t', iptRW, @TRTLActorFloorZ_R, @TRTLActorFloorZ_W);
  cactor.AddProperty('CeilingZ', 'fixed_t', iptRW, @TRTLActorCeilingZ_R, @TRTLActorCeilingZ_W);
  cactor.AddProperty('Speed', 'fixed_t', iptRW, @TRTLActorSpeed_R, @TRTLActorSpeed_W);
  cactor.AddProperty('Angle', 'angle_t', iptRW, @TRTLActorAngle_R, @TRTLActorAngle_W);
  cactor.AddProperty('Sector', '!TSector', iptR, @TRTLActorSector_R, nil);
  cactor.AddProperty('Health', 'Integer', iptRW, @TRTLActorHealth_R, @TRTLActorHealth_W);
  cactor.AddProperty('SpawnHealth', 'Integer', iptR, @TRTLActorSpawnHealth_R, nil);
  cactor.AddProperty('Mass', 'Integer', iptRW, @TRTLActorMass_R, @TRTLActorMass_W);
  cactor.AddProperty('Gravity', 'fixed_t', iptRW, @TRTLActorGravity_R, @TRTLActorGravity_W);
  cactor.AddProperty('Special', 'Integer', iptRW, @TRTLActorSpecial_R, @TRTLActorSpecial_W);
  cactor.AddProperty('Arg1', 'Integer', iptRW, @TRTLActorArg1_R, @TRTLActorArg1_W);
  cactor.AddProperty('Arg2', 'Integer', iptRW, @TRTLActorArg2_R, @TRTLActorArg2_W);
  cactor.AddProperty('Arg3', 'Integer', iptRW, @TRTLActorArg3_R, @TRTLActorArg3_W);
  cactor.AddProperty('Arg4', 'Integer', iptRW, @TRTLActorArg4_R, @TRTLActorArg4_W);
  cactor.AddProperty('Arg5', 'Integer', iptRW, @TRTLActorArg5_R, @TRTLActorArg5_W);
  cactor.AddProperty('Height', 'fixed_t', iptRW, @TRTLActorHeight_R, @TRTLActorHeight_W);
  cactor.AddProperty('WeaveIndexXY', 'Integer', iptRW, @TRTLActorWeaveIndexXY_R, @TRTLActorWeaveIndexXY_W);
  cactor.AddProperty('WeaveIndexZ', 'Integer', iptRW, @TRTLActorWeaveIndexZ_R, @TRTLActorWeaveIndexZ_W);
  cactor.AddProperty('Friction', 'fixed_t', iptRW, @TRTLActorFriction_R, @TRTLActorFriction_W);
  cactor.AddProperty('PainChance', 'fixed_t', iptRW, @TRTLActorPainChance_R, @TRTLActorPainChance_W);
  cactor.AddProperty('SpriteDX', 'fixed_t', iptRW, @TRTLActorSpriteDX_R, @TRTLActorSpriteDX_W);
  cactor.AddProperty('SpriteDY', 'fixed_t', iptRW, @TRTLActorSpriteDY_R, @TRTLActorSpriteDY_W);
  cactor.AddProperty('InfightingGroup', 'Integer', iptRW, @TRTLActorInfightingGroup_R, @TRTLActorInfightingGroup_W);
  cactor.AddProperty('ProjectileGroup', 'Integer', iptRW, @TRTLActorProjectileGroup_R, @TRTLActorProjectileGroup_W);
  cactor.AddProperty('SplashGroup', 'Integer', iptRW, @TRTLActorSplashGroup_R, @TRTLActorSplashGroup_W);
  cactor.AddProperty('Translation', 'string', iptRW, @TRTLActorTranslation_R, @TRTLActorTranslation_W);
  cactor.AddProperty('BloodColor', 'string', iptRW, @TRTLActorBloodColor_R, @TRTLActorBloodColor_W);
  cactor.AddProperty('CustomDropItem', 'Integer', iptRW, @TRTLActorCustomDropItem_R, @TRTLActorCustomDropItem_W);
  cactor.AddProperty('CustomParams', 'Integer String', iptRW, @TRTLActorCustomParams_R, @TRTLActorCustomParams_W);
  cactor.AddProperty('Flag', 'Boolean LongWord', iptRW, @TRTLActorFlags_R, @TRTLActorFlags_W);
  cactor.AddProperty('Name', 'String', iptR, @TRTLActorName_R, nil);
  cactor.AddProperty('Name2', 'String', iptR, @TRTLActorName2_R, nil, [sgStrife]);
  cactor.AddProperty('Player', 'Integer', iptR, @TRTLActorPlayer_R, nil);
  cactor.AddProperty('MobjType', 'Integer', iptR, @TRTLActorMobjType_R, nil);
  cactor.AddProperty('EditorNumber', 'Integer', iptR, @TRTLActorEditorNumber_R, nil);
  cactor.AddProperty('SeeSound', 'string', iptR, @TRTLActorSeeSound_R, nil);
  cactor.AddProperty('AttackSound', 'string', iptR, @TRTLActorAttackSound_R, nil);
  cactor.AddProperty('PainSound', 'string', iptR, @TRTLActorPainSound_R, nil);
  cactor.AddProperty('DeathSound', 'string', iptR, @TRTLActorDeathSound_R, nil);
  cactor.AddProperty('ActiveSound', 'string', iptR, @TRTLActorActiveSound_R, nil);
  cactor.AddProperty('CustomSound1', 'string', iptR, @TRTLActorCustomSound1_R, nil);
  cactor.AddProperty('CustomSound2', 'string', iptR, @TRTLActorCustomSound2_R, nil);
  cactor.AddProperty('CustomSound3', 'string', iptR, @TRTLActorCustomSound3_R, nil);
  cactor.AddProperty('MeleeSound', 'string', iptR, @TRTLActorMeleeSound_R, nil);
  cactor.AddProperty('RipSound', 'string', iptR, @TRTLActorRipSound_R, nil);
  cactor.AddProperty('State', 'Integer', iptRW, @TRTLActorState_R, @TRTLActorState_W);
  cactor.AddMethod('procedure PlaySound(const snd: string);', 'PlaySound', @TRTLActor.PlaySound);
  cactor.AddMethod('procedure Remove;', 'Remove', @TRTLActor.Remove);
  cactor.AddMethod('procedure SetPosition(const x, y, z: fixed_t)', 'SetPosition', @TRTLActor.SetPosition);
  cactor.AddRuntimeProperty('PushFactor', @TRTLActorPushFactor_R, @TRTLActorPushFactor_W);
  cactor.AddRuntimeProperty('Scale', @TRTLActorScale_R, @TRTLActorScale_W);

  cactors.AddMethod('function AllActors: TActorArray;', 'AllActors', @TRTLActors.AllActors);
  cactors.AddMethod('function AllMonstersAlive: TActorArray;', 'AllMonstersAlive', @TRTLActors.AllMonstersAlive);
  cactors.AddMethod('function AllMonstersDead: TActorArray;', 'AllMonstersDead', @TRTLActors.AllMonstersDead);
  cactors.AddMethod('function AllMonsters: TActorArray;', 'AllMonsters', @TRTLActors.AllMonsters);
  cactors.AddMethod('function AllMissiles: TActorArray;', 'AllMissiles', @TRTLActors.AllMissiles);
  cactors.AddMethod('function AllAtSector(const sec: Integer): TActorArray;', 'AllAtSector', @TRTLActors.AllAtSector);
  cactors.AddMethod('function AllAtSectorTag(const tag: Integer): TActorArray;', 'AllAtSectorTag', @TRTLActors.AllAtSectorTag);
  cactors.AddMethod('function AllEditorNumber(const dn: Integer): TActorArray;', 'AllEditorNumber', @TRTLActors.AllEditorNumber);
  cactors.AddMethod('function AllType(const typ: Integer): TActorArray;', 'AllType', @TRTLActors.AllType);
  cactors.AddProperty('Actor', '!TActor LongWord', iptR, @TRTLActorsActor_R, nil);
  cactors.AddDefaultProperty('Actor');

  cvertex.AddProperty('X', 'Integer', iptR, @TRTLVertexX_R, nil);
  cvertex.AddProperty('Y', 'Integer', iptR, @TRTLVertexY_R, nil);
  cvertex.AddProperty('ID', 'Integer', iptR, @TRTLVertexID_R, nil);

  cvertexes.AddProperty('Vertex', '!TVertex Integer', iptR, @TRTLVertexesVertex_R, nil);
  cvertexes.AddDefaultProperty('Vertex');
  cvertexes.AddProperty('Count', 'Integer', iptR, @TRTLVertexesCount_R, nil);

  cside.AddProperty('TextureOffset', 'fixed_t', iptRW, @TRTLSideTextureOffset_R, @TRTLSideTextureOffset_W);
  cside.AddProperty('TopTextureOffset', 'fixed_t', iptRW, @TRTLSideTopTextureOffset_R, @TRTLSideTopTextureOffset_W);
  cside.AddProperty('BottomTextureOffset', 'fixed_t', iptRW, @TRTLSideBottomTextureOffset_R, @TRTLSideBottomTextureOffset_W);
  cside.AddProperty('MidTextureOffset', 'fixed_t', iptRW, @TRTLSideMidTextureOffset_R, @TRTLSideMidTextureOffset_W);
  cside.AddProperty('RowOffset', 'fixed_t', iptRW, @TRTLSideRowOffset_R, @TRTLSideRowOffset_W);
  cside.AddProperty('TopRowOffset', 'fixed_t', iptRW, @TRTLSideTopRowOffset_R, @TRTLSideTopRowOffset_W);
  cside.AddProperty('BottomRowOffset', 'fixed_t', iptRW, @TRTLSideBottomRowOffset_R, @TRTLSideBottomRowOffset_W);
  cside.AddProperty('MidRowOffset', 'fixed_t', iptRW, @TRTLSideMidRowOffset_R, @TRTLSideMidRowOffset_W);
  cside.AddProperty('TopTexture', 'string', iptRW, @TRTLSideTopTexture_R, @TRTLSideTopTexture_W);
  cside.AddProperty('BottomTexture', 'string', iptRW, @TRTLSideBottomTexture_R, @TRTLSideBottomTexture_W);
  cside.AddProperty('MiddleTexture', 'string', iptRW, @TRTLSideMiddleTexture_R, @TRTLSideMiddleTexture_W);
  cside.AddProperty('Sector', '!TSector', iptR, @TRTLSideSector_R, nil);
  cside.AddProperty('ID', 'Integer', iptR, @TRTLSideID_R, nil);

  csides.AddProperty('Side', '!TSide Integer', iptR, @TRTLSidesSides_R, nil);
  csides.AddDefaultProperty('Side');
  csides.AddProperty('Count', 'Integer', iptR, @TRTLSidesCount_R, nil);

  cline.AddProperty('Vertex1', '!TVertex', iptR, @TRTLLineVertex1_R, nil);
  cline.AddProperty('Vertex2', '!TVertex', iptR, @TRTLLineVertex2_R, nil);
  cline.AddProperty('DX', 'fixed_t', iptR, @TRTLLineDX_R, nil);
  cline.AddProperty('DY', 'fixed_t', iptR, @TRTLLineDY_R, nil);
  cline.AddProperty('Special', 'Integer', iptRW, @TRTLLineSpecial_R, @TRTLLineSpecial_W);
  cline.AddProperty('Arg1', 'byte', iptRW, @TRTLLineArg1_R, @TRTLLineArg1_W);
  cline.AddProperty('Arg2', 'byte', iptRW, @TRTLLineArg2_R, @TRTLLineArg2_W);
  cline.AddProperty('Arg3', 'byte', iptRW, @TRTLLineArg3_R, @TRTLLineArg3_W);
  cline.AddProperty('Arg4', 'byte', iptRW, @TRTLLineArg4_R, @TRTLLineArg4_W);
  cline.AddProperty('Arg5', 'byte', iptRW, @TRTLLineArg5_R, @TRTLLineArg5_W);
  cline.AddProperty('Tag', 'Integer', iptRW, @TRTLLineTag_R, @TRTLLineTag_W, [sgDoom, sgHeretic, sgStrife]);
  cline.AddProperty('Transparent', 'Boolean', iptRW, @TRTLLineTransparent_R, @TRTLLineTransparent_W, [sgDoom, sgHeretic, sgStrife]);
  cline.AddProperty('IsBlocking', 'Boolean', iptRW, @TRTLLineIsBlocking_R, @TRTLLineIsBlocking_W);
  cline.AddProperty('IsBlockingMonsters', 'Boolean', iptRW, @TRTLLineIsBlockingMonsters_R, @TRTLLineIsBlockingMonsters_W);
  cline.AddProperty('TriggerScripts', 'Boolean', iptRW, @TRTLLineTriggerScripts_R, @TRTLLineTriggerScripts_W);
  cline.AddProperty('FrontSide', '!TSide', iptR, @TRTLLineFrontSide_R, nil);
  cline.AddProperty('BackSide', '!TSide', iptR, @TRTLLineBackSide_R, nil);
  cline.AddProperty('FrontSector', '!TSector', iptR, @TRTLLineFrontSector_R, nil);
  cline.AddProperty('BackSector', '!TSector', iptR, @TRTLLineBackSector_R, nil);
  cline.AddProperty('ID', 'Integer', iptR, @TRTLLineID_R, nil);

  clines.AddProperty('Line', '!TLine Integer', iptR, @TRTLLinesLine_R, nil);
  clines.AddDefaultProperty('Line');
  clines.AddProperty('Count', 'Integer', iptR, @TRTLLinesCount_R, nil);

  csector.AddProperty('FloorHeight', 'fixed_t', iptRW, @TRTLSectorFloorHeight_R, @TRTLSectorFloorHeight_W);
  csector.AddProperty('CeilingHeight', 'fixed_t', iptRW, @TRTLSectorCeilingHeight_R, @TRTLSectorCeilingHeight_W);
  csector.AddProperty('FloorPicture', 'string', iptRW, @TRTLSectorFloorPicture_R, @TRTLSectorFloorPicture_W);
  csector.AddProperty('CeilingPicture', 'string', iptRW, @TRTLSectorCeilingPicture_R, @TRTLSectorCeilingPicture_W);
  csector.AddProperty('LightLevel', 'Integer', iptRW, @TRTLSectorLightLevel_R, @TRTLSectorLightLevel_W);
  csector.AddProperty('Special', 'Integer', iptR, @TRTLSectorSpecial_R, nil);
  csector.AddProperty('Tag', 'Integer', iptRW, @TRTLSectorTag_R, @TRTLSectorTag_W);
  csector.AddProperty('Actors', 'TActorArray', iptR, @TRTLSectorActors_R, nil);
  csector.AddProperty('NumActors', 'Integer', iptR, @TRTLSectorNumActors_R, nil);
  csector.AddProperty('Lines', 'TIntegerArray', iptR, @TRTLSectorLines_R, nil);
  csector.AddProperty('NumLines', 'Integer', iptR, @TRTLSectorNumLines_R, nil);
  csector.AddProperty('FloorXOffset', 'fixed_t', iptRW, @TRTLSectorFloorXOffset_R, @TRTLSectorFloorXOffset_W, [sgDoom, sgStrife]);
  csector.AddProperty('FloorYOffset', 'fixed_t', iptRW, @TRTLSectorFloorYOffset_R, @TRTLSectorFloorYOffset_W, [sgDoom, sgStrife]);
  csector.AddProperty('CeilingXOffset', 'fixed_t', iptRW, @TRTLSectorCeilingXOffset_R, @TRTLSectorCeilingXOffset_W, [sgDoom, sgStrife]);
  csector.AddProperty('CeilingYOffset', 'fixed_t', iptRW, @TRTLSectorCeilingYOffset_R, @TRTLSectorCeilingYOffset_W, [sgDoom, sgStrife]);
  csector.AddProperty('MidSector', '!TSector', iptR, @TRTLSectorMidSector_R, nil);
  csector.AddProperty('SlopeSector', '!TSector', iptR, @TRTLSectorSlopeSector_R, nil);
  csector.AddProperty('ID', 'Integer', iptR, @TRTLSectorID_R, nil);
  csector.AddProperty('FloorAngle', 'angle_t', iptRW, @TRTLSectorFloorAngle_R, @TRTLSectorFloorAngle_W);
  csector.AddProperty('FloorAngleX', 'fixed_t', iptRW, @TRTLSectorFloorAngleX_R, @TRTLSectorFloorAngleX_W);
  csector.AddProperty('FloorAngleY', 'fixed_t', iptRW, @TRTLSectorFloorAngleY_R, @TRTLSectorFloorAngleY_W);
  csector.AddProperty('CeilingAngle', 'angle_t', iptRW, @TRTLSectorCeilingAngle_R, @TRTLSectorCeilingAngle_W);
  csector.AddProperty('CeilingAngleX', 'fixed_t', iptRW, @TRTLSectorCeilingAngleX_R, @TRTLSectorCeilingAngleX_W);
  csector.AddProperty('CeilingAngleY', 'fixed_t', iptRW, @TRTLSectorCeilingAngleY_R, @TRTLSectorCeilingAngleY_W);
  csector.AddProperty('RippleFloor', 'boolean', iptRW, @TRTLSectorRippleFloor_R, @TRTLSectorRippleFloor_W);
  csector.AddProperty('RippleCeiling', 'boolean', iptRW, @TRTLSectorRippleCeiling_R, @TRTLSectorRippleCeiling_W);
  csector.AddProperty('Interpolate', 'boolean', iptRW, @TRTLSectorInterpolate_R, @TRTLSectorInterpolate_W);
  csector.AddProperty('Fog', 'boolean', iptRW, @TRTLSectorFog_R, @TRTLSectorFog_W);
  csector.AddProperty('Gravity', 'fixed_t', iptRW, @TRTLSectorGravity_R, @TRTLSectorGravity_W);
  csector.AddProperty('WindThrust', 'fixed_t', iptRW, @TRTLSectorWindThrust_R, @TRTLSectorWindThrust_W);
  csector.AddProperty('WindAngle', 'angle_t', iptRW, @TRTLSectorWindAngle_R, @TRTLSectorWindAngle_W);
  csector.AddMethod('procedure PlaySound(const snd: string);', 'PlaySound', @TRTLSector.PlaySound);
  csector.AddMethod('procedure MoveZ(const dz: fixed_t);', 'MoveZ', @TRTLSector.MoveZ);
  csector.AddMethod('procedure SetFloorSlope(const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);', 'SetFloorSlope', @TRTLSector.SetFloorSlope);
  csector.AddMethod('procedure SetCeilingSlope(const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);', 'SetCeilingSlope', @TRTLSector.SetCeilingSlope);

  csectors.AddProperty('Sector', '!TSector Integer', iptR, @TRTLSectorsSector_R, nil);
  csectors.AddDefaultProperty('Sector');
  csectors.AddProperty('Count', 'Integer', iptR, @TRTLSectorsCount_R, nil);

  cmobjinfoitem.AddProperty('Name', 'string', iptR, @TRTLMobjInfoItemName_R, nil);
  cmobjinfoitem.AddProperty('Name2', 'string', iptR, @TRTLMobjInfoItemName2_R, nil,
    SCRIPT_ALL_GAMES, [sgStrife]);
  cmobjinfoitem.AddProperty('InheritsFrom', 'Integer', iptR, @TRTLMobjInfoItemInheritsFrom_R, nil);
  cmobjinfoitem.AddProperty('DoomEdNum', 'Integer', iptR, @TRTLMobjInfoItemDoomEdNum_R, nil);
  cmobjinfoitem.AddProperty('SpawnState', 'Integer', iptR, @TRTLMobjInfoItemSpawnState_R, nil);
  cmobjinfoitem.AddProperty('SpawnHealth', 'Integer', iptR, @TRTLMobjInfoItemSpawnHealth_R, nil);
  cmobjinfoitem.AddProperty('SeeState', 'Integer', iptR, @TRTLMobjInfoItemSeeState_R, nil);
  cmobjinfoitem.AddProperty('SeeSound', 'string', iptR, @TRTLMobjInfoItemSeeSound_R, nil);
  cmobjinfoitem.AddProperty('ReactionTime', 'Integer', iptR, @TRTLMobjInfoItemReactionTime_R, nil);
  cmobjinfoitem.AddProperty('AttackSound', 'string', iptR, @TRTLMobjInfoItemAttackSound_R, nil);
  cmobjinfoitem.AddProperty('PainState', 'Integer', iptR, @TRTLMobjInfoItemPainState_R, nil);
  cmobjinfoitem.AddProperty('PainChance', 'Integer', iptR, @TRTLMobjInfoItemPainChance_R, nil);
  cmobjinfoitem.AddProperty('PainSound', 'string', iptR, @TRTLMobjInfoItemPainSound_R, nil);
  cmobjinfoitem.AddProperty('MeleeState', 'Integer', iptR, @TRTLMobjInfoItemMeleeState_R, nil);
  cmobjinfoitem.AddProperty('MissileState', 'Integer', iptR, @TRTLMobjInfoItemMissileState_R, nil);
  cmobjinfoitem.AddProperty('DeathState', 'Integer', iptR, @TRTLMobjInfoItemDeathState_R, nil);
  cmobjinfoitem.AddProperty('XdeathState', 'Integer', iptR, @TRTLMobjInfoItemXdeathState_R, nil);
  cmobjinfoitem.AddProperty('DeathSound', 'string', iptR, @TRTLMobjInfoItemDeathSound_R, nil);
  cmobjinfoitem.AddProperty('Speed', 'Integer', iptR, @TRTLMobjInfoItemSpeed_R, nil);
  cmobjinfoitem.AddProperty('Radius', 'Integer', iptR, @TRTLMobjInfoItemRadius_R, nil);
  cmobjinfoitem.AddProperty('Height', 'Integer', iptR, @TRTLMobjInfoItemHeight_R, nil);
  cmobjinfoitem.AddProperty('Mass', 'Integer', iptR, @TRTLMobjInfoItemMass_R, nil);
  cmobjinfoitem.AddProperty('Damage', 'Integer', iptR, @TRTLMobjInfoItemDamage_R, nil);
  cmobjinfoitem.AddProperty('ActiveSound', 'string', iptR, @TRTLMobjInfoItemActiveSound_R, nil);
  cmobjinfoitem.AddProperty('Flag', 'Boolean Integer', iptR, @TRTLMobjInfoItemFlag_R, nil);
  cmobjinfoitem.AddProperty('RaiseState', 'Integer', iptR, @TRTLMobjInfoItemRaiseState_R, nil);
  cmobjinfoitem.AddProperty('CustomSound1', 'string', iptR, @TRTLMobjInfoItemCustomSound1_R, nil);
  cmobjinfoitem.AddProperty('CustomSound2', 'string', iptR, @TRTLMobjInfoItemCustomSound2_R, nil);
  cmobjinfoitem.AddProperty('CustomSound3', 'string', iptR, @TRTLMobjInfoItemCustomSound3_R, nil);
  cmobjinfoitem.AddProperty('MeleeSound', 'string', iptR, @TRTLMobjInfoItemMeleeSound_R, nil);
  cmobjinfoitem.AddProperty('DropItem', 'Integer', iptR, @TRTLMobjInfoItemDropItem_R, nil);
  cmobjinfoitem.AddProperty('MissileType', 'Integer', iptR, @TRTLMobjInfoItemMissileType_R, nil);
  cmobjinfoitem.AddProperty('ExplosionDamage', 'Integer', iptR, @TRTLMobjInfoItemExplosionDamage_R, nil);
  cmobjinfoitem.AddProperty('ExplosionRadius', 'Integer', iptR, @TRTLMobjInfoItemExplosionRadius_R, nil);
  cmobjinfoitem.AddProperty('MeleeDamage', 'Integer', iptR, @TRTLMobjInfoItemMeleeDamage_R, nil);
  cmobjinfoitem.AddProperty('RenderStyle', 'Integer', iptR, @TRTLMobjInfoItemRenderStyle_R, nil);
  cmobjinfoitem.AddProperty('Alpha', 'Integer', iptR, @TRTLMobjInfoItemAlpha_R, nil);
  cmobjinfoitem.AddProperty('HealState', 'Integer', iptR, @TRTLMobjInfoItemHealState_R, nil);
  cmobjinfoitem.AddProperty('CrashState', 'Integer', iptR, @TRTLMobjInfoItemCrashState_R, nil);
  cmobjinfoitem.AddProperty('CrushState', 'Integer', iptR, @TRTLMobjInfoItemCrushState_R, nil);
  cmobjinfoitem.AddProperty('InteractState', 'Integer', iptR, @TRTLMobjInfoItemInteractState_R, nil);
  cmobjinfoitem.AddProperty('MissileHeight', 'Integer', iptR, @TRTLMobjInfoItemMissileHeight_R, nil);
  cmobjinfoitem.AddProperty('VSpeed', 'Integer', iptR, @TRTLMobjInfoItemVSpeed_R, nil);
  cmobjinfoitem.AddProperty('MinMissileChance', 'Integer', iptR, @TRTLMobjInfoItemMinMissileChance_R, nil);
  cmobjinfoitem.AddProperty('PushFactor', 'Integer', iptR, @TRTLMobjInfoItemPushFactor_R, nil);
  cmobjinfoitem.AddProperty('Scale', 'Integer', iptR, @TRTLMobjInfoItemScale_R, nil);
  cmobjinfoitem.AddProperty('Gravity', 'Integer', iptR, @TRTLMobjInfoItemGravity_R, nil);
  cmobjinfoitem.AddProperty('FloatSpeed', 'Integer', iptR, @TRTLMobjInfoItemFloatSpeed_R, nil);
  cmobjinfoitem.AddProperty('NormalSpeed', 'Integer', iptR, @TRTLMobjInfoItemNormalSpeed_R, nil);
  cmobjinfoitem.AddProperty('FastSpeed', 'Integer', iptR, @TRTLMobjInfoItemFastSpeed_R, nil);
  cmobjinfoitem.AddProperty('Obituary', 'String', iptR, @TRTLMobjInfoItemObituary_R, nil);
  cmobjinfoitem.AddProperty('HitObituary', 'String', iptR, @TRTLMobjInfoItemHitObituary_R, nil);
  cmobjinfoitem.AddProperty('Gender', 'Integer', iptR, @TRTLMobjInfoItemGender_R, nil);
  cmobjinfoitem.AddProperty('MeleeRange', 'Integer', iptR, @TRTLMobjInfoItemMeleeRange_R, nil);
  cmobjinfoitem.AddProperty('MaxStepHeight', 'Integer', iptR, @TRTLMobjInfoItemMaxStepHeight_R, nil);
  cmobjinfoitem.AddProperty('MaxDropOffHeight', 'Integer', iptR, @TRTLMobjInfoItemMaxDropOffHeight_R, nil);
  cmobjinfoitem.AddProperty('GibHealth', 'Integer', iptR, @TRTLMobjInfoItemGibHealth_R, nil);
  cmobjinfoitem.AddProperty('MaxTargetRange', 'Integer', iptR, @TRTLMobjInfoItemMaxTargetRange_R, nil);
  cmobjinfoitem.AddProperty('WeaveIndexXY', 'Integer', iptR, @TRTLMobjInfoItemWeaveIndexXY_R, nil);
  cmobjinfoitem.AddProperty('WeaveIndexZ', 'Integer', iptR, @TRTLMobjInfoItemWeaveIndexZ_R, nil);
  cmobjinfoitem.AddProperty('Friction', 'Integer', iptR, @TRTLMobjInfoItemFriction_R, nil);
  cmobjinfoitem.AddProperty('SpriteDX', 'Integer', iptR, @TRTLMobjInfoItemSpriteDX_R, nil);
  cmobjinfoitem.AddProperty('SpriteDY', 'Integer', iptR, @TRTLMobjInfoItemSpriteDY_R, nil);
  cmobjinfoitem.AddProperty('InfightingGroup', 'Integer', iptRW, @TRTLMobjInfoItemInfightingGroup_R, nil);
  cmobjinfoitem.AddProperty('ProjectileGroup', 'Integer', iptRW, @TRTLMobjInfoItemProjectileGroup_R, nil);
  cmobjinfoitem.AddProperty('SplashGroup', 'Integer', iptRW, @TRTLMobjInfoItemSplashGroup_R, nil);
  cmobjinfoitem.AddProperty('RipSound', 'string', iptRW, @TRTLMobjInfoItemRipSound_R, nil);
  cmobjinfoitem.AddProperty('MeleeThreshold', 'Integer', iptRW, @TRTLMobjInfoItemMeleeThreshold_R, nil);

  cmobjinfo.AddProperty('Item', '!TMobjInfoItem integer', iptR, @TRTLMobjInfoItem_R, nil);
  cmobjinfo.AddDefaultProperty('Item');
  cmobjinfo.AddProperty('Count', 'Integer', iptR, @TRTLMobjInfoCount_R, nil);

  cactors.AddVariable('Actors',
    function: TObject
    begin
      Result := rtlactors;
    end);
  cvertexes.AddVariable('Vertexes',
    function: TObject
    begin
      Result := rtlvertexes;
    end);
  csides.AddVariable('Sides',
    function: TObject
    begin
      Result := rtlsides;
    end);
  clines.AddVariable('Lines',
    function: TObject
    begin
      Result := rtllines;
    end);
  csectors.AddVariable('Sectors',
    function: TObject
    begin
      Result := rtlsectors;
    end);
  cmobjinfo.AddVariable('MobjInfo',
    function: TObject
    begin
      Result := rtlmobjinfo;
    end);
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

