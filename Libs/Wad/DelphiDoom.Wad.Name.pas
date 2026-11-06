{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - name of a lump                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Name;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Types;

type
  /// <summary>
  ///   Names of lumps: upper case ASCII, cut at the first #0, at most 8
  ///   characters on disk
  /// </summary>
  TWadLumpName = class
  public
    /// <summary>Upper case, as the engine compares names (not locale aware)</summary>
    class function UpperCase(const AName: string): string; static;
    /// <summary>The name stored in a directory record of a WAD</summary>
    class function FromRecord(const ARecord: TWadDirectoryRecord): string; static;
    /// <summary>
    ///   Fills the 8 characters of a directory record; raises when AName is
    ///   empty, longer than 8 or has characters that are not ASCII printable
    /// </summary>
    class procedure ToRecord(const AName: string; var ARecord: TWadDirectoryRecord); static;
    /// <summary>True when AName can be the name of a lump of a WAD</summary>
    class function IsValid(const AName: string): Boolean; static;
    /// <summary>The name a single file gets as a lump: base name without extension, 8 characters</summary>
    class function FromFileName(const AFileName: string): string; static;
  end;

implementation

const
  SInvalidLumpName = 'Invalid lump name "%s"';

{ TWadLumpName }

class function TWadLumpName.UpperCase(const AName: string): string;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := AName;
  for LIndex := 1 to Length(Result) do
  begin
    LChar := Result[LIndex];
    if (LChar >= 'a') and (LChar <= 'z') then
      Result[LIndex] := Char(Ord(LChar) - 32);
  end;
end;

class function TWadLumpName.FromRecord(const ARecord: TWadDirectoryRecord): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to WAD_LUMP_NAME_SIZE - 1 do
  begin
    if ARecord.Name[LIndex] = #0 then
      Break;
    Result := Result + UpperCase(Char(Ord(ARecord.Name[LIndex])));
  end;
end;

class function TWadLumpName.IsValid(const AName: string): Boolean;
var
  LIndex: Integer;
begin
  Result := (Length(AName) >= 1) and (Length(AName) <= WAD_LUMP_NAME_SIZE);
  if Result then
    for LIndex := 1 to Length(AName) do
      if (AName[LIndex] <= ' ') or (AName[LIndex] > '~') then
        Exit(False);
end;

class procedure TWadLumpName.ToRecord(const AName: string; var ARecord: TWadDirectoryRecord);
var
  LName: string;
  LIndex: Integer;
begin
  if not IsValid(AName) then
    raise EWadException.CreateFmt(SInvalidLumpName, [AName]);
  LName := UpperCase(AName);
  FillChar(ARecord.Name, SizeOf(ARecord.Name), 0);
  for LIndex := 1 to Length(LName) do
    ARecord.Name[LIndex - 1] := AnsiChar(Ord(LName[LIndex]));
end;

class function TWadLumpName.FromFileName(const AFileName: string): string;
var
  LBase: string;
begin
  LBase := ChangeFileExt(ExtractFileName(AFileName), '');
  Result := UpperCase(Copy(LBase, 1, WAD_LUMP_NAME_SIZE));
end;

end.
