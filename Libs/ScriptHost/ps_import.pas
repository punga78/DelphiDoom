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
  DelphiDoom.ScriptHost.Classes.Intf,
  DelphiDoom.ScriptHost.Constants.Intf,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.Services.Intf;

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
    FServices: IScriptHostServices;
  public
    /// <summary>With the services given to PS_ConfigureHostServices</summary>
    constructor CreateDoomCompiler; overload; virtual;
    constructor CreateDoomCompiler(const AServices: IScriptHostServices); overload; virtual;
    property Services: IScriptHostServices read FServices;
    function CompileDoomScript(const source: TbtString; var pcode: TbtString): Boolean; virtual;
    destructor Destroy; override;
    property unitnames: TDStringList read funitnames;
  end;

  TDoomExec = class(TPSExec)
  private
    FServices: IScriptHostServices;
  public
    /// <summary>
    ///   The services are the ones of the importer (TPSDoomRuntimeClassImporter) or, if AServices is nil
    ///   and the importer is another one, the ones given to PS_ConfigureHostServices
    /// </summary>
    constructor CreateDoomExec(const aImporter: TPSRuntimeClassImporter;
      const AServices: IScriptHostServices = nil); virtual;
    property Services: IScriptHostServices read FServices;
    function LoadData(const pcode: TbtString): Boolean; override;
  end;

  TPSDoomRuntimeClassImporter = class(TPSRuntimeClassImporter)
  private
    FServices: IScriptHostServices;
  public
    constructor CreateDoomImporter(const AServices: IScriptHostServices); virtual;
    property Services: IScriptHostServices read FServices;
  end;

const
  ID_DDPS = 1397769284; // 'DDPS'

//==============================================================================
//
// PS_ConfigureHostServices
// What the compiler and the interpreter of the scripts use (the functions, the
// classes and the constants that scripts see, the files they include, the game):
// given by the composition root. The catalog of the classes is filled here with
// the tables of the units psi_globals and psi_game
//
//==============================================================================
procedure PS_ConfigureHostServices(const AServices: IScriptHostServices);

//==============================================================================
//
// PS_HostServices
//
//==============================================================================
function PS_HostServices: IScriptHostServices;

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
  ps_services_ref: IScriptHostServices = nil;
  ps_gameinfo_ref: IScriptFunctionSection = nil;
  ps_textures_ref: IScriptFunctionSection = nil;
  ps_keys_ref: IScriptFunctionSection = nil;

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
// PS_ConfigureHostServices
//
//==============================================================================
procedure PS_ConfigureHostServices(const AServices: IScriptHostServices);
begin
  ps_services_ref := AServices;
  if AServices <> nil then
  begin
    // the order of the registration of the compiler: the variables, then the game
    PS_DescribeGlobalClasses(AServices.Classes);
    PS_DescribeGameClasses(AServices.Classes);
  end;
end;

//==============================================================================
//
// PS_HostServices
//
//==============================================================================
function PS_HostServices: IScriptHostServices;
begin
  if ps_services_ref = nil then
    I_Error('PS_ConfigureHostServices() was not called: the services of the scripts are missing');
  Result := ps_services_ref;
end;

//==============================================================================
//
// PS_ScriptRegistry
//
//==============================================================================
function PS_ScriptRegistry: IScriptFunctionRegistry;
begin
  Result := PS_HostServices.Registry;
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
  PS_Actors.Describe(ATable);
  ATable.Add('function MergeActorArrays(const A1, A2: TActorArray): TActorArray;', @PS_MergeLongWordArrays);
  // ------------------------- Vertexes ----------------------------------------
  PS_Vertices.Describe(ATable);
  // ---------------------------- Sides ----------------------------------------
  PS_Sides.Describe(ATable);
  // ---------------------------- Lines ----------------------------------------
  PS_Lines.Describe(ATable);
// --------------------------- SECTORS -----------------------------------------
  PS_Sectors.Describe(ATable);
// --------------------------- PLAYERS -----------------------------------------
  PS_Players.Describe(ATable);
// -------------------------- TEXTURES -----------------------------------------
  ps_textures_ref.Describe(ATable);
// ----------------------------- MOBJS -----------------------------------------
  PS_MobjInfo.Describe(ATable);
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
  if ps_services_ref <> nil then
  begin
    ps_services_ref.Registry.RemoveGroup('PS_GAME');
    ps_services_ref.Registry.RemoveGroup('PS_OVERLAY');
  end;
end;

//==============================================================================
//
// PS_ScriptOnUses
//
//==============================================================================
function PS_ScriptOnUses(Sender: TPSPascalCompiler; const Name: TbtString): Boolean;
var
  LName: string;
  LServices: IScriptHostServices;
{ the OnUses callback function is called for each "uses" in the script.
  It's always called with the parameter 'SYSTEM' at the top of the script.
  For example: uses ii1, ii2;
  This will call this function 3 times. First with 'SYSTEM' then 'II1' and then 'II2'.
}
begin
  LServices := (Sender as TDoomCompiler).Services;
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
    LServices.Classes.RegisterCompiler(Sender);
    SIRegister_TOverlay(Sender);

    LServices.Registry.RegisterCompiler(string(Name), Sender);

    // the constants of every script: NaN, the flags of the mobjs, the angles...
    LServices.Constants.Describe(TScriptHostFactory.CreateCompilerConstants(Sender));

    Result := True;
  end
  else if Name = 'ALL' then
  begin
    for LName in LServices.Registry.CompilerUnitNames do
      PS_ScriptOnUses(Sender, TbtString(LName));
    Result := True;
  end
  else
  begin
    if LServices.Registry.RegisterCompiler(string(Name), Sender) then
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
  Output := TbtString(TDoomCompiler(Sender.Id).Services.Sources.ReadText(string(FileName)));
  Result := Output <> '';
end;

//==============================================================================
//
// TDoomCompiler.CreateDoomCompiler
//
//==============================================================================
constructor TDoomCompiler.CreateDoomCompiler;
begin
  CreateDoomCompiler(PS_HostServices);
end;

//==============================================================================
//
// TDoomCompiler.CreateDoomCompiler
//
//==============================================================================
constructor TDoomCompiler.CreateDoomCompiler(const AServices: IScriptHostServices);
begin
  if dccnt <> 0 then
    I_Error('TDoomCompiler.CreateDoomCompiler(): Compiler is already active!');

  Inc(dccnt);

  FServices := AServices;
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
  LDefine: string;
begin
  PS_ResetProcLists;

  FPP.Clear;

  // the game, DEBUG, DEVPARM, the X_OR_Y of the game and OPENGL (TScriptDefines)
  for LDefine in FServices.Defines do
    FPP.Defines.Add(TbtString(LDefine));

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

  unitstr := TbtString(FServices.GameName) + #13#10 + funitnames.Text;
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
constructor TDoomExec.CreateDoomExec(const aImporter: TPSRuntimeClassImporter;
  const AServices: IScriptHostServices);
begin
  inherited Create;
  FServices := AServices;
  if FServices = nil then
    if aImporter is TPSDoomRuntimeClassImporter then
      FServices := TPSDoomRuntimeClassImporter(aImporter).Services
    else
      FServices := PS_HostServices;
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
    if FServices.Registry.RegisterExecutor(s, Self) then
    begin
      Result := True;
    end
    else if s = 'ALL' then
    begin
      FServices.Registry.RegisterExecutorForAll(Self);
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

  if lst.Strings[0] <> FServices.GameName then
  begin
    I_Warning('TDoomExec.LoadData(): Can not load "%s" compiled script while playing "%s"'#13#10, [lst.Strings[0], FServices.GameName]);
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
    FServices.Classes.BindVariables(Self);
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
constructor TPSDoomRuntimeClassImporter.CreateDoomImporter(const AServices: IScriptHostServices);
begin
  inherited Create;
  FServices := AServices;
  with Add2(TRTLObject, '!TOBJECT') do
  begin
    RegisterConstructor(@TRTLObject.Create, 'Create');
    RegisterMethod(@TRTLObject.FakeFree, 'Free');
  end;
  FServices.Classes.RegisterRuntime(Self);
  RIRegister_TOverlay(Self);
end;

end.

