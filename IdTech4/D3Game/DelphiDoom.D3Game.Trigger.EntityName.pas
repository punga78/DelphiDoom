{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idTrigger_EntityName                       }
{                                                                              }
{  Port of Doom 3 (id Software): game\Trigger.cpp (idTrigger_EntityName): the   }
{  trigger that fires only for the entity that has the name in its              }
{  <c>entityname</c> key, when it touches the trigger or when the entity is     }
{  activated by it.                                                             }
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
unit DelphiDoom.D3Game.Trigger.EntityName;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Trigger;

type
  /// <summary>
  ///   idTrigger_EntityName: fires its targets (and its script function) when the entity named by <c>entityname</c>
  ///   touches it or activates it, then waits <c>wait</c> seconds; a negative wait fires once and removes the trigger.
  /// </summary>
  TD3TriggerEntityName = class(TD3Trigger)
  strict private
    FWait: Single;
    FRandom: Single;
    FDelay: Single;
    FRandomDelay: Single;
    FNextTriggerTime: Integer;
    FTriggerFirst: Boolean;
    FEntityName: AnsiString;
    procedure TriggerAction(const AActivator: TD3Entity);
    procedure EventTrigger(const AActivator: TD3Entity);
    procedure EventTouch(const AOther: TD3Entity);
  public
    /// <summary>idTrigger_EntityName::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    property Wait: Single read FWait;
    property Random: Single read FRandom;
    property Delay: Single read FDelay;
    property RandomDelay: Single read FRandomDelay;
    property NextTriggerTime: Integer read FNextTriggerTime;
    property TriggerFirst: Boolean read FTriggerFirst;
    property EntityName: AnsiString read FEntityName;
  end;

implementation

uses
  DelphiDoom.Collision.Types, DelphiDoom.D3Game.Types;

const
  SRandomWait = 'idTrigger_EntityName ''%s'' at (%s) has random >= wait';
  SRandomDelay = 'idTrigger_EntityName ''%s'' at (%s) has random_delay >= delay';
  SNoEntityName = 'idTrigger_EntityName ''%s'' at (%s) doesn''t have ''entityname'' key specified';

class procedure TD3TriggerEntityName.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3TriggerEntityName;
begin
  LSelf := TD3TriggerEntityName(AInstance);
  LSelf.SpawnArgs.GetFloat('wait', '0.5', LSelf.FWait);
  LSelf.SpawnArgs.GetFloat('random', '0', LSelf.FRandom);
  LSelf.SpawnArgs.GetFloat('delay', '0', LSelf.FDelay);
  LSelf.SpawnArgs.GetFloat('random_delay', '0', LSelf.FRandomDelay);

  if (LSelf.FRandom <> 0) and (LSelf.FRandom >= LSelf.FWait) and (LSelf.FWait >= 0) then
  begin
    LSelf.FRandom := LSelf.FWait - 1;
    LSelf.Game.Warning(AnsiString(Format(SRandomWait, [string(LSelf.GetName), string(LSelf.OriginText)])));
  end;

  if (LSelf.FRandomDelay <> 0) and (LSelf.FRandomDelay >= LSelf.FDelay) and (LSelf.FDelay >= 0) then
  begin
    LSelf.FRandomDelay := LSelf.FDelay - 1;
    LSelf.Game.Warning(AnsiString(Format(SRandomDelay, [string(LSelf.GetName), string(LSelf.OriginText)])));
  end;

  LSelf.SpawnArgs.GetBool('triggerFirst', '0', LSelf.FTriggerFirst);

  LSelf.FEntityName := LSelf.SpawnArgs.GetString('entityname');
  if Length(LSelf.FEntityName) = 0 then
    LSelf.World.Error(AnsiString(Format(SNoEntityName, [string(LSelf.GetName), string(LSelf.OriginText)])));

  LSelf.FNextTriggerTime := 0;

  if not LSelf.SpawnArgs.GetBool('noTouch') then
    LSelf.GetPhysics.SetContents(CONTENTS_TRIGGER);
end;

class procedure TD3TriggerEntityName.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Touch,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerEntityName(ATarget).EventTouch(TD3TriggerEntityName(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerEntityName(ATarget).EventTrigger(TD3TriggerEntityName(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.TriggerAction,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerEntityName(ATarget).TriggerAction(TD3TriggerEntityName(ATarget).EntityFromArg(AArgs[0]));
    end);
end;

procedure TD3TriggerEntityName.TriggerAction(const AActivator: TD3Entity);
var
  LTime: Single;
begin
  ActivateTargets(AActivator);
  CallScript;

  if FWait >= 0 then
  begin
    LTime := FWait + FRandom * Game.CRandomFloat;
    FNextTriggerTime := Game.GetTime + TDoomScriptConvert.SecToMs(LTime);
  end
  else
  begin
    // we can't just remove (this) here, because this is a touch function called while looping through area links...
    FNextTriggerTime := Game.GetTime + 1;
    PostEventMS(Game.GetEvents.Remove, 0);
  end;
end;

procedure TD3TriggerEntityName.EventTrigger(const AActivator: TD3Entity);
var
  LTime: Single;
begin
  if FNextTriggerTime > Game.GetTime then
    // can't retrigger until the wait is over
    Exit;

  if (not Assigned(AActivator)) or (AActivator.GetName <> FEntityName) then
    Exit;

  if FTriggerFirst then
  begin
    FTriggerFirst := False;
    Exit;
  end;

  // don't allow it to trigger twice in a single frame
  FNextTriggerTime := Game.GetTime + 1;

  if FDelay > 0 then
  begin
    // don't allow it to trigger again until our delay has passed
    LTime := FDelay + FRandomDelay * Game.CRandomFloat;
    Inc(FNextTriggerTime, TDoomScriptConvert.SecToMs(LTime));
    PostEventSec(Game.GetEvents.TriggerAction, FDelay, [EntityArg(AActivator)]);
  end
  else
    TriggerAction(AActivator);
end;

procedure TD3TriggerEntityName.EventTouch(const AOther: TD3Entity);
var
  LTime: Single;
begin
  if FTriggerFirst then
    Exit;

  if FNextTriggerTime > Game.GetTime then
    // can't retrigger until the wait is over
    Exit;

  if (not Assigned(AOther)) or (AOther.GetName <> FEntityName) then
    Exit;

  FNextTriggerTime := Game.GetTime + 1;
  if FDelay > 0 then
  begin
    // don't allow it to trigger again until our delay has passed
    LTime := FDelay + FRandomDelay * Game.CRandomFloat;
    Inc(FNextTriggerTime, TDoomScriptConvert.SecToMs(LTime));
    PostEventSec(Game.GetEvents.TriggerAction, FDelay, [EntityArg(AOther)]);
  end
  else
    TriggerAction(AOther);
end;

end.
