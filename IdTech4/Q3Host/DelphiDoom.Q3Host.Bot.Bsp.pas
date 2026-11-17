{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the world as the bot library sees it   }
{  (BotImport_Trace, BotImport_EntityTrace, BotImport_PointContents,           }
{  BotImport_inPVS, BotImport_BSPEntityData, BotImport_BSPModelMinsMaxsOrigin) }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): sv_bot.c.       }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.Bsp;

interface

uses
  System.SysUtils, DelphiDoom.Qvm.Intf, DelphiDoom.MathCore.Types, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Q3Host.Services.Intf,
  DelphiDoom.Q3Host.GameWorld;

type
  /// <summary>
  ///   The BSP the AAS and the bots ask: the traces go through the world of the server game (SV_Trace, so they meet
  ///   the entities of the module, which live in its memory: the host gives the memory of the module that is
  ///   calling with Attach before it answers a call), the point contents are SV_PointContents( point, -1 ), the
  ///   entity text, the bounds of a model and the PVS are the collision model's. The trace is copied as
  ///   BotImport_Trace copies it: <c>contents</c>, <c>sidenum</c> and <c>exp_dist</c> are 0
  /// </summary>
  TQ3BotBsp = class(TInterfacedObject, IAasBspWorld, IAasBspModels)
  strict private
    FWorld: TQ3GameWorld;
    FClipMap: IQ3HostClipMap;
    FMemory: IQvmMemory;
    function Memory: IQvmMemory;
    class function Convert(const ATrace: TQ3Trace): TAasBspTrace; static;
  public
    /// <summary>The world is not owned (the host owns it)</summary>
    constructor Create(const AWorld: TQ3GameWorld; const AClipMap: IQ3HostClipMap);
    /// <summary>The memory of the module that makes the call that is being answered</summary>
    procedure Attach(const AMemory: IQvmMemory);
    function PointContents(const APoint: TVec3): Integer;
    function Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
      AContentMask: Integer): TAasBspTrace;
    function EntityData: AnsiString;
    function EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
      AContentMask: Integer): TAasBspTrace;
    function InPVS(const AFirst, ASecond: TVec3): Boolean;
    procedure ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs, AOrigin: TVec3);
  end;

implementation

uses
  DelphiDoom.Aas.Bsp.CollisionModels, DelphiDoom.Q3Host.Types;

resourcestring
  SNoMemory = 'The bot library asked the world outside a system call of the module';
  SNoMap = 'The bot library asked the BSP before a map was loaded';

constructor TQ3BotBsp.Create(const AWorld: TQ3GameWorld; const AClipMap: IQ3HostClipMap);
begin
  inherited Create;
  FWorld := AWorld;
  FClipMap := AClipMap;
end;

procedure TQ3BotBsp.Attach(const AMemory: IQvmMemory);
begin
  FMemory := AMemory;
end;

function TQ3BotBsp.Memory: IQvmMemory;
begin
  if not Assigned(FMemory) then
    raise EQ3HostException.Create(SNoMemory);
  Result := FMemory;
end;

class function TQ3BotBsp.Convert(const ATrace: TQ3Trace): TAasBspTrace;
begin
  Result.AllSolid := ATrace.AllSolid;
  Result.StartSolid := ATrace.StartSolid;
  Result.Fraction := ATrace.Fraction;
  Result.EndPos := TVec3(ATrace.EndPos);
  Result.SurfaceFlags := ATrace.SurfaceFlags;
  Result.EntityNum := ATrace.EntityNum;
  Result.Contents := 0;
end;

function TQ3BotBsp.PointContents(const APoint: TVec3): Integer;
begin
  Result := FWorld.PointContents(Memory, TQ3Vec3(APoint), -1);
end;

function TQ3BotBsp.Trace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const APassEnt,
  AContentMask: Integer): TAasBspTrace;
var
  LMins, LMaxs: TQ3Vec3;
begin
  // SV_Trace: a nil box is vec3_origin
  LMins := Default(TQ3Vec3);
  LMaxs := Default(TQ3Vec3);
  if Assigned(AMins) then
    LMins := TQ3Vec3(AMins^);
  if Assigned(AMaxs) then
    LMaxs := TQ3Vec3(AMaxs^);
  Result := Convert(FWorld.Trace(Memory, TQ3Vec3(AStart), LMins, LMaxs, TQ3Vec3(AEnd), APassEnt, AContentMask,
    False));
end;

function TQ3BotBsp.EntityTrace(const AStart: TVec3; const AMins, AMaxs: PVec3; const AEnd: TVec3; const AEntNum,
  AContentMask: Integer): TAasBspTrace;
var
  LMins, LMaxs: TQ3Vec3;
begin
  LMins := Default(TQ3Vec3);
  LMaxs := Default(TQ3Vec3);
  if Assigned(AMins) then
    LMins := TQ3Vec3(AMins^);
  if Assigned(AMaxs) then
    LMaxs := TQ3Vec3(AMaxs^);
  Result := Convert(FWorld.ClipToEntity(Memory, TQ3Vec3(AStart), LMins, LMaxs, TQ3Vec3(AEnd), AEntNum,
    AContentMask, False));
end;

function TQ3BotBsp.EntityData: AnsiString;
begin
  if not Assigned(FClipMap.Model) then
    raise EQ3HostException.Create(SNoMap);
  Result := FClipMap.Model.GetEntityString;
end;

function TQ3BotBsp.InPVS(const AFirst, ASecond: TVec3): Boolean;
begin
  Result := FWorld.InPvs(TQ3Vec3(AFirst), TQ3Vec3(ASecond), False);
end;

procedure TQ3BotBsp.ModelMinsMaxsOrigin(const AModelNum: Integer; const AAngles: TVec3; out AMins, AMaxs,
  AOrigin: TVec3);
var
  LModels: IAasBspModels;
begin
  if not Assigned(FClipMap.Model) then
    raise EQ3HostException.Create(SNoMap);
  LModels := TAasCollisionModels.Create(FClipMap.Model);
  LModels.ModelMinsMaxsOrigin(AModelNum, AAngles, AMins, AMaxs, AOrigin);
end;

end.
