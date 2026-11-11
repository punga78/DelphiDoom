{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - how a screen finds the saved game and    }
{  the rules of the game in progress (Game::getSavedGame and Game::getMod)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Strategy;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Rules.Intf, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomMod.Random;

type
  EXcomGeoscapeException = class(Exception);

  /// <summary>
  ///   The saved game and the ruleset of a host, for the screens of the strategy. A host without a game in
  ///   progress or without rules is EXcomGeoscapeException (the C++ would use a null pointer)
  /// </summary>
  TXcomStrategy = class
  public
    class function SavedGame(AHost: TXcomStateHost): TXcomSavedGame; static;
    /// <summary>The generator of the game (RNG): the one of the saved game, shared with the simulation</summary>
    class function Random(AHost: TXcomStateHost): IXcomRandom; static;
    class function Rules(AHost: TXcomStateHost): IXcomGameRules; static;
    class function Ruleset(AHost: TXcomStateHost): TXcomRuleset; static;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGameHolder.Intf;

resourcestring
  SXcomNoSavedGame = 'XcomGeoscape: there is no saved game in progress';
  SXcomNoRules = 'XcomGeoscape: the data has no ruleset';

class function TXcomStrategy.SavedGame(AHost: TXcomStateHost): TXcomSavedGame;
var
  LHolder: IXcomSavedGameHolder;
begin
  if not Supports(AHost.Session, IXcomSavedGameHolder, LHolder) then
    raise EXcomGeoscapeException.Create(SXcomNoSavedGame);
  Result := LHolder.SavedGame;
end;

class function TXcomStrategy.Random(AHost: TXcomStateHost): IXcomRandom;
var
  LHolder: IXcomSavedGameHolder;
begin
  if not Supports(AHost.Session, IXcomSavedGameHolder, LHolder) or (LHolder.Random = nil) then
    raise EXcomGeoscapeException.Create(SXcomNoSavedGame);
  Result := LHolder.Random;
end;

class function TXcomStrategy.Rules(AHost: TXcomStateHost): IXcomGameRules;
begin
  if not Supports(AHost.Resources, IXcomGameRules, Result) then
    raise EXcomGeoscapeException.Create(SXcomNoRules);
end;

class function TXcomStrategy.Ruleset(AHost: TXcomStateHost): TXcomRuleset;
begin
  Result := Rules(AHost).Ruleset;
  if not Assigned(Result) then
    raise EXcomGeoscapeException.Create(SXcomNoRules);
end;

end.
