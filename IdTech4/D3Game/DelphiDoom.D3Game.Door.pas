{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idDoor                                    }
{                                                                              }
{  Port of Doom 3 (id Software): game\Mover.h, Mover.cpp (idDoor, the class of }
{  func_door). The trigger clip models (touch to open), sounds, area portals,  }
{  the AAS area state, the team hide and the companion doors are not ported:   }
{  a door opens by <c>activate</c>, <c>open</c> or a trigger that targets it.  }
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
unit DelphiDoom.D3Game.Door;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef,
  DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.Entity,
  DelphiDoom.D3Game.MoverBinary;

type
  /// <summary>
  ///   idDoor: a binary mover that opens by <c>lip</c> units short of its own size along <c>movedir</c> (or
  ///   <c>angle</c>), in <c>time</c> seconds or at <c>speed</c>. It can start open, be locked, wait <c>wait</c> seconds
  ///   (3 by default) before it closes, and fires the entities named by <c>triggerOpened</c> and
  ///   <c>triggerClosed</c> when it gets there.
  /// </summary>
  TD3Door = class(TD3MoverBinary)
  strict private
    FTriggerSize: Single;
    FCrusher: Boolean;
    FNoTouch: Boolean;
    FBuddy: AnsiString;
    FSyncLock: AnsiString;
    FRequires: AnsiString;
    FRemoveItem: Integer;
    procedure EventActivate(const AActivator: TD3Entity);
    procedure EventStartOpen;
    procedure EventSpawnDoorTrigger;
    procedure NotifyEntities(const APrefix: AnsiString);
  protected
    procedure EventReachedBinaryMover; override;
  public
    /// <summary>idDoor::Spawn</summary>
    class procedure SpawnClass(const AInstance: TD3Class); static;
    class procedure DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents); static;
    /// <summary>idDoor::Open</summary>
    procedure Open;
    /// <summary>idDoor::Close</summary>
    procedure Close;
    /// <summary>idDoor::Lock: every door of the team gets the lock; a lock closes the door</summary>
    procedure Lock(const AValue: Integer);
    function IsLocked: Integer;
    /// <summary>idDoor::IsOpen: anything but resting at pos1</summary>
    function IsOpen: Boolean;
    function IsNoTouch: Boolean;
  end;

implementation

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.D3Game.Types;

function IntArg(const AValue: Integer): TDoomScriptEventArg;
begin
  Result := Default(TDoomScriptEventArg);
  Result.Kind := DS_EVENT_INTEGER;
  Result.IntValue := AValue;
end;

class procedure TD3Door.SpawnClass(const AInstance: TD3Class);
var
  LSelf: TD3Door;
  LMovedir: TIdVec3;
  LAbsMovedir: TIdVec3;
  LSize: TIdVec3;
  LDir: Single;
  LLip: Single;
  LSpeed: Single;
  LTime: Single;
  LDistance: Single;
  LWait: Single;
  LDamage: Single;
  LStartOpen: Boolean;
  LPos1: TIdVec3;
  LPos2: TIdVec3;
  LLocked: Integer;
begin
  LSelf := TD3Door(AInstance);

  // get the direction to move
  if not LSelf.SpawnArgs.GetFloat('movedir', '0', LDir) then
    // no movedir, so angle defines movement direction and not orientation, a la oldschool Quake
    LSelf.SpawnArgs.GetFloat('angle', '0', LDir);
  LMovedir := GetMovedir(LDir);

  // default speed of 400
  LSelf.SpawnArgs.GetFloat('speed', '400', LSpeed);
  // default wait of 2 seconds
  LSelf.SpawnArgs.GetFloat('wait', '3', LWait);
  LSelf.Wait := LWait;
  // default lip of 8 units
  LSelf.SpawnArgs.GetFloat('lip', '8', LLip);
  // by default no damage
  LSelf.SpawnArgs.GetFloat('damage', '0', LDamage);
  // trigger size
  LSelf.SpawnArgs.GetFloat('triggersize', '120', LSelf.FTriggerSize);
  LSelf.SpawnArgs.GetBool('crusher', '0', LSelf.FCrusher);
  LSelf.SpawnArgs.GetBool('start_open', '0', LStartOpen);
  LSelf.SpawnArgs.GetBool('no_touch', '0', LSelf.FNoTouch);
  // expects syncLock to be a door that must be closed before this door will open
  LSelf.SpawnArgs.GetString('syncLock', '', LSelf.FSyncLock);
  LSelf.SpawnArgs.GetString('buddy', '', LSelf.FBuddy);
  LSelf.SpawnArgs.GetString('requires', '', LSelf.FRequires);
  LSelf.SpawnArgs.GetInt('removeItem', '0', LSelf.FRemoveItem);

  // first position at start
  LPos1 := LSelf.GetPhysics.GetOrigin;

  // calculate second position
  LAbsMovedir.SetValues(Abs(LMovedir.X), Abs(LMovedir.Y), Abs(LMovedir.Z));
  LSize := LSelf.GetPhysics.GetAbsBoundsMax - LSelf.GetPhysics.GetAbsBoundsMin;
  LDistance := (LAbsMovedir * LSize) - LLip;
  LPos2 := LPos1 + LMovedir * LDistance;

  // if "start_open", reverse position 1 and 2
  if LStartOpen then
    // post it after EV_SpawnBind
    LSelf.PostEventMS(LSelf.Game.GetEvents.StartOpen, 1);

  if LSelf.SpawnArgs.GetFloat('time', '1', LTime) then
    LSelf.InitTime(LPos1, LPos2, LTime, 0, 0)
  else
    LSelf.InitSpeed(LPos1, LPos2, LSpeed, 0, 0);

  if LSelf.MoveMaster = LSelf then
  begin
    if LSelf.FNoTouch or (LSelf.Health <> 0) then
      // non touch/shoot doors
      LSelf.PostEventMS(LSelf.Game.GetEvents.MatchTeam, 0, [IntArg(Ord(LSelf.MoverState)),
        IntArg(LSelf.Game.GetTime)])
    else
      // spawn trigger
      LSelf.PostEventMS(LSelf.Game.GetEvents.SpawnDoorTrigger, 0);
  end;

  LLocked := LSelf.SpawnArgs.GetInt('locked');
  if LLocked <> 0 then
    // make sure all members of the team get locked
    LSelf.PostEventMS(LSelf.Game.GetEvents.DoorLock, 0, [IntArg(LLocked)]);

  if LSelf.SpawnArgs.GetBool('continuous') then
    LSelf.PostEventSec(LSelf.Game.GetEvents.Activate, LSelf.SpawnArgs.GetFloat('delay'), [EntityArg(LSelf)]);

  LSelf.Enabled := True;
end;

class procedure TD3Door.DeclareEvents(const AType: TD3TypeInfo; const AEvents: TD3EntityEvents);
begin
  AType.AddEvent(AEvents.Activate,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Door(ATarget).EventActivate(TD3Door(ATarget).EntityFromArg(AArgs[0]));
    end);
  AType.AddEvent(AEvents.StartOpen,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Door(ATarget).EventStartOpen;
    end);
  AType.AddEvent(AEvents.SpawnDoorTrigger,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Door(ATarget).EventSpawnDoorTrigger;
    end);
  AType.AddEvent(AEvents.DoorOpen,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Door(ATarget).Open;
    end);
  AType.AddEvent(AEvents.DoorClose,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Door(ATarget).Close;
    end);
  AType.AddEvent(AEvents.DoorLock,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    begin
      TD3Door(ATarget).Lock(AArgs[0].IntValue);
    end);
  AType.AddEvent(AEvents.DoorIsOpen,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThreads: ID3ScriptThreads;
    begin
      LThreads := TD3Door(ATarget).Game.GetScriptThreads;
      if Assigned(LThreads) then
        LThreads.ReturnFloat(Ord(TD3Door(ATarget).IsOpen));
    end);
  AType.AddEvent(AEvents.DoorIsLocked,
    procedure(const ATarget: TD3Class; const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs)
    var
      LThreads: ID3ScriptThreads;
    begin
      LThreads := TD3Door(ATarget).Game.GetScriptThreads;
      if Assigned(LThreads) then
        LThreads.ReturnFloat(TD3Door(ATarget).IsLocked);
    end);
end;

procedure TD3Door.Open;
begin
  GotoPosition2;
end;

procedure TD3Door.Close;
begin
  GotoPosition1;
end;

procedure TD3Door.Lock(const AValue: Integer);
var
  LOther: TD3MoverBinary;
begin
  // lock all the doors on the team
  LOther := MoveMaster;
  while Assigned(LOther) do
  begin
    if LOther is TD3Door then
      TD3Door(LOther).SpawnArgs.SetInt('locked', AValue);
    LOther := LOther.ActivateChain;
  end;
  if AValue <> 0 then
    Close;
end;

function TD3Door.IsLocked: Integer;
begin
  Result := SpawnArgs.GetInt('locked');
end;

function TD3Door.IsOpen: Boolean;
begin
  Result := MoverState <> msPos1;
end;

function TD3Door.IsNoTouch: Boolean;
begin
  Result := FNoTouch;
end;

procedure TD3Door.EventActivate(const AActivator: TD3Entity);
var
  LOldLock: Integer;
  LSync: TD3Entity;
begin
  if SpawnArgs.GetInt('locked') <> 0 then
  begin
    if Length(FBuddy) > 0 then
      // the buddy's shader parm is not ported
      Game.FindEntity(FBuddy);
    LOldLock := SpawnArgs.GetInt('locked');
    Lock(0);
    if LOldLock = 2 then
      Exit;
  end;

  if Length(FSyncLock) > 0 then
  begin
    LSync := Game.FindEntity(FSyncLock);
    if Assigned(LSync) and (LSync is TD3Door) and TD3Door(LSync).IsOpen then
      Exit;
  end;

  ActivateTargets(AActivator);
  UseBinaryMover(AActivator);
end;

procedure TD3Door.EventStartOpen;
var
  LTime: Single;
  LSpeed: Single;
  LPos1: TIdVec3;
  LPos2: TIdVec3;
begin
  // if "start_open", reverse position 1 and 2
  LPos1 := Pos2;
  LPos2 := GetPhysics.GetOrigin;
  SpawnArgs.GetFloat('speed', '400', LSpeed);
  if SpawnArgs.GetFloat('time', '1', LTime) then
    InitTime(LPos1, LPos2, LTime, 0, 0)
  else
    InitSpeed(LPos1, LPos2, LSpeed, 0, 0);
end;

procedure TD3Door.EventSpawnDoorTrigger;
var
  LOther: TD3MoverBinary;
  LToggle: Boolean;
begin
  // check if any of the doors are marked as toggled
  LToggle := False;
  LOther := MoveMaster;
  while Assigned(LOther) do
  begin
    if (LOther is TD3Door) and LOther.SpawnArgs.GetBool('toggle') then
    begin
      LToggle := True;
      Break;
    end;
    LOther := LOther.ActivateChain;
  end;

  if LToggle then
  begin
    // mark them all as toggled
    LOther := MoveMaster;
    while Assigned(LOther) do
    begin
      if LOther is TD3Door then
        LOther.SpawnArgs.SetValue('toggle', '1');
      LOther := LOther.ActivateChain;
    end;
    // don't spawn trigger
    Exit;
  end;

  // the trigger clip model is not ported
  MatchActivateTeam(MoverState, Game.GetTime);
end;

procedure TD3Door.NotifyEntities(const APrefix: AnsiString);
var
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
  LEntity: TD3Entity;
begin
  LIndex := SpawnArgs.MatchPrefix(APrefix);
  while LIndex >= 0 do
  begin
    if SpawnArgs.TryGetKeyVal(LIndex, LKeyValue) then
    begin
      LEntity := Game.FindEntity(LKeyValue.Value);
      if Assigned(LEntity) then
        LEntity.PostEventMS(Game.GetEvents.Activate, 0, [EntityArg(MoveMaster.GetActivator)]);
    end;
    LIndex := SpawnArgs.MatchPrefix(APrefix, LIndex);
  end;
end;

procedure TD3Door.EventReachedBinaryMover;
begin
  if MoverState = ms2To1 then
  begin
    SetBlocked(False);
    NotifyEntities('triggerClosed');
  end
  else if MoverState = ms1To2 then
    NotifyEntities('triggerOpened');
  inherited EventReachedBinaryMover;
end;

end.
