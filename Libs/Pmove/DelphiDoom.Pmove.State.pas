{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the state shared by the parts of the movement   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the globals pm, }
{  pml, c_pmove and the pm_* parameters of bg_pmove.c. Copyright (C)           }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.State;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Logging.Intf, DelphiDoom.Pmove.Types,
  DelphiDoom.Pmove.Intf;

type
  /// <summary>
  ///   What the globals of bg_pmove.c are in the original: the pmove_t being executed (pm), the locals of the
  ///   step (pml), the counter (c_pmove) and the parameters, plus the world and the log. The parts of the
  ///   movement share one instance; nothing else is global, so two movers never meet
  /// </summary>
  TPmoveState = class
  strict private
    FPm: TPmove;
    FPml: TPmoveLocals;
    FTuning: TPmoveTuning;
    FTrace: IPmoveTrace;
    FItems: IPmoveItemCatalog;
    FLog: ILog;
    FCounter: Integer;
    function GetPm: PPmove;
    function GetPml: PPmoveLocals;
    function GetTuning: TPmoveTuning;
    function GetOrigin: PQ3Vec3;
    function GetVelocity: PQ3Vec3;
    function GetViewAngles: PQ3Vec3;
    function GetGrapplePoint: PQ3Vec3;
  public
    /// <summary>ALog may be nil (the diagnostic lines of DebugLevel are dropped)</summary>
    constructor Create(const ATrace: IPmoveTrace; const AItems: IPmoveItemCatalog; const ATuning: TPmoveTuning;
      const ALog: ILog);
    /// <summary>pm: the pmove_t of the step; the pointer stays valid as long as the state does</summary>
    property Pm: PPmove read GetPm;
    /// <summary>pml: zeroed at the start of each step</summary>
    property Pml: PPmoveLocals read GetPml;
    property Tuning: TPmoveTuning read GetTuning;
    /// <summary>
    ///   ps->origin, ps->velocity, ps->viewangles and ps->grapplePoint as vectors of the collision library (the
    ///   player state record has array types of its own, which do not convert)
    /// </summary>
    property Origin: PQ3Vec3 read GetOrigin;
    property Velocity: PQ3Vec3 read GetVelocity;
    property ViewAngles: PQ3Vec3 read GetViewAngles;
    property GrapplePoint: PQ3Vec3 read GetGrapplePoint;
    /// <summary>c_pmove</summary>
    property Counter: Integer read FCounter write FCounter;
    /// <summary>pm->trace with the entity of the player and the mask of the move</summary>
    function Trace(const AStart, AMins, AMaxs, AEnd: TQ3Vec3): TQ3Trace;
    /// <summary>pm->pointcontents with the entity of the player</summary>
    function PointContents(const APoint: TQ3Vec3): Integer;
    /// <summary>giTag of bg_itemlist</summary>
    function ItemTag(const AIndex: Integer): Integer;
    /// <summary>Com_Printf of the diagnostic lines (DebugLevel not zero)</summary>
    procedure DebugPrint(const AText: string);
    /// <summary>pm->debugLevel as a test</summary>
    function Debugging: Boolean;
  end;

implementation

constructor TPmoveState.Create(const ATrace: IPmoveTrace; const AItems: IPmoveItemCatalog;
  const ATuning: TPmoveTuning; const ALog: ILog);
begin
  inherited Create;
  Assert(Assigned(ATrace));
  FTrace := ATrace;
  FItems := AItems;
  FTuning := ATuning;
  FLog := ALog;
end;

function TPmoveState.GetPm: PPmove;
begin
  Result := @FPm;
end;

function TPmoveState.GetPml: PPmoveLocals;
begin
  Result := @FPml;
end;

function TPmoveState.GetTuning: TPmoveTuning;
begin
  Result := FTuning;
end;

function TPmoveState.GetOrigin: PQ3Vec3;
begin
  Result := PQ3Vec3(@FPm.Ps.Origin);
end;

function TPmoveState.GetVelocity: PQ3Vec3;
begin
  Result := PQ3Vec3(@FPm.Ps.Velocity);
end;

function TPmoveState.GetViewAngles: PQ3Vec3;
begin
  Result := PQ3Vec3(@FPm.Ps.ViewAngles);
end;

function TPmoveState.GetGrapplePoint: PQ3Vec3;
begin
  Result := PQ3Vec3(@FPm.Ps.GrapplePoint);
end;

function TPmoveState.Trace(const AStart, AMins, AMaxs, AEnd: TQ3Vec3): TQ3Trace;
begin
  Result := FTrace.Trace(AStart, AMins, AMaxs, AEnd, FPm.Ps.ClientNum, FPm.TraceMask);
end;

function TPmoveState.PointContents(const APoint: TQ3Vec3): Integer;
begin
  Result := FTrace.PointContents(APoint, FPm.Ps.ClientNum);
end;

function TPmoveState.ItemTag(const AIndex: Integer): Integer;
begin
  if Assigned(FItems) then
    Result := FItems.GameTag(AIndex)
  else
    Result := 0;
end;

function TPmoveState.Debugging: Boolean;
begin
  Result := FPm.DebugLevel <> 0;
end;

procedure TPmoveState.DebugPrint(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText);
end;

end.
