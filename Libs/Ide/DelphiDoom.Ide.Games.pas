{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the games a project can be written for            }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Games;

interface

type
  /// <summary>The names of the games and their place in the game box of the project manager</summary>
  TIdeGames = class
  public
    /// <summary>The name as the ide keeps it: trimmed and in lower case</summary>
    class function Normalize(const AName: string): string; static;
    /// <summary>Doom, Heretic, Hexen, Strife, Radix and Mars3D are the games a project accepts</summary>
    class function IsKnown(const AName: string): Boolean; static;
    /// <summary>
    ///   The line of the game box: doom 0, heretic 1, hexen 2, strife 3. Any other game (radix
    ///   and mars have no entry) shows the first line
    /// </summary>
    class function BoxIndex(const AName: string): Integer; static;
  end;

implementation

uses
  System.SysUtils;

{ TIdeGames }

class function TIdeGames.Normalize(const AName: string): string;
begin
  Result := LowerCase(Trim(AName));
end;

class function TIdeGames.IsKnown(const AName: string): Boolean;
var
  LName: string;
begin
  LName := Normalize(AName);
  Result := (LName = 'doom') or (LName = 'heretic') or (LName = 'hexen') or
    (LName = 'strife') or (LName = 'radix') or (LName = 'mars');
end;

class function TIdeGames.BoxIndex(const AName: string): Integer;
begin
  if AName = 'heretic' then
    Result := 1
  else if AName = 'hexen' then
    Result := 2
  else if AName = 'strife' then
    Result := 3
  else
    Result := 0;
end;

end.
