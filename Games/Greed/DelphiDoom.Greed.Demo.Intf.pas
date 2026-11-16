{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the recorded games: the pace of the loop         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Demo.Intf;

interface

type
  /// <summary>
  ///   Decides how many tics of the timer are played before each turn of the loop of the game. The loop of the
  ///   program plays the tics that the clock asks for; the game does different things with the same commands when
  ///   the turns fall on other tics (a turn runs the level for the tics that have passed), so a recorded game keeps
  ///   the tics of every turn and gives them back when it is played
  /// </summary>
  IGreedFramePacer = interface
    ['{6D0C3B58-E1F7-4A92-8B45-27A9C6E0D3F1}']
    /// <summary>
    ///   ATics comes in as the tics that the clock asks for and goes out as the tics to play before the turn.
    ///   False: it is not time for the next turn yet (the loop waits and asks again, nothing is played or drawn)
    /// </summary>
    function NextFrame(var ATics: Integer): Boolean;
    /// <summary>There are no more turns: the program stops</summary>
    function Finished: Boolean;
  end;

implementation

end.
