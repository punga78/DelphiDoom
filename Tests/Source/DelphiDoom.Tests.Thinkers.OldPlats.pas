{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the platforms as the old code   }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldPlats;

// The statements of the procedures are the ones of p_plats.pas (Doom, Heretic, Strife) and
// udmf_plats.pas before the library, with the engine replaced by the fake world (the sector
// moves, the sounds and the removal are written down) and P_Random by an IGameRandom: the tests
// run the old and the new code side by side on the same series of random numbers. The kinds and
// the status use the names of the library, which is all that is not the old code
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Platform.Types, DelphiDoom.Tests.Thinkers.PlatFakes;

type
  TOldPlat = record
    Sector: TFakePlatSector;
    Speed: Integer;
    Low: Integer;
    High: Integer;
    Wait: Integer;
    Count: Integer;
    Status: TPlatStatus;
    OldStatus: TPlatStatus;
    Crush: Boolean;
    Tag: Integer;
    Kind: TPlatKind;
    UdmfKind: TUdmfPlatKind;
  end;

/// <summary>T_PlatRaise of Doom</summary>
procedure OldDoomPlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
/// <summary>T_PlatRaise of Heretic</summary>
procedure OldHereticPlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
/// <summary>T_PlatRaise of Strife</summary>
procedure OldStrifePlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
/// <summary>The type switch of EV_DoPlat of Doom (after the thinker was made)</summary>
procedure OldDoomSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; APicture, amount: Integer);
/// <summary>The type switch of EV_DoPlat of Heretic</summary>
procedure OldHereticSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; APicture, amount: Integer);
/// <summary>The type switch of EV_DoPlat of Strife</summary>
procedure OldStrifeSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; APicture, amount: Integer);
/// <summary>P_ActivateInStasis of Doom for one platform</summary>
procedure OldDoomWakeUp(var plt: TOldPlat);
/// <summary>P_ActivateInStasis of Heretic and Strife for one platform</summary>
procedure OldPlainWakeUp(var plt: TOldPlat);
/// <summary>TH_PlatRaise</summary>
procedure OldUdmfPlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
/// <summary>The type switch of EVH_DoPlat (after the thinker was made); args are the four arguments of the special</summary>
procedure OldUdmfSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; const args: array of Integer);

implementation

uses
  System.SysUtils;

const
  FRACUNIT = 65536;
  PLATSPEED = FRACUNIT;
  PLATWAIT = 3;
  TICRATE = 35;

procedure Sound(AWorld: TFakePlatWorld; AKind: TPlatSound; sec: TFakePlatSector);
begin
  AWorld.PlaySound(sec, AKind);
end;

//==============================================================================
// Doom
//==============================================================================
procedure OldDoomPlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
var
  res: TPlatMoveResult;
begin
  case plat.Status of
    TPlatStatus.Up:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.High, plat.Crush, 1);

        if (plat.Kind = TPlatKind.RaiseAndChange) or (plat.Kind = TPlatKind.RaiseToNearestAndChange) then
        begin
          if AWorld.LevelTime and 7 = 0 then
            Sound(AWorld, TPlatSound.Move, plat.Sector);
        end;

        if (res = TPlatMoveResult.Crushed) and not plat.Crush then
        begin
          plat.Count := plat.Wait;
          plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end
        else
        begin
          if res = TPlatMoveResult.PastDestination then
          begin
            if plat.Kind = TPlatKind.ToggleUpDown then
            begin
              plat.OldStatus := plat.Status;
              plat.Status := TPlatStatus.InStasis;
            end
            else
            begin
              plat.Count := plat.Wait;
              plat.Status := TPlatStatus.Waiting;
              Sound(AWorld, TPlatSound.Stop, plat.Sector);
            end;

            case plat.Kind of
              TPlatKind.BlazeDownWaitUpStay,
              TPlatKind.DownWaitUpStay,
              TPlatKind.RaiseAndChange,
              TPlatKind.RaiseToNearestAndChange,
              TPlatKind.GenericLift:
                AWorld.RemovePlat(nil);
            end;
          end;
        end;
      end;

    TPlatStatus.Down:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.Low, False, -1);

        if res = TPlatMoveResult.PastDestination then
        begin
          if plat.Kind = TPlatKind.ToggleUpDown then
          begin
            plat.OldStatus := plat.Status;
            plat.Status := TPlatStatus.InStasis;
          end
          else
          begin
            plat.Count := plat.Wait;
            plat.Status := TPlatStatus.Waiting;
            Sound(AWorld, TPlatSound.Stop, plat.Sector);
          end;

          if AWorld.ModernEngine then
            if plat.Kind in [TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange] then
              AWorld.RemovePlat(nil);
        end;
      end;

    TPlatStatus.Waiting:
      begin
        plat.Count := plat.Count - 1;
        if plat.Count = 0 then
        begin
          if plat.Sector.FloorHeight = plat.Low then
            plat.Status := TPlatStatus.Up
          else
            plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end;
      end;
  end;
end;

procedure OldDoomSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; APicture, amount: Integer);
begin
  plat.Crush := False;
  plat.Low := sec.FloorHeight;

  case plat.Kind of
    TPlatKind.RaiseToNearestAndChange:
      begin
        plat.Speed := PLATSPEED div 2;
        sec.FloorPicture := APicture;
        AWorld.Events.Add('picture ' + IntToStr(APicture));
        plat.High := AWorld.NextHighestFloor(sec, sec.FloorHeight);
        plat.Wait := 0;
        plat.Status := TPlatStatus.Up;
        sec.Special := 0;
        AWorld.Events.Add('clear special');
        Sound(AWorld, TPlatSound.Move, sec);
      end;

    TPlatKind.RaiseAndChange:
      begin
        plat.Speed := PLATSPEED div 2;
        sec.FloorPicture := APicture;
        AWorld.Events.Add('picture ' + IntToStr(APicture));
        plat.High := sec.FloorHeight + amount * FRACUNIT;
        plat.Wait := 0;
        plat.Status := TPlatStatus.Up;
        Sound(AWorld, TPlatSound.Move, sec);
      end;

    TPlatKind.DownWaitUpStay:
      begin
        plat.Speed := PLATSPEED * 4;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus.Down;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.BlazeDownWaitUpStay:
      begin
        plat.Speed := PLATSPEED * 8;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus.Down;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.PerpetualRaise:
      begin
        plat.Speed := PLATSPEED;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := AWorld.HighestFloorSurrounding(sec);
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus(ARandom.NextPlay and 1);
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.ToggleUpDown:
      begin
        plat.Speed := PLATSPEED;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Crush := True;
        plat.Low := sec.CeilingHeight;
        plat.High := sec.FloorHeight;
        plat.Status := TPlatStatus.Down;
      end;
  end;
end;

procedure OldDoomWakeUp(var plt: TOldPlat);
begin
  if plt.Status = TPlatStatus.InStasis then
  begin
    if plt.Kind = TPlatKind.ToggleUpDown then
    begin
      if plt.OldStatus = TPlatStatus.Up then
        plt.Status := TPlatStatus.Down
      else
        plt.Status := TPlatStatus.Up;
    end
    else
      plt.Status := plt.OldStatus;
  end;
end;

procedure OldPlainWakeUp(var plt: TOldPlat);
begin
  if plt.Status = TPlatStatus.InStasis then
    plt.Status := plt.OldStatus;
end;

//==============================================================================
// Heretic
//==============================================================================
procedure OldHereticPlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
var
  res: TPlatMoveResult;
begin
  case plat.Status of
    TPlatStatus.Up:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.High, plat.Crush, 1);

        if (plat.Kind = TPlatKind.RaiseAndChange) or (plat.Kind = TPlatKind.RaiseToNearestAndChange) then
        begin
          if AWorld.LevelTime and 7 = 0 then
            Sound(AWorld, TPlatSound.Move, plat.Sector);
        end;

        if (res = TPlatMoveResult.Crushed) and not plat.Crush then
        begin
          plat.Count := plat.Wait;
          plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end
        else
        begin
          if res = TPlatMoveResult.PastDestination then
          begin
            plat.Count := plat.Wait;
            plat.Status := TPlatStatus.Waiting;
            Sound(AWorld, TPlatSound.Stop, plat.Sector);

            case plat.Kind of
              TPlatKind.BlazeDownWaitUpStay,
              TPlatKind.DownWaitUpStay:
                AWorld.RemovePlat(nil);
              TPlatKind.RaiseAndChange,
              TPlatKind.RaiseToNearestAndChange:
                AWorld.RemovePlat(nil);
            end;
          end;
        end;
      end;

    TPlatStatus.Down:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.Low, False, -1);

        if res = TPlatMoveResult.PastDestination then
        begin
          plat.Count := plat.Wait;
          plat.Status := TPlatStatus.Waiting;
          Sound(AWorld, TPlatSound.Stop, plat.Sector);
        end;
      end;

    TPlatStatus.Waiting:
      begin
        plat.Count := plat.Count - 1;
        if plat.Count = 0 then
        begin
          if plat.Sector.FloorHeight = plat.Low then
            plat.Status := TPlatStatus.Up
          else
            plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end;
      end;
  end;
end;

procedure OldHereticSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; APicture, amount: Integer);
begin
  plat.Crush := False;

  case plat.Kind of
    TPlatKind.RaiseToNearestAndChange:
      begin
        plat.Speed := PLATSPEED div 2;
        sec.FloorPicture := APicture;
        AWorld.Events.Add('picture ' + IntToStr(APicture));
        plat.High := AWorld.NextHighestFloor(sec, sec.FloorHeight);
        plat.Wait := 0;
        plat.Status := TPlatStatus.Up;
        sec.Special := 0;
        AWorld.Events.Add('clear special');
        Sound(AWorld, TPlatSound.Move, sec);
      end;

    TPlatKind.RaiseAndChange:
      begin
        plat.Speed := PLATSPEED div 2;
        sec.FloorPicture := APicture;
        AWorld.Events.Add('picture ' + IntToStr(APicture));
        plat.High := sec.FloorHeight + amount * FRACUNIT;
        plat.Wait := 0;
        plat.Status := TPlatStatus.Up;
        Sound(AWorld, TPlatSound.Move, sec);
      end;

    TPlatKind.DownWaitUpStay:
      begin
        plat.Speed := PLATSPEED * 4;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus.Down;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.BlazeDownWaitUpStay:
      begin
        plat.Speed := PLATSPEED * 8;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus.Down;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.PerpetualRaise:
      begin
        plat.Speed := PLATSPEED;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := AWorld.HighestFloorSurrounding(sec);
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus(ARandom.NextPlay and 1);
        Sound(AWorld, TPlatSound.Start, sec);
      end;
  end;
end;

//==============================================================================
// Strife
//==============================================================================
procedure OldStrifePlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
var
  res: TPlatMoveResult;
begin
  case plat.Status of
    TPlatStatus.Up:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.High, plat.Crush, 1);

        if (plat.Kind = TPlatKind.RaiseAndChange) or
           (plat.Kind = TPlatKind.RaiseToNearestAndChange) or
           (plat.Kind = TPlatKind.SlowDownWaitUpStay) then
        begin
          if AWorld.LevelTime and 7 = 0 then
            Sound(AWorld, TPlatSound.Move, plat.Sector);
        end;

        if (res = TPlatMoveResult.Crushed) and not plat.Crush then
        begin
          plat.Count := plat.Wait;
          plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end
        else
        begin
          if res = TPlatMoveResult.PastDestination then
          begin
            if plat.Kind = TPlatKind.ToggleUpDown then
            begin
              plat.OldStatus := plat.Status;
              plat.Status := TPlatStatus.InStasis;
            end
            else
            begin
              plat.Count := plat.Wait;
              plat.Status := TPlatStatus.Waiting;
              Sound(AWorld, TPlatSound.Stop, plat.Sector);
            end;

            case plat.Kind of
              TPlatKind.BlazeDownWaitUpStay,
              TPlatKind.DownWaitUpStay,
              TPlatKind.RaiseAndChange,
              TPlatKind.RaiseToNearestAndChange,
              TPlatKind.GenericLift,
              TPlatKind.SlowDownWaitUpStay:
                AWorld.RemovePlat(nil);
            end;
          end;
        end;
      end;

    TPlatStatus.Down:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.Low, False, -1);

        if plat.Kind = TPlatKind.SlowDownWaitUpStay then
          if AWorld.LevelTime and 7 = 0 then
            Sound(AWorld, TPlatSound.Move, plat.Sector);

        if res = TPlatMoveResult.PastDestination then
        begin
          if plat.Kind = TPlatKind.ToggleUpDown then
          begin
            plat.OldStatus := plat.Status;
            plat.Status := TPlatStatus.InStasis;
          end
          else
          begin
            plat.Count := plat.Wait;
            plat.Status := TPlatStatus.Waiting;
            Sound(AWorld, TPlatSound.Stop, plat.Sector);
          end;

          if plat.Kind in [TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange,
            TPlatKind.UpWaitDownStay] then
            AWorld.RemovePlat(nil);
        end;
      end;

    TPlatStatus.Waiting:
      begin
        plat.Count := plat.Count - 1;
        if plat.Count = 0 then
        begin
          if plat.Sector.FloorHeight = plat.Low then
            plat.Status := TPlatStatus.Up
          else
            plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end;
      end;
  end;
end;

procedure OldStrifeSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; APicture, amount: Integer);
begin
  plat.Crush := False;
  plat.Low := sec.FloorHeight;

  case plat.Kind of
    TPlatKind.RaiseToNearestAndChange:
      begin
        plat.Speed := PLATSPEED div 2;
        sec.FloorPicture := APicture;
        AWorld.Events.Add('picture ' + IntToStr(APicture));
        plat.High := AWorld.NextHighestFloor(sec, sec.FloorHeight);
        plat.Wait := 0;
        plat.Status := TPlatStatus.Up;
        sec.Special := 0;
        AWorld.Events.Add('clear special');
        Sound(AWorld, TPlatSound.Move, sec);
      end;

    TPlatKind.RaiseAndChange:
      begin
        plat.Speed := PLATSPEED div 2;
        sec.FloorPicture := APicture;
        AWorld.Events.Add('picture ' + IntToStr(APicture));
        plat.High := sec.FloorHeight + amount * FRACUNIT;
        plat.Wait := 0;
        plat.Status := TPlatStatus.Up;
        Sound(AWorld, TPlatSound.Move, sec);
      end;

    TPlatKind.UpWaitDownStay:
      begin
        plat.Speed := PLATSPEED * 4;
        plat.High := AWorld.NextHighestFloor(sec, sec.FloorHeight);
        plat.Low := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus.Up;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.DownWaitUpStay:
      begin
        plat.Speed := PLATSPEED * 4;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus.Down;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.SlowDownWaitUpStay:
      begin
        plat.Speed := PLATSPEED;
        plat.Low := AWorld.LowestFloorSurrounding(sec);

        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;

        plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * (PLATWAIT * 10);
        plat.Status := TPlatStatus.Down;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.BlazeDownWaitUpStay:
      begin
        plat.Speed := PLATSPEED * 8;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus.Down;
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.PerpetualRaise:
      begin
        plat.Speed := PLATSPEED;
        plat.Low := AWorld.LowestFloorSurrounding(sec);
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := AWorld.HighestFloorSurrounding(sec);
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Wait := TICRATE * PLATWAIT;
        plat.Status := TPlatStatus(ARandom.NextPlay and 1);
        Sound(AWorld, TPlatSound.Start, sec);
      end;

    TPlatKind.ToggleUpDown:
      begin
        plat.Speed := PLATSPEED;
        plat.Wait := 35 * PLATWAIT;
        plat.Crush := True;
        plat.Low := sec.CeilingHeight;
        plat.High := sec.FloorHeight;
        plat.Status := TPlatStatus.Down;
      end;
  end;
end;

//==============================================================================
// the scripted platforms
//==============================================================================
procedure OldUdmfPlatRaise(AWorld: TFakePlatWorld; var plat: TOldPlat);
var
  res: TPlatMoveResult;
begin
  case plat.Status of
    TPlatStatus.Up:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.High, plat.Crush, 1);
        if (res = TPlatMoveResult.Crushed) and not plat.Crush then
        begin
          plat.Count := plat.Wait;
          plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end
        else if res = TPlatMoveResult.PastDestination then
        begin
          plat.Count := plat.Wait;
          plat.Status := TPlatStatus.Waiting;
          Sound(AWorld, TPlatSound.Stop, plat.Sector);
          if (plat.UdmfKind = TUdmfPlatKind.DownWaitUpStay) or
            (plat.UdmfKind = TUdmfPlatKind.DownByValueWaitUpStay) or
            (plat.UdmfKind = TUdmfPlatKind.DownWaitUpStayLip) then
            AWorld.RemovePlat(nil);
        end;
      end;
    TPlatStatus.Down:
      begin
        res := AWorld.MovePlane(plat.Sector, plat.Speed, plat.Low, False, -1);
        if res = TPlatMoveResult.PastDestination then
        begin
          plat.Count := plat.Wait;
          plat.Status := TPlatStatus.Waiting;
          if (plat.UdmfKind = TUdmfPlatKind.UpWaitDownStay) or
            (plat.UdmfKind = TUdmfPlatKind.UpByValueWaitDownStay) or
            (plat.UdmfKind = TUdmfPlatKind.UpNearestWaitDownStay) then
            AWorld.RemovePlat(nil);
          Sound(AWorld, TPlatSound.Stop, plat.Sector);
        end;
      end;
    TPlatStatus.Waiting:
      begin
        Dec(plat.Count);
        if plat.Count <= 0 then
        begin
          if plat.Sector.FloorHeight = plat.Low then
            plat.Status := TPlatStatus.Up
          else
            plat.Status := TPlatStatus.Down;
          Sound(AWorld, TPlatSound.Start, plat.Sector);
        end;
      end;
  end;
end;

procedure OldUdmfSetup(AWorld: TFakePlatWorld; const ARandom: IGameRandom; var plat: TOldPlat;
  sec: TFakePlatSector; const args: array of Integer);
begin
  plat.Crush := False;
  plat.Tag := args[0];
  plat.Speed := args[1] * (FRACUNIT div 8);
  case plat.UdmfKind of
    TUdmfPlatKind.DownWaitUpStay:
      begin
        plat.Low := AWorld.LowestFloorSurrounding(sec) + 8 * FRACUNIT;
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus.Down;
      end;
    TUdmfPlatKind.DownWaitUpStayLip:
      begin
        plat.Low := AWorld.LowestFloorSurrounding(sec) + args[3] * FRACUNIT;
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus.Down;
      end;
    TUdmfPlatKind.DownByValueWaitUpStay:
      begin
        plat.Low := sec.FloorHeight - args[3] * 8 * FRACUNIT;
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus.Down;
      end;
    TUdmfPlatKind.UpWaitDownStay:
      begin
        plat.High := AWorld.HighestFloorSurrounding(sec);
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Low := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus.Up;
      end;
    TUdmfPlatKind.UpNearestWaitDownStay:
      begin
        plat.High := AWorld.NextHighestFloor(sec, sec.FloorHeight);
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Low := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus.Up;
      end;
    TUdmfPlatKind.UpByValueWaitDownStay:
      begin
        plat.High := sec.FloorHeight + args[3] * 8 * FRACUNIT;
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Low := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus.Up;
      end;
    TUdmfPlatKind.PerpetualRaise:
      begin
        plat.Low := AWorld.LowestFloorSurrounding(sec) + 8 * FRACUNIT;
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := AWorld.HighestFloorSurrounding(sec);
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus(ARandom.NextPlay and 1);
      end;
    TUdmfPlatKind.PerpetualRaiseLip:
      begin
        plat.Low := AWorld.LowestFloorSurrounding(sec) + args[3] * FRACUNIT;
        if plat.Low > sec.FloorHeight then
          plat.Low := sec.FloorHeight;
        plat.High := AWorld.HighestFloorSurrounding(sec);
        if plat.High < sec.FloorHeight then
          plat.High := sec.FloorHeight;
        plat.Wait := args[2];
        plat.Status := TPlatStatus(ARandom.NextPlay and 1);
      end;
  end;
end;

end.
