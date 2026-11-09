{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the specials of the sectors, together             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Functions;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Ceilings,
  DelphiDoom.ScriptHost.SectorSpecials.Doors,
  DelphiDoom.ScriptHost.SectorSpecials.Floors,
  DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Lights,
  DelphiDoom.ScriptHost.SectorSpecials.Pillars,
  DelphiDoom.ScriptHost.SectorSpecials.Plats,
  DelphiDoom.ScriptHost.SectorSpecials.Polyobjects;

type
  /// <summary>The seven classes of the specials of the sectors, built on one gateway</summary>
  TScriptSectorSpecialFunctions = class(TInterfacedObject, IScriptSectorSpecialFunctions)
  strict private
    FDoors: TScriptDoorSpecials;
    FCeilings: TScriptCeilingSpecials;
    FFloors: TScriptFloorSpecials;
    FLights: TScriptLightSpecials;
    FPlats: TScriptPlatSpecials;
    FPillars: TScriptPillarSpecials;
    FPolyobjects: TScriptPolyobjectSpecials;
  public
    /// <param name="ASpecials">The gateway to the specials of the map (shared by the classes)</param>
    constructor Create(const ASpecials: IScriptSectorSpecials);
    destructor Destroy; override;
    function Doors: TScriptDoorSpecials;
    function Ceilings: TScriptCeilingSpecials;
    function Floors: TScriptFloorSpecials;
    function Lights: TScriptLightSpecials;
    function Plats: TScriptPlatSpecials;
    function Pillars: TScriptPillarSpecials;
    function Polyobjects: TScriptPolyobjectSpecials;
  end;

implementation

{ TScriptSectorSpecialFunctions }

constructor TScriptSectorSpecialFunctions.Create(const ASpecials: IScriptSectorSpecials);
begin
  inherited Create;
  // each constructor checks the gateway: if one of them raises, the others are freed by Destroy
  FDoors := TScriptDoorSpecials.Create(ASpecials);
  FCeilings := TScriptCeilingSpecials.Create(ASpecials);
  FFloors := TScriptFloorSpecials.Create(ASpecials);
  FLights := TScriptLightSpecials.Create(ASpecials);
  FPlats := TScriptPlatSpecials.Create(ASpecials);
  FPillars := TScriptPillarSpecials.Create(ASpecials);
  FPolyobjects := TScriptPolyobjectSpecials.Create(ASpecials);
end;

destructor TScriptSectorSpecialFunctions.Destroy;
begin
  FPolyobjects.Free;
  FPillars.Free;
  FPlats.Free;
  FLights.Free;
  FFloors.Free;
  FCeilings.Free;
  FDoors.Free;
  inherited;
end;

function TScriptSectorSpecialFunctions.Doors: TScriptDoorSpecials;
begin
  Result := FDoors;
end;

function TScriptSectorSpecialFunctions.Ceilings: TScriptCeilingSpecials;
begin
  Result := FCeilings;
end;

function TScriptSectorSpecialFunctions.Floors: TScriptFloorSpecials;
begin
  Result := FFloors;
end;

function TScriptSectorSpecialFunctions.Lights: TScriptLightSpecials;
begin
  Result := FLights;
end;

function TScriptSectorSpecialFunctions.Plats: TScriptPlatSpecials;
begin
  Result := FPlats;
end;

function TScriptSectorSpecialFunctions.Pillars: TScriptPillarSpecials;
begin
  Result := FPillars;
end;

function TScriptSectorSpecialFunctions.Polyobjects: TScriptPolyobjectSpecials;
begin
  Result := FPolyobjects;
end;

end.
