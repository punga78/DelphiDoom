{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - reads the lumps of a level into the level model        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of the reading routines of level.c of glBSP 2.24 (C) 2000-2007         }
{  Andrew Apted                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Level.Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Wad.Document,
  DelphiDoom.Glbsp.Wad.Lump;

type
  /// <summary>
  ///   Fills a TGlbspLevelData with the lumps of the current level of a WAD.
  ///   The routines keep the order and the quirks of glbsp, because the
  ///   result of the node building depends on them
  /// </summary>
  TGlbspLevelLoader = class
  private
    FWad: TGlbspWad;
    FData: TGlbspLevelData;
    function SafeLookupSidedef(const ANumber: Word): TGlbspSidedef;
    class function IsZeroLength(const AStart, AEnd: TGlbspVertex): Boolean; static;
    procedure ConnectSidedefs(const ALine: TGlbspLinedef; const ARight, ALeft: Word);
  public
    /// <param name="AWad">WAD whose CurrentLevel is the level to read</param>
    /// <param name="AData">Receives the objects of the level</param>
    constructor Create(const AWad: TGlbspWad; const AData: TGlbspLevelData);

    /// <summary>
    ///   True when the level already has normal nodes: NODES exists and
    ///   SEGS and SSECTORS are not empty or all zeros
    /// </summary>
    function CheckForNormalNodes: Boolean;

    /// <exception cref="EGlbspLevelException">no vertices</exception>
    procedure GetVertices;
    procedure GetSectors;
    procedure GetSidedefs;
    procedure GetLinedefs;
    procedure GetLinedefsHexen;
    /// <summary>Adds a warning, but no error, when the level has no things</summary>
    procedure GetThings;
    procedure GetThingsHexen;
    /// <summary>Reads the nodes of the level, only to reuse their lines</summary>
    procedure GetStaleNodes;
  end;

implementation

uses
  DelphiDoom.Glbsp.Level.Raw;

const
  // Two vertices closer than this are the same point
  DIST_EPSILON = 1.0 / 128.0;

  SNoVertices = 'Couldn''t find any Vertices';
  SNoSectors = 'Couldn''t find any Sectors';
  SNoSidedefs = 'Couldn''t find any Sidedefs';
  SNoLinedefs = 'Couldn''t find any Linedefs';
  SNoThings = 'Couldn''t find any Things!';

{ TGlbspLevelLoader }

constructor TGlbspLevelLoader.Create(const AWad: TGlbspWad; const AData: TGlbspLevelData);
begin
  inherited Create;
  FWad := AWad;
  FData := AData;
end;

class function TGlbspLevelLoader.IsZeroLength(const AStart, AEnd: TGlbspVertex): Boolean;
begin
  Result := (Abs(AStart.X - AEnd.X) < DIST_EPSILON) and
    (Abs(AStart.Y - AEnd.Y) < DIST_EPSILON);
end;

function TGlbspLevelLoader.CheckForNormalNodes: Boolean;
var
  LLump: TGlbspLump;
begin
  // An empty NODES lump can be valid
  if not Assigned(FWad.FindLevelLump('NODES')) then
    Exit(False);

  LLump := FWad.FindLevelLump('SEGS');
  if not Assigned(LLump) or (LLump.Length = 0) or LLump.IsAllZero then
    Exit(False);

  LLump := FWad.FindLevelLump('SSECTORS');
  if not Assigned(LLump) or (LLump.Length = 0) or LLump.IsAllZero then
    Exit(False);

  Result := True;
end;

procedure TGlbspLevelLoader.GetVertices;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LRaw: TRawVertex;
  LVertex: TGlbspVertex;
begin
  LLump := FWad.FindLevelLump('VERTEXES');
  if not Assigned(LLump) then
    raise EGlbspLevelException.Create(SNoVertices);
  LCount := LLump.Length div SizeOf(TRawVertex);
  if LCount = 0 then
    raise EGlbspLevelException.Create(SNoVertices);

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawVertex)], LRaw, SizeOf(LRaw));
    LVertex := FData.NewVertex;
    LVertex.X := LRaw.X;
    LVertex.Y := LRaw.Y;
    LVertex.Index := LIndex;
  end;

  FData.NumNormalVert := FData.Vertices.Count;
  FData.NumGlVert := 0;
  FData.NumCompleteSeg := 0;
end;

procedure TGlbspLevelLoader.GetSectors;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LRaw: TRawSector;
  LSector: TGlbspSector;
begin
  LLump := FWad.FindLevelLump('SECTORS');
  if not Assigned(LLump) then
    raise EGlbspLevelException.Create(SNoSectors);
  LCount := LLump.Length div SizeOf(TRawSector);
  if LCount = 0 then
    raise EGlbspLevelException.Create(SNoSectors);

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawSector)], LRaw, SizeOf(LRaw));
    LSector := FData.NewSector;
    LSector.FloorHeight := LRaw.FloorHeight;
    LSector.CeilingHeight := LRaw.CeilingHeight;
    Move(LRaw.FloorTex, LSector.FloorTex, SizeOf(LSector.FloorTex));
    Move(LRaw.CeilingTex, LSector.CeilingTex, SizeOf(LSector.CeilingTex));
    LSector.Light := LRaw.Light;
    LSector.Special := LRaw.Special;
    LSector.Tag := LRaw.Tag;
    LSector.Coalesce := (LSector.Tag >= 900) and (LSector.Tag < 1000);
    // Sector indices never change
    LSector.Index := LIndex;
    LSector.WarnedFacing := -1;
  end;
end;

procedure TGlbspLevelLoader.GetSidedefs;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LRaw: TRawSidedef;
  LSide: TGlbspSidedef;
begin
  LLump := FWad.FindLevelLump('SIDEDEFS');
  if not Assigned(LLump) then
    raise EGlbspLevelException.Create(SNoSidedefs);
  LCount := LLump.Length div SizeOf(TRawSidedef);
  if LCount = 0 then
    raise EGlbspLevelException.Create(SNoSidedefs);

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawSidedef)], LRaw, SizeOf(LRaw));
    LSide := FData.NewSidedef;

    if SmallInt(LRaw.Sector) = -1 then
      LSide.Sector := nil
    else
      LSide.Sector := FData.LookupSector(LRaw.Sector);
    if Assigned(LSide.Sector) then
      Inc(LSide.Sector.RefCount);

    LSide.XOffset := LRaw.XOffset;
    LSide.YOffset := LRaw.YOffset;
    Move(LRaw.UpperTex, LSide.UpperTex, SizeOf(LSide.UpperTex));
    Move(LRaw.LowerTex, LSide.LowerTex, SizeOf(LSide.LowerTex));
    Move(LRaw.MidTex, LSide.MidTex, SizeOf(LSide.MidTex));
    // Sidedef indices never change at this stage
    LSide.Index := LIndex;
  end;
end;

function TGlbspLevelLoader.SafeLookupSidedef(const ANumber: Word): TGlbspSidedef;
begin
  if ANumber = $FFFF then
    Exit(nil);
  // Any other negative number is also "no sidedef" when it is out of range
  if (ANumber >= FData.Sidedefs.Count) and (SmallInt(ANumber) < 0) then
    Exit(nil);
  Result := FData.LookupSidedef(ANumber);
end;

procedure TGlbspLevelLoader.ConnectSidedefs(const ALine: TGlbspLinedef; const ARight,
  ALeft: Word);
begin
  ALine.Right := SafeLookupSidedef(ARight);
  ALine.Left := SafeLookupSidedef(ALeft);

  if Assigned(ALine.Right) then
  begin
    Inc(ALine.Right.RefCount);
    if ALine.LineType > 0 then
      ALine.Right.OnSpecial := ALine.Right.OnSpecial or 1;
  end;

  if Assigned(ALine.Left) then
  begin
    Inc(ALine.Left.RefCount);
    if ALine.LineType > 0 then
      ALine.Left.OnSpecial := ALine.Left.OnSpecial or 1;
  end;

  ALine.SelfRef := Assigned(ALine.Left) and Assigned(ALine.Right) and
    (ALine.Left.Sector = ALine.Right.Sector);
end;

procedure TGlbspLevelLoader.GetLinedefs;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LRaw: TRawLinedef;
  LLine: TGlbspLinedef;
  LStart: TGlbspVertex;
  LEnd: TGlbspVertex;
begin
  LLump := FWad.FindLevelLump('LINEDEFS');
  if not Assigned(LLump) then
    raise EGlbspLevelException.Create(SNoLinedefs);
  LCount := LLump.Length div SizeOf(TRawLinedef);
  if LCount = 0 then
    raise EGlbspLevelException.Create(SNoLinedefs);

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawLinedef)], LRaw, SizeOf(LRaw));

    LStart := FData.LookupVertex(LRaw.Start);
    LEnd := FData.LookupVertex(LRaw.EndVertex);
    Inc(LStart.RefCount);
    Inc(LEnd.RefCount);

    LLine := FData.NewLinedef;
    LLine.Start := LStart;
    LLine.EndVertex := LEnd;
    LLine.ZeroLength := IsZeroLength(LStart, LEnd);
    LLine.Flags := LRaw.Flags;
    LLine.LineType := LRaw.LineType;
    LLine.Tag := LRaw.Tag;
    LLine.TwoSided := (LLine.Flags and LINEFLAG_TWO_SIDED) <> 0;
    LLine.IsPrecious := (LLine.Tag >= 900) and (LLine.Tag < 1000);

    ConnectSidedefs(LLine, LRaw.Sidedef1, LRaw.Sidedef2);
    LLine.Index := LIndex;
  end;
end;

procedure TGlbspLevelLoader.GetLinedefsHexen;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LSpecial: Integer;
  LRaw: TRawHexenLinedef;
  LLine: TGlbspLinedef;
  LStart: TGlbspVertex;
  LEnd: TGlbspVertex;
begin
  LLump := FWad.FindLevelLump('LINEDEFS');
  if not Assigned(LLump) then
    raise EGlbspLevelException.Create(SNoLinedefs);
  LCount := LLump.Length div SizeOf(TRawHexenLinedef);
  if LCount = 0 then
    raise EGlbspLevelException.Create(SNoLinedefs);

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawHexenLinedef)], LRaw, SizeOf(LRaw));

    LStart := FData.LookupVertex(LRaw.Start);
    LEnd := FData.LookupVertex(LRaw.EndVertex);
    Inc(LStart.RefCount);
    Inc(LEnd.RefCount);

    LLine := FData.NewLinedef;
    LLine.Start := LStart;
    LLine.EndVertex := LEnd;
    LLine.ZeroLength := IsZeroLength(LStart, LEnd);
    LLine.Flags := LRaw.Flags;
    LLine.LineType := LRaw.LineType;
    LLine.Tag := 0;
    for LSpecial := 0 to 4 do
      LLine.Specials[LSpecial] := LRaw.Specials[LSpecial];
    LLine.TwoSided := (LLine.Flags and LINEFLAG_TWO_SIDED) <> 0;

    ConnectSidedefs(LLine, LRaw.Sidedef1, LRaw.Sidedef2);
    LLine.Index := LIndex;
  end;
end;

procedure TGlbspLevelLoader.GetThings;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LRaw: TRawThing;
  LThing: TGlbspThing;
begin
  LLump := FWad.FindLevelLump('THINGS');
  LCount := 0;
  if Assigned(LLump) then
    LCount := LLump.Length div SizeOf(TRawThing);
  if LCount = 0 then
  begin
    // No error: the level is unplayable without starts, but it can be built
    FWad.Warnings.Add(SNoThings);
    Exit;
  end;

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawThing)], LRaw, SizeOf(LRaw));
    LThing := FData.NewThing;
    LThing.X := LRaw.X;
    LThing.Y := LRaw.Y;
    LThing.ThingType := LRaw.ThingType;
    LThing.Options := LRaw.Options;
    LThing.Index := LIndex;
  end;
end;

procedure TGlbspLevelLoader.GetThingsHexen;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LRaw: TRawHexenThing;
  LThing: TGlbspThing;
begin
  LLump := FWad.FindLevelLump('THINGS');
  LCount := 0;
  if Assigned(LLump) then
    LCount := LLump.Length div SizeOf(TRawHexenThing);
  if LCount = 0 then
  begin
    FWad.Warnings.Add(SNoThings);
    Exit;
  end;

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawHexenThing)], LRaw, SizeOf(LRaw));
    LThing := FData.NewThing;
    LThing.X := LRaw.X;
    LThing.Y := LRaw.Y;
    LThing.ThingType := LRaw.ThingType;
    LThing.Options := LRaw.Options;
    LThing.Index := LIndex;
  end;
end;

procedure TGlbspLevelLoader.GetStaleNodes;
var
  LLump: TGlbspLump;
  LCount: Integer;
  LIndex: Integer;
  LRaw: TRawNode;
  LNode: TGlbspNode;
begin
  LLump := FWad.FindLevelLump('NODES');
  if not Assigned(LLump) then
    Exit;
  LCount := LLump.Length div SizeOf(TRawNode);
  if LCount < 5 then
    Exit;

  // All the nodes are created first, because they refer to each other
  for LIndex := 0 to LCount - 1 do
    FData.NewStaleNode;

  for LIndex := 0 to LCount - 1 do
  begin
    Move(LLump.Data[LIndex * SizeOf(TRawNode)], LRaw, SizeOf(LRaw));
    LNode := FData.LookupStaleNode(LIndex);
    LNode.X := LRaw.X;
    LNode.Y := LRaw.Y;
    LNode.Dx := LRaw.Dx;
    LNode.Dy := LRaw.Dy;
    LNode.Index := LIndex;

    // The references to subsectors and the bounding boxes are not needed
    if (LRaw.Right and $8000) = 0 then
      LNode.R.Node := FData.LookupStaleNode(LRaw.Right);
    if (LRaw.Left and $8000) = 0 then
      LNode.L.Node := FData.LookupStaleNode(LRaw.Left);
  end;
end;

end.
