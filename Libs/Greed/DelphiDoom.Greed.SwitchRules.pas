{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the switches on the walls and the use key        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): CheckForSwitch, SwitchWall  }
{  and CheckHere of raven.pas                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SwitchRules;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Level.Intf;

type
  /// <summary>
  ///   The switches of raven.pas, line by line. CheckForSwitch says if the wall that the player faces on its tile
  ///   has the picture of a switch (127, 172, 75, 140, 234 and, for a switch that goes back, the next number);
  ///   SwitchWall changes the picture to the other one of the pair and plays the sound; CheckHere is the use key
  ///   and the walk over a tile: it opens the door nearby (TryDoor of the host), runs the event of the switch of
  ///   the script (switches of event.pas, here TGreedGameState.Switches), swaps the E_SWAP elevators (SM_SWAPSWITCH)
  ///   and starts the secret elevators around a secret trigger (SM_STRIGGER). The globals are the fields of
  ///   TGreedGameState (TimeCount, SwitchTime, Switches, Elevators, World). The net game is not ported: the
  ///   NetCheckHere calls of the original are not here.
  ///   Switches is the array switches[x][y] of the original as it lies in memory: the index is x * 64 + y.
  ///   Kept defects: an SM_SWAPSWITCH switches the wall once for each elevator of the list that follows the first
  ///   E_SWAP that could move. Difference: a tile outside the map reads 0 and is not written (the original used
  ///   the memory near the arrays)
  /// </summary>
  TGreedSwitchRules = class
  strict private
    FState: TGreedGameState;
    FSound: IGreedGameSound;
    FEvents: IGreedEventRunner;
    FHost: IGreedSwitchHost;
    function WallSpot(AX, AY, AAngle: Integer; out APlane: TGreedPlane; out ASpot: Integer): Boolean;
    function ReadTile(APlane: TGreedPlane; ASpot: Integer): Integer;
    procedure WriteTile(APlane: TGreedPlane; ASpot, AValue: Integer);
    class function IsSwitchPicture(AValue: Integer; ADoubleSwitch: Boolean): Boolean; static;
    class function OtherPicture(AValue: Integer; ADoubleSwitch: Boolean): Integer; static;
  public
    /// <summary>
    ///   AState has the world, the elevators and the globals; ASound is SoundEffect, AEvents is RunEvent, AHost is
    ///   TryDoor. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const ASound: IGreedGameSound; const AEvents: IGreedEventRunner;
      const AHost: IGreedSwitchHost);
    /// <summary>
    ///   CheckForSwitch(x, y, angle, doubleswitch): True if the wall in front, on the tile (x, y), is a switch
    ///   that can be used now (False until SwitchTime)
    /// </summary>
    function CheckForSwitch(AX, AY, AAngle: Integer; ADoubleSwitch: Boolean): Boolean;
    /// <summary>SwitchWall(x, y, angle, doubleswitch): the sound, and the picture of the wall in front</summary>
    procedure SwitchWall(AX, AY, AAngle: Integer; ADoubleSwitch: Boolean);
    /// <summary>CheckHere(useit, cx, cy, angle): the place is in fixed point; AUseIt is the use key</summary>
    procedure CheckHere(AUseIt: Boolean; ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
  end;

implementation

const
  NORTH = 256;
  WEST = 512;
  SOUTH = 768;
  DEGREE45 = 128;
  TIC_RATE = 70;

{ TGreedSwitchRules }

constructor TGreedSwitchRules.Create(AState: TGreedGameState; const ASound: IGreedGameSound;
  const AEvents: IGreedEventRunner; const AHost: IGreedSwitchHost);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FState := AState;
  FSound := ASound;
  FEvents := AEvents;
  FHost := AHost;
end;

class function TGreedSwitchRules.IsSwitchPicture(AValue: Integer; ADoubleSwitch: Boolean): Boolean;
begin
  case AValue of
    127, 172, 75, 140, 234:
      Result := True;
    128, 173, 76, 141, 235:
      Result := ADoubleSwitch;
  else
    Result := False;
  end;
end;

class function TGreedSwitchRules.OtherPicture(AValue: Integer; ADoubleSwitch: Boolean): Integer;
begin
  Result := AValue;
  case AValue of
    127, 172, 75, 140, 234:
      Result := AValue + 1;
    128, 173, 76, 141, 235:
      if ADoubleSwitch then
        Result := AValue - 1;
  end;
end;

function TGreedSwitchRules.WallSpot(AX, AY, AAngle: Integer; out APlane: TGreedPlane; out ASpot: Integer): Boolean;
var
  LMapSpot: Integer;
begin
  LMapSpot := AY * GREED_MAP_SIZE + AX;
  Result := True;
  if (AAngle >= SOUTH + DEGREE45) or (AAngle < DEGREE45) then
  begin
    APlane := gpWestWall;
    ASpot := LMapSpot + 1;
  end
  else if (AAngle >= DEGREE45) and (AAngle < NORTH + DEGREE45) then
  begin
    APlane := gpNorthWall;
    ASpot := LMapSpot;
  end
  else if (AAngle >= NORTH + DEGREE45) and (AAngle < WEST + DEGREE45) then
  begin
    APlane := gpWestWall;
    ASpot := LMapSpot;
  end
  else if AAngle >= WEST + DEGREE45 then
  begin
    APlane := gpNorthWall;
    ASpot := LMapSpot + GREED_MAP_SIZE;
  end
  else
  begin
    APlane := gpNorthWall;
    ASpot := 0;
    Result := False;
  end;
end;

function TGreedSwitchRules.ReadTile(APlane: TGreedPlane; ASpot: Integer): Integer;
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    Result := 0
  else
    Result := FState.World.GetValue(APlane, ASpot);
end;

procedure TGreedSwitchRules.WriteTile(APlane: TGreedPlane; ASpot, AValue: Integer);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.World.SetValue(APlane, ASpot, Byte(AValue));
end;

function TGreedSwitchRules.CheckForSwitch(AX, AY, AAngle: Integer; ADoubleSwitch: Boolean): Boolean;
var
  LPlane: TGreedPlane;
  LSpot: Integer;
begin
  if FState.TimeCount < FState.SwitchTime then
    Exit(False);
  if not WallSpot(AX, AY, AAngle, LPlane, LSpot) then
    Exit(False);
  Result := IsSwitchPicture(ReadTile(LPlane, LSpot), ADoubleSwitch);
end;

procedure TGreedSwitchRules.SwitchWall(AX, AY, AAngle: Integer; ADoubleSwitch: Boolean);
var
  LPlane: TGreedPlane;
  LSpot, LValue, LOther: Integer;
begin
  FSound.SoundEffect(GREED_SN_WALLSWITCH, 0, AX * GREED_FRACTILEUNIT, AY * GREED_FRACTILEUNIT);
  if not WallSpot(AX, AY, AAngle, LPlane, LSpot) then
    Exit;
  LValue := ReadTile(LPlane, LSpot);
  LOther := OtherPicture(LValue, ADoubleSwitch);
  if LOther <> LValue then
    WriteTile(LPlane, LSpot, LOther);
end;

procedure TGreedSwitchRules.CheckHere(AUseIt: Boolean; ACenterX, ACenterY: TGreedFixed; AAngle: Integer);
var
  LMapSpot, LX, LY, LX1, LY1, LIndex, LSwitch: Integer;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
  LSwitchIt, LSkip: Boolean;
begin
  FHost.TryDoor(ACenterX, ACenterY);
  LX := ACenterX div GREED_FRACTILEUNIT;
  LY := ACenterY div GREED_FRACTILEUNIT;
  LMapSpot := LY * GREED_MAP_SIZE + LX;
  LSwitchIt := False;

  // switches[x][y]: the first index is x
  LSwitch := 0;
  if (LX >= 0) and (LX < GREED_MAP_SIZE) and (LY >= 0) and (LY < GREED_MAP_SIZE) then
    LSwitch := FState.Switches[LX * GREED_MAP_SIZE + LY];
  if LSwitch <> 0 then
  begin
    LSkip := False;
    if AUseIt then
      LSkip := not CheckForSwitch(LX, LY, AAngle, True);
    if not LSkip then
    begin
      SwitchWall(LX, LY, AAngle, True);
      // read again as the original does: the two calls before do not change it
      FEvents.RunEvent(FState.Switches[LX * GREED_MAP_SIZE + LY], False);
    end;
  end;

  case ReadTile(gpMapSprites, LMapSpot) of
    GREED_SM_SWAPSWITCH:
      begin
        if AUseIt and not CheckForSwitch(LX, LY, AAngle, True) then
          Exit;
        LIndex := FState.Elevators.First;
        while LIndex <> GREED_POOL_NIL do
        begin
          LElevator := FState.Elevators.Item(LIndex);
          if LElevator^.Kind = getSwap then
          begin
            if LElevator^.Position = LElevator^.Ceiling then
            begin
              LElevator^.Down := True;
              LElevator^.Timer := FState.TimeCount;
              LSwitchIt := True;
            end
            else if LElevator^.Position = LElevator^.Floor then
            begin
              LElevator^.Up := True;
              LElevator^.Timer := FState.TimeCount;
              LSwitchIt := True;
            end;
          end;
          if LSwitchIt then
          begin
            SwitchWall(LX, LY, AAngle, True);
            FState.SwitchTime := FState.TimeCount + 3 * TIC_RATE;
          end;
          LIndex := FState.Elevators.Next(LIndex);
        end;
      end;

    GREED_SM_STRIGGER:
      begin
        LIndex := FState.Elevators.First;
        while LIndex <> GREED_POOL_NIL do
        begin
          LElevator := FState.Elevators.Item(LIndex);
          if (LElevator^.Kind = getSecret) and not LElevator^.Down and not LElevator^.Up then
          begin
            LX1 := LElevator^.MapSpot mod GREED_MAP_SIZE;
            LY1 := LElevator^.MapSpot div GREED_MAP_SIZE;
            if (Abs(LX1 - LX) < 2) and (Abs(LY1 - LY) < 2) then
            begin
              LElevator^.Down := True;
              LElevator^.Timer := FState.TimeCount;
              CheckHere(False, LX1 * GREED_FRACTILEUNIT, LY1 * GREED_FRACTILEUNIT, AAngle);
            end;
          end;
          LIndex := FState.Elevators.Next(LIndex);
        end;
      end;
  end;
end;

end.
