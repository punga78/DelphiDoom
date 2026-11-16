{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - the types of the moving ceilings             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Ceiling.Types;

{$SCOPEDENUMS ON}

interface

type
  /// <summary>
  ///   The kinds of the classic ceilings of all the games together (ceiling_e of Doom, Heretic
  ///   and Strife); a game never makes the ones it does not have. The engine record keeps its
  ///   own enumeration: the adapter converts, so the order here does not matter for the savegames
  /// </summary>
  TCeilingKind = (
    LowerToFloor,
    RaiseToHighest,
    LowerToLowest,
    LowerToMaxFloor,
    LowerAndCrush,
    CrushAndRaise,
    FastCrushAndRaise,
    SilentCrushAndRaise,
    /// <summary>Boom: generalized ceiling mover</summary>
    GenCeiling,
    /// <summary>Boom: generalized mover that changes the texture</summary>
    GenCeilingChg,
    /// <summary>Boom: generalized mover that changes the texture and zeroes the special</summary>
    GenCeilingChg0,
    /// <summary>Boom: generalized mover that changes the texture and the special</summary>
    GenCeilingChgT,
    /// <summary>Boom: generalized crusher</summary>
    GenCrusher,
    /// <summary>Boom: generalized silent crusher</summary>
    GenSilentCrusher,
    /// <summary>A kind of the scripted ceilings: the classic thinker moves it and does nothing else</summary>
    Other
  );

  TCeilingKinds = set of TCeilingKind;

  /// <summary>The fields of the thinker that the tic of a ceiling reads and writes</summary>
  TCeilingState = record
    /// <summary>1 up, -1 down, 0 in stasis</summary>
    Direction: Integer;
    Speed: Integer;
    /// <summary>The speed of a generalized crusher before an obstacle slowed it (Boom)</summary>
    OldSpeed: Integer;
  end;

  /// <summary>What the game has to do after a step of a ceiling, in the order of the values</summary>
  TCeilingAction = (
    /// <summary>The sound of a ceiling that moves</summary>
    MoveSound,
    /// <summary>The sector takes the special that the ceiling carries (Boom changers)</summary>
    TransferSpecial,
    /// <summary>The sector takes the texture that the ceiling carries (Boom changers)</summary>
    ChangeTexture,
    /// <summary>The sound of a silent crusher that turns back</summary>
    StopSound,
    /// <summary>The ceiling ended: its thinker is removed</summary>
    Remove
  );

  TCeilingActions = set of TCeilingAction;

  /// <summary>A height around the sector that a new ceiling needs</summary>
  TCeilingNeighbor = (
    /// <summary>Nothing to look for</summary>
    None,
    /// <summary>The top is the highest ceiling around</summary>
    TopHighestCeiling,
    /// <summary>The bottom is the lowest ceiling around</summary>
    BottomLowestCeiling,
    /// <summary>The bottom is the highest floor around</summary>
    BottomHighestFloor
  );

  /// <summary>The fields of the thinker that a new ceiling sets</summary>
  TCeilingSpawn = record
    Crush: Boolean;
    TopHeight: Integer;
    BottomHeight: Integer;
    Direction: Integer;
    Speed: Integer;
  end;

  /// <summary>
  ///   The differences between the ceilings of the games (the three old copies of EV_DoCeiling):
  ///   the profile replaces the compiler switches and the copies of the code. The tic is the
  ///   same in every game
  /// </summary>
  TCeilingProfile = record
    /// <summary>How many times the normal speed a fast crusher has (2, Strife 4)</summary>
    FastCrushSpeedFactor: Integer;
    /// <summary>The crushers that go back up crush what they find (not in Strife)</summary>
    CrushAndRaiseCrushes: Boolean;
    /// <summary>
    ///   The ceiling that lowers and crushes does crush and goes down to the floor (Strife);
    ///   elsewhere it stops 8 units above the floor and does not crush
    /// </summary>
    LowerAndCrushReachesFloor: Boolean;
    /// <summary>A line that wakes up a stopped crusher counts as done (not in Heretic)</summary>
    WakeUpCounts: Boolean;
  end;

const
  /// <summary>The normal speed of a ceiling (CEILSPEED, one unit per tic)</summary>
  CEILING_SPEED = 65536;
  /// <summary>How far above the floor a crusher stops (8 units)</summary>
  CEILING_CRUSH_GAP = 8 * 65536;

implementation

end.
