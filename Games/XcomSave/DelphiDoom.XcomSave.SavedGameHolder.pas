{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the owner of the saved game of the    }
{  game in progress Derived from OpenXcom (the OpenXcom Developers),           }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version; see Games\XcomFormats\README.md for the license  }
{  of this unit                                                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.SavedGameHolder;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
  DelphiDoom.XcomSave.SavedGameHolder.Intf;

type
  /// <summary>
  ///   Keeps a saved game and the rules adapters it was built with, and frees them in the right order (the saved
  ///   game first). The ruleset itself is not owned: it must outlive the holder
  /// </summary>
  TXcomSavedGameHolder = class(TInterfacedObject, IXcomSavedGameHolder)
  strict private
    FSave: TXcomSavedGame;
    FRules: TXcomRulesetRules;
    FRandom: IXcomRandom;
  public
    /// <param name="ASave">Owned</param>
    /// <param name="ARules">Owned: the adapters that the objects of the saved game use</param>
    /// <param name="ARandom">The generator of the game (shared with the simulation); nil: none</param>
    constructor Create(ASave: TXcomSavedGame; ARules: TXcomRulesetRules; const ARandom: IXcomRandom = nil);
    destructor Destroy; override;
    function SavedGame: TXcomSavedGame;
    function Random: IXcomRandom;
  end;

implementation

constructor TXcomSavedGameHolder.Create(ASave: TXcomSavedGame; ARules: TXcomRulesetRules;
  const ARandom: IXcomRandom);
begin
  inherited Create;
  FSave := ASave;
  FRules := ARules;
  FRandom := ARandom;
end;

function TXcomSavedGameHolder.Random: IXcomRandom;
begin
  Result := FRandom;
end;

destructor TXcomSavedGameHolder.Destroy;
begin
  FSave.Free;
  FRules.Free;
  inherited Destroy;
end;

function TXcomSavedGameHolder.SavedGame: TXcomSavedGame;
begin
  Result := FSave;
end;

end.
