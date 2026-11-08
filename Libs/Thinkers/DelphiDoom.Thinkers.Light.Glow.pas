{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the glowing light                            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Glow;

// The light level is 16 bit and the old code let the values wrap when they were stored
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>The light that goes up and down smoothly (T_Glow and P_SpawnGlowingLight)</summary>
  TLightGlow = class
  public
    /// <summary>The values of a new glow, which starts going down; the game then clears the special of the sector</summary>
    class procedure Initialize(const ASector: ILightSector; out AMinLight, AMaxLight,
      ADirection: Integer); static;
    /// <summary>
    ///   One tic: moves the light level by 8 in the direction (-1 down, 1 up) and, when it
    ///   reaches the limit, steps back and turns around
    /// </summary>
    class procedure Tick(var ALightLevel: SmallInt; AMinLight, AMaxLight: Integer;
      var ADirection: Integer); static;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Neighbors;

{ TLightGlow }

class procedure TLightGlow.Initialize(const ASector: ILightSector; out AMinLight, AMaxLight,
  ADirection: Integer);
begin
  AMinLight := TLightNeighbors.Lowest(ASector, ASector.LightLevel);
  AMaxLight := ASector.LightLevel;
  ADirection := -1;
end;

class procedure TLightGlow.Tick(var ALightLevel: SmallInt; AMinLight, AMaxLight: Integer;
  var ADirection: Integer);
begin
  case ADirection of
    -1:
      begin
        // down
        ALightLevel := SmallInt(ALightLevel - LIGHT_GLOW_SPEED);
        if ALightLevel <= AMinLight then
        begin
          ALightLevel := SmallInt(ALightLevel + LIGHT_GLOW_SPEED);
          ADirection := 1;
        end;
      end;
    1:
      begin
        // up
        ALightLevel := SmallInt(ALightLevel + LIGHT_GLOW_SPEED);
        if ALightLevel >= AMaxLight then
        begin
          ALightLevel := SmallInt(ALightLevel - LIGHT_GLOW_SPEED);
          ADirection := -1;
        end;
      end;
  end;
end;

end.
