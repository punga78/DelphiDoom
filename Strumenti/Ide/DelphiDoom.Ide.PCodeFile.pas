{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the file of the compiled code of a script         }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.PCodeFile;

interface

uses
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   Writes the compiled code to a ".ddout" file. The compiler hands the code over as a string
  ///   with one character for each byte; the file holds one byte for each character, as the
  ///   command line compiler (ddc.exe) writes it, and as the game reads it
  /// </summary>
  TIdePCodeFile = class
  public
    /// <summary>The bytes of the file; the characters are cut to eight bits</summary>
    class function ToBytes(const APCode: string): AnsiString; static;
    class function Save(const AFileSystem: IIdeFileSystem; const AFileName, APCode: string): Boolean; static;
  end;

implementation

{ TIdePCodeFile }

class function TIdePCodeFile.ToBytes(const APCode: string): AnsiString;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(APCode));
  for LIndex := 1 to Length(APCode) do
    Result[LIndex] := AnsiChar(Ord(APCode[LIndex]) and $FF);
end;

class function TIdePCodeFile.Save(const AFileSystem: IIdeFileSystem; const AFileName,
  APCode: string): Boolean;
begin
  Result := AFileSystem.TryWriteAllText(AFileName, ToBytes(APCode));
end;

end.
