{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - what each game has for its doors             }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Door.Profiles;

interface

uses
  System.SysUtils, DelphiDoom.Thinkers.Door.Types;

type
  /// <summary>
  ///   The profiles of the doors: for each game and flavor the table of what every kind of door
  ///   does (the statements of T_VerticalDoor, TH_VerticalDoor and of the functions that make
  ///   the doors, written as data). They replace the compiler switches of the old code
  /// </summary>
  TDoorProfiles = class
  public
    /// <summary>The profile of a game and flavor; Hexen has only the scripted doors</summary>
    class function ForGame(AGame: TDoorGame; AFlavor: TDoorFlavor): TDoorProfile; static;
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    class function NameOf(AGame: TDoorGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the four</summary>
    class function TryGameFromName(const AName: string; out AGame: TDoorGame): Boolean; static;
  end;

implementation

resourcestring
  SNoClassicDoors = 'The game %s has no classic doors';

const
  GAME_NAMES: array[TDoorGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');

//==============================================================================
// the helpers that set the same rule on a list of kinds
//==============================================================================

procedure SetWait(var AProfile: TDoorProfile; const AKinds: array of TDoorKind;
  AEnd: TDoorWaitEnd; ASound: TDoorSound; ASpeed: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AKinds) do
  begin
    AProfile.Rules[AKinds[LIndex]].WaitEnd := AEnd;
    AProfile.Rules[AKinds[LIndex]].WaitEndSound := ASound;
    AProfile.Rules[AKinds[LIndex]].WaitEndSpeed := ASpeed;
  end;
end;

procedure SetInitialWait(var AProfile: TDoorProfile; AKind, ANewKind: TDoorKind;
  ASound: TDoorSound);
begin
  AProfile.Rules[AKind].InitialWaitOpens := True;
  AProfile.Rules[AKind].InitialWaitKind := ANewKind;
  AProfile.Rules[AKind].InitialWaitSound := ASound;
end;

procedure SetDown(var AProfile: TDoorProfile; const AKinds: array of TDoorKind;
  ADone: TDoorDownDone; ASound: TDoorSound; ANeedsCompatibility: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AKinds) do
  begin
    AProfile.Rules[AKinds[LIndex]].DownDone := ADone;
    AProfile.Rules[AKinds[LIndex]].DownDoneSound := ASound;
    AProfile.Rules[AKinds[LIndex]].DownDoneSoundNeedsCompatibility := ANeedsCompatibility;
  end;
end;

procedure SetUp(var AProfile: TDoorProfile; const AKinds: array of TDoorKind;
  ADone: TDoorUpDone; AStopsSound: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AKinds) do
  begin
    AProfile.Rules[AKinds[LIndex]].UpDone := ADone;
    AProfile.Rules[AKinds[LIndex]].UpDoneStopsSound := AStopsSound;
  end;
end;

procedure SetNotCrushed(var AProfile: TDoorProfile; const AKinds: array of TDoorKind);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AKinds) do
  begin
    AProfile.Rules[AKinds[LIndex]].Crushed := TDoorCrushed.Nothing;
    AProfile.Rules[AKinds[LIndex]].CrushedSound := TDoorSound.None;
  end;
end;

procedure SetSpawn(var AProfile: TDoorProfile; const AKinds: array of TDoorKind;
  ADirection: Integer; ATopMode: TDoorTopMode; ASound: TDoorSound; AOnlyIfMoves: Boolean;
  ASpeedFactor, ASpeedOverride: Integer; ASplitFloor: TDoorSplitFloor);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AKinds) do
  begin
    AProfile.Rules[AKinds[LIndex]].Spawn.Direction := ADirection;
    AProfile.Rules[AKinds[LIndex]].Spawn.TopMode := ATopMode;
    AProfile.Rules[AKinds[LIndex]].Spawn.Sound := ASound;
    AProfile.Rules[AKinds[LIndex]].Spawn.SoundOnlyIfMoves := AOnlyIfMoves;
    AProfile.Rules[AKinds[LIndex]].Spawn.SpeedFactor := ASpeedFactor;
    AProfile.Rules[AKinds[LIndex]].Spawn.SpeedOverride := ASpeedOverride;
    AProfile.Rules[AKinds[LIndex]].Spawn.SplitFloor := ASplitFloor;
  end;
end;

procedure SetManual(var AProfile: TDoorProfile; AManual: TDoorManualKind; AKind: TDoorKind;
  ASound: TDoorSound; ASpeedFactor: Integer; AConsumes: Boolean;
  const ASpecials: array of Integer);
var
  LIndex: Integer;
begin
  AProfile.ManualKinds[AManual] := AKind;
  AProfile.ManualSounds[AManual] := ASound;
  AProfile.ManualSpeedFactors[AManual] := ASpeedFactor;
  AProfile.ManualConsumesSpecial[AManual] := AConsumes;
  SetLength(AProfile.ManualSpecials[AManual], Length(ASpecials));
  for LIndex := 0 to High(ASpecials) do
    AProfile.ManualSpecials[AManual][LIndex] := ASpecials[LIndex];
end;

procedure SetRetrigger(var AProfile: TDoorProfile; const ASpecials: array of Integer);
var
  LIndex: Integer;
begin
  SetLength(AProfile.RetriggerSpecials, Length(ASpecials));
  for LIndex := 0 to High(ASpecials) do
    AProfile.RetriggerSpecials[LIndex] := ASpecials[LIndex];
end;

/// <summary>
///   An empty profile: nothing happens in any moment, except that something under a door makes
///   it go back up (the "else" of every old case on the result of the move)
/// </summary>
function NewProfile(AGame: TDoorGame; AFlavor: TDoorFlavor;
  ACrushedSound: TDoorSound): TDoorProfile;
var
  LKind: TDoorKind;
  LManual: TDoorManualKind;
begin
  Result := Default(TDoorProfile);
  Result.Game := AGame;
  Result.Flavor := AFlavor;
  for LKind := Low(TDoorKind) to High(TDoorKind) do
  begin
    Result.Rules[LKind].Crushed := TDoorCrushed.GoUp;
    Result.Rules[LKind].CrushedSound := ACrushedSound;
    Result.Rules[LKind].InitialWaitKind := LKind;
    Result.Rules[LKind].Spawn.SpeedFactor := 1;
  end;
  for LManual := Low(TDoorManualKind) to High(TDoorManualKind) do
  begin
    Result.ManualKinds[LManual] := TDoorKind.Normal;
    Result.ManualSounds[LManual] := TDoorSound.Open;
    Result.ManualSpeedFactors[LManual] := 1;
  end;
  Result.ManualDefault := TDoorManualKind.Raising;
end;

//==============================================================================
// Doom (T_VerticalDoor, EV_DoDoor, EV_VerticalDoor of Doom\p_doors.pas)
//==============================================================================
function DoomProfile: TDoorProfile;
begin
  Result := NewProfile(TDoorGame.Doom, TDoorFlavor.Classic, TDoorSound.Open);
  Result.LinkLights := True;

  SetNotCrushed(Result, [TDoorKind.BlazeClose, TDoorKind.Close, TDoorKind.GenBlazeClose,
    TDoorKind.GenClose]);

  SetWait(Result, [TDoorKind.BlazeRaise, TDoorKind.GenBlazeRaise], TDoorWaitEnd.GoDown,
    TDoorSound.BlazeClose, 0);
  SetWait(Result, [TDoorKind.Normal, TDoorKind.GenRaise], TDoorWaitEnd.GoDown,
    TDoorSound.Close, 0);
  SetWait(Result, [TDoorKind.Close30ThenOpen, TDoorKind.GenCdO], TDoorWaitEnd.GoUp,
    TDoorSound.Open, 0);
  SetWait(Result, [TDoorKind.GenBlazeCdO], TDoorWaitEnd.GoUp, TDoorSound.BlazeOpen, 0);

  SetInitialWait(Result, TDoorKind.RaiseIn5Mins, TDoorKind.Normal, TDoorSound.Open);

  // the sound of the blazing doors at the floor is only played in the compatibility mode
  SetDown(Result, [TDoorKind.BlazeRaise, TDoorKind.BlazeClose, TDoorKind.GenBlazeRaise,
    TDoorKind.GenBlazeClose], TDoorDownDone.Remove, TDoorSound.BlazeClose, True);
  SetDown(Result, [TDoorKind.Normal, TDoorKind.Close, TDoorKind.GenRaise, TDoorKind.GenClose],
    TDoorDownDone.Remove, TDoorSound.None, False);
  SetDown(Result, [TDoorKind.Close30ThenOpen], TDoorDownDone.WaitThirtySeconds,
    TDoorSound.None, False);
  SetDown(Result, [TDoorKind.GenCdO, TDoorKind.GenBlazeCdO], TDoorDownDone.WaitTopWait,
    TDoorSound.None, False);

  SetUp(Result, [TDoorKind.BlazeRaise, TDoorKind.Normal, TDoorKind.GenRaise,
    TDoorKind.GenBlazeRaise], TDoorUpDone.WaitAtTop, False);
  SetUp(Result, [TDoorKind.Close30ThenOpen, TDoorKind.BlazeOpen, TDoorKind.Open,
    TDoorKind.GenBlazeOpen, TDoorKind.GenOpen, TDoorKind.GenCdO, TDoorKind.GenBlazeCdO],
    TDoorUpDone.Remove, False);

  SetSpawn(Result, [TDoorKind.BlazeClose], -1, TDoorTopMode.LowestCeiling,
    TDoorSound.BlazeClose, False, 4, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.Close], -1, TDoorTopMode.LowestCeiling, TDoorSound.Close,
    False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.Close30ThenOpen], -1, TDoorTopMode.CeilingHeight,
    TDoorSound.Close, False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.BlazeRaise, TDoorKind.BlazeOpen], 1,
    TDoorTopMode.LowestCeiling, TDoorSound.BlazeOpen, True, 4, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.Normal, TDoorKind.Open], 1, TDoorTopMode.LowestCeiling,
    TDoorSound.Open, True, 1, 0, TDoorSplitFloor.None);

  SetManual(Result, TDoorManualKind.Raising, TDoorKind.Normal, TDoorSound.Open, 1, False,
    [1, 26, 27, 28]);
  SetManual(Result, TDoorManualKind.Opening, TDoorKind.Open, TDoorSound.Open, 1, True,
    [31, 32, 33, 34]);
  SetManual(Result, TDoorManualKind.BlazeRaising, TDoorKind.BlazeRaise, TDoorSound.BlazeOpen,
    4, False, [117]);
  SetManual(Result, TDoorManualKind.BlazeOpening, TDoorKind.BlazeOpen, TDoorSound.BlazeOpen,
    4, True, [118]);

  SetRetrigger(Result, [1, 26, 27, 28, 117]);
end;

//==============================================================================
// Heretic (Heretic\p_doors.pas): no blazing doors, no lights, and the sounds are not the
// ones of Doom (the door that goes down because of the wait still says "open")
//==============================================================================
function HereticProfile: TDoorProfile;
begin
  Result := NewProfile(TDoorGame.Heretic, TDoorFlavor.Classic, TDoorSound.Open);

  SetNotCrushed(Result, [TDoorKind.Close]);

  SetWait(Result, [TDoorKind.Normal], TDoorWaitEnd.GoDown, TDoorSound.Open, 0);
  SetWait(Result, [TDoorKind.Close30ThenOpen], TDoorWaitEnd.GoUp, TDoorSound.Open, 0);

  SetInitialWait(Result, TDoorKind.RaiseIn5Mins, TDoorKind.Normal, TDoorSound.Open);

  SetDown(Result, [TDoorKind.Normal, TDoorKind.Close], TDoorDownDone.Remove,
    TDoorSound.Close, False);
  SetDown(Result, [TDoorKind.Close30ThenOpen], TDoorDownDone.WaitThirtySeconds,
    TDoorSound.None, False);

  SetUp(Result, [TDoorKind.Normal], TDoorUpDone.WaitAtTop, False);
  SetUp(Result, [TDoorKind.Close30ThenOpen, TDoorKind.Open], TDoorUpDone.Remove, True);

  SetSpawn(Result, [TDoorKind.Close], -1, TDoorTopMode.LowestCeiling, TDoorSound.Open,
    False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.Close30ThenOpen], -1, TDoorTopMode.CeilingHeight,
    TDoorSound.Open, False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.Normal, TDoorKind.Open], 1, TDoorTopMode.LowestCeiling,
    TDoorSound.Open, True, 1, 0, TDoorSplitFloor.None);

  SetManual(Result, TDoorManualKind.Raising, TDoorKind.Normal, TDoorSound.Open, 1, False,
    [1, 26, 27, 28]);
  SetManual(Result, TDoorManualKind.Opening, TDoorKind.Open, TDoorSound.Open, 1, True,
    [31, 32, 33, 34]);

  SetRetrigger(Result, [1, 26, 27, 28]);
end;

//==============================================================================
// Strife (Strife\p_doors.pas): split doors, shop doors, and the sounds that the door keeps
//==============================================================================
function StrifeProfile: TDoorProfile;
begin
  Result := NewProfile(TDoorGame.Strife, TDoorFlavor.Classic, TDoorSound.Open);
  Result.LinkLights := True;
  Result.SplitDoors := True;

  SetNotCrushed(Result, [TDoorKind.BlazeClose, TDoorKind.Close, TDoorKind.ShopClose,
    TDoorKind.GenBlazeClose, TDoorKind.GenClose]);

  SetWait(Result, [TDoorKind.BlazeRaise, TDoorKind.GenBlazeRaise], TDoorWaitEnd.GoDown,
    TDoorSound.BlazeClose, 0);
  SetWait(Result, [TDoorKind.Normal, TDoorKind.GenRaise], TDoorWaitEnd.GoDown,
    TDoorSound.Close, 0);
  SetWait(Result, [TDoorKind.ShopClose], TDoorWaitEnd.GoUp, TDoorSound.Open, DOOR_SHOP_SPEED);
  SetWait(Result, [TDoorKind.Close30ThenOpen, TDoorKind.GenCdO], TDoorWaitEnd.GoUp,
    TDoorSound.Open, 0);
  SetWait(Result, [TDoorKind.GenBlazeCdO], TDoorWaitEnd.GoUp, TDoorSound.BlazeOpen, 0);

  SetInitialWait(Result, TDoorKind.RaiseIn5Mins, TDoorKind.Normal, TDoorSound.Open);

  SetDown(Result, [TDoorKind.BlazeRaise, TDoorKind.BlazeClose, TDoorKind.GenBlazeRaise,
    TDoorKind.GenBlazeClose, TDoorKind.Normal, TDoorKind.Close, TDoorKind.GenRaise,
    TDoorKind.GenClose], TDoorDownDone.Remove, TDoorSound.None, False);
  SetDown(Result, [TDoorKind.Close30ThenOpen], TDoorDownDone.WaitThirtySeconds,
    TDoorSound.None, False);
  SetDown(Result, [TDoorKind.GenCdO, TDoorKind.GenBlazeCdO], TDoorDownDone.WaitTopWait,
    TDoorSound.None, False);
  SetDown(Result, [TDoorKind.ShopClose], TDoorDownDone.WaitTwoMinutes, TDoorSound.None, False);

  SetUp(Result, [TDoorKind.BlazeRaise, TDoorKind.Normal, TDoorKind.GenRaise,
    TDoorKind.GenBlazeRaise], TDoorUpDone.WaitAtTop, False);
  SetUp(Result, [TDoorKind.Close30ThenOpen, TDoorKind.BlazeOpen, TDoorKind.Open,
    TDoorKind.ShopClose, TDoorKind.GenBlazeOpen, TDoorKind.GenOpen, TDoorKind.GenCdO,
    TDoorKind.GenBlazeCdO], TDoorUpDone.Remove, False);

  SetSpawn(Result, [TDoorKind.SplitOpen], -2, TDoorTopMode.LowestCeiling, TDoorSound.Open,
    True, 1, DOOR_SPLIT_SPEED, TDoorSplitFloor.Lowest);
  SetSpawn(Result, [TDoorKind.SplitRaiseNearest], -2, TDoorTopMode.LowestCeiling,
    TDoorSound.Open, True, 1, DOOR_SPLIT_SPEED, TDoorSplitFloor.Highest);
  SetSpawn(Result, [TDoorKind.BlazeClose, TDoorKind.ShopClose], -1,
    TDoorTopMode.LowestCeiling, TDoorSound.BlazeClose, False, 4, 0, TDoorSplitFloor.None);
  // the close of Strife says "open" with the sound of the door, as the original
  SetSpawn(Result, [TDoorKind.Close], -1, TDoorTopMode.LowestCeiling, TDoorSound.Open,
    False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.Close30ThenOpen], -1, TDoorTopMode.CeilingHeight,
    TDoorSound.Close, False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.BlazeRaise, TDoorKind.BlazeOpen], 1,
    TDoorTopMode.LowestCeiling, TDoorSound.BlazeOpen, True, 4, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.Normal, TDoorKind.Open], 1, TDoorTopMode.LowestCeiling,
    TDoorSound.Open, True, 1, 0, TDoorSplitFloor.None);

  SetManual(Result, TDoorManualKind.Raising, TDoorKind.Normal, TDoorSound.Open, 1, False,
    [1, 26, 27, 28]);
  SetManual(Result, TDoorManualKind.Opening, TDoorKind.Open, TDoorSound.Open, 1, True,
    [31, 32, 33, 34, 156, 157, 158]);
  SetManual(Result, TDoorManualKind.BlazeRaising, TDoorKind.BlazeRaise, TDoorSound.BlazeOpen,
    4, False, [117]);
  SetManual(Result, TDoorManualKind.BlazeOpening, TDoorKind.BlazeOpen, TDoorSound.BlazeOpen,
    4, True, [118]);

  SetRetrigger(Result, [1, 26, 27, 28, 117, 159, 160, 161, 166, 169, 170, 190, 213, 221, 232]);
end;

//==============================================================================
// the scripted doors (udmf_doors.pas): the same in every game
//==============================================================================
function UdmfProfile(AGame: TDoorGame): TDoorProfile;
var
  LKind: TDoorKind;
begin
  Result := NewProfile(AGame, TDoorFlavor.Udmf, TDoorSound.None);
  Result.StopSoundOnPastDest := True;

  // a new scripted door always plays its sound, whatever the kind
  for LKind := Low(TDoorKind) to High(TDoorKind) do
    Result.Rules[LKind].Spawn.Sound := TDoorSound.Open;

  SetNotCrushed(Result, [TDoorKind.UdmfClose]);

  SetWait(Result, [TDoorKind.UdmfNormal], TDoorWaitEnd.GoDown, TDoorSound.Close, 0);
  SetWait(Result, [TDoorKind.UdmfClose30ThenOpen, TDoorKind.UdmfCloseWaitThenOpen],
    TDoorWaitEnd.GoUp, TDoorSound.None, 0);

  SetInitialWait(Result, TDoorKind.UdmfRaiseIn5Mins, TDoorKind.UdmfNormal, TDoorSound.None);

  SetDown(Result, [TDoorKind.UdmfNormal, TDoorKind.UdmfClose], TDoorDownDone.Remove,
    TDoorSound.None, False);
  SetDown(Result, [TDoorKind.UdmfClose30ThenOpen], TDoorDownDone.WaitThirtySeconds,
    TDoorSound.None, False);
  SetDown(Result, [TDoorKind.UdmfCloseWaitThenOpen], TDoorDownDone.WaitTopWait,
    TDoorSound.None, False);

  SetUp(Result, [TDoorKind.UdmfNormal], TDoorUpDone.WaitAtTop, False);
  SetUp(Result, [TDoorKind.UdmfClose30ThenOpen, TDoorKind.UdmfCloseWaitThenOpen,
    TDoorKind.UdmfOpen], TDoorUpDone.Remove, False);

  SetSpawn(Result, [TDoorKind.UdmfClose], -1, TDoorTopMode.LowestCeiling, TDoorSound.Open,
    False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.UdmfClose30ThenOpen, TDoorKind.UdmfCloseWaitThenOpen], -1,
    TDoorTopMode.CeilingHeight, TDoorSound.Open, False, 1, 0, TDoorSplitFloor.None);
  SetSpawn(Result, [TDoorKind.UdmfNormal, TDoorKind.UdmfOpen], 1, TDoorTopMode.LowestCeiling,
    TDoorSound.Open, False, 1, 0, TDoorSplitFloor.None);
  // the wait of the door that closes, waits and opens is given in eighths of a second
  Result.Rules[TDoorKind.UdmfCloseWaitThenOpen].Spawn.TopWaitInEighths := True;

  SetManual(Result, TDoorManualKind.Raising, TDoorKind.UdmfNormal, TDoorSound.Open, 1, False,
    [12, 13]);
  SetManual(Result, TDoorManualKind.Opening, TDoorKind.UdmfOpen, TDoorSound.Open, 1, True,
    [11]);
  SetManual(Result, TDoorManualKind.BlazeRaising, TDoorKind.UdmfNormal, TDoorSound.Open, 1,
    False, []);
  SetManual(Result, TDoorManualKind.BlazeOpening, TDoorKind.UdmfOpen, TDoorSound.Open, 1,
    False, []);
end;

{ TDoorProfiles }

class function TDoorProfiles.ForGame(AGame: TDoorGame; AFlavor: TDoorFlavor): TDoorProfile;
begin
  if AFlavor = TDoorFlavor.Udmf then
    Result := UdmfProfile(AGame)
  else
    case AGame of
      TDoorGame.Doom:
        Result := DoomProfile;
      TDoorGame.Heretic:
        Result := HereticProfile;
      TDoorGame.Strife:
        Result := StrifeProfile;
    else
      raise EDoorException.CreateFmt(SNoClassicDoors, [NameOf(AGame)]);
    end;
end;

class function TDoorProfiles.NameOf(AGame: TDoorGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TDoorProfiles.TryGameFromName(const AName: string; out AGame: TDoorGame): Boolean;
var
  LGame: TDoorGame;
begin
  Result := False;
  AGame := TDoorGame.Doom;
  for LGame := Low(TDoorGame) to High(TDoorGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Result := True;
      Break;
    end;
end;

end.
