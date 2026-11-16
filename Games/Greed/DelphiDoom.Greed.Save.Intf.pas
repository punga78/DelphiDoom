{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the saved games                 }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Save.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Greed.SaveTypes;

type
  /// <summary>Which game of the family the saved games belong to: each has its own files (GAME1, GAME2, GAME3)</summary>
  TGreedGameVariant = (ggvDefault, ggvGame1, ggvGame2, ggvGame3);

  /// <summary>The files of the saved games: whole files by name, in the folder of the game</summary>
  IGreedSaveFiles = interface
    ['{6D18A4C3-E250-4B97-A1F6-3C8B05E9D274}']
    function Exists(const AName: string): Boolean;
    /// <summary>The whole file; EGreedNotFoundException if it is not there</summary>
    function ReadAll(const AName: string): TBytes;
    /// <summary>Creates or replaces the file; EGreedException if it cannot be written</summary>
    procedure WriteAll(const AName: string; const ABytes: TBytes);
  end;

  /// <summary>SaveGame and LoadGame of the original, and the directory of the names of the menu</summary>
  IGreedSaveGames = interface
    ['{A29F5E71-4B08-4D36-9C1A-E7D043B86F52}']
    /// <summary>The name of the file of the saved game N (SAVEGAME.N, SAVE1.N, SAVE2.N, SAVE3.N)</summary>
    function GameFileName(ANumber: Integer): string;
    /// <summary>The name of the file with the names of the saved games (SAVEGAME.DIR, SAVE1.DIR ...)</summary>
    function DirectoryFileName: string;
    /// <summary>Writes the record as it is</summary>
    procedure SaveGame(ANumber: Integer; const APlayer: TGreedPlayerRecord);
    /// <summary>
    ///   False when there is no file (LoadGame returns without doing anything). EGreedDataException when the file
    ///   has less bytes than the record (MS_Error in the original); the bytes after the record are not read
    /// </summary>
    function LoadGame(ANumber: Integer; out APlayer: TGreedPlayerRecord): Boolean;
    /// <summary>
    ///   The names of the menu. If the file is not there it is created with empty names (InitSaveDir); a file shorter
    ///   than the 230 bytes is EGreedDataException
    /// </summary>
    function ReadDirectory: TGreedSaveDirectory;
    procedure WriteDirectory(const ADirectory: TGreedSaveDirectory);
  end;

implementation

end.
