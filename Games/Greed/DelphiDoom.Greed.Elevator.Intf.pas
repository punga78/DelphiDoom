{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the elevators                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): CheckElevators of raven.pas }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Elevator.Intf;

interface

uses
  DelphiDoom.Greed.Types;

const
  /// <summary>MOVEDELAY: tics between two movements of an elevator</summary>
  GREED_MOVE_DELAY = 7;
  /// <summary>TICRATE</summary>
  GREED_TIC_RATE = 70;
  /// <summary>FALLUNIT: how much the fall rate of the player grows when the floor goes away</summary>
  GREED_FALL_UNIT = GREED_FRACUNIT;
  /// <summary>SN_ELEVATORSTART</summary>
  GREED_SN_ELEVATOR_START = 48;

type
  /// <summary>What the elevators ask to the rest of the game</summary>
  IGreedElevatorHost = interface
    ['{7A41C0E5-2B96-4D73-8E1F-C5D2A9B04F68}']
    /// <summary>timecount of the player: the tics of the level</summary>
    function GetTimeCount: Integer;
    /// <summary>SoundEffect(sound, variation, x, y)</summary>
    procedure PlaySound(ASound, AVariation: Integer; AX, AY: TGreedFixed);
    /// <summary>RunEvent(eval, false)</summary>
    procedure RunEvent(AEvent: Integer);
    property TimeCount: Integer read GetTimeCount;
  end;

implementation

end.
