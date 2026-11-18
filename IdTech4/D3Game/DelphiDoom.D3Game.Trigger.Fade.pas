{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idTrigger_Fade                            }
{                                                                              }
{  Port of Doom 3 (id Software): game\Trigger.cpp (idTrigger_Fade, the class   }
{  of trigger_fade). It fades the view of the local player and then activates  }
{  its targets: there is no local player in this game, so it does nothing, as  }
{  the original does with <c>GetLocalPlayer()</c> null (a dedicated server).   }
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
unit DelphiDoom.D3Game.Trigger.Fade;

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.ClassBase,
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Trigger;

type
  /// <summary>idTrigger_Fade: the body of the original with a local player that is always missing</summary>
  TD3TriggerFade = class(TD3Trigger)
  strict private
    procedure EventTrigger(const AActivator: TD3Entity);
  protected
    /// <summary>gameLocal.GetLocalPlayer(): nil (no player in this phase)</summary>
    function GetLocalPlayer: TD3Entity; virtual;
  public
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
  end;

implementation

class procedure TD3TriggerFade.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3TriggerFade(ATarget).EventTrigger(TD3TriggerFade(ATarget).EntityFromArg(AArgs[0]));
    end);
end;

function TD3TriggerFade.GetLocalPlayer: TD3Entity;
begin
  Result := nil;
end;

procedure TD3TriggerFade.EventTrigger(const AActivator: TD3Entity);
var
  LFadeTime: Integer;
  LPlayer: TD3Entity;
begin
  LPlayer := GetLocalPlayer;
  if Assigned(LPlayer) then
  begin
    // player->playerView.Fade( fadeColor, fadeTime ): no view to fade
    LFadeTime := TDoomScriptConvert.SecToMs(SpawnArgs.GetFloat('fadeTime', '0.5'));
    PostEventMS(Game.GetEvents.ActivateTargets, LFadeTime, [EntityArg(AActivator)]);
  end;
end;

end.
