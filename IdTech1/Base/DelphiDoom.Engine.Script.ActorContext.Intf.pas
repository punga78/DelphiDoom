{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the implicit actor of the scripts (the contract)       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.ActorContext.Intf;

interface

uses
  p_mobj_h,
  DelphiDoom.ScriptHost.Actors.Intf;

type
  /// <summary>
  ///   The actor that the engine runs a script for (it was the variable ps_currentactor of
  ///   psi_game.pas). The events of the engine (PS_Event*) and A_RunScript enter it before the
  ///   script runs and leave it after: the functions of the scripts that take the key 0 and the
  ///   function Actor read it. The library only knows its key (IScriptActorContext).
  /// </summary>
  IEngineScriptActorContext = interface(IScriptActorContext)
    ['{A1D75E39-62C8-4B04-9F2E-5C30B8E1D764}']
    /// <summary>Makes the mobj the current actor (nil: no actor)</summary>
    procedure Enter(const AActor: Pmobj_t);
    /// <summary>
    ///   Forgets the current actor. It does not give back the previous one: a script that runs
    ///   another one (an event inside A_RunScript) leaves the first without an actor, as it always did
    /// </summary>
    procedure Leave;
    function Current: Pmobj_t;
    /// <summary>
    ///   The mobj of a key as the scripts mean it: 0 is the current actor (even a mobj that the
    ///   engine has not registered), SCRIPT_INVALID_ID is none, any other key is looked for among the mobjs
    /// </summary>
    function MobjFromKey(const AKey: Cardinal): Pmobj_t;
  end;

implementation

end.
