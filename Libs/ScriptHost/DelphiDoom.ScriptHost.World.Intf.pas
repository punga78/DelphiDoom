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

  /// <summary>
  ///   The geometry of the level for the vertex, side and line functions of the scripts. The
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

implementation

end.
