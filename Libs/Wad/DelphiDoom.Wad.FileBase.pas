{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - the lump name of a file                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.FileBase;

interface

uses
  System.SysUtils,
  DelphiDoom.Wad.Types;

type
  /// <summary>
  ///   The base name of a path as the engine reads it for a demo or a lump: what follows the
  ///   last "/" or "\", up to the first ".", in upper case. It was ExtractFileBase of w_wad
  /// </summary>
  TWadFileBase = class
  public
    /// <summary>
    ///   The base name of APath in upper case (ASCII only). Raises EWadException when it has
    ///   more than 8 characters
    /// </summary>
    class function Extract(const APath: string): string; static;
  end;

implementation

const
  SFileBaseTooLong = 'Filename base of %s has more than 8 characters';
  FILE_BASE_MAX_LENGTH = 8;

{ TWadFileBase }

class function TWadFileBase.Extract(const APath: string): string;
var
  LIndex: Integer;
  LLength: Integer;
  LChar: Char;
begin
  LLength := Length(APath);
  LIndex := LLength;
  while LIndex > 0 do
  begin
    if (APath[LIndex] = '/') or (APath[LIndex] = '\') then
      Break;
    Dec(LIndex);
  end;

  Result := '';
  while LIndex < LLength do
  begin
    Inc(LIndex);
    LChar := APath[LIndex];
    if LChar = '.' then
      Break;
    if (LChar >= 'a') and (LChar <= 'z') then
      LChar := Char(Ord(LChar) - 32);
    Result := Result + LChar;
  end;

  if Length(Result) > FILE_BASE_MAX_LENGTH then
    raise EWadException.CreateFmt(SFileBaseTooLong, [APath]);
end;

end.
