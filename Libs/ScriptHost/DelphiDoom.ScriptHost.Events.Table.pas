{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the events that a script can have                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is EventExportedProcs of ps_events.pas. Must be in sync with the         }
{  events of TScriptEvents. The text of the template is always there (it was   }
{  only in the compiler DLLs, for the editor of the scripts).                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Events.Table;

interface

uses
  ps_compiler,
  ps_defs,
  ps_utils;

type
  /// <summary>The name and the parameters that the compiler checks for a procedure of event</summary>
  TScriptEventSignature = record
    /// <summary>The upper case name of the procedure</summary>
    Name: AnsiString;
    ParamCount: Byte;
    /// <summary>The type of the result (0 for none) and then of each parameter</summary>
    Typ: array [0..4] of Byte;
    Dir: array [0..3] of TPSParameterMode;
    /// <summary>The text that the editor of the scripts inserts for a new event ('|' is a line break)</summary>
    Template: AnsiString;
  end;

const
  SCRIPT_EVENT_COUNT = 10;

  SCRIPT_EVENT_SIGNATURES: array [0..SCRIPT_EVENT_COUNT - 1] of TScriptEventSignature =
  (
    (
      Name: 'ONACTORDIED';
      ParamCount: 2;
      Typ: (0, btU32, btU32, 0,     0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnActorDied(const actorKEY: LongWord; const killer: LongWord);|' +
                'begin|' +
                '// Executes every time an actor dies, before dropping the dropitem|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONPLAYERENTER';
      ParamCount: 1;
      Typ: (0, btS32, 0,     0,     0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnPlayerEnter(const playerNO: integer);|' +
                'begin|' +
                '// Executes the first time a player spawns to the map, just after OnMapStart Event|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONPLAYERDIED';
      ParamCount: 2;
      Typ: (0, btS32, btU32, 0,     0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnPlayerDied(const playerNO: integer; const killer: LongWord);|' +
                'begin|' +
                '// Executes every time a player dies, before OnActorDied event|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONCROSSLINE';
      ParamCount: 3;
      Typ: (0, btU32, btS32, btS32, 0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnCrossLine(const actorKEY: LongWord; const lineNO: Integer;|' +
                '  const oldside: Integer);|' +
                'begin|' +
                '// Executes when the actor "actorKEY" crosses the line "lineNO"|' +
                '// line must have the "Trigger PascalScript" setting enabled|' +
                '// actor must not have the MF2_EX_DONTRUNSCRIPTS flag|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONSHOOTLINE';
      ParamCount: 3;
      Typ: (0, btU32, btS32, btS32, 0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnShootLine(const actorKEY: LongWord; const lineNO: Integer;|' +
                '  const side: Integer);|' +
                'begin|' +
                '// Executes when the actor "actorKEY" shoots the line "lineNO"|' +
                '// line must have the "Trigger PascalScript" setting enabled|' +
                '// actor must not have the MF2_EX_DONTRUNSCRIPTS flag|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONUSELINE';
      ParamCount: 3;
      Typ: (0, btU32, btS32, btS32, 0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnUseLine(const actorKEY: LongWord; const lineNO: Integer;|' +
                '  const side: Integer);|' +
                'begin|' +
                '// Executes when the actor "actorKEY" uses the line "lineNO"|' +
                '// line must have the "Trigger PascalScript" setting enabled|' +
                '// actor must not have the MF2_EX_DONTRUNSCRIPTS flag|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONTICK';
      ParamCount: 1;
      Typ: (0, btS32, 0,     0,     0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnTick(const tick: Integer);|' +
                'begin|' +
                '// Executes in every tick (35 times/second), after running all thinkers|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONTIMEREVERYSECOND';
      ParamCount: 1;
      Typ: (0, btS32, 0,     0,     0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnTimerEverySecond(const second: Integer);|' +
                'begin|' +
                '// Executes every second (35 ticks), after OnTick Event|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONTIMEREVERYMINUTE';
      ParamCount: 1;
      Typ: (0, btS32, 0,     0,     0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnTimerEveryMinute(const minute: integer);|' +
                'begin|' +
                '// Executes every minute (35 * 60 ticks), after OnTimerEverySecond Event|' +
                '  |' +
                'end;||'
    ),
    (
      Name: 'ONMAPSTART';
      ParamCount: 0;
      Typ: (0, 0,     0,     0,     0    );
      Dir: (pmIn, pmIn, pmIn, pmIn);
      Template: 'event OnMapStart;|' +
                'begin|' +
                '// Executes the first time the map loads, before running thinkers|' +
                '  |' +
                'end;||'
    )
  );

implementation

end.
