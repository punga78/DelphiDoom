{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idTrigger_Multi                           }
{                                                                              }
{  Port of Doom 3 (id Software): game\Trigger.cpp (idTrigger_Multi). It is the }
{  class of trigger_multi and, with wait -1, of trigger_once (an entityDef of  }
{  the game data: there is no class of its own in the source).                 }
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
unit DelphiDoom.D3Game.Trigger.Multi;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Trigger;

type
  /// <summary>
  ///   idTrigger_Multi: fires its targets (and its script function) when activated or touched, then waits
  ///   <c>wait</c> seconds (plus or minus <c>random</c>) before it can fire again; a negative wait fires once and
  ///   removes the trigger. A <c>delay</c> postpones the firing. There is no player: <c>facing</c> never refuses, an
  ///   <c>requires</c> item is always met, and a touch is "other" (the <c>noClient</c>/<c>anyTouch</c> keys decide).
  /// </summary>
  TD3TriggerMulti = class(TD3Trigger)
  strict private
    FWait: Single;
    FRandom: Single;
    FDelay: Single;
    FRandomDelay: Single;
    FNextTriggerTime: Integer;
    FRequires: AnsiString;
    FRemoveItem: Integer;
    FTouchClient: Boolean;
    FTouchOther: Boolean;
    FTriggerFirst: Boolean;
    FTriggerWithSelf: Boolean;
    procedure TriggerAction(const AActivator: TD3Entity);
    procedure EventTrigger(const AActivator: TD3Entity);
    procedure EventTouch(const AOther: TD3Entity);
  public
    /// <summary>idTrigger_Multi::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    property Wait: Single read FWait;
    property Delay: Single read FDelay;
    property RandomDelay: Single read FRandomDelay;
    property Random: Single read FRandom;
    property NextTriggerTime: Integer read FNextTriggerTime;
    property TriggerFirst: Boolean read FTriggerFirst;
  end;

implementation

const
  SRandomWait = 'idTrigger_Multi ''%s'' at (%s) has random >= wait';
  SRandomDelay = 'idTrigger_Multi ''%s'' at (%s) has random_delay >= delay';

class procedure TD3TriggerMulti.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3TriggerMulti;
begin
  LSelf := TD3TriggerMulti(AInstance);
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

  LSelf.SpawnArgs.GetString('requires', '', LSelf.FRequires);
  LSelf.SpawnArgs.GetInt('removeItem', '0', LSelf.FRemoveItem);
  LSelf.SpawnArgs.GetBool('triggerFirst', '0', LSelf.FTriggerFirst);
  LSelf.SpawnArgs.GetBool('triggerWithSelf', '0', LSelf.FTriggerWithSelf);

  if LSelf.SpawnArgs.GetBool('anyTouch') then
  begin
    LSelf.FTouchClient := True;
    LSelf.FTouchOther := True;
  end
  else if LSelf.SpawnArgs.GetBool('noTouch') then
  begin
    LSelf.FTouchClient := False;
    LSelf.FTouchOther := False;
  end
  else if LSelf.SpawnArgs.GetBool('noClient') then
  begin
    LSelf.FTouchClient := False;
    LSelf.FTouchOther := True;
  end
  else
  begin
    LSelf.FTouchClient := True;
    LSelf.FTouchOther := False;
  end;

  LSelf.FNextTriggerTime := 0;
end;

class procedure TD3TriggerMulti.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Touch,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerMulti(ATarget).EventTouch(TD3TriggerMulti(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerMulti(ATarget).EventTrigger(TD3TriggerMulti(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.TriggerAction,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerMulti(ATarget).TriggerAction(TD3TriggerMulti(ATarget).EntityFromArg(AArgs[0]));
    end);
end;

procedure TD3TriggerMulti.TriggerAction(const AActivator: TD3Entity);
var
  LTime: Single;
begin
  if FTriggerWithSelf then
    ActivateTargets(Self)
  else
    ActivateTargets(AActivator);
  CallScript;

  if FWait >= 0 then
  begin
    LTime := FWait + FRandom * Game.CRandomFloat;
    FNextTriggerTime := Game.GetTime + TDoomScriptConvert.SecToMs(LTime);
  end
  else
  begin
    // we can't just remove (this) here, because this is a touch function
    // called while looping through area links...
    FNextTriggerTime := Game.GetTime + 1;
    PostEventMS(Game.GetEvents.Remove, 0);
  end;
end;

procedure TD3TriggerMulti.EventTrigger(const AActivator: TD3Entity);
var
  LTime: Single;
begin
  if FNextTriggerTime > Game.GetTime then
    // can't retrigger until the wait is over
    Exit;

  // see if this trigger requires an item
  if not RequirementMet(AActivator, FRequires, FRemoveItem) then
    Exit;

  // CheckFacing: only a player can face the wrong way, and there is none

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

procedure TD3TriggerMulti.EventTouch(const AOther: TD3Entity);
var
  LTime: Single;
begin
  if FTriggerFirst then
    Exit;

  // the original tells a player from the others; with no player type everything touching is "other"
  if not FTouchOther then
    Exit;

  if FNextTriggerTime > Game.GetTime then
    // can't retrigger until the wait is over
    Exit;

  // see if this trigger requires an item
  if not RequirementMet(AOther, FRequires, FRemoveItem) then
    Exit;

  if SpawnArgs.GetBool('toggleTriggerFirst') then
    FTriggerFirst := True;

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
