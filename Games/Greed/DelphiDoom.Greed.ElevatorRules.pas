{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the movement of the elevators                    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): CheckElevators of raven.pas }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ElevatorRules;

// the positions are 16.16 fixed point products that wrap as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Elevator.Intf;

type
  /// <summary>
  ///   CheckElevators: each elevator of the list moves up and down on its time, changes the floor height of its
  ///   tile, runs its end event and goes away when it has done (the kinds that do not repeat); the player that
  ///   stood on the floor follows it (and falls if the floor goes away faster than it can). The state is the world
  ///   (floorheight and mapsprites of the tiles), the list, the player and its fall rate
  /// </summary>
  TGreedElevatorRules = class
  strict private
    FWorld: IGreedWorld;
    FElevators: TGreedLinkedPool<TGreedElevator>;
    FHost: IGreedElevatorHost;
    procedure Finish(AItem: TGreedLinkedPool<TGreedElevator>.PItem);
    function Step(AItem: TGreedLinkedPool<TGreedElevator>.PItem; const APlayer: TGreedPlayerRecord): Boolean;
  public
    constructor Create(const AWorld: IGreedWorld; AElevators: TGreedLinkedPool<TGreedElevator>;
      const AHost: IGreedElevatorHost);
    /// <summary>One call of CheckElevators; AFallRate is the fall rate of the player (fallrate)</summary>
    procedure Check(var APlayer: TGreedPlayerRecord; var AFallRate: Integer);
  end;

implementation

uses
  DelphiDoom.Greed.Terrain;

const
  SPRITE_ELEVATOR = 127;

{ TGreedElevatorRules }

constructor TGreedElevatorRules.Create(const AWorld: IGreedWorld; AElevators: TGreedLinkedPool<TGreedElevator>;
  const AHost: IGreedElevatorHost);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(AElevators) then
    raise EArgumentNilException.Create('AElevators');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FWorld := AWorld;
  FElevators := AElevators;
  FHost := AHost;
end;

procedure TGreedElevatorRules.Finish(AItem: TGreedLinkedPool<TGreedElevator>.PItem);
begin
  if AItem^.EndEval <> 0 then
    FHost.RunEvent(AItem^.EndEval);
  FWorld.SetValue(gpFloorHeight, AItem^.MapSpot, Byte(AItem^.Position));
  if FWorld.GetValue(gpMapSprites, AItem^.MapSpot) = SPRITE_ELEVATOR then
    FWorld.SetValue(gpMapSprites, AItem^.MapSpot, 0);
end;

// One pass of the loop of an elevator; True when the elevator is over and has to leave the list
function TGreedElevatorRules.Step(AItem: TGreedLinkedPool<TGreedElevator>.PItem;
  const APlayer: TGreedPlayerRecord): Boolean;
var
  LDelta: Integer;
  LHandled: Boolean;

  procedure Sound;
  begin
    FHost.PlaySound(GREED_SN_ELEVATOR_START, 15, (AItem^.MapSpot and 63) * GREED_FRACTILEUNIT,
      (AItem^.MapSpot div 64) * GREED_FRACTILEUNIT);
  end;

begin
  Result := False;
  LHandled := False;
  LDelta := GREED_FRACUNIT * AItem^.Speed div GREED_MOVE_DELAY;
  // the conditions of the original change the position (CAddI, CSubI): only the ones that are evaluated
  if AItem^.Up then
  begin
    AItem^.Position64 := AItem^.Position64 + LDelta;
    if AItem^.Position64 >= AItem^.Ceiling * GREED_FRACUNIT then
    begin
      LHandled := True;
      Sound;
      AItem^.Position := AItem^.Ceiling;
      AItem^.Position64 := AItem^.Position * GREED_FRACUNIT;
      if AItem^.Kind = getNormal then
        AItem^.Down := True
      else if (AItem^.Kind <> getSwap) and (AItem^.Kind <> getSecret) then
      begin
        Finish(AItem);
        Exit(True);
      end;
      AItem^.Up := False;
      AItem^.Timer := AItem^.Timer + 4 * GREED_TIC_RATE;
    end;
  end;
  if not LHandled then
  begin
    if AItem^.Down then
    begin
      AItem^.Position64 := AItem^.Position64 - LDelta;
      if AItem^.Position64 <= AItem^.Floor * GREED_FRACUNIT then
      begin
        LHandled := True;
        Sound;
        AItem^.Position := AItem^.Floor;
        AItem^.Position64 := AItem^.Position * GREED_FRACUNIT;
        if (AItem^.Kind = getNormal) or (AItem^.Kind = getSecret) then
          AItem^.Up := True
        else if AItem^.Kind <> getSwap then
        begin
          Finish(AItem);
          Exit(True);
        end;
        AItem^.Down := False;
        AItem^.Timer := AItem^.Timer + 4 * GREED_TIC_RATE;
      end;
    end;
    if not LHandled then
      AItem^.Position := AItem^.Position64 div GREED_FRACUNIT;
  end;
  if (AItem^.Kind = getSecret) and AItem^.Up then
  begin
    if (APlayer.MapSpot = AItem^.MapSpot) or (FWorld.GetValue(gpMapSprites, AItem^.MapSpot) <> 0) then
    begin
      AItem^.Position := AItem^.Floor;
      AItem^.Position64 := AItem^.Position * GREED_FRACUNIT;
    end;
  end;
  if FWorld.GetValue(gpMapSprites, AItem^.MapSpot) = SPRITE_ELEVATOR then
    FWorld.SetValue(gpMapSprites, AItem^.MapSpot, 0);
  FWorld.SetValue(gpFloorHeight, AItem^.MapSpot, Byte(AItem^.Position));
  AItem^.Timer := AItem^.Timer + 1;
end;

procedure TGreedElevatorRules.Check(var APlayer: TGreedPlayerRecord; var AFallRate: Integer);
var
  LIndex: Integer;
  LPrevious: Integer;
  LItem: TGreedLinkedPool<TGreedElevator>.PItem;
  LTime: Integer;
  LFloorZ: TGreedFixed;
  LNewFloorZ: TGreedFixed;
  LWasOnGround: Boolean;
  LRemoved: Boolean;
begin
  LFloorZ := TGreedTerrain.FloorZ(FWorld, APlayer.X, APlayer.Y) + APlayer.Height;
  LWasOnGround := LFloorZ >= APlayer.Z;
  LTime := FHost.TimeCount;
  LIndex := FElevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LItem := FElevators.Item(LIndex);
    LRemoved := False;
    while LTime >= LItem^.Timer do
    begin
      if Step(LItem, APlayer) then
      begin
        LRemoved := True;
        Break;
      end;
    end;
    if LRemoved then
    begin
      LPrevious := FElevators.Previous(LIndex);
      FElevators.Remove(LIndex);
      if LPrevious = GREED_POOL_NIL then
        LIndex := FElevators.First
      else
        LIndex := FElevators.Next(LPrevious);
    end
    else
      LIndex := FElevators.Next(LIndex);
  end;
  if LWasOnGround then
  begin
    LNewFloorZ := TGreedTerrain.FloorZ(FWorld, APlayer.X, APlayer.Y) + APlayer.Height;
    if LNewFloorZ <> LFloorZ then
    begin
      if APlayer.Z > LNewFloorZ then
      begin
        if AFallRate >= 0 then
        begin
          APlayer.Z := LNewFloorZ;
          AFallRate := 0;
        end
        else
          AFallRate := AFallRate - GREED_FALL_UNIT;
      end
      else if APlayer.Z < LNewFloorZ then
      begin
        APlayer.Z := LNewFloorZ;
        AFallRate := 0;
      end;
    end;
  end;
end;

end.
