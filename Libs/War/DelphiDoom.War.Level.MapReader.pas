{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the tile maps of a level                          }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadLevelVisual and                       }
{  wres_loadLevelPassable of war_resources.c, (c) 2019 Alejandro Coto          }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level.MapReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   The visual record (the tile of the tileset of each cell) and the passable record (128 wood, 64 water,
  ///   16 bridge, 0 empty) are 64 x 64 little endian 16 bit numbers, row by row. The original read 8192 bytes
  ///   whatever the record had; here a shorter record is EWarException (a longer one is read as far as the map goes)
  /// </summary>
  TWarLevelMapReader = class
  public
    class function Read(const ARaw: TBytes): TArray<Word>; static;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.LittleEndian;

{ TWarLevelMapReader }

class function TWarLevelMapReader.Read(const ARaw: TBytes): TArray<Word>;
var
  LCell: Integer;
begin
  if Length(ARaw) < WAR_LEVEL_MAP_BYTES then
    raise EWarException.CreateFmt(SWarLevelMapSize, [Length(ARaw), WAR_LEVEL_MAP_BYTES]);
  SetLength(Result, WAR_MAP_TILES_WIDTH * WAR_MAP_TILES_HEIGHT);
  for LCell := 0 to High(Result) do
    Result[LCell] := TWarLittleEndian.ReadWord(ARaw, LCell * 2);
end;

end.
