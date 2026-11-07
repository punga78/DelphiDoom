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
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   The things of the lump THINGS: the things that make easy slopes first, then every thing
  ///   spawned as the game wants it (with the extra values of a text map). It was P_LoadThings
  /// </summary>
  TEngineLevelThings = class(TInterfacedObject, ILevelThings)
  strict private
    FRules: ILevelThingRules;
  public
    constructor Create(const ARules: ILevelThingRules);
    procedure Load(ALump: Integer);
  end;

implementation

uses
  System.SysUtils,
  doomdata,
  w_wad,
  z_zone,
  p_udmf,
  p_easyslope;

{ TEngineLevelThings }

constructor TEngineLevelThings.Create(const ARules: ILevelThingRules);
begin
  inherited Create;
  if not Assigned(ARules) then
    raise EArgumentNilException.Create('ARules');
  FRules := ARules;
end;

procedure TEngineLevelThings.Load(ALump: Integer);
var
  LData: Pointer;
  LIndex: Integer;
  LThing: Pmapthing_t;
  LCount: Integer;
begin
  LData := W_CacheLumpNum(ALump, PU_STATIC);
  LCount := W_LumpLength(ALump) div SizeOf(mapthing_t);

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
  Z_Free(LData);
  FRules.AfterThingsLoaded;
end;

end.
