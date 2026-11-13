{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - lines through the tree (be_aas_sample.c)          }
{                                                                              }
{  Port of AAS_TraceAreas and AAS_TraceClientBBox. Based on the Quake III      }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Tracer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf;

type
  /// <summary>
  ///   The two traces of the original, with its stack of 127 pieces of line (the "stack
  ///   overflow" error is raised at the same depth) and the same floating point operations,
  ///   one at a time and in the same type (the constants 0.125 are doubles). A tree that
  ///   refers outside its arrays, or has a loop, is an error that is printed (the original
  ///   reads outside the arrays or never ends).
  /// </summary>
  TAasTracer = class(TInterfacedObject, IAasTracer)
  strict private
    type
      TStackEntry = record
        Start: TVec3;
        Finish: TVec3;
        PlaneNum: Integer;
        NodeNum: Integer;
      end;
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
    function NodeBudget: Integer;
    procedure Block(var ATrace: TAasTrace; const AStart, AEnd: TVec3; var AEntry: TStackEntry; const AAreaNum: Integer);
  public
    constructor Create(const AFile: IAasFile; const AImport: IBotImport);
    function TraceAreas(const AStart, AEnd: TVec3; const AMaxAreas: Integer; out AAreas: TArray<Integer>;
      out APoints: TArray<TVec3>): Integer;
    function TraceClientBBox(const AStart, AEnd: TVec3; const APresenceType, APassEntity: Integer): TAasTrace;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath;

resourcestring
  STraceAreasStack = 'AAS_TraceAreas: stack overflow'#10;
  STraceBoxStack = 'AAS_TraceBoundingBox: stack overflow'#10;
  STraceAreaRange = 'AAS_TraceBoundingBox: -nodenum out of range'#10;
  STraceNodeRange = 'AAS_TraceBoundingBox: nodenum out of range'#10;
  STraceAreasNodeRange = 'AAS_TraceAreas: nodenum out of range'#10;
  STraceBadPlane = 'AAS_Trace: the plane %d of a node is out of range'#10;
  STraceLoop = 'AAS_Trace: the tree of nodes has a loop'#10;

const
  // TRACEPLANE_EPSILON of the original, a double
  TRACEPLANE_EPSILON: Double = 0.125;
  // the float literals 0.001f and 0.999f
  FRACTION_LOW: Single = 0.001;
  FRACTION_HIGH: Single = 0.999;

function Same(const A, B: TVec3): Boolean;
begin
  Result := (A[0] = B[0]) and (A[1] = B[1]) and (A[2] = B[2]);
end;

procedure MidPoint(const AStart, AEnd: TVec3; const AFraction: Single; var AMid: TVec3);
var
  LIndex: Integer;
  LDelta: Single;
begin
  for LIndex := 0 to 2 do
  begin
    LDelta := AEnd[LIndex] - AStart[LIndex];
    LDelta := LDelta * AFraction;
    AMid[LIndex] := AStart[LIndex] + LDelta;
  end;
end;

{ TAasTracer }

constructor TAasTracer.Create(const AFile: IAasFile; const AImport: IBotImport);
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
end;

function TAasTracer.NodeBudget: Integer;
begin
  // a tree is visited once; the extra is for trees where a node has more than one parent
  Result := (Length(FFile.Nodes) + 1) * AAS_TRACE_STACK_SIZE + 1024;
end;

function TAasTracer.TraceAreas(const AStart, AEnd: TVec3; const AMaxAreas: Integer; out AAreas: TArray<Integer>;
  out APoints: TArray<TVec3>): Integer;
var
  LStack: array[0..AAS_TRACE_STACK_SIZE - 1] of TStackEntry;
  LTop, LNodeNum, LSide, LPlaneNum, LBudget: Integer;
  LNodes: TArray<TAasNode>;
  LPlanes: TArray<TAasPlane>;
  LNode: TAasNode;
  LCurStart, LCurEnd, LCurMid: TVec3;
  LFront, LBack, LFraction, LDiff: Single;
begin
  Result := 0;
  AAreas := nil;
  APoints := nil;
  if AMaxAreas <= 0 then
    Exit;
  SetLength(AAreas, AMaxAreas);
  SetLength(APoints, AMaxAreas);
  LNodes := FFile.Nodes;
  LPlanes := FFile.Planes;
  LBudget := NodeBudget;
  // the whole line is on the stack; node 1 is the root, node zero a dummy for a solid leaf
  LStack[0].Start := AStart;
  LStack[0].Finish := AEnd;
  LStack[0].PlaneNum := 0;
  LStack[0].NodeNum := 1;
  LTop := 1;
  while True do
  begin
    Dec(LTop);
    if LTop < 0 then
      Break;
    Dec(LBudget);
    if LBudget < 0 then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, STraceLoop);
      Break;
    end;
    LNodeNum := LStack[LTop].NodeNum;
    if LNodeNum < 0 then
    begin
      AAreas[Result] := -LNodeNum;
      APoints[Result] := LStack[LTop].Start;
      Inc(Result);
      if Result >= AMaxAreas then
        Break;
      Continue;
    end;
    if LNodeNum = 0 then
      Continue;
    if LNodeNum >= Length(LNodes) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, STraceAreasNodeRange);
      Break;
    end;
    LNode := LNodes[LNodeNum];
    if (LNode.PlaneNum < 0) or (LNode.PlaneNum >= Length(LPlanes)) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, Format(STraceBadPlane, [LNode.PlaneNum]));
      Break;
    end;
    LCurStart := LStack[LTop].Start;
    LCurEnd := LStack[LTop].Finish;
    LFront := TAasVectorMath.Dot(LCurStart, LPlanes[LNode.PlaneNum].Normal);
    LFront := LFront - LPlanes[LNode.PlaneNum].Dist;
    LBack := TAasVectorMath.Dot(LCurEnd, LPlanes[LNode.PlaneNum].Normal);
    LBack := LBack - LPlanes[LNode.PlaneNum].Dist;
    if (LFront > 0) and (LBack > 0) then
    begin
      // the whole line is at the front: keep the line and go down with the front child
      LStack[LTop].NodeNum := LNode.Children[0];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceAreasStack);
        Break;
      end;
    end
    else if (LFront <= 0) and (LBack <= 0) then
    begin
      LStack[LTop].NodeNum := LNode.Children[1];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceAreasStack);
        Break;
      end;
    end
    else
    begin
      LPlaneNum := LStack[LTop].PlaneNum;
      LDiff := LFront - LBack;
      LFraction := LFront / LDiff;
      if LFraction < 0 then
        LFraction := 0
      else if LFraction > 1 then
        LFraction := 1;
      MidPoint(LCurStart, LCurEnd, LFraction, LCurMid);
      if LFront < 0 then
        LSide := 1
      else
        LSide := 0;
      // first the part of the line that is far from the start (the other side) ...
      LStack[LTop].Start := LCurMid;
      LStack[LTop].PlaneNum := LNode.PlaneNum;
      LStack[LTop].NodeNum := LNode.Children[1 - LSide];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceAreasStack);
        Break;
      end;
      // ... then the one near the start, so the areas come in the order of the line
      LStack[LTop].Start := LCurStart;
      LStack[LTop].Finish := LCurMid;
      LStack[LTop].PlaneNum := LPlaneNum;
      LStack[LTop].NodeNum := LNode.Children[LSide];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceAreasStack);
        Break;
      end;
    end;
  end;
  SetLength(AAreas, Result);
  SetLength(APoints, Result);
end;

procedure TAasTracer.Block(var ATrace: TAasTrace; const AStart, AEnd: TVec3; var AEntry: TStackEntry;
  const AAreaNum: Integer);
var
  LV1, LV2: TVec3;
  LLength, LNormalLength: Single;
  LPlanes: TArray<TAasPlane>;
begin
  // the start point of the piece is still the initial start point: no epsilon is needed
  // because the points are exactly the same when they both are the start point
  if Same(AEntry.Start, AStart) then
  begin
    ATrace.StartSolid := True;
    ATrace.Fraction := 0;
    LV1[0] := 0;
    LV1[1] := 0;
    LV1[2] := 0;
  end
  else
  begin
    ATrace.StartSolid := False;
    TAasVectorMath.Subtract(AEnd, AStart, LV1);
    TAasVectorMath.Subtract(AEntry.Start, AStart, LV2);
    LLength := TAasVectorMath.Length(LV2);
    LNormalLength := TAasVectorMath.Normalize(LV1);
    // the piece does not start at the start, so the line has a length: no division by zero
    ATrace.Fraction := LLength / LNormalLength;
    TAasVectorMath.MultiplyAdd(AEntry.Start, LV1, -0.125, AEntry.Start);
  end;
  ATrace.EndPos := AEntry.Start;
  ATrace.Ent := 0;
  ATrace.Area := AAreaNum;
  ATrace.PlaneNum := AEntry.PlaneNum;
  // always take the plane with the normal facing the start of the trace
  LPlanes := FFile.Planes;
  if (ATrace.PlaneNum >= 0) and (ATrace.PlaneNum < Length(LPlanes)) and
     (TAasVectorMath.Dot(LV1, LPlanes[ATrace.PlaneNum].Normal) > 0) then
    ATrace.PlaneNum := ATrace.PlaneNum xor 1;
end;

function TAasTracer.TraceClientBBox(const AStart, AEnd: TVec3; const APresenceType,
  APassEntity: Integer): TAasTrace;
var
  LStack: array[0..AAS_TRACE_STACK_SIZE - 1] of TStackEntry;
  LTop, LNodeNum, LSide, LPlaneNum, LBudget: Integer;
  LNodes: TArray<TAasNode>;
  LPlanes: TArray<TAasPlane>;
  LSettings: TArray<TAasAreaSettings>;
  LNode: TAasNode;
  LCurStart, LCurEnd, LCurMid: TVec3;
  LFront, LBack, LFraction, LDiff: Single;
  LNumerator: Double;
begin
  FillChar(Result, SizeOf(Result), 0);
  LNodes := FFile.Nodes;
  LPlanes := FFile.Planes;
  LSettings := FFile.AreaSettings;
  LBudget := NodeBudget;
  LStack[0].Start := AStart;
  LStack[0].Finish := AEnd;
  LStack[0].PlaneNum := 0;
  LStack[0].NodeNum := 1;
  LTop := 1;
  while True do
  begin
    Dec(LTop);
    // the stack is empty: the whole line was in areas it can enter, nothing was hit
    if LTop < 0 then
    begin
      Result.StartSolid := False;
      Result.Fraction := 1.0;
      Result.EndPos := AEnd;
      Result.Ent := 0;
      Result.Area := 0;
      Result.PlaneNum := 0;
      Exit;
    end;
    Dec(LBudget);
    if LBudget < 0 then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, STraceLoop);
      Exit;
    end;
    LNodeNum := LStack[LTop].NodeNum;
    if LNodeNum < 0 then
    begin
      if -LNodeNum >= Length(LSettings) then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceAreaRange);
        Exit;
      end;
      // an area the box cannot be in (no presence type of the box): the line stops
      if (LSettings[-LNodeNum].PresenceType and APresenceType) = 0 then
      begin
        Block(Result, AStart, AEnd, LStack[LTop], -LNodeNum);
        Exit;
      end;
      // the entities linked into the area (APassEntity) are not part of the library: none is hit
      Result.LastArea := -LNodeNum;
      Continue;
    end;
    if LNodeNum = 0 then
    begin
      Block(Result, AStart, AEnd, LStack[LTop], 0);
      Exit;
    end;
    if LNodeNum >= Length(LNodes) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, STraceNodeRange);
      Exit;
    end;
    LNode := LNodes[LNodeNum];
    if (LNode.PlaneNum < 0) or (LNode.PlaneNum >= Length(LPlanes)) then
    begin
      TAasPrinter.Print(FImport, PRT_ERROR, Format(STraceBadPlane, [LNode.PlaneNum]));
      Exit;
    end;
    LCurStart := LStack[LTop].Start;
    LCurEnd := LStack[LTop].Finish;
    LFront := TAasVectorMath.Dot(LCurStart, LPlanes[LNode.PlaneNum].Normal);
    LFront := LFront - LPlanes[LNode.PlaneNum].Dist;
    LBack := TAasVectorMath.Dot(LCurEnd, LPlanes[LNode.PlaneNum].Normal);
    LBack := LBack - LPlanes[LNode.PlaneNum].Dist;
    // ON_EPSILON is 0
    if (LFront >= 0) and (LBack >= 0) then
    begin
      LStack[LTop].NodeNum := LNode.Children[0];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceBoxStack);
        Exit;
      end;
    end
    else if (LFront < 0) and (LBack < 0) then
    begin
      LStack[LTop].NodeNum := LNode.Children[1];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceBoxStack);
        Exit;
      end;
    end
    else
    begin
      LPlaneNum := LStack[LTop].PlaneNum;
      // the original avoids a division by zero here when front = back, which cannot be
      // reached: one is at least 0 and the other less than 0 (NaN does not get here either)
      LDiff := LFront - LBack;
      // the crossing is put TRACEPLANE_EPSILON on the near side; a double operation as in the C
      if LFront < 0 then
        LNumerator := Double(LFront) + TRACEPLANE_EPSILON
      else
        LNumerator := Double(LFront) - TRACEPLANE_EPSILON;
      LFraction := LNumerator / Double(LDiff);
      if LFraction < 0 then
        LFraction := FRACTION_LOW
      else if LFraction > 1 then
        LFraction := FRACTION_HIGH;
      MidPoint(LCurStart, LCurEnd, LFraction, LCurMid);
      if LFront < 0 then
        LSide := 1
      else
        LSide := 0;
      LStack[LTop].Start := LCurMid;
      LStack[LTop].PlaneNum := LNode.PlaneNum;
      LStack[LTop].NodeNum := LNode.Children[1 - LSide];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceBoxStack);
        Exit;
      end;
      LStack[LTop].Start := LCurStart;
      LStack[LTop].Finish := LCurMid;
      LStack[LTop].PlaneNum := LPlaneNum;
      LStack[LTop].NodeNum := LNode.Children[LSide];
      Inc(LTop);
      if LTop >= AAS_TRACE_STACK_SIZE then
      begin
        TAasPrinter.Print(FImport, PRT_ERROR, STraceBoxStack);
        Exit;
      end;
    end;
  end;
end;

end.
