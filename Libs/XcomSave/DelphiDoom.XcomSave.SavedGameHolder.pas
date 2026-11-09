{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the owner of the saved game of the     }
{  game in progress                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.SavedGameHolder;

interface

uses
  System.SysUtils, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.RulesetRules,
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
  public
    /// <param name="ASave">Owned</param>
    /// <param name="ARules">Owned: the adapters that the objects of the saved game use</param>
    constructor Create(ASave: TXcomSavedGame; ARules: TXcomRulesetRules);
    destructor Destroy; override;
    function SavedGame: TXcomSavedGame;
  end;

implementation

constructor TXcomSavedGameHolder.Create(ASave: TXcomSavedGame; ARules: TXcomRulesetRules);
begin
  inherited Create;
  FSave := ASave;
  FRules := ARules;
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
