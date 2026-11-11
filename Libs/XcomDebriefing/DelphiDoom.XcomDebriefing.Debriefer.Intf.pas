{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - what the Battlescape asks for when a   }
{  battle is over                                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.Debriefer.Intf;

interface

uses
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomBattle.SavedBattleGame;

type
  /// <summary>
  ///   The end of a battle: the Battlescape (another library) gives the finished battle and gets the screen to push.
  ///   The saved game of the game is changed (the craft is back, the soldiers are promoted or dead, the items are in
  ///   the stores) and forgets its battle; the caller frees the battle. The tests give a fake
  /// </summary>
  IXcomMissionDebriefer = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000301}']
    /// <summary>
    ///   Evaluates the battle and gives the debriefing screen; it owns the report. Without the zombie converter a zombie
    ///   that is recovered is an error
    /// </summary>
    function Debrief(const ABattle: TXcomSavedBattleGame): TXcomState;
  end;

implementation

end.
