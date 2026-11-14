{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sprite that a unit shows                      }
{                                                                              }
{  Port of war1 (acoto87/war1), the sprite component calls that the states of  }
{  the gatherers make (we_addSpriteComponentFromResource,                      }
{  we_removeSpriteComponent, we_disableComponent), (c) 2019 Alejandro Coto     }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitSprites;

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   Which image a unit shows and whether it is drawn: the model keeps it in the unit (the component of the original
  ///   is only a number of the image and a flag). A worker that mines or delivers is not drawn, one that carries gold or
  ///   wood shows another image. Static functions on the component
  /// </summary>
  TWarUnitSprites = class
  public
    /// <summary>The image of the unit type (wu_getUnitData(type)->resourceIndex); 279, the footman, if the table has none, as the original does</summary>
    class function DefaultResource(AUnitType: Integer): Integer; static;
    /// <summary>wu_getWorkerData(type)->carryingGoldResource; EWarException for a type that is not a worker (the original asserts)</summary>
    class function CarryingGold(AUnitType: Integer): Integer; static;
    /// <summary>wu_getWorkerData(type)->carryingWoodResource</summary>
    class function CarryingWood(AUnitType: Integer): Integer; static;
    /// <summary>we_addSpriteComponentFromResource: the image, enabled, at its first frame</summary>
    class procedure Add(var AUnit: TWarUnitComponent; AResource: Integer); static;
    /// <summary>we_addSpriteComponentFromResource with the image of the unit type</summary>
    class procedure AddDefault(var AUnit: TWarUnitComponent); static;
    /// <summary>we_removeSpriteComponent</summary>
    class procedure Remove(var AUnit: TWarUnitComponent); static;
    /// <summary>we_disableComponent(COMP_SPRITE): nothing if the unit has no sprite</summary>
    class procedure Disable(var AUnit: TWarUnitComponent); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Map.UnitData, DelphiDoom.War.Model.GatherData;

resourcestring
  SWarModelNoWorkerData = 'The unit type %d is not a worker: it has no carrying images';

const
  // the image that the original falls back to when the table has none
  FOOTMAN_RESOURCE = 279;

{ TWarUnitSprites }

class function TWarUnitSprites.DefaultResource(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := Low(WAR_UNIT_DATA) to High(WAR_UNIT_DATA) do
    if WAR_UNIT_DATA[LIndex].UnitType = AUnitType then
    begin
      Result := WAR_UNIT_DATA[LIndex].ResourceIndex;
      Break;
    end;
  if Result = 0 then
    Result := FOOTMAN_RESOURCE;
end;

class function TWarUnitSprites.CarryingGold(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_WORKER_SPRITES) to High(WAR_WORKER_SPRITES) do
    if WAR_WORKER_SPRITES[LIndex].UnitType = AUnitType then
      Exit(WAR_WORKER_SPRITES[LIndex].CarryingGold);
  raise EWarException.CreateFmt(SWarModelNoWorkerData, [AUnitType]);
end;

class function TWarUnitSprites.CarryingWood(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_WORKER_SPRITES) to High(WAR_WORKER_SPRITES) do
    if WAR_WORKER_SPRITES[LIndex].UnitType = AUnitType then
      Exit(WAR_WORKER_SPRITES[LIndex].CarryingWood);
  raise EWarException.CreateFmt(SWarModelNoWorkerData, [AUnitType]);
end;

class procedure TWarUnitSprites.Add(var AUnit: TWarUnitComponent; AResource: Integer);
begin
  AUnit.SpriteResource := AResource;
  AUnit.SpriteEnabled := True;
  AUnit.SpriteFrame := 0;
end;

class procedure TWarUnitSprites.AddDefault(var AUnit: TWarUnitComponent);
begin
  Add(AUnit, DefaultResource(AUnit.UnitType));
end;

class procedure TWarUnitSprites.Remove(var AUnit: TWarUnitComponent);
begin
  AUnit.SpriteResource := 0;
  AUnit.SpriteEnabled := False;
  AUnit.SpriteFrame := 0;
end;

class procedure TWarUnitSprites.Disable(var AUnit: TWarUnitComponent);
begin
  if AUnit.SpriteResource <> 0 then
    AUnit.SpriteEnabled := False;
end;

end.
