{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the logic of the sprites asks to the game   }
{  Port of xGreed (Jim Valavanis): the calls of sprites.pas                     }
{  to raven.pas and the lights of the tiles of r_render.pas                     }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
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

  /// <summary>
  ///   What is next to reallight in the memory of the original. A very hot sprite (heat above 256) lights the nine
  ///   tiles around it without looking where the map ends: on the first and on the last row of the map the original
  ///   writes outside reallight, over the variables that its compiler put before and after it (see
  ///   TGreedLightOverflow). Who implements this takes those writes; without it they are dropped
  /// </summary>
  IGreedLightOverflow = interface
    ['{C4E19A70-5D2B-4B86-9F3E-A07D61B5C3E8}']
    /// <summary>reallight[AIndex] := reallight[AIndex] - AAmount, with AIndex below 0 or from GREED_MAP_TILES on</summary>
    procedure LightOutsideTheMap(AIndex, AAmount: Integer);
  end;

implementation

end.
