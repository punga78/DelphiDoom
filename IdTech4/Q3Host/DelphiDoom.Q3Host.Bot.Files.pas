{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the botfiles of the game for the bot   }
{  library                                                                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_bot.c        }
{  (botimport.FS_*). Copyright (C) 1999-2005 Id Software, Inc. This unit is    }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Files;

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   IBotFileSource on the file system of the game: a whole file by its path with forward slashes
  ///   (botfiles/syn.c, maps/q3dm1.aas), from the folders and the paks as FS_FOpenFile finds it
  /// </summary>
  TQ3BotFileSource = class(TInterfacedObject, IBotFileSource)
  strict private
    FFiles: IGameFileSystem;
  public
    constructor Create(const AFiles: IGameFileSystem);
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

implementation

constructor TQ3BotFileSource.Create(const AFiles: IGameFileSystem);
begin
  inherited Create;
  FFiles := AFiles;
end;

function TQ3BotFileSource.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
begin
  Result := FFiles.ReadFile(string(APath), AData);
end;

end.
