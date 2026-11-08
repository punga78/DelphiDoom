{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the fire flicker of Doom, Heretic and Hexen  }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.FlickerRules.Standard;

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>
  ///   The fire flicker of id Software: it changes every 4 tics by 0, 16, 32 or 48 levels and
  ///   never goes below the darkest neighbor plus 16. Only the amount uses the random
  /// </summary>
  TLightStandardFlickerRules = class(TInterfacedObject, ILightFlickerRules)
  public
    function NextAmount(const ARandom: IGameRandom): Integer;
    function NextCount(const ARandom: IGameRandom): Integer;
    function InitialCount: Integer;
    function InitialMinLight(ASectorLightLevel, ALowestSurrounding: Integer): Integer;
  end;

implementation

const
  FLICKER_STEP = 16;
  FLICKER_COUNT = 4;

{ TLightStandardFlickerRules }

function TLightStandardFlickerRules.NextAmount(const ARandom: IGameRandom): Integer;
begin
  Result := (ARandom.NextPlay and 3) * FLICKER_STEP;
end;

function TLightStandardFlickerRules.NextCount(const ARandom: IGameRandom): Integer;
begin
  Result := FLICKER_COUNT;
end;

function TLightStandardFlickerRules.InitialCount: Integer;
begin
  Result := FLICKER_COUNT;
end;

function TLightStandardFlickerRules.InitialMinLight(ASectorLightLevel,
  ALowestSurrounding: Integer): Integer;
begin
  Result := ALowestSurrounding + FLICKER_STEP;
end;

end.
