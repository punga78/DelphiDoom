{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - object code made by hand             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.ObjectBuilder;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   An object code with one script, written command by command: for the commands that the
  ///   compiler never writes (a jump out of the code, a command that does not exist) and for
  ///   the tables that are wrong
  /// </summary>
  TAcsObjectBuilder = class
  public
    /// <summary>
    ///   The header, the commands (at offset 12), the strings and the table with one script that
    ///   starts at the first command
    /// </summary>
    class function Build(const ACommands: array of Integer; const AStrings: array of string;
      AScriptNumber: Integer = 1; AArgumentCount: Integer = 0): TBytes; static;
    class procedure PutLong(var ABytes: TBytes; AOffset, AValue: Integer); static;
    class function LongAt(const ABytes: TBytes; AOffset: Integer): Integer; static;
  end;

implementation

{ TAcsObjectBuilder }

class procedure TAcsObjectBuilder.PutLong(var ABytes: TBytes; AOffset, AValue: Integer);
begin
  Move(AValue, ABytes[AOffset], SizeOf(Integer));
end;

class function TAcsObjectBuilder.LongAt(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Move(ABytes[AOffset], Result, SizeOf(Integer));
end;

class function TAcsObjectBuilder.Build(const ACommands: array of Integer;
  const AStrings: array of string; AScriptNumber, AArgumentCount: Integer): TBytes;
var
  LCodeEnd: Integer;
  LStringOffsets: TArray<Integer>;
  LTable: Integer;
  LIndex: Integer;
  LChar: Integer;
  LPosition: Integer;
begin
  LCodeEnd := 12 + Length(ACommands) * 4;
  SetLength(LStringOffsets, Length(AStrings));
  LPosition := LCodeEnd;
  for LIndex := 0 to High(AStrings) do
  begin
    LStringOffsets[LIndex] := LPosition;
    Inc(LPosition, Length(AStrings[LIndex]) + 1);
  end;
  LTable := (LPosition + 3) and not 3;
  SetLength(Result, LTable + 4 + 12 + 4 + Length(AStrings) * 4);
  FillChar(Result[0], Length(Result), 0);
  PutLong(Result, 0, $534341);
  PutLong(Result, 4, LTable);
  for LIndex := 0 to High(ACommands) do
    PutLong(Result, 12 + LIndex * 4, ACommands[LIndex]);
  for LIndex := 0 to High(AStrings) do
    for LChar := 1 to Length(AStrings[LIndex]) do
      Result[LStringOffsets[LIndex] + LChar - 1] := Byte(Ord(AStrings[LIndex][LChar]));
  PutLong(Result, LTable, 1);
  PutLong(Result, LTable + 4, AScriptNumber);
  PutLong(Result, LTable + 8, 12);
  PutLong(Result, LTable + 12, AArgumentCount);
  PutLong(Result, LTable + 16, Length(AStrings));
  for LIndex := 0 to High(AStrings) do
    PutLong(Result, LTable + 20 + LIndex * 4, LStringOffsets[LIndex]);
end;

end.
