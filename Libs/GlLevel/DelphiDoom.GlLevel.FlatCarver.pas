{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL level geometry - the polygons of the flats               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  The idea and the algorithm to compute the flats with nodes and subsectors   }
{  are originally from JHexen; adapted by proff (2000).                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlLevel.FlatCarver;

interface

uses
  System.SysUtils,
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf;

type
  /// <summary>
  ///   The old gld_CarveFlats, gld_FlatConvexCarver and gld_GetSubSectorVertices over a BSP given by
  ///   an IGlFlatWorld; the polygons go to an IGlFlatLoopSink in the order of the old code. It
  ///   has no state between calls (the partition lines of the path are a local list).
  /// </summary>
  TGlFlatCarver = class(TInterfacedObject, IGlFlatCarver)
  strict private
    FWorld: IGlFlatWorld;
    FSink: IGlFlatLoopSink;
    procedure CarveSubsector(const ASubsectorIndex: Integer; const ALines: TArray<TGlDivLine>;
      const ACount: Integer);
    procedure Carve(const ANode: Integer; var ALines: TArray<TGlDivLine>; const ACount: Integer;
      const AIsClosed: TGlSectorClosed);
  public
    constructor Create(const AWorld: IGlFlatWorld; const ASink: IGlFlatLoopSink);
    procedure CarveFlats(const ARootNode: Integer; const AIsClosed: TGlSectorClosed);
    procedure AddSubsectorLoops(const AIsClosed: TGlSectorClosed);
  end;

implementation

uses
  DelphiDoom.GlLevel.FlatEdgeClipper;

const
  // the "worldwide" polygon the carving starts from (MININT and MAXINT of the old code)
  WORLD_MIN = Low(Integer);
  WORLD_MAX = High(Integer);

{ TGlFlatCarver }

constructor TGlFlatCarver.Create(const AWorld: IGlFlatWorld; const ASink: IGlFlatLoopSink);
begin
  inherited Create;
  if not Assigned(AWorld) then
    raise EArgumentNilException.Create('AWorld');
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  FWorld := AWorld;
  FSink := ASink;
end;

procedure TGlFlatCarver.CarveSubsector(const ASubsectorIndex: Integer; const ALines: TArray<TGlDivLine>;
  const ACount: Integer);
var
  LSubsector: TGlCarverSubsector;
  LClippers: TArray<TGlDivLine>;
  LSeg: TGlCarverSeg;
  LPolygon: TGlClipPolygon;
  LIndex, LTotal: Integer;
begin
  LSubsector := FWorld.GetSubsector(ASubsectorIndex);
  LTotal := ACount + LSubsector.LineCount;

  SetLength(LClippers, LTotal);
  for LIndex := 0 to ACount - 1 do
    LClippers[LIndex] := ALines[ACount - LIndex - 1];
  for LIndex := ACount to LTotal - 1 do
  begin
    LSeg := FWorld.GetSeg(LSubsector.FirstLine + LIndex - ACount);
    LClippers[LIndex].X := LSeg.Start.X;
    LClippers[LIndex].Y := LSeg.Start.Y;
    LClippers[LIndex].DX := LSeg.Finish.X - LSeg.Start.X;
    LClippers[LIndex].DY := LSeg.Finish.Y - LSeg.Start.Y;
  end;

  // Setup the 'worldwide' polygon.
  LPolygon.Count := 4;
  LPolygon.Points[0].X := WORLD_MIN;
  LPolygon.Points[0].Y := WORLD_MAX;
  LPolygon.Points[1].X := WORLD_MAX;
  LPolygon.Points[1].Y := WORLD_MAX;
  LPolygon.Points[2].X := WORLD_MAX;
  LPolygon.Points[2].Y := WORLD_MIN;
  LPolygon.Points[3].X := WORLD_MIN;
  LPolygon.Points[3].Y := WORLD_MIN;

  // Do some clipping
  TGlFlatEdgeClipper.Clip(LPolygon, LClippers);

  if LPolygon.Count >= 3 then
    FSink.AddLoop(LSubsector.SectorId, @LPolygon.Points[0], LPolygon.Count);
end;

procedure TGlFlatCarver.Carve(const ANode: Integer; var ALines: TArray<TGlDivLine>; const ACount: Integer;
  const AIsClosed: TGlSectorClosed);
var
  LNode: TGlCarverNode;
  LSubsector: Integer;
begin
  if ANode = -1 then
  begin
    if not AIsClosed(FWorld.GetSubsector(0).SectorId) then
      CarveSubsector(0, ALines, ACount);
    Exit;
  end;

  // If this is a subsector we are dealing with, begin carving with the
  // given list. The divline list contains all the partition lines that carve out the subsector.
  if ANode and GLLEVEL_NODE_SUBSECTOR <> 0 then
  begin
    LSubsector := ANode and not GLLEVEL_NODE_SUBSECTOR;
    if not AIsClosed(FWorld.GetSubsector(LSubsector).SectorId) then
      CarveSubsector(LSubsector, ALines, ACount);
    Exit;
  end;

  LNode := FWorld.GetNode(ANode);

  // One more line for the children: the list is shared, the entry of the node is rewritten
  // for the second child
  if Length(ALines) < ACount + 1 then
    SetLength(ALines, (ACount + 1) * 2);
  // The right child gets the original line (LEFT side clipped).
  ALines[ACount] := LNode.Line;
  Carve(LNode.Children[0], ALines, ACount + 1, AIsClosed);

  // The left side. We must reverse the line, otherwise the wrong
  // side would get clipped.
  ALines[ACount].DX := -LNode.Line.DX;
  ALines[ACount].DY := -LNode.Line.DY;
  Carve(LNode.Children[1], ALines, ACount + 1, AIsClosed);
end;

procedure TGlFlatCarver.CarveFlats(const ARootNode: Integer; const AIsClosed: TGlSectorClosed);
var
  LLines: TArray<TGlDivLine>;
begin
  if not Assigned(AIsClosed) then
    raise EArgumentNilException.Create('AIsClosed');
  SetLength(LLines, 32);
  Carve(ARootNode, LLines, 0, AIsClosed);
end;

procedure TGlFlatCarver.AddSubsectorLoops(const AIsClosed: TGlSectorClosed);
var
  LIndex, LPoint: Integer;
  LSubsector: TGlCarverSubsector;
  LPoints: TArray<TGlFixedPoint>;
begin
  if not Assigned(AIsClosed) then
    raise EArgumentNilException.Create('AIsClosed');
  for LIndex := 0 to FWorld.GetSubsectorCount - 1 do
  begin
    LSubsector := FWorld.GetSubsector(LIndex);
    if AIsClosed(LSubsector.SectorId) then
      Continue;
    if LSubsector.LineCount < 3 then
      Continue;

    SetLength(LPoints, LSubsector.LineCount);
    for LPoint := 0 to LSubsector.LineCount - 1 do
      LPoints[LPoint] := FWorld.GetSeg(LSubsector.FirstLine + LPoint).Start;
    FSink.AddLoop(LSubsector.SectorId, @LPoints[0], LSubsector.LineCount);
  end;
end;

end.
