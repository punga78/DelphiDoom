{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the tools core library - the fakes                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ToolsCore.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Generics.Defaults, System.IOUtils,
  DelphiDoom.Tools.Intf;

type
  /// <summary>Files in memory (the case of a name does not count); a failure can be asked for</summary>
  TFakeToolFileSystem = class(TInterfacedObject, IToolFileSystem)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    FailRead: Boolean;
    FailWrite: Boolean;
    FailCopy: Boolean;
    CopyCount: Integer;
    constructor Create;
    destructor Destroy; override;
    function FileExists(const APath: string): Boolean;
    function TryReadAllBytes(const APath: string; out ABytes: TBytes): Boolean;
    function TryWriteAllBytes(const APath: string; const ABytes: TBytes): Boolean;
    function TryCopyFile(const ASource, ATarget: string): Boolean;
    procedure PutText(const APath, AText: string);
    function TextOf(const APath: string): string;
  end;

  /// <summary>Remembers what it was told</summary>
  TFakeProgressObserver = class(TInterfacedObject, IProgressObserver)
  public
    Percents: TList<Integer>;
    LastText: string;
    constructor Create;
    destructor Destroy; override;
    procedure ProgressChanged(const AText: string; APercent: Integer);
  end;

  /// <summary>The lines of a golden file whose first word is AKind (the rest of the line is given)</summary>
  TToolsGolden = class
  public
    class function Lines(const AFileName, AKind: string): TArray<string>; static;
    /// <summary>Every line of the file</summary>
    class function AllLines(const AFileName: string): TArray<string>; static;
  end;

implementation

{ TFakeToolFileSystem }

constructor TFakeToolFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create(TIStringComparer.Ordinal);
end;

destructor TFakeToolFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

function TFakeToolFileSystem.FileExists(const APath: string): Boolean;
begin
  Result := FFiles.ContainsKey(APath);
end;

function TFakeToolFileSystem.TryReadAllBytes(const APath: string; out ABytes: TBytes): Boolean;
begin
  Result := (not FailRead) and FFiles.TryGetValue(APath, ABytes);
end;

function TFakeToolFileSystem.TryWriteAllBytes(const APath: string; const ABytes: TBytes): Boolean;
begin
  Result := not FailWrite;
  if Result then
    FFiles.AddOrSetValue(APath, Copy(ABytes, 0, Length(ABytes)));
end;

function TFakeToolFileSystem.TryCopyFile(const ASource, ATarget: string): Boolean;
var
  LBytes: TBytes;
begin
  Inc(CopyCount);
  Result := (not FailCopy) and FFiles.TryGetValue(ASource, LBytes);
  if Result then
    FFiles.AddOrSetValue(ATarget, LBytes);
end;

procedure TFakeToolFileSystem.PutText(const APath, AText: string);
begin
  FFiles.AddOrSetValue(APath, TEncoding.UTF8.GetBytes(AText));
end;

function TFakeToolFileSystem.TextOf(const APath: string): string;
var
  LBytes: TBytes;
begin
  if FFiles.TryGetValue(APath, LBytes) then
    Result := TEncoding.UTF8.GetString(LBytes)
  else
    Result := '';
end;

{ TFakeProgressObserver }

constructor TFakeProgressObserver.Create;
begin
  inherited Create;
  Percents := TList<Integer>.Create;
end;

destructor TFakeProgressObserver.Destroy;
begin
  Percents.Free;
  inherited Destroy;
end;

procedure TFakeProgressObserver.ProgressChanged(const AText: string; APercent: Integer);
begin
  LastText := AText;
  Percents.Add(APercent);
end;

{ TToolsGolden }

class function TToolsGolden.AllLines(const AFileName: string): TArray<string>;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\' + AFileName));
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

class function TToolsGolden.Lines(const AFileName, AKind: string): TArray<string>;
var
  LLines: TStringList;
  LResult: TList<string>;
  LLine: string;
  LPrefix: string;
begin
  LResult := TList<string>.Create;
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\' + AFileName));
    LPrefix := AKind + ' ';
    for LLine in LLines do
      if LLine.StartsWith(LPrefix) then
        LResult.Add(Copy(LLine, Length(LPrefix) + 1, MaxInt));
    Result := LResult.ToArray;
  finally
    LLines.Free;
    LResult.Free;
  end;
end;

end.
