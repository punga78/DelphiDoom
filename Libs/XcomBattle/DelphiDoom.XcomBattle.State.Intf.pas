{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - a step of the battle (BattleState)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.State.Intf;

interface

type
  /// <summary>
  ///   One step of what happens on the battlefield (a walk, a shot, an explosion): BattlescapeGame keeps a list of
  ///   them and runs the first one at a time (BattleState)
  /// </summary>
  IXcomBattleState = interface
    ['{4B7C1E90-2A53-4D86-9F18-C3E0A6B57D24}']
    /// <summary>Starts the step</summary>
    procedure Init;
    /// <summary>Runs one tick of the step</summary>
    procedure Think;
    /// <summary>Cancels the step, if it can be cancelled</summary>
    procedure Cancel;
    /// <summary>Called when the step is the first of the list and the game is about to pop it</summary>
    procedure Deinit;
    /// <summary>The name of the kind of step (the C++ class name), for the tests and the logs</summary>
    function StateName: string;
  end;

implementation

end.
