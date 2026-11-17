{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - constants, events, shared state           }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp, Common.h,               }
{  EventLoop.h, sys\sys_public.h.                                              }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>MAX_PRINT_MSG_SIZE of Common.cpp</summary>
  D3_MAX_PRINT_MSG_SIZE = 4096;
  /// <summary>MAX_WARNING_LIST of Common.cpp</summary>
  D3_MAX_WARNING_LIST = 256;
  /// <summary>MAX_CONSOLE_LINES of Common.cpp: the lines of the command line (separated by +)</summary>
  D3_MAX_CONSOLE_LINES = 32;
  /// <summary>MAX_PUSHED_EVENTS of EventLoop.h</summary>
  D3_MAX_PUSHED_EVENTS = 64;

  /// <summary>errorParm_t: ERP_NONE</summary>
  ERP_NONE = 0;
  /// <summary>ERP_FATAL: exit the entire game</summary>
  ERP_FATAL = 1;
  /// <summary>ERP_DROP: print to console and disconnect from game</summary>
  ERP_DROP = 2;
  /// <summary>ERP_DISCONNECT: do not kill the server</summary>
  ERP_DISCONNECT = 3;

  /// <summary>The editor flags of com_editors (Common.h)</summary>
  EDITOR_NONE = 0;
  EDITOR_RADIANT = 1 shl 1;
  EDITOR_GUI = 1 shl 2;
  EDITOR_DEBUGGER = 1 shl 3;
  EDITOR_SCRIPT = 1 shl 4;
  EDITOR_LIGHT = 1 shl 5;
  EDITOR_SOUND = 1 shl 6;
  EDITOR_DECL = 1 shl 7;
  EDITOR_AF = 1 shl 8;
  EDITOR_PARTICLE = 1 shl 9;
  EDITOR_PDA = 1 shl 10;
  EDITOR_AAS = 1 shl 11;
  EDITOR_MATERIAL = 1 shl 12;

  /// <summary>sysEventType_t: evTime is still valid</summary>
  SE_NONE = 0;
  /// <summary>evValue is a key code, evValue2 is the down flag</summary>
  SE_KEY = 1;
  /// <summary>evValue is an ascii char</summary>
  SE_CHAR = 2;
  /// <summary>evValue and evValue2 are relative signed x / y moves</summary>
  SE_MOUSE = 3;
  /// <summary>evValue is an axis number and evValue2 is the current state (-127 to 127)</summary>
  SE_JOYSTICK_AXIS = 4;
  /// <summary>evData is a string, from typing something at a non-game console</summary>
  SE_CONSOLE = 5;

  /// <summary>S_COLOR_RED, S_COLOR_YELLOW of Str.h</summary>
  D3_COLOR_RED = '^1';
  D3_COLOR_YELLOW = '^3';

  /// <summary>Bytes of one event in the journal file: sizeof(sysEvent_t) of the 32 bit build</summary>
  D3_JOURNAL_EVENT_SIZE = 20;

type
  /// <summary>idException: what Error raises for a drop (the text of the error)</summary>
  ED3HostException = class(Exception);

  /// <summary>
  ///   sysEvent_t. The C++ pointer and its length (evPtr, evPtrLength) are one byte array: the length is
  ///   the length of the array, the block is freed by the garbage of the language
  /// </summary>
  TD3SysEvent = record
    EvType: Integer;
    EvValue: Integer;
    EvValue2: Integer;
    EvData: TBytes;
    class function Make(AType, AValue, AValue2: Integer): TD3SysEvent; static;
  end;

  /// <summary>
  ///   The state that the parts of idCommonLocal share: com_errorEntered, com_refreshOnPrint, com_editors
  /// </summary>
  TD3CommonState = class
  strict private
    FErrorEntered: Integer;
    FRefreshOnPrint: Boolean;
    FEditors: Integer;
  public
    /// <summary>0, ERP_DROP, ERP_FATAL...</summary>
    property ErrorEntered: Integer read FErrorEntered write FErrorEntered;
    /// <summary>update the screen every print (dmap)</summary>
    property RefreshOnPrint: Boolean read FRefreshOnPrint write FRefreshOnPrint;
    /// <summary>the editors that are open (EDITOR_*)</summary>
    property Editors: Integer read FEditors write FEditors;
  end;

  /// <summary>The cut of a message that idStr::vsnPrintf makes</summary>
  TD3MessageText = class
  public
    /// <summary>
    ///   A message formatted into a buffer of MAX_PRINT_MSG_SIZE bytes: at most 4095 characters; this is
    ///   what Warning, DWarning, DPrintf and Error do with their text
    /// </summary>
    class function Limit(const AText: AnsiString): AnsiString; static;
  end;

implementation

class function TD3SysEvent.Make(AType, AValue, AValue2: Integer): TD3SysEvent;
begin
  Result.EvType := AType;
  Result.EvValue := AValue;
  Result.EvValue2 := AValue2;
  Result.EvData := nil;
end;

class function TD3MessageText.Limit(const AText: AnsiString): AnsiString;
begin
  if Length(AText) > D3_MAX_PRINT_MSG_SIZE - 1 then
    Result := Copy(AText, 1, D3_MAX_PRINT_MSG_SIZE - 1)
  else
    Result := AText;
end;

end.
