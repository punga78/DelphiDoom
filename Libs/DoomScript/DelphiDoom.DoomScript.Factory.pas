{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptFactory, the composition   }
{  root of the library                                                         }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\script and          }
{  game\gamesys\Event, Class. Copyright (C) 1999-2011 id Software LLC, a       }
{  ZeniMax Media company.                                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Factory;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.DoomScript.Intf, DelphiDoom.DoomScript.Machine;

type
  /// <summary>
  ///   Builds a script machine: the only place that knows the concrete classes of the library and how
  ///   they depend on each other
  /// </summary>
  TDoomScriptFactory = class
  public
    /// <summary>
    ///   A new machine, owned by the caller. The host gives the time and the options; the world (may be
    ///   nil: then <c>sys.getEntity</c>, <c>spawn</c>, <c>copySpawnArgs</c>, <c>onSignal</c> and
    ///   <c>clearSignalThread</c> have no handler) the few world services the library calls; the log
    ///   receives what the original printed; the file system gives the script files. The class
    ///   "idClass" and its child "idThread" are declared in the class registry: the host declares its
    ///   own classes under "idClass".
    /// </summary>
    class function CreateMachine(const AHost: IDoomScriptHost; const AWorld: IDoomScriptWorld; const ALog: IIdLibLog;
      const AFileSystem: IIdLibFileSystem): TDoomScriptMachine; static;
  end;

implementation

uses
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventRegistry, DelphiDoom.DoomScript.ClassRegistry,
  DelphiDoom.DoomScript.EventQueue, DelphiDoom.DoomScript.Entities, DelphiDoom.DoomScript.ScriptProgram,
  DelphiDoom.DoomScript.Compiler, DelphiDoom.DoomScript.Context, DelphiDoom.DoomScript.Thread,
  DelphiDoom.DoomScript.SysEvents;

const
  SNoHost = 'TDoomScriptFactory: a script machine needs a host';
  ROOT_CLASS: AnsiString = 'idClass';
  THREAD_CLASS: AnsiString = 'idThread';

class function TDoomScriptFactory.CreateMachine(const AHost: IDoomScriptHost; const AWorld: IDoomScriptWorld;
  const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem): TDoomScriptMachine;
var
  LContext: TDoomScriptContext;
  LCompiler: TDoomScriptCompiler;
  LSysEvents: TDoomScriptSysEvents;
  LProgram: TDoomScriptProgram;
begin
  if not Assigned(AHost) then
    raise EDoomScriptError.Create(SNoHost);
  LCompiler := nil;
  LSysEvents := nil;
  LContext := TDoomScriptContext.Create;
  try
    LContext.Host := AHost;
    LContext.World := AWorld;
    LContext.Log := ALog;
    LContext.Events := TDoomScriptEventRegistry.Create;
    LContext.Classes := TDoomScriptClassRegistry.Create;
    LContext.Classes.Declare(ROOT_CLASS);
    LContext.ThreadClass := LContext.Classes.Declare(THREAD_CLASS, ROOT_CLASS);
    LProgram := TDoomScriptProgram.Create(AHost, ALog, AFileSystem);
    LContext.ScriptProgram := LProgram;
    LContext.Entities := TDoomScriptEntityTable.Create(LProgram);
    LContext.Queue := TDoomScriptEventQueue.Create(AHost, LContext.Events, LContext.Classes, LContext.Entities);
    LSysEvents := TDoomScriptSysEvents.Create(LContext);
    LCompiler := TDoomScriptCompiler.Create(LProgram, LContext.Events, LContext.ThreadClass, ALog, AFileSystem);
    LProgram.SetCompiler(
      procedure(const AText, AFileName: AnsiString; const AConsole: Boolean)
      begin
        LCompiler.CompileFile(AText, AFileName, AConsole);
      end);
    LProgram.SetRestartThreads(
      procedure
      begin
        TDoomScriptThread.Restart(LContext);
      end);
    LProgram.SetReleaseObjects(
      procedure(ATypeCount: Integer)
      begin
        LContext.Entities.ReleaseObjects(ATypeCount);
      end);
    Result := TDoomScriptMachine.Create(LContext, LCompiler, LSysEvents);
  except
    LSysEvents.Free;
    LCompiler.Free;
    if Assigned(LContext.ScriptProgram) then
    begin
      LContext.ScriptProgram.SetCompiler(nil);
      LContext.ScriptProgram.SetRestartThreads(nil);
      LContext.ScriptProgram.SetReleaseObjects(nil);
    end;
    LContext.Queue.Free;
    LContext.Entities.Free;
    LContext.ScriptProgram.Free;
    LContext.Classes.Free;
    LContext.Events.Free;
    LContext.Free;
    raise;
  end;
end;

end.
