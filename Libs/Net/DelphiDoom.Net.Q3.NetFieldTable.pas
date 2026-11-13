{******************************************************************************}
{                                                                              }
{  DelphiDoom: net library - the field tables of the deltas of Quake III       }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): msg.c           }
{  (entityStateFields, playerStateFields). Copyright (C) 1999-2005 id          }
{  Software, Inc.                                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Net.Q3.NetFieldTable;

interface

uses
  System.SysUtils, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.Intf;

type
  /// <summary>
  ///   entityStateFields or playerStateFields: the order of the fields is the order of the wire (a field
  ///   that changes often comes first, so that the count of changed fields stays small) and must not be
  ///   changed. The offsets are those of the Delphi records, taken from a record, not typed
  /// </summary>
  TQ3NetFieldTable = class(TInterfacedObject, IQ3NetFieldTable)
  strict private
    FFields: TArray<TQ3NetField>;
    procedure Add(const AName: string; const ARecord; const AField; ABits: Integer);
    procedure FillEntityState;
    procedure FillPlayerState;
  public
    /// <summary>The table of entityState_t (51 fields)</summary>
    class function ForEntityState: IQ3NetFieldTable; static;
    /// <summary>The table of playerState_t (48 fields)</summary>
    class function ForPlayerState: IQ3NetFieldTable; static;
    function Count: Integer;
    function GetField(AIndex: Integer): TQ3NetField;
  end;

implementation

{ TQ3NetFieldTable }

class function TQ3NetFieldTable.ForEntityState: IQ3NetFieldTable;
var
  LTable: TQ3NetFieldTable;
begin
  LTable := TQ3NetFieldTable.Create;
  LTable.FillEntityState;
  Result := LTable;
end;

class function TQ3NetFieldTable.ForPlayerState: IQ3NetFieldTable;
var
  LTable: TQ3NetFieldTable;
begin
  LTable := TQ3NetFieldTable.Create;
  LTable.FillPlayerState;
  Result := LTable;
end;

procedure TQ3NetFieldTable.Add(const AName: string; const ARecord; const AField; ABits: Integer);
var
  LField: TQ3NetField;
begin
  LField.Name := AName;
  LField.Offset := Integer(NativeInt(@AField) - NativeInt(@ARecord));
  LField.Bits := ABits;
  SetLength(FFields, Length(FFields) + 1);
  FFields[High(FFields)] := LField;
end;

procedure TQ3NetFieldTable.FillEntityState;
var
  E: TQ3EntityState;
begin
  FillChar(E, SizeOf(E), 0);
  Add('pos.trTime', E, E.Pos.TrTime, 32);
  Add('pos.trBase[0]', E, E.Pos.TrBase[0], 0);
  Add('pos.trBase[1]', E, E.Pos.TrBase[1], 0);
  Add('pos.trDelta[0]', E, E.Pos.TrDelta[0], 0);
  Add('pos.trDelta[1]', E, E.Pos.TrDelta[1], 0);
  Add('pos.trBase[2]', E, E.Pos.TrBase[2], 0);
  Add('apos.trBase[1]', E, E.Apos.TrBase[1], 0);
  Add('pos.trDelta[2]', E, E.Pos.TrDelta[2], 0);
  Add('apos.trBase[0]', E, E.Apos.TrBase[0], 0);
  Add('event', E, E.Event, 10);
  Add('angles2[1]', E, E.Angles2[1], 0);
  Add('eType', E, E.EType, 8);
  Add('torsoAnim', E, E.TorsoAnim, 8);
  Add('eventParm', E, E.EventParm, 8);
  Add('legsAnim', E, E.LegsAnim, 8);
  Add('groundEntityNum', E, E.GroundEntityNum, Q3_GENTITYNUM_BITS);
  Add('pos.trType', E, E.Pos.TrType, 8);
  Add('eFlags', E, E.EFlags, 19);
  Add('otherEntityNum', E, E.OtherEntityNum, Q3_GENTITYNUM_BITS);
  Add('weapon', E, E.Weapon, 8);
  Add('clientNum', E, E.ClientNum, 8);
  Add('angles[1]', E, E.Angles[1], 0);
  Add('pos.trDuration', E, E.Pos.TrDuration, 32);
  Add('apos.trType', E, E.Apos.TrType, 8);
  Add('origin[0]', E, E.Origin[0], 0);
  Add('origin[1]', E, E.Origin[1], 0);
  Add('origin[2]', E, E.Origin[2], 0);
  Add('solid', E, E.Solid, 24);
  Add('powerups', E, E.Powerups, 16);
  Add('modelindex', E, E.ModelIndex, 8);
  Add('otherEntityNum2', E, E.OtherEntityNum2, Q3_GENTITYNUM_BITS);
  Add('loopSound', E, E.LoopSound, 8);
  Add('generic1', E, E.Generic1, 8);
  Add('origin2[2]', E, E.Origin2[2], 0);
  Add('origin2[0]', E, E.Origin2[0], 0);
  Add('origin2[1]', E, E.Origin2[1], 0);
  Add('modelindex2', E, E.ModelIndex2, 8);
  Add('angles[0]', E, E.Angles[0], 0);
  Add('time', E, E.Time, 32);
  Add('apos.trTime', E, E.Apos.TrTime, 32);
  Add('apos.trDuration', E, E.Apos.TrDuration, 32);
  Add('apos.trBase[2]', E, E.Apos.TrBase[2], 0);
  Add('apos.trDelta[0]', E, E.Apos.TrDelta[0], 0);
  Add('apos.trDelta[1]', E, E.Apos.TrDelta[1], 0);
  Add('apos.trDelta[2]', E, E.Apos.TrDelta[2], 0);
  Add('time2', E, E.Time2, 32);
  Add('angles[2]', E, E.Angles[2], 0);
  Add('angles2[0]', E, E.Angles2[0], 0);
  Add('angles2[2]', E, E.Angles2[2], 0);
  Add('constantLight', E, E.ConstantLight, 32);
  Add('frame', E, E.Frame, 16);
end;

procedure TQ3NetFieldTable.FillPlayerState;
var
  P: TQ3PlayerState;
begin
  FillChar(P, SizeOf(P), 0);
  Add('commandTime', P, P.CommandTime, 32);
  Add('origin[0]', P, P.Origin[0], 0);
  Add('origin[1]', P, P.Origin[1], 0);
  Add('bobCycle', P, P.BobCycle, 8);
  Add('velocity[0]', P, P.Velocity[0], 0);
  Add('velocity[1]', P, P.Velocity[1], 0);
  Add('viewangles[1]', P, P.ViewAngles[1], 0);
  Add('viewangles[0]', P, P.ViewAngles[0], 0);
  Add('weaponTime', P, P.WeaponTime, -16);
  Add('origin[2]', P, P.Origin[2], 0);
  Add('velocity[2]', P, P.Velocity[2], 0);
  Add('legsTimer', P, P.LegsTimer, 8);
  Add('pm_time', P, P.PmTime, -16);
  Add('eventSequence', P, P.EventSequence, 16);
  Add('torsoAnim', P, P.TorsoAnim, 8);
  Add('movementDir', P, P.MovementDir, 4);
  Add('events[0]', P, P.Events[0], 8);
  Add('legsAnim', P, P.LegsAnim, 8);
  Add('events[1]', P, P.Events[1], 8);
  Add('pm_flags', P, P.PmFlags, 16);
  Add('groundEntityNum', P, P.GroundEntityNum, Q3_GENTITYNUM_BITS);
  Add('weaponstate', P, P.WeaponState, 4);
  Add('eFlags', P, P.EFlags, 16);
  Add('externalEvent', P, P.ExternalEvent, 10);
  Add('gravity', P, P.Gravity, 16);
  Add('speed', P, P.Speed, 16);
  Add('delta_angles[1]', P, P.DeltaAngles[1], 16);
  Add('externalEventParm', P, P.ExternalEventParm, 8);
  Add('viewheight', P, P.ViewHeight, -8);
  Add('damageEvent', P, P.DamageEvent, 8);
  Add('damageYaw', P, P.DamageYaw, 8);
  Add('damagePitch', P, P.DamagePitch, 8);
  Add('damageCount', P, P.DamageCount, 8);
  Add('generic1', P, P.Generic1, 8);
  Add('pm_type', P, P.PmType, 8);
  Add('delta_angles[0]', P, P.DeltaAngles[0], 16);
  Add('delta_angles[2]', P, P.DeltaAngles[2], 16);
  Add('torsoTimer', P, P.TorsoTimer, 12);
  Add('eventParms[0]', P, P.EventParms[0], 8);
  Add('eventParms[1]', P, P.EventParms[1], 8);
  Add('clientNum', P, P.ClientNum, 8);
  Add('weapon', P, P.Weapon, 5);
  Add('viewangles[2]', P, P.ViewAngles[2], 0);
  Add('grapplePoint[0]', P, P.GrapplePoint[0], 0);
  Add('grapplePoint[1]', P, P.GrapplePoint[1], 0);
  Add('grapplePoint[2]', P, P.GrapplePoint[2], 0);
  Add('jumppad_ent', P, P.JumppadEnt, 10);
  Add('loopSound', P, P.LoopSound, 16);
end;

function TQ3NetFieldTable.Count: Integer;
begin
  Result := Length(FFields);
end;

function TQ3NetFieldTable.GetField(AIndex: Integer): TQ3NetField;
begin
  Result := FFields[AIndex];
end;

end.
