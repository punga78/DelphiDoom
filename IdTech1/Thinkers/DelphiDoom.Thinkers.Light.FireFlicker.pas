{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the fire flicker                             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.FireFlicker;

// The light level is 16 bit and the old code let the values wrap when they were stored
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   The light of a fire (T_FireFlicker and P_SpawnFireFlicker). The thinker is a record of the
  ///   engine: its fields are passed here, so nothing is copied while the game runs
  /// </summary>
  TLightFireFlicker = class
  public
    /// <summary>The values of a new flicker; the game then clears the special of the sector</summary>
    class procedure Initialize(const ASector: ILightSector; const ARules: ILightFlickerRules;
      out AMaxLight, AMinLight, ACount: Integer); static;
    /// <summary>
    ///   One tic: counts down and, when the count is over, moves the light level of the sector
    ///   to a darker one (not below AMinLight) and takes the next wait
    /// </summary>
    class procedure Tick(var ACount: Integer; var ALightLevel: SmallInt; AMinLight, AMaxLight: Integer;
      const ARules: ILightFlickerRules; const ARandom: IGameRandom); static;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Neighbors;

{ TLightFireFlicker }

class procedure TLightFireFlicker.Initialize(const ASector: ILightSector;
  const ARules: ILightFlickerRules; out AMaxLight, AMinLight, ACount: Integer);
begin
  AMaxLight := ASector.LightLevel;
  AMinLight := ARules.InitialMinLight(ASector.LightLevel,
    TLightNeighbors.Lowest(ASector, ASector.LightLevel));
  ACount := ARules.InitialCount;
end;

class procedure TLightFireFlicker.Tick(var ACount: Integer; var ALightLevel: SmallInt;
  AMinLight, AMaxLight: Integer; const ARules: ILightFlickerRules; const ARandom: IGameRandom);
var
  LAmount: Integer;
begin
  ACount := ACount - 1;
  if ACount > 0 then
    Exit;

  LAmount := ARules.NextAmount(ARandom);

  if ALightLevel - LAmount < AMinLight then
    ALightLevel := SmallInt(AMinLight)
  else
    ALightLevel := SmallInt(AMaxLight - LAmount);

  ACount := ARules.NextCount(ARandom);
end;

end.
