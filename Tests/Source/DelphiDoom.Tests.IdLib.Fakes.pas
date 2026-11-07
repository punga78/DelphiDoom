{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the idLib ports - fakes of the engine services         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdLib.Fakes;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf;

type
  /// <summary>A log that remembers what idLib wrote ("P:" printf, "W:" warning), for the tests</summary>
  TIdLibLogRecorder = class(TInterfacedObject, IIdLibLog)
  private
    FEntries: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
    /// <summary>Adds an entry with the given prefix (the tests record the errors that were raised)</summary>
    procedure Add(const AEntry: string);
    property Entries: TStringList read FEntries;
  end;

  /// <summary>Console variables that answer with the name they are asked (as the C++ harness does)</summary>
  TIdLibEchoCVars = class(TInterfacedObject, IIdLibCVars)
  public
    function GetCVarString(const AName: AnsiString): AnsiString;
  end;

  /// <summary>A file system in memory: files by name, the full path is the name, the time is 1234</summary>
  TIdLibMemoryFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  private
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetFile(const AName: AnsiString; const AData: AnsiString);
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
    function GetFile(const AName: AnsiString): AnsiString;
  end;

implementation

{ TIdLibEchoCVars }

function TIdLibEchoCVars.GetCVarString(const AName: AnsiString): AnsiString;
begin
  Result := AName;
end;

{ TIdLibLogRecorder }

constructor TIdLibLogRecorder.Create;
begin
  inherited Create;
  FEntries := TStringList.Create;
end;

destructor TIdLibLogRecorder.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TIdLibLogRecorder.Printf(const AMessage: string);
begin
  FEntries.Add('P:' + AMessage);
end;

procedure TIdLibLogRecorder.Warning(const AMessage: string);
begin
  FEntries.Add('W:' + AMessage);
end;

procedure TIdLibLogRecorder.Add(const AEntry: string);
begin
  FEntries.Add(AEntry);
end;

{ TIdLibMemoryFileSystem }

constructor TIdLibMemoryFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TIdLibMemoryFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TIdLibMemoryFileSystem.SetFile(const AName: AnsiString; const AData: AnsiString);
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(AData));
  if Length(AData) > 0 then
    Move(AData[1], LBytes[0], Length(AData));
  FFiles.AddOrSetValue(string(AName), LBytes);
end;

function TIdLibMemoryFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
begin
  Result := FFiles.TryGetValue(string(AName), AFile.Data);
  if Result then
  begin
    AFile.FullPath := AName;
    AFile.Timestamp := 1234;
  end;
end;

function TIdLibMemoryFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  FFiles.AddOrSetValue(string(AName), Copy(AData));
  Result := True;
end;

function TIdLibMemoryFileSystem.GetFile(const AName: AnsiString): AnsiString;
var
  LBytes: TBytes;
begin
  Result := '';
  if FFiles.TryGetValue(string(AName), LBytes) and (Length(LBytes) > 0) then
  begin
    SetLength(Result, Length(LBytes));
    Move(LBytes[0], Result[1], Length(LBytes));
  end;
end;

end.
