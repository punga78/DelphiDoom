{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - shared types and exceptions                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Raised for a wrong option, a wrong layout or a log that cannot be written</summary>
  EParityException = class(Exception);

  /// <summary>
  ///   What the command line asked for. Every field is off (empty, -1 or False) unless the option was
  ///   given: with no option the parity tools do nothing
  /// </summary>
  TParityOptions = record
    /// <summary>-statehash file: one line of hashes of the game state for every tic</summary>
    StateHashFile: string;
    /// <summary>-statehash-detail first last: the value of every field for the tics of the range</summary>
    StateDetail: Boolean;
    StateDetailFirstTic: Integer;
    StateDetailLastTic: Integer;
    /// <summary>-framehash file: one line of hashes of the screen for every frame</summary>
    FrameHashFile: string;
    /// <summary>-framedump tic file: the frame of that tic as a BMP file (-1 when not asked)</summary>
    FrameDumpTic: Integer;
    FrameDumpFile: string;
    /// <summary>-autodemo seed tics: the automatic pilot plays the first player</summary>
    AutoDemo: Boolean;
    AutoDemoSeed: Cardinal;
    AutoDemoTics: Integer;
    /// <summary>-autosave tic slot: the game is saved in that slot after that tic (issue #40: the saved games)</summary>
    AutoSave: Boolean;
    AutoSaveTic: Integer;
    AutoSaveSlot: Integer;
    /// <summary>-savelayouts file: the layouts on disk of the records of the saved games, as text</summary>
    SaveLayoutsFile: string;
    /// <summary>-autoquit tic: the program ends after that tic (-1 when not asked); for a run with no pilot</summary>
    AutoQuitTic: Integer;
    /// <summary>-autoscript file: a script of commands plays the first player (empty when not asked)</summary>
    AutoScriptFile: string;
    /// <summary>True when at least one option was given</summary>
    function IsActive: Boolean;
  end;

  /// <summary>One command of the automatic pilot, independent of the layout of the ticcmd of a game</summary>
  TParityPilotCommand = record
    /// <summary>Forward (positive) or backward move, in the units of the ticcmd (up to 50)</summary>
    Forward: Integer;
    /// <summary>Right (positive) or left strafe, in the units of the ticcmd (up to 40)</summary>
    Side: Integer;
    /// <summary>Turn to the left (positive) or right, in the units of the angle of the ticcmd (65536 = a full turn)</summary>
    Turn: Integer;
    Fire: Boolean;
    Use: Boolean;
    /// <summary>Number of the weapon to take (1 and up), 0 to keep the one in hand</summary>
    Weapon: Integer;
    /// <summary>Look up (positive) or down, in steps of the look of the ticcmd (-7..7); 0 keeps the pitch</summary>
    Look: Integer;
    /// <summary>Brings the look back to the horizon (wins over Look)</summary>
    LookCenter: Boolean;
    /// <summary>The jump key (a craft that flies goes up)</summary>
    Jump: Boolean;
    /// <summary>The crouch key (a craft that flies goes down)</summary>
    Crouch: Boolean;
    /// <summary>The first key that only one game has (Radix: the afterburner); nothing for the other games</summary>
    Afterburner: Boolean;
    /// <summary>The second key that only one game has (Radix: the plasma bomb, once for every press)</summary>
    Bomb: Boolean;
    /// <summary>The game is saved in the slot Slot (a script only; it does nothing while a demo is recorded)</summary>
    Save: Boolean;
    /// <summary>The saved game of the slot Slot is loaded (a script only)</summary>
    Load: Boolean;
    /// <summary>The slot of Save and Load, from 0</summary>
    Slot: Integer;
    /// <summary>
    ///   A key of the engine (its own code: 27 escape, 13 enter, 173 up, 175 down...) that goes down and up
    ///   as an event, for the menus (a script only); 0 = none
    /// </summary>
    Key: Integer;
    /// <summary>The frame that follows is written beside the script as picture number Shot (a script only); 0 = none</summary>
    Shot: Integer;
  end;

  /// <summary>What the pilot may know about the world: the player and nothing else</summary>
  TParityPilotView = record
    /// <summary>The tic of the game that is being built</summary>
    Tic: Integer;
    Alive: Boolean;
    /// <summary>Position of the player (fixed point 16.16)</summary>
    X: Integer;
    Y: Integer;
    Z: Integer;
    /// <summary>Where the player looks: a binary angle (2^32 = a full turn, 0 = east, counterclockwise)</summary>
    Angle: Cardinal;
    /// <summary>How fast the player moves, in map units for each tic (fixed point 16.16): a car drives to a speed</summary>
    Speed: Integer;
    /// <summary>The health of the player (in Radix: the shield)</summary>
    Health: Integer;
    /// <summary>
    ///   True when a living enemy that the player can see is within the range that the pilot asked for;
    ///   EnemyX, EnemyY and EnemyZ are the place of the nearest one (fixed point 16.16)
    /// </summary>
    HasEnemy: Boolean;
    EnemyX: Integer;
    EnemyY: Integer;
    EnemyZ: Integer;
  end;

  /// <summary>What a step of a script of commands does</summary>
  TParityScriptStepKind = (
    /// <summary>Keeps the same keys pressed for some tics</summary>
    skHold,
    /// <summary>Turns to a point of the map and goes there</summary>
    skGoto,
    /// <summary>Turns to a point of the map without moving</summary>
    skFace,
    /// <summary>Flies up or down to a height</summary>
    skClimb,
    /// <summary>Turns to the nearest enemy and fires at it, until none is left near or the tics are over</summary>
    skHunt,
    /// <summary>Waits (fighting the enemies that come near) until the health is back, or the tics are over</summary>
    skHeal,
    /// <summary>Saves the game in a slot (one tic)</summary>
    skSave,
    /// <summary>Loads the saved game of a slot (one tic)</summary>
    skLoad);

  /// <summary>One step of a script of commands (-autoscript); the coordinates are map units</summary>
  TParityScriptStep = record
    Kind: TParityScriptStepKind;
    /// <summary>1-based line of the script, for the messages</summary>
    Line: Integer;
    /// <summary>
    ///   skHold: how long the step lasts; skHunt, skHeal: how long it lasts at most; the others: after how
    ///   many tics the script gives up
    /// </summary>
    Tics: Integer;
    /// <summary>
    ///   skGoto: on the way the pilot stops to fight the enemies that are near; skHunt, skHeal: always True
    /// </summary>
    Fight: Boolean;
    /// <summary>skGoto with Fight, skHunt, skHeal: how near an enemy is fought (map units)</summary>
    EnemyRange: Integer;
    /// <summary>skHeal: the health to wait for</summary>
    Health: Integer;
    /// <summary>
    ///   skHold: the keys pressed; skGoto: Forward is the speed, Fire and Use are pressed on the way;
    ///   skFace: Fire is pressed while turning
    /// </summary>
    Command: TParityPilotCommand;
    X: Integer;
    Y: Integer;
    /// <summary>skGoto: the height to reach on the way (when HasZ); skClimb: the height to reach</summary>
    Z: Integer;
    HasZ: Boolean;
    /// <summary>skGoto: keep the throttle on while turning (a car cannot turn on the spot)</summary>
    Drive: Boolean;
    /// <summary>skGoto: how near the point is "there"</summary>
    Radius: Integer;
  end;

  /// <summary>Where the 3D view is inside a frame (all the numbers are pixels)</summary>
  TParityFrameLayout = record
    Width: Integer;
    Height: Integer;
    ViewX: Integer;
    ViewY: Integer;
    ViewWidth: Integer;
    ViewHeight: Integer;
  end;

  /// <summary>The first line where two logs differ</summary>
  TParityDifference = record
    Found: Boolean;
    /// <summary>1-based number of the line in the logs (comments are counted)</summary>
    LineNumber: Integer;
    /// <summary>The tic of the line (-1 if the line has none)</summary>
    Tic: Integer;
    Expected: string;
    Actual: string;
    /// <summary>The names of the hashes or fields that differ, separated by a comma</summary>
    Differing: string;
    /// <summary>One line that tells it all, in plain words</summary>
    function Describe: string;
  end;

implementation

{ TParityOptions }

function TParityOptions.IsActive: Boolean;
begin
  Result := (StateHashFile <> '') or (FrameHashFile <> '') or (FrameDumpTic >= 0) or AutoDemo or AutoSave or
    (SaveLayoutsFile <> '') or (AutoQuitTic >= 0) or (AutoScriptFile <> '');
end;

{ TParityDifference }

function TParityDifference.Describe: string;
begin
  if not Found then
    Exit('EQUAL');
  Result := Format('DIFFERENT at line %d (tic %d): %s | expected: %s | actual: %s',
    [LineNumber, Tic, Differing, Expected, Actual]);
end;

end.
