{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - file system of the      }
{  parity driver                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Parity.FileSystem;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Tests.DoomScript.Parity.Output;

type
  /// <summary>
  ///   The file system of the C++ harness: a relative path is a file under the root (or a file made in
  ///   memory by the command "genfile"), its path of the operating system is "/base/" plus the relative
  ///   path. A relative read of an OS path fails, as in the harness. A written file is shown line by line
  ///   in the output ("DISASM" for script/disasm.txt). Not reference counted: the scenario owns it.
  /// </summary>
  TDoomScriptParityFileSystem = class(TNoRefCountObject, IIdLibFileSystem)
  strict private
    FRoot: string;
    FOutput: TDoomScriptParityOutput;
    FMemoryFiles: TDictionary<AnsiString, TBytes>;
    function ReadWhole(const AName: AnsiString; out AData: TBytes): Boolean;
  public
    const
      BASE_PATH: AnsiString = '/base/';
    constructor Create(const ARoot: string; const AOutput: TDoomScriptParityOutput);
    destructor Destroy; override;
    class function IsOsPath(const AName: AnsiString): Boolean; static;
    /// <summary>The command "genfile": a file that exists only in memory</summary>
    procedure SetMemoryFile(const AName, AText: AnsiString);
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

implementation

uses
  System.IOUtils;

constructor TDoomScriptParityFileSystem.Create(const ARoot: string; const AOutput: TDoomScriptParityOutput);
begin
  inherited Create;
  FRoot := ARoot;
  FOutput := AOutput;
  FMemoryFiles := TDictionary<AnsiString, TBytes>.Create;
end;

destructor TDoomScriptParityFileSystem.Destroy;
begin
  FMemoryFiles.Free;
  inherited;
end;

class function TDoomScriptParityFileSystem.IsOsPath(const AName: AnsiString): Boolean;
begin
  Result := Copy(AName, 1, Length(BASE_PATH)) = BASE_PATH;
end;

procedure TDoomScriptParityFileSystem.SetMemoryFile(const AName, AText: AnsiString);
var
  LData: TBytes;
begin
  SetLength(LData, Length(AText));
  if AText <> '' then
    Move(AText[1], LData[0], Length(AText));
  FMemoryFiles.AddOrSetValue(AName, LData);
end;

function TDoomScriptParityFileSystem.ReadWhole(const AName: AnsiString; out AData: TBytes): Boolean;
var
  LPath: string;
begin
  AData := nil;
  if IsOsPath(AName) then
    Exit(False);
  if FMemoryFiles.TryGetValue(AName, AData) then
    Exit(True);
  LPath := TPath.Combine(FRoot, StringReplace(string(AName), '/', '\', [rfReplaceAll]));
  Result := TFile.Exists(LPath);
  if Result then
    AData := TFile.ReadAllBytes(LPath);
end;

function TDoomScriptParityFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
var
  LName: AnsiString;
begin
  LName := AName;
  if AIsOsPath then
  begin
    // idFileSystem::OpenExplicitFileRead of the harness
    if not IsOsPath(LName) then
      Exit(False);
    Delete(LName, 1, Length(BASE_PATH));
  end;
  Result := ReadWhole(LName, AFile.Data);
  if Result then
  begin
    AFile.FullPath := BASE_PATH + LName;
    AFile.Timestamp := 0;
  end;
end;

function TDoomScriptParityFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
var
  LTag: AnsiString;
  LText: AnsiString;
  LStart: Integer;
  LPos: Integer;
begin
  if AName = 'script/disasm.txt' then
    LTag := 'DISASM'
  else
    LTag := 'FILEOUT ' + AName;
  SetLength(LText, Length(AData));
  if LText <> '' then
    Move(AData[0], LText[1], Length(LText));
  LStart := 1;
  while LStart <= Length(LText) do
  begin
    LPos := Pos(AnsiChar(#10), LText, LStart);
    if LPos = 0 then
      LPos := Length(LText) + 1;
    FOutput.Line(LTag + ' ' + TDoomScriptParityOutput.Esc(Copy(LText, LStart, LPos - LStart)));
    LStart := LPos + 1;
  end;
  Result := True;
end;

end.
