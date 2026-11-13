{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - types and exceptions                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.Types;

// The cold part of the i_* units of the engine (issue #185, phase 1, slice 1d): the types shared by
// the classes of the library. Nothing here knows the engine globals or the Windows API.

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Net.Types;

type
  /// <summary>Raised for what the caller got wrong when it builds a class of the library</summary>
  EEngineSystemException = class(Exception);

  /// <summary>What a drone computer shows: the view turned by an angle (-left, -right, -back)</summary>
  TNetDroneView = (ndvNone, ndvLeft, ndvRight, ndvBack);

  /// <summary>What the command line says about a network game (-dup, -extratic, -port, -left, -net...)</summary>
  TNetCommandLineOptions = record
    /// <summary>Tics that every ticcmd is repeated for, 1..9</summary>
    TicDup: Integer;
    /// <summary>1 with -extratic, else 0</summary>
    ExtraTics: Integer;
    /// <summary>The UDP port of this node; the port of the previous reading when -port is missing</summary>
    Port: Integer;
    Drone: TNetDroneView;
    /// <summary>True with -net</summary>
    IsNetGame: Boolean;
    /// <summary>0-based number of this computer</summary>
    ConsolePlayer: Integer;
    /// <summary>This node and the hosts that follow -net</summary>
    NumNodes: Integer;
    /// <summary>The other nodes, node 1 first</summary>
    Peers: TArray<TNetNodeAddress>;
  end;

  /// <summary>What the machine is, from the operating system and the processor</summary>
  TMachineProfile = record
    HasMmx: Boolean;
    Has3DNow: Boolean;
    ProcessorCount: Integer;
    /// <summary>True when the renderer may use more than one thread</summary>
    UseMultithread: Boolean;
    /// <summary>The lines the engine writes at the start, each one with its CRLF</summary>
    Lines: TArray<string>;
  end;

  /// <summary>The three files that the engine writes its output to, with the folder of the game</summary>
  TLogFileSet = record
    DebugFile: string;
    ErrorFile: string;
    StdoutFile: string;
  end;

  /// <summary>
  ///   One step of the shutdown: the line written before it and what it does (nil: the line only).
  ///   A reference to a procedure, so that a step can read what it needs when it runs
  /// </summary>
  TShutdownStep = record
    Announcement: string;
    Action: TProc;
    class function Make(const AAnnouncement: string; const AAction: TProc): TShutdownStep; static;
  end;

  /// <summary>
  ///   What the unhandled exception filter knows about the crash. A 32 bit machine: the
  ///   addresses and the registers are 32 bit values, as in the report of the old code
  /// </summary>
  TCrashSnapshot = record
    ExceptionCode: Cardinal;
    ExceptionAddress: Cardinal;
    ImageBase: Cardinal;
    ImageSize: Cardinal;
    ThreadId: Cardinal;
    /// <summary>The number of parameters of the exception record, and the first two</summary>
    ParameterCount: Cardinal;
    Parameter0: Cardinal;
    Parameter1: Cardinal;
    Eip: Cardinal;
    Esp: Cardinal;
    Ebp: Cardinal;
    Eax: Cardinal;
    Ebx: Cardinal;
    Ecx: Cardinal;
    Edx: Cardinal;
    Esi: Cardinal;
    Edi: Cardinal;
  end;

const
  /// <summary>MIDI player of the engine (snd_uselegacymidiplayer): never the legacy one, the stream</summary>
  MIDI_PLAYER_STREAM = 0;
  /// <summary>The player that goes through the MCI sequencer of Windows</summary>
  MIDI_PLAYER_LEGACY = 1;
  /// <summary>The internal player, which feeds a MIDI stream (the default)</summary>
  MIDI_PLAYER_INTERNAL = 2;

  /// <summary>Exception code of an access violation</summary>
  CRASH_EXCEPTION_ACCESS_VIOLATION = $C0000005;

resourcestring
  SMikModPlayWarning = 'I_PlayMik(): %s'#13#10;
  SMikModInitWarning = 'I_InitMik(): %s'#13#10;
  SGameFinished = #13#10'I_Destroy: Game finished.'#13#10#13#10;
  SNullPointerArgument = '%s is nil';

implementation

{ TShutdownStep }

class function TShutdownStep.Make(const AAnnouncement: string;
  const AAction: TProc): TShutdownStep;
begin
  Result.Announcement := AAnnouncement;
  Result.Action := AAction;
end;

end.
