{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the doors that open and close                    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): CheckDoors of raven.pas     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.DoorRules;

// the sizes are 16.16 fixed point numbers that wrap as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Door.Intf;

const
  /// <summary>MOVEDELAY: the tics of a step of a door (a door moves 4 units in this many tics)</summary>
  GREED_MOVE_DELAY = 7;
  /// <summary>MINDOORSIZE: how much of the door is left when it is open</summary>
  GREED_MIN_DOOR_SIZE = 8;
  /// <summary>The tics that an open door waits before it closes (3 seconds)</summary>
  GREED_DOOR_OPEN_TICS = 270;

type
  /// <summary>
  ///   CheckDoors: each door of the world catches up with the time of the game one tic at a time. An opening door
  ///   gets smaller to 8 units and stays open for 3 seconds; then it closes again unless the player or something
  ///   stands in its tile, which blocks it (it stays open). The door that is bumped starts opening in the movement
  ///   of the player (TryDoor), not here
  /// </summary>
  TGreedDoorRules = class
  strict private
    FWorld: IGreedWorld;
    FHost: IGreedDoorHost;
  public
    constructor Create(const AWorld: IGreedWorld; const AHost: IGreedDoorHost);
    /// <summary>One call of CheckDoors; ACenterX and ACenterY are where the player is</summary>
    procedure Check(ACenterX, ACenterY: TGreedFixed);
  end;

implementation

const
  STEP = 4 * GREED_FRACUNIT div GREED_MOVE_DELAY;

{ TGreedDoorRules }

constructor TGreedDoorRules.Create(const AWorld: IGreedWorld; const AHost: IGreedDoorHost);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FWorld := AWorld;
  FHost := AHost;
end;

procedure TGreedDoorRules.Check(ACenterX, ACenterY: TGreedFixed);
var
  LX, LY, LIndex, LSpot, LTime: Integer;
  LDoor: TGreedDoor;
begin
  LX := ACenterX div GREED_FRACTILEUNIT;
  LY := ACenterY div GREED_FRACTILEUNIT;
  LTime := FHost.GetTimeCount;
  for LIndex := 0 to FWorld.DoorCount - 1 do
  begin
    LDoor := FWorld.GetDoor(LIndex);
    while LTime >= LDoor.Timer do
    begin
      LSpot := LDoor.TileY * GREED_MAP_SIZE + LDoor.TileX;
      if ((LDoor.TileX = LX) and (LDoor.TileY = LY)) or (FWorld.GetValue(gpMapSprites, LSpot) <> 0) then
      begin
        if LDoor.Open and not LDoor.Closing then
          LDoor.Blocked := True;
      end
      else
        LDoor.Blocked := False;

      if LDoor.Opening then
      begin
        LDoor.Size := LDoor.Size - STEP;
        if LDoor.Size <= GREED_MIN_DOOR_SIZE * GREED_FRACUNIT then
        begin
          LDoor.Size := GREED_MIN_DOOR_SIZE * GREED_FRACUNIT;
          LDoor.Opening := False;
          LDoor.Open := True;
          LDoor.Timer := LDoor.Timer + GREED_DOOR_OPEN_TICS;
        end
        else
          LDoor.Timer := LDoor.Timer + 1;
      end
      else if LDoor.Closing then
      begin
        LDoor.Size := LDoor.Size + STEP;
        if LDoor.Size >= 64 * GREED_FRACUNIT then
        begin
          LDoor.Size := 64 * GREED_FRACUNIT;
          LDoor.Closing := False;
          LDoor.Timer := LDoor.Timer + 1;
        end
        else
          LDoor.Timer := LDoor.Timer + 1;
      end
      else if LDoor.Open and (LTime > LDoor.Timer) and not LDoor.Blocked then
      begin
        LDoor.Closing := True;
        LDoor.Open := False;
        FHost.PlayDoorSound(LDoor.TileX * GREED_FRACTILEUNIT, LDoor.TileY * GREED_FRACTILEUNIT);
        LDoor.Timer := LDoor.Timer + 1;
      end
      else
        LDoor.Timer := LDoor.Timer + 1;

      LDoor.Position := LDoor.Size;
    end;
    FWorld.SetDoor(LIndex, LDoor);
  end;
end;

end.
