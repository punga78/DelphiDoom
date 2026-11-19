{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the events of the entity classes          }
{                                                                              }
{  Port of Doom 3 (id Software): the idEventDef definitions of game\Entity.cpp, }
{  game\Trigger.cpp and game\Mover.cpp that the entity classes use (the other  }
{  events of the files are not ported).                                        }
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
unit DelphiDoom.D3Game.EntityEvents;

interface

uses
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.EventRegistry;

type
  /// <summary>
  ///   The <c>idEventDef</c> constants (<c>EV_Activate</c>, <c>EV_Hide</c>, ...) that the entity classes post and
  ///   process, defined in the event registry of the game (a definition that exists with the same name and format is
  ///   shared: <c>activate</c> and <c>enable</c> are also defined by the script system and by two classes). Define them
  ///   before the scripts are compiled: a <c>scriptEvent</c> is looked up by name.
  /// </summary>
  TD3EntityEvents = class
  public
    /// <summary>EV_Remove of idClass (the immediate one, <c>&lt;immediateremove&gt;</c>): shared with the class system</summary>
    Remove,
    // idEntity
    FindTargets, Touch, GetName, SetName, Activate, ActivateTargets, NumTargets, GetTarget, IsHidden, Hide, Show,
    // idTrigger
    Enable, Disable, TriggerAction, Timer,
    // idMover, idMover_Binary, idDoor
    ReachedPos, ReachedAng, ReturnToPos1, MatchTeam, StartOpen, SpawnDoorTrigger, DoorOpen, DoorClose, DoorLock,
    DoorIsOpen, DoorIsLocked, StopMoving, Speed, Time, AccelTime, DecelTime, MoveTo, MoveToPos, Move,
    IsMoving, SetCallback,
    // idEntity (binding) and idMover (rotation)
    Bind, BindPosition, Unbind, RemoveBinds, SpawnBind, StopRotating, RotateDownTo, RotateUpTo, RotateTo, Rotate,
    RotateOnce, IsRotating: TDoomScriptEventDef;
    constructor Create(const AEvents: TDoomScriptEventRegistry);
  end;

implementation

constructor TD3EntityEvents.Create(const AEvents: TDoomScriptEventRegistry);
begin
  inherited Create;
  Remove := AEvents.Define('<immediateremove>');
  FindTargets := AEvents.Define('<findTargets>');
  Touch := AEvents.Define('<touch>', 'et');
  GetName := AEvents.Define('getName', '', 's');
  SetName := AEvents.Define('setName', 's');
  Activate := AEvents.Define('activate', 'e');
  ActivateTargets := AEvents.Define('activateTargets', 'e');
  NumTargets := AEvents.Define('numTargets', '', 'f');
  GetTarget := AEvents.Define('getTarget', 'f', 'e');
  IsHidden := AEvents.Define('isHidden', '', 'd');
  Hide := AEvents.Define('hide');
  Show := AEvents.Define('show');
  Enable := AEvents.Define('enable');
  Disable := AEvents.Define('disable');
  TriggerAction := AEvents.Define('<triggerAction>', 'e');
  Timer := AEvents.Define('<timer>');
  ReachedPos := AEvents.Define('<reachedpos>');
  ReachedAng := AEvents.Define('<reachedang>');
  ReturnToPos1 := AEvents.Define('<returntopos1>');
  MatchTeam := AEvents.Define('<matchteam>', 'dd');
  StartOpen := AEvents.Define('<startOpen>');
  SpawnDoorTrigger := AEvents.Define('<spawnDoorTrigger>');
  DoorOpen := AEvents.Define('open');
  DoorClose := AEvents.Define('close');
  DoorLock := AEvents.Define('lock', 'd');
  DoorIsOpen := AEvents.Define('isOpen', '', 'f');
  DoorIsLocked := AEvents.Define('isLocked', '', 'f');
  StopMoving := AEvents.Define('stopMoving');
  Speed := AEvents.Define('speed', 'f');
  Time := AEvents.Define('time', 'f');
  AccelTime := AEvents.Define('accelTime', 'f');
  DecelTime := AEvents.Define('decelTime', 'f');
  MoveTo := AEvents.Define('moveTo', 'e');
  MoveToPos := AEvents.Define('moveToPos', 'v');
  Move := AEvents.Define('move', 'ff');
  IsMoving := AEvents.Define('isMoving', '', 'd');
  SetCallback := AEvents.Define('<script_setcallback>');
  Bind := AEvents.Define('bind', 'e');
  BindPosition := AEvents.Define('bindPosition', 'e');
  Unbind := AEvents.Define('unbind');
  RemoveBinds := AEvents.Define('removeBinds');
  SpawnBind := AEvents.Define('<spawnbind>');
  StopRotating := AEvents.Define('stopRotating');
  RotateDownTo := AEvents.Define('rotateDownTo', 'df');
  RotateUpTo := AEvents.Define('rotateUpTo', 'df');
  RotateTo := AEvents.Define('rotateTo', 'v');
  Rotate := AEvents.Define('rotate', 'v');
  RotateOnce := AEvents.Define('rotateOnce', 'v');
  IsRotating := AEvents.Define('isRotating', '', 'd');
end;

end.
