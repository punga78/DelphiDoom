{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the making of vertical doors                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Door.Spawner;

// The speed and the heights are fixed point numbers: as in the old code they wrap
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Thinkers.Door.Types, DelphiDoom.Thinkers.Door.Intf;

type
  /// <summary>
  ///   The part of EV_DoDoor, EV_VerticalDoor, P_SpawnDoorCloseIn30 and P_SpawnDoorRaiseIn5Mins
  ///   (and of the scripted EVH_DoDoor and EVH_VerticalDoor) that decides the values of a new
  ///   door. The engine finds the sectors, makes the thinker and writes the state in it
  /// </summary>
  TDoorSpawner = class(TInterfacedObject, IDoorSpawner)
  strict private
    FProfile: TDoorProfile;
    FSounds: IDoorSounds;
    FQueries: IDoorSectorQueries;
    procedure PlaySound(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
    class function Contains(const ASpecials: TArray<Integer>; ASpecial: Integer): Boolean; static;
    function ManualKindOf(ASpecial: Integer): TDoorManualKind;
  public
    constructor Create(const AProfile: TDoorProfile; const ASounds: IDoorSounds;
      const AQueries: IDoorSectorQueries);
    function SpawnTagged(ASector: Pointer; ACeilingHeight: Integer; AKind: TDoorKind;
      const AInput: TDoorSpawnInput): TDoorState;
    function SpawnManual(ASector: Pointer; ASpecial: Integer; const AInput: TDoorSpawnInput;
      out AConsumeSpecial: Boolean): TDoorState;
    function CloseInThirtySeconds: TDoorState;
    function RaiseInFiveMinutes(ASector: Pointer): TDoorState;
    function Retrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
      out AAction: TDoorRetrigger): Boolean;
  end;

implementation

uses
  System.SysUtils;

{ TDoorSpawner }

constructor TDoorSpawner.Create(const AProfile: TDoorProfile; const ASounds: IDoorSounds;
  const AQueries: IDoorSectorQueries);
begin
  inherited Create;
  if not Assigned(ASounds) then
    raise EArgumentNilException.Create('ASounds');
  if not Assigned(AQueries) then
    raise EArgumentNilException.Create('AQueries');
  FProfile := AProfile;
  FSounds := ASounds;
  FQueries := AQueries;
end;

procedure TDoorSpawner.PlaySound(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
begin
  if ASound <> TDoorSound.None then
    FSounds.Play(ASector, ASound, AState);
end;

class function TDoorSpawner.Contains(const ASpecials: TArray<Integer>; ASpecial: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to High(ASpecials) do
    if ASpecials[LIndex] = ASpecial then
    begin
      Result := True;
      Break;
    end;
end;

function TDoorSpawner.ManualKindOf(ASpecial: Integer): TDoorManualKind;
var
  LKind: TDoorManualKind;
begin
  Result := FProfile.ManualDefault;
  for LKind := Low(TDoorManualKind) to High(TDoorManualKind) do
    if Contains(FProfile.ManualSpecials[LKind], ASpecial) then
    begin
      Result := LKind;
      Break;
    end;
end;

function TDoorSpawner.SpawnTagged(ASector: Pointer; ACeilingHeight: Integer; AKind: TDoorKind;
  const AInput: TDoorSpawnInput): TDoorState;
var
  LSpawn: TDoorSpawnRules;
begin
  LSpawn := FProfile.Rules[AKind].Spawn;
  Result := Default(TDoorState);
  Result.Kind := AKind;
  Result.TopWait := AInput.TopWait;
  Result.OpenSound := AInput.OpenSound;
  Result.CloseSound := AInput.CloseSound;
  if LSpawn.SpeedOverride <> 0 then
    Result.Speed := LSpawn.SpeedOverride
  else
    Result.Speed := AInput.Speed * LSpawn.SpeedFactor;
  Result.Direction := LSpawn.Direction;

  case LSpawn.TopMode of
    TDoorTopMode.CeilingHeight:
      Result.TopHeight := ACeilingHeight;
    TDoorTopMode.LowestCeiling:
      Result.TopHeight := FQueries.LowestCeilingSurrounding(ASector) - DOOR_CEILING_GAP;
  end;

  // a split door keeps the height that its floor goes down to in the wait field
  case LSpawn.SplitFloor of
    TDoorSplitFloor.Lowest:
      Result.TopWait := FQueries.LowestFloorSurrounding(ASector);
    TDoorSplitFloor.Highest:
      Result.TopWait := FQueries.HighestFloorSurrounding(ASector);
  end;

  if LSpawn.TopWaitInEighths then
    Result.TopWait := (Result.TopWait * DOOR_TICRATE) div 8;

  if (not LSpawn.SoundOnlyIfMoves) or (Result.TopHeight <> ACeilingHeight) then
    PlaySound(ASector, LSpawn.Sound, Result);
end;

function TDoorSpawner.SpawnManual(ASector: Pointer; ASpecial: Integer;
  const AInput: TDoorSpawnInput; out AConsumeSpecial: Boolean): TDoorState;
var
  LManual: TDoorManualKind;
begin
  LManual := ManualKindOf(ASpecial);
  AConsumeSpecial := FProfile.ManualConsumesSpecial[LManual];

  Result := Default(TDoorState);
  Result.Kind := FProfile.ManualKinds[LManual];
  Result.Direction := 1;
  Result.Speed := AInput.Speed * FProfile.ManualSpeedFactors[LManual];
  Result.TopWait := AInput.TopWait;
  Result.OpenSound := AInput.OpenSound;
  Result.CloseSound := AInput.CloseSound;
  // the top of the movement range
  Result.TopHeight := FQueries.LowestCeilingSurrounding(ASector) - DOOR_CEILING_GAP;
  PlaySound(ASector, FProfile.ManualSounds[LManual], Result);
end;

function TDoorSpawner.CloseInThirtySeconds: TDoorState;
begin
  Result := Default(TDoorState);
  Result.Kind := TDoorKind.Normal;
  Result.Direction := 0;
  Result.Speed := DOOR_SPEED;
  Result.TopCountdown := 30 * DOOR_TICRATE;
end;

function TDoorSpawner.RaiseInFiveMinutes(ASector: Pointer): TDoorState;
begin
  Result := Default(TDoorState);
  Result.Kind := TDoorKind.RaiseIn5Mins;
  Result.Direction := 2;
  Result.Speed := DOOR_SPEED;
  Result.TopHeight := FQueries.LowestCeilingSurrounding(ASector) - DOOR_CEILING_GAP;
  Result.TopWait := DOOR_WAIT;
  Result.TopCountdown := 5 * 60 * DOOR_TICRATE;
end;

function TDoorSpawner.Retrigger(ASpecial, ADirection: Integer; AThingIsPlayer: Boolean;
  out AAction: TDoorRetrigger): Boolean;
begin
  AAction := TDoorRetrigger.Ignore;
  Result := Contains(FProfile.RetriggerSpecials, ASpecial);
  if Result then
  begin
    if ADirection = -1 then
      AAction := TDoorRetrigger.GoUp
    else if AThingIsPlayer then
      // the monsters never close doors
      AAction := TDoorRetrigger.GoDown;
  end;
end;

end.
