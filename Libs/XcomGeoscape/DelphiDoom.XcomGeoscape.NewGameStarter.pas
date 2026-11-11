{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - what NewGameState does when OK is        }
{  clicked (Mod::newSave, the geoscape and the screen of the first base)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.NewGameStarter;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomGeoscape.Simulation.Intf,
  DelphiDoom.XcomGeoscape.Navigator.Intf;

type
  /// <summary>Makes the simulation of a game that starts (it needs the saved game and the rules of that game)</summary>
  TXcomSimulationFactory = reference to function(AHost: TXcomStateHost; ASave: TXcomSavedGame;
    ARuleset: TXcomRuleset; const ARandom: IXcomRandom): IXcomGeoscapeSimulation;

  /// <summary>Makes the navigator of the geoscape (the screens of its buttons)</summary>
  TXcomNavigatorFactory = reference to function(AHost: TXcomStateHost): IXcomGeoscapeNavigator;

  /// <summary>
  ///   NewGameState::btnOkClick: a new saved game (Mod::newSave) with the difficulty and the ironman flag, the
  ///   geoscape as the only state and, over it, the choice of the site of the first base. The generator of random
  ///   numbers is given the seed of the game: a fixed one makes a game that can be repeated
  /// </summary>
  TXcomNewGameStarter = class(TInterfacedObject, IXcomNewGameStarter)
  strict private
    FHost: TXcomStateHost;
    FSeed: UInt64;
    FSimulationFactory: TXcomSimulationFactory;
    FNavigatorFactory: TXcomNavigatorFactory;
  public
    /// <param name="AHost">Not owned: the game</param>
    /// <param name="ASeed">The seed of the generator of the game; 0: taken from the clock</param>
    /// <param name="ASimulationFactory">nil: the time goes on and nothing happens</param>
    /// <param name="ANavigatorFactory">nil: the buttons of the geoscape do nothing</param>
    constructor Create(AHost: TXcomStateHost; ASeed: UInt64; const ASimulationFactory: TXcomSimulationFactory;
      const ANavigatorFactory: TXcomNavigatorFactory);
    procedure StartNewGame(ADifficulty: Integer; AIronman: Boolean);
  end;

implementation

uses
  System.Diagnostics, DelphiDoom.XcomSave.NewGame, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomSave.DefaultSettings,
  DelphiDoom.XcomSave.SavedGameHolder, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomGeoscape.GeoscapeState,
  DelphiDoom.XcomGeoscape.BuildNewBaseState;

constructor TXcomNewGameStarter.Create(AHost: TXcomStateHost; ASeed: UInt64;
  const ASimulationFactory: TXcomSimulationFactory; const ANavigatorFactory: TXcomNavigatorFactory);
begin
  inherited Create;
  FHost := AHost;
  FSeed := ASeed;
  FSimulationFactory := ASimulationFactory;
  FNavigatorFactory := ANavigatorFactory;
end;

procedure TXcomNewGameStarter.StartNewGame(ADifficulty: Integer; AIronman: Boolean);
var
  LRuleset: TXcomRuleset;
  LRules: TXcomRulesetRules;
  LRandom: IXcomRandom;
  LSave: TXcomSavedGame;
  LSeed: UInt64;
  LSimulation: IXcomGeoscapeSimulation;
  LNavigator: IXcomGeoscapeNavigator;
  LGeoscape: TXcomGeoscapeState;
begin
  LRuleset := TXcomStrategy.Ruleset(FHost);
  LSeed := FSeed;
  if LSeed = 0 then
    LSeed := UInt64(TStopwatch.GetTimeStamp);
  LRandom := TXcomRandom.Create(LSeed);
  LRules := TXcomRulesetRules.Create(LRuleset);
  try
    LSave := TXcomNewGame.Create(LRuleset, LRules, TXcomDefaultSaveSettings.Create, LRandom).NewSave;
  except
    LRules.Free;
    raise;
  end;
  LSave.Difficulty := ADifficulty;
  LSave.Ironman := AIronman;
  // the saved game is the game's from now on
  FHost.SetSession(TXcomSavedGameHolder.Create(LSave, LRules));
  LSimulation := nil;
  if Assigned(FSimulationFactory) then
    LSimulation := FSimulationFactory(FHost, LSave, LRuleset, LRandom);
  LNavigator := nil;
  if Assigned(FNavigatorFactory) then
    LNavigator := FNavigatorFactory(FHost);
  LGeoscape := TXcomGeoscapeState.Create(FHost, LSimulation, LNavigator);
  FHost.SetState(LGeoscape);
  LGeoscape.Init;
  FHost.PushState(TXcomBuildNewBaseState.Create(FHost, LSave.Bases.Last, LGeoscape.Globe, True));
end;

end.
