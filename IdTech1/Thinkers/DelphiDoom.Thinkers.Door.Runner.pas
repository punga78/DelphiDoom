{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - one tic of a vertical door                   }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Door.Runner;

// The speed and the heights are fixed point numbers: as in the old code they wrap
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Door.Types, DelphiDoom.Thinkers.Door.Intf;

type
  /// <summary>
  ///   T_VerticalDoor and TH_VerticalDoor: the door waits, goes down or goes up. What changes
  ///   between games is in the profile, and the movement of the ceiling, the sounds and the
  ///   compatibility option come from the services given to the constructor
  /// </summary>
  TDoorRunner = class(TInterfacedObject, IDoorRunner)
  strict private
    FProfile: TDoorProfile;
    FMover: IDoorPlaneMover;
    FSounds: IDoorSounds;
    FOptions: IDoorOptions;
    procedure PlaySound(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
    procedure TickWaiting(var AState: TDoorState; ASector: Pointer; ARules: PDoorKindRules);
    procedure TickInitialWait(var AState: TDoorState; ASector: Pointer; ARules: PDoorKindRules;
      var AOutcome: TDoorTickOutcome);
    procedure TickSplit(const AState: TDoorState; ASector: Pointer;
      var AOutcome: TDoorTickOutcome);
    procedure TickDown(var AState: TDoorState; ASector: Pointer; AFloorHeight: Integer;
      ARules: PDoorKindRules; var AOutcome: TDoorTickOutcome);
    procedure TickUp(var AState: TDoorState; ASector: Pointer; ARules: PDoorKindRules;
      var AOutcome: TDoorTickOutcome);
  public
    constructor Create(const AProfile: TDoorProfile; const AMover: IDoorPlaneMover;
      const ASounds: IDoorSounds; const AOptions: IDoorOptions);
    function Tick(var AState: TDoorState; ASector: Pointer; AFloorHeight: Integer): TDoorTickOutcome;
  end;

implementation

uses
  System.SysUtils;

{ TDoorRunner }

constructor TDoorRunner.Create(const AProfile: TDoorProfile; const AMover: IDoorPlaneMover;
  const ASounds: IDoorSounds; const AOptions: IDoorOptions);
begin
  inherited Create;
  if not Assigned(AMover) then
    raise EArgumentNilException.Create('AMover');
  if not Assigned(ASounds) then
    raise EArgumentNilException.Create('ASounds');
  if not Assigned(AOptions) then
    raise EArgumentNilException.Create('AOptions');
  FProfile := AProfile;
  FMover := AMover;
  FSounds := ASounds;
  FOptions := AOptions;
end;

procedure TDoorRunner.PlaySound(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
begin
  if ASound <> TDoorSound.None then
    FSounds.Play(ASector, ASound, AState);
end;

procedure TDoorRunner.TickWaiting(var AState: TDoorState; ASector: Pointer;
  ARules: PDoorKindRules);
begin
  AState.TopCountdown := AState.TopCountdown - 1;
  if AState.TopCountdown <> 0 then
    Exit;

  case ARules.WaitEnd of
    TDoorWaitEnd.GoDown:
      begin
        AState.Direction := -1;
        PlaySound(ASector, ARules.WaitEndSound, AState);
      end;
    TDoorWaitEnd.GoUp:
      begin
        AState.Direction := 1;
        if ARules.WaitEndSpeed <> 0 then
          AState.Speed := ARules.WaitEndSpeed;
        PlaySound(ASector, ARules.WaitEndSound, AState);
      end;
  end;
end;

procedure TDoorRunner.TickInitialWait(var AState: TDoorState; ASector: Pointer;
  ARules: PDoorKindRules; var AOutcome: TDoorTickOutcome);
begin
  AState.TopCountdown := AState.TopCountdown - 1;
  if AState.TopCountdown <> 0 then
    Exit;

  if ARules.InitialWaitOpens then
  begin
    AState.Direction := 1;
    if AState.Kind <> ARules.InitialWaitKind then
      AOutcome.KindChanged := True;
    AState.Kind := ARules.InitialWaitKind;
    PlaySound(ASector, ARules.InitialWaitSound, AState);
  end;
end;

procedure TDoorRunner.TickSplit(const AState: TDoorState; ASector: Pointer;
  var AOutcome: TDoorTickOutcome);
var
  LCeiling: TDoorPlaneResult;
  LFloor: TDoorPlaneResult;
begin
  // the two planes always move: the ceiling up to the top, the floor down to the height kept in
  // the wait field
  LCeiling := FMover.MovePlane(ASector, AState.Speed, AState.TopHeight, False, 1, 1);
  LFloor := FMover.MovePlane(ASector, AState.Speed, AState.TopWait, False, 0, -1);
  if (LCeiling = TDoorPlaneResult.PastDest) and (LFloor = TDoorPlaneResult.PastDest) then
    AOutcome.Removed := True;
end;

procedure TDoorRunner.TickDown(var AState: TDoorState; ASector: Pointer; AFloorHeight: Integer;
  ARules: PDoorKindRules; var AOutcome: TDoorTickOutcome);
var
  LResult: TDoorPlaneResult;
  LCompatibility: Boolean;
begin
  LResult := FMover.MovePlane(ASector, AState.Speed, AFloorHeight, False, 1, AState.Direction);
  if LResult = TDoorPlaneResult.PastDest then
  begin
    if FProfile.StopSoundOnPastDest then
      FSounds.Stop(ASector);

    case ARules.DownDone of
      TDoorDownDone.Remove:
        AOutcome.Removed := True;
      TDoorDownDone.WaitThirtySeconds:
        begin
          AState.Direction := 0;
          AState.TopCountdown := DOOR_TICRATE * 30;
        end;
      TDoorDownDone.WaitTopWait:
        begin
          AState.Direction := 0;
          AState.TopCountdown := AState.TopWait;
        end;
      TDoorDownDone.WaitTwoMinutes:
        begin
          AState.Direction := 0;
          AState.TopCountdown := DOOR_TICRATE * 120;
        end;
    end;

    LCompatibility := FOptions.CompatibilityMode;
    if (ARules.DownDoneSound <> TDoorSound.None) and
      (LCompatibility or not ARules.DownDoneSoundNeedsCompatibility) then
      PlaySound(ASector, ARules.DownDoneSound, AState);

    if FProfile.LinkLights and not LCompatibility then
      AOutcome.TurnLightsOff := True;
  end
  else if LResult = TDoorPlaneResult.Crushed then
  begin
    if ARules.Crushed = TDoorCrushed.GoUp then
    begin
      AState.Direction := 1;
      PlaySound(ASector, ARules.CrushedSound, AState);
    end;
  end;
end;

procedure TDoorRunner.TickUp(var AState: TDoorState; ASector: Pointer; ARules: PDoorKindRules;
  var AOutcome: TDoorTickOutcome);
var
  LResult: TDoorPlaneResult;
begin
  LResult := FMover.MovePlane(ASector, AState.Speed, AState.TopHeight, False, 1, AState.Direction);
  if LResult = TDoorPlaneResult.PastDest then
  begin
    if FProfile.StopSoundOnPastDest then
      FSounds.Stop(ASector);

    case ARules.UpDone of
      TDoorUpDone.WaitAtTop:
        begin
          AState.Direction := 0;
          AState.TopCountdown := AState.TopWait;
        end;
      TDoorUpDone.Remove:
        begin
          AOutcome.Removed := True;
          if ARules.UpDoneStopsSound then
            FSounds.Stop(ASector);
        end;
    end;

    if FProfile.LinkLights and not FOptions.CompatibilityMode then
      AOutcome.TurnLightsOn := True;
  end;
end;

function TDoorRunner.Tick(var AState: TDoorState; ASector: Pointer;
  AFloorHeight: Integer): TDoorTickOutcome;
var
  LRules: PDoorKindRules;
begin
  Result := Default(TDoorTickOutcome);
  LRules := @FProfile.Rules[AState.Kind];
  case AState.Direction of
    0:
      TickWaiting(AState, ASector, LRules);
    2:
      TickInitialWait(AState, ASector, LRules, Result);
    -2:
      if FProfile.SplitDoors then
        TickSplit(AState, ASector, Result);
    -1:
      TickDown(AState, ASector, AFloorHeight, LRules, Result);
    1:
      TickUp(AState, ASector, LRules, Result);
  end;
end;

end.
