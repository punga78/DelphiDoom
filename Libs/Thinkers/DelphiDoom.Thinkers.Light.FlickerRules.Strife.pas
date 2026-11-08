{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the fire flicker of Strife                   }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2010 James Haley, Samuel Villarreal (Strife changes)          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.FlickerRules.Strife;

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   The fire flicker of Strife: smaller steps (0, 8, 16 or 24 levels), a random wait of 1 to 4
  ///   tics, and a darkest level that is 32 below the light of the sector (not below 0) instead
  ///   of the one of the neighbors. The amount is drawn first, then the wait
  /// </summary>
  TLightStrifeFlickerRules = class(TInterfacedObject, ILightFlickerRules)
  public
    function NextAmount(const ARandom: IGameRandom): Integer;
    function NextCount(const ARandom: IGameRandom): Integer;
    function InitialCount: Integer;
    function InitialMinLight(ASectorLightLevel, ALowestSurrounding: Integer): Integer;
  end;

implementation

const
  FLICKER_STEP = 8;
  FLICKER_INITIAL_COUNT = 2;
  FLICKER_DEPTH = 32;

{ TLightStrifeFlickerRules }

function TLightStrifeFlickerRules.NextAmount(const ARandom: IGameRandom): Integer;
begin
  Result := (ARandom.NextPlay and 3) * FLICKER_STEP;
end;

function TLightStrifeFlickerRules.NextCount(const ARandom: IGameRandom): Integer;
begin
  Result := (ARandom.NextPlay and 3) + 1;
end;

function TLightStrifeFlickerRules.InitialCount: Integer;
begin
  Result := FLICKER_INITIAL_COUNT;
end;

function TLightStrifeFlickerRules.InitialMinLight(ASectorLightLevel,
  ALowestSurrounding: Integer): Integer;
begin
  Result := ASectorLightLevel - FLICKER_DEPTH;
  if Result < 0 then
    Result := 0;
end;

end.
