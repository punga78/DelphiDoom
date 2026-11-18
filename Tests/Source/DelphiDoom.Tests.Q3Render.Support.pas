{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R0) - fakes and  }
{  helpers                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Support;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Qvm.Intf, DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf;

type
  /// <summary>An ILog that counts and keeps the warnings</summary>
  TCountingLog = class(TInterfacedObject, ILog)
  strict private
    FWarnings: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: TStringList read FWarnings;
  end;

  /// <summary>Files in memory, found without regard to case; Reads counts the requests</summary>
  TMemoryFiles = class(TInterfacedObject, IQ3RenderFiles)
  strict private
    FFiles: TDictionary<string, TBytes>;
    FReads: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AData: TBytes); overload;
    procedure Add(const AName, AText: string); overload;
    function ReadFile(const AName: AnsiString; out AData: TBytes): Boolean;
    property Reads: TStringList read FReads;
  end;

  /// <summary>A flat memory of 64 KB for the calls that write into the program</summary>
  TFlatMemory = class(TInterfacedObject, IQvmMemory)
  strict private
    FBytes: TBytes;
  public
    constructor Create;
    function GetSize: Integer;
    function GetMask: Integer;
    function ArgPtr(AAddress: Integer; ALength: NativeInt): Pointer;
    function Range(AAddress: Integer; ALength: NativeInt): Pointer;
    function ReadByte(AAddress: Integer): Byte;
    procedure WriteByte(AAddress: Integer; AValue: Byte);
    function ReadInt32(AAddress: Integer): Integer;
    procedure WriteInt32(AAddress: Integer; AValue: Integer);
    function ReadString(AAddress: Integer): AnsiString;
    procedure WriteString(AAddress: Integer; const AText: AnsiString; ABufferSize: Integer);
    function ReadBytes(AAddress: Integer; ALength: NativeInt): TBytes;
    procedure WriteBytes(AAddress: Integer; const ABytes: TBytes);
    procedure Fill(AAddress: Integer; AValue: Byte; ALength: NativeInt);
    procedure Copy(ADestination, ASource: Integer; ALength: NativeInt);
    function ReadSingle(AAddress: Integer): Single;
  end;

  TTestSupport = class
  public
    /// <summary>The system built by hand over files in memory and shader scripts in memory</summary>
    class function BuildSystem(const AFiles: IQ3RenderFiles; const AScripts: TArray<TPair<string, string>>;
      const ALog: ILog = nil): IQ3RenderSystem; static;
    /// <summary>The bytes of an md3 with two frames, one tag (tag_weapon) and one surface with the shader name</summary>
    class function Md3Bytes(const AShader: AnsiString): TBytes; static;
    /// <summary>FNV-1a 64 as 16 hexadecimal digits</summary>
    class function Fnv(const ABytes: TBytes; ACount: Integer): string; static;
    /// <summary>The folder of OpenArena 0.8.8; the test is ignored when it is not there</summary>
    class function OpenArenaFolder: string; static;
    /// <summary>The file system of Framework\Wad over the folder (the base game baseoa, or the missionpack)</summary>
    class function OpenArenaFiles(const AFolder, AGame: string): IGameFileSystem; static;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Wad.Fs.Types, DelphiDoom.Wad.Fs.Factory, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Skip, DelphiDoom.Decl.Source.Intf, DelphiDoom.Decl.Source.Memory, DelphiDoom.Decl.Factory,
  DelphiDoom.Models.Static.Factory, DelphiDoom.Models.Q3Player.Factory, DelphiDoom.MapFile.Bsp.Factory,
  DelphiDoom.Q3Render.Image.Loader, DelphiDoom.Q3Render.Image.Catalog, DelphiDoom.Q3Render.Shader.Registry,
  DelphiDoom.Q3Render.Model.Registry, DelphiDoom.Q3Render.World.Loader, DelphiDoom.Q3Render.System;

{ TCountingLog }

constructor TCountingLog.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor TCountingLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TCountingLog.Info(const AText: string);
begin
end;

procedure TCountingLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TCountingLog.DevWarning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TCountingLog.Error(const AText: string);
begin
  FWarnings.Add(AText);
end;

{ TMemoryFiles }

constructor TMemoryFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
  FReads := TStringList.Create;
end;

destructor TMemoryFiles.Destroy;
begin
  FFiles.Free;
  FReads.Free;
  inherited Destroy;
end;

procedure TMemoryFiles.Add(const AName: string; const AData: TBytes);
begin
  FFiles.AddOrSetValue(LowerCase(AName), AData);
end;

procedure TMemoryFiles.Add(const AName, AText: string);
begin
  Add(AName, TEncoding.ANSI.GetBytes(AText));
end;

function TMemoryFiles.ReadFile(const AName: AnsiString; out AData: TBytes): Boolean;
begin
  FReads.Add(string(AName));
  Result := FFiles.TryGetValue(LowerCase(string(AName)), AData);
end;

{ TTestSupport }

{ TFlatMemory }

constructor TFlatMemory.Create;
begin
  inherited Create;
  SetLength(FBytes, 65536);
end;

function TFlatMemory.GetSize: Integer;
begin
  Result := Length(FBytes);
end;

function TFlatMemory.GetMask: Integer;
begin
  Result := Length(FBytes) - 1;
end;

function TFlatMemory.ArgPtr(AAddress: Integer; ALength: NativeInt): Pointer;
begin
  if AAddress = 0 then
    Exit(nil);
  Result := Range(AAddress, ALength);
end;

function TFlatMemory.Range(AAddress: Integer; ALength: NativeInt): Pointer;
begin
  Result := @FBytes[AAddress and GetMask];
end;

function TFlatMemory.ReadByte(AAddress: Integer): Byte;
begin
  Result := FBytes[AAddress and GetMask];
end;

procedure TFlatMemory.WriteByte(AAddress: Integer; AValue: Byte);
begin
  FBytes[AAddress and GetMask] := AValue;
end;

function TFlatMemory.ReadInt32(AAddress: Integer): Integer;
begin
  Result := PInteger(@FBytes[AAddress and GetMask])^;
end;

procedure TFlatMemory.WriteInt32(AAddress: Integer; AValue: Integer);
begin
  PInteger(@FBytes[AAddress and GetMask])^ := AValue;
end;

function TFlatMemory.ReadSingle(AAddress: Integer): Single;
begin
  Result := PSingle(@FBytes[AAddress and GetMask])^;
end;

function TFlatMemory.ReadString(AAddress: Integer): AnsiString;
begin
  Result := AnsiString(PAnsiChar(@FBytes[AAddress and GetMask]));
end;

procedure TFlatMemory.WriteString(AAddress: Integer; const AText: AnsiString; ABufferSize: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ABufferSize - 1 do
    if LIndex < Length(AText) then
      FBytes[(AAddress + LIndex) and GetMask] := Byte(AText[LIndex + 1])
    else
      FBytes[(AAddress + LIndex) and GetMask] := 0;
end;

function TFlatMemory.ReadBytes(AAddress: Integer; ALength: NativeInt): TBytes;
begin
  SetLength(Result, ALength);
  if ALength > 0 then
    Move(FBytes[AAddress and GetMask], Result[0], ALength);
end;

procedure TFlatMemory.WriteBytes(AAddress: Integer; const ABytes: TBytes);
begin
  if Length(ABytes) > 0 then
    Move(ABytes[0], FBytes[AAddress and GetMask], Length(ABytes));
end;

procedure TFlatMemory.Fill(AAddress: Integer; AValue: Byte; ALength: NativeInt);
begin
  if ALength > 0 then
    FillChar(FBytes[AAddress and GetMask], ALength, AValue);
end;

procedure TFlatMemory.Copy(ADestination, ASource: Integer; ALength: NativeInt);
begin
  if ALength > 0 then
    Move(FBytes[ASource and GetMask], FBytes[ADestination and GetMask], ALength);
end;

{ TTestSupport }

class function TTestSupport.BuildSystem(const AFiles: IQ3RenderFiles; const AScripts: TArray<TPair<string, string>>;
  const ALog: ILog): IQ3RenderSystem;
var
  LMemory: TDeclMemorySource;
  LSource: IDeclSource;
  LPair: TPair<string, string>;
  LImages: IQ3ImageCatalog;
  LShaders: IQ3ShaderRegistry;
  LModels: IQ3ModelRegistry;
  LWorld: IQ3WorldLoader;
begin
  LMemory := TDeclMemorySource.Create;
  LSource := LMemory;
  for LPair in AScripts do
    LMemory.Add(AnsiString(LPair.Key), AnsiString(LPair.Value));
  LImages := TQ3ImageCatalog.Create(TQ3ImageLoader.Create(AFiles, ALog));
  LShaders := TQ3ShaderRegistry.Create(TDeclFactory.CreateQuake3ShaderManager(LSource, nil, True), LImages);
  LModels := TQ3ModelRegistry.Create(AFiles, TStaticModelFactory.CreateMd3Reader, LShaders,
    TQ3PlayerFactory.CreateTagLerper, ALog);
  LWorld := TQ3WorldLoader.Create(AFiles, TBspFactory.CreateReader, TBspFactory.CreateTreeLoader,
    TBspFactory.CreateVisibilityLoader, TBspFactory.CreateLightmapLoader, TBspFactory.CreateLightGridLoader,
    TBspFactory.CreateFaceLoader, TBspFactory.CreateTriangleLoader, TBspFactory.CreateFlareLoader,
    TBspFactory.CreatePatchLoader, 1, ALog);
  Result := TQ3RenderSystem.Create(LImages, LShaders, LModels, LWorld);
end;

class function TTestSupport.Md3Bytes(const AShader: AnsiString): TBytes;
var
  LStream: TBytesStream;

  procedure Int(AValue: Integer);
  begin
    LStream.WriteBuffer(AValue, 4);
  end;

  procedure Flt(AValue: Single);
  begin
    LStream.WriteBuffer(AValue, 4);
  end;

  procedure Text(const AValue: AnsiString; ALength: Integer);
  var
    LBuffer: TBytes;
  begin
    SetLength(LBuffer, ALength);
    if AValue <> '' then
      Move(AValue[1], LBuffer[0], Length(AValue));
    LStream.WriteBuffer(LBuffer[0], ALength);
  end;

  procedure Frame(AMinX, AMaxX: Single; const AName: AnsiString);
  begin
    Flt(AMinX); Flt(-1); Flt(-2);
    Flt(AMaxX); Flt(3); Flt(4);
    Flt(0); Flt(0); Flt(0);
    Flt(5);
    Text(AName, 16);
  end;

  procedure Tag(AOriginX: Single);
  begin
    Text('tag_weapon', 64);
    Flt(AOriginX); Flt(0); Flt(0);
    Flt(1); Flt(0); Flt(0);
    Flt(0); Flt(1); Flt(0);
    Flt(0); Flt(0); Flt(1);
  end;

var
  LSurfaceStart, LIndex: Integer;
begin
  LStream := TBytesStream.Create;
  try
    // header: ofsFrames 108, ofsTags 108 + 2 * 56, ofsSurfaces + 2 * 112, then the surface
    Int($33504449); Int(15); Text('test', 64); Int(0);
    Int(2); Int(1); Int(1); Int(0);
    Int(108); Int(108 + 112); Int(108 + 112 + 224);
    Int(0); // ofsEnd, written below
    Frame(-10, 10, 'first');
    Frame(-20, 20, 'second');
    Tag(0);
    Tag(10);
    LSurfaceStart := Integer(LStream.Position);
    Int($33504449); Text('surf', 64); Int(0); Int(2); Int(1); Int(3); Int(1);
    Int(108); Int(108 + 12); Int(108 + 12 + 68); Int(108 + 12 + 68 + 24); Int(108 + 12 + 68 + 24 + 48);
    // triangles, shaders, st, xyz-normals of both frames
    Int(0); Int(1); Int(2);
    Text(AShader, 64); Int(0);
    for LIndex := 0 to 2 do
    begin
      Flt(LIndex);
      Flt(0);
    end;
    for LIndex := 0 to 5 do
    begin
      LStream.WriteBuffer(LIndex, 2);
      LStream.WriteBuffer(LIndex, 2);
      LStream.WriteBuffer(LIndex, 2);
      LStream.WriteBuffer(LIndex, 2);
    end;
    LIndex := Integer(LStream.Position) - LSurfaceStart;
    LStream.Position := 108 + 112 + 224 + 104;
    LStream.WriteBuffer(LIndex, 4);
    LIndex := Integer(LStream.Size);
    LStream.Position := 104;
    LStream.WriteBuffer(LIndex, 4);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

class function TTestSupport.Fnv(const ABytes: TBytes; ACount: Integer): string;
var
  LHash: UInt64;
  LIndex: Integer;
begin
  LHash := UInt64($CBF29CE484222325);
  for LIndex := 0 to ACount - 1 do
    LHash := (LHash xor ABytes[LIndex]) * UInt64($00000100000001B3);
  Result := LowerCase(IntToHex(LHash, 16));
end;

class function TTestSupport.OpenArenaFolder: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result = '') or not TDirectory.Exists(Result) then
    Result := TTestFiles.FindFolderUp('Reference\openarena\openarena-0.8.8');
  if (Result = '') or not TFile.Exists(TPath.Combine(Result, 'baseoa\pak0.pk3')) then
    TTestSkip.Ignore('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena)');
end;

class function TTestSupport.OpenArenaFiles(const AFolder, AGame: string): IGameFileSystem;
var
  LSettings: TGameFsSettings;
begin
  LSettings := Default(TGameFsSettings);
  LSettings.BasePath := AFolder;
  LSettings.SavePath := TPath.Combine(TPath.GetTempPath, 'ddq3render');
  LSettings.GameBase := 'baseoa';
  LSettings.Game := AGame;
  LSettings.PakExtension := '.pk3';
  Result := TGameFileSystemFactory.CreateOnDisk(LSettings);
  Result.Startup;
end;

end.
