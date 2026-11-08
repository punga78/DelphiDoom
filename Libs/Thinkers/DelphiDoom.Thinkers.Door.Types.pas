{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the types of the vertical doors              }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Door.Types;

{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils;

type
  /// <summary>Raised when a profile is asked for a game that has no doors of that flavor</summary>
  EDoorException = class(Exception);

  /// <summary>The games that have vertical doors</summary>
  TDoorGame = (Doom, Heretic, Hexen, Strife);

  /// <summary>
  ///   The two families of door code of the engine: the classic one (T_VerticalDoor of p_doors,
  ///   with the sounds and the kinds of each game) and the one of the scripted specials
  ///   (TH_VerticalDoor of udmf_doors, the same in every game)
  /// </summary>
  TDoorFlavor = (Classic, Udmf);

  /// <summary>
  ///   The kinds of door of every game together (vldoor_e of the four p_spec). Each game and
  ///   flavor uses its own subset, and the engine converts its enumeration to this one
  /// </summary>
  TDoorKind = (
    Normal,
    Close30ThenOpen,
    Close,
    Open,
    RaiseIn5Mins,
    BlazeRaise,
    BlazeOpen,
    BlazeClose,
    ShopClose,
    SplitRaiseNearest,
    SplitOpen,
    GenRaise,
    GenBlazeRaise,
    GenOpen,
    GenBlazeOpen,
    GenClose,
    GenBlazeClose,
    GenCdO,
    GenBlazeCdO,
    UdmfNormal,
    UdmfClose30ThenOpen,
    UdmfClose,
    UdmfOpen,
    UdmfRaiseIn5Mins,
    UdmfCloseWaitThenOpen
  );

  /// <summary>
  ///   What a door says with its sound: the engine chooses the real sound of the game. In Strife
  ///   Open and Close are the sounds kept in the door (they depend on its texture)
  /// </summary>
  TDoorSound = (None, Open, Close, BlazeOpen, BlazeClose);

  /// <summary>What moving the ceiling of the sector one tic did (result_e)</summary>
  TDoorPlaneResult = (Ok, Crushed, PastDest);

  /// <summary>What a door does when its wait is over</summary>
  TDoorWaitEnd = (Nothing, GoDown, GoUp);

  /// <summary>What a door does when it reaches the floor</summary>
  TDoorDownDone = (Nothing, Remove, WaitThirtySeconds, WaitTopWait, WaitTwoMinutes);

  /// <summary>What a door does when it reaches the top</summary>
  TDoorUpDone = (Nothing, WaitAtTop, Remove);

  /// <summary>What a door does when something is under it</summary>
  TDoorCrushed = (Nothing, GoUp);

  /// <summary>How the top of a new door is found</summary>
  TDoorTopMode = (
    /// <summary>The top height is not set (it stays at 0)</summary>
    Unchanged,
    /// <summary>The ceiling as it is now (the door starts open)</summary>
    CeilingHeight,
    /// <summary>The lowest ceiling around the sector, 4 units lower</summary>
    LowestCeiling
  );

  /// <summary>The floor that a split door (Strife) keeps in its wait field</summary>
  TDoorSplitFloor = (None, Lowest, Highest);

  /// <summary>The kinds of door that a line that is used by hand (no tag) can make</summary>
  TDoorManualKind = (Raising, Opening, BlazeRaising, BlazeOpening);

  /// <summary>What using a line again does to a door that is already working</summary>
  TDoorRetrigger = (Ignore, GoUp, GoDown);

  /// <summary>
  ///   What a door keeps between two tics: the fields of vldoor_t after the sector. OpenSound
  ///   and CloseSound are only Strife's, and are 0 in the other games
  /// </summary>
  TDoorState = record
    Kind: TDoorKind;
    Direction: Integer;
    TopHeight: Integer;
    Speed: Integer;
    TopWait: Integer;
    TopCountdown: Integer;
    OpenSound: Integer;
    CloseSound: Integer;
  end;

  /// <summary>
  ///   How a door of one kind is made: the same list covers the doors of a tag, the ones used
  ///   by hand and the ones that start with the level
  /// </summary>
  TDoorSpawnRules = record
    /// <summary>1 up, -1 down, -2 split, 0 not set</summary>
    Direction: Integer;
    TopMode: TDoorTopMode;
    /// <summary>The speed given is multiplied by this (4 for the blazing doors)</summary>
    SpeedFactor: Integer;
    /// <summary>A speed that replaces the one given; 0 is none</summary>
    SpeedOverride: Integer;
    Sound: TDoorSound;
    /// <summary>The sound is played only if the top is not where the ceiling is</summary>
    SoundOnlyIfMoves: Boolean;
    SplitFloor: TDoorSplitFloor;
    /// <summary>The wait given is in eighths of a second and becomes tics</summary>
    TopWaitInEighths: Boolean;
  end;

  /// <summary>What a door of one kind does in each moment of its life</summary>
  TDoorKindRules = record
    /// <summary>The wait at the top (direction 0) is over</summary>
    WaitEnd: TDoorWaitEnd;
    WaitEndSound: TDoorSound;
    /// <summary>The speed after the wait; 0 keeps the one of the door</summary>
    WaitEndSpeed: Integer;
    /// <summary>The first wait (direction 2) is over: the door opens and takes another kind</summary>
    InitialWaitOpens: Boolean;
    InitialWaitKind: TDoorKind;
    InitialWaitSound: TDoorSound;
    /// <summary>The door reached the floor</summary>
    DownDone: TDoorDownDone;
    DownDoneSound: TDoorSound;
    /// <summary>The sound of the end of the descent is played only in the compatibility mode</summary>
    DownDoneSoundNeedsCompatibility: Boolean;
    /// <summary>Something is under the door</summary>
    Crushed: TDoorCrushed;
    CrushedSound: TDoorSound;
    /// <summary>The door reached the top</summary>
    UpDone: TDoorUpDone;
    UpDoneStopsSound: Boolean;
    Spawn: TDoorSpawnRules;
  end;
  PDoorKindRules = ^TDoorKindRules;

  /// <summary>What one tic of a door asks of the engine</summary>
  TDoorTickOutcome = record
    /// <summary>The door is finished: the engine frees it and clears the sector</summary>
    Removed: Boolean;
    /// <summary>The kind in the state is not the one the door had</summary>
    KindChanged: Boolean;
    /// <summary>The lights of the tag of the line that made the door go off (Doom and Strife)</summary>
    TurnLightsOff: Boolean;
    /// <summary>The lights of the tag of the line that made the door go on (Doom and Strife)</summary>
    TurnLightsOn: Boolean;
  end;

  /// <summary>What the engine gives to a new door: the speed and the wait, and Strife's sounds</summary>
  TDoorSpawnInput = record
    Speed: Integer;
    TopWait: Integer;
    OpenSound: Integer;
    CloseSound: Integer;
  end;

  /// <summary>
  ///   Everything that changes between games and flavors: the rules of each kind, the specials of
  ///   the lines used by hand and the ones that can move a door that is already working. It is
  ///   data, so the doors of the four games are the same code
  /// </summary>
  TDoorProfile = record
    Game: TDoorGame;
    Flavor: TDoorFlavor;
    /// <summary>A door with direction -2 moves its ceiling up and its floor down (Strife)</summary>
    SplitDoors: Boolean;
    /// <summary>A door asks for the lights of its line to be switched (Doom and Strife)</summary>
    LinkLights: Boolean;
    /// <summary>The sound is stopped whenever a door reaches its destination (scripted doors)</summary>
    StopSoundOnPastDest: Boolean;
    Rules: array[TDoorKind] of TDoorKindRules;
    ManualKinds: array[TDoorManualKind] of TDoorKind;
    ManualSounds: array[TDoorManualKind] of TDoorSound;
    ManualSpeedFactors: array[TDoorManualKind] of Integer;
    /// <summary>The line special is cleared after it made a door of this kind</summary>
    ManualConsumesSpecial: array[TDoorManualKind] of Boolean;
    /// <summary>The line specials that make each kind of door</summary>
    ManualSpecials: array[TDoorManualKind] of TArray<Integer>;
    /// <summary>The kind of any other special</summary>
    ManualDefault: TDoorManualKind;
    /// <summary>The specials that close or reopen a door that is already working</summary>
    RetriggerSpecials: TArray<Integer>;
  end;

const
  /// <summary>One in fixed point (16.16)</summary>
  DOOR_FRACUNIT = 65536;
  /// <summary>Tics in a second (TICRATE)</summary>
  DOOR_TICRATE = 35;
  /// <summary>The normal speed of a door (VDOORSPEED)</summary>
  DOOR_SPEED = 2 * DOOR_FRACUNIT;
  /// <summary>The normal wait of a door at the top, in tics (VDOORWAIT)</summary>
  DOOR_WAIT = 150;
  /// <summary>How far under the lowest ceiling around a door its top is</summary>
  DOOR_CEILING_GAP = 4 * DOOR_FRACUNIT;
  /// <summary>The speed of a shop door after its wait (Strife)</summary>
  DOOR_SHOP_SPEED = 2 * DOOR_FRACUNIT;
  /// <summary>The speed of a split door (Strife)</summary>
  DOOR_SPLIT_SPEED = DOOR_FRACUNIT;

implementation

end.
