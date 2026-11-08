{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the doors as the old code       }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldDoors;

// The statements of the procedures are the ones of Doom\p_doors.pas, Heretic\p_doors.pas,
// Strife\p_doors.pas and udmf_doors.pas before the library, with the thinker replaced by a
// TDoorState (the same fields: _type is Kind), the calls to the game (T_MovePlane, S_StartSound,
// the surrounding sectors) replaced by calls to a fake host that writes them down, and the
// removal of the thinker and the switching of the lights of the line written in the outcome.
// The tests run the old and the new code side by side on the same script of results.
// The fields that the old code did not set stay at 0, and a kind that the old code did not set
// (a line that no case of the game names) is the normal door.
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Door.Types, DelphiDoom.Tests.Thinkers.DoorFakes;

type
  /// <summary>What the old code did besides changing the door and calling the host</summary>
  TOldDoorOutcome = record
    Removed: Boolean;
    LightsOff: Boolean;
    LightsOn: Boolean;
  end;

procedure OldDoomTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);
procedure OldHereticTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);
procedure OldStrifeTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);
procedure OldUdmfTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);

procedure OldDoomDoDoor(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
  const host: TFakeDoorHost);
procedure OldHereticDoDoor(var door: TDoorState; AKind: TDoorKind; ASpeed, ACeilingHeight: Integer;
  const host: TFakeDoorHost);
procedure OldStrifeDoDoor(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
  const host: TFakeDoorHost);
procedure OldUdmfDoDoor(var door: TDoorState; AKind: TDoorKind; ASpeed, ATopWait,
  ACeilingHeight: Integer; const host: TFakeDoorHost);

function OldDoomManual(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean;
function OldHereticManual(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean;
function OldStrifeManual(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean;
function OldUdmfManual(var door: TDoorState; ASpecial, ASpeed, ATopWait: Integer;
  const host: TFakeDoorHost): Boolean;

/// <summary>A line is used on a sector with a working door: false when the old code made a new door</summary>
function OldDoomRetrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
  out AAction: TDoorRetrigger): Boolean;
function OldHereticRetrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
  out AAction: TDoorRetrigger): Boolean;
function OldStrifeRetrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
  out AAction: TDoorRetrigger): Boolean;

procedure OldCloseIn30(var door: TDoorState);
procedure OldRaiseIn5Mins(var door: TDoorState; const host: TFakeDoorHost);

implementation

const
  FRACUNIT = 65536;
  TICRATE = 35;
  VDOORSPEED = FRACUNIT * 2;
  VDOORWAIT = 150;

//==============================================================================
// Doom\p_doors.pas: T_VerticalDoor
//==============================================================================
procedure OldDoomTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);
var
  res: TDoorPlaneResult;
begin
  case door.direction of
    0:
      begin
        // WAITING
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.BlazeRaise,
            TDoorKind.GenBlazeRaise:
              begin
                door.direction := -1; // time to go back down
                host.OldSound('BlazeClose');
              end;
            TDoorKind.Normal,
            TDoorKind.GenRaise:
              begin
                door.direction := -1; // time to go back down
                host.OldSound('Close');
              end;
            TDoorKind.Close30ThenOpen,
            TDoorKind.GenCdO:
              begin
                door.direction := 1;
                host.OldSound('Open');
              end;
            TDoorKind.GenBlazeCdO:
              begin
                door.direction := 1;
                host.OldSound('BlazeOpen');
              end;
          end;
        end;
      end;
    2:
      begin
        //  INITIAL WAIT
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.RaiseIn5Mins:
              begin
                door.direction := 1;
                door.Kind := TDoorKind.Normal;
                host.OldSound('Open');
              end;
          end;
        end;
      end;

   -1:
      begin
        // DOWN
        res := host.OldMove(door.speed, AFloorHeight, false, 1, door.direction);
        if res = TDoorPlaneResult.PastDest then
        begin
          case door.Kind of
            TDoorKind.BlazeRaise,
            TDoorKind.BlazeClose,
            TDoorKind.GenBlazeRaise,
            TDoorKind.GenBlazeClose:
              begin
                outcome.Removed := true;
                if host.Compatibility then
                  host.OldSound('BlazeClose');
              end;
            TDoorKind.Normal,
            TDoorKind.Close,
            TDoorKind.GenRaise,
            TDoorKind.GenClose:
              begin
                outcome.Removed := true;
              end;
            TDoorKind.Close30ThenOpen:
              begin
                door.direction := 0;
                door.topcountdown := TICRATE * 30;
              end;
            TDoorKind.GenCdO,
            TDoorKind.GenBlazeCdO:
              begin
                door.direction := 0;
                door.topcountdown := door.topwait; // jff 5/8/98 insert delay
              end;
          end;

          // the line of the door is taken as one that switches the lights of its tag
          if not host.Compatibility then
            outcome.LightsOff := true;
        end
        else if res = TDoorPlaneResult.Crushed then
        begin
          case door.Kind of
            TDoorKind.BlazeClose,
            TDoorKind.Close,    // DO NOT GO BACK UP!
            TDoorKind.GenBlazeClose,
            TDoorKind.GenClose:
              begin
              end;
          else
            begin
              door.direction := 1;
              host.OldSound('Open');
            end;
          end;
        end;
      end;
    1:
      begin
        // UP
        res := host.OldMove(door.speed, door.topheight, false, 1, door.direction);
        if res = TDoorPlaneResult.PastDest then
        begin
          case door.Kind of
            TDoorKind.BlazeRaise,
            TDoorKind.Normal,
            TDoorKind.GenRaise,
            TDoorKind.GenBlazeRaise:
              begin
                door.direction := 0; // wait at top
                door.topcountdown := door.topwait;
              end;
            TDoorKind.Close30ThenOpen,
            TDoorKind.BlazeOpen,
            TDoorKind.Open,
            TDoorKind.GenBlazeOpen,
            TDoorKind.GenOpen,
            TDoorKind.GenCdO,
            TDoorKind.GenBlazeCdO:
              begin
                outcome.Removed := true;
              end;
          end;

          if not host.Compatibility then
            outcome.LightsOn := true;
        end;
      end;
  end;
end;

//==============================================================================
// Heretic\p_doors.pas: T_VerticalDoor
//==============================================================================
procedure OldHereticTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);
var
  res: TDoorPlaneResult;
begin
  case door.direction of
    0:
      begin
        // WAITING
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.Normal:
              begin
                door.direction := -1; // time to go back down
                host.OldSound('Open');
              end;
            TDoorKind.Close30ThenOpen:
              begin
                door.direction := 1;
                host.OldSound('Open');
              end;
          end;
        end;
      end;
    2:
      begin
        //  INITIAL WAIT
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.RaiseIn5Mins:
              begin
                door.direction := 1;
                door.Kind := TDoorKind.Normal;
                host.OldSound('Open');
              end;
          end;
        end;
      end;

   -1:
      begin
        // DOWN
        res := host.OldMove(door.speed, AFloorHeight, false, 1, door.direction);
        if res = TDoorPlaneResult.PastDest then
        begin
          case door.Kind of
            TDoorKind.Normal,
            TDoorKind.Close:
              begin
                outcome.Removed := true;
                host.OldSound('Close');
              end;
            TDoorKind.Close30ThenOpen:
              begin
                door.direction := 0;
                door.topcountdown := TICRATE * 30;
              end;
          end;
        end
        else if res = TDoorPlaneResult.Crushed then
        begin
          case door.Kind of
            TDoorKind.Close:    // DO NOT GO BACK UP!
              begin
              end;
          else
            begin
              door.direction := 1;
              host.OldSound('Open');
            end;
          end;
        end;
      end;
    1:
      begin
        // UP
        res := host.OldMove(door.speed, door.topheight, false, 1, door.direction);
        if res = TDoorPlaneResult.PastDest then
        begin
          case door.Kind of
            TDoorKind.Normal:
              begin
                door.direction := 0; // wait at top
                door.topcountdown := door.topwait;
              end;
            TDoorKind.Close30ThenOpen,
            TDoorKind.Open:
              begin
                outcome.Removed := true;
                host.OldStop;
              end;
          end;
        end;
      end;
  end;
end;

//==============================================================================
// Strife\p_doors.pas: T_VerticalDoor
//==============================================================================
procedure OldStrifeTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);
var
  res1, res2: TDoorPlaneResult;
begin
  case door.direction of
    0:
      begin
        // WAITING
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.BlazeRaise,
            TDoorKind.GenBlazeRaise:
              begin
                door.direction := -1; // time to go back down
                host.OldSound('BlazeClose');
              end;
            TDoorKind.Normal,
            TDoorKind.GenRaise:
              begin
                door.direction := -1; // time to go back down
                // villsa [STRIFE] closesound added
                host.OldSound('Close');
              end;

            // villsa [STRIFE]
            TDoorKind.ShopClose:
              begin
                door.direction := 1;
                door.speed := 2 * FRACUNIT;
                host.OldSound('Open');
              end;

            TDoorKind.Close30ThenOpen,
            TDoorKind.GenCdO:
              begin
                door.direction := 1;
                // villsa [STRIFE] opensound added
                host.OldSound('Open');
              end;
            TDoorKind.GenBlazeCdO:
              begin
                door.direction := 1;
                host.OldSound('BlazeOpen');
              end;
          end;
        end;
      end;
    2:
      begin
        //  INITIAL WAIT
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.RaiseIn5Mins:
              begin
                door.direction := 1;
                door.Kind := TDoorKind.Normal;
                host.OldSound('Open');
              end;
          end;
        end;
      end;

    // villsa [STRIFE]
   -2:
      begin
        // SPLIT
        res1 := host.OldMove(door.speed, door.topheight, false, 1, 1);
        res2 := host.OldMove(door.speed, door.topwait, false, 0, -1);

        if (res1 = TDoorPlaneResult.PastDest) and (res2 = TDoorPlaneResult.PastDest) then
        begin
          outcome.Removed := true;
        end;
      end;

   -1:
      begin
        // DOWN
        res1 := host.OldMove(door.speed, AFloorHeight, false, 1, door.direction);
        if res1 = TDoorPlaneResult.PastDest then
        begin
          case door.Kind of
            TDoorKind.BlazeRaise,
            TDoorKind.BlazeClose,
            TDoorKind.GenBlazeRaise,
            TDoorKind.GenBlazeClose,
            TDoorKind.Normal,
            TDoorKind.Close,
            TDoorKind.GenRaise,
            TDoorKind.GenClose:
              begin
                outcome.Removed := true;
              end;

            TDoorKind.Close30ThenOpen:
              begin
                door.direction := 0;
                door.topcountdown := TICRATE * 30;
              end;

            TDoorKind.GenCdO,
            TDoorKind.GenBlazeCdO:
              begin
                door.direction := 0;
                door.topcountdown := door.topwait; // jff 5/8/98 insert delay
              end;

            // villsa [STRIFE]
            TDoorKind.ShopClose:
              begin
                door.direction := 0;
                door.topcountdown := TICRATE * 120;
              end;
          end;

          if not host.Compatibility then
            outcome.LightsOff := true;
        end
        else if res1 = TDoorPlaneResult.Crushed then
        begin
          case door.Kind of
            TDoorKind.BlazeClose,
            TDoorKind.Close,      // DO NOT GO BACK UP!
            TDoorKind.ShopClose,  // villsa [STRIFE]
            TDoorKind.GenBlazeClose,
            TDoorKind.GenClose:
              begin
              end;
          else
            begin
              door.direction := 1;
              // villsa [STRIFE] opensound added
              host.OldSound('Open');
            end;
          end;
        end;
      end;
    1:
      begin
        // UP
        res1 := host.OldMove(door.speed, door.topheight, false, 1, door.direction);
        if res1 = TDoorPlaneResult.PastDest then
        begin
          case door.Kind of
            TDoorKind.BlazeRaise,
            TDoorKind.Normal,
            TDoorKind.GenRaise,
            TDoorKind.GenBlazeRaise:
              begin
                door.direction := 0; // wait at top
                door.topcountdown := door.topwait;
              end;
            TDoorKind.Close30ThenOpen,
            TDoorKind.BlazeOpen,
            TDoorKind.Open,
            TDoorKind.ShopClose,  // villsa [STRIFE]
            TDoorKind.GenBlazeOpen,
            TDoorKind.GenOpen,
            TDoorKind.GenCdO,
            TDoorKind.GenBlazeCdO:
              begin
                outcome.Removed := true;
              end;
          end;

          if not host.Compatibility then
            outcome.LightsOn := true;
        end;
      end;
  end;
end;

//==============================================================================
// udmf_doors.pas: TH_VerticalDoor (the start of a sequence and of a sound are both 'Open'/'Close')
//==============================================================================
procedure OldUdmfTick(var door: TDoorState; AFloorHeight: Integer; const host: TFakeDoorHost;
  var outcome: TOldDoorOutcome);
var
  res: TDoorPlaneResult;
begin
  case door.direction of
    0:
      begin
        // WAITING
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.UdmfNormal:
              begin
                door.direction := -1; // time to go back down
                host.OldSound('Close');
              end;
            TDoorKind.UdmfClose30ThenOpen,
            TDoorKind.UdmfCloseWaitThenOpen:
              begin
                door.direction := 1;
              end;
          end;
        end;
      end;
    2:
      begin
        //  INITIAL WAIT
        dec(door.topcountdown);
        if door.topcountdown = 0 then
        begin
          case door.Kind of
            TDoorKind.UdmfRaiseIn5Mins:
              begin
                door.direction := 1;
                door.Kind := TDoorKind.UdmfNormal;
              end;
          end;
        end;
      end;

   -1:
      begin
        // DOWN
        res := host.OldMove(door.speed, AFloorHeight, false, 1, door.direction);
        if res = TDoorPlaneResult.PastDest then
        begin
          host.OldStop;
          case door.Kind of
            TDoorKind.UdmfNormal,
            TDoorKind.UdmfClose:
              begin
                outcome.Removed := true;
              end;
            TDoorKind.UdmfClose30ThenOpen:
              begin
                door.direction := 0;
                door.topcountdown := TICRATE * 30;
              end;
            TDoorKind.UdmfCloseWaitThenOpen:
              begin
                door.direction := 0;
                door.topcountdown := door.topwait;
              end;
          end;
        end
        else if res = TDoorPlaneResult.Crushed then
        begin
          case door.Kind of
            TDoorKind.UdmfClose:    // DO NOT GO BACK UP!
              begin
              end;
          else
            begin
              door.direction := 1;
            end;
          end;
        end;
      end;
    1:
      begin
        // UP
        res := host.OldMove(door.speed, door.topheight, false, 1, door.direction);
        if res = TDoorPlaneResult.PastDest then
        begin
          host.OldStop;
          case door.Kind of
            TDoorKind.UdmfNormal:
              begin
                door.direction := 0; // wait at top
                door.topcountdown := door.topwait;
              end;
            TDoorKind.UdmfClose30ThenOpen,
            TDoorKind.UdmfCloseWaitThenOpen,
            TDoorKind.UdmfOpen:
              begin
                outcome.Removed := true;
              end;
          end;
        end;
      end;
  end;
end;

//==============================================================================
// Doom\p_doors.pas: EV_DoDoor (the part for one sector)
//==============================================================================
procedure OldDoomDoDoor(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
  const host: TFakeDoorHost);
begin
  door.Kind := AKind;
  door.topwait := VDOORWAIT;
  door.speed := VDOORSPEED;

  case AKind of
    TDoorKind.BlazeClose:
      begin
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
        door.speed := VDOORSPEED * 4;
        host.OldSound('BlazeClose');
      end;

    TDoorKind.Close:
      begin
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
        host.OldSound('Close');
      end;

    TDoorKind.Close30ThenOpen:
      begin
        door.topheight := ACeilingHeight;
        door.direction := -1;
        host.OldSound('Close');
      end;

    TDoorKind.BlazeRaise,
    TDoorKind.BlazeOpen:
      begin
        door.direction := 1;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.speed := VDOORSPEED * 4;
        if door.topheight <> ACeilingHeight then
          host.OldSound('BlazeOpen');
      end;

    TDoorKind.Normal,
    TDoorKind.Open:
      begin
        door.direction := 1;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        if door.topheight <> ACeilingHeight then
          host.OldSound('Open');
      end;
  end;
end;

//==============================================================================
// Heretic\p_doors.pas: EV_DoDoor
//==============================================================================
procedure OldHereticDoDoor(var door: TDoorState; AKind: TDoorKind; ASpeed, ACeilingHeight: Integer;
  const host: TFakeDoorHost);
begin
  door.Kind := AKind;
  door.topwait := VDOORWAIT;
  door.speed := ASpeed;

  case AKind of
    TDoorKind.Close:
      begin
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
        host.OldSound('Open');
      end;

    TDoorKind.Close30ThenOpen:
      begin
        door.topheight := ACeilingHeight;
        door.direction := -1;
        host.OldSound('Open');
      end;

    TDoorKind.Normal,
    TDoorKind.Open:
      begin
        door.direction := 1;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        if door.topheight <> ACeilingHeight then
          host.OldSound('Open');
      end;
  end;
end;

//==============================================================================
// Strife\p_doors.pas: EV_DoDoor (the part for one sector)
//==============================================================================
procedure OldStrifeDoDoor(var door: TDoorState; AKind: TDoorKind; ACeilingHeight: Integer;
  const host: TFakeDoorHost);
begin
  door.Kind := AKind;
  door.topwait := VDOORWAIT;
  door.speed := VDOORSPEED;

  case AKind of
    // villsa [STRIFE] new door type
    TDoorKind.SplitOpen:
      begin
        door.direction := -2;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.speed := FRACUNIT;
        // yes, it using topwait to get the floor height
        door.topwait := host.LowestFloorSurrounding(nil);
        if door.topheight <> ACeilingHeight then
          host.OldSound('Open');
      end;

    // villsa [STRIFE] new door type
    TDoorKind.SplitRaiseNearest:
      begin
        door.direction := -2;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.speed := FRACUNIT;
        // yes, it using topwait to get the floor height
        door.topwait := host.HighestFloorSurrounding(nil);
        if door.topheight <> ACeilingHeight then
          host.OldSound('Open');
      end;

    TDoorKind.BlazeClose,
    TDoorKind.ShopClose:     // villsa [STRIFE]
      begin
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
        door.speed := VDOORSPEED * 4;
        host.OldSound('BlazeClose');
      end;

    TDoorKind.Close:
      begin
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
        // villsa [STRIFE] set door sounds
        host.OldSound('Open');
      end;

    TDoorKind.Close30ThenOpen:
      begin
        door.topheight := ACeilingHeight;
        door.direction := -1;
        // villsa [STRIFE] set door sounds
        host.OldSound('Close');
      end;

    TDoorKind.BlazeRaise,
    TDoorKind.BlazeOpen:
      begin
        door.direction := 1;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.speed := VDOORSPEED * 4;
        if door.topheight <> ACeilingHeight then
          host.OldSound('BlazeOpen');
      end;

    TDoorKind.Normal,
    TDoorKind.Open:
      begin
        door.direction := 1;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        if door.topheight <> ACeilingHeight then
          host.OldSound('Open');
      end;
  end;
end;

//==============================================================================
// udmf_doors.pas: EVH_DoDoor (the part for one sector)
//==============================================================================
procedure OldUdmfDoDoor(var door: TDoorState; AKind: TDoorKind; ASpeed, ATopWait,
  ACeilingHeight: Integer; const host: TFakeDoorHost);
begin
  case AKind of
    TDoorKind.UdmfClose:
      begin
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
        door.direction := -1;
      end;

    TDoorKind.UdmfClose30ThenOpen,
    TDoorKind.UdmfCloseWaitThenOpen:
      begin
        door.topheight := ACeilingHeight;
        door.direction := -1;
      end;

    TDoorKind.UdmfNormal,
    TDoorKind.UdmfOpen:
      begin
        door.direction := 1;
        door.topheight := host.LowestCeilingSurrounding(nil);
        door.topheight := door.topheight - 4 * FRACUNIT;
      end;
  end;

  door.Kind := AKind;
  door.speed := ASpeed;
  door.topwait := ATopWait;
  if AKind = TDoorKind.UdmfCloseWaitThenOpen then
    door.topwait := (door.topwait * TICRATE) div 8; // OctTics
  host.OldSound('Open');
end;

//==============================================================================
// Doom\p_doors.pas: EV_VerticalDoor, from "for proper sound" to the end
//==============================================================================
function OldDoomManual(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean;
begin
  Result := False;

  // for proper sound
  case ASpecial of
   117, // BLAZING DOOR RAISE
   118: // BLAZING DOOR OPEN
      host.OldSound('BlazeOpen');
     1, // NORMAL DOOR SOUND
    31:
      host.OldSound('Open');
  else // LOCKED DOOR SOUND
    host.OldSound('Open');
  end;

  door.direction := 1;
  door.speed := VDOORSPEED;
  door.topwait := VDOORWAIT;

  // a special that no case names gave the old code a door of no kind: here it is the normal one
  door.Kind := TDoorKind.Normal;
  case ASpecial of
     1,
    26,
    27,
    28:
      door.Kind := TDoorKind.Normal;
    31,
    32,
    33,
    34:
      begin
        door.Kind := TDoorKind.Open;
        Result := True; // line.special := 0
      end;
   117: // blazing door raise
      begin
        door.Kind := TDoorKind.BlazeRaise;
        door.speed := VDOORSPEED * 4;
      end;
   118: // blazing door open
      begin
        door.Kind := TDoorKind.BlazeOpen;
        Result := True; // line.special := 0
        door.speed := VDOORSPEED * 4;
      end;
  end;

  // find the top and bottom of the movement range
  door.topheight := host.LowestCeilingSurrounding(nil) - 4 * FRACUNIT;
end;

//==============================================================================
// Heretic\p_doors.pas: EV_VerticalDoor, from the sound to the end
//==============================================================================
function OldHereticManual(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean;
begin
  Result := False;
  host.OldSound('Open');

  door.direction := 1;
  door.speed := VDOORSPEED;
  door.topwait := VDOORWAIT;

  door.Kind := TDoorKind.Normal;
  case ASpecial of
     1,
    26,
    27,
    28:
      door.Kind := TDoorKind.Normal;
    31,
    32,
    33,
    34:
      begin
        door.Kind := TDoorKind.Open;
        Result := True; // line.special := 0
      end;
  end;

  // find the top and bottom of the movement range
  door.topheight := host.LowestCeilingSurrounding(nil);
  door.topheight := door.topheight - 4 * FRACUNIT;
end;

//==============================================================================
// Strife\p_doors.pas: EV_VerticalDoor, from the new door thinker to the end
//==============================================================================
function OldStrifeManual(var door: TDoorState; ASpecial: Integer; const host: TFakeDoorHost): Boolean;
begin
  Result := False;
  door.direction := 1;
  door.speed := VDOORSPEED;
  door.topwait := VDOORWAIT;

  // for proper sound - [STRIFE] - verified complete
  case ASpecial of
    117,  // BLAZING DOOR RAISE
    118:  // BLAZING DOOR OPEN
        host.OldSound('BlazeOpen');
  else    // NORMAL DOOR SOUND
    host.OldSound('Open');
  end;

  // haleyjd: [STRIFE] - verified all.
  case ASpecial of
     1,
    26,
    27,
    28:
      door.Kind := TDoorKind.Normal;

    31,
    32,
    33,
    34,
   156,   // villsa [STRIFE]
   157,   // villsa [STRIFE]
   158:   // villsa [STRIFE]
      begin
        door.Kind := TDoorKind.Open;
        Result := True; // line.special := 0
      end;

   117: // blazing door raise
      begin
        door.Kind := TDoorKind.BlazeRaise;
        door.speed := VDOORSPEED * 4;
      end;

   118: // blazing door open
      begin
        door.Kind := TDoorKind.BlazeOpen;
        Result := True; // line.special := 0
        door.speed := VDOORSPEED * 4;
      end;
  else
    // haleyjd: [STRIFE] pretty important to have this here!
    door.Kind := TDoorKind.Normal;

  end;

  // find the top and bottom of the movement range
  door.topheight := host.LowestCeilingSurrounding(nil) - 4 * FRACUNIT;
end;

//==============================================================================
// udmf_doors.pas: EVH_VerticalDoor, from the new door thinker to the end
//==============================================================================
function OldUdmfManual(var door: TDoorState; ASpecial, ASpeed, ATopWait: Integer;
  const host: TFakeDoorHost): Boolean;
begin
  Result := False;
  door.direction := 1;
  case ASpecial of
    11:
      begin
        door.Kind := TDoorKind.UdmfOpen;
        Result := True; // line.special := 0
      end;
    12,
    13:
      begin
        door.Kind := TDoorKind.UdmfNormal;
      end;
  else
    door.Kind := TDoorKind.UdmfNormal;
  end;

  door.speed := ASpeed;
  door.topwait := ATopWait;

  //
  // find the top and bottom of the movement range
  //
  door.topheight := host.LowestCeilingSurrounding(nil);
  door.topheight := door.topheight - 4 * FRACUNIT;
  host.OldSound('Open');
end;

//==============================================================================
// the lines used again on a sector with a working door
//==============================================================================
function OldDoomRetrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
  out AAction: TDoorRetrigger): Boolean;
begin
  Result := False;
  AAction := TDoorRetrigger.Ignore;
  case ASpecial of
     1, // ONLY FOR "RAISE" DOORS, NOT "OPEN"s
    26,
    27,
    28,
   117:
      begin
        Result := True;
        if ADirection = -1 then
          AAction := TDoorRetrigger.GoUp // go back up
        else
        begin
          if not AThingIsPlayer then
            Exit; // JDC: bad guys never close doors

          AAction := TDoorRetrigger.GoDown;
        end;
      end;
  end;
end;

function OldHereticRetrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
  out AAction: TDoorRetrigger): Boolean;
begin
  Result := False;
  AAction := TDoorRetrigger.Ignore;
  case ASpecial of
     1, // ONLY FOR "RAISE" DOORS, NOT "OPEN"s
    26,
    27,
    28:
      begin
        Result := True;
        if ADirection = -1 then
          AAction := TDoorRetrigger.GoUp // go back up
        else
        begin
          if not AThingIsPlayer then
            Exit; // JDC: bad guys never close doors

          AAction := TDoorRetrigger.GoDown; // start going down immediately
        end;
      end;
  end;
end;

function OldStrifeRetrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
  out AAction: TDoorRetrigger): Boolean;
begin
  Result := False;
  AAction := TDoorRetrigger.Ignore;
  case ASpecial of
     1, // ONLY FOR "RAISE" DOORS, NOT "OPEN"s
    26,
    27,
    28,
   117,
   159,       // villsa
   160,       // haleyjd
   161,       // villsa
   166,       // villsa
   169,       // villsa
   170,       // villsa
   190,       // villsa
   213,       // villsa
   221,       // kaiser // JVAL: added from svstrife 1.4
   232:       // villsa
      begin
        Result := True;
        if ADirection = -1 then
          AAction := TDoorRetrigger.GoUp // go back up
        else
        begin
          if not AThingIsPlayer then
            Exit; // JDC: bad guys never close doors

          AAction := TDoorRetrigger.GoDown; // start going down immediately
        end;
      end;
  end;
end;

//==============================================================================
// the doors that a sector makes by itself
//==============================================================================
procedure OldCloseIn30(var door: TDoorState);
begin
  door.direction := 0;
  door.Kind := TDoorKind.Normal;
  door.speed := VDOORSPEED;
  door.topcountdown := 30 * TICRATE;
end;

procedure OldRaiseIn5Mins(var door: TDoorState; const host: TFakeDoorHost);
begin
  door.direction := 2;
  door.Kind := TDoorKind.RaiseIn5Mins;
  door.speed := VDOORSPEED;
  door.topheight := host.LowestCeilingSurrounding(nil) - 4 * FRACUNIT;
  door.topwait := VDOORWAIT;
  door.topcountdown := 5 * 60 * TICRATE;
end;

end.
