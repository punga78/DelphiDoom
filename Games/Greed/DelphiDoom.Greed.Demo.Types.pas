{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the recorded games: what a tape holds            }
{  xGreed (and the DOS game) only keep the remains of a recorder: "record"      }
{  clears a buffer of RECBUFSIZE bytes that nothing fills and writes it to      }
{  "demo1", "playback" loads that file and nothing reads it (InitData,          }
{  SaveDemo and maingame of raven.pas). The format of this tape is new          }
{                                                                              }
{  xGreed (Jim Valavanis) and Raven 3D engine (c) 1996 Softdisk Publishing:    }
{  the user declares this port GPL v2 or later; the right on the parts         }
{  derived from the Softdisk code is not verified (docs\LICENZE.md)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Demo.Types;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.PlayerControl.Intf;

const
  /// <summary>The first four bytes of a tape: "GRDM"</summary>
  GREED_DEMO_MAGIC: array[0..3] of Byte = (Ord('G'), Ord('R'), Ord('D'), Ord('M'));
  GREED_DEMO_VERSION = 1;
  /// <summary>The bytes of the header: the magic, the version and sixteen numbers of 32 bits</summary>
  GREED_DEMO_HEADER_BYTES = 4 + 4 + 16 * 4;
  /// <summary>RECBUFSIZE of protos_h.pas: the size of the buffer that the original writes to "demo1"</summary>
  GREED_DEMO_ORIGINAL_BYTES = 16000;
  /// <summary>The name of the file of the original</summary>
  GREED_DEMO_ORIGINAL_NAME = 'demo1';

  SGreedDemoBadMagic = 'the file is not a recorded game of Greed32 (it does not start with GRDM)';
  SGreedDemoBadVersion = 'recorded game of version %d: this program reads the version %d';
  SGreedDemoTruncated = 'the recorded game ends in the middle of a record (byte %d)';
  SGreedDemoBadRecord = 'unknown record %d in the recorded game (byte %d)';
  SGreedDemoTooManyTics = 'a picture after %d tics cannot be recorded (0..255)';
  SGreedDemoTooManyTyped = '%d characters typed in one reading cannot be recorded (0..255)';

type
  EGreedDemoException = class(EGreedDataException);

  /// <summary>
  ///   What a tape is made of, in the order in which the game asked: a reading of the controls
  ///   (INT_ReadControls), the tics before a turn of the loop of the game, a reading of the clock of the system.
  ///   gdrEnd closes the tape
  /// </summary>
  TGreedDemoRecordKind = (gdrEnd, gdrReading, gdrFrame, gdrClock);

  TGreedCommands = set of TGreedCommand;
  TGreedMouseButtons = set of TGreedMouseButton;

  /// <summary>
  ///   How the game of a tape starts: what newplayer is given, the edition, and the settings that change what the
  ///   game does and not only what it shows
  /// </summary>
  TGreedDemoHeader = record
    Map: Integer;
    Character: Integer;
    Difficulty: Integer;
    /// <summary>1..3: GAME1, GAME2, GAME3</summary>
    Episode: Integer;
    /// <summary>The data are the ones of the demo (it ends after the map 2)</summary>
    DemoEdition: Boolean;
    /// <summary>lowresolution: the look up and down has half the range</summary>
    LowResolution: Boolean;
    /// <summary>rndofs when the game starts</summary>
    RandomOffset: Integer;
    /// <summary>SC.camdelay: the rear view camera runs the level while it draws</summary>
    CameraDelay: Integer;
    /// <summary>SC.screensize (0..4): with the status bar an item of the inventory is chosen by drawing it</summary>
    ViewSize: Integer;
    /// <summary>SC.violence: blood and corpses are sprites, and their making takes random numbers</summary>
    Violence: Boolean;
    /// <summary>
    ///   SC.mouse with a mouse installed, SC.mousesensitivity, mousesensitivityx, mousesensitivityy, invertmouseturn
    ///   and invertmouselook: how ControlMovement turns the movement of the mouse of a reading into a movement of
    ///   the player
    /// </summary>
    MouseEnabled: Boolean;
    MouseSensitivity: Integer;
    MouseSensitivityX: Integer;
    MouseSensitivityY: Integer;
    InvertMouseTurn: Boolean;
    InvertMouseLook: Boolean;
  end;

  /// <summary>One reading of the controls: what was down, what was typed, the mouse</summary>
  TGreedDemoReading = record
    Commands: TGreedCommands;
    MouseButtons: TGreedMouseButtons;
    MouseDeltaX: Integer;
    MouseDeltaY: Integer;
    /// <summary>The characters typed since the reading before (codes 0..255)</summary>
    Typed: string;
  end;

  /// <summary>A record of a tape; only the fields of its kind mean something</summary>
  TGreedDemoRecord = record
    Kind: TGreedDemoRecordKind;
    Reading: TGreedDemoReading;
    /// <summary>gdrFrame: the tics played before the turn of the loop (0..255)</summary>
    Tics: Integer;
    /// <summary>gdrClock: what the clock of the system answered</summary>
    Clock: Cardinal;
  end;

implementation

end.
