{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the dynamic lights library - the fakes of the game    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DynLights.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.GameState.Intf, DelphiDoom.DynLights.Intf;

type
  /// <summary>The numbers of the stub of m_rnd of the harness: (n * 37 + 11) and 255, n counts the calls</summary>
  TFakeRandom = class(TInterfacedObject, IDynLightRandom)
  private
    FCalls: Integer;
  public
    function NextByte: Integer;
    property Calls: Integer read FCalls;
  end;

  /// <summary>The things and the sprites of the stub of info_common of the harness</summary>
  TFakeNames = class(TInterfacedObject, IDynLightObjectResolver, IDynLightSpriteResolver)
  public
    function ObjectForName(const AUpperName: string): Integer;
    function SpriteForName(const AUpperName: string): Integer;
  end;

  /// <summary>
  ///   The twelve states of the stub of info of the harness: POSS A, B, C, TROO A, B, A, BAR1 A, B,
  ///   PLAY A, B, MISL A and POSS A with a flag in the frame; the player, the zombie, the imp and
  ///   the barrel go through some of them
  /// </summary>
  TFakeStateTable = class(TInterfacedObject, IDynLightStateTable)
  private
    FHasList: array[0..11] of Boolean;
    FLights: array[0..11] of TList<TPair<Integer, Integer>>;
  public
    constructor Create;
    destructor Destroy; override;
    function StateCount: Integer;
    function SpriteOf(AState: Integer): Integer;
    function FrameOf(AState: Integer): Integer;
    function StatesOfObject(AObject: Integer): TArray<Integer>;
    function HasLights(AState: Integer): Boolean;
    procedure CreateLights(AState: Integer);
    procedure RemoveLightsOfObject(AState, AObject: Integer);
    procedure AddLight(AState, AObject, ALight: Integer);
    /// <summary>" (object,light)" for each pair of the state, or nil if the state has no list</summary>
    function Describe(AState: Integer; out AText: string): Boolean;
  end;

  /// <summary>Whether the game was started with -devparm</summary>
  TFakeContext = class(TInterfacedObject, IGameContext)
  private
    FDeveloperMode: Boolean;
  public
    constructor Create(ADeveloperMode: Boolean);
    function IsDeveloperMode: Boolean;
    function IsNetGame: Boolean;
    function IsDemoRecording: Boolean;
    function IsDemoPlayback: Boolean;
    function IsPaused: Boolean;
    function GameTic: Integer;
  end;

  /// <summary>The warnings and the output as they were written, with nothing added</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  private
    FWarnings: string;
    FOutput: string;
  public
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: string read FWarnings;
    property Output: string read FOutput;
  end;

  /// <summary>Lumps and PAK entries in a list</summary>
  TFakeTextSource = class(TInterfacedObject, IDynLightTextSource)
  private
    FLumpNames: TList<string>;
    FLumpTexts: TList<string>;
    FPakNames: TList<string>;
    FPakTexts: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddLump(const AName, AText: string);
    procedure AddPak(const AName, AText: string);
    function WadLumpTexts(const AName: string): TArray<string>;
    function PakTexts(const AFileName: string): TArray<string>;
  end;

  /// <summary>Counts the texts it is given</summary>
  TFakeFilter = class(TInterfacedObject, IDynLightTextFilter)
  private
    FCalls: Integer;
  public
    function Filter(const AText: string): string;
    property Calls: Integer read FCalls;
  end;

implementation

const
  STATE_SPRITES: array[0..11] of Integer = (1, 1, 1, 0, 0, 0, 2, 2, 3, 3, 4, 1);
  STATE_FRAMES: array[0..11] of Integer = (0, 1, 2, 0, 1, 0, 0, 1, 0, 1, 0, $8000);

{ TFakeRandom }

function TFakeRandom.NextByte: Integer;
begin
  Result := (FCalls * 37 + 11) and 255;
  Inc(FCalls);
end;

{ TFakeNames }

function TFakeNames.ObjectForName(const AUpperName: string): Integer;
begin
  if (AUpperName = '') or (AUpperName = '-1') then
    Result := -1
  else if AUpperName = 'PLAYER' then
    Result := 0
  else if AUpperName = 'ZOMBIEMAN' then
    Result := 1
  else if AUpperName = 'IMP' then
    Result := 2
  else if AUpperName = 'BARREL' then
    Result := 3
  else
    Result := -1;
end;

function TFakeNames.SpriteForName(const AUpperName: string): Integer;
begin
  if AUpperName = 'TROO' then
    Result := 0
  else if AUpperName = 'POSS' then
    Result := 1
  else if AUpperName = 'BAR1' then
    Result := 2
  else if AUpperName = 'PLAY' then
    Result := 3
  else if AUpperName = 'MISL' then
    Result := 4
  else
    Result := -1;
end;

{ TFakeStateTable }

constructor TFakeStateTable.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to 11 do
    FLights[LIndex] := TList<TPair<Integer, Integer>>.Create;
end;

destructor TFakeStateTable.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 11 do
    FLights[LIndex].Free;
  inherited Destroy;
end;

function TFakeStateTable.StateCount: Integer;
begin
  Result := 12;
end;

function TFakeStateTable.SpriteOf(AState: Integer): Integer;
begin
  Result := STATE_SPRITES[AState];
end;

function TFakeStateTable.FrameOf(AState: Integer): Integer;
begin
  Result := STATE_FRAMES[AState] and $7FFF;
end;

function TFakeStateTable.StatesOfObject(AObject: Integer): TArray<Integer>;
begin
  case AObject of
    0:
      Result := TArray<Integer>.Create(8, 9);
    1:
      Result := TArray<Integer>.Create(0, 1, 2, 11);
    2:
      Result := TArray<Integer>.Create(3, 4, 5);
    3:
      Result := TArray<Integer>.Create(6, 7);
  else
    Result := nil;
  end;
end;

function TFakeStateTable.HasLights(AState: Integer): Boolean;
begin
  Result := FHasList[AState];
end;

procedure TFakeStateTable.CreateLights(AState: Integer);
begin
  FHasList[AState] := True;
end;

procedure TFakeStateTable.RemoveLightsOfObject(AState, AObject: Integer);
var
  LIndex: Integer;
begin
  for LIndex := FLights[AState].Count - 1 downto 0 do
    if FLights[AState][LIndex].Key = AObject then
      FLights[AState].Delete(LIndex);
end;

procedure TFakeStateTable.AddLight(AState, AObject, ALight: Integer);
begin
  FLights[AState].Add(TPair<Integer, Integer>.Create(AObject, ALight));
end;

function TFakeStateTable.Describe(AState: Integer; out AText: string): Boolean;
var
  LPair: TPair<Integer, Integer>;
begin
  AText := '';
  Result := FHasList[AState];
  if Result then
    for LPair in FLights[AState] do
      AText := AText + ' (' + IntToStr(LPair.Key) + ',' + IntToStr(LPair.Value) + ')';
end;

{ TFakeContext }

constructor TFakeContext.Create(ADeveloperMode: Boolean);
begin
  inherited Create;
  FDeveloperMode := ADeveloperMode;
end;

function TFakeContext.IsDeveloperMode: Boolean;
begin
  Result := FDeveloperMode;
end;

function TFakeContext.IsNetGame: Boolean;
begin
  Result := False;
end;

function TFakeContext.IsDemoRecording: Boolean;
begin
  Result := False;
end;

function TFakeContext.IsDemoPlayback: Boolean;
begin
  Result := False;
end;

function TFakeContext.IsPaused: Boolean;
begin
  Result := False;
end;

function TFakeContext.GameTic: Integer;
begin
  Result := 0;
end;

{ TFakeLog }

procedure TFakeLog.Info(const AText: string);
begin
  FOutput := FOutput + AText;
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FWarnings := FWarnings + AText;
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
end;

procedure TFakeLog.Error(const AText: string);
begin
end;

{ TFakeTextSource }

constructor TFakeTextSource.Create;
begin
  inherited Create;
  FLumpNames := TList<string>.Create;
  FLumpTexts := TList<string>.Create;
  FPakNames := TList<string>.Create;
  FPakTexts := TList<string>.Create;
end;

destructor TFakeTextSource.Destroy;
begin
  FPakTexts.Free;
  FPakNames.Free;
  FLumpTexts.Free;
  FLumpNames.Free;
  inherited Destroy;
end;

procedure TFakeTextSource.AddLump(const AName, AText: string);
begin
  FLumpNames.Add(AName);
  FLumpTexts.Add(AText);
end;

procedure TFakeTextSource.AddPak(const AName, AText: string);
begin
  FPakNames.Add(AName);
  FPakTexts.Add(AText);
end;

function TFakeTextSource.WadLumpTexts(const AName: string): TArray<string>;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to FLumpNames.Count - 1 do
    if FLumpNames[LIndex] = AName then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FLumpTexts[LIndex];
    end;
end;

function TFakeTextSource.PakTexts(const AFileName: string): TArray<string>;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to FPakNames.Count - 1 do
    if FPakNames[LIndex] = AFileName then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FPakTexts[LIndex];
    end;
end;

{ TFakeFilter }

function TFakeFilter.Filter(const AText: string): string;
begin
  Inc(FCalls);
  Result := AText;
end;

end.
