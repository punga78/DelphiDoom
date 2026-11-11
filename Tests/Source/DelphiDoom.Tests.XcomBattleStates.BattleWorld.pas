{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape states library - a fake game  }
{  with the battlescape of a real saved battle on screen (the data of TFTD of   }
{  Reference\_dati; without them the tests pass without checking)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattleStates.BattleWorld;

interface

uses
  System.SysUtils, System.Classes, System.ZLib, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomBattle.Intf, DelphiDoom.XcomBattle.SavedBattleGame,
  DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.Screens.Intf,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.Tests.XcomMod.RealData,
  DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>The settings of a saved game of the tests: everything off</summary>
  TBattleWorldSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

  /// <summary>
  ///   The fake game of TTestWorld with the battle of Tests\Data\XcomBattle\bg\g01_2 (a real saved game of TFTD)
  ///   loaded and its battlescape pushed. Owns everything; the battlescape is the game's
  /// </summary>
  TBattleTestWorld = class
  strict private
    class var FData: TXcomRealData;
    class var FRuleset: TXcomRuleset;
    class var FRules: TXcomRulesetRules;
    class var FSaveText: TYamlText;
    class var FLooked: Boolean;
    class function FindUp(const ARelative: string): string; static;
    class function ReadGzip(const APath: string): TYamlText; static;
    class procedure Look; static;
  strict private
    FWorld: TTestWorld;
    FSavedGame: TXcomSavedGame;
    FSession: IXcomBattleSession;
    FParent: TXcomBattlescapeState;
    FDebriefings: Integer;
    FDebriefing: TXcomState;
  public
    class destructor Destroy;
    /// <summary>nil when the data of the real game are not on this machine</summary>
    class function TryCreate: TBattleTestWorld; static;
    constructor Create;
    destructor Destroy; override;
    /// <summary>A click of a button of the mouse at a point of the 320x200 screen</summary>
    procedure ClickButton(AX, AY, AButton: Integer);
    /// <summary>A key pressed and released</summary>
    procedure PressKey(AKey: Integer);
    property World: TTestWorld read FWorld;
    property Session: IXcomBattleSession read FSession;
    property Parent: TXcomBattlescapeState read FParent;
    /// <summary>How many times the battlescape asked for the debriefing</summary>
    property Debriefings: Integer read FDebriefings;
    /// <summary>The empty state given as the debriefing (the game owns it); nil until asked</summary>
    property Debriefing: TXcomState read FDebriefing;
    function Battle: TXcomSavedBattleGame;
  end;

implementation

uses
  DelphiDoom.XcomBattle.Context, DelphiDoom.XcomBattle.SaveLink, DelphiDoom.XcomBattlescape.ModSprites,
  DelphiDoom.XcomBattleStates.Graphics, DelphiDoom.XcomBattleStates.Graphics.Intf,
  DelphiDoom.XcomBattleStates.Session, DelphiDoom.XcomBattleStates.Screens;

const
  SCENARIO = 'Tests\Data\XcomBattle\bg\g01_2\start.sav.gz';
  // the window of the fake game is 640x400 over a screen of 320x200
  WINDOW_SCALE = 2;

{ TBattleWorldSettings }

function TBattleWorldSettings.SoldierDiaries: Boolean;
begin
  Result := False;
end;

function TBattleWorldSettings.AllowPsiStrengthImprovement: Boolean;
begin
  Result := False;
end;

function TBattleWorldSettings.PsiStrengthEval: Boolean;
begin
  Result := False;
end;

{ TBattleTestWorld }

class function TBattleTestWorld.FindUp(const ARelative: string): string;
var
  LFolder: string;
  LLevel: Integer;
begin
  LFolder := ExtractFilePath(ParamStr(0));
  for LLevel := 1 to 8 do
  begin
    Result := LFolder + ARelative;
    if FileExists(Result) then
      Exit;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  Result := '';
end;

class function TBattleTestWorld.ReadGzip(const APath: string): TYamlText;
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

class procedure TBattleTestWorld.Look;
var
  LPath: string;
begin
  if FLooked then
    Exit;
  FLooked := True;
  LPath := FindUp(SCENARIO);
  if LPath = '' then
    Exit;
  FData := TXcomRealData.Create('tftd.xcom2.golden.txt');
  if FData.DataFolder = '' then
    Exit;
  FRuleset := FData.Load;
  FRules := TXcomRulesetRules.Create(FRuleset);
  FSaveText := ReadGzip(LPath);
end;

class destructor TBattleTestWorld.Destroy;
begin
  FRules.Free;
  FRuleset.Free;
  FData.Free;
end;

class function TBattleTestWorld.TryCreate: TBattleTestWorld;
begin
  Look;
  if Assigned(FRuleset) then
    Result := TBattleTestWorld.Create
  else
    Result := nil;
end;

constructor TBattleTestWorld.Create;
var
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LContext: IXcomBattleContext;
  LGraphics: IXcomBattleGraphics;
  LBattle: TXcomSavedBattleGame;
begin
  inherited Create;
  FWorld := TTestWorld.Create;
  LRandom := TXcomRandom.Create(1);
  LSettings := TBattleWorldSettings.Create;
  FSavedGame := TXcomSavedGame.Create;
  FSavedGame.Load(TYamlFactory.CreateParser.LoadAll(FSaveText), FRuleset, FRules, LSettings, False, LRandom);
  LContext := TXcomBattleContext.Create(LRandom, False, False, FRuleset.Constants.FireDamageRange[0],
    FRuleset.Constants.FireDamageRange[1], FRuleset.Constants.DamageRange, FRuleset.Constants.ExplosiveDamageRange,
    0);
  LGraphics := TXcomBattleGraphics.Create(FData.CreateFiles, nil, TXcomModSprites.Create(FData.CreateFiles),
    FWorld.Resources.GetPalette('PAL_BATTLESCAPE'));
  LBattle := TXcomBattleSaveLink.LoadBattle(FSavedGame, FRuleset, LContext);
  FSession := TXcomBattleSession.Create(FSavedGame, LBattle, FRuleset, LRandom, LContext, LGraphics, True);
  FParent := TXcomBattlescapeState.Create(FWorld.Game, FSession, TXcomBattleScreens.Create(
    function(AParent: TXcomState): TXcomState
    begin
      Inc(FDebriefings);
      FDebriefing := TXcomState.Create(AParent.Host);
      Result := FDebriefing;
    end), nil);
  FWorld.Game.PushState(FParent);
  FWorld.Wait(40);
end;

destructor TBattleTestWorld.Destroy;
begin
  // the states hold the session: the game goes first, then the battle of the session, then the saved game
  FWorld.Free;
  FSession := nil;
  FSavedGame.Free;
  inherited Destroy;
end;

function TBattleTestWorld.Battle: TXcomSavedBattleGame;
begin
  Result := FSession.Battle;
end;

procedure TBattleTestWorld.ClickButton(AX, AY, AButton: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekMouseMotion);
  LEvent.X := AX * WINDOW_SCALE;
  LEvent.Y := AY * WINDOW_SCALE;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  LEvent := TXcomInputEvent.Make(ekMouseDown);
  LEvent.X := AX * WINDOW_SCALE;
  LEvent.Y := AY * WINDOW_SCALE;
  LEvent.Button := AButton;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  LEvent.Kind := ekMouseUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
end;

procedure TBattleTestWorld.PressKey(AKey: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekKeyDown);
  LEvent.Key := AKey;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
  LEvent.Kind := ekKeyUp;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Wait(20);
end;

end.
