{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the broken light (random flashing)           }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Flash;

// The light level is 16 bit and the old code let the values wrap when they were stored
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>The light that flashes at random (T_LightFlash and P_SpawnLightFlash)</summary>
  TLightFlash = class
  public
    /// <summary>
    ///   The values of a new flash; uses one random number for the first wait. The game then
    ///   clears the special of the sector
    /// </summary>
    class procedure Initialize(const ASector: ILightSector; const ARandom: IGameRandom;
      out AMaxLight, AMinLight, AMaxTime, AMinTime, ACount: Integer); static;
    /// <summary>
    ///   One tic: when the count is over the light goes from the maximum to the minimum or back,
    ///   and the wait is a random number up to the time of the new level, plus one
    /// </summary>
    class procedure Tick(var ACount: Integer; var ALightLevel: SmallInt; AMaxLight, AMinLight,
      AMaxTime, AMinTime: Integer; const ARandom: IGameRandom); static;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Neighbors;

const
  FLASH_MAX_TIME = 64;
  FLASH_MIN_TIME = 7;

{ TLightFlash }

class procedure TLightFlash.Initialize(const ASector: ILightSector; const ARandom: IGameRandom;
  out AMaxLight, AMinLight, AMaxTime, AMinTime, ACount: Integer);
begin
  AMaxLight := ASector.LightLevel;
  AMinLight := TLightNeighbors.Lowest(ASector, ASector.LightLevel);
  AMaxTime := FLASH_MAX_TIME;
  AMinTime := FLASH_MIN_TIME;
  ACount := (ARandom.NextPlay and AMaxTime) + 1;
end;

class procedure TLightFlash.Tick(var ACount: Integer; var ALightLevel: SmallInt; AMaxLight,
  AMinLight, AMaxTime, AMinTime: Integer; const ARandom: IGameRandom);
begin
  ACount := ACount - 1;
  if ACount > 0 then
    Exit;

  if ALightLevel = AMaxLight then
  begin
    ALightLevel := SmallInt(AMinLight);
    ACount := (ARandom.NextPlay and AMinTime) + 1;
  end
  else
  begin
    ALightLevel := SmallInt(AMaxLight);
    ACount := (ARandom.NextPlay and AMaxTime) + 1;
  end;
end;

end.
