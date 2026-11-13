{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contracts of the levels                           }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level.Intf;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types;

type
  /// <summary>A level as the rest of the engine sees it: data, no rules of the game</summary>
  IWarLevel = interface
    ['{3C8E5D21-6B7A-4F90-A1D4-8E2F0C9B5A76}']
    function GetInfo: TWarLevelInfo;
    function GetVisual: TArray<Word>;
    function GetPassable: TArray<Word>;
    /// <summary>The tile of the tileset in the cell (X, Y); EWarException outside the 64 x 64 map</summary>
    function VisualAt(AX, AY: Integer): Word;
    /// <summary>The passable flags of the cell (X, Y): 128 wood, 64 water, 16 bridge</summary>
    function PassableAt(AX, AY: Integer): Word;
    property Info: TWarLevelInfo read GetInfo;
    property Visual: TArray<Word> read GetVisual;
    property Passable: TArray<Word> read GetPassable;
  end;

  /// <summary>Reads the levels of an archive</summary>
  IWarLevelLoader = interface
    ['{9A4B7C13-2E5D-4086-B3F1-6D8A0E7C4B29}']
    /// <summary>How many level info records the catalog lists</summary>
    function GetLevelCount: Integer;
    /// <summary>The archive index of the APosition-th level info of the catalog, in the order of the table</summary>
    function GetLevelIndex(APosition: Integer): Integer;
    /// <summary>True if the record is a level info of the catalog that the archive has</summary>
    function IsLevel(AIndex: Integer): Boolean;
    /// <summary>
    ///   The level info AIndex with its visual and passable maps; EWarException if the record is not a level or
    ///   one of the records it needs cannot be read
    /// </summary>
    function Load(AIndex: Integer): IWarLevel;
    /// <summary>Only the level info record (no maps)</summary>
    function LoadInfo(AIndex: Integer): TWarLevelInfo;
    property LevelCount: Integer read GetLevelCount;
  end;

implementation

end.
