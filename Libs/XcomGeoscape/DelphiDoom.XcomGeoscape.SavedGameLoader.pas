{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - loading a saved game (LoadGameState)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.SavedGameLoader;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Session.Intf,
  DelphiDoom.XcomGeoscape.NewGameStarter;

type
  /// <summary>Goes on with the battle of the saved game that was just loaded (the host has it)</summary>
  TXcomBattleResumer = reference to procedure(AHost: TXcomStateHost);

  /// <summary>
  ///   What LoadGameState does once its screen is drawn: SavedGame::load of the file (in the folder of the saved
  ///   games of the active master), the saved game as the game's, and the geoscape as the only state. A saved game
  ///   that is in the middle of a battle then goes on with BattleResumer (the Battlescape, another library, pushes
  ///   its screen over the geoscape); without one the geoscape is shown. The simulation and the navigator come from
  ///   the same factories as for a new game
  /// </summary>
  TXcomSavedGameLoader = class(TInterfacedObject, IXcomSavedGameLoader)
  strict private
    FHost: TXcomStateHost;
    FSimulationFactory: TXcomSimulationFactory;
    FNavigatorFactory: TXcomNavigatorFactory;
    FBattleResumer: TXcomBattleResumer;
  public
    /// <param name="AHost">Not owned: the game</param>
    /// <param name="ASimulationFactory">nil: the time goes on and nothing happens</param>
    /// <param name="ANavigatorFactory">nil: the buttons of the geoscape do nothing</param>
    constructor Create(AHost: TXcomStateHost; const ASimulationFactory: TXcomSimulationFactory;
      const ANavigatorFactory: TXcomNavigatorFactory);
    procedure LoadGame(const AFileName: string);
    /// <summary>Called after the geoscape is set when the saved game has a battle in progress; nil: nothing more</summary>
    property BattleResumer: TXcomBattleResumer read FBattleResumer write FBattleResumer;
  end;

implementation

uses
  System.IOUtils, System.AnsiStrings, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.DefaultSettings, DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomSave.SavedGameHolder,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.GeoscapeState, DelphiDoom.XcomGeoscape.Navigator.Intf,
  DelphiDoom.XcomStrategy.Simulation.Intf;

{ TXcomSavedGameLoader }

constructor TXcomSavedGameLoader.Create(AHost: TXcomStateHost; const ASimulationFactory: TXcomSimulationFactory;
  const ANavigatorFactory: TXcomNavigatorFactory);
begin
  inherited Create;
  FHost := AHost;
  FSimulationFactory := ASimulationFactory;
  FNavigatorFactory := ANavigatorFactory;
end;

procedure TXcomSavedGameLoader.LoadGame(const AFileName: string);
var
  LRuleset: TXcomRuleset;
  LRules: TXcomRulesetRules;
  LRandom: IXcomRandom;
  LSettings: IXcomSaveSettings;
  LSave: TXcomSavedGame;
  LBytes: TBytes;
  LText: TYamlText;
  LFile: TArray<IYamlNode>;
  LSimulation: IXcomGeoscapeSimulation;
  LNavigator: IXcomGeoscapeNavigator;
  LGeoscape: TXcomGeoscapeState;
begin
  LRuleset := TXcomStrategy.Ruleset(FHost);
  LBytes := TFile.ReadAllBytes(TPath.Combine(FHost.Options.MasterUserFolder, AFileName));
  SetLength(LText, Length(LBytes));
  if Length(LBytes) > 0 then
    Move(LBytes[0], LText[1], Length(LBytes));
  // the C++ writes the file in text mode: CRLF on Windows
  LText := System.AnsiStrings.StringReplace(LText, #13#10, #10, [rfReplaceAll]);
  LFile := TYamlFactory.CreateParser.LoadAll(LText);
  // the generator takes the seed of the file
  LRandom := TXcomRandom.Create(1);
  // held in a variable: an object made in the call of a const interface parameter is never released
  LSettings := TXcomDefaultSaveSettings.Create;
  LRules := TXcomRulesetRules.Create(LRuleset);
  LSave := TXcomSavedGame.Create;
  try
    LSave.Load(LFile, LRuleset, LRules, LSettings, False, LRandom);
  except
    LSave.Free;
    LRules.Free;
    raise;
  end;
  FHost.SetSession(TXcomSavedGameHolder.Create(LSave, LRules, LRandom));
  LSimulation := nil;
  if Assigned(FSimulationFactory) then
    LSimulation := FSimulationFactory(FHost, LSave, LRuleset, LRandom);
  LNavigator := nil;
  if Assigned(FNavigatorFactory) then
    LNavigator := FNavigatorFactory(FHost);
  LGeoscape := TXcomGeoscapeState.Create(FHost, LSimulation, LNavigator);
  FHost.SetState(LGeoscape);
  LGeoscape.Init;
  if Assigned(LSave.BattleGame) and Assigned(FBattleResumer) then
    FBattleResumer(FHost);
end;

end.
