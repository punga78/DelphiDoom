{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - the folders of the game in the PAK file system    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Pak.GameDirectories;

interface

type
  /// <summary>
  ///   The list of folders (names separated by commas) that the PAK file system searches for
  ///   the files of the game: the folders of the game itself, preceded by one for each file
  ///   that was loaded (D_IdentifyGameDirectories of the d_main units)
  /// </summary>
  TPakGameDirectories = class
  public
    /// <summary>
    ///   AGameDirectories is the list of the game (for example 'DOOM1,DOOM'). Each loaded file
    ///   (AFileNames are names without folder, in upper case), from the last to the first, adds
    ///   its name up to the first '.' in front of the list, unless the list has it already
    /// </summary>
    class function Compose(const AGameDirectories: string;
      const AFileNames: TArray<string>): string; static;
  end;

implementation

{ TPakGameDirectories }

class function TPakGameDirectories.Compose(const AGameDirectories: string;
  const AFileNames: TArray<string>): string;
var
  LIndex: Integer;
  LName: string;
  LDot: Integer;
begin
  Result := AGameDirectories;
  for LIndex := High(AFileNames) downto 0 do
  begin
    LName := AFileNames[LIndex];
    LDot := Pos('.', LName);
    if LDot > 0 then
      LName := Copy(LName, 1, LDot - 1);
    if Pos(',' + LName + ',', ',' + Result + ',') = 0 then
      Result := LName + ',' + Result;
  end;
end;

end.
