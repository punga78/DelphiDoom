{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptContext                    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): the static members of    }
{  idThread (threadList, currentThread, threadIndex) and what the threads      }
{  reach through gameLocal in game\script\Script_Thread.cpp. Copyright (C)     }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Context;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.DoomScript.Intf,
  DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry, DelphiDoom.DoomScript.ClassInfo,
  DelphiDoom.DoomScript.ClassRegistry, DelphiDoom.DoomScript.EventQueue, DelphiDoom.DoomScript.Entities,
  DelphiDoom.DoomScript.ScriptProgram, DelphiDoom.DoomScript.Interpreter;

type
  /// <summary>
  ///   What the threads of one script machine share: the parts of the machine (not owned: the composition
  ///   root owns them) and the state that was static in idThread - the list of the threads, the thread
  ///   that is running and the last thread number given.
  /// </summary>
  TDoomScriptContext = class
  public
    Host: IDoomScriptHost;
    World: IDoomScriptWorld;
    Log: IIdLibLog;
    ScriptProgram: TDoomScriptProgram;
    Entities: TDoomScriptEntityTable;
    Events: TDoomScriptEventRegistry;
    Classes: TDoomScriptClassRegistry;
    Queue: TDoomScriptEventQueue;
    /// <summary>The class of the threads ("idThread"): the events of <c>sys</c> are its handlers</summary>
    ThreadClass: TDoomScriptClassInfo;
    /// <summary>EV_Thread_Execute "&lt;execute&gt;"</summary>
    EvExecute: TDoomScriptEventDef;
    /// <summary>EV_Remove "&lt;immediateremove&gt;"</summary>
    EvRemove: TDoomScriptEventDef;
    /// <summary>EV_Thread_SetCallback "&lt;script_setcallback&gt;"</summary>
    EvSetCallback: TDoomScriptEventDef;
    /// <summary>idThread::threadList, in order of creation</summary>
    Threads: TList<TDoomScriptThreadBase>;
    /// <summary>idThread::currentThread</summary>
    CurrentThread: TDoomScriptThreadBase;
    /// <summary>idThread::threadIndex</summary>
    ThreadIndex: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Print(const AText: string);
  end;

implementation

constructor TDoomScriptContext.Create;
begin
  inherited Create;
  Threads := TList<TDoomScriptThreadBase>.Create;
end;

destructor TDoomScriptContext.Destroy;
begin
  Threads.Free;
  inherited;
end;

procedure TDoomScriptContext.Print(const AText: string);
begin
  if Assigned(Log) then
    Log.Printf(AText);
end;

end.
