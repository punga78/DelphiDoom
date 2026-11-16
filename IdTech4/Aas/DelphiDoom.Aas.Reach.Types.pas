{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - types and constants of the reachability           }
{  calculation                                                                 }
{                                                                              }
{  Port of the constants and of aas_lreachability_t of be_aas_reach.c. Based   }
{  on the Quake III Arena GPL Source Code (id Software). Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Types;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types;

const
  /// <summary>AAS_MAX_REACHABILITYSIZE: the number of links of the heap</summary>
  AAS_MAX_REACHABILITYSIZE = 65536;
  /// <summary>REACHABILITYAREASPERCYCLE: defined and never used by the original</summary>
  REACHABILITYAREASPERCYCLE = 15;
  /// <summary>INSIDEUNITS: the number of units reachability points are placed inside the areas</summary>
  INSIDEUNITS = 2;
  INSIDEUNITS_WALKEND = 5;
  INSIDEUNITS_WATERJUMP = 15;
  /// <summary>AREA_WEAPONJUMP: area flag, a valid area to weapon jump to</summary>
  AREA_WEAPONJUMP = 8192;
  /// <summary>MAX_EPAIRKEY: the size of the buffers the values of the BSP entities are copied to</summary>
  MAX_EPAIRKEY = 128;
  /// <summary>SURF_SKY of surfaceflags.h</summary>
  SURF_SKY = 4;
  /// <summary>INSIDEUNITS_WALKSTART: 0.1 in the original, a double</summary>
  INSIDEUNITS_WALKSTART: Double = 0.1;
  /// <summary>framereachability: the number of areas of one call of ContinueInitReachability</summary>
  AAS_REACH_AREAS_PER_CALL = 2000;
  /// <summary>reachability_delay: the milliseconds after which a call stops</summary>
  AAS_REACH_DELAY_MILLISECONDS = 1000;

type
  PAasLinkedReach = ^TAasLinkedReach;

  /// <summary>
  ///   aas_lreachability_t: a reachability that is in a list (the list of an area); Next is the pointer of the
  ///   original and points into the heap
  /// </summary>
  TAasLinkedReach = record
    AreaNum: Integer;
    FaceNum: Integer;
    EdgeNum: Integer;
    Start: TVec3;
    EndPoint: TVec3;
    TravelType: Integer;
    TravelTime: Word;
    Next: PAasLinkedReach;
  end;

  PAasReachCounters = ^TAasReachCounters;

  /// <summary>reach_swim ... reach_jumppad: the number of reachabilities of each type</summary>
  TAasReachCounters = record
    Swim: Integer;
    EqualFloor: Integer;
    Step: Integer;
    Walk: Integer;
    Barrier: Integer;
    WaterJump: Integer;
    WalkOffLedge: Integer;
    Jump: Integer;
    Ladder: Integer;
    Teleport: Integer;
    Elevator: Integer;
    FuncBob: Integer;
    Grapple: Integer;
    DoubleJump: Integer;
    RampJump: Integer;
    StrafeJump: Integer;
    RocketJump: Integer;
    BfgJump: Integer;
    JumpPad: Integer;
  end;

  /// <summary>A file that cannot be worked on (an index outside a table) or a heap that was used past its end</summary>
  EAasReachException = class(Exception);

  /// <summary>Sys_MilliSeconds: the time of the calculation, given from outside</summary>
  TAasMilliseconds = reference to function: Integer;

implementation

end.
