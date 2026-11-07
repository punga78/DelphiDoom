{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - the fakes                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Platform.Intf,
  DelphiDoom.Platform.Types;

type
  /// <summary>A directory that is whatever the test says</summary>
  TFakeTempDirectory = class(TInterfacedObject, ITempDirectory)
  public
    Path: string;
    constructor Create(const APath: string);
    function Directory: string;
  end;

  /// <summary>Files in memory: remembers the directories made and the files deleted</summary>
  TMemoryFileStore = class(TInterfacedObject, IFileStore)
  public
    Files: TDictionary<string, TBytes>;
    Directories: TList<string>;
    Deleted: TList<string>;
    /// <summary>When True every directory request fails</summary>
    FailDirectories: Boolean;
    constructor Create;
    destructor Destroy; override;
    function Exists(const AName: string): Boolean;
    function Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
    function Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
    function Read(const AName: string): TBytes;
    function Delete(const AName: string): Boolean;
    function EnsureDirectory(const APath: string): Boolean;
  end;

  /// <summary>Version numbers given by the test</summary>
  TFakeVersionSource = class(TInterfacedObject, IOperatingSystemSource)
  public
    Version: TOperatingSystemVersion;
    function Read: TOperatingSystemVersion;
  end;

implementation

{ TFakeTempDirectory }

constructor TFakeTempDirectory.Create(const APath: string);
begin
  inherited Create;
  Path := APath;
end;

function TFakeTempDirectory.Directory: string;
begin
  Result := Path;
end;

{ TMemoryFileStore }

constructor TMemoryFileStore.Create;
begin
  inherited Create;
  Files := TDictionary<string, TBytes>.Create;
  Directories := TList<string>.Create;
  Deleted := TList<string>.Create;
end;

destructor TMemoryFileStore.Destroy;
begin
  Files.Free;
  Directories.Free;
  Deleted.Free;
  inherited Destroy;
end;

function TMemoryFileStore.Exists(const AName: string): Boolean;
begin
  Result := Files.ContainsKey(AName);
end;

function TMemoryFileStore.Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, ALength);
  if ALength > 0 then
    Move(ASource^, LBytes[0], ALength);
  Files.AddOrSetValue(AName, LBytes);
  Result := ALength > 0;
end;

function TMemoryFileStore.Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
var
  LBytes: TBytes;
  LOld: Integer;
begin
  if not Files.TryGetValue(AName, LBytes) then
    LBytes := nil;
  LOld := Length(LBytes);
  SetLength(LBytes, LOld + ALength);
  if ALength > 0 then
    Move(ASource^, LBytes[LOld], ALength);
  Files.AddOrSetValue(AName, LBytes);
  Result := ALength;
end;

function TMemoryFileStore.Read(const AName: string): TBytes;
begin
  if not Files.TryGetValue(AName, Result) then
    raise EPlatformException.CreateFmt(SPlatformFileNotRead, [AName]);
end;

function TMemoryFileStore.Delete(const AName: string): Boolean;
begin
  Result := Files.ContainsKey(AName);
  Files.Remove(AName);
  Deleted.Add(AName);
end;

function TMemoryFileStore.EnsureDirectory(const APath: string): Boolean;
begin
  Directories.Add(APath);
  Result := not FailDirectories;
end;

{ TFakeVersionSource }

function TFakeVersionSource.Read: TOperatingSystemVersion;
begin
  Result := Version;
end;

end.
