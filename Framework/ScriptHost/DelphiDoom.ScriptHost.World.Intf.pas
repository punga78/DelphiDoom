{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what the vertex, side and line functions of the   }
{  scripts ask of the engine                                                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  IScriptWorld is the only door to vertexes[], sides[] and lines[]: the       }
{  classes of the library check the indexes and build the values that scripts  }
{  see (handles, invalid numbers), the engine answers with the raw data.       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.World.Intf;

interface

uses
  DelphiDoom.ScriptHost.Intf;

const
  /// <summary>What a function of the scripts gives for a vertex, side, line or sector that is not there (the old MAXKEY)</summary>
  SCRIPT_INVALID_ID = 2147483647;
  /// <summary>What IScriptWorld gives for a sector that a line or a side does not have</summary>
  SCRIPT_WORLD_NO_SECTOR = -1;

type
  /// <summary>
  ///   The offsets of a side that scripts can read and write. sofMidRow is a name of the scripts
  ///   only: the library turns it into sofBottomRow (a defect of the old code, kept), so the
  ///   world never gets it
  /// </summary>
  TScriptSideOffset = (
    sofTexture, sofTopTexture, sofBottomTexture, sofMiddleTexture, sofRow, sofTopRow, sofBottomRow,
    sofMidRow
  );

  /// <summary>The three textures of a side</summary>
  TScriptSidePart = (sspTop, sspBottom, sspMiddle);

  /// <summary>The flags of a line that scripts can read and write (the engine knows where each one is kept)</summary>
  TScriptLineFlag = (slfBlocking, slfBlockMonsters, slfTriggerScripts, slfTransparent);

  /// <summary>The two planes of a sector</summary>
  TScriptPlane = (splFloor, splCeiling);

  /// <summary>The texture offsets of a sector that scripts can read and write (Doom and Strife only)</summary>
  TScriptSectorOffset = (ssoFloorX, ssoFloorY, ssoCeilingX, ssoCeilingY);

  /// <summary>The rotation of the textures of a sector (the angle and the centre of the rotation of each plane)</summary>
  TScriptSectorAngle = (
    ssaFloor, ssaFloorX, ssaFloorY, ssaCeiling, ssaCeilingX, ssaCeilingY
  );

  /// <summary>
  ///   The flags of a sector as scripts see them: ssfInterpolate and ssfFog are true when the
  ///   engine does NOT have its flag of "no interpolation" and "no fog"
  /// </summary>
  TScriptSectorFlag = (ssfRippleFloor, ssfRippleCeiling, ssfInterpolate, ssfFog);

  /// <summary>The numbers of a sector that scripts can read and write besides heights and light</summary>
  TScriptSectorValue = (ssvGravity, ssvWindThrust, ssvWindAngle);

  /// <summary>
  ///   The geometry of the level for the vertex, side, line and sector functions of the scripts. The
  ///   indexes arrive already checked against the counts (except where a method says it does not
  ///   check); a game that has no tag on its lines answers 0 and ignores the writes
  /// </summary>
  IScriptWorld = interface
    ['{2E6A91C4-5D07-4B83-A1F9-C80D36E47B52}']
    function VertexCount: Integer;
    function VertexX(const AIndex: Integer): Integer;
    function VertexY(const AIndex: Integer): Integer;
    function SideCount: Integer;
    function SideOffset(const AIndex: Integer; const AKind: TScriptSideOffset): Integer;
    procedure SetSideOffset(const AIndex: Integer; const AKind: TScriptSideOffset; const AValue: Integer);
    /// <summary>The name of the texture, empty for no texture (the "-" of the engine and a texture that is not valid)</summary>
    function SideTexture(const AIndex: Integer; const APart: TScriptSidePart): string;
    /// <summary>Sets a texture by name; a name that is no texture changes nothing</summary>
    procedure SetSideTexture(const AIndex: Integer; const APart: TScriptSidePart; const AName: string);
    /// <summary>The sector of a side (the old code did not check that the side has one)</summary>
    function SideSectorId(const AIndex: Integer): Integer;
    function LineCount: Integer;
    /// <summary>The number of the first (or second) vertex of a line, as the pointer difference gives it</summary>
    function LineVertex(const AIndex: Integer; const ASecond: Boolean): Integer;
    function LineDeltaX(const AIndex: Integer): Integer;
    function LineDeltaY(const AIndex: Integer): Integer;
    function LineSpecial(const AIndex: Integer): Integer;
    procedure SetLineSpecial(const AIndex: Integer; const AValue: Integer);
    /// <summary>One of the five arguments of a line (0 to 4)</summary>
    function LineArgument(const AIndex: Integer; const AArgument: Integer): Integer;
    procedure SetLineArgument(const AIndex: Integer; const AArgument: Integer; const AValue: Byte);
    function LineTag(const AIndex: Integer): Integer;
    procedure SetLineTag(const AIndex: Integer; const AValue: Integer);
    function LineHasFlag(const AIndex: Integer; const AFlag: TScriptLineFlag): Boolean;
    procedure SetLineFlag(const AIndex: Integer; const AFlag: TScriptLineFlag; const AValue: Boolean);
    /// <summary>The side number of the front (or back) of a line, -1 if the line has none</summary>
    function LineSideNumber(const AIndex: Integer; const ASecond: Boolean): Integer;
    /// <summary>The sector of the front (or back) of a line, SCRIPT_WORLD_NO_SECTOR if the line has none</summary>
    function LineSectorId(const AIndex: Integer; const ASecond: Boolean): Integer;
    function SectorCount: Integer;
    function SectorHeight(const AIndex: Integer; const APlane: TScriptPlane): Integer;
    /// <summary>Sets a height and lets the engine react (things in the sector are moved or crushed)</summary>
    procedure SetSectorHeight(const AIndex: Integer; const APlane: TScriptPlane; const AValue: Integer);
    /// <summary>The name of the flat, empty for a flat number that is not valid</summary>
    function SectorPicture(const AIndex: Integer; const APlane: TScriptPlane): string;
    /// <summary>Sets a flat by name; a name that is no flat changes nothing</summary>
    procedure SetSectorPicture(const AIndex: Integer; const APlane: TScriptPlane; const AName: string);
    function SectorLightLevel(const AIndex: Integer): Integer;
    procedure SetSectorLightLevel(const AIndex: Integer; const AValue: Integer);
    function SectorSpecial(const AIndex: Integer): Integer;
    function SectorTag(const AIndex: Integer): Integer;
    procedure SetSectorTag(const AIndex: Integer; const AValue: Integer);
    /// <summary>How many things the sector has in its list</summary>
    function SectorActorCount(const AIndex: Integer): Integer;
    /// <summary>The keys of the things of the sector, in the order of its list</summary>
    function SectorActorKeys(const AIndex: Integer): TArray<Cardinal>;
    function SectorLineCount(const AIndex: Integer): Integer;
    /// <summary>The number of a line of the sector (AOrder from 0 to SectorLineCount - 1)</summary>
    function SectorLineNumber(const AIndex: Integer; const AOrder: Integer): Integer;
    function SectorOffset(const AIndex: Integer; const AKind: TScriptSectorOffset): Integer;
    procedure SetSectorOffset(const AIndex: Integer; const AKind: TScriptSectorOffset; const AValue: Integer);
    /// <summary>The angles are 32 bit: the engine keeps the unsigned value, here it is the same bits</summary>
    function SectorAngle(const AIndex: Integer; const AKind: TScriptSectorAngle): Integer;
    /// <summary>Sets an angle and asks for the interpolation of the rotation</summary>
    procedure SetSectorAngle(const AIndex: Integer; const AKind: TScriptSectorAngle; const AValue: Integer);
    function SectorFlag(const AIndex: Integer; const AFlag: TScriptSectorFlag): Boolean;
    procedure SetSectorFlag(const AIndex: Integer; const AFlag: TScriptSectorFlag; const AValue: Boolean);
    function SectorValue(const AIndex: Integer; const AKind: TScriptSectorValue): Integer;
    procedure SetSectorValue(const AIndex: Integer; const AKind: TScriptSectorValue; const AValue: Integer);
    /// <summary>The number of the sector of the 3D floor (midsec) as the engine keeps it, not checked</summary>
    function SectorMidSector(const AIndex: Integer): Integer;
    /// <summary>The sector that gives the slope, SCRIPT_WORLD_NO_SECTOR if there is none</summary>
    function SectorSlopeSectorId(const AIndex: Integer): Integer;
    /// <summary>The name of the flat of the sky</summary>
    function SkyPicture: string;
    /// <summary>Moves floor and ceiling together by ADelta</summary>
    procedure MoveSectorZ(const AIndex: Integer; const ADelta: Integer);
    /// <summary>Plays a sound from the origin of the sector (the name is a sound or a random list)</summary>
    procedure PlaySectorSound(const AIndex: Integer; const AName: string);
    /// <summary>Gives the floor the plane of three points (x, y, z of each, fixed point)</summary>
    procedure SetFloorSlope(const AIndex: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
    procedure SetCeilingSlope(const AIndex: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
  end;

  /// <summary>
  ///   The vertex functions of the scripts (the methods are called by the interpreter and, for the
  ///   properties of the classes of the scripts, by psi_game)
  /// </summary>
  IScriptVertices = interface(IScriptFunctionSection)
    ['{9C37D1A8-60FE-4B25-8A41-D7E2B5F90C36}']
    /// <summary>The handle of the vertex (its number plus one), or SCRIPT_INVALID_ID</summary>
    function TVertex(const AId: Integer): Integer;
    function GetVertexX(const AVertex: Integer): Integer;
    function GetVertexY(const AVertex: Integer): Integer;
    function IsValidVertex(const AVertex: Integer): Boolean;
    function GetVertexCount: Integer;
  end;

  /// <summary>The side functions of the scripts</summary>
  IScriptSides = interface(IScriptFunctionSection)
    ['{4B81E6F3-A92D-4D70-B5C8-1E63F0A7D924}']
    function TSide(const AId: Integer): Integer;
    function GetOffset(const ASide: Integer; const AKind: TScriptSideOffset): Integer;
    procedure SetOffset(const ASide: Integer; const AKind: TScriptSideOffset; const AValue: Integer);
    function GetTexture(const ASide: Integer; const APart: TScriptSidePart): string;
    procedure SetTexture(const ASide: Integer; const APart: TScriptSidePart; const AName: string);
    function GetSideSector(const ASide: Integer): Integer;
    function IsValidSide(const ASide: Integer): Boolean;
    function GetSideCount: Integer;
  end;

  /// <summary>The line functions of the scripts</summary>
  IScriptLines = interface(IScriptFunctionSection)
    ['{D5260B9E-37F1-4C48-9A6D-82C4E1B7A053}']
    function TLine(const AId: Integer): Integer;
    function GetLineVertex1(const ALine: Integer): Integer;
    function GetLineVertex2(const ALine: Integer): Integer;
    function GetLineSpecial(const ALine: Integer): Integer;
    procedure SetLineSpecial(const ALine: Integer; const ASpecial: Integer);
    function GetLineDX(const ALine: Integer): Integer;
    function GetLineDY(const ALine: Integer): Integer;
    function GetLineArgument(const ALine: Integer; const AArgument: Integer): Byte;
    procedure SetLineArgument(const ALine: Integer; const AArgument: Integer; const AValue: Byte);
    function GetLineTag(const ALine: Integer): Integer;
    procedure SetLineTag(const ALine: Integer; const ATag: Integer);
    function GetLineFlag(const ALine: Integer; const AFlag: TScriptLineFlag): Boolean;
    procedure SetLineFlag(const ALine: Integer; const AFlag: TScriptLineFlag; const AValue: Boolean);
    function GetLineFrontSide(const ALine: Integer): Integer;
    function GetLineBackSide(const ALine: Integer): Integer;
    function GetLineFrontSector(const ALine: Integer): Integer;
    function GetLineBackSector(const ALine: Integer): Integer;
    function IsValidLine(const ALine: Integer): Boolean;
    function GetLineCount: Integer;
  end;

  /// <summary>
  ///   The sector functions of the scripts (the names are the ones of the old PS_* without the
  ///   prefix: the properties of the classes of the scripts in psi_game call them)
  /// </summary>
  IScriptSectors = interface(IScriptFunctionSection)
    ['{A3F6C28D-5B14-4E97-9D0A-62E81C7B4F35}']
    function TSector(const AId: Integer): Integer;
    function GetSectorFloorHeight(const ASector: Integer): Integer;
    procedure SetSectorFloorHeight(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingHeight(const ASector: Integer): Integer;
    procedure SetSectorCeilingHeight(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorPicture(const ASector: Integer): string;
    procedure SetSectorFloorPicture(const ASector: Integer; const AName: string);
    function GetSectorCeilingPicture(const ASector: Integer): string;
    procedure SetSectorCeilingPicture(const ASector: Integer; const AName: string);
    function GetSectorLightLevel(const ASector: Integer): Integer;
    procedure SetSectorLightLevel(const ASector: Integer; const AValue: Integer);
    function GetSectorSpecial(const ASector: Integer): Integer;
    function GetSectorTag(const ASector: Integer): Integer;
    procedure SetSectorTag(const ASector: Integer; const AValue: Integer);
    function GetSectorActors(const ASector: Integer): TArray<Cardinal>;
    function GetSectorNumActors(const ASector: Integer): Integer;
    function GetSectorLines(const ASector: Integer): TArray<Integer>;
    function GetSectorNumLines(const ASector: Integer): Integer;
    function GetSectorFloorXOffset(const ASector: Integer): Integer;
    procedure SetSectorFloorXOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorYOffset(const ASector: Integer): Integer;
    procedure SetSectorFloorYOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingXOffset(const ASector: Integer): Integer;
    procedure SetSectorCeilingXOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingYOffset(const ASector: Integer): Integer;
    procedure SetSectorCeilingYOffset(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorAngle(const ASector: Integer): Cardinal;
    procedure SetSectorFloorAngle(const ASector: Integer; const AValue: Cardinal);
    function GetSectorFloorAngleX(const ASector: Integer): Integer;
    procedure SetSectorFloorAngleX(const ASector: Integer; const AValue: Integer);
    function GetSectorFloorAngleY(const ASector: Integer): Integer;
    procedure SetSectorFloorAngleY(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingAngle(const ASector: Integer): Cardinal;
    procedure SetSectorCeilingAngle(const ASector: Integer; const AValue: Cardinal);
    function GetSectorCeilingAngleX(const ASector: Integer): Integer;
    procedure SetSectorCeilingAngleX(const ASector: Integer; const AValue: Integer);
    function GetSectorCeilingAngleY(const ASector: Integer): Integer;
    procedure SetSectorCeilingAngleY(const ASector: Integer; const AValue: Integer);
    function GetSectorRippleFloor(const ASector: Integer): Boolean;
    procedure SetSectorRippleFloor(const ASector: Integer; const AValue: Boolean);
    function GetSectorRippleCeiling(const ASector: Integer): Boolean;
    procedure SetSectorRippleCeiling(const ASector: Integer; const AValue: Boolean);
    function GetSectorInterpolate(const ASector: Integer): Boolean;
    procedure SetSectorInterpolate(const ASector: Integer; const AValue: Boolean);
    function GetSectorFog(const ASector: Integer): Boolean;
    procedure SetSectorFog(const ASector: Integer; const AValue: Boolean);
    function GetSectorGravity(const ASector: Integer): Integer;
    procedure SetSectorGravity(const ASector: Integer; const AValue: Integer);
    function GetSectorWindThrust(const ASector: Integer): Integer;
    procedure SetSectorWindThrust(const ASector: Integer; const AValue: Integer);
    function GetSectorWindAngle(const ASector: Integer): Cardinal;
    procedure SetSectorWindAngle(const ASector: Integer; const AValue: Cardinal);
    function GetSectorMidSector(const ASector: Integer): Integer;
    function GetSectorSlopeSector(const ASector: Integer): Integer;
    function SkyPicture: string;
    function IsValidSector(const ASector: Integer): Boolean;
    function GetSectorCount: Integer;
    function FindSectorsFromTag(const ATag: Integer): TArray<Integer>;
    procedure SectorPlaySound(const ASector: Integer; const AName: string);
    procedure SectorMoveZ(const ASector: Integer; const ADelta: Integer);
    procedure SetSectorFloorSlope(const ASector: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
    procedure SetSectorCeilingSlope(const ASector: Integer; const X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3: Integer);
  end;

implementation

end.
