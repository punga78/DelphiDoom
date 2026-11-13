{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the file of the errors of the program     }
{  (issue 187)                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ErrorLog;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.AtomicFileWriter,
  DelphiDoom.XcomEngine.ErrorLog.Types;

type
  /// <summary>
  ///   Every error that reaches the main loop of the program is added to a file (xcom_errors.log of the user folder),
  ///   one entry per error: a program with a window shows the error only in a message box, and nothing is left when
  ///   the box is closed. The file is only added to; an entry that cannot be written never raises (the error that is
  ///   on its way out is the one that matters) and the reason is kept in LastError
  /// </summary>
  TXcomErrorLog = class
  strict private
    FFiles: IXcomFileSystem;
    FPath: string;
    FNow: TFunc<string>;
    FLastError: string;
  public
    /// <param name="AFiles">Where the file is (an IXcomAtomicFiles file system writes it in one step)</param>
    /// <param name="APath">The file of the errors</param>
    /// <param name="ANow">The date and time as text (the clock is not read here, so a test can fix it)</param>
    constructor Create(const AFiles: IXcomFileSystem; const APath: string; const ANow: TFunc<string>);
    /// <summary>The text of an entry, with the time of ANow</summary>
    function FormatEntry(const AEntry: TXcomErrorEntry): string;
    /// <summary>Adds an entry to the file; false (and LastError) when the file could not be written</summary>
    function Write(const AEntry: TXcomErrorEntry): Boolean;
    /// <summary>Why the last Write failed; empty when it wrote</summary>
    property LastError: string read FLastError;
    property Path: string read FPath;
  end;

implementation

const
  SEntryRule = '==== ';

constructor TXcomErrorLog.Create(const AFiles: IXcomFileSystem; const APath: string; const ANow: TFunc<string>);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(ANow) then
    raise EArgumentNilException.Create('ANow');
  FFiles := AFiles;
  FPath := APath;
  FNow := ANow;
end;

function TXcomErrorLog.FormatEntry(const AEntry: TXcomErrorEntry): string;
var
  LStates: string;
  LIndex: Integer;
begin
  LStates := '';
  for LIndex := 0 to High(AEntry.States) do
  begin
    if LIndex > 0 then
      LStates := LStates + ' > ';
    LStates := LStates + AEntry.States[LIndex];
  end;
  Result := SEntryRule + FNow() + sLineBreak +
    'version: ' + AEntry.Version + sLineBreak +
    'error: ' + AEntry.ExceptionClass + ': ' + AEntry.ExceptionMessage + sLineBreak +
    'map address: ' + AEntry.MapAddress + sLineBreak +
    'stack: ' + AEntry.CallStack + sLineBreak +
    'states: ' + LStates + sLineBreak;
end;

function TXcomErrorLog.Write(const AEntry: TXcomErrorEntry): Boolean;
var
  LExisting: TBytes;
  LEntry: TBytes;
  LAll: TBytes;
begin
  Result := False;
  FLastError := '';
  try
    LExisting := nil;
    if FFiles.FileExists(FPath) then
      LExisting := FFiles.ReadAll(FPath);
    LEntry := TEncoding.UTF8.GetBytes(FormatEntry(AEntry) + sLineBreak);
    SetLength(LAll, Length(LExisting) + Length(LEntry));
    if Length(LExisting) > 0 then
      Move(LExisting[0], LAll[0], Length(LExisting));
    Move(LEntry[0], LAll[Length(LExisting)], Length(LEntry));
    TXcomAtomicFileWriter.Write(FFiles, FPath, LAll);
    Result := True;
  except
    on E: Exception do
      FLastError := E.ClassName + ': ' + E.Message;
  end;
end;

end.
