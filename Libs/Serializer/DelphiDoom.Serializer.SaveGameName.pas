{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the file names of the saved games          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.SaveGameName;

interface

type
  /// <summary>
  ///   How the engine finds the file of a saved game from what the menu or the console gives
  ///   (G_GetSaveName of g_game)
  /// </summary>
  TSaveGameName = class sealed
  public
    /// <summary>The file of a saved game</summary>
    /// <param name="AName">A slot number as text ("0".."N-1"), or the name of a file with or without the extension</param>
    /// <param name="ASlotCount">How many slots the game has</param>
    /// <param name="ASlotPrefix">The path and the beginning of the name of the files of the slots (save folder plus the name of the game)</param>
    /// <returns>
    ///   The file of the slot (prefix, number and .dsg), or the name with .DSG added if it has not it (the
    ///   test of the extension is not case sensitive)
    /// </returns>
    class function Resolve(const AName: string; const ASlotCount: Integer;
      const ASlotPrefix: string): string; static;
  end;

implementation

uses
  System.SysUtils;

{ TSaveGameName }

class function TSaveGameName.Resolve(const AName: string; const ASlotCount: Integer;
  const ASlotPrefix: string): string;
var
  LSlot: Integer;
begin
  for LSlot := 0 to ASlotCount - 1 do
    if AName = IntToStr(LSlot) then
    begin
      Result := ASlotPrefix + AName + '.dsg';
      Exit;
    end;

  // only the letters a-z go to upper case, as strupper of the engine
  if UpperCase(Copy(AName, Length(AName) - 3, 4)) <> '.DSG' then
    Result := AName + '.DSG'
  else
    Result := AName;
end;

end.
