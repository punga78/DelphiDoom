{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the HUD asks of the renderer                }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the reallight array of      }
{  r_render.pas as display.pas reads it                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Hud.Intf;

interface

type
  /// <summary>
  ///   reallight: the light that the sprites leave on the tiles (shots, explosions, the heat of the monsters). The
  ///   heat sensor of the HUD shows it. In the program it is TGreedRenderState.RealLight of the renderer
  /// </summary>
  IGreedTileLights = interface
    ['{5A0E7C31-B84D-4F26-9D13-C7E2A6F80B49}']
    /// <summary>reallight[mapspot]; 0 for a tile outside the map</summary>
    function RealLight(AMapSpot: Integer): Integer;
  end;

  /// <summary>
  ///   The light on the weapon in the hands: the choice of the color table at the start of
  ///   VI_DrawMaskedPicToBuffer2 (TGreedWeaponLight in the program)
  /// </summary>
  IGreedWeaponLight = interface
    ['{C2D94B60-7E15-4A83-B6F0-18A5E3D7C924}']
    /// <summary>The 256 colors of the light of the tile where the player stands (player.mapspot)</summary>
    function WeaponColormap(AMapSpot: Integer): PByte;
  end;

implementation

end.
