{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idTrigger_Hurt                            }
{                                                                              }
{  Port of Doom 3 (id Software): game\Trigger.cpp (idTrigger_Hurt, the class   }
{  of trigger_hurt). The damage itself is not ported: the touched entity is    }
{  told <c>Damage( def, 1.0 )</c> and does what it does (nothing by default).  }
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
unit DelphiDoom.D3Game.Trigger.Hurt;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Trigger;

type
  /// <summary>
  ///   idTrigger_Hurt: damages what touches it, at most once every <c>delay</c> seconds, and fires its targets;
  ///   activating it switches it on and off.
  /// </summary>
  TD3TriggerHurt = class(TD3Trigger)
  strict private
    FOn: Boolean;
    FDelay: Single;
    FNextTime: Integer;
    procedure EventTouch(const AOther: TD3Entity);
    procedure EventToggle;
  public
    /// <summary>idTrigger_Hurt::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    property IsOn: Boolean read FOn;
    property NextTime: Integer read FNextTime;
    property Delay: Single read FDelay;
  end;

implementation

class procedure TD3TriggerHurt.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3TriggerHurt;
begin
  LSelf := TD3TriggerHurt(AInstance);
  LSelf.SpawnArgs.GetBool('on', '1', LSelf.FOn);
  LSelf.SpawnArgs.GetFloat('delay', '1.0', LSelf.FDelay);
  LSelf.FNextTime := LSelf.Game.GetTime;
  LSelf.Enable;
end;

class procedure TD3TriggerHurt.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Touch,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerHurt(ATarget).EventTouch(TD3TriggerHurt(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerHurt(ATarget).EventToggle;
    end);
end;

procedure TD3TriggerHurt.EventTouch(const AOther: TD3Entity);
begin
  if FOn and Assigned(AOther) and (Game.GetTime >= FNextTime) then
  begin
    AOther.Damage(SpawnArgs.GetString('def_damage', 'damage_painTrigger'), 1.0);
    ActivateTargets(AOther);
    CallScript;
    FNextTime := Game.GetTime + TDoomScriptConvert.SecToMs(FDelay);
  end;
end;

procedure TD3TriggerHurt.EventToggle;
begin
  FOn := not FOn;
end;

end.
