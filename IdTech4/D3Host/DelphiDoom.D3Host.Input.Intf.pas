{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - contracts of the input and the console    }
{                                                                              }
{  Port of Doom 3 (id Software): what framework\KeyInput.cpp, EditField.cpp,   }
{  UsercmdGen.cpp and Console.cpp use of the rest of the engine.               }
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
unit DelphiDoom.D3Host.Input.Intf;

interface

uses
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Input.Types;

type
  /// <summary>What the edit field and the console ask of idKeyInput: the state of a key and the overstrike mode</summary>
  ID3KeyStates = interface
    ['{7B2D6E41-95C3-4A08-B1F7-3E40A8C5D612}']
    function IsDown(const AKey: Integer): Boolean;
    function GetOverstrikeMode: Boolean;
    procedure SetOverstrikeMode(const AState: Boolean);
  end;

  /// <summary>idKeyInput::ExecKeyBinding: the console sends the F keys to their bindings</summary>
  ID3KeyBindingExecutor = interface
    ['{0E5A93C7-2F81-4D64-A6B0-C97D18E4F325}']
    /// <summary>False if the key belongs to the async usercmd generation (nothing is added to the buffer)</summary>
    function ExecKeyBinding(const AKey: Integer): Boolean;
  end;

  /// <summary>idKeyInput::GetUsercmdAction: the button of a binding, for the usercmd generator</summary>
  ID3UsercmdActions = interface
    ['{A41C8F25-6D07-4B39-92E8-5F03B7D1A648}']
    function GetUsercmdAction(const AKey: Integer): Integer;
  end;

  /// <summary>What idKeyInput asks of the usercmd generator (usercmdGen->Clear, CommandStringUsercmdData)</summary>
  ID3UsercmdControl = interface
    ['{D93F0B6A-18E2-4C57-8A4D-6B25E7C01F93}']
    procedure Clear;
    function CommandStringUsercmdData(const ACommand: AnsiString): Integer;
  end;

  /// <summary>The language dictionary and the key map of the system, for the localized names of the keys</summary>
  ID3KeyText = interface
    ['{5C07E2B8-4A93-4F16-B0D5-82A1F3E96C74}']
    /// <summary>Sys_MapCharForKey</summary>
    function MapCharForKey(const AKey: Integer): AnsiChar;
    /// <summary>common->GetLanguageDict()->GetString</summary>
    function LanguageString(const AId: AnsiString): AnsiString;
  end;

  /// <summary>The cvar system as the keys and the console use it: completion, the modified flags, the values to set</summary>
  ID3CVarServices = interface
    ['{E6B1A790-3D25-4C48-97F2-0A8C5D41B3E6}']
    procedure CommandCompletion(const ACallback: TCmdCompletionCallback);
    procedure ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
    procedure SetModifiedFlags(const AFlags: Integer);
    function GetModifiedFlags: Integer;
    procedure ClearModifiedFlags(const AFlags: Integer);
    procedure SetCVarInteger(const AName: AnsiString; const AValue: Integer);
    function GetCVarString(const AName: AnsiString): AnsiString;
  end;

  /// <summary>The values of the cvars that the usercmd generator reads (names in D3_USERCMD_CVARS)</summary>
  ID3CVarValues = interface
    ['{3A9D5C62-F4B1-4E70-8C37-D1062E7B9A85}']
    function GetFloat(const AName: AnsiString): Single;
    function GetInteger(const AName: AnsiString): Integer;
    function GetBool(const AName: AnsiString): Boolean;
  end;

  /// <summary>Sys_GetClipboardData</summary>
  ID3Clipboard = interface
    ['{81F4C0D3-7E56-4A29-B3A8-4D95E02C6F17}']
    /// <summary>False if the clipboard has no text</summary>
    function GetClipboardData(out AText: AnsiString): Boolean;
  end;

  /// <summary>The system queues of the keyboard and the mouse that the usercmd generator reads (Sys_Poll*InputEvents)</summary>
  ID3InputDevices = interface
    ['{C5128E9B-06D3-4F7A-A1E4-7B3F90D82C56}']
    function PollKeyboardEvents: Integer;
    function ReturnKeyboardEvent(const AIndex: Integer; out AKey: Integer; out AState: Boolean): Boolean;
    procedure EndKeyboardEvents;
    function PollMouseEvents: Integer;
    function ReturnMouseEvent(const AIndex: Integer; out AAction: Integer; out AValue: Integer): Boolean;
    procedure EndMouseEvents;
  end;

  /// <summary>idAsyncNetwork::IsActive</summary>
  ID3AsyncState = interface
    ['{F70A3D58-B2E1-4C96-8D4F-1A6E05C93B72}']
    function IsActive: Boolean;
  end;

  /// <summary>Sys_DebugPrintf</summary>
  ID3DebugOutput = interface
    ['{2B8E6F14-93D7-4A50-A5C1-E40D7F83B296}']
    procedure DebugPrintf(const AText: AnsiString);
  end;

  /// <summary>idUsercmdGen as the rest of the engine uses it</summary>
  ID3UsercmdGenerator = interface
    ['{9D4C71A6-0B58-4E23-B6F9-52A8C3E1D704}']
    procedure Init;
    procedure InitForNewMap;
    procedure Shutdown;
    procedure Clear;
    procedure ClearAngles;
    procedure InhibitUsercmd(const ASubsystem: Integer; const AInhibit: Boolean);
    function TicCmd(const ATicNumber: Integer): TD3Usercmd;
    procedure UsercmdInterrupt;
    function CommandStringUsercmdData(const ACommand: AnsiString): Integer;
    function GetNumUserCommands: Integer;
    function GetUserCommandName(const AIndex: Integer): AnsiString;
    procedure MouseState(out AX, AY, AButton: Integer; out ADown: Boolean);
    function ButtonState(const AKey: Integer): Integer;
    function KeyState(const AKey: Integer): Integer;
    function GetDirectUsercmd: TD3Usercmd;
  end;

  /// <summary>The system calls that the console makes: the key that opens it and the grab of the mouse</summary>
  ID3ConsolePlatform = interface
    ['{64E0B93D-C7A2-4158-9F36-8D1B5A70E4C2}']
    /// <summary>Sys_GetConsoleKey</summary>
    function GetConsoleKey(const AShifted: Boolean): Integer;
    /// <summary>Sys_GrabMouseCursor</summary>
    procedure GrabMouseCursor(const AGrab: Boolean);
  end;

  /// <summary>eventLoop->Milliseconds, which the console uses for the repeat of the scroll keys</summary>
  ID3EventClock = interface
    ['{1A7C95E0-48B3-4D62-8E06-F2D3B8091A47}']
    function EventMilliseconds: Integer;
  end;

  /// <summary>The part of the session that the console calls: UpdateScreen after a command line</summary>
  ID3ScreenUpdater = interface
    ['{B20F6D84-5E19-4C37-A9D0-7C41E3A8B5F6}']
    procedure UpdateScreen(const AOutOfSequence: Boolean);
  end;

implementation

end.
