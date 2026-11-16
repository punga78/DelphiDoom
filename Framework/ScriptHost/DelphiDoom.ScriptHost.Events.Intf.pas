{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - contract of the events of the scripts             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Events.Intf;

interface

type
  /// <summary>
  ///   The procedures of event that a script can have (OnTick, OnMapStart...). A script that
  ///   does not have the procedure does nothing; an exception of the script is a warning. Must
  ///   be in sync with DelphiDoom.ScriptHost.Events.Table
  /// </summary>
  IScriptEvents = interface
    ['{7D2A5E19-B806-4F3C-A1D4-96C83E0B5F72}']
    /// <summary>Forgets the procedures: there is no script</summary>
    procedure Clear;
    /// <summary>Finds the procedures in the script that is loaded</summary>
    procedure LinkEvents;
    procedure ProcActorDied(AActor: LongWord; AKiller: LongWord);
    procedure ProcPlayerEnter(APlayerNumber: Integer);
    procedure ProcPlayerDied(APlayerNumber: Integer; AKiller: LongWord);
    procedure ProcCrossLine(AActor: LongWord; ALine: Integer; AOldSide: Integer);
    procedure ProcShootLine(AActor: LongWord; ALine: Integer; ASide: Integer);
    procedure ProcUseLine(AActor: LongWord; ALine: Integer; ASide: Integer);
    procedure ProcTick(ATick: Integer);
    procedure ProcTimerEverySecond(ASecond: Integer);
    procedure ProcTimerEveryMinute(AMinute: Integer);
    procedure ProcMapStart;
  end;

implementation

end.
