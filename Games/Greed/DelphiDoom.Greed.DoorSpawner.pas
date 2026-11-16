{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the doors of a map                               }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the door cases of           }
{  SpawnSprite of spawn.pas                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.DoorSpawner;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Door.Intf;

const
  /// <summary>S_VDOOR1: the sprites 60..73 of the map are the doors (vertical and horizontal of 7 kinds, in turn)</summary>
  GREED_S_FIRST_DOOR = 60;
  GREED_S_LAST_DOOR = 73;

type
  /// <summary>
  ///   Makes the doors that the map has (the sprite values 60..73 of the plane mapsprites, a vertical and a
  ///   horizontal door of each of the 7 kinds): a door of the world on the tile, closed, that can be bumped; the
  ///   second door of a pair side by side is turned the other way (vertical2 and horizontal2, they open to the
  ///   other side). The value of the map is cleared, as the original does when it makes the door
  /// </summary>
  TGreedDoorSpawner = class
  public
    /// <summary>Returns the doors made; EGreedException if the map has more than the world holds (32)</summary>
    class function SpawnAll(const AWorld: IGreedWorld; const APictures: IGreedDoorPictures; ATime: Integer): Integer;
      static;
  end;

implementation

{ TGreedDoorSpawner }

class function TGreedDoorSpawner.SpawnAll(const AWorld: IGreedWorld; const APictures: IGreedDoorPictures;
  ATime: Integer): Integer;
var
  LSpot, LValue, LIndex: Integer;
  LDoor: TGreedDoor;
  LVertical: Boolean;
begin
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(APictures) then
    raise EArgumentNilException.Create('APictures');
  Result := 0;
  for LSpot := 0 to GREED_MAP_TILES - 1 do
  begin
    LValue := AWorld.GetValue(gpMapSprites, LSpot);
    if (LValue < GREED_S_FIRST_DOOR) or (LValue > GREED_S_LAST_DOOR) then
      Continue;
    LVertical := (LValue - GREED_S_FIRST_DOOR) and 1 = 0;
    LIndex := AWorld.AddDoor(LSpot mod GREED_MAP_SIZE, LSpot div GREED_MAP_SIZE);
    LDoor := AWorld.GetDoor(LIndex);
    if LVertical then
    begin
      if (LSpot >= GREED_MAP_SIZE) and (AWorld.GetMapFlags(LSpot - GREED_MAP_SIZE) and GREED_FL_DOOR <> 0) then
        LDoor.Orientation := gdoVertical2
      else
        LDoor.Orientation := gdoVertical;
    end
    else
    begin
      if (LSpot >= 1) and (AWorld.GetMapFlags(LSpot - 1) and GREED_FL_DOOR <> 0) then
        LDoor.Orientation := gdoHorizontal2
      else
        LDoor.Orientation := gdoHorizontal;
    end;
    LDoor.Bumpable := True;
    LDoor.Size := 64 * GREED_FRACUNIT;
    LDoor.Position := LDoor.Size;
    LDoor.Timer := ATime;
    LDoor.Pic := APictures.PictureOf((LValue - GREED_S_FIRST_DOOR) div 2 + 1);
    AWorld.SetDoor(LIndex, LDoor);
    AWorld.SetValue(gpMapSprites, LSpot, 0);
    Inc(Result);
  end;
end;

end.
