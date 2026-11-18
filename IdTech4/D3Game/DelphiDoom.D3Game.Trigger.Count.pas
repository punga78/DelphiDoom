{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idTrigger_Count                           }
{                                                                              }
{  Port of Doom 3 (id Software): game\Trigger.cpp (idTrigger_Count, the class  }
{  of trigger_count).                                                          }
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
unit DelphiDoom.D3Game.Trigger.Count;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Trigger;

type
  /// <summary>
  ///   idTrigger_Count: fires its targets once it has been activated <c>count</c> times (after <c>delay</c> seconds);
  ///   with <c>repeat</c> it starts counting again, otherwise it is exhausted (goal -1) and removes itself.
  /// </summary>
  TD3TriggerCount = class(TD3Trigger)
  strict private
    FGoal: Integer;
    FCount: Integer;
    FDelay: Single;
    procedure EventTrigger(const AActivator: TD3Entity);
    procedure EventTriggerAction(const AActivator: TD3Entity);
  public
    /// <summary>idTrigger_Count::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    property Goal: Integer read FGoal;
    property Count: Integer read FCount;
  end;

implementation

class procedure TD3TriggerCount.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3TriggerCount;
begin
  LSelf := TD3TriggerCount(AInstance);
  LSelf.SpawnArgs.GetInt('count', '1', LSelf.FGoal);
  LSelf.SpawnArgs.GetFloat('delay', '0', LSelf.FDelay);
  LSelf.FCount := 0;
end;

class procedure TD3TriggerCount.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerCount(ATarget).EventTrigger(TD3TriggerCount(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.TriggerAction,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerCount(ATarget).EventTriggerAction(TD3TriggerCount(ATarget).EntityFromArg(AArgs[0]));
    end);
end;

procedure TD3TriggerCount.EventTrigger(const AActivator: TD3Entity);
begin
  // goal of -1 means trigger has been exhausted
  if FGoal >= 0 then
  begin
    Inc(FCount);
    if FCount >= FGoal then
    begin
      if SpawnArgs.GetBool('repeat') then
        FCount := 0
      else
        FGoal := -1;
      PostEventSec(Game.GetEvents.TriggerAction, FDelay, [EntityArg(AActivator)]);
    end;
  end;
end;

procedure TD3TriggerCount.EventTriggerAction(const AActivator: TD3Entity);
begin
  ActivateTargets(AActivator);
  CallScript;
  if FGoal = -1 then
    PostEventMS(Game.GetEvents.Remove, 0);
end;

end.
