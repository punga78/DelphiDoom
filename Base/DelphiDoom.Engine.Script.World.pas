{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the geometry of the level for the functions of scripts }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.World;

interface

uses
  DelphiDoom.ScriptHost.World.Intf;

type
  /// <summary>
  ///   vertexes[], sides[] and lines[] for the scripts. The only class that reads them for the
  ///   vertex, side and line functions (they were in psi_game.pas); the library checks the
  ///   indexes, so here nothing is checked
  /// </summary>
  TEngineScriptWorld = class(TInterfacedObject, IScriptWorld)
  public
    function VertexCount: Integer;
    function VertexX(const AIndex: Integer): Integer;
    function VertexY(const AIndex: Integer): Integer;
    function SideCount: Integer;
    function SideOffset(const AIndex: Integer; const AKind: TScriptSideOffset): Integer;
    procedure SetSideOffset(const AIndex: Integer; const AKind: TScriptSideOffset; const AValue: Integer);
    function SideTexture(const AIndex: Integer; const APart: TScriptSidePart): string;
    procedure SetSideTexture(const AIndex: Integer; const APart: TScriptSidePart; const AName: string);
    function SideSectorId(const AIndex: Integer): Integer;
    function LineCount: Integer;
    function LineVertex(const AIndex: Integer; const ASecond: Boolean): Integer;
    function LineDeltaX(const AIndex: Integer): Integer;
    function LineDeltaY(const AIndex: Integer): Integer;
    function LineSpecial(const AIndex: Integer): Integer;
    procedure SetLineSpecial(const AIndex: Integer; const AValue: Integer);
    function LineArgument(const AIndex: Integer; const AArgument: Integer): Integer;
    procedure SetLineArgument(const AIndex: Integer; const AArgument: Integer; const AValue: Byte);
    function LineTag(const AIndex: Integer): Integer;
    procedure SetLineTag(const AIndex: Integer; const AValue: Integer);
    function LineHasFlag(const AIndex: Integer; const AFlag: TScriptLineFlag): Boolean;
    procedure SetLineFlag(const AIndex: Integer; const AFlag: TScriptLineFlag; const AValue: Boolean);
    function LineSideNumber(const AIndex: Integer; const ASecond: Boolean): Integer;
    function LineSectorId(const AIndex: Integer; const ASecond: Boolean): Integer;
    function SectorCount: Integer;
    function SectorHeight(const AIndex: Integer; const APlane: TScriptPlane): Integer;
    procedure SetSectorHeight(const AIndex: Integer; const APlane: TScriptPlane; const AValue: Integer);
    function SectorPicture(const AIndex: Integer; const APlane: TScriptPlane): string;
    procedure SetSectorPicture(const AIndex: Integer; const APlane: TScriptPlane; const AName: string);
    function SectorLightLevel(const AIndex: Integer): Integer;
    procedure SetSectorLightLevel(const AIndex: Integer; const AValue: Integer);
    function SectorSpecial(const AIndex: Integer): Integer;
    function SectorTag(const AIndex: Integer): Integer;
    procedure SetSectorTag(const AIndex: Integer; const AValue: Integer);
    function SectorActorCount(const AIndex: Integer): Integer;
    function SectorActorKeys(const AIndex: Integer): TArray<Cardinal>;
    function SectorLineCount(const AIndex: Integer): Integer;
    function SectorLineNumber(const AIndex: Integer; const AOrder: Integer): Integer;
    function SectorOffset(const AIndex: Integer; const AKind: TScriptSectorOffset): Integer;
    procedure SetSectorOffset(const AIndex: Integer; const AKind: TScriptSectorOffset; const AValue: Integer);
    function SectorAngle(const AIndex: Integer; const AKind: TScriptSectorAngle): Integer;
    procedure SetSectorAngle(const AIndex: Integer; const AKind: TScriptSectorAngle; const AValue: Integer);
    function SectorFlag(const AIndex: Integer; const AFlag: TScriptSectorFlag): Boolean;
    procedure SetSectorFlag(const AIndex: Integer; const AFlag: TScriptSectorFlag; const AValue: Boolean);
    function SectorValue(const AIndex: Integer; const AKind: TScriptSectorValue): Integer;
    procedure SetSectorValue(const AIndex: Integer; const AKind: TScriptSectorValue; const AValue: Integer);
    function SectorMidSector(const AIndex: Integer): Integer;
    function SectorSlopeSectorId(const AIndex: Integer): Integer;
    function SkyPicture: string;
    procedure MoveSectorZ(const AIndex: Integer; const ADelta: Integer);
    procedure PlaySectorSound(const AIndex: Integer; const AName: string);
    procedure SetFloorSlope(const AIndex: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
    procedure SetCeilingSlope(const AIndex: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
  end;

implementation

uses
  d_delphi,
  DelphiDoom.Engine.Script.Actors,
  DelphiDoom.ScriptHost.Actors.Intf,
  DelphiDoom.ScriptHost.Actors.KeyList,
  doomdata,
  psi_game,
  p_map,
  p_mobj_h,
  p_setup,
  p_slopes,
  r_data,
  r_defs,
  r_sky,
  w_wad;

function FlatNameFromId(const AId: Integer): string;
begin
  if (AId >= 0) and (AId < numflats) then
    Result := char8tostring(flats[AId].name)
  else
    Result := '';
end;


function TextureNameFromId(const AId: Integer): string;
begin
  if AId = TEXTURE_INVALID then
    Result := ''
  else
  begin
    Result := char8tostring(R_NameForSideTexture(AId));
    if Result = '-' then
      Result := '';
  end;
end;

function LineFlagMask(const AFlag: TScriptLineFlag): Integer;
begin
  case AFlag of
    slfBlocking: Result := ML_BLOCKING;
    slfBlockMonsters: Result := ML_BLOCKMONSTERS;
    slfTriggerScripts: Result := ML_TRIGGERSCRIPTS;
  else
    Result := 0;
  end;
end;

{ TEngineScriptWorld }

function TEngineScriptWorld.VertexCount: Integer;
begin
  Result := numvertexes;
end;

function TEngineScriptWorld.VertexX(const AIndex: Integer): Integer;
begin
  Result := vertexes[AIndex].x;
end;

function TEngineScriptWorld.VertexY(const AIndex: Integer): Integer;
begin
  Result := vertexes[AIndex].y;
end;

function TEngineScriptWorld.SideCount: Integer;
begin
  Result := numsides;
end;

function TEngineScriptWorld.SideOffset(const AIndex: Integer; const AKind: TScriptSideOffset): Integer;
begin
  case AKind of
    sofTexture: Result := sides[AIndex].textureoffset;
    sofTopTexture: Result := sides[AIndex].toptextureoffset;
    sofBottomTexture: Result := sides[AIndex].bottomtextureoffset;
    sofMiddleTexture: Result := sides[AIndex].midtextureoffset;
    sofRow: Result := sides[AIndex].rowoffset;
    sofTopRow: Result := sides[AIndex].toprowoffset;
  else
    // sofBottomRow (the library never gives sofMidRow)
    Result := sides[AIndex].bottomrowoffset;
  end;
end;

procedure TEngineScriptWorld.SetSideOffset(const AIndex: Integer; const AKind: TScriptSideOffset;
  const AValue: Integer);
begin
  case AKind of
    sofTexture: sides[AIndex].textureoffset := AValue;
    sofTopTexture: sides[AIndex].toptextureoffset := AValue;
    sofBottomTexture: sides[AIndex].bottomtextureoffset := AValue;
    sofMiddleTexture: sides[AIndex].midtextureoffset := AValue;
    sofRow: sides[AIndex].rowoffset := AValue;
    sofTopRow: sides[AIndex].toprowoffset := AValue;
  else
    sides[AIndex].bottomrowoffset := AValue;
  end;
end;

function TEngineScriptWorld.SideTexture(const AIndex: Integer; const APart: TScriptSidePart): string;
begin
  case APart of
    sspTop: Result := TextureNameFromId(sides[AIndex].toptexture);
    sspBottom: Result := TextureNameFromId(sides[AIndex].bottomtexture);
  else
    Result := TextureNameFromId(sides[AIndex].midtexture);
  end;
end;

procedure TEngineScriptWorld.SetSideTexture(const AIndex: Integer; const APart: TScriptSidePart;
  const AName: string);
var
  LId: Integer;
begin
  LId := psi_game._textureidfromname(AName);
  if LId = TEXTURE_INVALID then
    Exit;
  case APart of
    sspTop: sides[AIndex].toptexture := LId;
    sspBottom: sides[AIndex].bottomtexture := LId;
  else
    sides[AIndex].midtexture := LId;
  end;
end;

function TEngineScriptWorld.SideSectorId(const AIndex: Integer): Integer;
begin
  Result := sides[AIndex].sector.iSectorID;
end;

function TEngineScriptWorld.LineCount: Integer;
begin
  Result := numlines;
end;

function TEngineScriptWorld.LineVertex(const AIndex: Integer; const ASecond: Boolean): Integer;
begin
  if ASecond then
    Result := pDiff(lines[AIndex].v2, @vertexes[0], SizeOf(vertex_t))
  else
    Result := pDiff(lines[AIndex].v1, @vertexes[0], SizeOf(vertex_t));
end;

function TEngineScriptWorld.LineDeltaX(const AIndex: Integer): Integer;
begin
  Result := lines[AIndex].dx;
end;

function TEngineScriptWorld.LineDeltaY(const AIndex: Integer): Integer;
begin
  Result := lines[AIndex].dy;
end;

function TEngineScriptWorld.LineSpecial(const AIndex: Integer): Integer;
begin
  Result := lines[AIndex].special;
end;

procedure TEngineScriptWorld.SetLineSpecial(const AIndex: Integer; const AValue: Integer);
begin
  lines[AIndex].special := AValue;
end;

function TEngineScriptWorld.LineArgument(const AIndex: Integer; const AArgument: Integer): Integer;
begin
  case AArgument of
    0: Result := lines[AIndex].arg1;
    1: Result := lines[AIndex].arg2;
    2: Result := lines[AIndex].arg3;
    3: Result := lines[AIndex].arg4;
  else
    Result := lines[AIndex].arg5;
  end;
end;

procedure TEngineScriptWorld.SetLineArgument(const AIndex: Integer; const AArgument: Integer;
  const AValue: Byte);
begin
  case AArgument of
    0: lines[AIndex].arg1 := AValue;
    1: lines[AIndex].arg2 := AValue;
    2: lines[AIndex].arg3 := AValue;
    3: lines[AIndex].arg4 := AValue;
  else
    lines[AIndex].arg5 := AValue;
  end;
end;

function TEngineScriptWorld.LineTag(const AIndex: Integer): Integer;
begin
{$IFDEF HEXEN}
  Result := 0; // the lines of Hexen have arguments and no tag
{$ELSE}
  Result := lines[AIndex].tag;
{$ENDIF}
end;

procedure TEngineScriptWorld.SetLineTag(const AIndex: Integer; const AValue: Integer);
begin
{$IFNDEF HEXEN}
  lines[AIndex].tag := AValue;
{$ENDIF}
end;

function TEngineScriptWorld.LineHasFlag(const AIndex: Integer; const AFlag: TScriptLineFlag): Boolean;
begin
{$IFNDEF HEXEN}
  if AFlag = slfTransparent then
  begin
    Result := lines[AIndex].renderflags and LRF_TRANSPARENT <> 0;
    Exit;
  end;
{$ENDIF}
  Result := lines[AIndex].flags and LineFlagMask(AFlag) <> 0;
end;

procedure TEngineScriptWorld.SetLineFlag(const AIndex: Integer; const AFlag: TScriptLineFlag;
  const AValue: Boolean);
begin
{$IFNDEF HEXEN}
  if AFlag = slfTransparent then
  begin
    if AValue then
      lines[AIndex].renderflags := lines[AIndex].renderflags or LRF_TRANSPARENT
    else
      lines[AIndex].renderflags := lines[AIndex].renderflags and not LRF_TRANSPARENT;
    Exit;
  end;
{$ENDIF}
  if AValue then
    lines[AIndex].flags := lines[AIndex].flags or LineFlagMask(AFlag)
  else
    lines[AIndex].flags := lines[AIndex].flags and not LineFlagMask(AFlag);
end;

function TEngineScriptWorld.LineSideNumber(const AIndex: Integer; const ASecond: Boolean): Integer;
begin
  if ASecond then
    Result := lines[AIndex].sidenum[1]
  else
    Result := lines[AIndex].sidenum[0];
end;

function TEngineScriptWorld.LineSectorId(const AIndex: Integer; const ASecond: Boolean): Integer;
var
  LSector: Psector_t;
begin
  if ASecond then
    LSector := lines[AIndex].backsector
  else
    LSector := lines[AIndex].frontsector;
  if LSector <> nil then
    Result := LSector.iSectorID
  else
    Result := SCRIPT_WORLD_NO_SECTOR;
end;

function TEngineScriptWorld.SectorCount: Integer;
begin
  Result := numsectors;
end;

function TEngineScriptWorld.SectorHeight(const AIndex: Integer; const APlane: TScriptPlane): Integer;
begin
  if APlane = splFloor then
    Result := sectors[AIndex].floorheight
  else
    Result := sectors[AIndex].ceilingheight;
end;

procedure TEngineScriptWorld.SetSectorHeight(const AIndex: Integer; const APlane: TScriptPlane;
  const AValue: Integer);
var
  LSector: Psector_t;
begin
  LSector := @sectors[AIndex];
  if APlane = splFloor then
    LSector.floorheight := AValue
  else
    LSector.ceilingheight := AValue;
  P_ChangeSector(LSector, False);
end;

function TEngineScriptWorld.SectorPicture(const AIndex: Integer; const APlane: TScriptPlane): string;
begin
  if APlane = splFloor then
    Result := FlatNameFromId(sectors[AIndex].floorpic)
  else
    Result := FlatNameFromId(sectors[AIndex].ceilingpic);
end;

procedure TEngineScriptWorld.SetSectorPicture(const AIndex: Integer; const APlane: TScriptPlane;
  const AName: string);
var
  LFlat: Integer;
begin
  LFlat := R_SafeFlatNumForName(AName);
  if (LFlat >= 0) and (LFlat < numflats) then
    if APlane = splFloor then
      sectors[AIndex].floorpic := LFlat
    else
      sectors[AIndex].ceilingpic := LFlat;
end;

function TEngineScriptWorld.SectorLightLevel(const AIndex: Integer): Integer;
begin
  Result := sectors[AIndex].lightlevel;
end;

procedure TEngineScriptWorld.SetSectorLightLevel(const AIndex: Integer; const AValue: Integer);
begin
  sectors[AIndex].lightlevel := AValue;
end;

function TEngineScriptWorld.SectorSpecial(const AIndex: Integer): Integer;
begin
  Result := sectors[AIndex].special;
end;

function TEngineScriptWorld.SectorTag(const AIndex: Integer): Integer;
begin
  Result := sectors[AIndex].tag;
end;

procedure TEngineScriptWorld.SetSectorTag(const AIndex: Integer; const AValue: Integer);
begin
  sectors[AIndex].tag := AValue;
end;

function TEngineScriptWorld.SectorActorCount(const AIndex: Integer): Integer;
var
  LThing: Pmobj_t;
begin
  Result := 0;
  LThing := sectors[AIndex].thinglist;
  while LThing <> nil do
  begin
    Inc(Result);
    LThing := LThing.snext;
  end;
end;

function TEngineScriptWorld.SectorActorKeys(const AIndex: Integer): TArray<Cardinal>;
var
  LList: TScriptActorKeyList;
begin
  // the same list that the actor functions use (duplicates and order as they have always been)
  LList := TScriptActorKeyList.Create;
  try
    TEngineScriptActors.CollectKeys(acsSector, AIndex, LList);
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TEngineScriptWorld.SectorLineCount(const AIndex: Integer): Integer;
begin
  Result := sectors[AIndex].linecount;
end;

function TEngineScriptWorld.SectorLineNumber(const AIndex: Integer; const AOrder: Integer): Integer;
begin
  Result := pDiff(sectors[AIndex].lines[AOrder], lines, SizeOf(line_t));
end;

function TEngineScriptWorld.SectorOffset(const AIndex: Integer; const AKind: TScriptSectorOffset): Integer;
begin
{$IFDEF DOOM_OR_STRIFE}
  case AKind of
    ssoFloorX: Result := sectors[AIndex].floor_xoffs;
    ssoFloorY: Result := sectors[AIndex].floor_yoffs;
    ssoCeilingX: Result := sectors[AIndex].ceiling_xoffs;
  else
    Result := sectors[AIndex].ceiling_yoffs;
  end;
{$ELSE}
  Result := 0; // Heretic and Hexen have no offsets of the textures of a sector
{$ENDIF}
end;

procedure TEngineScriptWorld.SetSectorOffset(const AIndex: Integer; const AKind: TScriptSectorOffset;
  const AValue: Integer);
begin
{$IFDEF DOOM_OR_STRIFE}
  case AKind of
    ssoFloorX: sectors[AIndex].floor_xoffs := AValue;
    ssoFloorY: sectors[AIndex].floor_yoffs := AValue;
    ssoCeilingX: sectors[AIndex].ceiling_xoffs := AValue;
  else
    sectors[AIndex].ceiling_yoffs := AValue;
  end;
{$ENDIF}
end;

function TEngineScriptWorld.SectorAngle(const AIndex: Integer; const AKind: TScriptSectorAngle): Integer;
begin
  case AKind of
    ssaFloor: Result := Integer(sectors[AIndex].floorangle);
    ssaFloorX: Result := sectors[AIndex].flooranglex;
    ssaFloorY: Result := sectors[AIndex].floorangley;
    ssaCeiling: Result := Integer(sectors[AIndex].ceilingangle);
    ssaCeilingX: Result := sectors[AIndex].ceilinganglex;
  else
    Result := sectors[AIndex].ceilingangley;
  end;
end;

procedure TEngineScriptWorld.SetSectorAngle(const AIndex: Integer; const AKind: TScriptSectorAngle;
  const AValue: Integer);
begin
  case AKind of
    ssaFloor: sectors[AIndex].floorangle := LongWord(AValue);
    ssaFloorX: sectors[AIndex].flooranglex := AValue;
    ssaFloorY: sectors[AIndex].floorangley := AValue;
    ssaCeiling: sectors[AIndex].ceilingangle := LongWord(AValue);
    ssaCeilingX: sectors[AIndex].ceilinganglex := AValue;
  else
    sectors[AIndex].ceilingangley := AValue;
  end;
  sectors[AIndex].renderflags := sectors[AIndex].renderflags or SRF_INTERPOLATE_ROTATE;
end;

function TEngineScriptWorld.SectorFlag(const AIndex: Integer; const AFlag: TScriptSectorFlag): Boolean;
begin
  case AFlag of
    ssfRippleFloor: Result := sectors[AIndex].renderflags and SRF_RIPPLE_FLOOR <> 0;
    ssfRippleCeiling: Result := sectors[AIndex].renderflags and SRF_RIPPLE_CEILING <> 0;
    ssfInterpolate: Result := sectors[AIndex].renderflags and SRF_NO_INTERPOLATE = 0;
  else
    Result := sectors[AIndex].renderflags and SRF_FOG = 0;
  end;
end;

procedure TEngineScriptWorld.SetSectorFlag(const AIndex: Integer; const AFlag: TScriptSectorFlag;
  const AValue: Boolean);
var
  LMask: Integer;
  LSet: Boolean;
begin
  LSet := AValue;
  case AFlag of
    ssfRippleFloor: LMask := SRF_RIPPLE_FLOOR;
    ssfRippleCeiling: LMask := SRF_RIPPLE_CEILING;
    ssfInterpolate:
      begin
        LMask := SRF_NO_INTERPOLATE;
        LSet := not AValue; // the engine keeps "no interpolation"
      end;
  else
    LMask := SRF_FOG;
    LSet := not AValue; // the engine keeps the flag of the fog the other way round
  end;
  if LSet then
    sectors[AIndex].renderflags := sectors[AIndex].renderflags or LMask
  else
    sectors[AIndex].renderflags := sectors[AIndex].renderflags and not LMask;
end;

function TEngineScriptWorld.SectorValue(const AIndex: Integer; const AKind: TScriptSectorValue): Integer;
begin
  case AKind of
    ssvGravity: Result := sectors[AIndex].gravity;
    ssvWindThrust: Result := sectors[AIndex].windthrust;
  else
    Result := Integer(sectors[AIndex].windangle);
  end;
end;

procedure TEngineScriptWorld.SetSectorValue(const AIndex: Integer; const AKind: TScriptSectorValue;
  const AValue: Integer);
begin
  case AKind of
    ssvGravity: sectors[AIndex].gravity := AValue;
    ssvWindThrust: sectors[AIndex].windthrust := AValue;
  else
    sectors[AIndex].windangle := LongWord(AValue);
  end;
end;

function TEngineScriptWorld.SectorMidSector(const AIndex: Integer): Integer;
begin
  Result := sectors[AIndex].midsec;
end;

function TEngineScriptWorld.SectorSlopeSectorId(const AIndex: Integer): Integer;
begin
  if sectors[AIndex].slopesec <> nil then
    Result := sectors[AIndex].slopesec.iSectorID
  else
    Result := SCRIPT_WORLD_NO_SECTOR;
end;

function TEngineScriptWorld.SkyPicture: string;
begin
  Result := FlatNameFromId(skyflatnum);
end;

procedure TEngineScriptWorld.MoveSectorZ(const AIndex: Integer; const ADelta: Integer);
var
  LSector: Psector_t;
begin
  LSector := @sectors[AIndex];
  LSector.floorheight := LSector.floorheight + ADelta;
  LSector.ceilingheight := LSector.ceilingheight + ADelta;
  P_ChangeSector(LSector, False);
end;

procedure TEngineScriptWorld.PlaySectorSound(const AIndex: Integer; const AName: string);
begin
  TEngineScriptActors.PlaySoundAt(@sectors[AIndex].soundorg, AName);
end;

procedure TEngineScriptWorld.SetFloorSlope(const AIndex: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
begin
  p_slopes.PS_SetFloorSlope(AIndex, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3);
end;

procedure TEngineScriptWorld.SetCeilingSlope(const AIndex: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
begin
  p_slopes.PS_SetCeilingSlope(AIndex, X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3);
end;

end.
