{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the fakes of the services  }
{  of phase 2b (files, calendar, the commands of the server) and the helpers    }
{  that call a system call directly                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Services;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, System.Generics.Collections, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf,
  DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf, DelphiDoom.Q3Host.Services.Intf;

type
  /// <summary>An open file for reading with its bytes (a file of a folder: no pack)</summary>
  TQ3FakeGameFile = class(TInterfacedObject, IGameFile)
  strict private
    FName: string;
    FData: TBytes;
  public
    constructor Create(const AName: string; const AData: TBytes);
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Integer;
    function GetTimestamp: Int64;
    function GetPack: IGamePack;
    function ReadAll: TBytes;
  end;

  /// <summary>Files in memory by their relative path (lower case), listed by folder and extension</summary>
  TQ3FakeGameFileSystem = class(TInterfacedObject, IGameFileSystem)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AData: TBytes);
    procedure Startup;
    procedure Restart;
    procedure Shutdown;
    function IsInitialized: Boolean;
    function OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags = [TGameSearchFlag.SearchDirs, TGameSearchFlag.SearchPaks];
      const AGameDir: string = ''): IGameFile;
    function ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
    function FileLength(const ARelativePath: string): Integer;
    function FileIsInPak(const ARelativePath: string): Boolean;
    function ListFiles(const ARelativePath, AExtension: string; ASort: Boolean = False;
      AFullRelativePath: Boolean = False; const AGameDir: string = ''): TArray<string>;
    function ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean = False;
      const AGameDir: string = ''): TArray<string>;
    function SearchPaths: TArray<TGameSearchPath>;
    function PackChecksums: TArray<Cardinal>;
    function AddonPackFileNames: TArray<string>;
  end;

  /// <summary>Keeps what is written: the name, the mode and the bytes of each file</summary>
  TQ3FakeGameWriter = class(TInterfacedObject, IGameFileWriter)
  strict private
    FFiles: TDictionary<string, TBytes>;
    FModes: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function OpenFileWrite(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    function OpenFileAppend(const ARelativePath: string; ASync: Boolean = False;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): IGameWriteFile;
    function WriteFile(const ARelativePath: string; const AData: TBytes;
      ABase: TGameWriteBase = TGameWriteBase.SavePath): Integer;
    procedure RemoveFile(const ARelativePath: string);
    function RelativePathToOSPath(const ARelativePath: string; ABase: TGameWriteBase = TGameWriteBase.SavePath): string;
    function Bytes(const AName: string): TBytes;
    property Modes: TStringList read FModes;
    procedure Append(const AName: string; const ABytes: TBytes);
  end;

  TQ3FakeWriteFile = class(TInterfacedObject, IGameWriteFile)
  strict private
    FOwner: TQ3FakeGameWriter;
    FName: string;
    FAppend: Boolean;
  public
    constructor Create(AOwner: TQ3FakeGameWriter; const AName: string; AAppend: Boolean);
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Int64;
    function GetIsAppend: Boolean;
    function Write(const ABytes: TBytes): Integer;
    function WriteText(const AText: AnsiString): Integer;
    procedure Flush;
  end;

  /// <summary>What the server was told to send and to drop</summary>
  TQ3RecordingServerCommands = class(TInterfacedObject, IQ3HostServerCommands)
  strict private
    FSent: TStringList;
    FDropped: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Send(AClient: Integer; const AText: AnsiString);
    procedure Drop(AClient: Integer; const AReason: AnsiString);
    property Sent: TStringList read FSent;
    property Dropped: TStringList read FDropped;
  end;

  TQ3FixedCalendar = class(TInterfacedObject, IQ3HostCalendar)
  public
    function RealTime(out ATime: TQ3HostRealTime): Integer;
  end;

  /// <summary>Calls a system call of a host directly, with up to nine arguments after the number</summary>
  TQ3TestCalls = class
  public
    class function Invoke(const AHost: IQvmHost; const AMachine: IQvmMachine;
      const AValues: array of Integer): Integer; static;
    class function Bits(AValue: Single): Integer; static;
    class function Float(AValue: Integer): Single; static;
    /// <summary>True when the procedure raises an exception of the class (or a descendant)</summary>
    class function Raises(const AProcedure: TProc; AClass: ExceptClass): Boolean; static;
  end;

implementation

{ TQ3FakeGameFile }

constructor TQ3FakeGameFile.Create(const AName: string; const AData: TBytes);
begin
  inherited Create;
  FName := AName;
  FData := AData;
end;

function TQ3FakeGameFile.GetName: string;
begin
  Result := FName;
end;

function TQ3FakeGameFile.GetFullPath: string;
begin
  Result := 'c:\fake\' + FName;
end;

function TQ3FakeGameFile.GetLength: Integer;
begin
  Result := Length(FData);
end;

function TQ3FakeGameFile.GetTimestamp: Int64;
begin
  Result := 0;
end;

function TQ3FakeGameFile.GetPack: IGamePack;
begin
  Result := nil;
end;

function TQ3FakeGameFile.ReadAll: TBytes;
begin
  Result := Copy(FData);
end;

{ TQ3FakeGameFileSystem }

constructor TQ3FakeGameFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TQ3FakeGameFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TQ3FakeGameFileSystem.Add(const AName: string; const AData: TBytes);
begin
  FFiles.AddOrSetValue(LowerCase(AName), AData);
end;

procedure TQ3FakeGameFileSystem.Startup;
begin
end;

procedure TQ3FakeGameFileSystem.Restart;
begin
end;

procedure TQ3FakeGameFileSystem.Shutdown;
begin
end;

function TQ3FakeGameFileSystem.IsInitialized: Boolean;
begin
  Result := True;
end;

function TQ3FakeGameFileSystem.OpenFileRead(const ARelativePath: string; AFlags: TGameSearchFlags;
  const AGameDir: string): IGameFile;
var
  LData: TBytes;
begin
  if FFiles.TryGetValue(LowerCase(ARelativePath), LData) then
    Result := TQ3FakeGameFile.Create(ARelativePath, LData)
  else
    Result := nil;
end;

function TQ3FakeGameFileSystem.ReadFile(const ARelativePath: string; out AData: TBytes): Boolean;
begin
  Result := FFiles.TryGetValue(LowerCase(ARelativePath), AData);
end;

function TQ3FakeGameFileSystem.FileLength(const ARelativePath: string): Integer;
var
  LData: TBytes;
begin
  if FFiles.TryGetValue(LowerCase(ARelativePath), LData) then
    Result := Length(LData)
  else
    Result := -1;
end;

function TQ3FakeGameFileSystem.FileIsInPak(const ARelativePath: string): Boolean;
begin
  Result := False;
end;

function TQ3FakeGameFileSystem.ListFiles(const ARelativePath, AExtension: string; ASort, AFullRelativePath: Boolean;
  const AGameDir: string): TArray<string>;
var
  LName, LFolder: string;
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LFolder := LowerCase(ARelativePath) + '/';
    for LName in FFiles.Keys do
      if LName.StartsWith(LFolder) and LName.EndsWith(LowerCase(AExtension)) and
        (Pos('/', Copy(LName, Length(LFolder) + 1, MaxInt)) = 0) then
        LList.Add(Copy(LName, Length(LFolder) + 1, MaxInt));
    LList.Sort;
    Result := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

function TQ3FakeGameFileSystem.ListFilesTree(const ARelativePath, AExtension: string; ASort: Boolean;
  const AGameDir: string): TArray<string>;
begin
  Result := nil;
end;

function TQ3FakeGameFileSystem.SearchPaths: TArray<TGameSearchPath>;
begin
  Result := nil;
end;

function TQ3FakeGameFileSystem.PackChecksums: TArray<Cardinal>;
begin
  Result := nil;
end;

function TQ3FakeGameFileSystem.AddonPackFileNames: TArray<string>;
begin
  Result := nil;
end;

{ TQ3FakeGameWriter }

constructor TQ3FakeGameWriter.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
  FModes := TStringList.Create;
end;

destructor TQ3FakeGameWriter.Destroy;
begin
  FModes.Free;
  FFiles.Free;
  inherited Destroy;
end;

function TQ3FakeGameWriter.OpenFileWrite(const ARelativePath: string; ABase: TGameWriteBase): IGameWriteFile;
begin
  FModes.Add('write ' + ARelativePath);
  FFiles.AddOrSetValue(ARelativePath, nil);
  Result := TQ3FakeWriteFile.Create(Self, ARelativePath, False);
end;

function TQ3FakeGameWriter.OpenFileAppend(const ARelativePath: string; ASync: Boolean;
  ABase: TGameWriteBase): IGameWriteFile;
begin
  FModes.Add(IfThen(ASync, 'append-sync ', 'append ') + ARelativePath);
  Result := TQ3FakeWriteFile.Create(Self, ARelativePath, True);
end;

function TQ3FakeGameWriter.WriteFile(const ARelativePath: string; const AData: TBytes;
  ABase: TGameWriteBase): Integer;
begin
  FFiles.AddOrSetValue(ARelativePath, AData);
  Result := Length(AData);
end;

procedure TQ3FakeGameWriter.RemoveFile(const ARelativePath: string);
begin
  FFiles.Remove(ARelativePath);
end;

function TQ3FakeGameWriter.RelativePathToOSPath(const ARelativePath: string; ABase: TGameWriteBase): string;
begin
  Result := 'c:\fake\' + ARelativePath;
end;

function TQ3FakeGameWriter.Bytes(const AName: string): TBytes;
begin
  if not FFiles.TryGetValue(AName, Result) then
    Result := nil;
end;

procedure TQ3FakeGameWriter.Append(const AName: string; const ABytes: TBytes);
var
  LOld: TBytes;
begin
  if not FFiles.TryGetValue(AName, LOld) then
    LOld := nil;
  FFiles.AddOrSetValue(AName, LOld + ABytes);
end;

{ TQ3FakeWriteFile }

constructor TQ3FakeWriteFile.Create(AOwner: TQ3FakeGameWriter; const AName: string; AAppend: Boolean);
begin
  inherited Create;
  FOwner := AOwner;
  FName := AName;
  FAppend := AAppend;
end;

function TQ3FakeWriteFile.GetName: string;
begin
  Result := FName;
end;

function TQ3FakeWriteFile.GetFullPath: string;
begin
  Result := 'c:\fake\' + FName;
end;

function TQ3FakeWriteFile.GetLength: Int64;
begin
  Result := Length(FOwner.Bytes(FName));
end;

function TQ3FakeWriteFile.GetIsAppend: Boolean;
begin
  Result := FAppend;
end;

function TQ3FakeWriteFile.Write(const ABytes: TBytes): Integer;
begin
  FOwner.Append(FName, ABytes);
  Result := Length(ABytes);
end;

function TQ3FakeWriteFile.WriteText(const AText: AnsiString): Integer;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], LBytes[0], Length(AText));
  Result := Write(LBytes);
end;

procedure TQ3FakeWriteFile.Flush;
begin
end;

{ TQ3RecordingServerCommands }

constructor TQ3RecordingServerCommands.Create;
begin
  inherited Create;
  FSent := TStringList.Create;
  FDropped := TStringList.Create;
end;

destructor TQ3RecordingServerCommands.Destroy;
begin
  FDropped.Free;
  FSent.Free;
  inherited Destroy;
end;

procedure TQ3RecordingServerCommands.Send(AClient: Integer; const AText: AnsiString);
begin
  FSent.Add(IntToStr(AClient) + ':' + string(AText));
end;

procedure TQ3RecordingServerCommands.Drop(AClient: Integer; const AReason: AnsiString);
begin
  FDropped.Add(IntToStr(AClient) + ':' + string(AReason));
end;

{ TQ3FixedCalendar }

function TQ3FixedCalendar.RealTime(out ATime: TQ3HostRealTime): Integer;
begin
  ATime.Second := 1;
  ATime.Minute := 2;
  ATime.Hour := 3;
  ATime.DayOfMonth := 4;
  ATime.Month := 5;
  ATime.Year := 126;
  ATime.DayOfWeek := 0;
  ATime.DayOfYear := 155;
  ATime.IsDst := 1;
  Result := 1780000000;
end;

{ TQ3TestCalls }

class function TQ3TestCalls.Invoke(const AHost: IQvmHost; const AMachine: IQvmMachine;
  const AValues: array of Integer): Integer;
var
  LArguments: TQvmSystemCallArguments;
  LIndex: Integer;
begin
  FillChar(LArguments, SizeOf(LArguments), 0);
  for LIndex := 0 to High(AValues) do
    LArguments[LIndex] := AValues[LIndex];
  Result := AHost.SystemCall(AMachine, LArguments);
end;

class function TQ3TestCalls.Bits(AValue: Single): Integer;
begin
  Result := PInteger(@AValue)^;
end;

class function TQ3TestCalls.Float(AValue: Integer): Single;
begin
  Result := PSingle(@AValue)^;
end;

class function TQ3TestCalls.Raises(const AProcedure: TProc; AClass: ExceptClass): Boolean;
begin
  try
    AProcedure;
    Result := False;
  except
    on E: Exception do
      Result := E.InheritsFrom(AClass);
  end;
end;

end.
