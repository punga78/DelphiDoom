{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - contracts                                 }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp, EventLoop.cpp (what     }
{  they use of the cvar system, the system, the session, the file system).     }
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
unit DelphiDoom.D3Host.Intf;

interface

uses
  System.SysUtils, DelphiDoom.D3Host.Types;

type
  /// <summary>The cvar system as idCommonLocal uses it (the global cvarSystem)</summary>
  ID3CommonCVars = interface
    ['{3C5E21B4-7A90-4D18-8B6F-D1E24A907C31}']
    function IsInitialized: Boolean;
    function GetCVarInteger(const AName: AnsiString): Integer;
    function GetCVarBool(const AName: AnsiString): Boolean;
    procedure SetCVarBool(const AName: AnsiString; const AValue: Boolean);
    procedure SetCVarString(const AName, AValue: AnsiString);
  end;

  /// <summary>The cvars that Common.cpp declares for printing: developer, com_timestampPrints, logFile, logFileName</summary>
  ID3CommonSettings = interface
    ['{9A0D7E62-1B35-4C84-A7F9-5E3C60B28D14}']
    /// <summary>com_developer.GetBool</summary>
    function Developer: Boolean;
    /// <summary>com_timestampPrints.GetInteger: 0 none, 1 seconds, otherwise milliseconds</summary>
    function TimestampPrints: Integer;
    /// <summary>com_logFile.GetInteger: 0 off, 1 buffer, 2 flush after each print</summary>
    function LogFile: Integer;
    /// <summary>com_logFile.SetBool( false )</summary>
    procedure DisableLogFile;
    /// <summary>com_logFileName.GetString; may be empty</summary>
    function LogFileName: AnsiString;
  end;

  /// <summary>The Sys_* functions that Common.cpp calls</summary>
  ID3CommonSystem = interface
    ['{5B7F3A19-C2E0-4D65-93A8-0E41D6B7F2C9}']
    /// <summary>Sys_Milliseconds</summary>
    function Milliseconds: Integer;
    /// <summary>Sys_Printf: the text to the dedicated console and the early console</summary>
    procedure Printf(const AText: AnsiString);
    /// <summary>Sys_SetClipboardData</summary>
    procedure SetClipboardData(const AText: AnsiString);
    /// <summary>Sys_SetFatalError</summary>
    procedure SetFatalError(const AText: AnsiString);
    /// <summary>Sys_Quit: ends the process; the caller does not expect it to return</summary>
    procedure Quit;
    /// <summary>Sys_Error: shows the error and ends the process; the caller does not expect it to return</summary>
    procedure Error(const AText: AnsiString);
  end;

  /// <summary>The global console: console->Print</summary>
  ID3CommonConsole = interface
    ['{E2C48D07-6F13-4A5B-B9D0-7A18C3E5F624}']
    procedure Print(const AText: AnsiString);
  end;

  /// <summary>The part of the session that Common.cpp and EventLoop.cpp call</summary>
  ID3CommonSession = interface
    ['{47D1B8E3-0A9C-4F52-8E36-C5B2D9A04F71}']
    procedure Stop;
    procedure UpdateScreen;
    procedure PacifierUpdate;
    /// <summary>session->ProcessEvent: an event that is not a console line</summary>
    procedure ProcessEvent(const AEvent: TD3SysEvent);
  end;

  /// <summary>
  ///   renderSystem->IsOpenGLRunning. Without a renderer (a program without a window) this is false, and then
  ///   every Error is fatal: the drop of Common.cpp is never reached; that is what the original does
  /// </summary>
  ID3CommonRenderState = interface
    ['{8F36C0A5-D47E-4B19-A2E8-31F9B6D07C45}']
    function IsOpenGLRunning: Boolean;
  end;

  /// <summary>An idFile: written or read as bytes, or written as text</summary>
  ID3CommonFile = interface
    ['{1D9A5F73-B8E2-4C06-95A1-4C70E3F8B2D6}']
    /// <summary>The bytes written, or -1</summary>
    function Write(const ABuffer; ACount: Integer): Integer;
    /// <summary>The bytes read, less than ACount at the end of the file</summary>
    function Read(var ABuffer; ACount: Integer): Integer;
    procedure Flush;
    procedure ForceFlush;
  end;

  /// <summary>The part of idFileSystem that Common.cpp and EventLoop.cpp use</summary>
  ID3CommonFileSystem = interface
    ['{6A2E90D4-3F85-4B71-8C0D-E7A4B1F53296}']
    function IsInitialized: Boolean;
    /// <summary>OpenFileWrite; APath is the base ("fs_savepath") or empty; nil if it cannot be opened</summary>
    function OpenFileWrite(const AName, APath: AnsiString): ID3CommonFile;
    /// <summary>OpenFileRead; nil if it does not exist</summary>
    function OpenFileRead(const AName: AnsiString): ID3CommonFile;
    procedure CloseFile(const AFile: ID3CommonFile);
  end;

  /// <summary>Shutdown() of idCommonLocal, which Error and FatalError call before leaving</summary>
  ID3CommonLifecycle = interface
    ['{C07B4E91-52A6-4D38-B1F7-2E85A9D30C68}']
    procedure Shutdown;
  end;

  /// <summary>The time and date of the computer: asctime( localtime( time ) ), with the line feed</summary>
  ID3CommonCalendar = interface
    ['{F4A18D26-9E73-4C05-A6B2-83D50E7C1F94}']
    function CurrentTimeText: AnsiString;
  end;

  /// <summary>FatalError of idCommonLocal, for the classes that can fail fatally (the log file)</summary>
  ID3FatalErrorSink = interface
    ['{2E96D5B1-A4C8-4F30-87D2-B01C7F3A5E49}']
    procedure FatalError(const AText: AnsiString);
  end;

  /// <summary>Error of idCommonLocal: raises ED3HostException for a drop, or leaves the program for a fatal error</summary>
  ID3ErrorReporter = interface
    ['{6D3F8A12-C095-4B7E-A1D4-0E92B5F7C386}']
    procedure Error(const AText: AnsiString);
  end;

  /// <summary>Warning of idCommonLocal: prints "WARNING:" and remembers the text</summary>
  ID3WarningSink = interface
    ['{B9E4172C-5A08-4D3F-8C61-F27D0A93E5B4}']
    procedure Warning(const AText: AnsiString);
  end;

  /// <summary>The printing of idCommonLocal (VPrintf, Printf, DPrintf); every text is already formatted</summary>
  ID3Printer = interface
    ['{B3C70F58-1D2A-4E96-9A4B-6F85E0D17C23}']
    procedure Printf(const AText: AnsiString);
    procedure DPrintf(const AText: AnsiString);
  end;

  /// <summary>idCommon::StartupVariable: the "set" lines of the command line</summary>
  ID3StartupVariables = interface
    ['{D18E4A63-7C05-4B92-A3F6-90B5C2E8D471}']
    procedure StartupVariable(const AMatch: AnsiString; const AOnce: Boolean);
  end;

  /// <summary>The key states that the event loop updates: idKeyInput::PreliminaryKeyEvent</summary>
  ID3KeyTracker = interface
    ['{4C85A2F9-E031-4D67-B8A0-17D3F6C95E82}']
    procedure PreliminaryKeyEvent(const AKey: Integer; const ADown: Boolean);
  end;

  /// <summary>Sys_GetEvent: the next event of the system, SE_NONE when there are no more</summary>
  ID3EventSource = interface
    ['{A7F23E58-0B91-4C6D-93E4-5D08B1C7A236}']
    function GetEvent: TD3SysEvent;
  end;

  /// <summary>com_journal: 0 off, 1 record the events, 2 play them back</summary>
  ID3JournalSettings = interface
    ['{09D6B4E2-8A53-4F17-B0C9-E2A7358D1F64}']
    function JournalLevel: Integer;
    /// <summary>com_journal.SetInteger</summary>
    procedure SetJournalLevel(const ALevel: Integer);
  end;

implementation

end.
