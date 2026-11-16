{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the types of the platforms                   }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Platform.Types;

{$SCOPEDENUMS ON}

interface

type
  /// <summary>The games that have the classic platforms (Hexen has only the scripted ones)</summary>
  TPlatGame = (Doom, Heretic, Strife);

  /// <summary>
  ///   What a platform is doing. The engine record keeps its own enumeration (plat_e): the host
  ///   converts, so the order here does not matter for the savegames
  /// </summary>
  TPlatStatus = (Up, Down, Waiting, InStasis);

  /// <summary>
  ///   The kinds of the classic platforms of all the games together (plattype_e of Doom, Heretic
  ///   and Strife); a game never makes the ones it does not have
  /// </summary>
  TPlatKind = (
    PerpetualRaise,
    DownWaitUpStay,
    /// <summary>Strife: the slow lift</summary>
    SlowDownWaitUpStay,
    RaiseAndChange,
    RaiseToNearestAndChange,
    BlazeDownWaitUpStay,
    /// <summary>Strife: the lift that goes up first</summary>
    UpWaitDownStay,
    GenericLift,
    GenericPerpetual,
    ToggleUpDown
  );

  TPlatKinds = set of TPlatKind;

  /// <summary>The kinds of the scripted platforms (the PLAT_* of udmf_plats)</summary>
  TUdmfPlatKind = (
    PerpetualRaise,
    DownWaitUpStay,
    DownByValueWaitUpStay,
    UpWaitDownStay,
    UpByValueWaitDownStay,
    PerpetualRaiseLip,
    DownWaitUpStayLip,
    UpNearestWaitDownStay
  );

  /// <summary>What the move of a plane did (result_e): the plane is where it must be, it hit something or it passed its destination</summary>
  TPlatMoveResult = (Ok, Crushed, PastDestination);

  /// <summary>The sounds of a platform: the one of a plane that moves in steps, the start and the stop of the movement</summary>
  TPlatSound = (Move, Start, Stop);

  /// <summary>
  ///   What a platform keeps between two tics: the fields of plat_t after the sector (the kind is
  ///   kept apart, so the same record serves the classic and the scripted platforms)
  /// </summary>
  TPlatState = record
    Speed: Integer;
    Low: Integer;
    High: Integer;
    Wait: Integer;
    Count: Integer;
    Status: TPlatStatus;
    OldStatus: TPlatStatus;
    Crush: Boolean;
    Tag: Integer;
  end;

  /// <summary>
  ///   What changes between the games in the classic platforms: it replaces the compiler
  ///   switches and the three copies of the code of p_plats
  /// </summary>
  TPlatProfile = record
    /// <summary>The kinds that play the stone sound every 8 tics while they go up</summary>
    MoveSoundWhileRising: TPlatKinds;
    /// <summary>The kinds that play the stone sound every 8 tics while they go down</summary>
    MoveSoundWhileLowering: TPlatKinds;
    /// <summary>The kinds that are removed when they get to the top</summary>
    RemovedAtTop: TPlatKinds;
    /// <summary>The kinds that are removed when they get to the bottom</summary>
    RemovedAtBottom: TPlatKinds;
    /// <summary>The removal at the bottom happens only in the engine versions after 1.15 (Doom)</summary>
    RemovalAtBottomNeedsModernEngine: Boolean;
    /// <summary>The toggle platform (stops at both ends) exists in the game</summary>
    HasToggle: Boolean;
    /// <summary>
    ///   A toggle that is woken up goes the other way (Doom). In Strife it takes the status it
    ///   had, so it never alternates (a defect of the old code, kept)
    /// </summary>
    ToggleReversesOnWake: Boolean;
    /// <summary>The low position starts as the floor of the sector (Doom and Strife; Heretic leaves it as it was)</summary>
    LowStartsAtFloor: Boolean;
  end;

const
  /// <summary>PLATWAIT: seconds of the wait of a platform</summary>
  PLAT_WAIT_SECONDS = 3;
  /// <summary>PLATSPEED (FRACUNIT)</summary>
  PLAT_SPEED = 65536;
  /// <summary>TICRATE</summary>
  PLAT_TICS_PER_SECOND = 35;
  /// <summary>FRACUNIT</summary>
  PLAT_FRACUNIT = 65536;
  /// <summary>The direction of a plane that goes up, as T_MovePlane wants it</summary>
  PLAT_DIRECTION_UP = 1;
  /// <summary>The direction of a plane that goes down</summary>
  PLAT_DIRECTION_DOWN = -1;

implementation

end.
