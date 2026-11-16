{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - what the drawing reads               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.View;

interface

uses
  DelphiDoom.Hud.TextLine, DelphiDoom.Hud.InputText, DelphiDoom.Hud.ScrollingText;

type
  /// <summary>
  ///   What the drawing of the heads-up display reads, once for every frame: the widgets as the
  ///   model keeps them
  /// </summary>
  IHudView = interface
    ['{B2F8D035-9A47-4C1E-8E63-70D5A1C4F928}']
    function GetMessageWindow: THudScrollingText;
    function GetMessageVisible: Boolean;
    function GetChatLine: THudInputText;
    function GetChatVisible: Boolean;
    function GetTitle: THudTextLine;
    function GetLevelTime: THudTextLine;
    function GetFpsText: string;
    /// <summary>Writes the time of the level in its line (done while the automap is shown)</summary>
    procedure UpdateLevelTime(const ALevelTime: Integer);
    /// <summary>The window of the messages (w_message)</summary>
    property MessageWindow: THudScrollingText read GetMessageWindow;
    /// <summary>A message is on the screen (message_on)</summary>
    property MessageVisible: Boolean read GetMessageVisible;
    /// <summary>The line the player types the chat in (w_chat)</summary>
    property ChatLine: THudInputText read GetChatLine;
    /// <summary>The chat line is open (chat_on)</summary>
    property ChatVisible: Boolean read GetChatVisible;
    /// <summary>The name of the map (w_title)</summary>
    property Title: THudTextLine read GetTitle;
    /// <summary>The time of the level (w_leveltime)</summary>
    property LevelTime: THudTextLine read GetLevelTime;
    /// <summary>"n fps" (m_fps)</summary>
    property FpsText: string read GetFpsText;
  end;

implementation

end.
