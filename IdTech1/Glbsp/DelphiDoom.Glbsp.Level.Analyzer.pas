{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - analysis and pruning of the level data                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of analyze.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                  }
{  Polyobj detection based on code courtesy of Janis Legzdinsh                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Level.Analyzer;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Options;

type
  /// <summary>
  ///   The steps that glbsp does between reading a level and building the
  ///   nodes: it finds duplicates, prunes what is unused, computes the wall
  ///   tips and detects polyobjs, overlapping lines and window effects
  /// </summary>
  /// <remarks>
  ///   Sorting uses the order of the indices as a tie breaker, so that the
  ///   result does not depend on the sort algorithm (qsort of the C library
  ///   is not stable). The warnings glbsp prints go to AMessages
  /// </remarks>
  TGlbspLevelAnalyzer = class
  private
    FData: TGlbspLevelData;
    FOptions: TGlbspOptions;
    FMessages: TStrings;
    procedure Warn(const AMessage: string);
    procedure MarkPolyobjSector(const ASector: TGlbspSector);
    procedure MarkPolyobjPoint(const AX, AY: Double);
    procedure TestForWindowEffect(const ALine: TGlbspLinedef);
    function CompareVertices(const ALeft, ARight: Integer): Integer;
    function CompareSidedefs(const ALeft, ARight: Integer): Integer;
    function CompareLineStarts(const ALeft, ARight: Integer): Integer;
    function CompareLineEnds(const ALeft, ARight: Integer): Integer;
    function SortedIndices(const ACount: Integer;
      const ACompare: TFunc<Integer, Integer, Integer>): TArray<Integer>;
    class procedure KeepOnly<T: class>(const AList: TObjectList<T>;
      const AKept: TList<T>); static;
    class procedure CountWallTips(const AVertex: TGlbspVertex; out AOneSided,
      ATwoSided: Integer); static;
  public
    /// <param name="AData">Level to analyze; it is changed in place</param>
    /// <param name="AOptions">Options of the build</param>
    /// <param name="AMessages">Receives the warnings; may be nil</param>
    constructor Create(const AData: TGlbspLevelData; const AOptions: TGlbspOptions;
      const AMessages: TStrings);

    procedure DetectDuplicateVertices;
    procedure DetectDuplicateSidedefs;
    procedure DetectPolyobjSectors;
    procedure DetectOverlappingLines;
    procedure DetectWindowEffects;

    procedure PruneLinedefs;
    procedure PruneVertices;
    procedure PruneSidedefs;
    procedure PruneSectors;

    /// <summary>Computes the wall tips of all the vertices</summary>
    procedure CalculateWallTips;

    /// <summary>
    ///   New vertex, with the wall tips, for the split of ASeg at (AX, AY)
    /// </summary>
    function NewVertexFromSplitSeg(const ASeg: TGlbspSeg; const AX,
      AY: Double): TGlbspVertex;

    /// <summary>
    ///   New end vertex for a seg that would be zero length after rounding
    ///   its ends to integers. It has no wall tips: use it after the nodes
    ///   are built
    /// </summary>
    function NewVertexDegenerate(const AStart, AEnd: TGlbspVertex): TGlbspVertex;

    /// <summary>
    ///   Sector on the open side of the line that leaves AVertex with the
    ///   given delta; nil if the line is closed (void or along a linedef)
    /// </summary>
    function VertexCheckOpen(const AVertex: TGlbspVertex; const ADx,
      ADy: Double): TGlbspSector;
  end;

implementation

uses
  System.Generics.Defaults,
  System.Math,
  DelphiDoom.Glbsp.Geometry,
  DelphiDoom.Glbsp.Level.Raw,
  DelphiDoom.Glbsp.Util;

const
  POLY_BOX_SZ = 10;

  SNoLinedefs = 'Couldn''t find any Linedefs';
  SNoVertices = 'Couldn''t find any Vertices';
  SNoSidedefs = 'Couldn''t find any Sidedefs';
  SNoSectors = 'Couldn''t find any Sectors';

function LineVertexLowest(const ALine: TGlbspLinedef): Integer;
begin
  // The "lowest" vertex is normally the left-most one; if the line is
  // vertical, the bottom-most. 0 for the start, 1 for the end
  if (Trunc(ALine.Start.X) < Trunc(ALine.EndVertex.X)) or
    ((Trunc(ALine.Start.X) = Trunc(ALine.EndVertex.X)) and
    (Trunc(ALine.Start.Y) < Trunc(ALine.EndVertex.Y))) then
    Result := 0
  else
    Result := 1;
end;

// Same order as memcmp on the 8 bytes of two texture names
function CompareTextureNames(const ALeft, ARight: array of AnsiChar): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
  begin
    if ALeft[LIndex] <> ARight[LIndex] then
      Exit(Ord(ALeft[LIndex]) - Ord(ARight[LIndex]));
  end;
  Result := 0;
end;

procedure AddWallTip(const AData: TGlbspLevelData; const AVertex: TGlbspVertex;
  const ADx, ADy: Double; const ALeft, ARight: TGlbspSector);
var
  LTip: TGlbspWallTip;
  LAfter: TGlbspWallTip;
begin
  LTip := AData.NewWallTip;
  LTip.Angle := TGlbspUtil.ComputeAngle(ADx, ADy);
  LTip.Left := ALeft;
  LTip.Right := ARight;

  // The place is found by increasing angle
  LAfter := AVertex.TipSet;
  while Assigned(LAfter) and Assigned(LAfter.Next) do
    LAfter := LAfter.Next;

  while Assigned(LAfter) and (LTip.Angle + ANG_EPSILON < LAfter.Angle) do
    LAfter := LAfter.Prev;

  // Link it in
  if Assigned(LAfter) then
    LTip.Next := LAfter.Next
  else
    LTip.Next := AVertex.TipSet;
  LTip.Prev := LAfter;

  if Assigned(LAfter) then
  begin
    if Assigned(LAfter.Next) then
      LAfter.Next.Prev := LTip;
    LAfter.Next := LTip;
  end
  else
  begin
    if Assigned(AVertex.TipSet) then
      AVertex.TipSet.Prev := LTip;
    AVertex.TipSet := LTip;
  end;
end;

{ TGlbspLevelAnalyzer }

class procedure TGlbspLevelAnalyzer.KeepOnly<T>(const AList: TObjectList<T>;
  const AKept: TList<T>);
var
  LItem: T;
  LKept: TDictionary<T, Boolean>;
begin
  // Replaces the content of AList with AKept, and frees what is left out
  LKept := TDictionary<T, Boolean>.Create;
  try
    for LItem in AKept do
      LKept.AddOrSetValue(LItem, True);
    AList.OwnsObjects := False;
    try
      for LItem in AList do
      begin
        if not LKept.ContainsKey(LItem) then
          LItem.Free;
      end;
      AList.Clear;
      AList.AddRange(AKept);
    finally
      AList.OwnsObjects := True;
    end;
  finally
    LKept.Free;
  end;
end;

constructor TGlbspLevelAnalyzer.Create(const AData: TGlbspLevelData;
  const AOptions: TGlbspOptions; const AMessages: TStrings);
begin
  inherited Create;
  FData := AData;
  FOptions := AOptions;
  FMessages := AMessages;
end;

procedure TGlbspLevelAnalyzer.Warn(const AMessage: string);
begin
  if Assigned(FMessages) then
    FMessages.Add(AMessage);
end;

{ polyobj handling }

procedure TGlbspLevelAnalyzer.MarkPolyobjSector(const ASector: TGlbspSector);
var
  LLine: TGlbspLinedef;
begin
  if not Assigned(ASector) then
    Exit;

  // Already marked?
  if ASector.HasPolyobj <> 0 then
    Exit;

  // All the lines of the sector become precious, so it is never split
  ASector.HasPolyobj := 1;
  for LLine in FData.Linedefs do
  begin
    if (Assigned(LLine.Right) and (LLine.Right.Sector = ASector)) or
      (Assigned(LLine.Left) and (LLine.Left.Sector = ASector)) then
      LLine.IsPrecious := True;
  end;
end;

procedure TGlbspLevelAnalyzer.MarkPolyobjPoint(const AX, AY: Double);
var
  LLine: TGlbspLinedef;
  LBestMatch: TGlbspLinedef;
  LBestDist: Double;
  LInsideCount: Integer;
  LSector: TGlbspSector;
  LX1, LY1, LX2, LY2: Double;
  LXCut: Double;
  LBMinX, LBMinY, LBMaxX, LBMaxY: Integer;
begin
  LInsideCount := 0;
  LBestDist := 999999;
  LBestMatch := nil;
  LSector := nil;

  // First the awkward cases, where the polyobj sits directly on a linedef or
  // even on a vertex: all the lines that touch a small box around the spawn
  // point are checked
  LBMinX := Trunc(AX - POLY_BOX_SZ);
  LBMinY := Trunc(AY - POLY_BOX_SZ);
  LBMaxX := Trunc(AX + POLY_BOX_SZ);
  LBMaxY := Trunc(AY + POLY_BOX_SZ);

  for LLine in FData.Linedefs do
  begin
    if TGlbspGeometry.CheckLinedefInsideBox(LBMinX, LBMinY, LBMaxX, LBMaxY,
      Trunc(LLine.Start.X), Trunc(LLine.Start.Y), Trunc(LLine.EndVertex.X),
      Trunc(LLine.EndVertex.Y)) then
    begin
      if Assigned(LLine.Left) then
        MarkPolyobjSector(LLine.Left.Sector);
      if Assigned(LLine.Right) then
        MarkPolyobjSector(LLine.Right.Sector);
      Inc(LInsideCount);
    end;
  end;

  if LInsideCount > 0 then
    Exit;

  // Like DEU: a line is cast horizontally from the point and the closest
  // linedef that it meets is chosen
  for LLine in FData.Linedefs do
  begin
    LX1 := LLine.Start.X;
    LY1 := LLine.Start.Y;
    LX2 := LLine.EndVertex.X;
    LY2 := LLine.EndVertex.Y;

    // Vertical range
    if Abs(LY2 - LY1) < DIST_EPSILON then
      Continue;

    if ((AY > (LY1 + DIST_EPSILON)) and (AY > (LY2 + DIST_EPSILON))) or
      ((AY < (LY1 - DIST_EPSILON)) and (AY < (LY2 - DIST_EPSILON))) then
      Continue;

    LXCut := LX1 + (LX2 - LX1) * (AY - LY1) / (LY2 - LY1) - AX;

    if Abs(LXCut) < Abs(LBestDist) then
    begin
      LBestMatch := LLine;
      LBestDist := LXCut;
    end;
  end;

  if not Assigned(LBestMatch) then
  begin
    Warn(Format('Bad polyobj thing at (%.0f,%.0f).', [AX, AY], TFormatSettings.Invariant));
    Exit;
  end;

  LY1 := LBestMatch.Start.Y;
  LY2 := LBestMatch.EndVertex.Y;

  // The orientation of the line tells on which side the polyobj is
  if (LY1 > LY2) = (LBestDist > 0) then
  begin
    if Assigned(LBestMatch.Right) then
      LSector := LBestMatch.Right.Sector;
  end
  else
  begin
    if Assigned(LBestMatch.Left) then
      LSector := LBestMatch.Left.Sector;
  end;

  if not Assigned(LSector) then
  begin
    Warn(Format('Invalid Polyobj thing at (%.0f,%.0f).', [AX, AY],
      TFormatSettings.Invariant));
    Exit;
  end;

  MarkPolyobjSector(LSector);
end;

procedure TGlbspLevelAnalyzer.DetectPolyobjSectors;
var
  LLine: TGlbspLinedef;
  LThing: TGlbspThing;
  LFound: Boolean;
  LHexenStyle: Boolean;
begin
  // The polyobj thing types of Hexen conflict with those of Doom (3001 is an
  // imp and 3002 a demon), so the lines are checked first: only levels with
  // polyobj lines are looked at. Then the things tell whether the ZDoom
  // types are used; if not, the Hexen ones are
  LFound := False;
  for LLine in FData.Linedefs do
  begin
    if (LLine.LineType = HEXTYPE_POLY_START) or (LLine.LineType = HEXTYPE_POLY_EXPLICIT) then
    begin
      LFound := True;
      Break;
    end;
  end;
  if not LFound then
    Exit;

  LHexenStyle := True;
  for LThing in FData.Things do
  begin
    if (LThing.ThingType = ZDOOM_PO_SPAWN_TYPE) or
      (LThing.ThingType = ZDOOM_PO_SPAWNCRUSH_TYPE) then
    begin
      LHexenStyle := False;
      Break;
    end;
  end;

  for LThing in FData.Things do
  begin
    // Only the polyobj start spots are of interest
    if LHexenStyle then
    begin
      if (LThing.ThingType <> PO_SPAWN_TYPE) and (LThing.ThingType <> PO_SPAWNCRUSH_TYPE) then
        Continue;
    end
    else
    begin
      if (LThing.ThingType <> ZDOOM_PO_SPAWN_TYPE) and
        (LThing.ThingType <> ZDOOM_PO_SPAWNCRUSH_TYPE) then
        Continue;
    end;

    MarkPolyobjPoint(LThing.X, LThing.Y);
  end;
end;

{ analysis routines }

function TGlbspLevelAnalyzer.SortedIndices(const ACount: Integer;
  const ACompare: TFunc<Integer, Integer, Integer>): TArray<Integer>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := LIndex;
  TArray.Sort<Integer>(Result, TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    begin
      Result := ACompare(ALeft, ARight);
      // The index breaks the ties: the order does not depend on the algorithm
      if Result = 0 then
        Result := ALeft - ARight;
    end));
end;

function TGlbspLevelAnalyzer.CompareVertices(const ALeft, ARight: Integer): Integer;
var
  LA: TGlbspVertex;
  LB: TGlbspVertex;
begin
  if ALeft = ARight then
    Exit(0);
  LA := FData.Vertices[ALeft];
  LB := FData.Vertices[ARight];
  if Trunc(LA.X) <> Trunc(LB.X) then
    Exit(Trunc(LA.X) - Trunc(LB.X));
  Result := Trunc(LA.Y) - Trunc(LB.Y);
end;

function TGlbspLevelAnalyzer.CompareSidedefs(const ALeft, ARight: Integer): Integer;
var
  LA: TGlbspSidedef;
  LB: TGlbspSidedef;
begin
  if ALeft = ARight then
    Exit(0);
  LA := FData.Sidedefs[ALeft];
  LB := FData.Sidedefs[ARight];

  // The sidedefs on special lines are not merged. glbsp 2.24 compared them by
  // index with every other sidedef: that is not an order (A < S < B with
  // A = B), so the duplicates were merged or not depending on the sort
  // algorithm. Here they come after the other sidedefs (#139)
  if (LA.OnSpecial <> 0) and (LB.OnSpecial <> 0) then
    Exit(ALeft - ARight);
  if LA.OnSpecial <> 0 then
    Exit(1);
  if LB.OnSpecial <> 0 then
    Exit(-1);

  if LA.Sector <> LB.Sector then
  begin
    if not Assigned(LA.Sector) then
      Exit(-1);
    if not Assigned(LB.Sector) then
      Exit(1);
    Exit(LA.Sector.Index - LB.Sector.Index);
  end;

  if LA.XOffset <> LB.XOffset then
    Exit(LA.XOffset - LB.XOffset);
  if LA.YOffset <> LB.YOffset then
    Exit(LA.YOffset - LB.YOffset);

  Result := CompareTextureNames(LA.UpperTex, LB.UpperTex);
  if Result <> 0 then
    Exit;
  Result := CompareTextureNames(LA.LowerTex, LB.LowerTex);
  if Result <> 0 then
    Exit;
  Result := CompareTextureNames(LA.MidTex, LB.MidTex);
end;

procedure TGlbspLevelAnalyzer.DetectDuplicateVertices;
var
  LOrder: TArray<Integer>;
  LIndex: Integer;
  LA: TGlbspVertex;
  LB: TGlbspVertex;
begin
  LOrder := SortedIndices(FData.Vertices.Count,
    function(ALeft, ARight: Integer): Integer
    begin
      Result := CompareVertices(ALeft, ARight);
    end);

  for LIndex := 0 to High(LOrder) - 1 do
  begin
    if CompareVertices(LOrder[LIndex], LOrder[LIndex + 1]) = 0 then
    begin
      LA := FData.Vertices[LOrder[LIndex]];
      LB := FData.Vertices[LOrder[LIndex + 1]];
      // Found a duplicate
      if Assigned(LA.Equiv) then
        LB.Equiv := LA.Equiv
      else
        LB.Equiv := LA;
    end;
  end;
end;

procedure TGlbspLevelAnalyzer.DetectDuplicateSidedefs;
var
  LOrder: TArray<Integer>;
  LIndex: Integer;
  LA: TGlbspSidedef;
  LB: TGlbspSidedef;
begin
  LOrder := SortedIndices(FData.Sidedefs.Count,
    function(ALeft, ARight: Integer): Integer
    begin
      Result := CompareSidedefs(ALeft, ARight);
    end);

  for LIndex := 0 to High(LOrder) - 1 do
  begin
    if CompareSidedefs(LOrder[LIndex], LOrder[LIndex + 1]) = 0 then
    begin
      LA := FData.Sidedefs[LOrder[LIndex]];
      LB := FData.Sidedefs[LOrder[LIndex + 1]];
      // Found a duplicate
      if Assigned(LA.Equiv) then
        LB.Equiv := LA.Equiv
      else
        LB.Equiv := LA;
    end;
  end;
end;

procedure TGlbspLevelAnalyzer.PruneLinedefs;
var
  LLine: TGlbspLinedef;
  LKept: TList<TGlbspLinedef>;
  LNewIndex: Integer;
begin
  LKept := TList<TGlbspLinedef>.Create;
  try
    LNewIndex := 0;
    for LLine in FData.Linedefs do
    begin
      // Duplicated vertices
      while Assigned(LLine.Start.Equiv) do
      begin
        Dec(LLine.Start.RefCount);
        LLine.Start := LLine.Start.Equiv;
        Inc(LLine.Start.RefCount);
      end;
      while Assigned(LLine.EndVertex.Equiv) do
      begin
        Dec(LLine.EndVertex.RefCount);
        LLine.EndVertex := LLine.EndVertex.Equiv;
        Inc(LLine.EndVertex.RefCount);
      end;

      // Duplicated sidedefs
      while Assigned(LLine.Right) and Assigned(LLine.Right.Equiv) do
      begin
        Dec(LLine.Right.RefCount);
        LLine.Right := LLine.Right.Equiv;
        Inc(LLine.Right.RefCount);
      end;
      while Assigned(LLine.Left) and Assigned(LLine.Left.Equiv) do
      begin
        Dec(LLine.Left.RefCount);
        LLine.Left := LLine.Left.Equiv;
        Inc(LLine.Left.RefCount);
      end;

      // Zero length lines are removed
      if LLine.ZeroLength then
      begin
        Dec(LLine.Start.RefCount);
        Dec(LLine.EndVertex.RefCount);
        Continue;
      end;

      LLine.Index := LNewIndex;
      Inc(LNewIndex);
      LKept.Add(LLine);
    end;

    if LKept.Count = 0 then
      raise EGlbspLevelException.Create(SNoLinedefs);
    if LKept.Count < FData.Linedefs.Count then
      KeepOnly<TGlbspLinedef>(FData.Linedefs, LKept);
  finally
    LKept.Free;
  end;
end;

procedure TGlbspLevelAnalyzer.PruneVertices;
var
  LVertex: TGlbspVertex;
  LKept: TList<TGlbspVertex>;
  LNewIndex: Integer;
  LIndex: Integer;
begin
  LKept := TList<TGlbspVertex>.Create;
  try
    LNewIndex := 0;
    LIndex := 0;
    for LVertex in FData.Vertices do
    begin
      if LVertex.RefCount < 0 then
        raise EGlbspLevelException.CreateFmt('Vertex %d ref_count is %d',
          [LIndex, LVertex.RefCount]);
      Inc(LIndex);

      // Unused vertices are dropped
      if LVertex.RefCount = 0 then
        Continue;

      LVertex.Index := LNewIndex;
      Inc(LNewIndex);
      LKept.Add(LVertex);
    end;

    if LKept.Count = 0 then
      raise EGlbspLevelException.Create(SNoVertices);
    if LKept.Count < FData.Vertices.Count then
      KeepOnly<TGlbspVertex>(FData.Vertices, LKept);
  finally
    LKept.Free;
  end;
  FData.NumNormalVert := FData.Vertices.Count;
end;

procedure TGlbspLevelAnalyzer.PruneSidedefs;
var
  LSide: TGlbspSidedef;
  LKept: TList<TGlbspSidedef>;
  LNewIndex: Integer;
  LIndex: Integer;
begin
  LKept := TList<TGlbspSidedef>.Create;
  try
    LNewIndex := 0;
    LIndex := 0;
    for LSide in FData.Sidedefs do
    begin
      if LSide.RefCount < 0 then
        raise EGlbspLevelException.CreateFmt('Sidedef %d ref_count is %d',
          [LIndex, LSide.RefCount]);
      Inc(LIndex);

      if LSide.RefCount = 0 then
      begin
        if Assigned(LSide.Sector) then
          Dec(LSide.Sector.RefCount);
        Continue;
      end;

      LSide.Index := LNewIndex;
      Inc(LNewIndex);
      LKept.Add(LSide);
    end;

    if LKept.Count = 0 then
      raise EGlbspLevelException.Create(SNoSidedefs);
    if LKept.Count < FData.Sidedefs.Count then
      KeepOnly<TGlbspSidedef>(FData.Sidedefs, LKept);
  finally
    LKept.Free;
  end;
end;

procedure TGlbspLevelAnalyzer.PruneSectors;
var
  LSector: TGlbspSector;
  LKept: TList<TGlbspSector>;
  LNewIndex: Integer;
  LIndex: Integer;
begin
  LKept := TList<TGlbspSector>.Create;
  try
    LNewIndex := 0;
    LIndex := 0;
    for LSector in FData.Sectors do
    begin
      if LSector.RefCount < 0 then
        raise EGlbspLevelException.CreateFmt('Sector %d ref_count is %d',
          [LIndex, LSector.RefCount]);
      Inc(LIndex);

      if LSector.RefCount = 0 then
        Continue;

      LSector.Index := LNewIndex;
      Inc(LNewIndex);
      LKept.Add(LSector);
    end;

    if LKept.Count = 0 then
      raise EGlbspLevelException.Create(SNoSectors);
    if LKept.Count < FData.Sectors.Count then
      KeepOnly<TGlbspSector>(FData.Sectors, LKept);
  finally
    LKept.Free;
  end;
end;

function TGlbspLevelAnalyzer.CompareLineStarts(const ALeft, ARight: Integer): Integer;
var
  LA: TGlbspLinedef;
  LB: TGlbspLinedef;
  LC: TGlbspVertex;
  LD: TGlbspVertex;
begin
  if ALeft = ARight then
    Exit(0);
  LA := FData.Linedefs[ALeft];
  LB := FData.Linedefs[ARight];

  // The left-most vertex of each line
  if LineVertexLowest(LA) <> 0 then
    LC := LA.EndVertex
  else
    LC := LA.Start;
  if LineVertexLowest(LB) <> 0 then
    LD := LB.EndVertex
  else
    LD := LB.Start;

  if Trunc(LC.X) <> Trunc(LD.X) then
    Exit(Trunc(LC.X) - Trunc(LD.X));
  Result := Trunc(LC.Y) - Trunc(LD.Y);
end;

function TGlbspLevelAnalyzer.CompareLineEnds(const ALeft, ARight: Integer): Integer;
var
  LA: TGlbspLinedef;
  LB: TGlbspLinedef;
  LC: TGlbspVertex;
  LD: TGlbspVertex;
begin
  if ALeft = ARight then
    Exit(0);
  LA := FData.Linedefs[ALeft];
  LB := FData.Linedefs[ARight];

  // The right-most vertex of each line
  if LineVertexLowest(LA) <> 0 then
    LC := LA.Start
  else
    LC := LA.EndVertex;
  if LineVertexLowest(LB) <> 0 then
    LD := LB.Start
  else
    LD := LB.EndVertex;

  if Trunc(LC.X) <> Trunc(LD.X) then
    Exit(Trunc(LC.X) - Trunc(LD.X));
  Result := Trunc(LC.Y) - Trunc(LD.Y);
end;

procedure TGlbspLevelAnalyzer.DetectOverlappingLines;
var
  LOrder: TArray<Integer>;
  LIndex: Integer;
  LOther: Integer;
  LA: TGlbspLinedef;
  LB: TGlbspLinedef;
begin
  // The lines are sorted by their left-most vertex: the overlapping ones are
  // near each other. The lines that overlap only partly are not detected
  LOrder := SortedIndices(FData.Linedefs.Count,
    function(ALeft, ARight: Integer): Integer
    begin
      Result := CompareLineStarts(ALeft, ARight);
    end);

  for LIndex := 0 to High(LOrder) - 1 do
  begin
    for LOther := LIndex + 1 to High(LOrder) do
    begin
      if CompareLineStarts(LOrder[LIndex], LOrder[LOther]) <> 0 then
        Break;

      if CompareLineEnds(LOrder[LIndex], LOrder[LOther]) = 0 then
      begin
        LA := FData.Linedefs[LOrder[LIndex]];
        LB := FData.Linedefs[LOrder[LOther]];
        // Found an overlap
        if Assigned(LA.Overlap) then
          LB.Overlap := LA.Overlap
        else
          LB.Overlap := LA;
      end;
    end;
  end;
end;

class procedure TGlbspLevelAnalyzer.CountWallTips(const AVertex: TGlbspVertex;
  out AOneSided, ATwoSided: Integer);
var
  LTip: TGlbspWallTip;
begin
  AOneSided := 0;
  ATwoSided := 0;
  LTip := AVertex.TipSet;
  while Assigned(LTip) do
  begin
    if not Assigned(LTip.Left) or not Assigned(LTip.Right) then
      Inc(AOneSided)
    else
      Inc(ATwoSided);
    LTip := LTip.Next;
  end;
end;

procedure TGlbspLevelAnalyzer.TestForWindowEffect(const ALine: TGlbspLinedef);
var
  LIndex: Integer;
  LOther: TGlbspLinedef;
  LMx, LMy: Double;
  LDx, LDy: Double;
  LDx2, LDy2: Double;
  LDist: Double;
  LCastHoriz: Boolean;
  LIsFront: Boolean;
  LHitSide: TGlbspSidedef;
  LBackDist, LFrontDist: Double;
  LBackOpen, LFrontOpen: TGlbspSector;
begin
  // A line is cast horizontally or vertically to see what it hits. It needs
  // all the linedefs
  LMx := (ALine.Start.X + ALine.EndVertex.X) / 2.0;
  LMy := (ALine.Start.Y + ALine.EndVertex.Y) / 2.0;
  LDx := ALine.EndVertex.X - ALine.Start.X;
  LDy := ALine.EndVertex.Y - ALine.Start.Y;
  LCastHoriz := Abs(LDx) < Abs(LDy);

  LBackDist := 999999.0;
  LBackOpen := nil;
  LFrontDist := 999999.0;
  LFrontOpen := nil;

  for LIndex := 0 to FData.Linedefs.Count - 1 do
  begin
    LOther := FData.Linedefs[LIndex];
    if (LOther = ALine) or LOther.ZeroLength or Assigned(LOther.Overlap) then
      Continue;

    LDx2 := LOther.EndVertex.X - LOther.Start.X;
    LDy2 := LOther.EndVertex.Y - LOther.Start.Y;

    if LCastHoriz then
    begin
      if Abs(LDy2) < DIST_EPSILON then
        Continue;

      if (Max(LOther.Start.Y, LOther.EndVertex.Y) < LMy - DIST_EPSILON) or
        (Min(LOther.Start.Y, LOther.EndVertex.Y) > LMy + DIST_EPSILON) then
        Continue;

      LDist := (LOther.Start.X + (LMy - LOther.Start.Y) * LDx2 / LDy2) - LMx;
      LIsFront := (LDy > 0) = (LDist > 0);
      LDist := Abs(LDist);
      if LDist < DIST_EPSILON then
        Continue;

      if (LDy > 0) xor (LDy2 > 0) xor (not LIsFront) then
        LHitSide := LOther.Right
      else
        LHitSide := LOther.Left;
    end
    else
    begin
      if Abs(LDx2) < DIST_EPSILON then
        Continue;

      if (Max(LOther.Start.X, LOther.EndVertex.X) < LMx - DIST_EPSILON) or
        (Min(LOther.Start.X, LOther.EndVertex.X) > LMx + DIST_EPSILON) then
        Continue;

      LDist := (LOther.Start.Y + (LMx - LOther.Start.X) * LDy2 / LDx2) - LMy;
      LIsFront := (LDx > 0) <> (LDist > 0);
      LDist := Abs(LDist);

      if (LDx > 0) xor (LDx2 > 0) xor (not LIsFront) then
        LHitSide := LOther.Right
      else
        LHitSide := LOther.Left;
    end;

    // Too close (overlapping lines?)
    if LDist < DIST_EPSILON then
      Continue;

    if LIsFront then
    begin
      if LDist < LFrontDist then
      begin
        LFrontDist := LDist;
        if Assigned(LHitSide) then
          LFrontOpen := LHitSide.Sector
        else
          LFrontOpen := nil;
      end;
    end
    else
    begin
      if LDist < LBackDist then
      begin
        LBackDist := LDist;
        if Assigned(LHitSide) then
          LBackOpen := LHitSide.Sector
        else
          LBackOpen := nil;
      end;
    end;
  end;

  if Assigned(LBackOpen) and Assigned(LFrontOpen) and (ALine.Right.Sector = LFrontOpen) then
  begin
    ALine.WindowEffect := LBackOpen;
    if FOptions.MiniWarnings then
      Warn(Format('Linedef #%d seems to be a One-Sided Window (back faces sector #%d).',
        [ALine.Index, LBackOpen.Index]));
  end;
end;

procedure TGlbspLevelAnalyzer.DetectWindowEffects;
var
  LLine: TGlbspLinedef;
  LOneSiders: Integer;
  LTwoSiders: Integer;
begin
  // The lines that could be windows are looked for: an odd number of one
  // sided linedefs that meet at a vertex (an idea of Graham Jackson)
  for LLine in FData.Linedefs do
  begin
    if LLine.TwoSided or LLine.ZeroLength or Assigned(LLine.Overlap) or
      not Assigned(LLine.Right) then
      Continue;

    CountWallTips(LLine.Start, LOneSiders, LTwoSiders);
    if ((LOneSiders mod 2) = 1) and ((LOneSiders + LTwoSiders) > 1) then
    begin
      TestForWindowEffect(LLine);
      Continue;
    end;

    CountWallTips(LLine.EndVertex, LOneSiders, LTwoSiders);
    if ((LOneSiders mod 2) = 1) and ((LOneSiders + LTwoSiders) > 1) then
      TestForWindowEffect(LLine);
  end;
end;

{ vertex routines }

procedure TGlbspLevelAnalyzer.CalculateWallTips;
var
  LLine: TGlbspLinedef;
  LX1, LY1, LX2, LY2: Double;
  LLeft, LRight: TGlbspSector;
begin
  for LLine in FData.Linedefs do
  begin
    if LLine.SelfRef and FOptions.SkipSelfRef then
      Continue;

    LX1 := LLine.Start.X;
    LY1 := LLine.Start.Y;
    LX2 := LLine.EndVertex.X;
    LY2 := LLine.EndVertex.Y;

    LLeft := nil;
    if Assigned(LLine.Left) then
      LLeft := LLine.Left.Sector;
    LRight := nil;
    if Assigned(LLine.Right) then
      LRight := LLine.Right.Sector;

    AddWallTip(FData, LLine.Start, LX2 - LX1, LY2 - LY1, LLeft, LRight);
    AddWallTip(FData, LLine.EndVertex, LX1 - LX2, LY1 - LY2, LRight, LLeft);
  end;
end;

function TGlbspLevelAnalyzer.NewVertexFromSplitSeg(const ASeg: TGlbspSeg; const AX,
  AY: Double): TGlbspVertex;
var
  LPartnerSector: TGlbspSector;
begin
  Result := FData.NewVertex;
  Result.X := AX;
  Result.Y := AY;

  if Assigned(ASeg.Partner) then
    Result.RefCount := 4
  else
    Result.RefCount := 2;

  if FData.DoingNormal and (FOptions.SpecVersion = 1) then
  begin
    Result.Index := FData.NumNormalVert;
    FData.NumNormalVert := FData.NumNormalVert + 1;
  end
  else
  begin
    Result.Index := FData.NumGlVert or IS_GL_VERTEX;
    FData.NumGlVert := FData.NumGlVert + 1;
  end;

  // The wall tips
  LPartnerSector := nil;
  if Assigned(ASeg.Partner) then
    LPartnerSector := ASeg.Partner.Sector;
  AddWallTip(FData, Result, -ASeg.PdX, -ASeg.PdY, ASeg.Sector, LPartnerSector);
  AddWallTip(FData, Result, ASeg.PdX, ASeg.PdY, LPartnerSector, ASeg.Sector);

  // A duplicate vertex when normal nodes are built with a version 2 or higher
  if FData.DoingNormal and (FOptions.SpecVersion <> 1) then
  begin
    Result.NormalDup := FData.NewVertex;
    Result.NormalDup.X := AX;
    Result.NormalDup.Y := AY;
    Result.NormalDup.RefCount := Result.RefCount;
    Result.NormalDup.Index := FData.NumNormalVert;
    FData.NumNormalVert := FData.NumNormalVert + 1;
  end;
end;

function TGlbspLevelAnalyzer.NewVertexDegenerate(const AStart,
  AEnd: TGlbspVertex): TGlbspVertex;
var
  LDx, LDy, LLength: Double;
begin
  LDx := AEnd.X - AStart.X;
  LDy := AEnd.Y - AStart.Y;
  LLength := Sqrt(LDx * LDx + LDy * LDy);

  Result := FData.NewVertex;
  Result.RefCount := AStart.RefCount;

  if FData.DoingNormal then
  begin
    Result.Index := FData.NumNormalVert;
    FData.NumNormalVert := FData.NumNormalVert + 1;
  end
  else
  begin
    Result.Index := FData.NumGlVert or IS_GL_VERTEX;
    FData.NumGlVert := FData.NumGlVert + 1;
  end;

  // New coordinates. Y starts from the X of the start vertex: this is a
  // typo of glbsp, kept because the result of the build depends on it
  Result.X := AStart.X;
  Result.Y := AStart.X;

  if LLength = 0 then
    raise EGlbspLevelException.Create('NewVertexDegenerate: bad delta !');

  LDx := LDx / LLength;
  LDy := LDy / LLength;

  while (TGlbspUtil.RoundToInt(Result.X) = TGlbspUtil.RoundToInt(AStart.X)) and
    (TGlbspUtil.RoundToInt(Result.Y) = TGlbspUtil.RoundToInt(AStart.Y)) do
  begin
    Result.X := Result.X + LDx;
    Result.Y := Result.Y + LDy;
  end;
end;

function TGlbspLevelAnalyzer.VertexCheckOpen(const AVertex: TGlbspVertex; const ADx,
  ADy: Double): TGlbspSector;
var
  LTip: TGlbspWallTip;
  LAngle: Double;
begin
  LAngle := TGlbspUtil.ComputeAngle(ADx, ADy);

  // First: is there a wall tip exactly in that direction?
  LTip := AVertex.TipSet;
  while Assigned(LTip) do
  begin
    if (Abs(LTip.Angle - LAngle) < ANG_EPSILON) or
      (Abs(LTip.Angle - LAngle) > (360.0 - ANG_EPSILON)) then
      Exit(nil);
    LTip := LTip.Next;
  end;

  // Then the first tip with a greater angle: we are on its RIGHT side
  LTip := AVertex.TipSet;
  while Assigned(LTip) do
  begin
    if LAngle + ANG_EPSILON < LTip.Angle then
      Exit(LTip.Right);

    // No more tips: we are on the LEFT side of the tip with the largest angle
    if not Assigned(LTip.Next) then
      Exit(LTip.Left);

    LTip := LTip.Next;
  end;

  raise EGlbspLevelException.CreateFmt('Vertex %d has no tips !', [AVertex.Index]);
end;

end.

