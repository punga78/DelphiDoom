{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the names of the sprites                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// The code of a sprite name is made with shifts that wrap around as in the old code
{$Q-}
{$R-}
unit DelphiDoom.Info.SpriteNames;

interface

type
  /// <summary>
  ///   A sprite is known by an index into a table of codes: the four characters of its name
  ///   as an integer, the first one in the lowest byte
  /// </summary>
  TInfoSpriteNames = class sealed
  public
    /// <summary>
    ///   True if AName is a sprite index (written in decimal, in the table); the index is then
    ///   in AIndex. Anything else is a name
    /// </summary>
    class function TryParseIndex(const AName: string; const ACount: Integer;
      out AIndex: Integer): Boolean; static;
    /// <summary>The code of a name in upper case; False if the name does not have four characters</summary>
    class function TryCode(const AName: string; out ACode: Integer): Boolean; static;
    /// <summary>The four characters of a code</summary>
    class function NameOfCode(const ACode: Integer): string; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Scanner.Strings;

{ TInfoSpriteNames }

class function TInfoSpriteNames.TryParseIndex(const AName: string; const ACount: Integer;
  out AIndex: Integer): Boolean;
begin
  AIndex := TScannerStrings.ToInteger(AName, -1);
  Result := (AIndex >= 0) and (AIndex < ACount) and (IntToStr(AIndex) = AName);
end;

class function TInfoSpriteNames.TryCode(const AName: string; out ACode: Integer): Boolean;
var
  LName: string;
begin
  ACode := 0;
  Result := Length(AName) = 4;
  if not Result then
    Exit;
  LName := TScannerStrings.UpperAscii(AName);
  ACode := Ord(LName[1]) + Ord(LName[2]) shl 8 + Ord(LName[3]) shl 16 + Ord(LName[4]) shl 24;
end;

class function TInfoSpriteNames.NameOfCode(const ACode: Integer): string;
var
  LCode: Cardinal;
begin
  LCode := Cardinal(ACode);
  Result := Char(LCode and $FF) + Char((LCode shr 8) and $FF) + Char((LCode shr 16) and $FF) +
    Char((LCode shr 24) and $FF);
end;

end.
