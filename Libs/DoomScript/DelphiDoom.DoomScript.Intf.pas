{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - what the script system asks its host  }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): the uses of gameLocal,   }
{  fileSystem and the cvars in game\script\*.cpp. Copyright (C) 1999-2011 id   }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.Intf;

interface

uses
  DelphiDoom.Scanner.IdDict;

type
  /// <summary>
  ///   The game around the script system. Time is always given from outside: the library never reads a
  ///   clock. What is printed goes to an <c>IIdLibLog</c>, source files come from an
  ///   <c>IIdLibFileSystem</c>, and the objects of the game receive events as
  ///   <c>TDoomScriptEventTarget</c> registered in the entity table; errors are exceptions.
  /// </summary>
  IDoomScriptHost = interface
    ['{6B1E3C52-0F5E-4B0A-9C2D-11A0D0C0F110}']
    /// <summary>gameLocal.time, in milliseconds</summary>
    function GetTime: Integer;
    /// <summary>gameLocal.msec: the length of a frame in milliseconds</summary>
    function GetFrameMsec: Integer;
    /// <summary>gameLocal.realClientTime, what <c>sys.getTime</c> returns in seconds</summary>
    function GetRealClientTime: Integer;
    /// <summary>gameLocal.random.RandomFloat: 0 to 1, for <c>sys.random</c></summary>
    function RandomFloat: Single;
    /// <summary>fileSystem->RelativePathToOSPath</summary>
    function RelativePathToOSPath(const APath: AnsiString): AnsiString;
    /// <summary>fileSystem->OSPathToRelativePath: '' if the path is not under the base path</summary>
    function OSPathToRelativePath(const APath: AnsiString): AnsiString;
    /// <summary>The cvar g_debugScript: trace of threads and calls</summary>
    function DebugScript: Boolean;
    /// <summary>The cvar developer: more warnings and the list of files in the compile statistics</summary>
    function Developer: Boolean;
    /// <summary>The cvar g_disasm: write script/disasm.txt after a compilation</summary>
    function Disassemble: Boolean;
    /// <summary>
    ///   gameLocal.DPrintf: text for the developer (the host shows it only when its cvar "developer" is set)
    /// </summary>
    procedure DebugPrintf(const AText: string);
  end;

  /// <summary>
  ///   The few things of the game world that the events of the <c>sys</c> object implemented by the
  ///   library need (the other world events - cvars, traces, sounds, camera... - are handlers the host
  ///   adds to the class of the threads). An entity is its handle, -1 for none.
  /// </summary>
  IDoomScriptWorld = interface
    ['{6B1E3C52-0F5E-4B0A-9C2D-11A0D0C0F111}']
    /// <summary>gameLocal.FindEntity: the entity with this name, -1 if none</summary>
    function FindEntity(const AName: AnsiString): Integer;
    /// <summary>gameLocal.SpawnEntityDef with the spawn arguments of the thread; -1 if nothing was spawned</summary>
    function SpawnEntity(const ASpawnArgs: TIdDict): Integer;
    /// <summary>Copies the spawn arguments of an entity into a dictionary (<c>sys.copySpawnArgs</c>)</summary>
    procedure CopyEntitySpawnArgs(const AEntityNumber: Integer; const ATarget: TIdDict);
    /// <summary>idEntity::SetSignal: a thread asks to run a function when the entity gets a signal</summary>
    procedure SetSignal(const AEntityNumber, ASignal, AThreadNum: Integer; const AFunctionName: AnsiString);
    /// <summary>idEntity::ClearSignalThread</summary>
    procedure ClearSignalThread(const AEntityNumber, ASignal, AThreadNum: Integer);
  end;

implementation

end.
