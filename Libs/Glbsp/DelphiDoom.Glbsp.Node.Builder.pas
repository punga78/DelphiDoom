{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - builds the BSP tree from the segs of a level            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of node.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                     }
{  Based on 'BSP 2.3' by Colin Reed, Lee Killough and others, and on the       }
{  algorithm of DEU5beta (Raphael Quinet)                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Node.Builder;

interface

uses
  System.Classes,
  DelphiDoom.Glbsp.Level.Analyzer,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Node.Partitioner,
  DelphiDoom.Glbsp.Options,
  DelphiDoom.Glbsp.Wad.Document;

type
  /// <summary>
  ///   Origin and size, in blocks, of the blockmap: the segs are indexed on
  ///   the same area
  /// </summary>
  TGlbspBlockmapBounds = record
    X, Y: Integer;
    Width, Height: Integer;
  end;

  /// <summary>
  ///   Creates the segs of a level and divides them recursively until each
  ///   part is convex: the parts are the subsectors, the divisions the nodes
  /// </summary>
  TGlbspNodeBuilder = class
  private
    FData: TGlbspLevelData;
    FAnalyzer: TGlbspLevelAnalyzer;
    FPartitioner: TGlbspPartitioner;
    FOptions: TGlbspOptions;
    FWad: TGlbspWad;
    FMessages: TStrings;
    procedure Warn(const AMessage: string);
    procedure MiniWarn(const AMessage: string);
    function CreateOneSeg(const ALine: TGlbspLinedef; const AStart,
      AEnd: TGlbspVertex; const ASide: TGlbspSidedef; const ASideNum: Integer): TGlbspSeg;
    procedure DetermineMiddle(const ASub: TGlbspSubsec);
    procedure ClockwiseOrder(const ASub: TGlbspSubsec);
    procedure SanityCheckClosed(const ASub: TGlbspSubsec);
    procedure SanityCheckSameSector(const ASub: TGlbspSubsec);
    procedure SanityCheckHasRealSeg(const ASub: TGlbspSubsec);
    procedure RenumberSubsecSegs(const ASub: TGlbspSubsec);
    procedure CreateSubsecWorker(const ASub: TGlbspSubsec; const ABlock: TGlbspSuperBlock);
    function CreateSubsec(const ASegList: TGlbspSuperBlock): TGlbspSubsec;
    procedure NormaliseSubsector(const ASub: TGlbspSubsec);
    procedure RoundOffSubsector(const ASub: TGlbspSubsec);
  public
    /// <param name="AData">Level being built</param>
    /// <param name="AAnalyzer">Analyzer of the same level</param>
    /// <param name="APartitioner">Chooses and applies the partitions</param>
    /// <param name="AOptions">Options of the build</param>
    /// <param name="AWad">
    ///   WAD of the level, to mark the failures of the current level; may be nil
    /// </param>
    /// <param name="AMessages">Receives the warnings; may be nil</param>
    constructor Create(const AData: TGlbspLevelData; const AAnalyzer: TGlbspLevelAnalyzer;
      const APartitioner: TGlbspPartitioner; const AOptions: TGlbspOptions;
      const AWad: TGlbspWad; const AMessages: TStrings);

    /// <summary>
    ///   Creates one seg for each side of each linedef and returns the
    ///   superblock that holds them; the caller frees it
    /// </summary>
    function CreateSegs(const ABounds: TGlbspBlockmapBounds): TGlbspSuperBlock;

    /// <summary>
    ///   Divides the seg list: when it is convex the segs become a subsector
    ///   (ASub is set, ANode nil), otherwise a node is made and the two halves
    ///   are built recursively (ANode is set, ASub nil)
    /// </summary>
    procedure BuildNodes(const ASegList: TGlbspSuperBlock; out ANode: TGlbspNode;
      out ASub: TGlbspSubsec; const ADepth: Integer; AStaleNode: TGlbspNode);

    /// <summary>Height of the tree that starts at ANode (a leaf is 1)</summary>
    class function ComputeBspHeight(const ANode: TGlbspNode): Integer; static;

    /// <summary>
    ///   Puts the segs of every subsector in clockwise order and renumbers
    ///   them. It cannot be done while building, because splitting a seg
    ///   with a partner may insert a seg in the wrong place of the partner's list
    /// </summary>
    procedure ClockwiseBspTree;

    /// <summary>
    ///   Converts the tree from the GL standard to the normal one: the
    ///   minisegs are removed
    /// </summary>
    procedure NormaliseBspTree;

    /// <summary>
    ///   Rounds the vertices to integers: the segs that become degenerate
    ///   are removed
    /// </summary>
    procedure RoundOffBspTree;
  end;

implementation

uses
  System.Generics.Collections,
  System.Math,
  System.SysUtils,
  DelphiDoom.Glbsp.Node.SuperBlocks,
  DelphiDoom.Glbsp.Util,
  DelphiDoom.Glbsp.Wad.Types;

const
  LONG_PARTITION_LENGTH = 30000;
  HUGE_LINE_COORDINATE = 10000;
  HUGE_LINE_LENGTH = 30000;
  REMOVED_SEG_INDEX = 1 shl 24;

{ TGlbspNodeBuilder }

constructor TGlbspNodeBuilder.Create(const AData: TGlbspLevelData;
  const AAnalyzer: TGlbspLevelAnalyzer; const APartitioner: TGlbspPartitioner;
  const AOptions: TGlbspOptions; const AWad: TGlbspWad; const AMessages: TStrings);
begin
  inherited Create;
  FData := AData;
  FAnalyzer := AAnalyzer;
  FPartitioner := APartitioner;
  FOptions := AOptions;
  FWad := AWad;
  FMessages := AMessages;
end;

procedure TGlbspNodeBuilder.Warn(const AMessage: string);
begin
  if Assigned(FMessages) then
    FMessages.Add(AMessage);
end;

procedure TGlbspNodeBuilder.MiniWarn(const AMessage: string);
begin
  if FOptions.MiniWarnings then
    Warn(AMessage);
end;

function TGlbspNodeBuilder.CreateOneSeg(const ALine: TGlbspLinedef; const AStart,
  AEnd: TGlbspVertex; const ASide: TGlbspSidedef; const ASideNum: Integer): TGlbspSeg;
begin
  Result := FData.NewSeg;

  // A bad sidedef
  if not Assigned(ASide.Sector) then
  begin
    Warn(Format('Bad sidedef on linedef #%d (Z_CheckHeap error)', [ALine.Index]));
    if Assigned(FWad) then
      FWad.MarkSoftFailure(LIMIT_BAD_SIDE);
  end;

  Result.Start := AStart;
  Result.EndVertex := AEnd;
  Result.Linedef := ALine;
  Result.Side := ASideNum;
  Result.Sector := ASide.Sector;
  Result.Partner := nil;

  Result.SourceLine := Result.Linedef;
  Result.Index := -1;

  TGlbspPartitioner.RecomputeSeg(Result);
end;

function TGlbspNodeBuilder.CreateSegs(const ABounds: TGlbspBlockmapBounds): TGlbspSuperBlock;
var
  LLine: TGlbspLinedef;
  LLeft, LRight: TGlbspSeg;
  LWindow: TGlbspSeg;
begin
  Result := TGlbspSuperBlock.Create;

  Result.X1 := ABounds.X;
  Result.Y1 := ABounds.Y;
  Result.X2 := Result.X1 + 128 * TGlbspUtil.RoundPow2(ABounds.Width);
  Result.Y2 := Result.Y1 + 128 * TGlbspUtil.RoundPow2(ABounds.Height);

  // The linedefs give the sidedefs
  for LLine in FData.Linedefs do
  begin
    LRight := nil;

    // Zero length lines are ignored
    if LLine.ZeroLength then
      Continue;

    // Overlapping lines too
    if Assigned(LLine.Overlap) then
      Continue;

    // Self-referencing lines, only when explicitly disabled
    if LLine.SelfRef and FOptions.SkipSelfRef then
      Continue;

    // Humongously long lines
    if (Abs(LLine.Start.X - LLine.EndVertex.X) >= HUGE_LINE_COORDINATE) or
      (Abs(LLine.Start.Y - LLine.EndVertex.Y) >= HUGE_LINE_COORDINATE) then
    begin
      if Sqrt(Sqr(LLine.Start.X - LLine.EndVertex.X) +
        Sqr(LLine.Start.Y - LLine.EndVertex.Y)) >= HUGE_LINE_LENGTH then
        Warn(Format('Linedef #%d is VERY long, it may cause problems', [LLine.Index]));
    end;

    if Assigned(LLine.Right) then
    begin
      LRight := CreateOneSeg(LLine, LLine.Start, LLine.EndVertex, LLine.Right, 0);
      TGlbspSuperBlocks.AddSegToSuper(Result, LRight);
    end
    else
      Warn(Format('Linedef #%d has no right sidedef!', [LLine.Index]));

    if Assigned(LLine.Left) then
    begin
      LLeft := CreateOneSeg(LLine, LLine.EndVertex, LLine.Start, LLine.Left, 1);
      TGlbspSuperBlocks.AddSegToSuper(Result, LLeft);

      if Assigned(LRight) then
      begin
        // Partner segs always keep a one to one correspondence, so if one of
        // them is split the other must be split too
        LLeft.Partner := LRight;
        LRight.Partner := LLeft;
      end;
    end
    else
    begin
      if LLine.TwoSided then
      begin
        Warn(Format('Linedef #%d is 2s but has no left sidedef', [LLine.Index]));
        LLine.TwoSided := False;
      end;

      // The "One-Sided Window" trick
      if Assigned(LLine.WindowEffect) then
      begin
        LWindow := FData.NewSeg;

        LWindow.Start := LLine.EndVertex;
        LWindow.EndVertex := LLine.Start;
        LWindow.Side := 1;
        LWindow.Linedef := LRight.Linedef;
        LWindow.Sector := LLine.WindowEffect;

        LWindow.SourceLine := LLine;
        LWindow.Index := -1;

        TGlbspPartitioner.RecomputeSeg(LWindow);

        TGlbspSuperBlocks.AddSegToSuper(Result, LWindow);

        LWindow.Partner := LRight;
        LRight.Partner := LWindow;
      end;
    end;
  end;
end;

procedure TGlbspNodeBuilder.DetermineMiddle(const ASub: TGlbspSubsec);
var
  LCur: TGlbspSeg;
  LMidX, LMidY: Double;
  LTotal: Integer;
begin
  LMidX := 0;
  LMidY := 0;
  LTotal := 0;

  LCur := ASub.SegList;
  while Assigned(LCur) do
  begin
    LMidX := LMidX + LCur.Start.X + LCur.EndVertex.X;
    LMidY := LMidY + LCur.Start.Y + LCur.EndVertex.Y;
    Inc(LTotal, 2);
    LCur := LCur.Next;
  end;

  ASub.MidX := LMidX / LTotal;
  ASub.MidY := LMidY / LTotal;
end;

procedure TGlbspNodeBuilder.ClockwiseOrder(const ASub: TGlbspSubsec);
var
  LCur: TGlbspSeg;
  LArray: TArray<TGlbspSeg>;
  LTotal: Integer;
  LIndex: Integer;
  LFirst: Integer;
  LScore: Integer;
  LCurScore: Integer;
  LA, LB: TGlbspSeg;
  LAngle1, LAngle2: Double;
  LJ: Integer;
begin
  // The segs go in an array to be manipulated
  LTotal := 0;
  LCur := ASub.SegList;
  while Assigned(LCur) do
  begin
    Inc(LTotal);
    LCur := LCur.Next;
  end;

  SetLength(LArray, LTotal);
  LIndex := 0;
  LCur := ASub.SegList;
  while Assigned(LCur) do
  begin
    LArray[LIndex] := LCur;
    Inc(LIndex);
    LCur := LCur.Next;
  end;

  // Sorted by angle (from the middle point to the start vertex) with the
  // "double bubble" sorter: the clockwise order means descending angles
  LIndex := 0;
  while LIndex + 1 < LTotal do
  begin
    LA := LArray[LIndex];
    LB := LArray[LIndex + 1];

    LAngle1 := TGlbspUtil.ComputeAngle(LA.Start.X - ASub.MidX, LA.Start.Y - ASub.MidY);
    LAngle2 := TGlbspUtil.ComputeAngle(LB.Start.X - ASub.MidX, LB.Start.Y - ASub.MidY);

    if LAngle1 + ANG_EPSILON < LAngle2 then
    begin
      // Swap them and bubble down
      LArray[LIndex] := LB;
      LArray[LIndex + 1] := LA;
      if LIndex > 0 then
        Dec(LIndex);
    end
    else
      Inc(LIndex);
  end;

  // The first seg: the game engine typically uses it to find the sector.
  // The self-referencing linedefs are not liked (often used for deep water)
  LFirst := 0;
  LScore := -1;
  for LIndex := 0 to LTotal - 1 do
  begin
    LCurScore := 3;

    if not Assigned(LArray[LIndex].Linedef) then
      LCurScore := 0
    else if Assigned(LArray[LIndex].Linedef.WindowEffect) then
      LCurScore := 1
    else if LArray[LIndex].Linedef.SelfRef then
      LCurScore := 2;

    if LCurScore > LScore then
    begin
      LFirst := LIndex;
      LScore := LCurScore;
    end;
  end;

  // The sorted array goes back into the subsector
  ASub.SegList := nil;
  for LIndex := LTotal - 1 downto 0 do
  begin
    LJ := (LIndex + LFirst) mod LTotal;
    LArray[LJ].Next := ASub.SegList;
    ASub.SegList := LArray[LJ];
  end;
end;

procedure TGlbspNodeBuilder.SanityCheckClosed(const ASub: TGlbspSubsec);
var
  LCur, LNext: TGlbspSeg;
  LTotal, LGaps: Integer;
begin
  LTotal := 0;
  LGaps := 0;

  LCur := ASub.SegList;
  while Assigned(LCur) do
  begin
    if Assigned(LCur.Next) then
      LNext := LCur.Next
    else
      LNext := ASub.SegList;

    if (LCur.EndVertex.X <> LNext.Start.X) or (LCur.EndVertex.Y <> LNext.Start.Y) then
      Inc(LGaps);

    Inc(LTotal);
    LCur := LCur.Next;
  end;

  if LGaps > 0 then
    MiniWarn(Format('Subsector #%d near (%.1f,%.1f) is not closed (%d gaps, %d segs)',
      [ASub.Index, ASub.MidX, ASub.MidY, LGaps, LTotal]));
end;

procedure TGlbspNodeBuilder.SanityCheckSameSector(const ASub: TGlbspSubsec);
var
  LCur, LCompare: TGlbspSeg;
begin
  // A suitable seg for the comparison
  LCompare := ASub.SegList;
  while Assigned(LCompare) do
  begin
    if Assigned(LCompare.Sector) and not LCompare.Sector.Coalesce then
      Break;
    LCompare := LCompare.Next;
  end;

  if not Assigned(LCompare) then
    Exit;

  LCur := LCompare.Next;
  while Assigned(LCur) do
  begin
    // All the subsectors must come from the same sector, unless it is marked
    // "special" with a sector tag of 900 or more (Lee Killough)
    if Assigned(LCur.Sector) and (LCur.Sector <> LCompare.Sector) and
      not LCur.Sector.Coalesce and
      (LCompare.Sector.WarnedFacing <> LCur.Sector.Index) then
    begin
      // Prevents an excessive number of warnings
      LCompare.Sector.WarnedFacing := LCur.Sector.Index;

      if Assigned(LCur.Linedef) then
        MiniWarn(Format('Sector #%d has sidedef facing #%d (line #%d) near (%.0f,%.0f).',
          [LCompare.Sector.Index, LCur.Sector.Index, LCur.Linedef.Index, ASub.MidX,
          ASub.MidY]))
      else
        MiniWarn(Format('Sector #%d has sidedef facing #%d near (%.0f,%.0f).',
          [LCompare.Sector.Index, LCur.Sector.Index, ASub.MidX, ASub.MidY]));
    end;
    LCur := LCur.Next;
  end;
end;

procedure TGlbspNodeBuilder.SanityCheckHasRealSeg(const ASub: TGlbspSubsec);
var
  LCur: TGlbspSeg;
begin
  LCur := ASub.SegList;
  while Assigned(LCur) do
  begin
    if Assigned(LCur.Linedef) then
      Exit;
    LCur := LCur.Next;
  end;

  raise EGlbspLevelException.CreateFmt(
    'Subsector #%d near (%.1f,%.1f) has no real seg !', [ASub.Index, ASub.MidX, ASub.MidY]);
end;

procedure TGlbspNodeBuilder.RenumberSubsecSegs(const ASub: TGlbspSubsec);
var
  LCur: TGlbspSeg;
begin
  ASub.SegCount := 0;

  LCur := ASub.SegList;
  while Assigned(LCur) do
  begin
    LCur.Index := FData.NumCompleteSeg;
    FData.NumCompleteSeg := FData.NumCompleteSeg + 1;
    Inc(ASub.SegCount);
    LCur := LCur.Next;
  end;
end;

procedure TGlbspNodeBuilder.CreateSubsecWorker(const ASub: TGlbspSubsec;
  const ABlock: TGlbspSuperBlock);
var
  LCur: TGlbspSeg;
  LNum: Integer;
  LChild: TGlbspSuperBlock;
begin
  while Assigned(ABlock.Segs) do
  begin
    // The first seg is unlinked from the block...
    LCur := ABlock.Segs;
    ABlock.Segs := LCur.Next;

    // ...and linked at the head of the list of the subsector
    LCur.Next := ASub.SegList;
    LCur.Block := nil;
    ASub.SegList := LCur;
  end;

  for LNum := 0 to 1 do
  begin
    LChild := ABlock.Subs[LNum];
    if Assigned(LChild) then
    begin
      CreateSubsecWorker(ASub, LChild);

      if LChild.RealNum + LChild.MiniNum > 0 then
        raise EGlbspLevelException.CreateFmt('CreateSubsec: child %d not empty !', [LNum]);

      LChild.Free;
      ABlock.Subs[LNum] := nil;
    end;
  end;

  ABlock.RealNum := 0;
  ABlock.MiniNum := 0;
end;

function TGlbspNodeBuilder.CreateSubsec(const ASegList: TGlbspSuperBlock): TGlbspSubsec;
begin
  Result := FData.NewSubsec;
  Result.Index := FData.Subsecs.Count - 1;

  // The segs go into the subsector
  CreateSubsecWorker(Result, ASegList);

  DetermineMiddle(Result);
end;

class function TGlbspNodeBuilder.ComputeBspHeight(const ANode: TGlbspNode): Integer;
begin
  if Assigned(ANode) then
    Result := Max(ComputeBspHeight(ANode.L.Node), ComputeBspHeight(ANode.R.Node)) + 1
  else
    Result := 1;
end;

procedure TGlbspNodeBuilder.BuildNodes(const ASegList: TGlbspSuperBlock;
  out ANode: TGlbspNode; out ASub: TGlbspSubsec; const ADepth: Integer;
  AStaleNode: TGlbspNode);
var
  LBest: TGlbspSeg;
  LRights, LLefts: TGlbspSuperBlock;
  LCutList: TGlbspIntersection;
  LStaleOpposite: Integer;
  LNode: TGlbspNode;
  LNextStale: TGlbspNode;
begin
  ANode := nil;
  ASub := nil;
  LStaleOpposite := 0;

  // The best node to use; none means the list is convex
  LBest := FPartitioner.PickNode(ASegList, AStaleNode, LStaleOpposite);

  if not Assigned(LBest) then
  begin
    ASub := CreateSubsec(ASegList);
    Exit;
  end;

  // The left and right superblocks
  LLefts := TGlbspSuperBlock.Create;
  LRights := TGlbspSuperBlock.Create;
  try
    LLefts.X1 := ASegList.X1;
    LRights.X1 := ASegList.X1;
    LLefts.Y1 := ASegList.Y1;
    LRights.Y1 := ASegList.Y1;
    LLefts.X2 := ASegList.X2;
    LRights.X2 := ASegList.X2;
    LLefts.Y2 := ASegList.Y2;
    LRights.Y2 := ASegList.Y2;

    // The segs are divided into two lists: left and right
    LCutList := nil;
    FPartitioner.SeparateSegs(ASegList, LBest, LLefts, LRights, LCutList);

    if LRights.RealNum + LRights.MiniNum = 0 then
      raise EGlbspLevelException.Create('Separated seg-list has no RIGHT side');
    if LLefts.RealNum + LLefts.MiniNum = 0 then
      raise EGlbspLevelException.Create('Separated seg-list has no LEFT side');

    FPartitioner.AddMinisegs(LBest, LLefts, LRights, LCutList);

    LNode := FData.NewNode;
    ANode := LNode;

    if LBest.Side = 0 then
    begin
      LNode.X := Trunc(LBest.Linedef.Start.X);
      LNode.Y := Trunc(LBest.Linedef.Start.Y);
      LNode.Dx := Trunc(LBest.Linedef.EndVertex.X - LNode.X);
      LNode.Dy := Trunc(LBest.Linedef.EndVertex.Y - LNode.Y);
    end
    else
    begin
      // Left side
      LNode.X := Trunc(LBest.Linedef.EndVertex.X);
      LNode.Y := Trunc(LBest.Linedef.EndVertex.Y);
      LNode.Dx := Trunc(LBest.Linedef.Start.X - LNode.X);
      LNode.Dy := Trunc(LBest.Linedef.Start.Y - LNode.Y);
    end;

    // A really long partition overflows dx and dy in the NODES lump
    if LBest.PLength >= LONG_PARTITION_LENGTH then
    begin
      if (LNode.Dx <> 0) and (LNode.Dy <> 0) and (((LNode.Dx and 1) <> 0) or
        ((LNode.Dy and 1) <> 0)) then
        MiniWarn(Format('Loss of accuracy on VERY long node: (%d,%d) -> (%d,%d)',
          [LNode.X, LNode.Y, LNode.X + LNode.Dx, LNode.Y + LNode.Dy]));

      LNode.TooLong := 1;
    end;

    // The limits of the vertices
    LNode.L.Bounds := TGlbspPartitioner.FindLimits(LLefts);
    LNode.R.Bounds := TGlbspPartitioner.FindLimits(LRights);

    LNextStale := nil;
    if Assigned(AStaleNode) then
    begin
      if LStaleOpposite <> 0 then
        LNextStale := AStaleNode.R.Node
      else
        LNextStale := AStaleNode.L.Node;
    end;
    BuildNodes(LLefts, LNode.L.Node, LNode.L.Subsec, ADepth + 1, LNextStale);
    FreeAndNil(LLefts);

    LNextStale := nil;
    if Assigned(AStaleNode) then
    begin
      if LStaleOpposite <> 0 then
        LNextStale := AStaleNode.L.Node
      else
        LNextStale := AStaleNode.R.Node;
    end;
    BuildNodes(LRights, LNode.R.Node, LNode.R.Subsec, ADepth + 1, LNextStale);
  finally
    LLefts.Free;
    LRights.Free;
  end;
end;

procedure TGlbspNodeBuilder.ClockwiseBspTree;
var
  LSub: TGlbspSubsec;
begin
  for LSub in FData.Subsecs do
  begin
    ClockwiseOrder(LSub);
    RenumberSubsecSegs(LSub);

    // Some sanity checks
    SanityCheckClosed(LSub);
    SanityCheckSameSector(LSub);
    SanityCheckHasRealSeg(LSub);
  end;
end;

procedure TGlbspNodeBuilder.NormaliseSubsector(const ASub: TGlbspSubsec);
var
  LNewHead, LNewTail, LCur: TGlbspSeg;
begin
  LNewHead := nil;
  LNewTail := nil;

  while Assigned(ASub.SegList) do
  begin
    // The head is removed
    LCur := ASub.SegList;
    ASub.SegList := LCur.Next;

    // Only the non minisegs go to the new list
    if Assigned(LCur.Linedef) then
    begin
      LCur.Next := nil;

      if Assigned(LNewTail) then
        LNewTail.Next := LCur
      else
        LNewHead := LCur;
      LNewTail := LCur;

      // Updated later
      LCur.Index := -1;
    end
    else
      // A really high value, so that the sort of the segs moves all the
      // minisegs to the top of the seg array
      LCur.Index := REMOVED_SEG_INDEX;
  end;

  if not Assigned(LNewHead) then
    raise EGlbspLevelException.CreateFmt('Subsector %d normalised to being EMPTY',
      [ASub.Index]);

  ASub.SegList := LNewHead;
end;

procedure TGlbspNodeBuilder.NormaliseBspTree;
var
  LSub: TGlbspSubsec;
begin
  // The minisegs are unlinked from each subsector
  FData.NumCompleteSeg := 0;

  for LSub in FData.Subsecs do
  begin
    NormaliseSubsector(LSub);
    RenumberSubsecSegs(LSub);
  end;
end;

procedure TGlbspNodeBuilder.RoundOffSubsector(const ASub: TGlbspSubsec);
var
  LNewHead, LNewTail, LCur, LLastRealDegen: TGlbspSeg;
  LRealTotal: Integer;
begin
  LNewHead := nil;
  LNewTail := nil;
  LLastRealDegen := nil;
  LRealTotal := 0;

  // A first pass counts the degenerate segs
  LCur := ASub.SegList;
  while Assigned(LCur) do
  begin
    // The duplex vertices
    if Assigned(LCur.Start.NormalDup) then
      LCur.Start := LCur.Start.NormalDup;
    if Assigned(LCur.EndVertex.NormalDup) then
      LCur.EndVertex := LCur.EndVertex.NormalDup;

    // Is the seg degenerate?
    if (TGlbspUtil.RoundToInt(LCur.Start.X) = TGlbspUtil.RoundToInt(LCur.EndVertex.X)) and
      (TGlbspUtil.RoundToInt(LCur.Start.Y) = TGlbspUtil.RoundToInt(LCur.EndVertex.Y)) then
    begin
      LCur.Degenerate := 1;
      if Assigned(LCur.Linedef) then
        LLastRealDegen := LCur;
    end
    else if Assigned(LCur.Linedef) then
      Inc(LRealTotal);

    LCur := LCur.Next;
  end;

  // The (hopefully rare) case where all the real segs became degenerate
  if LRealTotal = 0 then
  begin
    if not Assigned(LLastRealDegen) then
      raise EGlbspLevelException.CreateFmt('Subsector %d rounded off with NO real segs',
        [ASub.Index]);

    // A new vertex for it
    LLastRealDegen.EndVertex := FAnalyzer.NewVertexDegenerate(LLastRealDegen.Start,
      LLastRealDegen.EndVertex);
    LLastRealDegen.Degenerate := 0;
  end;

  // The second pass removes the blighters
  while Assigned(ASub.SegList) do
  begin
    LCur := ASub.SegList;
    ASub.SegList := LCur.Next;

    if LCur.Degenerate = 0 then
    begin
      LCur.Next := nil;

      if Assigned(LNewTail) then
        LNewTail.Next := LCur
      else
        LNewHead := LCur;
      LNewTail := LCur;

      // Updated later
      LCur.Index := -1;
    end
    else
      LCur.Index := REMOVED_SEG_INDEX;
  end;

  if not Assigned(LNewHead) then
    raise EGlbspLevelException.CreateFmt('Subsector %d rounded off to being EMPTY',
      [ASub.Index]);

  ASub.SegList := LNewHead;
end;

procedure TGlbspNodeBuilder.RoundOffBspTree;
var
  LIndex: Integer;
begin
  FData.NumCompleteSeg := 0;

  // The new degenerate vertices are not subsectors: the loop is by index
  for LIndex := 0 to FData.Subsecs.Count - 1 do
  begin
    RoundOffSubsector(FData.Subsecs[LIndex]);
    RenumberSubsecSegs(FData.Subsecs[LIndex]);
  end;
end;

end.
