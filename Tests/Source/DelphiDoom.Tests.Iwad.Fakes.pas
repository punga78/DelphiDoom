{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the fakes                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Iwad.Intf;

type
  /// <summary>Variables kept in memory (names are not case sensitive, as in Windows)</summary>
  TFakeIwadEnvironment = class(TInterfacedObject, IIwadEnvironment)
  strict private
    FValues: TDictionary<string, string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetValue(const AName, AValue: string);
    function GetValue(const AName: string): string;
  end;

  /// <summary>
  ///   Files kept in memory. Paths are compared as Windows does: the case does not count,
  ///   '/' is '\', repeated separators are one, and a path without drive is in the current folder
  /// </summary>
  TFakeIwadFileSystem = class(TInterfacedObject, IIwadFileSystem)
  strict private
    FFiles: TStringList;
    function Normalize(const APath: string): string;
  public
    CurrentDirectory: string;
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(const APath: string);
    function FileExists(const APath: string): Boolean;
    function ExpandPath(const APath: string): string;
  end;

  /// <summary>Steam applications that are "installed" where the test says</summary>
  TFakeIwadSteam = class(TInterfacedObject, IIwadSteam)
  strict private
    FDirectories: TDictionary<Integer, string>;
  public
    Queries: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Install(AApplicationId: Integer; const ADirectory: string);
    function GetInstallDirectory(AApplicationId: Integer): string;
  end;

  /// <summary>The options of the search, as the test wants them (all on, no extra paths)</summary>
  TFakeIwadOptions = class(TInterfacedObject, IIwadOptions)
  public
    SearchWadDirectory: Boolean;
    SearchWadPath: Boolean;
    SearchSteamPaths: Boolean;
    AdditionalPaths: string;
    constructor Create;
    function GetSearchWadDirectory: Boolean;
    function GetSearchWadPath: Boolean;
    function GetSearchSteamPaths: Boolean;
    function GetAdditionalPaths: string;
  end;

implementation

{ TFakeIwadEnvironment }

constructor TFakeIwadEnvironment.Create;
begin
  inherited Create;
  FValues := TDictionary<string, string>.Create;
end;

destructor TFakeIwadEnvironment.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

procedure TFakeIwadEnvironment.SetValue(const AName, AValue: string);
begin
  FValues.AddOrSetValue(UpperCase(AName), AValue);
end;

function TFakeIwadEnvironment.GetValue(const AName: string): string;
begin
  if not FValues.TryGetValue(UpperCase(AName), Result) then
    Result := '';
end;

{ TFakeIwadFileSystem }

constructor TFakeIwadFileSystem.Create;
begin
  inherited Create;
  FFiles := TStringList.Create;
  FFiles.Sorted := True;
  FFiles.Duplicates := dupIgnore;
  CurrentDirectory := 'R:\cwd';
end;

destructor TFakeIwadFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

function TFakeIwadFileSystem.ExpandPath(const APath: string): string;
var
  LPath: string;
begin
  LPath := StringReplace(APath, '/', '\', [rfReplaceAll]);
  if not ((Length(LPath) >= 2) and (LPath[2] = ':')) then
    LPath := CurrentDirectory + '\' + LPath;
  while Pos('\\', LPath) > 0 do
    LPath := StringReplace(LPath, '\\', '\', [rfReplaceAll]);
  // a '.' folder is the same folder (the engine writes '.\name' when it has no variable)
  while Pos('\.\', LPath) > 0 do
    LPath := StringReplace(LPath, '\.\', '\', [rfReplaceAll]);
  Result := LPath;
end;

function TFakeIwadFileSystem.Normalize(const APath: string): string;
begin
  Result := LowerCase(ExpandPath(APath));
end;

procedure TFakeIwadFileSystem.AddFile(const APath: string);
begin
  FFiles.Add(Normalize(APath));
end;

function TFakeIwadFileSystem.FileExists(const APath: string): Boolean;
var
  LIndex: Integer;
begin
  Result := FFiles.Find(Normalize(APath), LIndex);
end;

{ TFakeIwadSteam }

constructor TFakeIwadSteam.Create;
begin
  inherited Create;
  FDirectories := TDictionary<Integer, string>.Create;
end;

destructor TFakeIwadSteam.Destroy;
begin
  FDirectories.Free;
  inherited Destroy;
end;

procedure TFakeIwadSteam.Install(AApplicationId: Integer; const ADirectory: string);
begin
  FDirectories.AddOrSetValue(AApplicationId, ADirectory);
end;

function TFakeIwadSteam.GetInstallDirectory(AApplicationId: Integer): string;
begin
  Inc(Queries);
  if not FDirectories.TryGetValue(AApplicationId, Result) then
    Result := '';
end;

{ TFakeIwadOptions }

constructor TFakeIwadOptions.Create;
begin
  inherited Create;
  SearchWadDirectory := True;
  SearchWadPath := True;
  SearchSteamPaths := True;
  AdditionalPaths := '';
end;

function TFakeIwadOptions.GetSearchWadDirectory: Boolean;
begin
  Result := SearchWadDirectory;
end;

function TFakeIwadOptions.GetSearchWadPath: Boolean;
begin
  Result := SearchWadPath;
end;

function TFakeIwadOptions.GetSearchSteamPaths: Boolean;
begin
  Result := SearchSteamPaths;
end;

function TFakeIwadOptions.GetAdditionalPaths: string;
begin
  Result := AdditionalPaths;
end;

end.
