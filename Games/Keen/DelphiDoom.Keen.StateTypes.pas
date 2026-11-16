{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the type of a state of an actor                   }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  statetype of kd_def.h                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.StateTypes;

interface

type
  /// <summary>
  ///   How an actor goes through a state: step = it waits the tics, then goes on; slide = it moves a little
  ///   every tic; think = the function is called at every frame and the state never ends by itself;
  ///   stepthink and slidethink = they call the function every frame as well
  /// </summary>
  TKeenProgress = (kpStep, kpSlide, kpThink, kpStepThink, kpSlideThink);

  /// <summary>
  ///   One state of an actor (statetype). The C keeps pointers to functions and to the next state: here the
  ///   three functions are the numbers of DelphiDoom.Keen.ActionIds (0 = none) and the next state is an index
  ///   of the table (-1 = none: the actor is removed). A shape of -1 is an invisible actor, 0 is "the think
  ///   function chooses the shape"
  /// </summary>
  TKeenStateDef = record
    Name: string;
    LeftShape: Integer;
    RightShape: Integer;
    Progress: TKeenProgress;
    Skippable: Boolean;
    PushToFloor: Boolean;
    TicTime: Integer;
    XMove: Integer;
    YMove: Integer;
    Think: Word;
    Contact: Word;
    React: Word;
    NextState: Integer;
  end;

implementation

end.
