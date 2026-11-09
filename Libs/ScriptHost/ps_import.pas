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
//  Pascal Script import definitions.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit ps_import;
{$I PascalScript.inc}

interface

uses
  d_delphi,
  ps_defs,
  ps_compiler,
  uPSPreProcessor,
  ps_runtime,
  DelphiDoom.ScriptHost.Intf;

//==============================================================================
//
// PS_InitProcLists
//
//==============================================================================
procedure PS_InitProcLists;

//==============================================================================
//
// PS_ShutDownProcLists
//
//==============================================================================
procedure PS_ShutDownProcLists;

type
  TDoomCompiler = class(TPSPascalCompiler)
  private
    FPP: TPSPreProcessor;
    funitnames: TDStringList;
  public
    constructor CreateDoomCompiler; virtual;
    function CompileDoomScript(const source: TbtString; var pcode: TbtString): Boolean; virtual;
    destructor Destroy; override;
    property unitnames: TDStringList read funitnames;
  end;

  TDoomExec = class(TPSExec)
  public
    constructor CreateDoomExec(const aImporter: TPSRuntimeClassImporter); virtual;
    function LoadData(const pcode: TbtString): Boolean; override;
  end;

  TPSDoomRuntimeClassImporter = class(TPSRuntimeClassImporter)
  public
    constructor Create; override;
  end;

const
  ID_DDPS = 1397769284; // 'DDPS'

//==============================================================================
//
// PS_ConfigureScriptRegistry
// The functions that scripts can call, given by the composition root
//
//==============================================================================
procedure PS_ConfigureScriptRegistry(const ARegistry: IScriptFunctionRegistry);

//==============================================================================
//
// PS_ConfigureGameFunctions
// The parts of PS_GAME that are classes (game information, textures, keyboard)
//
//==============================================================================
procedure PS_ConfigureGameFunctions(const AGameInfo, ATextures, AKeys: IScriptFunctionSection);

//==============================================================================
//
// PS_ScriptRegistry
//
//==============================================================================
function PS_ScriptRegistry: IScriptFunctionRegistry;

//==============================================================================
//
// PS_ScriptOnUses
//
//==============================================================================
function PS_ScriptOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;

implementation

uses
  Classes,
  TypInfo,
  uPSC_dateutils,
  uPSC_dll,
  uPSR_dateutils,
  uPSR_dll,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Types,
  psi_game,
  psi_map,
  psi_overlay,
  psi_system,
  psi_globals,
  doomdef,
  deh_main,
  {$IFDEF DOOM_OR_STRIFE}
  d_items,
  {$ENDIF}
  d_main,
  g_game,
  info_h,
  info_common,
  i_system,
  m_base,
  m_fixed,
  m_rnd,
  p_gender,
  p_local,
  p_maputl,
  p_slopes,
  {$IFDEF HEXEN}
  p_mapinfo,
  {$ENDIF}
  r_main,
  r_renderstyle,
  sc_states,
  tables,
  w_pak,
  ddc_base,
  ps_keywords;

var
  // given by the composition root
  ps_registry_ref: IScriptFunctionRegistry = nil;
  ps_gameinfo_ref: IScriptFunctionSection = nil;
  ps_textures_ref: IScriptFunctionSection = nil;
  ps_keys_ref: IScriptFunctionSection = nil;

//==============================================================================
//
// PS_ConfigureScriptRegistry
//
//==============================================================================
procedure PS_ConfigureScriptRegistry(const ARegistry: IScriptFunctionRegistry);
begin
  ps_registry_ref := ARegistry;
end;

//==============================================================================
//
// PS_ConfigureGameFunctions
//
//==============================================================================
procedure PS_ConfigureGameFunctions(const AGameInfo, ATextures, AKeys: IScriptFunctionSection);
begin
  ps_gameinfo_ref := AGameInfo;
  ps_textures_ref := ATextures;
  ps_keys_ref := AKeys;
end;

//==============================================================================
//
// PS_ScriptRegistry
//
//==============================================================================
function PS_ScriptRegistry: IScriptFunctionRegistry;
begin
  if ps_registry_ref = nil then
    I_Error('PS_ConfigureScriptRegistry() was not called: the functions of the scripts are missing');
  Result := ps_registry_ref;
end;

//==============================================================================
//
// PS_DescribeGameFunctions
// The functions of the unit PS_GAME
//
//==============================================================================
procedure PS_DescribeGameFunctions(const ATable: IScriptFunctionTable);
begin
  if (ps_gameinfo_ref = nil) or (ps_textures_ref = nil) or (ps_keys_ref = nil) then
    I_Error('PS_ConfigureGameFunctions() was not called: the functions of the game are missing');
  // --------------------------- Actors ----------------------------------------
  ATable.Add('function Actor: LongWord;', @PS_Actor);
  ATable.AddWithCustomResult('procedure TActor(const key: LongWord);', '!TActor', 'function TActor(const key: LongWord): !TActor;', @PS_TActor);
  ATable.Add('function GetActorTarget(const key: LongWord): LongWord;', @PS_GetActorTarget);
  ATable.Add('procedure SetActorTarget(const key: LongWord; const targ: LongWord);', @PS_SetActorTarget);
  ATable.Add('function GetActorTracer(const key: LongWord): LongWord;', @PS_GetActorTracer);
  ATable.Add('procedure SetActorTracer(const key: LongWord; const targ: LongWord);', @PS_SetActorTracer);
  ATable.Add('function GetActorMaster(const key: LongWord): LongWord;', @PS_GetActorMaster);
  ATable.Add('procedure SetActorMaster(const key: LongWord; const targ: LongWord);', @PS_SetActorMaster);
  ATable.Add('function GetActorX(const key: LongWord): fixed_t;', @PS_GetActorX);
  ATable.Add('procedure SetActorX(const key: LongWord; const x: fixed_t);', @PS_SetActorX);
  ATable.Add('function GetActorY(const key: LongWord): fixed_t;', @PS_GetActorY);
  ATable.Add('procedure SetActorY(const key: LongWord; const y: fixed_t);', @PS_SetActorY);
  ATable.Add('function GetActorZ(const key: LongWord): fixed_t;', @PS_GetActorZ);
  ATable.Add('procedure SetActorZ(const key: LongWord; const z: fixed_t);', @PS_SetActorZ);
  ATable.Add('procedure SetActorPosition(const key: LongWord; const x, y, z: fixed_t);', @PS_SetActorPosition);
  ATable.Add('function GetActorMOMX(const key: LongWord): fixed_t;', @PS_GetActorMOMX);
  ATable.Add('procedure SetActorMOMX(const key: LongWord; const x: fixed_t);', @PS_SetActorMOMX);
  ATable.Add('function GetActorMOMY(const key: LongWord): fixed_t;', @PS_GetActorMOMY);
  ATable.Add('procedure SetActorMOMY(const key: LongWord; const y: fixed_t);', @PS_SetActorMOMY);
  ATable.Add('function GetActorMOMZ(const key: LongWord): fixed_t;', @PS_GetActorMOMZ);
  ATable.Add('procedure SetActorMOMZ(const key: LongWord; const z: fixed_t);', @PS_SetActorMOMZ);
  ATable.Add('function GetActorFloorZ(const key: LongWord): fixed_t;', @PS_GetActorFloorZ);
  ATable.Add('procedure SetActorFloorZ(const key: LongWord; const z: fixed_t);', @PS_SetActorFloorZ);
  ATable.Add('function GetActorCeilingZ(const key: LongWord): fixed_t;', @PS_GetActorCeilingZ);
  ATable.Add('procedure SetActorCeilingZ(const key: LongWord; const z: fixed_t);', @PS_SetActorCeilingZ);
  ATable.Add('function GetActorSpeed(const key: LongWord): fixed_t;', @PS_GetActorSpeed);
  ATable.Add('procedure SetActorSpeed(const key: LongWord; const speed: fixed_t);', @PS_SetActorSpeed);
  ATable.Add('function GetActorAngle(const key: LongWord): angle_t;', @PS_GetActorAngle);
  ATable.Add('procedure SetActorAngle(const key: LongWord; const angle: angle_t);', @PS_SetActorAngle);
  ATable.Add('function GetActorSector(const key: LongWord): integer;', @PS_GetActorSector);
  ATable.Add('function GetActorHealth(const key: LongWord): integer;', @PS_GetActorHealth);
  ATable.Add('procedure SetActorHealth(const key: LongWord; const h: integer);', @PS_SetActorHealth);
  ATable.Add('function GetActorSpawnHealth(const key: LongWord): integer;', @PS_GetActorSpawnHealth);
  ATable.Add('function GetActorMass(const key: LongWord): integer;', @PS_GetActorMass);
  ATable.Add('procedure SetActorMass(const key: LongWord; const m: Integer);', @PS_SetActorMass);
  ATable.Add('function GetActorHeight(const key: LongWord): fixed_t;', @PS_GetActorHeight);
  ATable.Add('procedure SetActorHeight(const key: LongWord; const h: fixed_t);', @PS_SetActorHeight);
  ATable.Add('function GetActorCustomDropItem(const key: LongWord): integer;', @PS_GetActorCustomDropItem);
  ATable.Add('procedure SetActorCustomDropItem(const key: LongWord; const value: integer);', @PS_SetActorCustomDropItem);
  ATable.Add('procedure SetActorDefaultDropItem(const key: LongWord);', @PS_SetActorDefaultDropItem);
  ATable.Add('function GetActorPushFactor(const key: LongWord): integer;', @PS_GetActorPushFactor);
  ATable.Add('procedure SetActorPushFactor(const key: LongWord; const value: integer);', @PS_SetActorPushFactor);
  ATable.Add('function GetActorScale(const key: LongWord): integer;', @PS_GetActorScale);
  ATable.Add('procedure SetActorScale(const key: LongWord; const value: integer);', @PS_SetActorScale);
  ATable.Add('function GetActorGravity(const key: LongWord): integer;', @PS_GetActorGravity);
  ATable.Add('procedure SetActorGravity(const key: LongWord; const value: integer);', @PS_SetActorGravity);
  ATable.Add('function GetActorSpecial(const key: LongWord): Integer;', @PS_GetActorSpecial);
  ATable.Add('procedure SetActorSpecial(const key: LongWord; const value: Integer);', @PS_SetActorSpecial);
  ATable.Add('function GetActorArg1(const key: LongWord): integer;', @PS_GetActorArg1);
  ATable.Add('procedure SetActorArg1(const key: LongWord; const value: integer);', @PS_SetActorArg1);
  ATable.Add('function GetActorArg2(const key: LongWord): integer;', @PS_GetActorArg2);
  ATable.Add('procedure SetActorArg2(const key: LongWord; const value: integer);', @PS_SetActorArg2);
  ATable.Add('function GetActorArg3(const key: LongWord): integer;', @PS_GetActorArg3);
  ATable.Add('procedure SetActorArg3(const key: LongWord; const value: integer);', @PS_SetActorArg3);
  ATable.Add('function GetActorArg4(const key: LongWord): integer;', @PS_GetActorArg4);
  ATable.Add('procedure SetActorArg4(const key: LongWord; const value: integer);', @PS_SetActorArg4);
  ATable.Add('function GetActorArg5(const key: LongWord): integer;', @PS_GetActorArg5);
  ATable.Add('procedure SetActorArg5(const key: LongWord; const value: integer);', @PS_SetActorArg5);
  ATable.Add('function GetActorWeaveIndexXY(const key: LongWord): Integer;);', @PS_GetActorWeaveIndexXY);
  ATable.Add('procedure SetActorWeaveIndexXY(const key: LongWord; const value: Integer);', @PS_SetActorWeaveIndexXY);
  ATable.Add('function GetActorWeaveIndexZ(const key: LongWord): Integer;);', @PS_GetActorWeaveIndexZ);
  ATable.Add('procedure SetActorWeaveIndexZ(const key: LongWord; const value: Integer);', @PS_SetActorWeaveIndexZ);
  ATable.Add('function GetActorFriction(const key: LongWord): Integer;);', @PS_GetActorFriction);
  ATable.Add('procedure SetActorFriction(const key: LongWord; const value: Integer););', @PS_SetActorFriction);
  ATable.Add('function GetActorPainChance(const key: LongWord): Integer;);', @PS_GetActorPainChance);
  ATable.Add('procedure SetActorPainChance(const key: LongWord; const value: Integer);', @PS_SetActorPainChance);
  ATable.Add('function GetActorSpriteDX(const key: LongWord): Integer;);', @PS_GetActorSpriteDX);
  ATable.Add('procedure SetActorSpriteDX(const key: LongWord; const value: Integer);', @PS_SetActorSpriteDX);
  ATable.Add('function GetActorSpriteDY(const key: LongWord): Integer;);', @PS_GetActorSpriteDY);
  ATable.Add('procedure SetActorSpriteDY(const key: LongWord; const value: Integer);', @PS_SetActorSpriteDY);
  ATable.Add('function GetActorCustomParam(const key: LongWord; const parm: string): integer;', @PS_GetActorCustomParam);
  ATable.Add('procedure SetActorCustomParam(const key: LongWord; const parm: string; const value: integer);', @PS_SetActorCustomParam);
  ATable.Add('function CheckActorFlag(const key: LongWord; const flag: LongWord): boolean;', @PS_CheckActorFlag);
  ATable.Add('procedure SetActorFlag(const key: LongWord; const flag: LongWord);', @PS_SetActorFlag);
  ATable.Add('procedure UnSetActorFlag(const key: LongWord; const flag: LongWord);', @PS_UnSetActorFlag);
  ATable.Add('function GetActorInfightingGroup(const key: LongWord): Integer;', @PS_GetActorInfightingGroup);
  ATable.Add('procedure SetActorInfightingGroup(const key: LongWord; const value: Integer);', @PS_SetActorInfightingGroup);
  ATable.Add('function GetActorProjectileGroup(const key: LongWord): Integer;', @PS_GetActorProjectileGroup);
  ATable.Add('procedure SetActorProjectileGroup(const key: LongWord; const value: Integer);', @PS_SetActorProjectileGroup);
  ATable.Add('function GetActorSplashGroup(const key: LongWord): Integer;', @PS_GetActorSplashGroup);
  ATable.Add('procedure SetActorSplashGroup(const key: LongWord; const value: Integer);', @PS_SetActorSplashGroup);
  ATable.Add('function GetActorTranslation(const key: LongWord): string;', @PS_GetActorTranslation);
  ATable.Add('procedure SetActorTranslation(const key: LongWord; const value: string);', @PS_SetActorTranslation);
  ATable.Add('function GetActorBloodColor(const key: LongWord): string;', @PS_GetActorBloodColor);
  ATable.Add('procedure SetActorBloodColor(const key: LongWord; const value: string);', @PS_SetActorBloodColor);
  ATable.Add('function GetActorRipSound(const key: LongWord): string;', @PS_GetActorRipSound);
  ATable.Add('function GetActorName(const key: LongWord): string;', @PS_GetActorName);
  {$IFDEF STRIFE}
  ATable.Add('function GetActorName2(const key: LongWord): string;', @PS_GetActorName2);
  {$ENDIF}
  ATable.Add('function GetActorDistanceXY(const key1, key2: LongWord): fixed_t;', @PS_GetActorDistanceXY);
  ATable.Add('function GetActorDistanceXYZ(const key1, key2: LongWord): fixed_t;', @PS_GetActorDistanceXYZ);
  ATable.Add('function GetActorMobjType(const key: LongWord): integer;', @PS_GetActorMobjType);
  ATable.Add('function GetActorEditorNumber(const key: LongWord): integer;', @PS_GetActorEditorNumber);
  ATable.Add('function GetActorState(const key: LongWord): integer;', @PS_GetActorState);
  ATable.Add('procedure SetActorState(const key: LongWord; const value: Integer);', @PS_SetActorState);
  ATable.Add('function IsValidActor(const key: LongWord): boolean;', @PS_IsValidActor);
  ATable.Add('procedure ActorPlaySound(const key: LongWord; const snd: string);', @PS_ActorPlaySound);
  ATable.Add('procedure PlaySound(const snd: string);', @PS_PlaySound);
  ATable.Add('function GetActorPlayer(const key: LongWord): integer;', @PS_GetActorPlayer);
  ATable.Add('function GetPlayerActor(const plnum: integer): LongWord;', @PS_GetPlayerActor);
  ATable.Add('function SpawnActorType(x, y, z: fixed_t; const typ: integer): LongWord;', @PS_SpawnActorType);
  ATable.Add('function SpawnActorEditorNumber(x, y, z: fixed_t; const ednum: integer): LongWord;', @PS_SpawnActorEditorNumber);
  ATable.Add('function SpawnActorName(x, y, z: fixed_t; const name: string): LongWord;', @PS_SpawnActorName);
  ATable.Add('procedure RemoveActor(const key: LongWord);', @PS_RemoveActor);
  ATable.Add('function CheckActorSight(const actor1, actor2: LongWord): boolean;', @PS_CheckActorSight);
  ATable.Add('function ActorTypeFromEditorNumber(const ednum: integer): integer;', @PS_ActorTypeFromEditorNumber);
  ATable.Add('function ActorTypeFromName(const name: string): integer;', @PS_ActorTypeFromName);
  ATable.Add('function GetActorSeeSound(const key: LongWord): string;', @PS_GetActorSeeSound);
  ATable.Add('function GetActorAttackSound(const key: LongWord): string;', @PS_GetActorAttackSound);
  ATable.Add('function GetActorPainSound(const key: LongWord): string;', @PS_GetActorPainSound);
  ATable.Add('function GetActorDeathSound(const key: LongWord): string;', @PS_GetActorDeathSound);
  ATable.Add('function GetActorActiveSound(const key: LongWord): string;', @PS_GetActorActiveSound);
  ATable.Add('function GetActorCustomSound1(const key: LongWord): string;', @PS_GetActorCustomSound1);
  ATable.Add('function GetActorCustomSound2(const key: LongWord): string;', @PS_GetActorCustomSound2);
  ATable.Add('function GetActorCustomSound3(const key: LongWord): string;', @PS_GetActorCustomSound3);
  ATable.Add('function GetActorMeleeSound(const key: LongWord): string;', @PS_GetActorMeleeSound);
  ATable.Add('function MergeActorArrays(const A1, A2: TActorArray): TActorArray;', @PS_MergeLongWordArrays);
  // ------------------------- Vertexes ----------------------------------------
  ATable.AddWithCustomResult('procedure TVertex(const id: Integer);', '!TVertex', 'function TVertex(const id: Integer): !TVertex;', @PS_TVertex);
  ATable.Add('function GetVertexX(const v: integer): fixed_t;', @PS_GetVertexX);
  ATable.Add('function GetVertexY(const v: integer): fixed_t;', @PS_GetVertexY);
  ATable.Add('function IsValidVertex(const v: Integer): boolean;', @PS_IsValidVertex);
  ATable.Add('function GetVertexCount: Integer;', @PS_GetVertexCount);
  // ---------------------------- Sides ----------------------------------------
  ATable.AddWithCustomResult('procedure TSide(const id: Integer);', '!TSide', 'function TSide(const id: Integer): !TSide;', @PS_TSide);
  ATable.Add('function GetSideTextureOffset(const sd: Integer): fixed_t;', @PS_GetSideTextureOffset);
  ATable.Add('procedure SetSideTextureOffset(const sd: Integer; const offs: fixed_t);', @PS_SetSideTextureOffset);
  ATable.Add('function GetSideTopTextureOffset(const sd: Integer): Integer;', @PS_GetSideTopTextureOffset);
  ATable.Add('procedure SetSideTopTextureOffset(const sd: Integer; const offs: Integer);', @PS_SetSideTopTextureOffset);
  ATable.Add('function GetSideBottomTextureOffset(const sd: Integer): Integer;', @PS_GetSideBottomTextureOffset);
  ATable.Add('procedure SetSideBottomTextureOffset(const sd: Integer; const offs: Integer);', @PS_SetSideBottomTextureOffset);
  ATable.Add('function GetSideMidTextureOffset(const sd: Integer): Integer;', @PS_GetSideMidTextureOffset);
  ATable.Add('procedure SetSideMidTextureOffset(const sd: Integer; const offs: Integer);', @PS_SetSideMidTextureOffset);
  ATable.Add('function GetSideRowOffset(const sd: Integer): fixed_t;', @PS_GetSideRowOffset);
  ATable.Add('procedure SetSideRowOffset(const sd: Integer; const offs: fixed_t);', @PS_SetSideRowOffset);
  ATable.Add('function GetSideTopRowOffset(const sd: Integer): Integer;', @PS_GetSideTopRowOffset);
  ATable.Add('procedure SetSideTopRowOffset(const sd: Integer; const offs: Integer);', @PS_SetSideTopRowOffset);
  ATable.Add('function GetSideBottomRowOffset(const sd: Integer): Integer;', @PS_GetSideBottomRowOffset);
  ATable.Add('procedure SetSideBottomRowOffset(const sd: Integer; const offs: Integer);', @PS_SetSideBottomRowOffset);
  ATable.Add('function GetSideMidRowOffset(const sd: Integer): Integer;', @PS_GetSideMidRowOffset);
  ATable.Add('procedure SetSideMidRowOffset(const sd: Integer; const offs: Integer);', @PS_SetSideMidRowOffset);
  ATable.Add('function GetSideTopTexture(const sd: Integer): string;', @PS_GetSideTopTexture);
  ATable.Add('procedure SetSideTopTexture(const sd: Integer; const tex: string);', @PS_SetSideTopTexture);
  ATable.Add('function GetSideBottomTexture(const sd: Integer): string;', @PS_GetSideBottomTexture);
  ATable.Add('procedure SetSideBottomTexture(const sd: Integer; const tex: string);', @PS_SetSideBottomTexture);
  ATable.Add('function GetSideMiddleTexture(const sd: Integer): string;', @PS_GetSideMiddleTexture);
  ATable.Add('procedure SetSideMiddleTexture(const sd: Integer; const tex: string);', @PS_SetSideMiddleTexture);
  ATable.Add('function GetSideSector(const sd: Integer): integer;', @PS_GetSideSector);
  ATable.Add('function IsValidSide(const sd: Integer): boolean;', @PS_IsValidSide);
  ATable.Add('function GetSideCount: Integer;', @PS_GetSideCount);
  // ---------------------------- Lines ----------------------------------------
  ATable.AddWithCustomResult('procedure TLine(const id: Integer);', '!TLine', 'function TLine(const id: Integer): !TLine;', @PS_TLine);
  ATable.Add('function GetLineVertex1(const ld: Integer): integer;', @PS_GetLineVertex1);
  ATable.Add('function GetLineVertex2(const ld: Integer): integer;', @PS_GetLineVertex2);
  ATable.Add('function GetLineDX(const ld: Integer): fixed_t;', @PS_GetLineDX);
  ATable.Add('function GetLineDY(const ld: Integer): fixed_t;', @PS_GetLineDY);
  ATable.Add('function GetLineSpecial(const ld: Integer): integer;', @PS_GetLineSpecial);
  ATable.Add('procedure SetLineSpecial(const ld: Integer; const spec: integer);', @PS_SetLineSpecial);
  ATable.Add('function GetLineArg1(const ld: Integer): byte;', @PS_GetLineArg1);
  ATable.Add('procedure SetLineArg1(const ld: Integer; const arg: byte);', @PS_SetLineArg1);
  ATable.Add('function GetLineArg2(const ld: Integer): byte;', @PS_GetLineArg2);
  ATable.Add('procedure SetLineArg2(const ld: Integer; const arg: byte);', @PS_SetLineArg2);
  ATable.Add('function GetLineArg3(const ld: Integer): byte;', @PS_GetLineArg3);
  ATable.Add('procedure SetLineArg3(const ld: Integer; const arg: byte);', @PS_SetLineArg3);
  ATable.Add('function GetLineArg4(const ld: Integer): byte;', @PS_GetLineArg4);
  ATable.Add('procedure SetLineArg4(const ld: Integer; const arg: byte);', @PS_SetLineArg4);
  ATable.Add('function GetLineArg5(const ld: Integer): byte;', @PS_GetLineArg5);
  ATable.Add('procedure SetLineArg5(const ld: Integer; const arg: byte);', @PS_SetLineArg5);
  {$IFNDEF HEXEN}
  ATable.Add('function GetLineTag(const ld: Integer): integer;', @PS_GetLineTag);
  ATable.Add('procedure SetLineTag(const ld: Integer; const tag: integer);', @PS_SetLineTag);
  ATable.Add('function GetLineTransparent(const ld: Integer): Boolean;', @PS_GetLineTransparent);
  ATable.Add('procedure SetLineTransparent(const ld: Integer; const x: Boolean);', @PS_SetLineTransparent);
  {$ENDIF}
  ATable.Add('function GetLineIsBlocking(const ld: Integer): Boolean;', @PS_GetLineIsBlocking);
  ATable.Add('procedure SetLineIsBlocking(const ld: Integer; const x: Boolean);', @PS_SetLineIsBlocking);
  ATable.Add('function GetLineIsBlockingMonsters(const ld: Integer): Boolean;', @PS_GetLineIsBlockingMonsters);
  ATable.Add('procedure SetLineIsBlockingMonsters(const ld: Integer; const x: Boolean);', @PS_SetLineIsBlockingMonsters);
  ATable.Add('function GetLineTriggerScripts(const ld: Integer): Boolean;', @PS_GetLineTriggerScripts);
  ATable.Add('procedure SetLineTriggerScripts(const ld: Integer; const x: Boolean);', @PS_SetLineTriggerScripts);
  ATable.Add('function GetLineFrontSide(const ld: Integer): integer;', @PS_GetLineFrontSide);
  ATable.Add('function GetLineBackSide(const ld: Integer): integer;', @PS_GetLineBackSide);
  ATable.Add('function GetLineFrontSector(const ld: Integer): integer;', @PS_GetLineFrontSector);
  ATable.Add('function GetLineBackSector(const ld: Integer): integer;', @PS_GetLineBackSector);
  ATable.Add('function IsValidLine(const ld: Integer): boolean;', @PS_IsValidLine);
  ATable.Add('function GetLineCount: Integer;', @PS_GetLineCount);
  {$IFNDEF HEXEN}
  ATable.Add('function FindLinesFromTag(const tag: integer): TIntegerArray;', @PS_FindLinesFromTag);
  {$ENDIF}
// --------------------------- SECTORS -----------------------------------------
  ATable.AddWithCustomResult('procedure TSector(const id: Integer);', '!TSector', 'function TSector(const id: Integer): !TSector;', @PS_TSector);
  ATable.Add('function GetSectorFloorHeight(const sec: Integer): fixed_t;', @PS_GetSectorFloorHeight);
  ATable.Add('procedure SetSectorFloorHeight(const sec: Integer; const x: fixed_t);', @PS_SetSectorFloorHeight);
  ATable.Add('function GetSectorCeilingHeight(const sec: Integer): fixed_t;', @PS_GetSectorCeilingHeight);
  ATable.Add('procedure SetSectorCeilingHeight(const sec: Integer; const x: fixed_t);', @PS_SetSectorCeilingHeight);
  ATable.Add('function GetSectorFloorPicture(const sec: Integer): string;', @PS_GetSectorFloorPicture);
  ATable.Add('procedure SetSectorFloorPicture(const sec: Integer; const pic: string);', @PS_SetSectorFloorPicture);
  ATable.Add('function GetSectorCeilingPicture(const sec: Integer): string;', @PS_GetSectorCeilingPicture);
  ATable.Add('procedure SetSectorCeilingPicture(const sec: Integer; const pic: string);', @PS_SetSectorCeilingPicture);
  ATable.Add('function GetSectorLightLevel(const sec: Integer): Integer;', @PS_GetSectorLightLevel);
  ATable.Add('procedure SetSectorLightLevel(const sec: Integer; const x: Integer);', @PS_SetSectorLightLevel);
  ATable.Add('function GetSectorSpecial(const sec: Integer): Integer;', @PS_GetSectorSpecial);
  ATable.Add('function GetSectorTag(const sec: Integer): Integer;', @PS_GetSectorTag);
  ATable.Add('procedure SetSectorTag(const sec: Integer; const x: Integer);', @PS_SetSectorTag);
  ATable.Add('function GetSectorActors(const sec: Integer): TActorArray;', @PS_GetSectorActors);
  ATable.Add('function GetSectorNumActors(const sec: Integer): Integer;', @PS_GetSectorNumActors);
  ATable.Add('function GetSectorLines(const sec: Integer): TIntegerArray;', @PS_GetSectorLines);
  ATable.Add('function GetSectorNumLines(const sec: Integer): Integer;', @PS_GetSectorNumLines);
  {$IFDEF DOOM_OR_STRIFE}
  ATable.Add('function GetSectorFloorXOffset(const sec: Integer): fixed_t;', @PS_GetSectorFloorXOffset);
  ATable.Add('procedure SetSectorFloorXOffset(const sec: Integer; const offs: fixed_t);', @PS_SetSectorFloorXOffset);
  ATable.Add('function GetSectorFloorYOffset(const sec: Integer): fixed_t;', @PS_GetSectorFloorYOffset);
  ATable.Add('procedure SetSectorFloorYOffset(const sec: Integer; const offs: fixed_t);', @PS_SetSectorFloorYOffset);
  ATable.Add('function GetSectorCeilingXOffset(const sec: Integer): fixed_t;', @PS_GetSectorCeilingXOffset);
  ATable.Add('procedure SetSectorCeilingXOffset(const sec: Integer; const offs: fixed_t);', @PS_SetSectorCeilingXOffset);
  ATable.Add('function GetSectorCeilingYOffset(const sec: Integer): fixed_t;', @PS_GetSectorCeilingYOffset);
  ATable.Add('procedure SetSectorCeilingYOffset(const sec: Integer; const offs: fixed_t);', @PS_SetSectorCeilingYOffset);
  {$ENDIF}
  ATable.Add('function GetSectorFloorAngle(const sec: Integer): angle_t;', @PS_GetSectorFloorAngle);
  ATable.Add('procedure SetSectorFloorAngle(const sec: Integer; const ang: angle_t);', @PS_SetSectorFloorAngle);
  ATable.Add('function GetSectorFloorAngleX(const sec: Integer): fixed_t;', @PS_GetSectorFloorAngleX);
  ATable.Add('procedure SetSectorFloorAngleX(const sec: Integer; const angx: fixed_t);', @PS_SetSectorFloorAngleX);
  ATable.Add('function GetSectorFloorAngleY(const sec: Integer): fixed_t;', @PS_GetSectorFloorAngleY);
  ATable.Add('procedure SetSectorFloorAngleY(const sec: Integer; const angy: fixed_t);', @PS_SetSectorFloorAngleY);
  ATable.Add('function GetSectorCeilingAngle(const sec: Integer): angle_t;', @PS_GetSectorCeilingAngle);
  ATable.Add('procedure SetSectorCeilingAngle(const sec: Integer; const ang: angle_t);', @PS_SetSectorCeilingAngle);
  ATable.Add('function GetSectorCeilingAngleX(const sec: Integer): fixed_t;', @PS_GetSectorCeilingAngleX);
  ATable.Add('procedure SetSectorCeilingAngleX(const sec: Integer; const angx: fixed_t);', @PS_SetSectorCeilingAngleX);
  ATable.Add('function GetSectorCeilingAngleY(const sec: Integer): fixed_t;', @PS_GetSectorCeilingAngleY);
  ATable.Add('procedure SetSectorCeilingAngleY(const sec: Integer; const angy: fixed_t);', @PS_SetSectorCeilingAngleY);
  ATable.Add('function GetSectorRippleFloor(const sec: Integer): Boolean;', @PS_GetSectorRippleFloor);
  ATable.Add('procedure SetSectorRippleFloor(const sec: Integer; const rpl: Boolean);', @PS_SetSectorRippleFloor);
  ATable.Add('function GetSectorRippleCeiling(const sec: Integer): Boolean;', @PS_GetSectorRippleCeiling);
  ATable.Add('procedure SetSectorRippleCeiling(const sec: Integer; const rpl: Boolean);', @PS_SetSectorRippleCeiling);
  ATable.Add('function GetSectorInterpolate(const sec: Integer): Boolean;', @PS_GetSectorInterpolate);
  ATable.Add('procedure SetSectorInterpolate(const sec: Integer; const intpl: Boolean);', @PS_SetSectorInterpolate);
  ATable.Add('function GetSectorFog(const sec: Integer): Boolean;', @PS_GetSectorFog);
  ATable.Add('procedure SetSectorFog(const sec: Integer; const fog: Boolean);', @PS_SetSectorFog);
  ATable.Add('function GetSectorGravity(const sec: Integer): fixed_t;', @PS_GetSectorGravity);  // JVAL: sector gravity (VERSION 204)
  ATable.Add('procedure SetSectorGravity(const sec: Integer; const grav: fixed_t);', @PS_SetSectorGravity); // JVAL: sector gravity (VERSION 204)
  ATable.Add('function GetSectorWindThrust(const sec: Integer): Integer;', @PS_GetSectorWindThrust);  // JVAL: 20220223 - Sector WindThrust
  ATable.Add('procedure SetSectorWindThrust(const sec: Integer; const wthrust: Integer);', @PS_SetSectorWindThrust);  // JVAL: 20220223 - Sector WindThrust
  ATable.Add('function GetSectorWindAngle(const sec: Integer): LongWord;', @PS_GetSectorWindAngle); // JVAL: 20220223 - Sector WindAngle
  ATable.Add('procedure SetSectorWindAngle(const sec: Integer; const wangle: LongWord);', @PS_SetSectorWindAngle);  // JVAL: 20220223 - Sector WindAngle
  ATable.Add('function GetSectorMidSector(const sec: Integer): Integer;', @PS_GetSectorMidSector);
  ATable.Add('function GetSectorSlopeSector(const sec: Integer): Integer;', @PS_GetSectorSlopeSector);
  ATable.Add('function SkyPicture: string;', @PS_SkyPicture);
  ATable.Add('function IsValidSector(const sec: Integer): boolean;', @PS_IsValidSector);
  ATable.Add('function GetSectorCount: Integer;', @PS_GetSectorCount);
  ATable.Add('function FindSectorsFromTag(const tag: integer): TIntegerArray;', @PS_FindSectorsFromTag);
  ATable.Add('procedure SectorPlaySound(const secid: integer; const snd: string);', @PS_SectorPlaySound);
  ATable.Add('procedure SectorMoveZ(const secid: integer; const dz: fixed_t);', @PS_SectorMoveZ);
  ATable.Add('procedure SetSectorFloorSlope(const secid: integer; const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);', @PS_SetFloorSlope);
  ATable.Add('procedure SetSectorCeilingSlope(const secid: integer; const x1, y1, z1: fixed_t; const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);', @PS_SetCeilingSlope);
// --------------------------- PLAYERS -----------------------------------------
  ATable.Add('function PlayerInGame(const plnum: integer): boolean;', @PS_PlayerInGame);
  {$IFDEF DOOM_OR_STRIFE}
  ATable.Add('procedure PlayerFaceMobj(const plnum: integer; const actor: LongWord; const ticks: integer);', @PS_PlayerFaceMobj);
  {$ENDIF}
  {$IFDEF DOOM_OR_STRIFE}
  ATable.Add('procedure SetPlayerHasCard(const plnum: integer; const card: integer; const value: boolean);', @PS_SetPlayerHasCard);
  ATable.Add('function GetPlayerHasCard(const plnum: integer; const card: integer): boolean;', @PS_GetPlayerHasCard);
  ATable.Add('procedure SetPlayerHasKey(const plnum: integer; const key: integer; const value: boolean);', @PS_SetPlayerHasCard);
  ATable.Add('function GetPlayerHasKey(const plnum: integer; const key: integer): boolean;', @PS_GetPlayerHasCard);
  {$ENDIF}
  {$IFDEF HERETIC_OR_HEXEN}
  ATable.Add('procedure SetPlayerHasCard(const plnum: integer; const card: integer; const value: boolean);', @PS_SetPlayerHasKey);
  ATable.Add('function GetPlayerHasCard(const plnum: integer; const card: integer): boolean;', @PS_GetPlayerHasKey);
  ATable.Add('procedure SetPlayerHasKey(const plnum: integer; const key: integer; const value: boolean);', @PS_SetPlayerHasKey);
  ATable.Add('function GetPlayerHasKey(const plnum: integer; const key: integer): boolean;', @PS_GetPlayerHasKey);
  ATable.Add('procedure PlayerUseArtifact(const plnum: Integer; const arti: Integer);', @PS_PlayerUseArtifact);
  ATable.Add('function GiveArtifactToPlayer(const plnum: Integer; const arti: Integer): Boolean;', @PS_GiveArtifactToPlayer);
  ATable.Add('function CheckPlayerArtifact(const plnum: Integer; const arti: Integer): Integer;', @PS_CheckPlayerArtifact);
  {$ENDIF}
  ATable.Add('procedure SetPlayerHasWeapon(const plnum: integer; const weapon: integer; const value: boolean);', @PS_SetPlayerHasWeapon);
  ATable.Add('function GetPlayerHasWeapon(const plnum: integer; const weapon: integer): boolean;', @PS_GetPlayerHasWeapon);
  {$IFNDEF HEXEN}
  ATable.Add('procedure SetPlayerAmmo(const plnum: integer; const ammotype: integer; const value: integer);', @PS_SetPlayerAmmo);
  ATable.Add('function GetPlayerAmmo(const plnum: integer; const ammotype: integer): integer;', @PS_GetPlayerAmmo);
  {$ELSE}
  ATable.Add('procedure SetPlayerMana(const plnum: integer; const mana: integer; const value: integer);', @PS_SetPlayerMana);
  ATable.Add('function GetPlayerMana(const plnum: integer; const mana: integer): integer;', @PS_GetPlayerMana);
  {$ENDIF}
  {$IFDEF HEXEN}
  ATable.Add('function GetPlayerClass(const plnum: Integer): Integer;', @PS_GetPlayerClass);
  {$ENDIF}
  ATable.Add('procedure SetPlayerMessage(const plnum: integer; const msg: string);', @PS_SetPlayerMessage);
  ATable.Add('function GetPlayerMessage(const plnum: integer): string;', @PS_GetPlayerMessage);
  ATable.Add('procedure SetPlayerExtraLight(const plnum: Integer; const l: Integer);', @PS_SetPlayerExtraLight);
  ATable.Add('function GetPlayerExtraLight(const plnum: Integer): Integer;', @PS_GetPlayerExtraLight);
  ATable.Add('procedure SetPlayerPowerTicks(const plnum: integer; const powertype: integer; const ticks: integer);', @PS_SetPlayerPowerTicks);
  ATable.Add('function GetPlayerPowerTicks(const plnum: integer; const powertype: integer): integer;', @PS_GetPlayerPowerTicks);
  ATable.Add('function GetPlayerViewZ(const plnum: integer): fixed_t;', @PS_GetPlayerViewZ);
  ATable.Add('function GetPlayerViewHeight(const plnum: integer): fixed_t;', @PS_GetPlayerViewHeight);
  ATable.Add('function ConsolePlayer: Integer;', @PS_ConsolePlayer);
  {$IFDEF STRIFE}
  ATable.Add('function CheckPlayerQuest(const plnum: Integer; const quest: LongWord): Boolean;', @PS_CheckPlayerQuest);
  ATable.Add('procedure SetPlayerQuest(const plnum: Integer; const quest: LongWord);', @PS_SetPlayerQuest);
  ATable.Add('procedure UnSetPlayerQuest(const plnum: Integer; const quest: LongWord);', @PS_UnSetPlayerQuest);
  {$ENDIF}
// -------------------------- TEXTURES -----------------------------------------
  ps_textures_ref.Describe(ATable);
// ----------------------------- MOBJS -----------------------------------------
  ATable.Add('function IsValidMobjType(const typ: integer): boolean;', @PS_IsValidMobjType);
  ATable.Add('function GetMobjTypeFromEditorNumber(const en: integer): integer;', @PS_GetMobjTypeFromEditorNumber);
  ATable.Add('function GetEditorNumberFromMobjType(const typ: integer): integer;', @PS_GetEditorNumberFromMobjType);
  ATable.Add('function GetMobjInfoCount: integer;', @PS_GetMobjInfoCount);
  ATable.Add('function GetMobjInfoName(const typ: integer): string;', @PS_GetMobjInfoName);
  {$IFDEF STRIFE}
  ATable.Add('function GetMobjInfoName2(const typ: integer): string;', @PS_GetMobjInfoName2);
  {$ENDIF}
  ATable.Add('function GetMobjInfoInheritsFrom(const typ: integer): integer;', @PS_GetMobjInfoInheritsFrom);
  ATable.Add('function GetMobjInfoDoomEdNum(const typ: integer): integer;', @PS_GetMobjInfoDoomEdNum);
  ATable.Add('function GetMobjInfoSpawnState(const typ: integer): integer;', @PS_GetMobjInfoSpawnState);
  ATable.Add('function GetMobjInfoSpawnHealth(const typ: integer): integer;', @PS_GetMobjInfoSpawnHealth);
  ATable.Add('function GetMobjInfoSeeState(const typ: integer): integer;', @PS_GetMobjInfoSeeState);
  ATable.Add('function GetMobjInfoSeeSound(const typ: integer): string;', @PS_GetMobjInfoSeeSound);
  ATable.Add('function GetMobjInfoReactionTime(const typ: integer): integer;', @PS_GetMobjInfoReactionTime);
  ATable.Add('function GetMobjInfoAttackSound(const typ: integer): string;', @PS_GetMobjInfoAttackSound);
  ATable.Add('function GetMobjInfoPainState(const typ: integer): integer;', @PS_GetMobjInfoPainState);
  ATable.Add('function GetMobjInfoPainChance(const typ: integer): integer;', @PS_GetMobjInfoPainChance);
  ATable.Add('function GetMobjInfoPainSound(const typ: integer): string;', @PS_GetMobjInfoPainSound);
  ATable.Add('function GetMobjInfoMeleeState(const typ: integer): integer;', @PS_GetMobjInfoMeleeState);
  ATable.Add('function GetMobjInfoMissileState(const typ: integer): integer;', @PS_GetMobjInfoMissileState);
  ATable.Add('function GetMobjInfoDeathState(const typ: integer): integer;', @PS_GetMobjInfoDeathState);
  ATable.Add('function GetMobjInfoXdeathState(const typ: integer): integer;', @PS_GetMobjInfoXdeathState);
  ATable.Add('function GetMobjInfoDeathSound(const typ: integer): string;', @PS_GetMobjInfoDeathSound);
  ATable.Add('function GetMobjInfoSpeed(const typ: integer): integer;', @PS_GetMobjInfoSpeed);
  ATable.Add('function GetMobjInfoRadius(const typ: integer): integer;', @PS_GetMobjInfoRadius);
  ATable.Add('function GetMobjInfoHeight(const typ: integer): integer;', @PS_GetMobjInfoHeight);
  ATable.Add('function GetMobjInfoMass(const typ: integer): integer;', @PS_GetMobjInfoMass);
  ATable.Add('function GetMobjInfoDamage(const typ: integer): integer;', @PS_GetMobjInfoDamage);
  ATable.Add('function GetMobjInfoActiveSound(const typ: integer): string;', @PS_GetMobjInfoActiveSound);
  ATable.Add('function GetMobjInfoFlag(const typ: Integer; const flg: integer): boolean;', @PS_GetMobjInfoFlag);
  ATable.Add('function GetMobjInfoRaiseState(const typ: integer): integer;', @PS_GetMobjInfoRaiseState);
  ATable.Add('function GetMobjInfoCustomSound1(const typ: integer): string;', @PS_GetMobjInfoCustomSound1);
  ATable.Add('function GetMobjInfoCustomSound2(const typ: integer): string;', @PS_GetMobjInfoCustomSound2);
  ATable.Add('function GetMobjInfoCustomSound3(const typ: integer): string;', @PS_GetMobjInfoCustomSound3);
  ATable.Add('function GetMobjInfoDropItem(const typ: integer): integer;', @PS_GetMobjInfoDropItem);
  ATable.Add('function GetMobjInfoMissiletype(const typ: integer): integer;', @PS_GetMobjInfoMissiletype);
  ATable.Add('function GetMobjInfoExplosionDamage(const typ: integer): integer;', @PS_GetMobjInfoExplosionDamage);
  ATable.Add('function GetMobjInfoExplosionRadius(const typ: integer): integer;', @PS_GetMobjInfoExplosionRadius);
  ATable.Add('function GetMobjInfoMeleeDamage(const typ: integer): integer;', @PS_GetMobjInfoMeleeDamage);
  ATable.Add('function GetMobjInfoMeleeSound(const typ: integer): string;', @PS_GetMobjInfoMeleeSound);
  ATable.Add('function GetMobjInfoRenderStyle(const typ: integer): integer;', @PS_GetMobjInfoRenderStyle);
  ATable.Add('function GetMobjInfoAlpha(const typ: integer): integer;', @PS_GetMobjInfoAlpha);
  ATable.Add('function GetMobjInfoHealState(const typ: integer): integer;', @PS_GetMobjInfoHealState);
  ATable.Add('function GetMobjInfoCrashState(const typ: integer): integer;', @PS_GetMobjInfoCrashState);
  ATable.Add('function GetMobjInfoCrushState(const typ: integer): integer;', @PS_GetMobjInfoCrushState);
  ATable.Add('function GetMobjInfoVSpeed(const typ: integer): integer;', @PS_GetMobjInfoVSpeed);
  ATable.Add('function GetMobjInfoMinMissileChance(const typ: integer): integer;', @PS_GetMobjInfoMinMissileChance);
  ATable.Add('function GetMobjInfoPushFactor(const typ: integer): integer;', @PS_GetMobjInfoPushFactor);
  ATable.Add('function GetMobjInfoScale(const typ: integer): integer;', @PS_GetMobjInfoScale);
  ATable.Add('function GetMobjInfoInteractState(const typ: integer): integer;', @PS_GetMobjInfoInteractState);
  ATable.Add('function GetMobjInfoMissileHeight(const typ: integer): integer;', @PS_GetMobjInfoMissileHeight);
  ATable.Add('function GetMobjInfoFloatSpeed(const typ: integer): integer;', @PS_GetMobjInfoFloatSpeed);
  ATable.Add('function GetMobjInfoNormalSpeed(const typ: integer): integer;', @PS_GetMobjInfoNormalSpeed);
  ATable.Add('function GetMobjInfoFastSpeed(const typ: integer): integer;', @PS_GetMobjInfoFastSpeed);
  ATable.Add('function GetMobjInfoObituary(const typ: integer): string;', @PS_GetMobjInfoObituary);
  ATable.Add('function GetMobjInfoHitObituary(const typ: integer): string;', @PS_GetMobjInfoHitObituary);
  ATable.Add('function GetMobjInfoGender(const typ: integer): integer;', @PS_GetMobjInfoGender);
  ATable.Add('function GetMobjInfoMeleeRange(const typ: integer): integer;', @PS_GetMobjInfoMeleeRange);
  ATable.Add('function GetMobjInfoMaxStepHeight(const typ: integer): integer;', @PS_GetMobjInfoMaxStepHeight);
  ATable.Add('function GetMobjInfoMaxDropOffHeight(const typ: integer): integer;', @PS_GetMobjInfoMaxDropOffHeight);
  ATable.Add('function GetMobjInfoGibHealth(const typ: integer): integer;', @PS_GetMobjInfoGibHealth);
  ATable.Add('function GetMobjInfoMaxTargetRange(const typ: integer): integer;', @PS_GetMobjInfoMaxTargetRange);
  ATable.Add('function GetMobjInfoWeaveIndexXY(const typ: integer): integer;', @PS_GetMobjInfoWeaveIndexXY);
  ATable.Add('function GetMobjInfoWeaveIndexZ(const typ: integer): integer;', @PS_GetMobjInfoWeaveIndexZ);
  ATable.Add('function GetMobjInfoFriction(const typ: integer): integer;', @PS_GetMobjInfoFriction);
  ATable.Add('function GetMobjInfoSpriteDX(const dx: integer): integer;', @PS_GetMobjInfoSpriteDX);
  ATable.Add('function GetMobjInfoSpriteDY(const dy: integer): integer;', @PS_GetMobjInfoSpriteDY);
  ATable.Add('function GetMobjInfoInfightingGroup(const typ: integer): Integer;', @PS_GetMobjInfoInfightingGroup);
  ATable.Add('function GetMobjInfoProjectileGroup(const typ: integer): Integer;', @PS_GetMobjInfoProjectileGroup);
  ATable.Add('function GetMobjInfoSplashGroup(const typ: integer): Integer;', @PS_GetMobjInfoSplashGroup);
  ATable.Add('function GetMobjInfoRipSound(const typ: integer): string;', @PS_GetMobjInfoRipSound);
  ATable.Add('function GetMobjInfoMeleeThreshold(const typ: integer): integer;', @PS_GetMobjInfoMeleeThreshold);
// ------------------------------ GAME -----------------------------------------
  {$IFDEF HEXEN}
  ATable.Add('procedure G_Completed(map, position: integer);', @G_Completed);
  ATable.Add('function P_TranslateMap(map: integer): integer;', @P_TranslateMap);
  ATable.Add('function P_GetMapNextMap(map: integer): integer;', @P_GetMapNextMap);
  {$ENDIF}
  {$IFDEF DOOM_OR_HERETIC}
  ATable.Add('procedure G_ExitLevel;', @G_ExitLevel);
  ATable.Add('procedure G_SecretExitLevel;', @G_SecretExitLevel);
  {$ENDIF}
  {$IFDEF STRIFE}
  ATable.Add('procedure G_ExitLevel(dest: integer);', @G_ExitLevel);
  {$ENDIF}
  ps_gameinfo_ref.Describe(ATable);
// ------------------ KEYBOARD CONTROL -----------------------------------------
  ps_keys_ref.Describe(ATable);
// ------------------------------- MAP -----------------------------------------
  ATable.Add('function R_PointToAngle(x: fixed_t; y: fixed_t): angle_t;', @R_PointToAngle);
  ATable.Add('function R_PointToAngle2(const x1: fixed_t; const y1: fixed_t; const x2: fixed_t; const y2: fixed_t): angle_t;', @R_PointToAngle2);
  ATable.Add('function R_PointToDist(const x: fixed_t; const y: fixed_t): fixed_t;', @R_PointToDist);
  ATable.Add('function P_AproxDistance(dx: fixed_t; dy: fixed_t): fixed_t;', @P_AproxDistance);
  ATable.Add('function P_PointOnLineSide(x: fixed_t; y: fixed_t; line: integer): integer;', @PS_P_PointOnLineSide);
  ATable.Add('function R_PointInSector(const x: fixed_t; const y: fixed_t): integer;', @PS_R_PointInSector);
  ATable.Add('function R_PointInSubSector(const x: fixed_t; const y: fixed_t): integer;', @PS_R_PointInSubSector);
// ------------------------------- MAP -----------------------------------------
  ATable.Add('function Ceiling_CrushAndRaise(const tag: integer; const speed: integer; const crush: integer): boolean;', @PS_Ceiling_CrushAndRaise);
  ATable.Add('function Ceiling_CrushRaiseAndStay(const tag: integer; const speed: integer; const crush: integer): boolean;', @PS_Ceiling_CrushRaiseAndStay);
  ATable.Add('function Ceiling_CrushStop(const tag: integer): boolean;', @PS_Ceiling_CrushStop);
  ATable.Add('function Ceiling_LowerAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;', @PS_Ceiling_LowerAndCrush);
  ATable.Add('function Ceiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Ceiling_LowerByValue);
  ATable.Add('function Ceiling_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Ceiling_LowerByValueTimes8);
  ATable.Add('function Ceiling_LowerToFloor(const tag: integer; const speed: integer): boolean;', @PS_Ceiling_LowerToFloor);
  ATable.Add('function Ceiling_LowerToHighestFloor(const tag: integer; const speed: integer): boolean;', @PS_Ceiling_LowerToHighestFloor);
  ATable.Add('function Ceiling_LowerToLowest(const tag: integer; const speed: integer): boolean;', @PS_Ceiling_LowerToLowest);
  ATable.Add('function Ceiling_MoveToValueAndCrush(const tag: integer; const speed: integer; const height: integer; const crush: integer): boolean;', @PS_Ceiling_MoveToValueAndCrush);
  ATable.Add('function Ceiling_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;', @PS_Ceiling_MoveToValue);
  ATable.Add('function Ceiling_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;', @PS_Ceiling_MoveToValueTimes8);
  ATable.Add('function Ceiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Ceiling_RaiseByValue);
  ATable.Add('function Ceiling_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Ceiling_RaiseByValueTimes8);
  ATable.Add('function Ceiling_RaiseToHighestFloor(const tag: integer; const speed: integer): boolean;', @PS_Ceiling_RaiseToHighestFloor);
  ATable.Add('function Door_Close(const tag: integer; const speed: integer): boolean;', @PS_Door_Close);
  ATable.Add('function Door_CloseWaitOpen(const tag: integer; const speed: integer; const delay: integer): boolean;', @PS_Door_CloseWaitOpen);
  ATable.Add('function Door_Open(const tag: integer; const speed: integer): boolean;', @PS_Door_Open);
  ATable.Add('function Door_Raise(const tag: integer; const speed: integer; delay: integer): boolean;', @PS_Door_Raise);
  ATable.Add('function FloorAndCeiling_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_FloorAndCeiling_LowerByValue);
  ATable.Add('function FloorAndCeiling_LowerRaise(const tag: integer; const fspeed, cspeed: integer): boolean;', @PS_FloorAndCeiling_LowerRaise);
  ATable.Add('function FloorAndCeiling_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_FloorAndCeiling_RaiseByValue);
  ATable.Add('function Floor_CrushStop(const tag: integer): boolean;', @PS_Floor_CrushStop);
  ATable.Add('function Floor_LowerByValue(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Floor_LowerByValue);
  ATable.Add('function Floor_LowerByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Floor_LowerByValueTimes8);
  ATable.Add('function Floor_LowerToHighest(const tag: integer; const speed: integer; const adjust: integer): boolean;', @PS_Floor_LowerToHighest);
  ATable.Add('function Floor_LowerToLowestCeiling(const tag: integer; const speed: integer): boolean;', @PS_Floor_LowerToLowestCeiling);
  ATable.Add('function Floor_LowerToLowest(const tag: integer; const speed: integer): boolean;', @PS_Floor_LowerToLowest);
  ATable.Add('function Floor_LowerToNearest(const tag: integer; const speed: integer): boolean;', @PS_Floor_LowerToNearest);
  ATable.Add('function Floor_MoveToValue(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;', @PS_Floor_MoveToValue);
  ATable.Add('function Floor_MoveToValueTimes8(const tag: integer; const speed: integer; const height: integer; const neg: integer): boolean;', @PS_Floor_MoveToValueTimes8);
  ATable.Add('function Floor_RaiseAndCrushDoom(const tag: integer; const speed: integer; const crush: integer): boolean;', @PS_Floor_RaiseAndCrushDoom);
  ATable.Add('function Floor_RaiseAndCrush(const tag: integer; const speed: integer; const crush: integer): boolean;', @PS_Floor_RaiseAndCrush);
  ATable.Add('function Floor_RaiseByTexture(const tag: integer; const speed: integer): boolean;', @PS_Floor_RaiseByTexture);
  ATable.Add('function Floor_RaiseByValue(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Floor_RaiseByValue);
  ATable.Add('function Floor_RaiseByValueTimes8(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Floor_RaiseByValueTimes8);
  ATable.Add('function Floor_RaiseInstant(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Floor_RaiseInstant);
  ATable.Add('function Floor_LowerInstant(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Floor_LowerInstant);
  ATable.Add('function Floor_RaiseToCeilingNoChange(const tag: integer; const speed: integer; const crush: integer; const gap: integer): boolean;', @PS_Floor_RaiseToCeilingNoChange);
  ATable.Add('function Floor_RaiseToHighest(const tag: integer; const speed: integer): boolean;', @PS_Floor_RaiseToHighest);
  ATable.Add('function Floor_RaiseToLowestCeiling(const tag: integer; const speed: integer): boolean;', @PS_Floor_RaiseToLowestCeiling);
  ATable.Add('function Floor_RaiseToNearest(const tag: integer; const speed: integer): boolean;', @PS_Floor_RaiseToNearest);
  ATable.Add('function Floor_ToCeilingInstantNoChange(const tag: integer; const crush: integer; const gap: integer): boolean;', @PS_Floor_ToCeilingInstantNoChange);
  ATable.Add('function Floor_Waggle(const tag: integer; const amp: integer; const freq: integer; const offset: integer; const time: integer): boolean;', @PS_Floor_Waggle);
  ATable.Add('function Light_ChangeToValue(const tag: integer; const value: integer): boolean;', @PS_Light_ChangeToValue);
  ATable.Add('function Light_Fade(const tag: integer; const value: integer; const tics: integer): boolean;', @PS_Light_Fade);
  ATable.Add('function Light_Flicker(const tag: integer; const upper: integer; const lower: integer): boolean;', @PS_Light_Flicker);
  ATable.Add('function Light_ForceLightning: boolean;', @PS_Light_ForceLightning);
  ATable.Add('function Light_ForceLightningTics(const tics: integer): boolean;', @PS_Light_ForceLightningTics);
  ATable.Add('function Light_Glow(const tag: integer; const upper: integer; const lower: integer; const tics: integer): boolean;', @PS_Light_Glow);
  ATable.Add('function Light_LowerByValue(const tag: integer; const value: integer): boolean;', @PS_Light_LowerByValue);
  ATable.Add('function Light_MaxNeighbor(const tag: integer): boolean;', @PS_Light_MaxNeighbor);
  ATable.Add('function Light_MinNeighbor(const tag: integer): boolean;', @PS_Light_MinNeighbor);
  ATable.Add('function Light_RaiseByValue(const tag: integer; const value: integer): boolean;', @PS_Light_RaiseByValue);
  ATable.Add('function Light_Strobe(const tag: integer; const upper: integer; const lower: integer; const utics: integer; const ltics: integer): boolean;', @PS_Light_Strobe);
  ATable.Add('function Light_StrobeDoom(const tag: integer; const utics: integer; const ltics: integer): boolean;', @PS_Light_StrobeDoom);
  ATable.Add('function Pillar_BuildAndCrush(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Pillar_BuildAndCrush);
  ATable.Add('function Pillar_Build(const tag: integer; const speed: integer; const height: integer): boolean;', @PS_Pillar_Build);
  ATable.Add('function Pillar_Open(const tag: integer; const speed: integer; const fdist: integer; const cdist: integer): boolean;', @PS_Pillar_Open);
  ATable.Add('function Plat_DownByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;', @PS_Plat_DownByValue);
  ATable.Add('function Plat_DownWaitUpStay(const tag: integer; const speed: integer; const delay: integer): boolean;', @PS_Plat_DownWaitUpStay);
  ATable.Add('function Plat_DownWaitUpStayLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;', @PS_Plat_DownWaitUpStayLip);
  ATable.Add('function Plat_PerpetualRaise(const tag: integer; const speed: integer; const delay: integer): boolean;', @PS_Plat_PerpetualRaise);
  ATable.Add('function Plat_PerpetualRaiseLip(const tag: integer; const speed: integer; const delay: integer; const lip: integer): boolean;', @PS_Plat_PerpetualRaiseLip);
  ATable.Add('function Plat_UpByValue(const tag: integer; const speed: integer; const delay: integer; const height: integer): boolean;', @PS_Plat_UpByValue);
  ATable.Add('function Plat_UpNearestWaitDownStay (const tag: integer; const speed: integer; const delay: integer): boolean;', @PS_Plat_UpNearestWaitDownStay );
  ATable.Add('function Plat_UpWaitDownStay(const tag: integer; const speed: integer; const delay: integer): boolean;', @PS_Plat_UpWaitDownStay);
  ATable.Add('function Polyobj_DoorSlide(const po: integer; const speed: integer; const angle: integer; const dist: integer; const delay: integer): boolean;', @PS_Polyobj_DoorSlide);
  ATable.Add('function Polyobj_DoorSwing(const po: integer; const speed: integer; const angle: integer; const delay: integer): boolean;', @PS_Polyobj_DoorSwing);
  ATable.Add('function Polyobj_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;', @PS_Polyobj_Move);
  ATable.Add('function Polyobj_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;', @PS_Polyobj_MoveTimes8);
  ATable.Add('function Polyobj_OR_Move(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;', @PS_Polyobj_OR_Move);
  ATable.Add('function Polyobj_OR_MoveTimes8(const po: integer; const speed: integer; const angle: integer; const dist: integer): boolean;', @PS_Polyobj_OR_MoveTimes8);
  ATable.Add('function Polyobj_OR_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;', @PS_Polyobj_OR_RotateLeft);
  ATable.Add('function Polyobj_OR_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;', @PS_Polyobj_OR_RotateRight);
  ATable.Add('function Polyobj_RotateLeft(const po: integer; const speed: integer; const angle: integer): boolean;', @PS_Polyobj_RotateLeft);
  ATable.Add('function Polyobj_RotateRight(const po: integer; const speed: integer; const angle: integer): boolean;', @PS_Polyobj_RotateRight);
end;

//==============================================================================
//
// PS_DescribeOverlayFunctions
// The functions of the unit PS_OVERLAY
//
//==============================================================================
procedure PS_DescribeOverlayFunctions(const ATable: IScriptFunctionTable);
begin
  ATable.Add('procedure OverlayClear;', @PS_OverlayClear);
  ATable.Add('procedure OverlayDrawPatch(const ticks: Integer; const patchname: string; const x, y: Integer);', @PS_OverlayDrawPatch);
  ATable.Add('procedure OverlayDrawPatchStretched(const ticks: Integer; const patchname: string; const x1, y1, x2, y2: Integer);', @PS_OverlayDrawPatchStretched);
  ATable.Add('procedure OverlayDrawPixel(const ticks: Integer; const red, green, blue : byte; const x, y : Integer);', @PS_OverlayDrawPixel);
  ATable.Add('procedure OverlayDrawRect(const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer);', @PS_OverlayDrawRect);
  ATable.Add('procedure OverlayDrawLine(const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer);', @PS_OverlayDrawLine);
  ATable.Add('procedure OverlayDrawText(const ticks: Integer; const txt: string; const align: Integer; const x, y: Integer);', @PS_OverlayDrawText);
  ATable.Add('procedure OverlayDrawLeftText(const ticks: Integer; const txt: string; const x, y: Integer);', @PS_OverlayDrawLeftText);
  ATable.Add('procedure OverlayDrawRightText(const ticks: Integer; const txt: string; const x, y: Integer);', @PS_OverlayDrawRightText);
  ATable.Add('procedure OverlayDrawCenterText(const ticks: Integer; const txt: string; const x, y: Integer);', @PS_OverlayDrawCenterText);
end;

//==============================================================================
//
// PS_InitProcLists
// SYSTEM and PS_FIXED are classes that the composition root has already put in the registry
//
//==============================================================================
procedure PS_InitProcLists;
begin
  PS_ScriptRegistry.AddGroup(TScriptHostFactory.CreateCallbackGroup('PS_GAME', PS_DescribeGameFunctions));
  PS_ScriptRegistry.AddGroup(TScriptHostFactory.CreateCallbackGroup('PS_OVERLAY', PS_DescribeOverlayFunctions));
end;

//==============================================================================
//
// PS_ResetProcLists
//
//==============================================================================
procedure PS_ResetProcLists;
begin
  PS_ScriptRegistry.Reset;
end;

//==============================================================================
//
// PS_ShutDownProcLists
//
//==============================================================================
procedure PS_ShutDownProcLists;
begin
  // PS_GAME and PS_OVERLAY are the ones that PS_InitProcLists added
  if ps_registry_ref <> nil then
  begin
    ps_registry_ref.RemoveGroup('PS_GAME');
    ps_registry_ref.RemoveGroup('PS_OVERLAY');
  end;
end;

//==============================================================================
//
// PS_ScriptOnUses
//
//==============================================================================
function PS_ScriptOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
var
  i: integer;
  lst: TDStringList;
  m: integer;
  uT_integer: TPSType;
  uT_longword: TPSType;
  uT_extended: TPSType;
  LName: string;
  flgcount: LongWord;
{ the OnUses callback function is called for each "uses" in the script.
  It's always called with the parameter 'SYSTEM' at the top of the script.
  For example: uses ii1, ii2;
  This will call this function 3 times. First with 'SYSTEM' then 'II1' and then 'II2'.
}
begin
  if Name = 'SYSTEM' then
  begin
    // Functions
    with Sender.AddClassN(nil, '!TOBJECT') do
    begin
      RegisterMethod('constructor Create');
      RegisterMethod('procedure Free');
    end;
    Sender.AddTypeS('TActorArray', 'array of LongWord');
    Sender.AddTypeS('TIntegerArray', 'array of integer');
    Sender.AddTypeS('TInt64Array', 'array of int64');
    Sender.AddTypeS('TLongWordArray', 'array of LongWord');
    Sender.AddTypeS('TSingleArray', 'array of single');
    Sender.AddTypeS('TFloatArray', 'array of single');
    Sender.AddTypeS('TDoubleArray', 'array of double');
    Sender.AddTypeS('TExtendedArray', 'array of extended');
    Sender.AddTypeS('float', 'single');
    Sender.AddTypeS('real', 'double');
    Sender.AddTypeS('fixed_t', 'integer');
    Sender.AddTypeS('angle_t', 'longword');
    RegisterDateTimeLibrary_C(Sender);
    SIRegister_GlobalVars(Sender);
    SIRegister_Game(Sender);
    SIRegister_TOverlay(Sender);

    PS_ScriptRegistry.RegisterCompiler(string(Name), Sender);

    { This will register the function to the script engine. Now it can be used from within the script. }
    uT_extended := Sender.FindType('extended');
    uT_integer := Sender.FindType('integer');
    uT_longword := Sender.FindType('longword');
    Sender.AddConstant('NaN', uT_extended).Value.textended := 0.0 / 0.0;
    Sender.AddConstant('Infinity', uT_extended).Value.textended := 1.0 / 0.0;
    Sender.AddConstant('NegInfinity', uT_extended).Value.textended := - 1.0 / 0.0;
    Sender.AddConstant('MAXINT', uT_integer).Value.ts32 := MAXINT;

    // Overlay drawing
    Sender.AddConstant('alLeft', uT_integer).Value.ts32 := OVR_ALIGN_LEFT;
    Sender.AddConstant('alRight', uT_integer).Value.ts32 := OVR_ALIGN_RIGHT;
    Sender.AddConstant('alCenter', uT_integer).Value.ts32 := OVR_ALIGN_CENTER;

    // mobj flags
    flgcount := 0;
    for i := 0 to mobj_flags.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;

    {$IFDEF HERETIC_OR_HEXEN}
    // mobj flags2
    flgcount := 32;
    for i := 0 to mobj_flags2.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags2[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;
    {$ENDIF}

    // mobj flags_ex
    flgcount := 64;
    for i := 0 to mobj_flags_ex.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags_ex[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;

    // mobj flags2_ex
    flgcount := 96;
    for i := 0 to mobj_flags2_ex.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags2_ex[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;

    // mobj flags3_ex
    flgcount := 128;
    for i := 0 to mobj_flags3_ex.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags3_ex[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;

    // mobj flags4_ex
    flgcount := 160;
    for i := 0 to mobj_flags4_ex.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags4_ex[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;

    // mobj flags5_ex
    flgcount := 192;
    for i := 0 to mobj_flags5_ex.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags5_ex[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;

    // mobj flags6_ex
    flgcount := 224;
    for i := 0 to mobj_flags6_ex.Count - 1 do
    begin
      Sender.AddConstant(mobj_flags6_ex[i], uT_longword).Value.tu32 := flgcount;
      Inc(flgcount);
    end;

    // states
    lst := statenames.AllTokensWithIndex;
    for i := 0 to lst.Count - 1 do
    begin
      Sender.AddConstant(lst[i], uT_integer).Value.ts32 := (lst.Objects[i] as TInteger).intnum;
      (lst.Objects[i] as TInteger).Free;
    end;
    lst.Free;

    // mobj types
    for m := 0 to Ord(DO_NUMMOBJTYPES) - 1 do
      Sender.AddConstant(GetENumName(TypeInfo(mobjtype_t), m), uT_integer).Value.ts32 := m;

    // consts doomdef
    Sender.AddConstant('MAXPLAYERS', uT_integer).Value.ts32 := MAXPLAYERS;

    for m := 0 to Ord(sk_nightmare) do
      Sender.AddConstant(GetENumName(TypeInfo(skill_t), m), uT_integer).Value.ts32 := m;

    {$IFDEF DOOM_OR_STRIFE}
    for m := 0 to Ord(NUMCARDS) do
      Sender.AddConstant(GetENumName(TypeInfo(card_t), m), uT_integer).Value.ts32 := m;
    {$ELSE}
    for m := 0 to Ord(NUMKEYCARDS) do
      Sender.AddConstant(GetENumName(TypeInfo(keytype_t), m), uT_integer).Value.ts32 := m;
    {$ENDIF}

    {$IFDEF HEXEN}
    for m := 0 to Ord(NUMCLASSES) do
      Sender.AddConstant(GetENumName(TypeInfo(pclass_t), m), uT_integer).Value.ts32 := m;
    {$ENDIF}

    for m := 0 to Ord(NUMWEAPONS) do
      Sender.AddConstant(GetENumName(TypeInfo(weapontype_t), m), uT_integer).Value.ts32 := m;

    for m := 0 to Ord(NUMMOBJRENDERSTYLES) do
      Sender.AddConstant(GetENumName(TypeInfo(mobjrenderstyle_t), m), uT_integer).Value.ts32 := m;

    for m := 0 to Ord(NUMGENDERS) do
      Sender.AddConstant(GetENumName(TypeInfo(gender_t), m), uT_integer).Value.ts32 := m;

    {$IFDEF HEXEN}
    for m := 0 to Ord(NUMMANA) do
      Sender.AddConstant(GetENumName(TypeInfo(manatype_t), m), uT_integer).Value.ts32 := m;
    Sender.AddConstant('MAX_MANA', uT_integer).Value.ts32 := MAX_MANA;
    {$ELSE}
    for m := 0 to Ord(NUMAMMO) do
      Sender.AddConstant(GetENumName(TypeInfo(ammotype_t), m), uT_integer).Value.ts32 := m;
    {$ENDIF}

    for m := 0 to Ord(NUMPOWERS) do
      Sender.AddConstant(GetENumName(TypeInfo(powertype_t), m), uT_integer).Value.ts32 := m;

    {$IFDEF HERETIC_OR_HEXEN}
    for m := 0 to Ord(NUMARTIFACTS) do
      Sender.AddConstant(GetENumName(TypeInfo(artitype_t), m), uT_integer).Value.ts32 := m;
    {$ENDIF}

    {$IFDEF HEXEN}
    Sender.AddConstant('arti_firstpuzzitem', uT_integer).Value.ts32 := arti_firstpuzzitem;
    {$ENDIF}

    {$IFDEF STRIFE}
    for m := 0 to Ord(tk_numquests) do
      Sender.AddConstant(GetENumName(TypeInfo(questtype_t), m), uT_integer).Value.ts32 := m;

    Sender.AddConstant('QF_QUEST1', uT_longword).Value.tu32 := QF_QUEST1;
    Sender.AddConstant('QF_QUEST2', uT_longword).Value.tu32 := QF_QUEST2;
    Sender.AddConstant('QF_QUEST3', uT_longword).Value.tu32 := QF_QUEST3;
    Sender.AddConstant('QF_QUEST4', uT_longword).Value.tu32 := QF_QUEST4;
    Sender.AddConstant('QF_QUEST5', uT_longword).Value.tu32 := QF_QUEST5;
    Sender.AddConstant('QF_QUEST6', uT_longword).Value.tu32 := QF_QUEST6;
    Sender.AddConstant('QF_QUEST7', uT_longword).Value.tu32 := QF_QUEST7;
    Sender.AddConstant('QF_QUEST8', uT_longword).Value.tu32 := QF_QUEST8;
    Sender.AddConstant('QF_QUEST9', uT_longword).Value.tu32 := QF_QUEST9;
    Sender.AddConstant('QF_QUEST10', uT_longword).Value.tu32 := QF_QUEST10;
    Sender.AddConstant('QF_QUEST11', uT_longword).Value.tu32 := QF_QUEST11;
    Sender.AddConstant('QF_QUEST12', uT_longword).Value.tu32 := QF_QUEST12;
    Sender.AddConstant('QF_QUEST13', uT_longword).Value.tu32 := QF_QUEST13;
    Sender.AddConstant('QF_QUEST14', uT_longword).Value.tu32 := QF_QUEST14;
    Sender.AddConstant('QF_QUEST15', uT_longword).Value.tu32 := QF_QUEST15;
    Sender.AddConstant('QF_QUEST16', uT_longword).Value.tu32 := QF_QUEST16;
    Sender.AddConstant('QF_QUEST17', uT_longword).Value.tu32 := QF_QUEST17;
    Sender.AddConstant('QF_QUEST18', uT_longword).Value.tu32 := QF_QUEST18;
    Sender.AddConstant('QF_QUEST19', uT_longword).Value.tu32 := QF_QUEST19;
    Sender.AddConstant('QF_QUEST20', uT_longword).Value.tu32 := QF_QUEST20;
    Sender.AddConstant('QF_QUEST21', uT_longword).Value.tu32 := QF_QUEST21;
    Sender.AddConstant('QF_QUEST22', uT_longword).Value.tu32 := QF_QUEST22;
    Sender.AddConstant('QF_QUEST23', uT_longword).Value.tu32 := QF_QUEST23;
    Sender.AddConstant('QF_QUEST24', uT_longword).Value.tu32 := QF_QUEST24;
    Sender.AddConstant('QF_QUEST25', uT_longword).Value.tu32 := QF_QUEST25;
    Sender.AddConstant('QF_QUEST26', uT_longword).Value.tu32 := QF_QUEST26;
    Sender.AddConstant('QF_QUEST27', uT_longword).Value.tu32 := QF_QUEST27;
    Sender.AddConstant('QF_QUEST28', uT_longword).Value.tu32 := QF_QUEST28;
    Sender.AddConstant('QF_QUEST29', uT_longword).Value.tu32 := QF_QUEST29;
    Sender.AddConstant('QF_QUEST30', uT_longword).Value.tu32 := QF_QUEST30;
    Sender.AddConstant('QF_QUEST31', uT_longword).Value.tu32 := QF_QUEST31;
    Sender.AddConstant('QF_ALLQUESTS', uT_longword).Value.tu32 := QF_ALLQUESTS;
    {$ENDIF}

    // consts p_local
    Sender.AddConstant('ONFLOORZ', uT_integer).Value.ts32 := ONFLOORZ;
    Sender.AddConstant('FLOORZ', uT_integer).Value.ts32 := ONFLOORZ;
    Sender.AddConstant('ONCEILINGZ', uT_integer).Value.ts32 := ONCEILINGZ;
    Sender.AddConstant('CEILINGZ', uT_integer).Value.ts32 := ONCEILINGZ;
    Sender.AddConstant('ONFLOATZ', uT_integer).Value.ts32 := {$IFDEF HEXEN}FLOATRANDZ{$ELSE}ONFLOATZ{$ENDIF};
    Sender.AddConstant('FLOATZ', uT_integer).Value.ts32 := {$IFDEF HEXEN}FLOATRANDZ{$ELSE}ONFLOATZ{$ENDIF};
    {$IFDEF HEXEN}
    Sender.AddConstant('FLOATRANDZ', uT_integer).Value.ts32 := FLOATRANDZ;
    {$ENDIF}
    Sender.AddConstant('TICRATE', uT_integer).Value.ts32 := TICRATE;
    Sender.AddConstant('FRACUNIT', uT_integer).Value.ts32 := FRACUNIT;
    Sender.AddConstant('ACTOR_INVALID', uT_integer).Value.ts32 := ACTOR_INVALID;
    Sender.AddConstant('PLAYER_INVALID', uT_integer).Value.ts32 := PLAYER_INVALID;
    Sender.AddConstant('MOBJTYPE_INVALID', uT_integer).Value.ts32 := MOBJTYPE_INVALID;
    Sender.AddConstant('STATE_INVALID', uT_integer).Value.ts32 := STATE_INVALID;
    Sender.AddConstant('EDITORNUMBER_INVALID', uT_integer).Value.ts32 := EDITORNUMBER_INVALID;
    Sender.AddConstant('EDITORNUMBER_UNKNOWN', uT_integer).Value.ts32 := EDITORNUMBER_UNKNOWN;
    Sender.AddConstant('TEXTURE_INVALID', uT_integer).Value.ts32 := TEXTURE_INVALID;
    Sender.AddConstant('FLAT_INVALID', uT_integer).Value.ts32 := FLAT_INVALID;
    Sender.AddConstant('SECTOR_INVALID', uT_integer).Value.ts32 := SECTOR_INVALID;
    Sender.AddConstant('LINE_INVALID', uT_integer).Value.ts32 := LINE_INVALID;
    Sender.AddConstant('SIDE_INVALID', uT_integer).Value.ts32 := SIDE_INVALID;
    Sender.AddConstant('VERTEX_INVALID', uT_integer).Value.ts32 := VERTEX_INVALID;
    Sender.AddConstant('LIGHTLEVEL_INVALID', uT_integer).Value.ts32 := LIGHTLEVEL_INVALID;

    // consts tables
    Sender.AddConstant('D_PI', uT_extended).Value.textended := D_PI;
    Sender.AddConstant('ANGLE_T_TO_RAD', uT_extended).Value.textended := ANGLE_T_TO_RAD;
    Sender.AddConstant('ANGLETOFINESHIFT', uT_longword).Value.tu32 := ANGLETOFINESHIFT;
    Sender.AddConstant('ANGLETOFINEUNIT', uT_longword).Value.tu32 := ANGLETOFINEUNIT;
    Sender.AddConstant('FINEANGLES', uT_longword).Value.tu32 := FINEANGLES;
    Sender.AddConstant('FINEMASK', uT_longword).Value.tu32 := FINEMASK;
    Sender.AddConstant('DIR256ANGLES', uT_longword).Value.tu32 := DIR256ANGLES;
    Sender.AddConstant('DIR256TOANGLEUNIT', uT_longword).Value.tu32 := DIR256TOANGLEUNIT;
    Sender.AddConstant('DIR256TOANGLESHIFT', uT_longword).Value.tu32 := DIR256TOANGLESHIFT;
    Sender.AddConstant('ANG1', uT_longword).Value.tu32 := ANG1;
{    for i := 2 to 4 do
      Sender.AddConstant('ANG' + itoa(i), uT_longword).Value.tu32 := ANG1 * i;}
    Sender.AddConstant('ANG5', uT_longword).Value.tu32 := ANG5;
    Sender.AddConstant('ANG30', uT_longword).Value.tu32 := ANG60 div 2;
    Sender.AddConstant('ANG45', uT_longword).Value.tu32 := ANG45;
    Sender.AddConstant('ANG60', uT_longword).Value.tu32 := ANG60;
    Sender.AddConstant('ANG90', uT_longword).Value.tu32 := ANG90;
    Sender.AddConstant('ANG120', uT_longword).Value.tu32 := ANG120;
    Sender.AddConstant('ANG180', uT_longword).Value.tu32 := ANG180;
    Sender.AddConstant('ANG240', uT_longword).Value.tu32 := ANG240;
    Sender.AddConstant('ANG270', uT_longword).Value.tu32 := ANG270;
    Sender.AddConstant('ANG300', uT_longword).Value.tu32 := ANG300;
    Sender.AddConstant('ANG315', uT_longword).Value.tu32 := ANG315;
    Sender.AddConstant('ANG355', uT_longword).Value.tu32 := ANG355;
    Sender.AddConstant('ANGLE_MAX', uT_longword).Value.tu32 := ANGLE_MAX;
    Sender.AddConstant('SLOPEBITS', uT_longword).Value.tu32 := SLOPEBITS;
    Sender.AddConstant('SLOPERANGE', uT_longword).Value.tu32 := SLOPERANGE;
    Sender.AddConstant('DBITS', uT_longword).Value.tu32 := DBITS;
    Sender.AddConstant('DRANGE', uT_longword).Value.tu32 := DRANGE;

    // Generalized constants
    Sender.AddConstant('DAMAGE_MASK', uT_integer).Value.ts32 := $60;
    Sender.AddConstant('DAMAGE_SHIFT', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('SECRET_MASK', uT_integer).Value.ts32 := $80;
    Sender.AddConstant('SECRET_SHIFT', uT_integer).Value.ts32 := 7;
    Sender.AddConstant('FRICTION_MASK', uT_integer).Value.ts32 := $100;
    Sender.AddConstant('FRICTION_SHIFT', uT_integer).Value.ts32 := 8;
    Sender.AddConstant('PUSH_MASK', uT_integer).Value.ts32 := $200;
    Sender.AddConstant('PUSH_SHIFT', uT_integer).Value.ts32 := 9;

    Sender.AddConstant('CGENFLOORBASE', uT_integer).Value.ts32 := $6000;
    Sender.AddConstant('CGENCEILINGBASE', uT_integer).Value.ts32 := $4000;
    Sender.AddConstant('CGENDOORBASE', uT_integer).Value.ts32 := $3C00;
    Sender.AddConstant('CGENLOCKEDBASE', uT_integer).Value.ts32 := $3800;
    Sender.AddConstant('CGENLIFTBASE', uT_integer).Value.ts32 := $3400;
    Sender.AddConstant('CGENSTAIRSBASE', uT_integer).Value.ts32 := $3000;
    Sender.AddConstant('CGENCRUSHERBASE', uT_integer).Value.ts32 := $2F80;

    Sender.AddConstant('TriggerType', uT_integer).Value.ts32 := $0007;
    Sender.AddConstant('TriggerTypeShift', uT_integer).Value.ts32 := 0;

    Sender.AddConstant('gen_FloorCrush', uT_integer).Value.ts32 := $1000;
    Sender.AddConstant('gen_FloorChange', uT_integer).Value.ts32 := $0C00;
    Sender.AddConstant('gen_FloorTarget', uT_integer).Value.ts32 := $0380;
    Sender.AddConstant('gen_FloorDirection', uT_integer).Value.ts32 := $0040;
    Sender.AddConstant('gen_FloorModel', uT_integer).Value.ts32 := $0020;
    Sender.AddConstant('gen_FloorSpeed', uT_integer).Value.ts32 := $0018;

    Sender.AddConstant('FloorCrushShift', uT_integer).Value.ts32 := 12;
    Sender.AddConstant('FloorChangeShift', uT_integer).Value.ts32 := 10;
    Sender.AddConstant('FloorTargetShift', uT_integer).Value.ts32 := 7;
    Sender.AddConstant('FloorDirectionShift', uT_integer).Value.ts32 := 6;
    Sender.AddConstant('FloorModelShift', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('FloorSpeedShift', uT_integer).Value.ts32 := 3;

    Sender.AddConstant('CeilingCrush', uT_integer).Value.ts32 := $1000;
    Sender.AddConstant('CeilingChange', uT_integer).Value.ts32 := $0C00;
    Sender.AddConstant('CeilingTarget', uT_integer).Value.ts32 := $0380;
    Sender.AddConstant('CeilingDirection', uT_integer).Value.ts32 := $0040;
    Sender.AddConstant('CeilingModel', uT_integer).Value.ts32 := $0020;
    Sender.AddConstant('CeilingSpeed', uT_integer).Value.ts32 := $0018;

    Sender.AddConstant('CeilingCrushShift', uT_integer).Value.ts32 := 12;
    Sender.AddConstant('CeilingChangeShift', uT_integer).Value.ts32 := 10;
    Sender.AddConstant('CeilingTargetShift', uT_integer).Value.ts32 := 7;
    Sender.AddConstant('CeilingDirectionShift', uT_integer).Value.ts32 := 6;
    Sender.AddConstant('CeilingModelShift', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('CeilingSpeedShift', uT_integer).Value.ts32 := 3;

    Sender.AddConstant('LiftTarget', uT_integer).Value.ts32 := $0300;
    Sender.AddConstant('LiftDelay', uT_integer).Value.ts32 := $00C0;
    Sender.AddConstant('LiftMonster', uT_integer).Value.ts32 := $0020;
    Sender.AddConstant('LiftSpeed', uT_integer).Value.ts32 := $0018;

    Sender.AddConstant('LiftTargetShift', uT_integer).Value.ts32 := 8;
    Sender.AddConstant('LiftDelayShift', uT_integer).Value.ts32 := 6;
    Sender.AddConstant('LiftMonsterShift', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('LiftSpeedShift', uT_integer).Value.ts32 := 3;

    Sender.AddConstant('StairIgnore', uT_integer).Value.ts32 := $0200;
    Sender.AddConstant('StairDirection', uT_integer).Value.ts32 := $0100;
    Sender.AddConstant('StairStep', uT_integer).Value.ts32 := $00c0;
    Sender.AddConstant('StairMonster', uT_integer).Value.ts32 := $0020;
    Sender.AddConstant('StairSpeed', uT_integer).Value.ts32 := $0018;

    Sender.AddConstant('StairIgnoreShift', uT_integer).Value.ts32 := 9;
    Sender.AddConstant('StairDirectionShift', uT_integer).Value.ts32 := 8;
    Sender.AddConstant('StairStepShift', uT_integer).Value.ts32 := 6;
    Sender.AddConstant('StairMonsterShift', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('StairSpeedShift', uT_integer).Value.ts32 := 3;

    Sender.AddConstant('CrusherSilent', uT_integer).Value.ts32 := $0040;
    Sender.AddConstant('CrusherMonster', uT_integer).Value.ts32 := $0020;
    Sender.AddConstant('CrusherSpeed', uT_integer).Value.ts32 := $0018;

    Sender.AddConstant('CrusherSilentShift', uT_integer).Value.ts32 := 6;
    Sender.AddConstant('CrusherMonsterShift', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('CrusherSpeedShift', uT_integer).Value.ts32 := 3;

    Sender.AddConstant('DoorDelay', uT_integer).Value.ts32 := $0300;
    Sender.AddConstant('DoorMonster', uT_integer).Value.ts32 := $0080;
    Sender.AddConstant('DoorKind', uT_integer).Value.ts32 := $0060;
    Sender.AddConstant('DoorSpeed', uT_integer).Value.ts32 := $0018;

    Sender.AddConstant('DoorDelayShift', uT_integer).Value.ts32 := 8;
    Sender.AddConstant('DoorMonsterShift', uT_integer).Value.ts32 := 7;
    Sender.AddConstant('DoorKindShift', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('DoorSpeedShift', uT_integer).Value.ts32 := 3;

    Sender.AddConstant('LockedNKeys', uT_integer).Value.ts32 := $0200;
    Sender.AddConstant('LockedKey', uT_integer).Value.ts32 := $01c0;
    Sender.AddConstant('LockedKind', uT_integer).Value.ts32 := $0020;
    Sender.AddConstant('LockedSpeed', uT_integer).Value.ts32 := $0018;

    Sender.AddConstant('LockedNKeysShift', uT_integer).Value.ts32 := 9;
    Sender.AddConstant('LockedKeyShift', uT_integer).Value.ts32 := 6;
    Sender.AddConstant('LockedKindShift', uT_integer).Value.ts32 := 5;
    Sender.AddConstant('LockedSpeedShift', uT_integer).Value.ts32 := 3;

    // MBF21 groups
    // infighting groups
    Sender.AddConstant('IG_INVALID', uT_integer).Value.ts32 := IG_INVALID;
    for i := 0 to infighting_groups.Count - 1 do
      Sender.AddConstant(infighting_groups.Strings[i], uT_integer).Value.ts32 := i;
    Sender.AddConstant('IG_END', uT_integer).Value.ts32 := IG_END;

    // projectile groups
    Sender.AddConstant('PG_INVALID', uT_integer).Value.ts32 := PG_INVALID;
    Sender.AddConstant('PG_GROUPLESS', uT_integer).Value.ts32 := PG_GROUPLESS;
    for i := 0 to projectile_groups.Count - 1 do
      Sender.AddConstant(projectile_groups.Strings[i], uT_integer).Value.ts32 := i;
    Sender.AddConstant('PG_END', uT_integer).Value.ts32 := PG_END;

    // Splash groups
    Sender.AddConstant('SG_INVALID', uT_integer).Value.ts32 := SG_INVALID;
    for i := 0 to splash_groups.Count - 1 do
      Sender.AddConstant(splash_groups.Strings[i], uT_integer).Value.ts32 := i;
    Sender.AddConstant('SG_END', uT_integer).Value.ts32 := SG_END;

    // MBF21 Weapon Flags
    Sender.AddConstant('WPF_NOFLAG', uT_integer).Value.ts32 := WPF_NOFLAG;
    Sender.AddConstant('WPF_NOTHRUST', uT_integer).Value.ts32 := WPF_NOTHRUST;
    Sender.AddConstant('WPF_SILENT', uT_integer).Value.ts32 := WPF_SILENT;
    Sender.AddConstant('WPF_NOAUTOFIRE', uT_integer).Value.ts32 := WPF_NOAUTOFIRE;
    Sender.AddConstant('WPF_FLEEMELEE', uT_integer).Value.ts32 := WPF_FLEEMELEE;
    Sender.AddConstant('WPF_AUTOSWITCHFROM', uT_integer).Value.ts32 := WPF_AUTOSWITCHFROM;
    Sender.AddConstant('WPF_NOAUTOSWITCHTO', uT_integer).Value.ts32 := WPF_NOAUTOSWITCHTO;

    Result := True;
  end
  else if Name = 'ALL' then
  begin
    for LName in PS_ScriptRegistry.CompilerUnitNames do
      PS_ScriptOnUses(Sender, TbtString(LName));
    Result := True;
  end
  else
  begin
    if PS_ScriptRegistry.RegisterCompiler(string(Name), Sender) then
    begin
      Result := True;
    end
    else
    begin
      Sender.MakeError('', ecUnknownIdentifier, '');
      Result := False;
    end;
  end;

  if Result then
    (Sender as TDoomCompiler).unitnames.Add(Name);
end;

// **** TDoomCompiler ****
var
  dccnt: integer = 0;

//==============================================================================
//
// CompTranslateLineInfo
//
//==============================================================================
procedure CompTranslateLineInfo(Sender: TPSPascalCompiler; var Pos, Row, Col: Cardinal; var Name: TbtString);
var
  res: TPSLineInfoResults;
begin
  if TDoomCompiler(Sender).FPP.CurrentLineInfo.GetLineInfo(Name, Pos, Res) then
  begin
    Pos := Res.Pos;
    Row := Res.Row;
    Col := Res.Col;
    Name := Res.Name;
  end;
end;

procedure callObjectOnProcessDirective (
  Sender: TPSPreProcessor;
  Parser: TPSPascalPreProcessorParser;
  const Active: Boolean;
  const DirectiveName, DirectiveParam: TbtString;
  var Continue: Boolean);
begin
end;

procedure callObjectOnProcessUnknowDirective (
  Sender: TPSPreProcessor;
  Parser: TPSPascalPreProcessorParser;
  const Active: Boolean;
  const DirectiveName, DirectiveParam: TbtString;
  var Continue: Boolean);
begin
end;

//==============================================================================
//
// FPPNeedFile
//
//==============================================================================
function FPPNeedFile(Sender: TPSPreProcessor; const callingfilename: TbtString; var FileName, Output: TbtString): Boolean;
begin
  Output := PAK_ReadFileAsString(FileName);
  Result := Output <> '';
end;

//==============================================================================
//
// TDoomCompiler.CreateDoomCompiler
//
//==============================================================================
constructor TDoomCompiler.CreateDoomCompiler;
begin
  if dccnt <> 0 then
    I_Error('TDoomCompiler.CreateDoomCompiler(): Compiler is already active!');

  Inc(dccnt);

  inherited Create(@DefaultLookupTable, DEFAULT_KEYWORD_COUNT);
  OnUses := PS_ScriptOnUses;
  OnExternalProc := DllExternalProc;
  AllowNoEnd := true;

  FPP := TPSPreProcessor.Create;
  FPP.Id := Self;
  FPP.OnNeedFile := FPPNeedFile;

  funitnames := TDStringList.Create;
end;

//==============================================================================
//
// TDoomCompiler.Destroy
//
//==============================================================================
destructor TDoomCompiler.Destroy;
begin
  Dec(dccnt);
  FPP.Free;
  funitnames.Free;

  inherited;
end;

//==============================================================================
//
// TDoomCompiler.CompileDoomScript
//
//==============================================================================
function TDoomCompiler.CompileDoomScript(const source: TbtString; var pcode: TbtString): Boolean;
var
  ppsrc: TbtString;
  ppout: TbtString;
  unitstr: TbtString;
  len: integer;
begin
  PS_ResetProcLists;

  FPP.Clear;

  FPP.Defines.Add(strupper(_GAME));
  {$IFDEF DEBUG}
  FPP.Defines.Add('DEBUG');
  {$ENDIF}
  if devparm then
    FPP.Defines.Add('DEVPARM');

  {$IFDEF DOOM}
  FPP.Defines.Add('DOOM_OR_HERETIC');
  FPP.Defines.Add('DOOM_OR_HEXEN');
  FPP.Defines.Add('DOOM_OR_STRIFE');
  FPP.Defines.Add('HERETIC_OR_DOOM');
  FPP.Defines.Add('HEXEN_OR_DOOM');
  FPP.Defines.Add('STRIFE_OR_DOOM');
  {$ENDIF}

  {$IFDEF HERETIC}
  FPP.Defines.Add('HERETIC_OR_DOOM');
  FPP.Defines.Add('HERETIC_OR_HEXEN');
  FPP.Defines.Add('HERETIC_OR_STRIFE');
  FPP.Defines.Add('DOOM_OR_HERETIC');
  FPP.Defines.Add('HEXEN_OR_HERETIC');
  FPP.Defines.Add('STRIFE_OR_HERETIC');
  {$ENDIF}

  {$IFDEF HEXEN}
  FPP.Defines.Add('HEXEN_OR_DOOM');
  FPP.Defines.Add('HEXEN_OR_HERETIC');
  FPP.Defines.Add('HEXEN_OR_STRIFE');
  FPP.Defines.Add('DOOM_OR_HEXEN');
  FPP.Defines.Add('HERETIC_OR_HEXEN');
  FPP.Defines.Add('STRIFE_OR_HEXEN');
  {$ENDIF}

  {$IFDEF STRIFE}
  FPP.Defines.Add('STRIFE_OR_DOOM');
  FPP.Defines.Add('STRIFE_OR_HERETIC');
  FPP.Defines.Add('STRIFE_OR_HEXEN');
  FPP.Defines.Add('DOOM_OR_STRIFE');
  FPP.Defines.Add('HERETIC_OR_STRIFE');
  FPP.Defines.Add('HEXEN_OR_STRIFE');
  {$ENDIF}

  {$IFDEF OPENGL}
  FPP.Defines.Add('OPENGL');
  {$ENDIF}

  OnTranslateLineInfo := CompTranslateLineInfo;
  FPP.OnProcessDirective := callObjectOnProcessDirective;
  FPP.OnProcessUnknowDirective := callObjectOnProcessUnknowDirective;
  FPP.MainFile := source;
  FPP.MainFileName := '';
  FPP.PreProcess(FPP.MainFileName, ppsrc);

  funitnames.Clear;

  Result := Compile(ppsrc);

  if Result then
    GetOutput(ppout)
  else
    ppout := '';

  unitstr := _GAME + #13#10 + funitnames.Text;
  len := Length(unitstr);
  pcode := '            ' + unitstr + ppout;
  PLongWord(@pcode[1])^ := ID_DDPS;
  PLongWord(@pcode[5])^ := DDCVERSION;
  PLongWord(@pcode[9])^ := len;

  FPP.AdjustMessages(Self);
end;

//==============================================================================
// TDoomExec.CreateDoomExec
//
// **** TDoomExec ****
//
//==============================================================================
constructor TDoomExec.CreateDoomExec(const aImporter: TPSRuntimeClassImporter);
begin
  inherited Create;
  AllowNullClasses := True;
  RegisterDLLRuntime(Self);
  RegisterClassLibraryRuntime(Self, aImporter);
  RegisterDateTimeLibrary_R(Self);
end;

//==============================================================================
//
// TDoomExec.LoadData
//
//==============================================================================
function TDoomExec.LoadData(const pcode: TbtString): Boolean;
var
  dta: TbtString;
  unitstr: TbtString;
  len: integer;
  ver: integer;
  i, x: integer;
  lst: TStringList;

  function RegisterRTLUnit(const s: string): boolean;
  begin
    if PS_ScriptRegistry.RegisterExecutor(s, Self) then
    begin
      Result := True;
    end
    else if s = 'ALL' then
    begin
      PS_ScriptRegistry.RegisterExecutorForAll(Self);
      Result := True;
    end
    else
    begin
      I_Warning('RegisterRTLUnit(): Unknown RTL unit %s'#13#10, [s]);
      Result := False;
    end;
  end;

begin
  len := Length(pcode);
  if len < 4 then
  begin
    Result := False;
    Exit;
  end;

  if PLongWord(@pcode[1])^ <> ID_DDPS then
  begin
    RegisterRTLUnit('SYSTEM');
    Result := inherited LoadData(pcode);
    Exit;
  end;

  if len < 16 then
  begin
    Result := False;
    Exit;
  end;

  ver := PLongWord(@pcode[5])^;
  if ver <> DDCVERSION then
  begin
    Result := False;
    Exit;
  end;

  x := PLongWord(@pcode[9])^;
  if len < 12 + x then
  begin
    Result := False;
    Exit;
  end;

  SetLength(unitstr, x);
  for i := 1 to x do
    unitstr[i] := pcode[i + 12];

  lst := TStringList.Create;
  lst.Text := unitstr;

  if lst.Count < 2 then
  begin
    lst.Free;
    Result := False;
    Exit;
  end;

  if lst.Strings[0] <> _GAME then
  begin
    I_Warning('TDoomExec.LoadData(): Can not load "%s" compiled script while playing "%s"'#13#10, [lst.Strings[0], _GAME]);
    lst.Free;
    Result := False;
    Exit;
  end;

  for i := 1 to lst.Count - 1 do
    RegisterRTLUnit(lst.Strings[i]);
  lst.Free;

  dta := Copy(pcode, x + 13, len - x - 12);
  Result := inherited LoadData(dta);

  if Result then
  begin
    // JVAL: Must be called after TPSExec.LoadData()
    RIRegisterRTL_GlobalVars(Self);
    RIRegisterRTL_Game(Self);
    RIRegisterRTL_TOverlay(Self);
  end;
end;

type
  TRTLObject = class(TObject)
  public
    procedure FakeFree;
  end;

//==============================================================================
//
// TRTLObject.FakeFree
//
//==============================================================================
procedure TRTLObject.FakeFree;
begin
  // JVAL: Do nothing :)
  // Explanation:
  //   Since we can only use imported classes usage of Free procedure inside
  //   script could cause problems. Instead we use a stub method, and we leave
  //   the actual Free of the objects to the calling Application.
end;

//==============================================================================
//
// TPSDoomRuntimeClassImporter.Create
//
//==============================================================================
constructor TPSDoomRuntimeClassImporter.Create;
begin
  inherited;
  with Add2(TRTLObject, '!TOBJECT') do
  begin
    RegisterConstructor(@TRTLObject.Create, 'Create');
    RegisterMethod(@TRTLObject.FakeFree, 'Free');
  end;
  RIRegister_GlobalVars(Self);
  RIRegister_Game(Self);
  RIRegister_TOverlay(Self);
end;

end.

