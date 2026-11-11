{******************************************************************************}
{                                                                              }
{  DelphiDoom: what the tests of the popups of the battle share - a real        }
{  battle (the saved game g01_2 written by the real OpenXcom, with the rules    }
{  of TFTD) in a session, and fakes of the pictures, of the screens and of      }
{  the interface rules                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.Battle;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.ZLib, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.RuleInterface,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.State, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattle.SaveLink, DelphiDoom.XcomBattlescape.Sprites.Intf, DelphiDoom.XcomBattleStates.Graphics.Intf,
  DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.Session,
  DelphiDoom.XcomBattleStates.Screens.Intf, DelphiDoom.Tests.XcomMod.RealData;

type
  /// <summary>The resources of the test world plus the interface "battlescape" with the elements of the popups (TFTD)</summary>
  TTestBattleResources = class(TInterfacedObject, IXcomResources)
  strict private
    FInner: IXcomResources;
    FBattlescape: TXcomRuleInterface;
  public
    constructor Create(const AInner: IXcomResources);
    destructor Destroy; override;
    function GetSurface(const AName: string): TXcomSurface;
    function GetFont(const AName: string): TXcomFont;
    function GetInterface(const AId: string): TXcomRuleInterface;
    function GetPalette(const AName: string): PXcomColor;
    function CursorColor(const APalette: string): Integer;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256);
    function HasSoundDefinitions: Boolean;
    function SoundWave(const ASet: string; AIndex: Integer): TBytes;
    function Constant(const AName: string; ADefault: Integer): Integer;
    function MusicRules: TArray<TXcomMusicRule>;
    function SoundFile(const AName: string): TBytes;
  end;

  /// <summary>The pictures of a battle without pictures: only the voxel data and a palette of grays</summary>
  TTestBattleGraphics = class(TInterfacedObject, IXcomBattleGraphics)
  strict private
    FVoxels: TArray<Word>;
    FPalette: TXcomColors;
  public
    constructor Create(const AVoxels: TArray<Word>);
    function Sprites: IXcomBattleSprites;
    function SurfaceSet(const AName: string): TXcomSurfaceSet;
    function Surface(const AName: string): TXcomSurface;
    function Palette(ADepth: Integer): PXcomColor;
    function Transparencies(ADepth: Integer): TBytes;
    procedure SetPalette(AColors: PXcomColor);
    function VoxelData: TArray<Word>;
  end;

  /// <summary>
  ///   IXcomBattleScreens that remembers what was asked and gives the state put in Next (nil: no screen); the state
  ///   given is the caller's
  /// </summary>
  TTestBattleScreens = class(TInterfacedObject, IXcomBattleScreens)
  public
    Next: TXcomState;
    Calls: string;
    LastParent: TXcomState;
    LastAction: TXcomBattleAction;
    LastTarget: TXcomBattleUnit;
    function Take(const AName: string; AParent: TXcomState; const AAction: TXcomBattleAction): TXcomState;
    function ActionMenu(AParent: TXcomState; const AAction: TXcomBattleAction; AX, AY: Integer): TXcomState;
    function PrimeGrenade(AParent: TXcomState; const AAction: TXcomBattleAction; AInInventoryView: Boolean;
      const AGrenade: TXcomBattleItem): TXcomState;
    function Medikit(AParent: TXcomState; const ATarget: TXcomBattleUnit; const AAction: TXcomBattleAction)
      : TXcomState;
    function Scanner(AParent: TXcomState; const AAction: TXcomBattleAction): TXcomState;
    function UnitInfo(AParent: TXcomState; const AUnit: TXcomBattleUnit; AFromInventory, AMindProbe: Boolean)
      : TXcomState;
    function Inventory(AParent: TXcomState; ATimeUnits: Boolean): TXcomState;
    function MiniMap(AParent: TXcomState): TXcomState;
    function Options(AParent: TXcomState): TXcomState;
    function AbortMission(AParent: TXcomState): TXcomState;
    function NextTurn(AParent: TXcomState): TXcomState;
    function Infobox(AParent: TXcomState; const AMessage: string): TXcomState;
    function InfoboxOk(AParent: TXcomState; const AMessage: string): TXcomState;
    function Debriefing(AParent: TXcomState): TXcomState;
  end;

  /// <summary>The options of the default configuration of OpenXcom</summary>
  TTestBattleSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

  /// <summary>
  ///   The rules of TFTD and the battle of Tests\Data\XcomBattle\bg\g01_2 in a real session. Available is false
  ///   when the data of the game is not on this machine (Reference\_dati\xcom_tftd): the tests then pass empty
  /// </summary>
  TTestBattle = class
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FVoxels: TArray<Word>;
    FScenario: string;
    FGame: TXcomSavedGame;
    FSession: IXcomBattleSession;
    class function FindUp(const ARelative: string; AFolder: Boolean): string; static;
    class function ReadGzip(const APath: string): TYamlText; static;
  public
    constructor Create;
    destructor Destroy; override;
    function Available: Boolean;
    /// <summary>Loads the battle again: a new saved game and a new session</summary>
    procedure Open;
    /// <summary>Lets the session go (the states that hold it must be gone) and frees the saved game</summary>
    procedure Close;
    function FindItem(AId: Integer): TXcomBattleItem;
    function FindUnit(AId: Integer): TXcomBattleUnit;
    property Ruleset: TXcomRuleset read FRuleset;
    property Session: IXcomBattleSession read FSession;
  end;

const
  /// <summary>The soldier that is selected in the saved game (Sung-min Nang: 51 time units)</summary>
  TEST_BATTLE_SOLDIER = 1;
  /// <summary>His gas cannon, in the right hand</summary>
  TEST_BATTLE_GAS_CANNON = 9;
  /// <summary>The magna blast grenade of his belt</summary>
  TEST_BATTLE_GRENADE = 37;
  /// <summary>The sonic cannon of an alien</summary>
  TEST_BATTLE_SONIC_CANNON = 102;

implementation

{ TTestBattleResources }

constructor TTestBattleResources.Create(const AInner: IXcomResources);
begin
  inherited Create;
  FInner := AInner;
  FBattlescape := TXcomRuleInterface.Create('battlescape');
  // the elements of standard\xcom2\interfaces.rul
  FBattlescape.Load(TYamlFactory.CreateParser.Load('elements:'#10 +
    '  - id: grenadeMenu'#10'    color: 47'#10'    color2: 63'#10'    border: 57'#10 +
    '  - id: actionMenu'#10'    color: 47'#10'    color2: 61'#10'    border: 51'#10'    TFTDMode: true'#10 +
    '  - id: grenadeBackground'#10'    color: 59'#10'    color2: 63'#10'    border: 55'#10));
end;

destructor TTestBattleResources.Destroy;
begin
  FBattlescape.Free;
  inherited Destroy;
end;

function TTestBattleResources.GetSurface(const AName: string): TXcomSurface;
begin
  Result := FInner.GetSurface(AName);
end;

function TTestBattleResources.GetFont(const AName: string): TXcomFont;
begin
  Result := FInner.GetFont(AName);
end;

function TTestBattleResources.GetInterface(const AId: string): TXcomRuleInterface;
begin
  if AId = 'battlescape' then
    Result := FBattlescape
  else
    Result := FInner.GetInterface(AId);
end;

function TTestBattleResources.GetPalette(const AName: string): PXcomColor;
begin
  Result := FInner.GetPalette(AName);
end;

function TTestBattleResources.CursorColor(const APalette: string): Integer;
begin
  Result := FInner.CursorColor(APalette);
end;

procedure TTestBattleResources.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
begin
  FInner.SetPalette(AColors, AFirst, ACount);
end;

function TTestBattleResources.HasSoundDefinitions: Boolean;
begin
  Result := FInner.HasSoundDefinitions;
end;

function TTestBattleResources.SoundWave(const ASet: string; AIndex: Integer): TBytes;
begin
  Result := FInner.SoundWave(ASet, AIndex);
end;

function TTestBattleResources.Constant(const AName: string; ADefault: Integer): Integer;
begin
  Result := FInner.Constant(AName, ADefault);
end;

function TTestBattleResources.MusicRules: TArray<TXcomMusicRule>;
begin
  Result := FInner.MusicRules;
end;

function TTestBattleResources.SoundFile(const AName: string): TBytes;
begin
  Result := FInner.SoundFile(AName);
end;

{ TTestBattleGraphics }

constructor TTestBattleGraphics.Create(const AVoxels: TArray<Word>);
var
  LIndex: Integer;
begin
  inherited Create;
  FVoxels := AVoxels;
  for LIndex := 0 to 255 do
  begin
    FPalette[LIndex].Red := LIndex;
    FPalette[LIndex].Green := LIndex;
    FPalette[LIndex].Blue := LIndex;
    FPalette[LIndex].Alpha := 255;
  end;
end;

function TTestBattleGraphics.Sprites: IXcomBattleSprites;
begin
  Result := nil;
end;

function TTestBattleGraphics.SurfaceSet(const AName: string): TXcomSurfaceSet;
begin
  Result := nil;
end;

function TTestBattleGraphics.Surface(const AName: string): TXcomSurface;
begin
  Result := nil;
end;

function TTestBattleGraphics.Palette(ADepth: Integer): PXcomColor;
begin
  Result := @FPalette[0];
end;

function TTestBattleGraphics.Transparencies(ADepth: Integer): TBytes;
begin
  Result := nil;
end;

procedure TTestBattleGraphics.SetPalette(AColors: PXcomColor);
begin
  // no surface to recolor
end;

function TTestBattleGraphics.VoxelData: TArray<Word>;
begin
  Result := FVoxels;
end;

{ TTestBattleScreens }

function TTestBattleScreens.Take(const AName: string; AParent: TXcomState;
  const AAction: TXcomBattleAction): TXcomState;
begin
  Calls := Calls + AName + ';';
  LastParent := AParent;
  LastAction := AAction;
  Result := Next;
  Next := nil;
end;

function TTestBattleScreens.ActionMenu(AParent: TXcomState; const AAction: TXcomBattleAction; AX,
  AY: Integer): TXcomState;
begin
  Result := Take('ActionMenu', AParent, AAction);
end;

function TTestBattleScreens.PrimeGrenade(AParent: TXcomState; const AAction: TXcomBattleAction;
  AInInventoryView: Boolean; const AGrenade: TXcomBattleItem): TXcomState;
begin
  Result := Take('PrimeGrenade', AParent, AAction);
end;

function TTestBattleScreens.Medikit(AParent: TXcomState; const ATarget: TXcomBattleUnit;
  const AAction: TXcomBattleAction): TXcomState;
begin
  LastTarget := ATarget;
  Result := Take('Medikit', AParent, AAction);
end;

function TTestBattleScreens.Scanner(AParent: TXcomState; const AAction: TXcomBattleAction): TXcomState;
begin
  Result := Take('Scanner', AParent, AAction);
end;

function TTestBattleScreens.UnitInfo(AParent: TXcomState; const AUnit: TXcomBattleUnit; AFromInventory,
  AMindProbe: Boolean): TXcomState;
begin
  Result := Take('UnitInfo', AParent, nil);
end;

function TTestBattleScreens.Inventory(AParent: TXcomState; ATimeUnits: Boolean): TXcomState;
begin
  Result := Take('Inventory', AParent, nil);
end;

function TTestBattleScreens.MiniMap(AParent: TXcomState): TXcomState;
begin
  Result := Take('MiniMap', AParent, nil);
end;

function TTestBattleScreens.Options(AParent: TXcomState): TXcomState;
begin
  Result := Take('Options', AParent, nil);
end;

function TTestBattleScreens.AbortMission(AParent: TXcomState): TXcomState;
begin
  Result := Take('AbortMission', AParent, nil);
end;

function TTestBattleScreens.NextTurn(AParent: TXcomState): TXcomState;
begin
  Result := Take('NextTurn', AParent, nil);
end;

function TTestBattleScreens.Infobox(AParent: TXcomState; const AMessage: string): TXcomState;
begin
  Result := Take('Infobox', AParent, nil);
end;

function TTestBattleScreens.InfoboxOk(AParent: TXcomState; const AMessage: string): TXcomState;
begin
  Result := Take('InfoboxOk', AParent, nil);
end;

function TTestBattleScreens.Debriefing(AParent: TXcomState): TXcomState;
begin
  Result := Take('Debriefing', AParent, nil);
end;

{ TTestBattleSettings }

function TTestBattleSettings.SoldierDiaries: Boolean;
begin
  Result := True;
end;

function TTestBattleSettings.AllowPsiStrengthImprovement: Boolean;
begin
  Result := False;
end;

function TTestBattleSettings.PsiStrengthEval: Boolean;
begin
  Result := False;
end;

{ TTestBattle }

class function TTestBattle.FindUp(const ARelative: string; AFolder: Boolean): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 8 do
  begin
    Result := LFolder + ARelative;
    if (AFolder and DirectoryExists(Result)) or ((not AFolder) and FileExists(Result)) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TTestBattle.ReadGzip(const APath: string): TYamlText;
var
  LSource: TFileStream;
  LDecompress: TZDecompressionStream;
  LTarget: TBytesStream;
begin
  Result := '';
  LSource := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try
    LDecompress := TZDecompressionStream.Create(LSource, 15 + 16);
    try
      LTarget := TBytesStream.Create;
      try
        LTarget.CopyFrom(LDecompress, 0);
        SetLength(Result, LTarget.Size);
        if LTarget.Size > 0 then
          Move(LTarget.Bytes[0], Result[1], LTarget.Size);
      finally
        LTarget.Free;
      end;
    finally
      LDecompress.Free;
    end;
  finally
    LSource.Free;
  end;
end;

constructor TTestBattle.Create;
var
  LPath: string;
  LBytes: TBytes;
  LIndex: Integer;
begin
  inherited Create;
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  FScenario := FindUp('Tests\Data\XcomBattle\bg\g01_2\start.sav.gz', False);
  LPath := FindUp('Reference\_dati\xcom_tftd\TFTD\TERRAIN\LOFTEMPS.DAT', False);
  if (FData.DataFolder = '') or (FScenario = '') or (LPath = '') then
    Exit;
  LBytes := TFile.ReadAllBytes(LPath);
  SetLength(FVoxels, Length(LBytes) div 2);
  for LIndex := 0 to High(FVoxels) do
    FVoxels[LIndex] := Word(LBytes[LIndex * 2]) or (Word(LBytes[LIndex * 2 + 1]) shl 8);
  FRuleset := FData.Load;
  FRules := TXcomRulesetRules.Create(FRuleset);
end;

destructor TTestBattle.Destroy;
begin
  Close;
  FRules.Free;
  FRuleset.Free;
  FData.Free;
  inherited Destroy;
end;

function TTestBattle.Available: Boolean;
begin
  Result := Assigned(FRuleset);
end;

procedure TTestBattle.Open;
var
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LContext: IXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
begin
  Close;
  LRandom := TXcomRandom.Create(1);
  LSettings := TTestBattleSettings.Create;
  FGame := TXcomSavedGame.Create;
  FGame.Load(TYamlFactory.CreateParser.LoadAll(ReadGzip(FScenario)), FRuleset, FRules, LSettings, False, LRandom);
  LContext := TXcomBattleContext.Create(LRandom, False, False, FRuleset.Constants.FireDamageRange[0],
    FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange,
    0);
  LBattle := TXcomBattleSaveLink.LoadBattle(FGame, FRuleset, LContext);
  FSession := TXcomBattleSession.Create(FGame, LBattle, FRuleset, LRandom, LContext,
    TTestBattleGraphics.Create(FVoxels), True);
end;

procedure TTestBattle.Close;
begin
  FSession := nil;
  FreeAndNil(FGame);
end;

function TTestBattle.FindItem(AId: Integer): TXcomBattleItem;
var
  LItem: TXcomBattleItem;
begin
  Result := nil;
  for LItem in FSession.Battle.Items do
    if LItem.Id = AId then
      Exit(LItem);
end;

function TTestBattle.FindUnit(AId: Integer): TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
begin
  Result := nil;
  for LUnit in FSession.Battle.Units do
    if LUnit.Id = AId then
      Exit(LUnit);
end;

end.
