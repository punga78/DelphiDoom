{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - fakes of animations            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.AnimSupport;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Anim.Intf;

type
  /// <summary>Files in memory (IModelFileSource); counts the reads</summary>
  TFakeFiles = class(TInterfacedObject, IModelFileSource)
  strict private
    FFiles: TDictionary<string, AnsiString>;
    FReads: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Put(const AName: string; const AData: AnsiString);
    function ReadFile(const AName: AnsiString; out AData: AnsiString; out ATimeStamp: Int64): Boolean;
    property Reads: Integer read FReads;
  end;

  /// <summary>A log that keeps the warnings</summary>
  TRecordingLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FWarnings: TStringBuilder;
    FCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
    function Text: string;
    property Count: Integer read FCount;
  end;

  /// <summary>The game: what exists is what the test adds</summary>
  TFakeGameLookup = class(TInterfacedObject, IModelDefGameLookup)
  strict private
    FFunctions: TList<string>;
    FEvents: TDictionary<string, Integer>;
    FSkins: TList<string>;
    FFx: TList<string>;
    FEntityDefs: TList<string>;
    FSounds: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFunction(const AName: string);
    procedure AddEvent(const AName: string; const AArgumentCount: Integer);
    procedure AddSkin(const AName: string);
    procedure AddFx(const AName: string);
    procedure AddEntityDef(const AName: string);
    procedure AddSound(const AName: string);
    function FindScriptFunction(const AName: AnsiString): Boolean;
    function FindEvent(const AName: AnsiString; out AArgumentCount: Integer): Boolean;
    function FindSkin(const AName: AnsiString): Boolean;
    function FindFx(const AName: AnsiString): Boolean;
    function FindEntityDef(const AName: AnsiString): Boolean;
    function IsSoundDefaulted(const AName: AnsiString): Boolean;
  end;

  /// <summary>Models and definitions by name</summary>
  TFakeModelDefSource = class(TInterfacedObject, IModelDefSource)
  strict private
    FModels: TDictionary<string, IMd5Model>;
    FDefaultedModels: TList<string>;
    FDefs: TDictionary<string, IModelDef>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddModel(const AName: string; const AModel: IMd5Model);
    procedure AddDefaultedModel(const AName: string);
    procedure AddDef(const AName: string; const ADef: IModelDef);
    function FindMd5Model(const AName: AnsiString; out ADefaulted: Boolean): IMd5Model;
    function FindModelDef(const AName: AnsiString; out ADefaulted: Boolean): IModelDef;
  end;

/// <summary>The synthetic cube animation of Tests\Data\Models\md5 (3 frames, 24 fps)</summary>
function CubeAnimText: AnsiString;
/// <summary>The same animation with only 2 frames: its length is different</summary>
function ShortAnimText: AnsiString;
/// <summary>The animation with another name for the second joint</summary>
function RenamedJointAnimText: AnsiString;
/// <summary>The synthetic cube model</summary>
function CubeModelText: AnsiString;

implementation

uses
  DelphiDoom.Tests.Models.Md5Golden;

function CubeAnimText: AnsiString;
begin
  Result := TMd5Golden.ReadText('cube.md5anim');
end;

function CubeModelText: AnsiString;
begin
  Result := TMd5Golden.ReadText('cube.md5mesh');
end;

function ShortAnimText: AnsiString;
begin
  Result := Replace8(CubeAnimText, 'numFrames 3', 'numFrames 2');
  Result := Replace8(Result, '( -3 -2 -2.25 ) ( 3 2 2 )', '');
  Result := Replace8(Result, 'frame 2 {' + #13#10 + #9 + '3 4.2 0.2 0.0 0.3 0.4' + #13#10 + '}', '');
  Result := Replace8(Result, 'frame 2 {' + #10 + #9 + '3 4.2 0.2 0.0 0.3 0.4' + #10 + '}', '');
end;

function RenamedJointAnimText: AnsiString;
begin
  Result := Replace8(CubeAnimText, '"arm"', '"leg"');
end;

{ TFakeFiles }

constructor TFakeFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, AnsiString>.Create;
end;

destructor TFakeFiles.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeFiles.Put(const AName: string; const AData: AnsiString);
begin
  FFiles.AddOrSetValue(AName, AData);
end;

function TFakeFiles.ReadFile(const AName: AnsiString; out AData: AnsiString; out ATimeStamp: Int64): Boolean;
begin
  Inc(FReads);
  ATimeStamp := 0;
  Result := FFiles.TryGetValue(string(AName), AData);
end;

{ TRecordingLog }

constructor TRecordingLog.Create;
begin
  inherited Create;
  FWarnings := TStringBuilder.Create;
end;

destructor TRecordingLog.Destroy;
begin
  FWarnings.Free;
  inherited Destroy;
end;

procedure TRecordingLog.Printf(const AMessage: string);
begin
end;

procedure TRecordingLog.Warning(const AMessage: string);
begin
  Inc(FCount);
  FWarnings.AppendLine(AMessage);
end;

function TRecordingLog.Text: string;
begin
  Result := FWarnings.ToString;
end;

{ TFakeGameLookup }

constructor TFakeGameLookup.Create;
begin
  inherited Create;
  FFunctions := TList<string>.Create;
  FEvents := TDictionary<string, Integer>.Create;
  FSkins := TList<string>.Create;
  FFx := TList<string>.Create;
  FEntityDefs := TList<string>.Create;
  FSounds := TList<string>.Create;
end;

destructor TFakeGameLookup.Destroy;
begin
  FSounds.Free;
  FEntityDefs.Free;
  FFx.Free;
  FSkins.Free;
  FEvents.Free;
  FFunctions.Free;
  inherited Destroy;
end;

procedure TFakeGameLookup.AddFunction(const AName: string);
begin
  FFunctions.Add(AName);
end;

procedure TFakeGameLookup.AddEvent(const AName: string; const AArgumentCount: Integer);
begin
  FEvents.AddOrSetValue(AName, AArgumentCount);
end;

procedure TFakeGameLookup.AddSkin(const AName: string);
begin
  FSkins.Add(AName);
end;

procedure TFakeGameLookup.AddFx(const AName: string);
begin
  FFx.Add(AName);
end;

procedure TFakeGameLookup.AddEntityDef(const AName: string);
begin
  FEntityDefs.Add(AName);
end;

procedure TFakeGameLookup.AddSound(const AName: string);
begin
  FSounds.Add(AName);
end;

function TFakeGameLookup.FindScriptFunction(const AName: AnsiString): Boolean;
begin
  Result := FFunctions.Contains(string(AName));
end;

function TFakeGameLookup.FindEvent(const AName: AnsiString; out AArgumentCount: Integer): Boolean;
begin
  Result := FEvents.TryGetValue(string(AName), AArgumentCount);
end;

function TFakeGameLookup.FindSkin(const AName: AnsiString): Boolean;
begin
  Result := FSkins.Contains(string(AName));
end;

function TFakeGameLookup.FindFx(const AName: AnsiString): Boolean;
begin
  Result := FFx.Contains(string(AName));
end;

function TFakeGameLookup.FindEntityDef(const AName: AnsiString): Boolean;
begin
  Result := FEntityDefs.Contains(string(AName));
end;

function TFakeGameLookup.IsSoundDefaulted(const AName: AnsiString): Boolean;
begin
  Result := not FSounds.Contains(string(AName));
end;

{ TFakeModelDefSource }

constructor TFakeModelDefSource.Create;
begin
  inherited Create;
  FModels := TDictionary<string, IMd5Model>.Create;
  FDefaultedModels := TList<string>.Create;
  FDefs := TDictionary<string, IModelDef>.Create;
end;

destructor TFakeModelDefSource.Destroy;
begin
  FDefs.Free;
  FDefaultedModels.Free;
  FModels.Free;
  inherited Destroy;
end;

procedure TFakeModelDefSource.AddModel(const AName: string; const AModel: IMd5Model);
begin
  FModels.AddOrSetValue(AName, AModel);
end;

procedure TFakeModelDefSource.AddDefaultedModel(const AName: string);
begin
  FDefaultedModels.Add(AName);
end;

procedure TFakeModelDefSource.AddDef(const AName: string; const ADef: IModelDef);
begin
  FDefs.AddOrSetValue(AName, ADef);
end;

function TFakeModelDefSource.FindMd5Model(const AName: AnsiString; out ADefaulted: Boolean): IMd5Model;
begin
  ADefaulted := FDefaultedModels.Contains(string(AName));
  if ADefaulted or not FModels.TryGetValue(string(AName), Result) then
    Result := nil;
  // the manager gives the default model for a name it does not find: the caller sees it as defaulted
  if (Result = nil) and ADefaulted then
    Result := FModels.Values.ToArray[0];
end;

function TFakeModelDefSource.FindModelDef(const AName: AnsiString; out ADefaulted: Boolean): IModelDef;
begin
  if not FDefs.TryGetValue(string(AName), Result) then
  begin
    Result := nil;
    ADefaulted := False;
  end
  else
    ADefaulted := Result.Defaulted;
end;

end.
