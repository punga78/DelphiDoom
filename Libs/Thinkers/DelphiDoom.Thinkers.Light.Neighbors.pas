{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the light of the sectors around a sector     }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Light.Neighbors;

interface

uses
  DelphiDoom.Thinkers.Light.Intf;

type
  /// <summary>The searches of the light level among the sectors around one (they have no state)</summary>
  TLightNeighbors = class
  public
    /// <summary>
    ///   The lowest light level of the neighbors, or AMax if none is lower (P_FindMinSurroundingLight);
    ///   with the level of the sector as AMax the sector counts too
    /// </summary>
    class function Lowest(const ASector: ILightSector; AMax: Integer): Integer; static;
    /// <summary>
    ///   The lowest light level of the neighbors, or the one of the sector if it has none
    ///   (P_FindLowestLightSurrounding of the scripted specials)
    /// </summary>
    class function LowestOrOwn(const ASector: ILightSector): Integer; static;
    /// <summary>
    ///   The "highest" light level of the neighbors (P_FindHighestLightSurrounding of the scripted
    ///   specials). The old function compared with "less than" instead of "greater than", so it
    ///   never found a higher level and gave the level of the sector; this one does the same
    /// </summary>
    class function HighestOrOwn(const ASector: ILightSector): Integer; static;
    /// <summary>The highest light level of the neighbors, or ABright if none is higher</summary>
    class function HighestAbove(const ASector: ILightSector; ABright: Integer): Integer; static;
  end;

implementation

const
  NO_LOWEST = $FFFF;
  NO_HIGHEST = -1;

{ TLightNeighbors }

class function TLightNeighbors.Lowest(const ASector: ILightSector; AMax: Integer): Integer;
var
  LIndex: Integer;
  LOther: ILightSector;
begin
  Result := AMax;
  for LIndex := 0 to ASector.NeighborCount - 1 do
  begin
    LOther := ASector.Neighbors[LIndex];
    if Assigned(LOther) and (LOther.LightLevel < Result) then
      Result := LOther.LightLevel;
  end;
end;

class function TLightNeighbors.LowestOrOwn(const ASector: ILightSector): Integer;
begin
  Result := Lowest(ASector, NO_LOWEST);
  if Result = NO_LOWEST then
    Result := ASector.LightLevel;
end;

class function TLightNeighbors.HighestOrOwn(const ASector: ILightSector): Integer;
var
  LIndex: Integer;
  LOther: ILightSector;
begin
  Result := NO_HIGHEST;
  for LIndex := 0 to ASector.NeighborCount - 1 do
  begin
    LOther := ASector.Neighbors[LIndex];
    // the comparison is the one of the old code, see the remarks of the declaration
    if Assigned(LOther) and (LOther.LightLevel < Result) then
      Result := LOther.LightLevel;
  end;

  if Result = NO_HIGHEST then
    Result := ASector.LightLevel;
end;

class function TLightNeighbors.HighestAbove(const ASector: ILightSector; ABright: Integer): Integer;
var
  LIndex: Integer;
  LOther: ILightSector;
begin
  Result := ABright;
  for LIndex := 0 to ASector.NeighborCount - 1 do
  begin
    LOther := ASector.Neighbors[LIndex];
    if Assigned(LOther) and (LOther.LightLevel > Result) then
      Result := LOther.LightLevel;
  end;
end;

end.
