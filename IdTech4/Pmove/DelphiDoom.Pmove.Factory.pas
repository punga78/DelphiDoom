{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the player movement of Quake III Arena:         }
{  factory                                                                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): bg_pmove.c.     }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Intf, DelphiDoom.Logging.Intf, DelphiDoom.Pmove.Types,
  DelphiDoom.Pmove.Intf;

type
  /// <summary>The only place that knows the classes of the movement</summary>
  TPmoveFactory = class
  public
    /// <summary>
    ///   A mover on a world. AItems nil gives the item list of baseq3, ALog nil drops the diagnostic lines of
    ///   DebugLevel; the parameters are those of bg_pmove.c. The mover is not thread safe (one per thread)
    /// </summary>
    class function CreateMover(const ATrace: IPmoveTrace; const AItems: IPmoveItemCatalog = nil;
      const ALog: ILog = nil): IPmove; overload; static;
    class function CreateMover(const ATrace: IPmoveTrace; const AItems: IPmoveItemCatalog;
      const ATuning: TPmoveTuning; const ALog: ILog): IPmove; overload; static;
    /// <summary>A mover on the collision model of a map (the world only: see TPmoveCollisionTrace)</summary>
    class function CreateForMap(const AModel: IQ3CollisionModel; const ALog: ILog = nil): IPmove; static;
  end;

implementation

uses
  DelphiDoom.Pmove.State, DelphiDoom.Pmove.Parts, DelphiDoom.Pmove.Mover, DelphiDoom.Pmove.Items,
  DelphiDoom.Pmove.CollisionTrace;

class function TPmoveFactory.CreateMover(const ATrace: IPmoveTrace; const AItems: IPmoveItemCatalog;
  const ALog: ILog): IPmove;
begin
  Result := CreateMover(ATrace, AItems, TPmoveTuning.Default, ALog);
end;

class function TPmoveFactory.CreateMover(const ATrace: IPmoveTrace; const AItems: IPmoveItemCatalog;
  const ATuning: TPmoveTuning; const ALog: ILog): IPmove;
var
  LItems: IPmoveItemCatalog;
  LState: TPmoveState;
  LParts: TPmoveParts;
begin
  LItems := AItems;
  if not Assigned(LItems) then
    LItems := TPmoveBaseItemCatalog.Create;
  LState := TPmoveState.Create(ATrace, LItems, ATuning, ALog);
  try
    LParts := TPmoveParts.Create(LState);
  except
    LState.Free;
    raise;
  end;
  // the mover owns both from here
  Result := TPmover.Create(LState, LParts);
end;

class function TPmoveFactory.CreateForMap(const AModel: IQ3CollisionModel; const ALog: ILog): IPmove;
begin
  Result := CreateMover(TPmoveCollisionTrace.Create(AModel), nil, ALog);
end;

end.
