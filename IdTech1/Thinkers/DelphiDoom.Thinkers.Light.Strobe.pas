{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the strobe light                             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Strobe;

// The light level is 16 bit and the old code let the values wrap when they were stored
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>The light that goes bright and dark with a fixed rhythm (T_StrobeFlash and P_SpawnStrobeFlash)</summary>
  TLightStrobe = class
  public
    /// <summary>
    ///   The values of a new strobe. The dark phase lasts ADarkTics; the bright one 5 tics. A
    ///   strobe that is not in sync starts after a random wait of 1 to 8 tics (one random
    ///   number), one in sync after 1 tic. The game then clears the special of the sector
    /// </summary>
    class procedure Initialize(const ASector: ILightSector; ADarkTics: Integer; AInSync: Boolean;
      const ARandom: IGameRandom; out AMaxLight, AMinLight, ADarkTime, ABrightTime,
      ACount: Integer); static;
    /// <summary>One tic: when the count is over the light changes to the other level</summary>
    class procedure Tick(var ACount: Integer; var ALightLevel: SmallInt; AMinLight, AMaxLight,
      ADarkTime, ABrightTime: Integer); static;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Neighbors;

{ TLightStrobe }

class procedure TLightStrobe.Initialize(const ASector: ILightSector; ADarkTics: Integer;
  AInSync: Boolean; const ARandom: IGameRandom; out AMaxLight, AMinLight, ADarkTime, ABrightTime,
  ACount: Integer);
begin
  ADarkTime := ADarkTics;
  ABrightTime := LIGHT_STROBE_BRIGHT_TICS;
  AMaxLight := ASector.LightLevel;
  AMinLight := TLightNeighbors.Lowest(ASector, ASector.LightLevel);

  if AMinLight = AMaxLight then
    AMinLight := 0;

  if AInSync then
    ACount := 1
  else
    ACount := (ARandom.NextPlay and 7) + 1;
end;

class procedure TLightStrobe.Tick(var ACount: Integer; var ALightLevel: SmallInt; AMinLight,
  AMaxLight, ADarkTime, ABrightTime: Integer);
begin
  ACount := ACount - 1;
  if ACount > 0 then
    Exit;

  if ALightLevel = AMinLight then
  begin
    ALightLevel := SmallInt(AMaxLight);
    ACount := ABrightTime;
  end
  else
  begin
    ALightLevel := SmallInt(AMinLight);
    ACount := ADarkTime;
  end;
end;

end.
