{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the things of a level                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.Things;

interface

uses
  DelphiDoom.Zone.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   The things of the lump THINGS: the things that make easy slopes first, then every thing
  ///   spawned as the game wants it (with the extra values of a text map). It was P_LoadThings
  /// </summary>
  TEngineLevelThings = class(TInterfacedObject, ILevelThings)
  strict private
    FRules: ILevelThingRules;
    FLumps: IEngineLumps;
    FZone: IZoneAllocator;
  public
    /// <summary>ALumps gives the lump THINGS and AZone takes back the copy of it that was cached</summary>
    constructor Create(const ARules: ILevelThingRules; const ALumps: IEngineLumps;
      const AZone: IZoneAllocator);
    procedure Load(ALump: Integer);
  end;

implementation

uses
  System.SysUtils,
  doomdata,
  p_udmf,
  p_easyslope,
  DelphiDoom.Zone.Types;

{ TEngineLevelThings }

constructor TEngineLevelThings.Create(const ARules: ILevelThingRules; const ALumps: IEngineLumps;
  const AZone: IZoneAllocator);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EArgumentNilException.Create('ARules');
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  if not Assigned(AZone) then
    raise EArgumentNilException.Create('AZone');
  FRules := ARules;
  FLumps := ALumps;
  FZone := AZone;
end;

procedure TEngineLevelThings.Load(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LThing: Pmapthing_t;
  LCount: Integer;
begin
  LData := FLumps.Cache(ALump, ZONE_TAG_STATIC);
  LCount := FLumps.LengthOf(ALump) div SizeOf(mapthing_t);

  P_EasySlopeInit;

  LThing := Pmapthing_t(LData);
  for LIndex := 0 to LCount - 1 do
  begin
    if P_IsEasySlopeItem(LThing._type) then // Do spawn easy slope items
      P_SpawnEasySlopeThing(LThing);
    Inc(LThing);
  end;

  P_EasySlopeExecute;

  LThing := Pmapthing_t(LData);
  for LIndex := 0 to LCount - 1 do
  begin
    if hasudmfdata then
      FRules.SpawnMapThing(LThing, @udmfthings[LIndex])
    else
      FRules.SpawnMapThing(LThing, nil);
    Inc(LThing);
  end;

  FRules.AfterMapThingsSpawned;
  FZone.FreeBlock(LData);
  FRules.AfterThingsLoaded;
end;

end.
