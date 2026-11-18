{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idTrigger_Timer                           }
{                                                                              }
{  Port of Doom 3 (id Software): game\Trigger.cpp (idTrigger_Timer, the class  }
{  of trigger_timer).                                                          }
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
unit DelphiDoom.D3Game.Trigger.Timer;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Trigger;

type
  /// <summary>
  ///   idTrigger_Timer: repeatedly fires its targets, every <c>wait</c> seconds plus or minus <c>random</c> (the
  ///   default <c>random</c> is 1, so every cycle draws a random number). It is turned on by <c>start_on</c>, by
  ///   <c>enable</c> or by being activated, and off by <c>disable</c> or by being activated again.
  /// </summary>
  TD3TriggerTimer = class(TD3Trigger)
  strict private
    FRandom: Single;
    FWait: Single;
    FOn: Boolean;
    FDelay: Single;
    FOnName: AnsiString;
    FOffName: AnsiString;
    procedure EventTimer;
    procedure EventUse(const AActivator: TD3Entity);
  public
    /// <summary>idTrigger_Timer::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    procedure Enable; override;
    procedure Disable; override;
    property IsOn: Boolean read FOn;
    property Random: Single read FRandom;
  end;

implementation

const
  SRandomWait = 'idTrigger_Timer ''%s'' at (%s) has random >= wait';

class procedure TD3TriggerTimer.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3TriggerTimer;
begin
  LSelf := TD3TriggerTimer(AInstance);
  LSelf.SpawnArgs.GetFloat('random', '1', LSelf.FRandom);
  LSelf.SpawnArgs.GetFloat('wait', '1', LSelf.FWait);
  LSelf.SpawnArgs.GetBool('start_on', '0', LSelf.FOn);
  LSelf.SpawnArgs.GetFloat('delay', '0', LSelf.FDelay);
  LSelf.FOnName := LSelf.SpawnArgs.GetString('onName');
  LSelf.FOffName := LSelf.SpawnArgs.GetString('offName');

  if (LSelf.FRandom >= LSelf.FWait) and (LSelf.FWait >= 0) then
  begin
    // random = wait - 0.001 (a double expression stored in a float)
    LSelf.FRandom := LSelf.FWait - 0.001;
    LSelf.Game.Warning(AnsiString(Format(SRandomWait, [string(LSelf.GetName), string(LSelf.OriginText)])));
  end;

  if LSelf.FOn then
    LSelf.PostEventSec(LSelf.Game.GetEvents.Timer, LSelf.FDelay);
end;

class procedure TD3TriggerTimer.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Timer,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerTimer(ATarget).EventTimer;
    end);
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerTimer(ATarget).EventUse(TD3TriggerTimer(ATarget).EntityFromArg(AArgs[0]));
    end);
end;

procedure TD3TriggerTimer.Enable;
begin
  // if off, turn it on
  if not FOn then
  begin
    FOn := True;
    PostEventSec(Game.GetEvents.Timer, FDelay);
  end;
end;

procedure TD3TriggerTimer.Disable;
begin
  // if on, turn it off
  if FOn then
  begin
    FOn := False;
    CancelEvent(Game.GetEvents.Timer);
  end;
end;

procedure TD3TriggerTimer.EventTimer;
begin
  ActivateTargets(Self);

  // set time before next firing
  if FWait >= 0.0 then
    PostEventSec(Game.GetEvents.Timer, FWait + Game.CRandomFloat * FRandom);
end;

procedure TD3TriggerTimer.EventUse(const AActivator: TD3Entity);
var
  LActivatorName: AnsiString;
begin
  // the original reads the name of the activator even when it is null (a crash); no name never matches here
  if Assigned(AActivator) then
    LActivatorName := AActivator.GetName
  else
    LActivatorName := #1;
  // if on, turn it off
  if FOn then
  begin
    if (Length(FOffName) > 0) and (not SameText(string(FOffName), string(LActivatorName))) then
      Exit;
    FOn := False;
    CancelEvent(Game.GetEvents.Timer);
  end
  else
  begin
    // turn it on
    if (Length(FOnName) > 0) and (not SameText(string(FOnName), string(LActivatorName))) then
      Exit;
    FOn := True;
    PostEventSec(Game.GetEvents.Timer, FDelay);
  end;
end;

end.
