{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the fakes                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Fakes;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>A log that keeps the text of every warning as it was given</summary>
  TVoxelFakeLog = class(TInterfacedObject, ILog)
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

  /// <summary>Files in memory by name; it remembers what was asked, in order</summary>
  TVoxelFakeSource = class(TInterfacedObject, IVoxelFileSource)
  strict private
    FFiles: TStringList;
    FDirectoryFiles: TStringList;
    FLumps: TStringList;
    FBytes: TArray<TBytes>;
    FCalls: TStringList;
    function Find(const AList: TStringList; const AName: string; out ABytes: TBytes): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(const AName: string; const ABytes: TBytes);
    procedure AddDirectoryFile(const AName: string; const ABytes: TBytes);
    procedure AddLump(const AName: string; const ABytes: TBytes);
    function TryReadFile(const AName: string; out ABytes: TBytes): Boolean;
    function TryReadDirectoryFile(const AName: string; out ABytes: TBytes): Boolean;
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
    property Calls: TStringList read FCalls;
  end;

  /// <summary>The colors of the game: any function of the color (the same for the old code and the new)</summary>
  TVoxelFakeMapper = class(TInterfacedObject, IVoxelColorMapper)
  public
    function PaletteIndex(const AColor: Cardinal): Byte;
  end;

  /// <summary>Three states and a few sprites, as a game would have</summary>
  TVoxelFakeLookup = class(TInterfacedObject, IVoxelDefinitionLookup)
  public
    function FindState(const AName: string): Integer;
    function FindStatesOfSprite(const ASpriteName: string): TArray<Integer>;
  end;

  /// <summary>A sink that writes what it receives, one line for each call</summary>
  TVoxelFakeSink = class(TInterfacedObject, IVoxelDefinitionSink)
  strict private
    FLines: TStringList;
    FCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function AddVoxel(const AItem: TVoxelDefinitionItem): Integer;
    procedure AddState(const AState: TVoxelDefinitionState);
    procedure CheckSprite(const ASpriteName, AVoxelName: string);
    property Lines: TStringList read FLines;
  end;

implementation

uses
  DelphiDoom.Tests.Voxel.Samples;

{ TVoxelFakeLog }

constructor TVoxelFakeLog.Create;
begin
  inherited Create;
  FWarnings := TStringList.Create;
end;

destructor TVoxelFakeLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TVoxelFakeLog.Info(const AText: string);
begin
end;

procedure TVoxelFakeLog.Warning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TVoxelFakeLog.DevWarning(const AText: string);
begin
  FWarnings.Add(AText);
end;

procedure TVoxelFakeLog.Error(const AText: string);
begin
  FWarnings.Add(AText);
end;

{ TVoxelFakeSource }

constructor TVoxelFakeSource.Create;
begin
  inherited Create;
  FFiles := TStringList.Create;
  FDirectoryFiles := TStringList.Create;
  FLumps := TStringList.Create;
  FCalls := TStringList.Create;
end;

destructor TVoxelFakeSource.Destroy;
begin
  FFiles.Free;
  FDirectoryFiles.Free;
  FLumps.Free;
  FCalls.Free;
  inherited Destroy;
end;

function TVoxelFakeSource.Find(const AList: TStringList; const AName: string;
  out ABytes: TBytes): Boolean;
var
  LIndex: Integer;
begin
  LIndex := AList.IndexOf(AName);
  Result := LIndex >= 0;
  if Result then
    ABytes := FBytes[Integer(AList.Objects[LIndex])]
  else
    ABytes := nil;
end;

procedure TVoxelFakeSource.AddFile(const AName: string; const ABytes: TBytes);
begin
  SetLength(FBytes, Length(FBytes) + 1);
  FBytes[High(FBytes)] := ABytes;
  FFiles.AddObject(AName, TObject(High(FBytes)));
end;

procedure TVoxelFakeSource.AddDirectoryFile(const AName: string; const ABytes: TBytes);
begin
  SetLength(FBytes, Length(FBytes) + 1);
  FBytes[High(FBytes)] := ABytes;
  FDirectoryFiles.AddObject(AName, TObject(High(FBytes)));
end;

procedure TVoxelFakeSource.AddLump(const AName: string; const ABytes: TBytes);
begin
  SetLength(FBytes, Length(FBytes) + 1);
  FBytes[High(FBytes)] := ABytes;
  FLumps.AddObject(AName, TObject(High(FBytes)));
end;

function TVoxelFakeSource.TryReadFile(const AName: string; out ABytes: TBytes): Boolean;
begin
  FCalls.Add('file ' + AName);
  Result := Find(FFiles, AName, ABytes);
end;

function TVoxelFakeSource.TryReadDirectoryFile(const AName: string; out ABytes: TBytes): Boolean;
begin
  FCalls.Add('directory ' + AName);
  Result := Find(FDirectoryFiles, AName, ABytes);
end;

function TVoxelFakeSource.TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
begin
  FCalls.Add('lump ' + AName);
  Result := Find(FLumps, AName, ABytes);
end;

{ TVoxelFakeMapper }

function TVoxelFakeMapper.PaletteIndex(const AColor: Cardinal): Byte;
begin
  Result := TVoxelSamples.PaletteIndexOf(AColor);
end;

{ TVoxelFakeLookup }

function TVoxelFakeLookup.FindState(const AName: string): Integer;
begin
  if AName = 'S_ONE' then
    Result := 1
  else if AName = 'S_TWO' then
    Result := 2
  else if AName = 'S_THREE' then
    Result := 3
  else
    Result := -1;
end;

function TVoxelFakeLookup.FindStatesOfSprite(const ASpriteName: string): TArray<Integer>;
begin
  if ASpriteName = 'TROO' then
    Result := TArray<Integer>.Create(10, 11, 12)
  else if ASpriteName = 'POSS' then
    Result := TArray<Integer>.Create(20)
  else if ASpriteName = 'POSSA' then
    Result := TArray<Integer>.Create(21)
  else if ASpriteName = 'CYBR' then
    Result := TArray<Integer>.Create(30, 31)
  else
    Result := nil;
end;

{ TVoxelFakeSink }

constructor TVoxelFakeSink.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TVoxelFakeSink.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

function TVoxelFakeSink.AddVoxel(const AItem: TVoxelDefinitionItem): Integer;
var
  LOffset, LScale: Single;
begin
  Result := FCount;
  Inc(FCount);
  LOffset := AItem.Offset;
  LScale := AItem.Scale;
  FLines.Add(Format('V %s|%d|%d|%d|%d|%d|%d -> %d', [AItem.Name, PInteger(@LOffset)^,
    PInteger(@LScale)^, AItem.AngleOffset, AItem.DroppedSpin, AItem.PlacedSpin, Integer(AItem.Flags),
    Result]));
end;

procedure TVoxelFakeSink.AddState(const AState: TVoxelDefinitionState);
begin
  FLines.Add(Format('S %d|%d|%d', [AState.VoxelIndex, AState.Frame, AState.State]));
end;

procedure TVoxelFakeSink.CheckSprite(const ASpriteName, AVoxelName: string);
begin
  FLines.Add(Format('C %s|%s', [ASpriteName, AVoxelName]));
end;

end.
