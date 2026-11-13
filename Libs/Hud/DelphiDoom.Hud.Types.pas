{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - shared types and constants           }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Lines a scrolling text window can hold (the old HU_MAXLINES)</summary>
  HUD_MAX_LINES = 4;
  /// <summary>Rows of text (separated by line feeds) that fit in one text line (HU_MAXLINELINESS)</summary>
  HUD_MAX_LINE_ROWS = 4;
  /// <summary>Characters a text line can hold (HU_MAXLINELENGTH)</summary>
  HUD_MAX_LINE_LENGTH = HUD_MAX_LINE_ROWS * 80;
  /// <summary>Erase passes a changed line goes through (the old needsupdate = 4)</summary>
  HUD_UPDATE_PASSES = 4;
  /// <summary>Characters the chat queue holds before a new one is refused (QUEUESIZE)</summary>
  HUD_CHAT_QUEUE_SIZE = 128;
  /// <summary>Entries of the shift table of the keyboard</summary>
  HUD_SHIFT_TABLE_SIZE = 128;
  /// <summary>Most players a game can have (Hexen and Strife have 8)</summary>
  HUD_MAX_PLAYERS = 8;
  /// <summary>Entries of the width table of a font (a glyph for every byte)</summary>
  HUD_MAX_GLYPHS = 256;
  /// <summary>Fixed point unit of the times the engine gives to the frame counter</summary>
  HUD_FRACUNIT = 65536;
  /// <summary>Messages of the player that tell "you talk to yourself", from the mildest</summary>
  HUD_TALK_TO_SELF_LEVELS = 5;

type
  /// <summary>Raised when the library is used against its contract (wrong size, missing service)</summary>
  EHudException = class(Exception);

  /// <summary>Codes of the keys the heads-up display reacts to (the old KEY_* constants)</summary>
  THudKeys = record
    Enter: Integer;
    Escape: Integer;
    Backspace: Integer;
    RightShift: Integer;
    RightAlt: Integer;
    LeftAlt: Integer;
  end;

  /// <summary>
  ///   What changes from a game to another (a profile, not an IFDEF): the old HU_* constants of
  ///   hu_stuff.pas
  /// </summary>
  THudRules = record
    /// <summary>Tics a message stays on screen (HU_MSGTIMEOUT)</summary>
    MessageTimeout: Integer;
    /// <summary>Tics in a second (TICRATE): the frame counter divides by it</summary>
    TicRate: Integer;
    /// <summary>Entries of the long history of frame times (512, Hexen 128)</summary>
    FpsLongHistory: Integer;
    /// <summary>Destination code "everybody" (HU_BROADCAST)</summary>
    Broadcast: Integer;
    /// <summary>Highest code that is a destination and not a character (HU_BROADCAST, Strife HU_CHANGENAME)</summary>
    LastDestination: Integer;
    /// <summary>Key that shows the last message again (HU_MSGREFRESH)</summary>
    MessageRefreshKey: Integer;
    /// <summary>Key that opens the chat line (HU_INPUTTOGGLE)</summary>
    InputToggleKey: Integer;
    /// <summary>Players of the game (MAXPLAYERS)</summary>
    MaxPlayers: Integer;
    /// <summary>Codes of the keys</summary>
    Keys: THudKeys;
  end;

  /// <summary>Where the widgets are put when a level starts (what HU_Start computes)</summary>
  THudStartParams = record
    MessageX: Integer;
    MessageY: Integer;
    /// <summary>Lines of the message window (HU_MSGHEIGHT)</summary>
    MessageHeight: Integer;
    /// <summary>Height of a line of the small font plus one</summary>
    LineHeight: Integer;
    /// <summary>First character of the font (HU_FONTSTART)</summary>
    StartChar: Integer;
    TitleX: Integer;
    TitleY: Integer;
    LevelTimeX: Integer;
    LevelTimeY: Integer;
    InputX: Integer;
    InputY: Integer;
    /// <summary>Name of the map, written in the title line</summary>
    Title: string;
  end;

  /// <summary>The characters the keyboard writes when shift is down (index = key code)</summary>
  THudShiftTable = array[0..HUD_SHIFT_TABLE_SIZE - 1] of Char;

  /// <summary>Widths of the glyphs of a font, indexed from its first character</summary>
  THudFontWidths = record
    /// <summary>Glyphs that exist</summary>
    Count: Integer;
    Width: array[0..HUD_MAX_GLYPHS - 1] of Integer;
  end;

  /// <summary>A glyph to draw: its index in the font and its place on the 320x200 screen</summary>
  THudGlyph = record
    Index: Integer;
    X: Integer;
    Y: Integer;
    /// <summary>The digit is written with the highlight translation (only the text of the statistics)</summary>
    Highlighted: Boolean;
  end;

  /// <summary>What the player is aiming at, for the crosshair</summary>
  THudCrosshairTarget = (
    /// <summary>Nothing</summary>
    None,
    /// <summary>An ally, a friend: the plain crosshair</summary>
    Friend,
    /// <summary>An enemy: the crosshair that spins</summary>
    Enemy
  );

implementation

end.
