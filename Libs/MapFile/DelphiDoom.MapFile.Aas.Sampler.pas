{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - environment sampling of an .aas file         }
{                                                                              }
{  Port of PointAreaNum, PointReachableAreaNum, BoundsReachableAreaNum,        }
{  PushPointIntoAreaNum, AreaReachableGoal and Trace of idAASFileLocal         }
{  (AASFile_sample.cpp), Doom 3 GPL Source Code.                               }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Sampler;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.AasFile,
  DelphiDoom.MapFile.Aas.Trace, DelphiDoom.MapFile.Aas.Intf;

type
  /// <summary>
  ///   Answers the queries of the AI on a loaded file. The file is borrowed, not owned: the
  ///   caller keeps it alive as long as the sampler is used. An index that is not in its list
  ///   (a plane, a node, an area, a face) is an EAasFileException, where the original reads
  ///   outside its arrays. <b>Defects of the original that are kept</b>: in
  ///   <c>PointReachableAreaNum</c> the "trace up" test reads the flags of area 0 instead of the
  ///   flags of the area it found, and the cut of a trace puts the point TRACEPLANE_EPSILON on
  ///   the near side with a double and then narrows it to a float, as the original does
  /// </summary>
  TAasSampler = class(TInterfacedObject, IAasSampler)
  strict private
    FFile: TAasFile;
    procedure CheckNode(const ANodeNum: Integer);
    procedure CheckArea(const AAreaNum: Integer);
    function SuitableArea(const AAreaNum, AAreaFlags, AExcludeTravelFlags: Integer): Boolean;
    function BoundsReachableAreaNumFrom(const ANodeNum: Integer; const ABounds: TGeoBounds;
      const AAreaFlags, AExcludeTravelFlags, ADepth: Integer): Integer;
    procedure FailOnStackOverflow(const ATop: Integer);
  public
    constructor Create(const AFile: TAasFile);
    function PointAreaNum(const AOrigin: TGeoVec3): Integer;
    function PointReachableAreaNum(const AOrigin: TGeoVec3; const ASearchBounds: TGeoBounds;
      const AAreaFlags, AExcludeTravelFlags: Integer): Integer;
    function BoundsReachableAreaNum(const ABounds: TGeoBounds; const AAreaFlags,
      AExcludeTravelFlags: Integer): Integer;
    procedure PushPointIntoAreaNum(const AAreaNum: Integer; var APoint: TGeoVec3);
    function AreaReachableGoal(const AAreaNum: Integer): TGeoVec3;
    function Trace(var ATrace: TAasTrace; const AStart, AEnd: TGeoVec3): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Plane, DelphiDoom.MapFile.Aas.Types,
  DelphiDoom.MapFile.Aas.Area, DelphiDoom.MapFile.Aas.Geometry;

resourcestring
  SNodeNotInTree = 'node %d is not in 1..%d';
  SAreaNotInFile = 'area %d is not in 0..%d';
  STraceOverflow = 'idAASFileLocal::Trace: stack overflow';
  STreeTooDeep = 'the tree of the AAS is deeper than its number of nodes';
  SPlaneNotInFile = 'plane %d is not in 0..%d';

const
  TRACEPLANE_EPSILON: Single = 0.125;

/// <summary>
///   idVec3::Length: idMath::Sqrt is x * InvSqrt(x) (a table and Newton steps), not the square
///   root of the C library that TGeoVec3.Length uses
/// </summary>
function FloatLength(const AVector: TGeoVec3): Single;
begin
  Result := TIdMath.Sqrt(AVector.X * AVector.X + AVector.Y * AVector.Y + AVector.Z * AVector.Z);
end;

type
  TTraceStackEntry = record
    Start: TGeoVec3;
    EndPoint: TGeoVec3;
    PlaneNum: Integer;
    NodeNum: Integer;
  end;

{ TAasSampler }

constructor TAasSampler.Create(const AFile: TAasFile);
begin
  inherited Create;
  FFile := AFile;
end;

procedure TAasSampler.CheckNode(const ANodeNum: Integer);
begin
  if (ANodeNum < 0) or (ANodeNum >= FFile.NumNodes) then
    raise EAasFileException.Create(Format(SNodeNotInTree, [ANodeNum, FFile.NumNodes - 1]));
  if Integer(FFile.Nodes[ANodeNum].PlaneNum) >= FFile.NumPlanes then
    raise EAasFileException.Create(Format(SPlaneNotInFile, [FFile.Nodes[ANodeNum].PlaneNum, FFile.NumPlanes - 1]));
end;

procedure TAasSampler.CheckArea(const AAreaNum: Integer);
begin
  if (AAreaNum < 0) or (AAreaNum >= FFile.NumAreas) then
    raise EAasFileException.Create(Format(SAreaNotInFile, [AAreaNum, FFile.NumAreas - 1]));
end;

procedure TAasSampler.FailOnStackOverflow(const ATop: Integer);
begin
  if ATop >= MAX_AAS_TREE_DEPTH then
    raise EAasFileException.Create(STraceOverflow);
end;

function TAasSampler.SuitableArea(const AAreaNum, AAreaFlags, AExcludeTravelFlags: Integer): Boolean;
begin
  CheckArea(AAreaNum);
  Result := ((FFile.Areas[AAreaNum].Flags and AAreaFlags) <> 0) and
    ((FFile.Areas[AAreaNum].TravelFlags and AExcludeTravelFlags) = 0);
end;

function TAasSampler.PointAreaNum(const AOrigin: TGeoVec3): Integer;
var
  LNodeNum: Integer;
  LNode: TAasNode;
begin
  LNodeNum := 1;
  repeat
    CheckNode(LNodeNum);
    LNode := FFile.Nodes[LNodeNum];
    if FFile.Planes[LNode.PlaneNum].Side(AOrigin) = PLANESIDE_BACK then
      LNodeNum := LNode.Children[1]
    else
      LNodeNum := LNode.Children[0];
    if LNodeNum < 0 then
      Exit(-LNodeNum);
  until LNodeNum = 0;
  Result := 0;
end;

function TAasSampler.BoundsReachableAreaNumFrom(const ANodeNum: Integer; const ABounds: TGeoBounds;
  const AAreaFlags, AExcludeTravelFlags, ADepth: Integer): Integer;
var
  LNodeNum, LSide: Integer;
  LNode: TAasNode;
begin
  if ADepth > FFile.NumNodes then
    raise EAasFileException.Create(STreeTooDeep);
  LNodeNum := ANodeNum;
  while LNodeNum <> 0 do
  begin
    if LNodeNum < 0 then
    begin
      if SuitableArea(-LNodeNum, AAreaFlags, AExcludeTravelFlags) then
        Exit(-LNodeNum);
      Exit(0);
    end;
    CheckNode(LNodeNum);
    LNode := FFile.Nodes[LNodeNum];
    LSide := ABounds.PlaneSide(FFile.Planes[LNode.PlaneNum]);
    if LSide = PLANESIDE_BACK then
      LNodeNum := LNode.Children[1]
    else if LSide = PLANESIDE_FRONT then
      LNodeNum := LNode.Children[0]
    else
    begin
      LNodeNum := BoundsReachableAreaNumFrom(LNode.Children[1], ABounds, AAreaFlags, AExcludeTravelFlags,
        ADepth + 1);
      if LNodeNum <> 0 then
        Exit(LNodeNum);
      LNodeNum := LNode.Children[0];
    end;
  end;
  Result := 0;
end;

function TAasSampler.BoundsReachableAreaNum(const ABounds: TGeoBounds; const AAreaFlags,
  AExcludeTravelFlags: Integer): Integer;
begin
  Result := BoundsReachableAreaNumFrom(1, ABounds, AAreaFlags, AExcludeTravelFlags, 0);
end;

function TAasSampler.PointReachableAreaNum(const AOrigin: TGeoVec3; const ASearchBounds: TGeoBounds;
  const AAreaFlags, AExcludeTravelFlags: Integer): Integer;
var
  LStart, LEnd: TGeoVec3;
  LTrace: TAasTrace;
  LAreaNum, LIndex: Integer;
  LBounds: TGeoBounds;
  LFraction, LTwelfth: Single;
begin
  LStart := AOrigin;
  LTrace := TAasTrace.Init;
  SetLength(LTrace.Areas, 32);
  SetLength(LTrace.Points, 32);
  LTrace.MaxAreas := 32;
  LTrace.GetOutOfSolid := True;

  LAreaNum := PointAreaNum(LStart);
  if LAreaNum <> 0 then
  begin
    if SuitableArea(LAreaNum, AAreaFlags, AExcludeTravelFlags) then
      Exit(LAreaNum);
  end
  else
  begin
    // trace up
    LEnd := LStart;
    LEnd.Z := LEnd.Z + 32.0;
    Trace(LTrace, LStart, LEnd);
    if LTrace.NumAreas >= 1 then
    begin
      // the original tests the flags of area 0, not those of the area it found
      if SuitableArea(0, AAreaFlags, AExcludeTravelFlags) then
        Exit(LTrace.Areas[0]);
      LStart := LTrace.Points[0];
      LStart.Z := LStart.Z + 1.0;
    end;
  end;

  // trace down
  LEnd := LStart;
  LEnd.Z := LEnd.Z - 32.0;
  Trace(LTrace, LStart, LEnd);
  if LTrace.LastAreaNum <> 0 then
  begin
    if SuitableArea(LTrace.LastAreaNum, AAreaFlags, AExcludeTravelFlags) then
      Exit(LTrace.LastAreaNum);
    LStart := LTrace.EndPos;
  end;

  // expand bounds until an area is found
  LTwelfth := Single(1.0) / Single(12.0);
  for LIndex := 1 to 12 do
  begin
    LFraction := Single(LIndex) * LTwelfth;
    LBounds.Mins := AOrigin + ASearchBounds.Mins * LFraction;
    LBounds.Maxs := AOrigin + ASearchBounds.Maxs * LFraction;
    LAreaNum := BoundsReachableAreaNum(LBounds, AAreaFlags, AExcludeTravelFlags);
    if (LAreaNum <> 0) and SuitableArea(LAreaNum, AAreaFlags, AExcludeTravelFlags) then
      Exit(LAreaNum);
  end;
  Result := 0;
end;

procedure TAasSampler.PushPointIntoAreaNum(const AAreaNum: Integer; var APoint: TGeoVec3);
var
  LArea: TAasArea;
  LIndex, LFaceNum, LPlaneNum: Integer;
  LPlane: TGeoPlane;
  LDistance: Single;
begin
  CheckArea(AAreaNum);
  LArea := FFile.Areas[AAreaNum];
  // push the point to the right side of all area face planes
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := FFile.FaceIndex[LArea.FirstFace + LIndex];
    if Abs(LFaceNum) >= FFile.NumFaces then
      raise EAasFileException.Create(Format(SAreaNotInFile, [Abs(LFaceNum), FFile.NumFaces - 1]));
    LPlaneNum := FFile.Faces[Abs(LFaceNum)].PlaneNum;
    // INTSIGNBITSET: the plane of a face seen from the back is the next one
    if LFaceNum < 0 then
      LPlaneNum := LPlaneNum xor 1;
    if LPlaneNum >= FFile.NumPlanes then
      raise EAasFileException.Create(Format(SPlaneNotInFile, [LPlaneNum, FFile.NumPlanes - 1]));
    LPlane := FFile.Planes[LPlaneNum];
    LDistance := LPlane.Distance(APoint);
    // project the point onto the face plane if it is on the wrong side
    if LDistance < 0.0 then
      APoint := APoint - LPlane.Normal * LDistance;
  end;
end;

function TAasSampler.AreaReachableGoal(const AAreaNum: Integer): TGeoVec3;
var
  LArea: TAasArea;
  LIndex, LFaceNum, LNumFaces: Integer;
  LCenter, LEnd: TGeoVec3;
  LTrace: TAasTrace;
begin
  CheckArea(AAreaNum);
  LArea := FFile.Areas[AAreaNum];
  if ((LArea.Flags and (AREA_REACHABLE_WALK or AREA_REACHABLE_FLY)) = 0) or ((LArea.Flags and AREA_LIQUID) <> 0) then
    Exit(TAasGeometry.AreaCenter(FFile, AAreaNum));

  LCenter := TGeoVec3.Origin;
  LNumFaces := 0;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := FFile.FaceIndex[LArea.FirstFace + LIndex];
    if (FFile.Faces[Abs(LFaceNum)].Flags and FACE_FLOOR) = 0 then
      Continue;
    LCenter := LCenter + TAasGeometry.FaceCenter(FFile, Abs(LFaceNum));
    Inc(LNumFaces);
  end;
  if LNumFaces > 0 then
    LCenter := LCenter * (Single(1.0) / Single(LNumFaces));
  LCenter.Z := LCenter.Z + 1.0;
  LEnd := LCenter;
  LEnd.Z := LEnd.Z - 1024;
  LTrace := TAasTrace.Init;
  Trace(LTrace, LCenter, LEnd);
  Result := LTrace.EndPos;
end;

function TAasSampler.Trace(var ATrace: TAasTrace; const AStart, AEnd: TGeoVec3): Boolean;
var
  LStack: array[0..MAX_AAS_TREE_DEPTH - 1] of TTraceStackEntry;
  LTop, LNodeNum, LSide, LTempPlaneNum: Integer;
  LFront, LBack, LFraction, LNumerator, LDenominator: Double;
  LCurStart, LCurEnd, LCurMid, LV1, LV2: TGeoVec3;
  LNode: TAasNode;
  LPlane: TGeoPlane;
  LOnEpsilon: Double;
  LLengthStart, LLengthTotal: Single;

  procedure StopAt(const ABlockingAreaNum: Integer);
  begin
    if ATrace.LastAreaNum = 0 then
    begin
      ATrace.Fraction := 0.0;
      LV1 := TGeoVec3.Origin;
    end
    else
    begin
      LV1 := AEnd - AStart;
      LV2 := LStack[LTop].Start - AStart;
      LLengthStart := FloatLength(LV2);
      LLengthTotal := FloatLength(LV1);
      ATrace.Fraction := LLengthStart / LLengthTotal;
    end;
    ATrace.EndPos := LStack[LTop].Start;
    ATrace.BlockingAreaNum := ABlockingAreaNum;
    ATrace.PlaneNum := LStack[LTop].PlaneNum;
    // always take the plane with normal facing towards the trace start
    if ATrace.PlaneNum >= FFile.NumPlanes then
      raise EAasFileException.Create(Format(SPlaneNotInFile, [ATrace.PlaneNum, FFile.NumPlanes - 1]));
    LPlane := FFile.Planes[ATrace.PlaneNum];
    if LV1.Dot(LPlane.Normal) > 0.0 then
      ATrace.PlaneNum := ATrace.PlaneNum xor 1;
  end;

begin
  LOnEpsilon := ON_EPSILON;
  ATrace.NumAreas := 0;
  ATrace.LastAreaNum := 0;
  ATrace.BlockingAreaNum := 0;

  LTop := 0;
  LStack[0].Start := AStart;
  LStack[0].EndPoint := AEnd;
  LStack[0].PlaneNum := 0;
  LStack[0].NodeNum := 1; // start with the root of the tree
  Inc(LTop);

  while True do
  begin
    Dec(LTop);
    // if the trace stack is empty
    if LTop < 0 then
    begin
      if ATrace.LastAreaNum = 0 then
      begin
        // completely in solid
        ATrace.Fraction := 0.0;
        ATrace.EndPos := AStart;
      end
      else
      begin
        // nothing was hit
        ATrace.Fraction := 1.0;
        ATrace.EndPos := AEnd;
      end;
      ATrace.PlaneNum := 0;
      Exit(False);
    end;

    // number of the current node to test the line against
    LNodeNum := LStack[LTop].NodeNum;

    // if it is an area
    if LNodeNum < 0 then
    begin
      CheckArea(-LNodeNum);
      // if can't enter the area
      if ((FFile.Areas[-LNodeNum].Flags and ATrace.Flags) <> 0) or
        ((FFile.Areas[-LNodeNum].TravelFlags and ATrace.TravelFlags) <> 0) then
      begin
        StopAt(-LNodeNum);
        Exit(True);
      end;
      ATrace.LastAreaNum := -LNodeNum;
      if ATrace.NumAreas < ATrace.MaxAreas then
      begin
        if ATrace.NumAreas < Length(ATrace.Areas) then
          ATrace.Areas[ATrace.NumAreas] := -LNodeNum;
        if ATrace.NumAreas < Length(ATrace.Points) then
          ATrace.Points[ATrace.NumAreas] := LStack[LTop].Start;
        Inc(ATrace.NumAreas);
      end;
      Continue;
    end;

    // if it is a solid leaf
    if LNodeNum = 0 then
    begin
      StopAt(0); // hit solid leaf
      if (ATrace.LastAreaNum = 0) and ATrace.GetOutOfSolid then
        Continue;
      Exit(True);
    end;

    CheckNode(LNodeNum);
    // the node to test against
    LNode := FFile.Nodes[LNodeNum];
    // start and end point of the current line to test against the node
    LCurStart := LStack[LTop].Start;
    LCurEnd := LStack[LTop].EndPoint;
    // the current node plane
    LPlane := FFile.Planes[LNode.PlaneNum];

    LFront := LPlane.Distance(LCurStart);
    LBack := LPlane.Distance(LCurEnd);

    if (LFront >= -LOnEpsilon) and (LBack >= -LOnEpsilon) then
    begin
      // the whole line is in front: only go down the tree with the front child
      LStack[LTop].NodeNum := LNode.Children[0];
      Inc(LTop);
      FailOnStackOverflow(LTop);
    end
    else if (LFront < LOnEpsilon) and (LBack < LOnEpsilon) then
    begin
      // the whole line is at the back: only go down the tree with the back child
      LStack[LTop].NodeNum := LNode.Children[1];
      Inc(LTop);
      FailOnStackOverflow(LTop);
    end
    else
    begin
      // go down the tree both at the front and back of the node
      LTempPlaneNum := LStack[LTop].PlaneNum;
      // put the cross point TRACEPLANE_EPSILON on the near side
      // every operation goes through a Double variable: the x87 unit would keep the sums and
      // the quotient in extended precision and the float that follows could differ by a bit
      LDenominator := LFront - LBack;
      if LFront < 0 then
        LNumerator := LFront + TRACEPLANE_EPSILON
      else
        LNumerator := LFront - TRACEPLANE_EPSILON;
      LFraction := LNumerator / LDenominator;
      if LFraction < 0 then
        LFraction := Double(Single(0.001))
      else if LFraction > 1 then
        LFraction := Double(Single(0.999));

      // idVec3 times a double: the double is narrowed to a float
      LCurMid := LCurStart + (LCurEnd - LCurStart) * Single(LFraction);

      // side the front part of the line is on
      LSide := Ord(LFront < 0);

      // first put the end part of the line on the stack (back side)
      LStack[LTop].Start := LCurMid;
      LStack[LTop].PlaneNum := LNode.PlaneNum;
      LStack[LTop].NodeNum := LNode.Children[1 - LSide];
      Inc(LTop);
      FailOnStackOverflow(LTop);
      // now the part near the start of the line, to continue with that part first
      LStack[LTop].Start := LCurStart;
      LStack[LTop].EndPoint := LCurMid;
      LStack[LTop].PlaneNum := LTempPlaneNum;
      LStack[LTop].NodeNum := LNode.Children[LSide];
      Inc(LTop);
      FailOnStackOverflow(LTop);
    end;
  end;
end;

end.
