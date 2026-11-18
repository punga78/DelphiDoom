{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idTrigger (the base of the triggers)      }
{                                                                              }
{  Port of Doom 3 (id Software): game\Trigger.h, Trigger.cpp (idTrigger).      }
{  Contents and clip models are not ported (there is no clipping): a trigger   }
{  is activated by the <c>activate</c> and <c>&lt;touch&gt;</c> events.        }
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
unit DelphiDoom.D3Game.Trigger;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity;

type
  /// <summary>
  ///   idTrigger: an entity that fires when it is activated or touched. The base knows the script function the
  ///   <c>call</c> key names (a new thread runs it when the trigger fires) and answers <c>enable</c> and
  ///   <c>disable</c>.
  /// </summary>
  TD3Trigger = class(TD3Entity)
  strict private
    FScriptFunction: AnsiString;
  protected
    /// <summary>idTrigger::CallScript: starts the function of the <c>call</c> key in a new thread</summary>
    procedure CallScript;
    /// <summary>The origin as the warnings print it: <c>GetPhysics()->GetOrigin().ToString( 0 )</c></summary>
    function OriginText: AnsiString;
  public
    /// <summary>idTrigger::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    /// <summary>The <c>EVENT</c> lines of idTrigger (<c>enable</c>, <c>disable</c>)</summary>
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    /// <summary>idTrigger::Enable: the contents are not ported</summary>
    procedure Enable; virtual;
    /// <summary>idTrigger::Disable</summary>
    procedure Disable; virtual;
    /// <summary>idTrigger::GetScriptFunction: the name of the function, empty for none</summary>
    function GetScriptFunction: AnsiString;
  end;

implementation

const
  SUnknownFunction = 'trigger ''%s'' at (%s) calls unknown function ''%s''';

class procedure TD3Trigger.SpawnClass(const AInstance: TD3Class);
var
  LTrigger: TD3Trigger;
  LFunctionName: AnsiString;
begin
  LTrigger := TD3Trigger(AInstance);
  LFunctionName := LTrigger.SpawnArgs.GetString('call', '');
  LTrigger.FScriptFunction := '';
  if Length(LFunctionName) > 0 then
  begin
    if Assigned(LTrigger.Game) and Assigned(LTrigger.Game.GetScriptFunctions) and
      LTrigger.Game.GetScriptFunctions.HasFunction(LFunctionName) then
      LTrigger.FScriptFunction := LFunctionName
    else
      LTrigger.Game.Warning(AnsiString(Format(SUnknownFunction, [string(LTrigger.GetName),
        string(LTrigger.OriginText), string(LFunctionName)])));
  end;
end;

class procedure TD3Trigger.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Enable,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Trigger(ATarget).Enable;
    end);
  AType.AddEvent(AEvents.Disable,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Trigger(ATarget).Disable;
    end);
end;

procedure TD3Trigger.Enable;
begin
end;

procedure TD3Trigger.Disable;
begin
end;

function TD3Trigger.GetScriptFunction: AnsiString;
begin
  Result := FScriptFunction;
end;

procedure TD3Trigger.CallScript;
begin
  if (Length(FScriptFunction) > 0) and Assigned(Game) and Assigned(Game.GetSpawnFunctions) then
    // idThread *thread = new idThread( scriptFunction ); thread->DelayedStart( 0 );
    Game.GetSpawnFunctions.StartSpawnFunction(FScriptFunction);
end;

function TD3Trigger.OriginText: AnsiString;
begin
  Result := GetPhysics.GetOrigin.ToString(0);
end;

end.
