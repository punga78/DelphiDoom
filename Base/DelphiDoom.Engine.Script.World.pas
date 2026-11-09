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
  end;

implementation

uses
  d_delphi,
  doomdata,
  psi_game,
  p_setup,
  r_data,
  r_defs,
  w_wad;


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

end.
