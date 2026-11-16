{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the classic platforms                        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Platform.Machine;

// The heights are fixed point: the old code let the products wrap and so does this one
{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Platform.Intf;

type
  /// <summary>
  ///   The platforms and lifts of Doom, Heretic and Strife (T_PlatRaise, the type switch of
  ///   EV_DoPlat and the stasis of P_ActivateInStasis and EV_StopPlat). The thinker stays a record of
  ///   the engine: this class works on a copy of its fields (TPlatState) and asks the game, through
  ///   IPlatHost and IPlatSurroundings, for what it cannot know. The random numbers are used in the
  ///   same place and order as in the old code
  /// </summary>
  TPlatMachine = class(TInterfacedObject, IPlatMachine)
  strict private
    FHost: IPlatHost;
    FSurroundings: IPlatSurroundings;
    FRandom: IGameRandom;
    FProfile: TPlatProfile;
    procedure SetLowestAndHighestFloor(ASector: Pointer; AWithHighest: Boolean;
      var AState: TPlatState);
    procedure ConfigureDownWaitUpStay(ASector: Pointer; ASpeed, AWait: Integer;
      var AState: TPlatState);
  public
    /// <exception cref="EArgumentNilException">A service is nil</exception>
    constructor Create(const AHost: IPlatHost; const ASurroundings: IPlatSurroundings;
      const ARandom: IGameRandom; const AProfile: TPlatProfile);
    procedure Configure(ASector: Pointer; AKind: TPlatKind; APictureOfLine, AAmount: Integer;
      var AState: TPlatState);
    procedure Tick(APlat, ASector: Pointer; AKind: TPlatKind; var AState: TPlatState);
    function WakeUpStatus(AKind: TPlatKind; AOldStatus: TPlatStatus): TPlatStatus;
    procedure Pause(var AState: TPlatState);
    function IsToggle(AKind: TPlatKind): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TPlatMachine }

constructor TPlatMachine.Create(const AHost: IPlatHost; const ASurroundings: IPlatSurroundings;
  const ARandom: IGameRandom; const AProfile: TPlatProfile);
begin
  inherited Create;
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  if not Assigned(ASurroundings) then
    raise EArgumentNilException.Create('ASurroundings');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FHost := AHost;
  FSurroundings := ASurroundings;
  FRandom := ARandom;
  FProfile := AProfile;
end;

function TPlatMachine.IsToggle(AKind: TPlatKind): Boolean;
begin
  Result := FProfile.HasToggle and (AKind = TPlatKind.ToggleUpDown);
end;

procedure TPlatMachine.Tick(APlat, ASector: Pointer; AKind: TPlatKind; var AState: TPlatState);
var
  LResult: TPlatMoveResult;
begin
  case AState.Status of
    TPlatStatus.Up:
      begin
        LResult := FHost.MovePlane(ASector, AState.Speed, AState.High, AState.Crush,
          PLAT_DIRECTION_UP);

        if AKind in FProfile.MoveSoundWhileRising then
          if (FHost.GetLevelTime and 7) = 0 then
            FHost.PlaySound(ASector, TPlatSound.Move);

        if (LResult = TPlatMoveResult.Crushed) and not AState.Crush then
        begin
          AState.Count := AState.Wait;
          AState.Status := TPlatStatus.Down;
          FHost.PlaySound(ASector, TPlatSound.Start);
        end
        else if LResult = TPlatMoveResult.PastDestination then
        begin
          if IsToggle(AKind) then
          begin
            // in stasis awaiting the next toggle activation
            AState.OldStatus := AState.Status;
            AState.Status := TPlatStatus.InStasis;
          end
          else
          begin
            AState.Count := AState.Wait;
            AState.Status := TPlatStatus.Waiting;
            FHost.PlaySound(ASector, TPlatSound.Stop);
          end;

          // lifts and pure raises are done at the end of the up stroke, only the perpetual
          // ones wait and go back down
          if AKind in FProfile.RemovedAtTop then
            FHost.RemovePlat(APlat);
        end;
      end;

    TPlatStatus.Down:
      begin
        LResult := FHost.MovePlane(ASector, AState.Speed, AState.Low, False, PLAT_DIRECTION_DOWN);

        if AKind in FProfile.MoveSoundWhileLowering then
          if (FHost.GetLevelTime and 7) = 0 then
            FHost.PlaySound(ASector, TPlatSound.Move);

        if LResult = TPlatMoveResult.PastDestination then
        begin
          if IsToggle(AKind) then
          begin
            AState.OldStatus := AState.Status;
            AState.Status := TPlatStatus.InStasis;
          end
          else
          begin
            AState.Count := AState.Wait;
            AState.Status := TPlatStatus.Waiting;
            FHost.PlaySound(ASector, TPlatSound.Stop);
          end;

          // a platform that raises and bounces is removed so it can be tried again
          if AKind in FProfile.RemovedAtBottom then
            if (not FProfile.RemovalAtBottomNeedsModernEngine) or FHost.IsModernEngine then
              FHost.RemovePlat(APlat);
        end;
      end;

    TPlatStatus.Waiting:
      begin
        AState.Count := AState.Count - 1;
        if AState.Count = 0 then
        begin
          if FHost.GetFloorHeight(ASector) = AState.Low then
            AState.Status := TPlatStatus.Up
          else
            AState.Status := TPlatStatus.Down;
          FHost.PlaySound(ASector, TPlatSound.Start);
        end;
      end;
  end;
end;

procedure TPlatMachine.SetLowestAndHighestFloor(ASector: Pointer; AWithHighest: Boolean;
  var AState: TPlatState);
var
  LFloor: Integer;
begin
  LFloor := FSurroundings.GetFloorHeight(ASector);
  AState.Low := FSurroundings.LowestFloorSurrounding(ASector);
  if AState.Low > LFloor then
    AState.Low := LFloor;
  if AWithHighest then
  begin
    AState.High := FSurroundings.HighestFloorSurrounding(ASector);
    if AState.High < LFloor then
      AState.High := LFloor;
  end
  else
    AState.High := LFloor;
end;

procedure TPlatMachine.ConfigureDownWaitUpStay(ASector: Pointer; ASpeed, AWait: Integer;
  var AState: TPlatState);
begin
  AState.Speed := ASpeed;
  SetLowestAndHighestFloor(ASector, False, AState);
  AState.Wait := AWait;
  AState.Status := TPlatStatus.Down;
  FHost.PlaySound(ASector, TPlatSound.Start);
end;

procedure TPlatMachine.Configure(ASector: Pointer; AKind: TPlatKind; APictureOfLine,
  AAmount: Integer; var AState: TPlatState);
var
  LFloor: Integer;
begin
  LFloor := FSurroundings.GetFloorHeight(ASector);

  // do not let a raising platform bounce a head off a ceiling and then go down forever: the low
  // position starts as the height of the platform when it is triggered
  if FProfile.LowStartsAtFloor then
    AState.Low := LFloor;

  case AKind of
    TPlatKind.RaiseToNearestAndChange:
      begin
        AState.Speed := PLAT_SPEED div 2;
        FSurroundings.SetFloorPicture(ASector, APictureOfLine);
        AState.High := FSurroundings.NextHighestFloor(ASector, LFloor);
        AState.Wait := 0;
        AState.Status := TPlatStatus.Up;
        // no more damage, if applicable
        FSurroundings.ClearSpecial(ASector);
        FHost.PlaySound(ASector, TPlatSound.Move);
      end;

    TPlatKind.RaiseAndChange:
      begin
        AState.Speed := PLAT_SPEED div 2;
        FSurroundings.SetFloorPicture(ASector, APictureOfLine);
        AState.High := LFloor + AAmount * PLAT_FRACUNIT;
        AState.Wait := 0;
        AState.Status := TPlatStatus.Up;
        FHost.PlaySound(ASector, TPlatSound.Move);
      end;

    TPlatKind.UpWaitDownStay:
      begin
        // Strife
        AState.Speed := PLAT_SPEED * 4;
        AState.High := FSurroundings.NextHighestFloor(ASector, LFloor);
        AState.Low := LFloor;
        AState.Wait := PLAT_TICS_PER_SECOND * PLAT_WAIT_SECONDS;
        AState.Status := TPlatStatus.Up;
        FHost.PlaySound(ASector, TPlatSound.Start);
      end;

    TPlatKind.DownWaitUpStay:
      ConfigureDownWaitUpStay(ASector, PLAT_SPEED * 4,
        PLAT_TICS_PER_SECOND * PLAT_WAIT_SECONDS, AState);

    TPlatKind.SlowDownWaitUpStay:
      // Strife
      ConfigureDownWaitUpStay(ASector, PLAT_SPEED,
        PLAT_TICS_PER_SECOND * (PLAT_WAIT_SECONDS * 10), AState);

    TPlatKind.BlazeDownWaitUpStay:
      ConfigureDownWaitUpStay(ASector, PLAT_SPEED * 8,
        PLAT_TICS_PER_SECOND * PLAT_WAIT_SECONDS, AState);

    TPlatKind.PerpetualRaise:
      begin
        AState.Speed := PLAT_SPEED;
        SetLowestAndHighestFloor(ASector, True, AState);
        AState.Wait := PLAT_TICS_PER_SECOND * PLAT_WAIT_SECONDS;
        if (FRandom.NextPlay and 1) = 0 then
          AState.Status := TPlatStatus.Up
        else
          AState.Status := TPlatStatus.Down;
        FHost.PlaySound(ASector, TPlatSound.Start);
      end;

    TPlatKind.ToggleUpDown:
      begin
        // the instant toggle: speed and wait are not used
        AState.Speed := PLAT_SPEED;
        AState.Wait := PLAT_TICS_PER_SECOND * PLAT_WAIT_SECONDS;
        // crush anything in the way
        AState.Crush := True;
        // toggle between the ceiling and the floor, inclusive
        AState.Low := FSurroundings.GetCeilingHeight(ASector);
        AState.High := LFloor;
        AState.Status := TPlatStatus.Down;
      end;
  end;
end;

function TPlatMachine.WakeUpStatus(AKind: TPlatKind; AOldStatus: TPlatStatus): TPlatStatus;
begin
  if IsToggle(AKind) and FProfile.ToggleReversesOnWake then
  begin
    // the toggle goes the other way
    if AOldStatus = TPlatStatus.Up then
      Result := TPlatStatus.Down
    else
      Result := TPlatStatus.Up;
  end
  else
    Result := AOldStatus;
end;

procedure TPlatMachine.Pause(var AState: TPlatState);
begin
  AState.OldStatus := AState.Status;
  AState.Status := TPlatStatus.InStasis;
end;

end.
