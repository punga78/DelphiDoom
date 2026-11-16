{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contracts of the doors                       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): what CheckDoors asks of the game }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Door.Intf;

interface

uses
  DelphiDoom.Greed.Types;

type
  /// <summary>What the doors ask of the game: the time (timecount) and the sound of a door that closes</summary>
  IGreedDoorHost = interface
    ['{B7C3E1A4-5D92-4F08-A6B1-29E0D4F7C583}']
    function GetTimeCount: Integer;
    /// <summary>SoundEffect(SN_DOOR, 15, x, y)</summary>
    procedure PlayDoorSound(AX, AY: TGreedFixed);
  end;

  /// <summary>The wall number of the picture of each kind of door (the lumps door_1 .. door_7 of the archive)</summary>
  IGreedDoorPictures = interface
    ['{4A9D2C61-E7B3-4015-8F6A-C1D3E5B70924}']
    /// <summary>ADoorKind is 1..7</summary>
    function PictureOf(ADoorKind: Integer): Integer;
  end;

implementation

end.
