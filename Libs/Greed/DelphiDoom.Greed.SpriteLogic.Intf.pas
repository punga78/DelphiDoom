{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the logic of the sprites asks to the game   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of sprites.pas    }
{  to raven.pas and the lights of the tiles of r_render.pas                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SpriteLogic.Intf;

interface

uses
  DelphiDoom.Greed.Types;

type
  /// <summary>reallight of r_render.pas: the light that the objects take from each tile, for one frame</summary>
  TGreedTileLights = array[0..GREED_MAP_TILES - 1] of Integer;
  PGreedTileLights = ^TGreedTileLights;

  /// <summary>What the sprites ask to the part of the game that moves the player</summary>
  IGreedSpriteHost = interface
    ['{7B0D4E62-C9A1-4F38-8E57-13A6D2F9B4C0}']
    /// <summary>
    ///   Thrust(angle, speed) of raven.pas: a shot pushes the player along its own angle. The result of the
    ///   original is not used by the sprites
    /// </summary>
    function ThrustPlayer(AAngle: Integer; ASpeed: TGreedFixed): Boolean;
  end;

implementation

end.
