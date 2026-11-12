{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the types of the user interface, of the           }
{  configuration file and of the saved games                                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  id_us.c, id_us.h and kd_def.h. The records of the files are the ones of the   }
{  16 bit program (int is 2 bytes, structures packed to the byte)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.UserTypes;

interface

uses
  System.SysUtils, DelphiDoom.Keen.GameTypes;

const
  KEEN_MAX_X = 320;
  KEEN_MAX_Y = 200;
  /// <summary>MaxString of id_us.c: the longest line that US_LineInput takes, with its end</summary>
  KEEN_MAX_STRING = 128;
  KEEN_MAX_HIGH_NAME = 57;
  KEEN_MAX_SCORES = 10;
  KEEN_MAX_GAME_NAME = 32;
  KEEN_MAX_SAVE_GAMES = 7;
  KEEN_MAX_HELP_LINES = 500;
  /// <summary>EXTENSION of id_heads.h: the signature of a saved game and the extension of its file</summary>
  KEEN_EXTENSION = 'KDR';
  KEEN_CONFIG_NAME = 'KDREAMS.CFG';
  /// <summary>RLETAG of kd_def.h: the tag of the RLEW planes of a saved game</summary>
  KEEN_SAVE_RLEW_TAG = $ABCD;
  /// <summary>A pointer of the C that is nil in a record of a saved game</summary>
  KEEN_SAVE_NIL = 0;

type
  /// <summary>Point and Rect of id_heads.h</summary>
  TKeenPoint = record
    X: Integer;
    Y: Integer;
  end;

  TKeenRect = record
    UL: TKeenPoint;
    LR: TKeenPoint;
    class function Make(ALeft, ATop, ARight, ABottom: Integer): TKeenRect; static;
  end;

  /// <summary>WindowRec: the window of the user manager and where it prints</summary>
  TKeenWindowRec = record
    X: Integer;
    Y: Integer;
    W: Integer;
    H: Integer;
    PX: Integer;
    PY: Integer;
  end;

  /// <summary>GameDiff: what the control panel asks the game to start</summary>
  TKeenGameDiff = (kgdContinue, kgdEasy, kgdNormal, kgdHard);

  /// <summary>The 16 palette registers of the EGA: the color number (0..63) that each color of a pixel shows</summary>
  TKeenPaletteRegisters = array[0..15] of Byte;

  /// <summary>HighScore of id_us.c, as it is in KDREAMS.CFG (64 bytes)</summary>
  TKeenHighScoreRecord = packed record
    Name: array[0..KEEN_MAX_HIGH_NAME] of AnsiChar;
    Score: Integer;
    Completed: Word;
  end;

  /// <summary>A line of the table of the scores</summary>
  TKeenHighScore = record
    Name: AnsiString;
    Score: Integer;
    Completed: Word;
  end;

  /// <summary>KeyboardDef of id_in.h as it is in KDREAMS.CFG: ten scan codes</summary>
  TKeenKeyboardRecord = packed record
    Button0: Byte;
    Button1: Byte;
    UpLeft: Byte;
    Up: Byte;
    UpRight: Byte;
    Left: Byte;
    Right: Byte;
    DownLeft: Byte;
    Down: Byte;
    DownRight: Byte;
  end;

  /// <summary>
  ///   KDREAMS.CFG (USL_WriteConfig): the scores, the sound mode (SDMode), the music mode (SMMode), the control
  ///   of the first player (ControlType) and its keys; 656 bytes
  /// </summary>
  TKeenConfigRecord = packed record
    Scores: array[0..KEEN_MAX_SCORES - 1] of TKeenHighScoreRecord;
    SoundMode: Word;
    MusicMode: Word;
    Control: Word;
    Keyboard: TKeenKeyboardRecord;
  end;

  /// <summary>SaveGame of id_us.c: the header of SAVEGMn.KDR (39 bytes)</summary>
  TKeenSaveHeader = packed record
    Signature: array[0..3] of AnsiChar;
    Present: Word;
    Name: array[0..KEEN_MAX_GAME_NAME] of AnsiChar;
  end;

  /// <summary>gametype of kd_def.h as SaveGame writes it (60 bytes)</summary>
  TKeenSaveGameState = packed record
    WorldX: Word;
    WorldY: Word;
    LevelDone: array[0..KEEN_GAMELEVELS - 1] of Word;
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

  /// <summary>
  ///   objtype of kd_def.h as SaveGame writes it (76 bytes). The four fields that are near pointers in the C are
  ///   words here too: State is the number of the state plus 1 (0 is nil), Sprite is 0, Next is 1 while
  ///   another actor follows, Prev is 0
  /// </summary>
  TKeenSaveObject = packed record
    ObClass: Word;
    Active: Word;
    NeedToReact: Word;
    NeedToClip: Word;
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
    State: Word;
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
    Sprite: Word;
    Next: Word;
    Prev: Word;
  end;

  /// <summary>A saved game of the list of the control panel</summary>
  TKeenSaveSlot = record
    Present: Boolean;
    Name: AnsiString;
  end;

implementation

{ TKeenRect }

class function TKeenRect.Make(ALeft, ATop, ARight, ABottom: Integer): TKeenRect;
begin
  Result.UL.X := ALeft;
  Result.UL.Y := ATop;
  Result.LR.X := ARight;
  Result.LR.Y := ABottom;
end;

end.
