{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - the answers of the real compilers    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.CompilerGolden;

interface

uses
  System.SysUtils,
  System.Classes;

type
  /// <summary>
  ///   What the old IDE got from the real ddc_*.dll for a script (Tests\Data\Ide\Compiler): the
  ///   answer, the messages as the dll wrote them, the compiled code and the place of the first
  ///   error as the old editor worked it out
  /// </summary>
  TCompilerGolden = record
    Succeeded: Boolean;
    Messages: string;
    /// <summary>The compiled code, one character for each byte of the .ddout file</summary>
    PCode: string;
    /// <summary>"line,column", or "none" or "invalid"</summary>
    Location: string;
    PCodeLength: Integer;
    class function Load(const AScript, AGame: string): TCompilerGolden; static;
    /// <summary>The names of the scripts that were compiled</summary>
    class function Scripts: TArray<string>; static;
    class function Games: TArray<string>; static;
  end;

implementation

uses
  DelphiDoom.Tests.Ide.TestData;

{ TCompilerGolden }

class function TCompilerGolden.Load(const AScript, AGame: string): TCompilerGolden;
var
  LLines: TStringList;
  LLine: string;
  LRaw: AnsiString;
  LIndex: Integer;
begin
  LLines := TIdeTestData.ReadLines('Compiler\' + AScript + '.' + AGame + '.golden.txt');
  try
    for LLine in LLines do
      if LLine.StartsWith('result=') then
        Result.Succeeded := SameText(Copy(LLine, 8, MaxInt), 'True')
      else if LLine.StartsWith('location=') then
        Result.Location := Copy(LLine, 10, MaxInt)
      else if LLine.StartsWith('pcodelength=') then
        Result.PCodeLength := StrToInt(Copy(LLine, 13, MaxInt));
  finally
    LLines.Free;
  end;
  Result.Messages := string(TIdeTestData.ReadBytes('Compiler\' + AScript + '.' + AGame + '.msgs.txt'));
  Result.PCode := '';
  if Result.Succeeded then
  begin
    LRaw := TIdeTestData.ReadBytes('Compiler\' + AScript + '.' + AGame + '.ddout');
    SetLength(Result.PCode, Length(LRaw));
    for LIndex := 1 to Length(LRaw) do
      Result.PCode[LIndex] := Char(Ord(LRaw[LIndex]));
  end;
end;

class function TCompilerGolden.Scripts: TArray<string>;
begin
  Result := TArray<string>.Create('empty_script', 'err_missing_end', 'err_missing_semicolon',
    'err_two_errors', 'err_type_mismatch', 'err_unknown_identifier', 'err_unknown_unit',
    'ok_minimal', 'ok_two_events');
end;

class function TCompilerGolden.Games: TArray<string>;
begin
  Result := TArray<string>.Create('doom', 'heretic', 'hexen', 'strife');
end;

end.
