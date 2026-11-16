{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the types of the game                             }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  kd_def.h                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GameTypes;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types;

const
  /// <summary>Objects that can be in the game at the same time (MAXACTORS = MAXSPRITES)</summary>
  KEEN_MAXACTORS = KEEN_MAXSPRITES;
  /// <summary>Gravity added at each odd tic (ACCGRAVITY) and the fastest fall (SPDMAXY)</summary>
  KEEN_ACCGRAVITY = 3;
  KEEN_SPDMAXY = 80;
  /// <summary>Levels of the game, without the title page (GAMELEVELS); the slot 0 is the world map</summary>
  KEEN_GAMELEVELS = 17;
  /// <summary>Tiles away from the view where an actor goes to sleep (INACTIVATEDIST)</summary>
  KEEN_INACTIVATEDIST = 10;
  /// <summary>The most that an actor moves in one frame (MAXMOVE): a tile less 17</summary>
  KEEN_MAXMOVE = KEEN_TILEGLOBAL - 17;
  /// <summary>Speed with which an actor is pushed out of a wall (CLIPMOVE)</summary>
  KEEN_CLIPMOVE = 24;
  /// <summary>Where the view starts to scroll when Keen goes toward an edge (SCROLLEAST...)</summary>
  KEEN_SCROLLEAST = KEEN_TILEGLOBAL * 11;
  KEEN_SCROLLWEST = KEEN_TILEGLOBAL * 9;
  KEEN_SCROLLSOUTH = KEEN_TILEGLOBAL * 8;
  KEEN_SCROLLNORTH = KEEN_TILEGLOBAL * 4;
  /// <summary>The map of the title page, that has no actors</summary>
  KEEN_TITLE_MAP = 20;
  /// <summary>A pixel in global units (PIXGLOBAL) and the size of a block (BLOCKSIZE) that places the starting actors</summary>
  KEEN_PIXGLOBAL = 16;
  KEEN_BLOCKSIZE = 8 * KEEN_PIXGLOBAL;
  /// <summary>The slot of dummyobj in the list of the actors: the place that takes what does not fit</summary>
  KEEN_DUMMY_SLOT = KEEN_MAXACTORS;

type
  /// <summary>exittype: how a level ends</summary>
  TKeenExit = (keNotDone, keResetGame, keLevelComplete, keWarpToLevel, keDied, keVictorious);

  /// <summary>classtype: what an actor is (0 = nothing: a contact function sets it to remove the actor)</summary>
  TKeenClass = (kcNothing, kcKeen, kcPower, kcDoor, kcBonus, kcBrocco, kcTomat, kcCarrot, kcCelery, kcAspar,
    kcGrape, kcTater, kcCart, kcFrenchy, kcMelon, kcTurnip, kcCauli, kcBrussel, kcMushroom, kcSquash, kcApel,
    kcPeaPod, kcPeaBrain, kcBoobus, kcShot, kcInert);

  /// <summary>
  ///   active of objtype: no = asleep (far from the view); yes = it thinks; allways = never goes to sleep;
  ///   removable = it is removed instead of going to sleep
  /// </summary>
  TKeenActive = (kaNo, kaYes, kaAllways, kaRemovable);

  /// <summary>SDMode: what plays the sound effects. Off, the PC speaker and the AdLib; the digitized sounds (Sound Blaster, Sound Source) are not ported: the shareware has no data for them</summary>
  TKeenSoundMode = (ksmOff, ksmPC, ksmAdLib);

  /// <summary>gametype: what a saved game keeps of the game</summary>
  /// <summary>What an audio mixer has done: services of the sound manager, frames, frames that are not silence, the loudest sample</summary>
  TKeenAudioStatistics = record
    Services: Int64;
    Frames: Int64;
    AudibleFrames: Int64;
    Peak: Integer;
  end;

  TKeenGameState = record
    WorldX: Word;
    WorldY: Word;
    LevelDone: array[0..KEEN_GAMELEVELS - 1] of Boolean;
    Score: Integer;
    NextExtra: Integer;
    FlowerPowers: SmallInt;
    BoobusBombs: SmallInt;
    BombsThisLevel: SmallInt;
    Keys: SmallInt;
    MapOn: SmallInt;
    Lives: SmallInt;
    Difficulty: SmallInt;
  end;

  PKeenGameState = ^TKeenGameState;

  PKeenObject = ^TKeenObject;

  /// <summary>
  ///   An actor (objtype). int and unsigned are 16 bit like in the C, so the coordinates wrap and the speeds
  ///   keep the sign. The links are slots of the array of the objects (-1 = none); Slot is the place of
  ///   the actor in it. The pointer to the shape of the refresh manager is a handle
  /// </summary>
  TKeenObject = record
    Slot: SmallInt;
    ObClass: TKeenClass;
    Active: TKeenActive;
    NeedToReact: Boolean;
    NeedToClip: Boolean;
    NoThink: Word;
    X: Word;
    Y: Word;
    XDir: SmallInt;
    YDir: SmallInt;
    XMove: SmallInt;
    YMove: SmallInt;
    XSpeed: SmallInt;
    YSpeed: SmallInt;
    TicCount: SmallInt;
    TicAdjust: SmallInt;
    /// <summary>The index in the table of the states; -1 is no state (the actor has removed itself)</summary>
    State: SmallInt;
    ShapeNum: Word;
    Left: Word;
    Top: Word;
    Right: Word;
    Bottom: Word;
    MidX: Word;
    TileLeft: Word;
    TileTop: Word;
    TileRight: Word;
    TileBottom: Word;
    TileMidX: Word;
    HitNorth: SmallInt;
    HitEast: SmallInt;
    HitSouth: SmallInt;
    HitWest: SmallInt;
    Temp1: SmallInt;
    Temp2: SmallInt;
    Temp3: SmallInt;
    Temp4: SmallInt;
    Sprite: TKeenSpriteHandle;
    Next: SmallInt;
    Prev: SmallInt;
  end;

implementation

end.
