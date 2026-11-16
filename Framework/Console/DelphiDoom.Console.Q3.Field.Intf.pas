{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, what the line editing      }
{  needs from the client                                                       }
{                                                                              }
{  Small contracts for the key state, the clipboard, the scrolling of the      }
{  console and the connection state, which the original reads from the rest    }
{  of the client (keys[], Sys_GetClipboardData, Con_PageUp, cls.state).        }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Field.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Field.Types;

type
  /// <summary>keys[key].down</summary>
  IQ3KeyState = interface
    ['{7A1D52B0-6E4C-4F9A-8B13-0C5E92D7A401}']
    function IsDown(AKey: Integer): Boolean;
  end;

  /// <summary>Sys_GetClipboardData</summary>
  IQ3Clipboard = interface
    ['{7A1D52B0-6E4C-4F9A-8B13-0C5E92D7A402}']
    /// <summary>False when there is no text on the clipboard (the original gets NULL)</summary>
    function TryGetText(out AText: AnsiString): Boolean;
  end;

  /// <summary>Con_PageUp, Con_PageDown, Con_Top and Con_Bottom</summary>
  IQ3ConsoleScroller = interface
    ['{7A1D52B0-6E4C-4F9A-8B13-0C5E92D7A403}']
    procedure PageUp;
    procedure PageDown;
    procedure Top;
    procedure Bottom;
  end;

  /// <summary>What the Enter key of the console reads of the client: cls.state and SCR_UpdateScreen</summary>
  IQ3ClientState = interface
    ['{7A1D52B0-6E4C-4F9A-8B13-0C5E92D7A404}']
    /// <summary>cls.state == CA_ACTIVE: in the game, so the line without a slash is a chat message</summary>
    function IsActive: Boolean;
    /// <summary>cls.state == CA_DISCONNECTED: the screen is updated at once after a command</summary>
    function IsDisconnected: Boolean;
    /// <summary>SCR_UpdateScreen</summary>
    procedure UpdateScreen;
  end;

implementation

end.
