{******************************************************************************}
{                                                                              }
{  DelphiDoom: the bench of the tests of the battlescape states: a real battle  }
{  of TFTD (Tests\Data\XcomBattle\bg\g01_2) on the fake game of the engine      }
{  tests, with fake screens and sounds                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.Bench;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.Screens.Intf,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.Tests.XcomMod.RealData,
  DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>IXcomBattleScreens that writes down what was asked and gives no screen (or the one set in Next)</summary>
  TFakeBattleScreens = class(TInterfacedObject, IXcomBattleScreens)
  strict private
    FCalls: TStringList;
    FNext: TXcomState;
    function Take(const ACall: string): TXcomState;
  public
    constructor Create;
    destructor Destroy; override;
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
    /// <summary>The names of the screens asked for, in order ("NextTurn", "Infobox:text"...)</summary>
    property Calls: TStringList read FCalls;
    /// <summary>The state the next call gives (then nil again); the caller of the screens owns it</summary>
    property Next: TXcomState read FNext write FNext;
  end;

  /// <summary>IXcomBattleAudio that writes down the sounds ("play depth sound angle", "loop", "stop")</summary>
  TFakeBattleAudio = class(TInterfacedObject, IXcomBattleAudio)
  strict private
    FCalls: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure PlaySound(ADepth, ASound, AAngle: Integer);
    procedure LoopAmbience(ADepth, ASound: Integer);
    procedure StopAmbience;
    property Calls: TStringList read FCalls;
  end;

  /// <summary>
  ///   A battle of the repository with the rules and the pictures of the real TFTD, ready for a state. Without the
  ///   data of the game (Reference\_dati\xcom_tftd) Available is false and the tests pass without checking
  /// </summary>
  TBattleBench = class
  strict private
    FData: TXcomRealData;
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FWorld: TTestWorld;
    FSavedGame: TXcomSavedGame;
    FRandom: IXcomRandom;
    FSession: IXcomBattleSession;
    FScreens: TFakeBattleScreens;
    FScreensRef: IXcomBattleScreens;
    FAudio: TFakeBattleAudio;
    FAudioRef: IXcomBattleAudio;
    class function ReadText(const APath: string): AnsiString; static;
  public
    constructor Create;
    destructor Destroy; override;
    function Available: Boolean;
    /// <summary>A new fake game and the battle of the scenario loaded again (the old ones are freed)</summary>
    procedure Start(const AScenario: string = 'g01_2');
    /// <summary>Frees the game and the battle (the states first)</summary>
    procedure Stop;
    /// <summary>Makes the battlescape state on the session and pushes it; the game owns it</summary>
    function PushBattlescape: TXcomBattlescapeState;
    /// <summary>Clicks the point of the display where the cursor of the tiles goes on a tile; false if it is not on screen</summary>
    function ClickTile(AState: TXcomBattlescapeState; AX, AY: Integer): Boolean;
    property World: TTestWorld read FWorld;
    property Session: IXcomBattleSession read FSession;
    property Screens: TFakeBattleScreens read FScreens;
    property ScreensRef: IXcomBattleScreens read FScreensRef;
    property Audio: TFakeBattleAudio read FAudio;
    property Ruleset: TXcomRuleset read FRuleset;
    property SavedGame: TXcomSavedGame read FSavedGame;
  end;

implementation

uses
  System.IOUtils, System.ZLib, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.Context,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.SaveLink, DelphiDoom.XcomBattlescape.ModSprites,
  DelphiDoom.XcomBattleStates.Graphics, DelphiDoom.XcomBattleStates.Graphics.Intf, DelphiDoom.XcomBattleStates.Session;

type
  TBenchSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

function TBenchSettings.SoldierDiaries: Boolean;
begin
  Result := True;
end;

function TBenchSettings.AllowPsiStrengthImprovement: Boolean;
begin
  Result := False;
end;

function TBenchSettings.PsiStrengthEval: Boolean;
begin
  Result := False;
end;

{ TFakeBattleScreens }

constructor TFakeBattleScreens.Create;
begin
  inherited Create;
  FCalls := TStringList.Create;
end;

destructor TFakeBattleScreens.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

function TFakeBattleScreens.Take(const ACall: string): TXcomState;
begin
  FCalls.Add(ACall);
  Result := FNext;
  FNext := nil;
end;

function TFakeBattleScreens.ActionMenu(AParent: TXcomState; const AAction: TXcomBattleAction; AX,
  AY: Integer): TXcomState;
begin
  Result := Take(Format('ActionMenu:%d,%d', [AX, AY]));
end;

function TFakeBattleScreens.PrimeGrenade(AParent: TXcomState; const AAction: TXcomBattleAction;
  AInInventoryView: Boolean; const AGrenade: TXcomBattleItem): TXcomState;
begin
  Result := Take('PrimeGrenade');
end;

function TFakeBattleScreens.Medikit(AParent: TXcomState; const ATarget: TXcomBattleUnit;
  const AAction: TXcomBattleAction): TXcomState;
begin
  Result := Take('Medikit');
end;

function TFakeBattleScreens.Scanner(AParent: TXcomState; const AAction: TXcomBattleAction): TXcomState;
begin
  Result := Take('Scanner');
end;

function TFakeBattleScreens.UnitInfo(AParent: TXcomState; const AUnit: TXcomBattleUnit; AFromInventory,
  AMindProbe: Boolean): TXcomState;
begin
  Result := Take('UnitInfo');
end;

function TFakeBattleScreens.Inventory(AParent: TXcomState; ATimeUnits: Boolean): TXcomState;
begin
  Result := Take('Inventory');
end;

function TFakeBattleScreens.MiniMap(AParent: TXcomState): TXcomState;
begin
  Result := Take('MiniMap');
end;

function TFakeBattleScreens.Options(AParent: TXcomState): TXcomState;
begin
  Result := Take('Options');
end;

function TFakeBattleScreens.AbortMission(AParent: TXcomState): TXcomState;
begin
  Result := Take('AbortMission');
end;

function TFakeBattleScreens.NextTurn(AParent: TXcomState): TXcomState;
begin
  Result := Take('NextTurn');
end;

function TFakeBattleScreens.Infobox(AParent: TXcomState; const AMessage: string): TXcomState;
begin
  Result := Take('Infobox:' + AMessage);
end;

function TFakeBattleScreens.InfoboxOk(AParent: TXcomState; const AMessage: string): TXcomState;
begin
  Result := Take('InfoboxOk:' + AMessage);
end;

function TFakeBattleScreens.Debriefing(AParent: TXcomState): TXcomState;
begin
  Result := Take('Debriefing');
end;

{ TFakeBattleAudio }

constructor TFakeBattleAudio.Create;
begin
  inherited Create;
  FCalls := TStringList.Create;
end;

destructor TFakeBattleAudio.Destroy;
begin
  FCalls.Free;
  inherited Destroy;
end;

procedure TFakeBattleAudio.PlaySound(ADepth, ASound, AAngle: Integer);
begin
  FCalls.Add(Format('play %d %d %d', [ADepth, ASound, AAngle]));
end;

procedure TFakeBattleAudio.LoopAmbience(ADepth, ASound: Integer);
begin
  FCalls.Add(Format('loop %d %d', [ADepth, ASound]));
end;

procedure TFakeBattleAudio.StopAmbience;
begin
  FCalls.Add('stop');
end;

{ TBattleBench }

constructor TBattleBench.Create;
begin
  inherited Create;
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder <> '' then
  begin
    FRuleset := FData.Load;
    FRules := TXcomRulesetRules.Create(FRuleset);
  end;
end;

destructor TBattleBench.Destroy;
begin
  Stop;
  FRules.Free;
  FRuleset.Free;
  FData.Free;
  inherited Destroy;
end;

function TBattleBench.Available: Boolean;
begin
  Result := Assigned(FRuleset);
end;

class function TBattleBench.ReadText(const APath: string): AnsiString;
var
  LSource: TFileStream;
  LDecompress: TZDecompressionStream;
  LTarget: TBytesStream;
begin
  LSource := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try
    LDecompress := TZDecompressionStream.Create(LSource, 15 + 16);
    try
      LTarget := TBytesStream.Create;
      try
        LTarget.CopyFrom(LDecompress, 0);
        SetString(Result, PAnsiChar(LTarget.Memory), LTarget.Size);
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

procedure TBattleBench.Start(const AScenario: string);
var
  LFolder: string;
  LText: AnsiString;
  LContext: IXcomBattleContext;
  LBattle: TXcomSavedBattleGame;
  LGraphics: IXcomBattleGraphics;
  LFiles: TArray<IYamlNode>;
begin
  Stop;
  LFolder := ExtractFilePath(ParamStr(0));
  while (LFolder <> '') and not DirectoryExists(LFolder + 'Tests\Data\XcomBattle\bg') do
  begin
    if ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) = LFolder then
      raise Exception.Create('Tests\Data\XcomBattle\bg not found');
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  LText := ReadText(LFolder + 'Tests\Data\XcomBattle\bg\' + AScenario + '\start.sav.gz');
  LText := AnsiString(StringReplace(string(LText), #13#10, #10, [rfReplaceAll]));
  LFiles := TYamlFactory.CreateParser.LoadAll(TYamlText(LText));
  FRandom := TXcomRandom.Create(1);
  FSavedGame := TXcomSavedGame.Create;
  FSavedGame.Load(LFiles, FRuleset, FRules, TBenchSettings.Create, False, FRandom);
  LContext := TXcomBattleContext.Create(FRandom, False, False, FRuleset.Constants.FireDamageRange[0],
    FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange, 0);
  FWorld := TTestWorld.Create;
  LGraphics := TXcomBattleGraphics.Create(FData.CreateFiles, nil, TXcomModSprites.Create(FData.CreateFiles),
    FWorld.Game.Resources.GetPalette('PAL_BATTLESCAPE'));
  LBattle := TXcomBattleSaveLink.LoadBattle(FSavedGame, FRuleset, LContext);
  FSession := TXcomBattleSession.Create(FSavedGame, LBattle, FRuleset, FRandom, LContext, LGraphics, True);
  FScreens := TFakeBattleScreens.Create;
  FScreensRef := FScreens;
  FAudio := TFakeBattleAudio.Create;
  FAudioRef := FAudio;
end;

procedure TBattleBench.Stop;
begin
  // the states hold the session: the game goes first
  FreeAndNil(FWorld);
  FSession := nil;
  FScreensRef := nil;
  FScreens := nil;
  FAudioRef := nil;
  FAudio := nil;
  FreeAndNil(FSavedGame);
  FRandom := nil;
end;

function TBattleBench.PushBattlescape: TXcomBattlescapeState;
begin
  Result := TXcomBattlescapeState.Create(FWorld.Game, FSession, FScreensRef, FAudioRef);
  FWorld.Game.PushState(Result);
  FWorld.Wait(40);
end;

function TBattleBench.ClickTile(AState: TXcomBattlescapeState; AX, AY: Integer): Boolean;
var
  LScreenX: Integer;
  LScreenY: Integer;
  LMapX: Integer;
  LMapY: Integer;
begin
  // the cursor of the tiles takes the tile under the mouse, a quarter of a sprite lower (Map::setSelectorPosition)
  LScreenY := 4;
  while LScreenY < 140 do
  begin
    LScreenX := 4;
    while LScreenX < 316 do
    begin
      AState.Map.Camera.ConvertScreenToMap(LScreenX, LScreenY + 10, LMapX, LMapY);
      if (LMapX = AX) and (LMapY = AY) then
      begin
        FWorld.Click(LScreenX * 2, LScreenY * 2);
        Exit(True);
      end;
      Inc(LScreenX, 4);
    end;
    Inc(LScreenY, 4);
  end;
  Result := False;
end;

end.
