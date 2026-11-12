{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the light of the level on the weapon and on the  }
{  heat sensor                                                                  }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the choice of the color     }
{  table of VI_DrawMaskedPicToBuffer2 of d_video.pas                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.WeaponLight;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Render.State, DelphiDoom.Greed.Hud.Intf;

type
  /// <summary>
  ///   What the HUD reads in the state of the renderer. The weapon is lit as the tile where the player stands:
  ///   without an effect by the light of the tile (maplights * 8) plus the light the sprites leave there; with the
  ///   effects 1 .. 4 by the glowing or flickering table of the frame; with 5 .. 8 at full light when it is the
  ///   turn of that tile in the cycle and by its own light otherwise; with 9 by its own light plus the fourth
  ///   flicker. Any other effect gives the full light. As in the original the choice leaves the effect in the
  ///   wallshadow of the renderer.
  ///   Difference from the original: a tile outside the map counts as the tile 0
  /// </summary>
  TGreedWeaponLight = class(TInterfacedObject, IGreedWeaponLight, IGreedTileLights)
  strict private
    FState: TGreedRenderState;
  public
    /// <summary>AState is the state of the renderer of the level; it is not owned</summary>
    constructor Create(AState: TGreedRenderState);
    function WeaponColormap(AMapSpot: Integer): PByte;
    function RealLight(AMapSpot: Integer): Integer;
  end;

implementation

{ TGreedWeaponLight }

constructor TGreedWeaponLight.Create(AState: TGreedRenderState);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  FState := AState;
end;

function TGreedWeaponLight.RealLight(AMapSpot: Integer): Integer;
begin
  if (AMapSpot < 0) or (AMapSpot >= GREED_MAP_TILES) then
    Result := 0
  else
    Result := FState.RealLight[AMapSpot];
end;

function TGreedWeaponLight.WeaponColormap(AMapSpot: Integer): PByte;
var
  LShadow: Integer;
  LOwnLight: Integer;
begin
  if (AMapSpot < 0) or (AMapSpot >= GREED_MAP_TILES) then
    AMapSpot := 0;
  LShadow := FState.MapEffects[AMapSpot];
  FState.WallShadow := LShadow;
  LOwnLight := FState.MapLights[AMapSpot] * 8 + FState.RealLight[AMapSpot];
  case LShadow of
    0:
      Result := FState.LightColormap(LOwnLight);
    1:
      Result := PByte(NativeUInt(FState.ColorMaps) + NativeUInt(FState.WallGlow * 256));
    2:
      Result := PByte(NativeUInt(FState.ColorMaps) + NativeUInt(FState.WallFlicker1 * 256));
    3:
      Result := PByte(NativeUInt(FState.ColorMaps) + NativeUInt(FState.WallFlicker2 * 256));
    4:
      Result := PByte(NativeUInt(FState.ColorMaps) + NativeUInt(FState.WallFlicker3 * 256));
    5..8:
      if FState.WallCycle = LShadow - 5 then
        Result := FState.ColorMaps
      else
        Result := FState.LightColormap(LOwnLight);
    9:
      Result := FState.LightColormap(LOwnLight + FState.WallFlicker4);
  else
    Result := FState.ColorMaps;
  end;
end;

end.
