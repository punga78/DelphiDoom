{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - choice of the partition line and division of the segs  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of seg.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                      }
{  Based on the nodeline picker of DEU5beta (Raphael Quinet), rewritten by     }
{  Lee Killough and by Andrew Apted                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Node.Partitioner;

interface

uses
  System.Classes,
  System.Generics.Collections,
  DelphiDoom.Glbsp.Level.Analyzer,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Options;

type
  /// <summary>
  ///   Chooses the best seg to use as a partition line and divides the segs
  ///   with it, splitting the ones that cross it and adding the minisegs
  /// </summary>
  TGlbspPartitioner = class
  private
    type
      TEvalInfo = record
        Cost: Integer;
        Splits: Integer;
        Iffy: Integer;
        NearMiss: Integer;
        RealLeft: Integer;
        RealRight: Integer;
        MiniLeft: Integer;
        MiniRight: Integer;
      end;
  private
    FData: TGlbspLevelData;
    FAnalyzer: TGlbspLevelAnalyzer;
    FOptions: TGlbspOptions;
    FMessages: TStrings;
    FCuts: TObjectList<TGlbspIntersection>;
    procedure MiniWarn(const AMessage: string);
    function SplitSeg(const AOldSeg: TGlbspSeg; const AX, AY: Double): TGlbspSeg;
    class procedure ComputeIntersection(const ACur, APart: TGlbspSeg; const APerpC,
      APerpD: Double; out AX, AY: Double); static;
    procedure AddIntersection(var ACutList: TGlbspIntersection;
      const AVertex: TGlbspVertex; const APart: TGlbspSeg; const ASelfRef: Boolean);
    function EvalPartitionWorker(const ASegList: TGlbspSuperBlock;
      const APart: TGlbspSeg; const ABestCost: Integer; var AInfo: TEvalInfo): Boolean;
    function EvalPartition(const ASegList: TGlbspSuperBlock; const APart: TGlbspSeg;
      const ABestCost: Integer): Integer;
    class function FindSegFromStaleNode(const APartList: TGlbspSuperBlock;
      const AStaleNode: TGlbspNode; var AStaleOpposite: Integer): TGlbspSeg; static;
    procedure PickNodeWorker(const APartList, ASegList: TGlbspSuperBlock;
      var ABest: TGlbspSeg; var ABestCost: Integer);
    class procedure FindLimitWorker(const ABlock: TGlbspSuperBlock;
      var ABBox: TGlbspBBox); static;
  public
    /// <param name="AData">Level being built</param>
    /// <param name="AAnalyzer">Creates the vertices of the splits</param>
    /// <param name="AOptions">Options; the factor weighs the cost of a split</param>
    /// <param name="AMessages">Receives the warnings; may be nil</param>
    constructor Create(const AData: TGlbspLevelData; const AAnalyzer: TGlbspLevelAnalyzer;
      const AOptions: TGlbspOptions; const AMessages: TStrings);
    destructor Destroy; override;

    /// <summary>
    ///   Computes the private data of the seg (start, end, delta, length,
    ///   angle and the distance constants)
    /// </summary>
    class procedure RecomputeSeg(const ASeg: TGlbspSeg); static;

    /// <summary>
    ///   The best seg to use as a partition line, or nil when no seg can be
    ///   used (the list is convex). When AStaleNode is assigned it is tried
    ///   first and cleared if it is unsuitable
    /// </summary>
    function PickNode(const ASegList: TGlbspSuperBlock; var AStaleNode: TGlbspNode;
      var AStaleOpposite: Integer): TGlbspSeg;

    /// <summary>
    ///   Puts the seg in the left or right list, or splits it in two;
    ///   updates the cut list when the seg lies on or crosses the partition
    /// </summary>
    procedure DivideOneSeg(const ACur, APart: TGlbspSeg; const ALeftList,
      ARightList: TGlbspSuperBlock; var ACutList: TGlbspIntersection);

    /// <summary>
    ///   Moves all the segs of the list to the left or right lists; the
    ///   emptied sub-blocks of ASegList are freed
    /// </summary>
    procedure SeparateSegs(const ASegList: TGlbspSuperBlock; const APart: TGlbspSeg;
      const ALeftList, ARightList: TGlbspSuperBlock; var ACutList: TGlbspIntersection);

    /// <summary>
    ///   Adds the minisegs (one on each side) that the cut list needs, and
    ///   releases the cut list
    /// </summary>
    procedure AddMinisegs(const APart: TGlbspSeg; const ALeftList,
      ARightList: TGlbspSuperBlock; ACutList: TGlbspIntersection);

    /// <summary>Bounding box, in integers, of the segs of the list</summary>
    class function FindLimits(const ASegList: TGlbspSuperBlock): TGlbspBBox; static;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  DelphiDoom.Glbsp.Node.SuperBlocks,
  DelphiDoom.Glbsp.Util;

const
  PRECIOUS_MULTIPLY = 100;
  SEG_REUSE_THRESHHOLD = 200;
  SHRT_MAX = 32767;
  SHRT_MIN = -32768;

{ TGlbspPartitioner }

constructor TGlbspPartitioner.Create(const AData: TGlbspLevelData;
  const AAnalyzer: TGlbspLevelAnalyzer; const AOptions: TGlbspOptions;
  const AMessages: TStrings);
begin
  inherited Create;
  FData := AData;
  FAnalyzer := AAnalyzer;
  FOptions := AOptions;
  FMessages := AMessages;
  FCuts := TObjectList<TGlbspIntersection>.Create(True);
end;

destructor TGlbspPartitioner.Destroy;
begin
  FCuts.Free;
  inherited Destroy;
end;

procedure TGlbspPartitioner.MiniWarn(const AMessage: string);
begin
  if FOptions.MiniWarnings and Assigned(FMessages) then
    FMessages.Add(AMessage);
end;

class procedure TGlbspPartitioner.RecomputeSeg(const ASeg: TGlbspSeg);
begin
  ASeg.PsX := ASeg.Start.X;
  ASeg.PsY := ASeg.Start.Y;
  ASeg.PeX := ASeg.EndVertex.X;
  ASeg.PeY := ASeg.EndVertex.Y;
  ASeg.PdX := ASeg.PeX - ASeg.PsX;
  ASeg.PdY := ASeg.PeY - ASeg.PsY;

  ASeg.PLength := Sqrt(ASeg.PdX * ASeg.PdX + ASeg.PdY * ASeg.PdY);
  ASeg.PAngle := TGlbspUtil.ComputeAngle(ASeg.PdX, ASeg.PdY);

  if ASeg.PLength <= 0 then
    raise EGlbspLevelException.Create('Seg has zero p_length.');

  ASeg.PPerp := ASeg.PsY * ASeg.PdX - ASeg.PsX * ASeg.PdY;
  ASeg.PPara := -ASeg.PsX * ASeg.PdX - ASeg.PsY * ASeg.PdY;
end;

function TGlbspPartitioner.SplitSeg(const AOldSeg: TGlbspSeg; const AX,
  AY: Double): TGlbspSeg;
var
  LNewVertex: TGlbspVertex;
begin
  // The counts of the superblock are updated, so that the later processing
  // is not fooled by wrong counts
  if Assigned(AOldSeg.Block) then
    TGlbspSuperBlocks.SplitSegInSuper(AOldSeg.Block, AOldSeg);

  LNewVertex := FAnalyzer.NewVertexFromSplitSeg(AOldSeg, AX, AY);
  Result := FData.NewSeg;

  // Copy the seg info; the new seg becomes the cut-off tail
  Result.Assign(AOldSeg);
  Result.Next := nil;

  AOldSeg.EndVertex := LNewVertex;
  RecomputeSeg(AOldSeg);

  Result.Start := LNewVertex;
  RecomputeSeg(Result);

  // The partner is split too, and keeps the relationship valid
  if Assigned(AOldSeg.Partner) then
  begin
    if Assigned(AOldSeg.Partner.Block) then
      TGlbspSuperBlocks.SplitSegInSuper(AOldSeg.Partner.Block, AOldSeg.Partner);

    Result.Partner := FData.NewSeg;
    Result.Partner.Assign(AOldSeg.Partner);
    Result.Partner.Partner := Result;

    AOldSeg.Partner.Start := LNewVertex;
    RecomputeSeg(AOldSeg.Partner);

    Result.Partner.EndVertex := LNewVertex;
    RecomputeSeg(Result.Partner);

    // Link it into the list, after the partner
    AOldSeg.Partner.Next := Result.Partner;
  end;
end;

class procedure TGlbspPartitioner.ComputeIntersection(const ACur, APart: TGlbspSeg;
  const APerpC, APerpD: Double; out AX, AY: Double);
var
  LDs: Double;
begin
  // Horizontal partition against vertical seg
  if (APart.PdY = 0) and (ACur.PdX = 0) then
  begin
    AX := ACur.PsX;
    AY := APart.PsY;
    Exit;
  end;

  // Vertical partition against horizontal seg
  if (APart.PdX = 0) and (ACur.PdY = 0) then
  begin
    AX := APart.PsX;
    AY := ACur.PsY;
    Exit;
  end;

  // 0 = start, 1 = end
  LDs := APerpC / (APerpC - APerpD);

  if ACur.PdX = 0 then
    AX := ACur.PsX
  else
    AX := ACur.PsX + (ACur.PdX * LDs);

  if ACur.PdY = 0 then
    AY := ACur.PsY
  else
    AY := ACur.PsY + (ACur.PdY * LDs);
end;

procedure TGlbspPartitioner.AddIntersection(var ACutList: TGlbspIntersection;
  const AVertex: TGlbspVertex; const APart: TGlbspSeg; const ASelfRef: Boolean);
var
  LCut: TGlbspIntersection;
  LAfter: TGlbspIntersection;
begin
  // Is the vertex already there?
  LCut := ACutList;
  while Assigned(LCut) do
  begin
    if AVertex = LCut.Vertex then
      Exit;
    LCut := LCut.Next;
  end;

  LCut := TGlbspIntersection.Create;
  FCuts.Add(LCut);

  LCut.Vertex := AVertex;
  LCut.AlongDist := APart.ParallelDist(AVertex.X, AVertex.Y);
  LCut.SelfRef := ASelfRef;
  LCut.Before := FAnalyzer.VertexCheckOpen(AVertex, -APart.PdX, -APart.PdY);
  LCut.After := FAnalyzer.VertexCheckOpen(AVertex, APart.PdX, APart.PdY);

  // Enqueue the new intersection in the list
  LAfter := ACutList;
  while Assigned(LAfter) and Assigned(LAfter.Next) do
    LAfter := LAfter.Next;

  while Assigned(LAfter) and (LCut.AlongDist < LAfter.AlongDist) do
    LAfter := LAfter.Prev;

  // Link it in
  if Assigned(LAfter) then
    LCut.Next := LAfter.Next
  else
    LCut.Next := ACutList;
  LCut.Prev := LAfter;

  if Assigned(LAfter) then
  begin
    if Assigned(LAfter.Next) then
      LAfter.Next.Prev := LCut;
    LAfter.Next := LCut;
  end
  else
  begin
    if Assigned(ACutList) then
      ACutList.Prev := LCut;
    ACutList := LCut;
  end;
end;

function TGlbspPartitioner.EvalPartitionWorker(const ASegList: TGlbspSuperBlock;
  const APart: TGlbspSeg; const ABestCost: Integer; var AInfo: TEvalInfo): Boolean;
var
  LCheck: TGlbspSeg;
  LQnty: Double;
  A, B, FA, FB: Double;
  LNum: Integer;
  LFactor: Integer;

  procedure AddLeft;
  begin
    if Assigned(LCheck.Linedef) then
      Inc(AInfo.RealLeft)
    else
      Inc(AInfo.MiniLeft);
  end;

  procedure AddRight;
  begin
    if Assigned(LCheck.Linedef) then
      Inc(AInfo.RealRight)
    else
      Inc(AInfo.MiniRight);
  end;

begin
  LFactor := FOptions.Factor;

  // The whole block is tested against the partition line: only when the line
  // crosses the box the segs inside must be looked at one by one
  LNum := TGlbspSuperBlocks.BoxOnLineSide(ASegList, APart);

  if LNum < 0 then
  begin
    Inc(AInfo.RealLeft, ASegList.RealNum);
    Inc(AInfo.MiniLeft, ASegList.MiniNum);
    Exit(False);
  end
  else if LNum > 0 then
  begin
    Inc(AInfo.RealRight, ASegList.RealNum);
    Inc(AInfo.MiniRight, ASegList.MiniNum);
    Exit(False);
  end;

  // The partition is checked against all the segs
  LCheck := ASegList.Segs;
  while Assigned(LCheck) do
  begin
    try
      // Catches the bad segs early (Killough)
      if AInfo.Cost > ABestCost then
        Exit(True);

      // The relation of the lines to each other
      if LCheck.SourceLine = APart.SourceLine then
      begin
        A := 0;
        B := 0;
        FA := 0;
        FB := 0;
      end
      else
      begin
        A := APart.PerpDist(LCheck.PsX, LCheck.PsY);
        B := APart.PerpDist(LCheck.PeX, LCheck.PeY);
        FA := Abs(A);
        FB := Abs(B);
      end;

      // On the same line as the partition: the direction tells the side
      if (FA <= DIST_EPSILON) and (FB <= DIST_EPSILON) then
      begin
        if LCheck.PdX * APart.PdX + LCheck.PdY * APart.PdY < 0 then
          AddLeft
        else
          AddRight;
        Continue;
      end;

      // Passing through a vertex is normally fine, but the vertex could be on
      // a sector that must not be split (thanks to Janis Legzdinsh)
      if (FA <= DIST_EPSILON) or (FB <= DIST_EPSILON) then
      begin
        if Assigned(LCheck.Linedef) and LCheck.Linedef.IsPrecious then
          Inc(AInfo.Cost, 40 * LFactor * PRECIOUS_MULTIPLY);
      end;

      // Right side
      if (A > -DIST_EPSILON) and (B > -DIST_EPSILON) then
      begin
        AddRight;

        // Near misses are bad: they can create very short minisegs later,
        // so the closer the miss, the higher the cost
        if ((A >= IFFY_LEN) and (B >= IFFY_LEN)) or
          ((A <= DIST_EPSILON) and (B >= IFFY_LEN)) or
          ((B <= DIST_EPSILON) and (A >= IFFY_LEN)) then
          Continue;

        Inc(AInfo.NearMiss);

        if (A <= DIST_EPSILON) or (B <= DIST_EPSILON) then
          LQnty := IFFY_LEN / Max(A, B)
        else
          LQnty := IFFY_LEN / Min(A, B);

        Inc(AInfo.Cost, Trunc(100 * LFactor * (LQnty * LQnty - 1.0)));
        Continue;
      end;

      // Left side
      if (A < DIST_EPSILON) and (B < DIST_EPSILON) then
      begin
        AddLeft;

        if ((A <= -IFFY_LEN) and (B <= -IFFY_LEN)) or
          ((A >= -DIST_EPSILON) and (B <= -IFFY_LEN)) or
          ((B >= -DIST_EPSILON) and (A <= -IFFY_LEN)) then
          Continue;

        Inc(AInfo.NearMiss);

        if (A >= -DIST_EPSILON) or (B >= -DIST_EPSILON) then
          LQnty := IFFY_LEN / -Min(A, B)
        else
          LQnty := IFFY_LEN / -Max(A, B);

        Inc(AInfo.Cost, Trunc(70 * LFactor * (LQnty * LQnty - 1.0)));
        Continue;
      end;

      // Here A and B are not zero and have opposite signs: the partition line
      // splits this seg
      Inc(AInfo.Splits);

      // Linedefs with a tag of 900 or more are precious: they are not split
      // unless there is nothing else (deep water, invisible lifts or stairs)
      if Assigned(LCheck.Linedef) and LCheck.Linedef.IsPrecious then
        Inc(AInfo.Cost, 100 * LFactor * PRECIOUS_MULTIPLY)
      else
        Inc(AInfo.Cost, 100 * LFactor);

      // A split near one of the ends makes a really short seg (the "iffy"
      // segs, one source of the slime trails) and costs a lot
      if (FA < IFFY_LEN) or (FB < IFFY_LEN) then
      begin
        Inc(AInfo.Iffy);
        LQnty := IFFY_LEN / Min(FA, FB);
        Inc(AInfo.Cost, Trunc(140 * LFactor * (LQnty * LQnty - 1.0)));
      end;
    finally
      LCheck := LCheck.Next;
    end;
  end;

  // The sub-blocks
  for LNum := 0 to 1 do
  begin
    if not Assigned(ASegList.Subs[LNum]) then
      Continue;
    if EvalPartitionWorker(ASegList.Subs[LNum], APart, ABestCost, AInfo) then
      Exit(True);
  end;

  // No bad seg was found
  Result := False;
end;

function TGlbspPartitioner.EvalPartition(const ASegList: TGlbspSuperBlock;
  const APart: TGlbspSeg; const ABestCost: Integer): Integer;
var
  LInfo: TEvalInfo;
begin
  FillChar(LInfo, SizeOf(LInfo), 0);

  if EvalPartitionWorker(ASegList, APart, ABestCost, LInfo) then
    Exit(-1);

  // At least one real seg on each side
  if (LInfo.RealLeft = 0) or (LInfo.RealRight = 0) then
    Exit(-1);

  // Cost of the difference between left and right
  Inc(LInfo.Cost, 100 * Abs(LInfo.RealLeft - LInfo.RealRight));

  // The miniseg counts matter too, but less than the real segs
  Inc(LInfo.Cost, 50 * Abs(LInfo.MiniLeft - LInfo.MiniRight));

  // A slight preference for partitions purely horizontal or vertical
  if (APart.PdX <> 0) and (APart.PdY <> 0) then
    Inc(LInfo.Cost, 25);

  Result := LInfo.Cost;
end;

class function TGlbspPartitioner.FindSegFromStaleNode(const APartList: TGlbspSuperBlock;
  const AStaleNode: TGlbspNode; var AStaleOpposite: Integer): TGlbspSeg;
var
  LPart: TGlbspSeg;
  LNum: Integer;
  FA, FB: Double;
begin
  LPart := APartList.Segs;
  while Assigned(LPart) do
  begin
    // Minisegs are never partition candidates
    if Assigned(LPart.Linedef) then
    begin
      FA := Abs(LPart.PerpDist(AStaleNode.X, AStaleNode.Y));
      FB := Abs(LPart.PerpDist(AStaleNode.X + AStaleNode.Dx, AStaleNode.Y + AStaleNode.Dy));

      if (FA < DIST_EPSILON) and (FB < DIST_EPSILON) then
      begin
        // Found it: does it run in the same direction?
        if AStaleNode.Dx * LPart.PdX + AStaleNode.Dy * LPart.PdY < 0 then
          AStaleOpposite := 1
        else
          AStaleOpposite := 0;
        Exit(LPart);
      end;
    end;
    LPart := LPart.Next;
  end;

  for LNum := 0 to 1 do
  begin
    if not Assigned(APartList.Subs[LNum]) then
      Continue;
    Result := FindSegFromStaleNode(APartList.Subs[LNum], AStaleNode, AStaleOpposite);
    if Assigned(Result) then
      Exit;
  end;

  Result := nil;
end;

procedure TGlbspPartitioner.PickNodeWorker(const APartList, ASegList: TGlbspSuperBlock;
  var ABest: TGlbspSeg; var ABestCost: Integer);
var
  LPart: TGlbspSeg;
  LNum: Integer;
  LCost: Integer;
begin
  // Every seg is tried as a partition
  LPart := APartList.Segs;
  while Assigned(LPart) do
  begin
    // Minisegs are never partition candidates
    if Assigned(LPart.Linedef) then
    begin
      LCost := EvalPartition(ASegList, LPart, ABestCost);

      // Unsuitable or too costly?
      if (LCost >= 0) and (LCost < ABestCost) then
      begin
        ABestCost := LCost;
        ABest := LPart;
      end;
    end;
    LPart := LPart.Next;
  end;

  for LNum := 0 to 1 do
  begin
    if Assigned(APartList.Subs[LNum]) then
      PickNodeWorker(APartList.Subs[LNum], ASegList, ABest, ABestCost);
  end;
end;

function TGlbspPartitioner.PickNode(const ASegList: TGlbspSuperBlock;
  var AStaleNode: TGlbspNode; var AStaleOpposite: Integer): TGlbspSeg;
var
  LBestCost: Integer;
begin
  Result := nil;
  LBestCost := MaxInt;

  // When only the GL nodes are built, the original nodes are assumed to be
  // good choices and are reused as much as possible: this saves a lot of
  // time on large levels
  if Assigned(AStaleNode) and (ASegList.RealNum >= SEG_REUSE_THRESHHOLD) then
  begin
    Result := FindSegFromStaleNode(ASegList, AStaleNode, AStaleOpposite);

    if Assigned(Result) and (EvalPartition(ASegList, Result, LBestCost) < 0) then
      Result := nil;

    if Assigned(Result) then
      Exit;
  end;

  AStaleNode := nil;

  PickNodeWorker(ASegList, ASegList, Result, LBestCost);
end;

procedure TGlbspPartitioner.DivideOneSeg(const ACur, APart: TGlbspSeg; const ALeftList,
  ARightList: TGlbspSuperBlock; var ACutList: TGlbspIntersection);
var
  LNewSeg: TGlbspSeg;
  LX, LY: Double;
  A, B: Double;
  LSelfRef: Boolean;
begin
  // The relation of the lines to each other
  A := APart.PerpDist(ACur.PsX, ACur.PsY);
  B := APart.PerpDist(ACur.PeX, ACur.PeY);

  LSelfRef := Assigned(ACur.Linedef) and ACur.Linedef.SelfRef;

  if ACur.SourceLine = APart.SourceLine then
  begin
    A := 0;
    B := 0;
  end;

  // On the same line: the direction tells the side
  if (Abs(A) <= DIST_EPSILON) and (Abs(B) <= DIST_EPSILON) then
  begin
    AddIntersection(ACutList, ACur.Start, APart, LSelfRef);
    AddIntersection(ACutList, ACur.EndVertex, APart, LSelfRef);

    if ACur.PdX * APart.PdX + ACur.PdY * APart.PdY < 0 then
      TGlbspSuperBlocks.AddSegToSuper(ALeftList, ACur)
    else
      TGlbspSuperBlocks.AddSegToSuper(ARightList, ACur);
    Exit;
  end;

  // Right side
  if (A > -DIST_EPSILON) and (B > -DIST_EPSILON) then
  begin
    if A < DIST_EPSILON then
      AddIntersection(ACutList, ACur.Start, APart, LSelfRef)
    else if B < DIST_EPSILON then
      AddIntersection(ACutList, ACur.EndVertex, APart, LSelfRef);

    TGlbspSuperBlocks.AddSegToSuper(ARightList, ACur);
    Exit;
  end;

  // Left side
  if (A < DIST_EPSILON) and (B < DIST_EPSILON) then
  begin
    if A > -DIST_EPSILON then
      AddIntersection(ACutList, ACur.Start, APart, LSelfRef)
    else if B > -DIST_EPSILON then
      AddIntersection(ACutList, ACur.EndVertex, APart, LSelfRef);

    TGlbspSuperBlocks.AddSegToSuper(ALeftList, ACur);
    Exit;
  end;

  // A and B are not zero and have opposite signs: the seg is split
  ComputeIntersection(ACur, APart, A, B, LX, LY);

  LNewSeg := SplitSeg(ACur, LX, LY);

  AddIntersection(ACutList, ACur.EndVertex, APart, LSelfRef);

  if A < 0 then
  begin
    TGlbspSuperBlocks.AddSegToSuper(ALeftList, ACur);
    TGlbspSuperBlocks.AddSegToSuper(ARightList, LNewSeg);
  end
  else
  begin
    TGlbspSuperBlocks.AddSegToSuper(ARightList, ACur);
    TGlbspSuperBlocks.AddSegToSuper(ALeftList, LNewSeg);
  end;
end;

procedure TGlbspPartitioner.SeparateSegs(const ASegList: TGlbspSuperBlock;
  const APart: TGlbspSeg; const ALeftList, ARightList: TGlbspSuperBlock;
  var ACutList: TGlbspIntersection);
var
  LCur: TGlbspSeg;
  LNum: Integer;
  LBlock: TGlbspSuperBlock;
begin
  while Assigned(ASegList.Segs) do
  begin
    LCur := ASegList.Segs;
    ASegList.Segs := LCur.Next;
    LCur.Block := nil;

    DivideOneSeg(LCur, APart, ALeftList, ARightList, ACutList);
  end;

  // The sub-blocks
  for LNum := 0 to 1 do
  begin
    LBlock := ASegList.Subs[LNum];
    if Assigned(LBlock) then
    begin
      SeparateSegs(LBlock, APart, ALeftList, ARightList, ACutList);

      if LBlock.RealNum + LBlock.MiniNum > 0 then
        raise EGlbspLevelException.CreateFmt('SeparateSegs: child %d not empty !', [LNum]);

      LBlock.Free;
      ASegList.Subs[LNum] := nil;
    end;
  end;

  ASegList.RealNum := 0;
  ASegList.MiniNum := 0;
end;

class procedure TGlbspPartitioner.FindLimitWorker(const ABlock: TGlbspSuperBlock;
  var ABBox: TGlbspBBox);
var
  LCur: TGlbspSeg;
  LNum: Integer;
  LX1, LY1, LX2, LY2: Double;
  LLx, LLy, LHx, LHy: Integer;
begin
  LCur := ABlock.Segs;
  while Assigned(LCur) do
  begin
    LX1 := LCur.Start.X;
    LY1 := LCur.Start.Y;
    LX2 := LCur.EndVertex.X;
    LY2 := LCur.EndVertex.Y;

    LLx := Floor(Min(LX1, LX2));
    LLy := Floor(Min(LY1, LY2));
    LHx := Ceil(Max(LX1, LX2));
    LHy := Ceil(Max(LY1, LY2));

    if LLx < ABBox.MinX then
      ABBox.MinX := LLx;
    if LLy < ABBox.MinY then
      ABBox.MinY := LLy;
    if LHx > ABBox.MaxX then
      ABBox.MaxX := LHx;
    if LHy > ABBox.MaxY then
      ABBox.MaxY := LHy;

    LCur := LCur.Next;
  end;

  for LNum := 0 to 1 do
  begin
    if Assigned(ABlock.Subs[LNum]) then
      FindLimitWorker(ABlock.Subs[LNum], ABBox);
  end;
end;

class function TGlbspPartitioner.FindLimits(const ASegList: TGlbspSuperBlock): TGlbspBBox;
begin
  Result.MinX := SHRT_MAX;
  Result.MinY := SHRT_MAX;
  Result.MaxX := SHRT_MIN;
  Result.MaxY := SHRT_MIN;
  FindLimitWorker(ASegList, Result);
end;

procedure TGlbspPartitioner.AddMinisegs(const APart: TGlbspSeg; const ALeftList,
  ARightList: TGlbspSuperBlock; ACutList: TGlbspIntersection);
var
  LCur, LNext: TGlbspIntersection;
  LSeg, LBuddy: TGlbspSeg;
  LLen: Double;
begin
  if not Assigned(ACutList) then
    Exit;

  try
    // Step 1: fix the problems of the intersection list
    LCur := ACutList;
    LNext := LCur.Next;

    while Assigned(LCur) and Assigned(LNext) do
    begin
      LLen := LNext.AlongDist - LCur.AlongDist;

      if LLen < -0.1 then
        raise EGlbspLevelException.Create(Format(
          'Bad order in intersect list: %.3f > %.3f', [LCur.AlongDist, LNext.AlongDist],
          TFormatSettings.Invariant));

      if LLen > 0.2 then
      begin
        LCur := LNext;
        LNext := LCur.Next;
        Continue;
      end;

      if LLen > DIST_EPSILON then
        MiniWarn(Format('Skipping very short seg (len=%.3f) near (%.1f,%.1f)',
          [LLen, LCur.Vertex.X, LCur.Vertex.Y], TFormatSettings.Invariant));

      // The two intersections are merged into one
      if LCur.SelfRef and not LNext.SelfRef then
      begin
        if Assigned(LCur.Before) and Assigned(LNext.Before) then
          LCur.Before := LNext.Before;
        if Assigned(LCur.After) and Assigned(LNext.After) then
          LCur.After := LNext.After;
        LCur.SelfRef := False;
      end;

      if not Assigned(LCur.Before) and Assigned(LNext.Before) then
        LCur.Before := LNext.Before;
      if not Assigned(LCur.After) and Assigned(LNext.After) then
        LCur.After := LNext.After;

      // The unused cut is unlinked (it is released with the others)
      LCur.Next := LNext.Next;
      LNext := LCur.Next;
    end;

    // Step 2: find the connections in the intersection list
    LCur := ACutList;
    while Assigned(LCur) and Assigned(LCur.Next) do
    begin
      LNext := LCur.Next;
      try
        if not Assigned(LCur.After) and not Assigned(LNext.Before) then
          Continue;

        // Some nasty OPEN/CLOSED or CLOSED/OPEN cases
        if Assigned(LCur.After) and not Assigned(LNext.Before) then
        begin
          if not LCur.SelfRef and not LCur.After.WarnedUnclosed then
          begin
            MiniWarn(Format('Sector #%d is unclosed near (%.1f,%.1f)',
              [LCur.After.Index, (LCur.Vertex.X + LNext.Vertex.X) / 2.0,
              (LCur.Vertex.Y + LNext.Vertex.Y) / 2.0], TFormatSettings.Invariant));
            LCur.After.WarnedUnclosed := True;
          end;
          Continue;
        end
        else if not Assigned(LCur.After) and Assigned(LNext.Before) then
        begin
          if not LNext.SelfRef and not LNext.Before.WarnedUnclosed then
          begin
            MiniWarn(Format('Sector #%d is unclosed near (%.1f,%.1f)',
              [LNext.Before.Index, (LCur.Vertex.X + LNext.Vertex.X) / 2.0,
              (LCur.Vertex.Y + LNext.Vertex.Y) / 2.0], TFormatSettings.Invariant));
            LNext.Before.WarnedUnclosed := True;
          end;
          Continue;
        end;

        // Definite open space: a sanity check on the sectors
        if LCur.After <> LNext.Before then
        begin
          if not LCur.SelfRef and not LNext.SelfRef then
            MiniWarn(Format('Sector mismatch: #%d (%.1f,%.1f) != #%d (%.1f,%.1f)',
              [LCur.After.Index, LCur.Vertex.X, LCur.Vertex.Y, LNext.Before.Index,
              LNext.Vertex.X, LNext.Vertex.Y], TFormatSettings.Invariant));

          // The sector that is not self-referencing is preferred
          if LCur.SelfRef and not LNext.SelfRef then
            LCur.After := LNext.Before;
        end;

        // The pair of minisegs
        LSeg := FData.NewSeg;
        LBuddy := FData.NewSeg;

        LSeg.Partner := LBuddy;
        LBuddy.Partner := LSeg;

        LSeg.Start := LCur.Vertex;
        LSeg.EndVertex := LNext.Vertex;

        LBuddy.Start := LNext.Vertex;
        LBuddy.EndVertex := LCur.Vertex;

        // Linedef stays nil and side zero: they are not needed for minisegs
        LSeg.Sector := LCur.After;
        LBuddy.Sector := LCur.After;

        LSeg.Index := -1;
        LBuddy.Index := -1;

        LSeg.SourceLine := APart.Linedef;
        LBuddy.SourceLine := APart.Linedef;

        RecomputeSeg(LSeg);
        RecomputeSeg(LBuddy);

        TGlbspSuperBlocks.AddSegToSuper(ARightList, LSeg);
        TGlbspSuperBlocks.AddSegToSuper(ALeftList, LBuddy);
      finally
        LCur := LCur.Next;
      end;
    end;
  finally
    // All the intersections are released
    FCuts.Clear;
  end;
end;

end.
