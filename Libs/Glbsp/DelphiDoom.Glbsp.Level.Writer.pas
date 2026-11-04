{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - writes the lumps of a built level                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of the writing routines of level.c of glBSP 2.24                       }
{  (C) 2000-2007 Andrew Apted                                                  }
{  ZDBSP format support based on code (C) 2002, 2003 Randy Heit                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Level.Writer;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Options,
  DelphiDoom.Glbsp.Wad.Document,
  DelphiDoom.Glbsp.Wad.Lump;

type
  /// <summary>
  ///   Writes to the lumps of the current level the vertices, segs,
  ///   subsectors and nodes that were built, in the normal, GL (versions 1,
  ///   2, 3 and 5) and ZDBSP formats
  /// </summary>
  TGlbspLevelWriter = class
  private
    FData: TGlbspLevelData;
    FWad: TGlbspWad;
    FNodeCurIndex: Integer;
    class function VertexIndex16Bit(const AVertex: TGlbspVertex): Word; static;
    class function VertexIndex32BitV5(const AVertex: TGlbspVertex): Cardinal; static;
    class function TransformSegDist(const ASeg: TGlbspSeg): Integer; static;
    class function TransformAngle(const AAngle: Double): Integer; static;
    class function Magic(const AText: AnsiString): TBytes; static;
    procedure SortSegs;
    procedure PutOneNode(const ANode: TGlbspNode; const ALump: TGlbspLump);
    procedure PutOneV5Node(const ANode: TGlbspNode; const ALump: TGlbspLump);
    procedure PutOneZNode(const ANode: TGlbspNode; const AStream: TStream);
    procedure PutZVertices(const AStream: TStream);
    procedure PutZSubsecs(const AStream: TStream);
    procedure PutZSegs(const AStream: TStream);
    procedure PutZNodes(const ARoot: TGlbspNode; const AStream: TStream);
  public
    /// <param name="AData">The built level</param>
    /// <param name="AWad">WAD whose current level receives the lumps</param>
    constructor Create(const AData: TGlbspLevelData; const AWad: TGlbspWad);

    /// <summary>
    ///   The VERTEXES (ADoGL False) or GL_VERT (version 1) lump
    /// </summary>
    procedure PutVertices(const AName: AnsiString; const ADoGL: Boolean);
    /// <summary>GL_VERT of the versions 2, 3 and 5 (the 16.16 vertices)</summary>
    procedure PutV2Vertices(const ADoV5: Boolean);
    procedure PutSectors;
    procedure PutSidedefs;
    procedure PutLinedefs;
    procedure PutLinedefsHexen;
    procedure PutSegs;
    procedure PutGLSegs;
    procedure PutV3Segs(const ADoV5: Boolean);
    procedure PutSubsecs(const AName: AnsiString; const ADoGL: Boolean);
    procedure PutV3Subsecs(const ADoV5: Boolean);
    procedure PutNodes(const AName: AnsiString; const ADoGL, ADoV5: Boolean;
      const ARoot: TGlbspNode);

    /// <summary>
    ///   The nodes in the ZDBSP format: NODES holds "ZNOD" and the
    ///   compressed vertices, subsectors, segs and nodes; SEGS and SSECTORS
    ///   are left empty
    /// </summary>
    procedure SaveZDFormat(const ARoot: TGlbspNode);

    /// <summary>The OPTIONS line of the GL marker</summary>
    procedure PutGLOptions(const AOptions: TGlbspOptions);
    /// <summary>The CHECKSUM line: Adler-32 of VERTEXES and LINEDEFS</summary>
    procedure PutGLChecksum;
  end;

implementation

uses
  System.Generics.Collections,
  System.Generics.Defaults,
  System.Math,
  DelphiDoom.Glbsp.Level.Raw,
  DelphiDoom.Glbsp.Util,
  DelphiDoom.Glbsp.Wad.Types,
  DelphiDoom.Zlib.Provider;

const
  MAX_VERTICES_16BIT = 32767;
  MAX_ENTRIES_16BIT = 65534;
  GL_VERTEX_16BIT_FLAG = $8000;
  GL_VERTEX_32BIT_FLAG = $80000000;
  SUBSECTOR_16BIT_FLAG = $8000;

{ TGlbspLevelWriter }

constructor TGlbspLevelWriter.Create(const AData: TGlbspLevelData; const AWad: TGlbspWad);
begin
  inherited Create;
  FData := AData;
  FWad := AWad;
end;

class function TGlbspLevelWriter.Magic(const AText: AnsiString): TBytes;
begin
  SetLength(Result, Length(AText));
  Move(AText[1], Result[0], Length(AText));
end;

class function TGlbspLevelWriter.VertexIndex16Bit(const AVertex: TGlbspVertex): Word;
begin
  if (AVertex.Index and IS_GL_VERTEX) <> 0 then
    Result := Word((AVertex.Index and not IS_GL_VERTEX) or GL_VERTEX_16BIT_FLAG)
  else
    Result := Word(AVertex.Index);
end;

class function TGlbspLevelWriter.VertexIndex32BitV5(const AVertex: TGlbspVertex): Cardinal;
begin
  if (AVertex.Index and IS_GL_VERTEX) <> 0 then
    Result := Cardinal(AVertex.Index and not IS_GL_VERTEX) or GL_VERTEX_32BIT_FLAG
  else
    Result := Cardinal(AVertex.Index);
end;

class function TGlbspLevelWriter.TransformSegDist(const ASeg: TGlbspSeg): Integer;
var
  LSx, LSy, LDx, LDy: Double;
begin
  if ASeg.Side <> 0 then
  begin
    LSx := ASeg.Linedef.EndVertex.X;
    LSy := ASeg.Linedef.EndVertex.Y;
  end
  else
  begin
    LSx := ASeg.Linedef.Start.X;
    LSy := ASeg.Linedef.Start.Y;
  end;
  LDx := ASeg.Start.X - LSx;
  LDy := ASeg.Start.Y - LSy;
  Result := Ceil(Sqrt(LDx * LDx + LDy * LDy));
end;

class function TGlbspLevelWriter.TransformAngle(const AAngle: Double): Integer;
begin
  Result := Trunc(AAngle * 65536.0 / 360.0);
  if Result < 0 then
    Inc(Result, 65536);
  Result := Result and $FFFF;
end;

procedure TGlbspLevelWriter.SortSegs;
begin
  // The segs go into ascending index; one that never reached a subsector
  // is a failure
  FData.Segs.Sort(TComparer<TGlbspSeg>.Construct(
    function(const ALeft, ARight: TGlbspSeg): Integer
    begin
      if ALeft.Index < 0 then
        raise EGlbspLevelException.Create('Seg never reached a subsector !');
      if ARight.Index < 0 then
        raise EGlbspLevelException.Create('Seg never reached a subsector !');
      Result := ALeft.Index - ARight.Index;
    end));
end;

procedure TGlbspLevelWriter.PutVertices(const AName: AnsiString; const ADoGL: Boolean);
var
  LLump: TGlbspLump;
  LVertex: TGlbspVertex;
  LRaw: TRawVertex;
  LCount, LExpected: Integer;
begin
  if ADoGL then
    LLump := FWad.CreateGLLump(AName)
  else
    LLump := FWad.CreateLevelLump(AName);

  LCount := 0;
  for LVertex in FData.Vertices do
  begin
    if ADoGL <> ((LVertex.Index and IS_GL_VERTEX) <> 0) then
      Continue;

    LRaw.X := SmallInt(TGlbspUtil.RoundToInt(LVertex.X));
    LRaw.Y := SmallInt(TGlbspUtil.RoundToInt(LVertex.Y));
    LLump.Append(LRaw, SizeOf(LRaw));
    Inc(LCount);
  end;

  if ADoGL then
    LExpected := FData.NumGlVert
  else
    LExpected := FData.NumNormalVert;
  if LCount <> LExpected then
    raise EGlbspLevelException.CreateFmt('PutVertices miscounted (%d != %d)',
      [LCount, LExpected]);

  if FData.DoingNormal and not ADoGL and (LCount > MAX_ENTRIES_16BIT) then
    FWad.MarkHardFailure(LIMIT_VERTEXES)
  else if LCount > MAX_VERTICES_16BIT then
  begin
    if ADoGL then
      FWad.MarkSoftFailure(LIMIT_GL_VERT)
    else
      FWad.MarkSoftFailure(LIMIT_VERTEXES);
  end;
end;

procedure TGlbspLevelWriter.PutV2Vertices(const ADoV5: Boolean);
var
  LLump: TGlbspLump;
  LVertex: TGlbspVertex;
  LRaw: TRawV2Vertex;
  LCount: Integer;
begin
  LLump := FWad.CreateGLLump('GL_VERT');

  if ADoV5 then
    LLump.Append(AnsiString('gNd5'))
  else
    LLump.Append(AnsiString('gNd2'));

  LCount := 0;
  for LVertex in FData.Vertices do
  begin
    if (LVertex.Index and IS_GL_VERTEX) = 0 then
      Continue;

    LRaw.X := Trunc(LVertex.X * 65536.0);
    LRaw.Y := Trunc(LVertex.Y * 65536.0);
    LLump.Append(LRaw, SizeOf(LRaw));
    Inc(LCount);
  end;

  if LCount <> FData.NumGlVert then
    raise EGlbspLevelException.CreateFmt('PutV2Vertices miscounted (%d != %d)',
      [LCount, FData.NumGlVert]);

  if LCount > MAX_VERTICES_16BIT then
    FWad.MarkSoftFailure(LIMIT_GL_VERT);
end;

procedure TGlbspLevelWriter.PutSectors;
var
  LLump: TGlbspLump;
  LSector: TGlbspSector;
  LRaw: TRawSector;
begin
  LLump := FWad.CreateLevelLump('SECTORS');

  for LSector in FData.Sectors do
  begin
    LRaw.FloorHeight := SmallInt(LSector.FloorHeight);
    LRaw.CeilingHeight := SmallInt(LSector.CeilingHeight);
    Move(LSector.FloorTex, LRaw.FloorTex, SizeOf(LRaw.FloorTex));
    Move(LSector.CeilingTex, LRaw.CeilingTex, SizeOf(LRaw.CeilingTex));
    LRaw.Light := Word(LSector.Light);
    LRaw.Special := Word(LSector.Special);
    LRaw.Tag := SmallInt(LSector.Tag);
    LLump.Append(LRaw, SizeOf(LRaw));
  end;

  if FData.Sectors.Count > MAX_ENTRIES_16BIT then
    FWad.MarkHardFailure(LIMIT_SECTORS)
  else if FData.Sectors.Count > MAX_VERTICES_16BIT then
    FWad.MarkSoftFailure(LIMIT_SECTORS);
end;

procedure TGlbspLevelWriter.PutSidedefs;
var
  LLump: TGlbspLump;
  LSide: TGlbspSidedef;
  LRaw: TRawSidedef;
begin
  LLump := FWad.CreateLevelLump('SIDEDEFS');

  for LSide in FData.Sidedefs do
  begin
    if Assigned(LSide.Sector) then
      LRaw.Sector := Word(LSide.Sector.Index)
    else
      LRaw.Sector := $FFFF;
    LRaw.XOffset := SmallInt(LSide.XOffset);
    LRaw.YOffset := SmallInt(LSide.YOffset);
    Move(LSide.UpperTex, LRaw.UpperTex, SizeOf(LRaw.UpperTex));
    Move(LSide.LowerTex, LRaw.LowerTex, SizeOf(LRaw.LowerTex));
    Move(LSide.MidTex, LRaw.MidTex, SizeOf(LRaw.MidTex));
    LLump.Append(LRaw, SizeOf(LRaw));
  end;

  if FData.Sidedefs.Count > MAX_ENTRIES_16BIT then
    FWad.MarkHardFailure(LIMIT_SIDEDEFS)
  else if FData.Sidedefs.Count > MAX_VERTICES_16BIT then
    FWad.MarkSoftFailure(LIMIT_SIDEDEFS);
end;

procedure TGlbspLevelWriter.PutLinedefs;
var
  LLump: TGlbspLump;
  LLine: TGlbspLinedef;
  LRaw: TRawLinedef;
begin
  LLump := FWad.CreateLevelLump('LINEDEFS');

  for LLine in FData.Linedefs do
  begin
    LRaw.Start := Word(LLine.Start.Index);
    LRaw.EndVertex := Word(LLine.EndVertex.Index);
    LRaw.Flags := Word(LLine.Flags);
    LRaw.LineType := Word(LLine.LineType);
    LRaw.Tag := SmallInt(LLine.Tag);
    if Assigned(LLine.Right) then
      LRaw.Sidedef1 := Word(LLine.Right.Index)
    else
      LRaw.Sidedef1 := $FFFF;
    if Assigned(LLine.Left) then
      LRaw.Sidedef2 := Word(LLine.Left.Index)
    else
      LRaw.Sidedef2 := $FFFF;
    LLump.Append(LRaw, SizeOf(LRaw));
  end;

  if FData.Linedefs.Count > MAX_ENTRIES_16BIT then
    FWad.MarkHardFailure(LIMIT_LINEDEFS)
  else if FData.Linedefs.Count > MAX_VERTICES_16BIT then
    FWad.MarkSoftFailure(LIMIT_LINEDEFS);
end;

procedure TGlbspLevelWriter.PutLinedefsHexen;
var
  LLump: TGlbspLump;
  LLine: TGlbspLinedef;
  LRaw: TRawHexenLinedef;
  LSpecial: Integer;
begin
  LLump := FWad.CreateLevelLump('LINEDEFS');

  for LLine in FData.Linedefs do
  begin
    LRaw.Start := Word(LLine.Start.Index);
    LRaw.EndVertex := Word(LLine.EndVertex.Index);
    LRaw.Flags := Word(LLine.Flags);
    LRaw.LineType := Byte(LLine.LineType);
    for LSpecial := 0 to 4 do
      LRaw.Specials[LSpecial] := Byte(LLine.Specials[LSpecial]);
    if Assigned(LLine.Right) then
      LRaw.Sidedef1 := Word(LLine.Right.Index)
    else
      LRaw.Sidedef1 := $FFFF;
    if Assigned(LLine.Left) then
      LRaw.Sidedef2 := Word(LLine.Left.Index)
    else
      LRaw.Sidedef2 := $FFFF;
    LLump.Append(LRaw, SizeOf(LRaw));
  end;

  if FData.Linedefs.Count > MAX_ENTRIES_16BIT then
    FWad.MarkHardFailure(LIMIT_LINEDEFS)
  else if FData.Linedefs.Count > MAX_VERTICES_16BIT then
    FWad.MarkSoftFailure(LIMIT_LINEDEFS);
end;

procedure TGlbspLevelWriter.PutSegs;
var
  LLump: TGlbspLump;
  LSeg: TGlbspSeg;
  LRaw: TRawSeg;
  LCount: Integer;
begin
  LLump := FWad.CreateLevelLump('SEGS');
  SortSegs;

  LCount := 0;
  for LSeg in FData.Segs do
  begin
    // Minisegs and degenerate segs are ignored
    if not Assigned(LSeg.Linedef) or (LSeg.Degenerate <> 0) then
      Continue;

    LRaw.Start := VertexIndex16Bit(LSeg.Start);
    LRaw.EndVertex := VertexIndex16Bit(LSeg.EndVertex);
    LRaw.Angle := Word(TransformAngle(LSeg.PAngle));
    LRaw.Linedef := Word(LSeg.Linedef.Index);
    LRaw.Flip := Word(LSeg.Side);
    LRaw.Dist := Word(TransformSegDist(LSeg));
    LLump.Append(LRaw, SizeOf(LRaw));
    Inc(LCount);
  end;

  if LCount <> FData.NumCompleteSeg then
    raise EGlbspLevelException.CreateFmt('PutSegs miscounted (%d != %d)',
      [LCount, FData.NumCompleteSeg]);

  if LCount > MAX_ENTRIES_16BIT then
    FWad.MarkHardFailure(LIMIT_SEGS)
  else if LCount > MAX_VERTICES_16BIT then
    FWad.MarkSoftFailure(LIMIT_SEGS);
end;

procedure TGlbspLevelWriter.PutGLSegs;
var
  LLump: TGlbspLump;
  LSeg: TGlbspSeg;
  LRaw: TRawGLSeg;
  LCount: Integer;
begin
  LLump := FWad.CreateGLLump('GL_SEGS');
  SortSegs;

  LCount := 0;
  for LSeg in FData.Segs do
  begin
    // Degenerate segs are ignored
    if LSeg.Degenerate <> 0 then
      Continue;

    LRaw.Start := VertexIndex16Bit(LSeg.Start);
    LRaw.EndVertex := VertexIndex16Bit(LSeg.EndVertex);
    LRaw.Side := Word(LSeg.Side);
    if Assigned(LSeg.Linedef) then
      LRaw.Linedef := Word(LSeg.Linedef.Index)
    else
      LRaw.Linedef := $FFFF;
    if Assigned(LSeg.Partner) then
      LRaw.Partner := Word(LSeg.Partner.Index)
    else
      LRaw.Partner := $FFFF;
    LLump.Append(LRaw, SizeOf(LRaw));
    Inc(LCount);
  end;

  if LCount <> FData.NumCompleteSeg then
    raise EGlbspLevelException.CreateFmt('PutGLSegs miscounted (%d != %d)',
      [LCount, FData.NumCompleteSeg]);

  if LCount > MAX_ENTRIES_16BIT then
    raise EGlbspLevelException.CreateFmt('PutGLSegs with %d (> 65534) segs', [LCount])
  else if LCount > MAX_VERTICES_16BIT then
    FWad.MarkSoftFailure(LIMIT_GL_SEGS);
end;

procedure TGlbspLevelWriter.PutV3Segs(const ADoV5: Boolean);
var
  LLump: TGlbspLump;
  LSeg: TGlbspSeg;
  LRaw: TRawV3Seg;
  LCount: Integer;
  LMagic: TBytes;
begin
  LLump := FWad.CreateGLLump('GL_SEGS');

  if not ADoV5 then
  begin
    LMagic := Magic('gNd3');
    LLump.Append(LMagic[0], Length(LMagic));
  end;

  SortSegs;

  LCount := 0;
  for LSeg in FData.Segs do
  begin
    if LSeg.Degenerate <> 0 then
      Continue;

    if ADoV5 then
    begin
      LRaw.Start := VertexIndex32BitV5(LSeg.Start);
      LRaw.EndVertex := VertexIndex32BitV5(LSeg.EndVertex);
    end
    else
    begin
      LRaw.Start := Cardinal(LSeg.Start.Index);
      LRaw.EndVertex := Cardinal(LSeg.EndVertex.Index);
    end;

    LRaw.Side := Word(LSeg.Side);
    if Assigned(LSeg.Linedef) then
      LRaw.Linedef := Word(LSeg.Linedef.Index)
    else
      LRaw.Linedef := $FFFF;
    if Assigned(LSeg.Partner) then
      LRaw.Partner := Cardinal(LSeg.Partner.Index)
    else
      LRaw.Partner := $FFFFFFFF;
    LLump.Append(LRaw, SizeOf(LRaw));
    Inc(LCount);
  end;

  if LCount <> FData.NumCompleteSeg then
    raise EGlbspLevelException.CreateFmt('PutGLSegs miscounted (%d != %d)',
      [LCount, FData.NumCompleteSeg]);
end;

procedure TGlbspLevelWriter.PutSubsecs(const AName: AnsiString; const ADoGL: Boolean);
var
  LLump: TGlbspLump;
  LSub: TGlbspSubsec;
  LRaw: TRawSubsector;
begin
  if ADoGL then
    LLump := FWad.CreateGLLump(AName)
  else
    LLump := FWad.CreateLevelLump(AName);

  for LSub in FData.Subsecs do
  begin
    LRaw.First := Word(LSub.SegList.Index);
    LRaw.Count := Word(LSub.SegCount);
    LLump.Append(LRaw, SizeOf(LRaw));
  end;

  if FData.Subsecs.Count > MAX_VERTICES_16BIT then
  begin
    if ADoGL then
      FWad.MarkHardFailure(LIMIT_GL_SSECT)
    else
      FWad.MarkHardFailure(LIMIT_SSECTORS);
  end;
end;

procedure TGlbspLevelWriter.PutV3Subsecs(const ADoV5: Boolean);
var
  LLump: TGlbspLump;
  LSub: TGlbspSubsec;
  LRaw: TRawV3Subsector;
  LMagic: TBytes;
begin
  LLump := FWad.CreateGLLump('GL_SSECT');

  if not ADoV5 then
  begin
    LMagic := Magic('gNd3');
    LLump.Append(LMagic[0], Length(LMagic));
  end;

  for LSub in FData.Subsecs do
  begin
    LRaw.First := Cardinal(LSub.SegList.Index);
    LRaw.Count := Cardinal(LSub.SegCount);
    LLump.Append(LRaw, SizeOf(LRaw));
  end;

  if not ADoV5 and (FData.Subsecs.Count > MAX_VERTICES_16BIT) then
    FWad.MarkHardFailure(LIMIT_GL_SSECT);
end;

procedure TGlbspLevelWriter.PutOneNode(const ANode: TGlbspNode; const ALump: TGlbspLump);
var
  LRaw: TRawNode;
  LDivisor: Integer;
begin
  if Assigned(ANode.R.Node) then
    PutOneNode(ANode.R.Node, ALump);
  if Assigned(ANode.L.Node) then
    PutOneNode(ANode.L.Node, ALump);

  ANode.Index := FNodeCurIndex;
  Inc(FNodeCurIndex);

  if ANode.TooLong <> 0 then
    LDivisor := 2
  else
    LDivisor := 1;

  LRaw.X := SmallInt(ANode.X);
  LRaw.Y := SmallInt(ANode.Y);
  LRaw.Dx := SmallInt(ANode.Dx div LDivisor);
  LRaw.Dy := SmallInt(ANode.Dy div LDivisor);

  LRaw.B1.MinX := SmallInt(ANode.R.Bounds.MinX);
  LRaw.B1.MinY := SmallInt(ANode.R.Bounds.MinY);
  LRaw.B1.MaxX := SmallInt(ANode.R.Bounds.MaxX);
  LRaw.B1.MaxY := SmallInt(ANode.R.Bounds.MaxY);

  LRaw.B2.MinX := SmallInt(ANode.L.Bounds.MinX);
  LRaw.B2.MinY := SmallInt(ANode.L.Bounds.MinY);
  LRaw.B2.MaxX := SmallInt(ANode.L.Bounds.MaxX);
  LRaw.B2.MaxY := SmallInt(ANode.L.Bounds.MaxY);

  if Assigned(ANode.R.Node) then
    LRaw.Right := Word(ANode.R.Node.Index)
  else if Assigned(ANode.R.Subsec) then
    LRaw.Right := Word(ANode.R.Subsec.Index or SUBSECTOR_16BIT_FLAG)
  else
    raise EGlbspLevelException.CreateFmt('Bad right child in node %d', [ANode.Index]);

  if Assigned(ANode.L.Node) then
    LRaw.Left := Word(ANode.L.Node.Index)
  else if Assigned(ANode.L.Subsec) then
    LRaw.Left := Word(ANode.L.Subsec.Index or SUBSECTOR_16BIT_FLAG)
  else
    raise EGlbspLevelException.CreateFmt('Bad left child in node %d', [ANode.Index]);

  ALump.Append(LRaw, SizeOf(LRaw));
end;

procedure TGlbspLevelWriter.PutOneV5Node(const ANode: TGlbspNode; const ALump: TGlbspLump);
var
  LRaw: TRawV5Node;
  LDivisor: Integer;
begin
  if Assigned(ANode.R.Node) then
    PutOneV5Node(ANode.R.Node, ALump);
  if Assigned(ANode.L.Node) then
    PutOneV5Node(ANode.L.Node, ALump);

  ANode.Index := FNodeCurIndex;
  Inc(FNodeCurIndex);

  if ANode.TooLong <> 0 then
    LDivisor := 2
  else
    LDivisor := 1;

  LRaw.X := SmallInt(ANode.X);
  LRaw.Y := SmallInt(ANode.Y);
  LRaw.Dx := SmallInt(ANode.Dx div LDivisor);
  LRaw.Dy := SmallInt(ANode.Dy div LDivisor);

  LRaw.B1.MinX := SmallInt(ANode.R.Bounds.MinX);
  LRaw.B1.MinY := SmallInt(ANode.R.Bounds.MinY);
  LRaw.B1.MaxX := SmallInt(ANode.R.Bounds.MaxX);
  LRaw.B1.MaxY := SmallInt(ANode.R.Bounds.MaxY);

  LRaw.B2.MinX := SmallInt(ANode.L.Bounds.MinX);
  LRaw.B2.MinY := SmallInt(ANode.L.Bounds.MinY);
  LRaw.B2.MaxX := SmallInt(ANode.L.Bounds.MaxX);
  LRaw.B2.MaxY := SmallInt(ANode.L.Bounds.MaxY);

  if Assigned(ANode.R.Node) then
    LRaw.Right := Cardinal(ANode.R.Node.Index)
  else if Assigned(ANode.R.Subsec) then
    LRaw.Right := Cardinal(ANode.R.Subsec.Index) or GL_VERTEX_32BIT_FLAG
  else
    raise EGlbspLevelException.CreateFmt('Bad right child in V5 node %d', [ANode.Index]);

  if Assigned(ANode.L.Node) then
    LRaw.Left := Cardinal(ANode.L.Node.Index)
  else if Assigned(ANode.L.Subsec) then
    LRaw.Left := Cardinal(ANode.L.Subsec.Index) or GL_VERTEX_32BIT_FLAG
  else
    raise EGlbspLevelException.CreateFmt('Bad left child in V5 node %d', [ANode.Index]);

  ALump.Append(LRaw, SizeOf(LRaw));
end;

procedure TGlbspLevelWriter.PutNodes(const AName: AnsiString; const ADoGL, ADoV5: Boolean;
  const ARoot: TGlbspNode);
var
  LLump: TGlbspLump;
begin
  if ADoGL then
    LLump := FWad.CreateGLLump(AName)
  else
    LLump := FWad.CreateLevelLump(AName);

  FNodeCurIndex := 0;

  if Assigned(ARoot) then
  begin
    if ADoV5 then
      PutOneV5Node(ARoot, LLump)
    else
      PutOneNode(ARoot, LLump);
  end;

  if FNodeCurIndex <> FData.Nodes.Count then
    raise EGlbspLevelException.CreateFmt('PutNodes miscounted (%d != %d)',
      [FNodeCurIndex, FData.Nodes.Count]);

  if not ADoV5 and (FNodeCurIndex > MAX_VERTICES_16BIT) then
    FWad.MarkHardFailure(LIMIT_NODES);
end;

{ ZDBSP format }

procedure TGlbspLevelWriter.PutZVertices(const AStream: TStream);
var
  LVertex: TGlbspVertex;
  LRaw: TRawV2Vertex;
  LOrgVerts, LNewVerts: Cardinal;
  LCount: Integer;
begin
  LOrgVerts := Cardinal(FData.NumNormalVert);
  LNewVerts := Cardinal(FData.NumGlVert);
  AStream.WriteBuffer(LOrgVerts, 4);
  AStream.WriteBuffer(LNewVerts, 4);

  LCount := 0;
  for LVertex in FData.Vertices do
  begin
    if (LVertex.Index and IS_GL_VERTEX) = 0 then
      Continue;

    LRaw.X := Trunc(LVertex.X * 65536.0);
    LRaw.Y := Trunc(LVertex.Y * 65536.0);
    AStream.WriteBuffer(LRaw, SizeOf(LRaw));
    Inc(LCount);
  end;

  if LCount <> FData.NumGlVert then
    raise EGlbspLevelException.CreateFmt('PutZVertices miscounted (%d != %d)',
      [LCount, FData.NumGlVert]);
end;

procedure TGlbspLevelWriter.PutZSubsecs(const AStream: TStream);
var
  LRawNum: Cardinal;
  LCurSegIndex, LCount, LIndex: Integer;
  LSub: TGlbspSubsec;
  LSeg: TGlbspSeg;
begin
  LCurSegIndex := 0;
  LRawNum := Cardinal(FData.Subsecs.Count);
  AStream.WriteBuffer(LRawNum, 4);

  for LIndex := 0 to FData.Subsecs.Count - 1 do
  begin
    LSub := FData.Subsecs[LIndex];
    LRawNum := Cardinal(LSub.SegCount);
    AStream.WriteBuffer(LRawNum, 4);

    // The seg index values are checked
    LCount := 0;
    LSeg := LSub.SegList;
    while Assigned(LSeg) do
    begin
      // Minisegs and degenerate segs are ignored
      if Assigned(LSeg.Linedef) and (LSeg.Degenerate = 0) then
      begin
        if LCurSegIndex <> LSeg.Index then
          raise EGlbspLevelException.CreateFmt(
            'PutZSubsecs: seg index mismatch in sub %d (%d != %d)',
            [LIndex, LCurSegIndex, LSeg.Index]);
        Inc(LCount);
      end;
      Inc(LCurSegIndex);
      LSeg := LSeg.Next;
    end;

    if LCount <> LSub.SegCount then
      raise EGlbspLevelException.CreateFmt('PutZSubsecs: miscounted segs in sub %d (%d != %d)',
        [LIndex, LCount, LSub.SegCount]);
  end;

  if LCurSegIndex <> FData.NumCompleteSeg then
    raise EGlbspLevelException.CreateFmt('PutZSubsecs miscounted segs (%d != %d)',
      [LCurSegIndex, FData.NumCompleteSeg]);
end;

procedure TGlbspLevelWriter.PutZSegs(const AStream: TStream);
var
  LRawNum: Cardinal;
  LSeg: TGlbspSeg;
  LCount: Integer;
  LV1, LV2: Cardinal;
  LLine: Word;
  LSide: Byte;
begin
  LRawNum := Cardinal(FData.NumCompleteSeg);
  AStream.WriteBuffer(LRawNum, 4);

  LCount := 0;
  for LSeg in FData.Segs do
  begin
    // Minisegs and degenerate segs are ignored
    if not Assigned(LSeg.Linedef) or (LSeg.Degenerate <> 0) then
      Continue;

    if LCount <> LSeg.Index then
      raise EGlbspLevelException.CreateFmt('PutZSegs: seg index mismatch (%d != %d)',
        [LCount, LSeg.Index]);

    LV1 := VertexIndex32BitV5(LSeg.Start);
    LV2 := VertexIndex32BitV5(LSeg.EndVertex);
    LLine := Word(LSeg.Linedef.Index);
    LSide := Byte(LSeg.Side);

    AStream.WriteBuffer(LV1, 4);
    AStream.WriteBuffer(LV2, 4);
    AStream.WriteBuffer(LLine, 2);
    AStream.WriteBuffer(LSide, 1);
    Inc(LCount);
  end;

  if LCount <> FData.NumCompleteSeg then
    raise EGlbspLevelException.CreateFmt('PutZSegs miscounted (%d != %d)',
      [LCount, FData.NumCompleteSeg]);
end;

procedure TGlbspLevelWriter.PutOneZNode(const ANode: TGlbspNode; const AStream: TStream);
var
  LRaw: TRawV5Node;
  LDivisor: Integer;
begin
  if Assigned(ANode.R.Node) then
    PutOneZNode(ANode.R.Node, AStream);
  if Assigned(ANode.L.Node) then
    PutOneZNode(ANode.L.Node, AStream);

  ANode.Index := FNodeCurIndex;
  Inc(FNodeCurIndex);

  if ANode.TooLong <> 0 then
    LDivisor := 2
  else
    LDivisor := 1;

  LRaw.X := SmallInt(ANode.X);
  LRaw.Y := SmallInt(ANode.Y);
  LRaw.Dx := SmallInt(ANode.Dx div LDivisor);
  LRaw.Dy := SmallInt(ANode.Dy div LDivisor);

  AStream.WriteBuffer(LRaw.X, 2);
  AStream.WriteBuffer(LRaw.Y, 2);
  AStream.WriteBuffer(LRaw.Dx, 2);
  AStream.WriteBuffer(LRaw.Dy, 2);

  LRaw.B1.MinX := SmallInt(ANode.R.Bounds.MinX);
  LRaw.B1.MinY := SmallInt(ANode.R.Bounds.MinY);
  LRaw.B1.MaxX := SmallInt(ANode.R.Bounds.MaxX);
  LRaw.B1.MaxY := SmallInt(ANode.R.Bounds.MaxY);

  LRaw.B2.MinX := SmallInt(ANode.L.Bounds.MinX);
  LRaw.B2.MinY := SmallInt(ANode.L.Bounds.MinY);
  LRaw.B2.MaxX := SmallInt(ANode.L.Bounds.MaxX);
  LRaw.B2.MaxY := SmallInt(ANode.L.Bounds.MaxY);

  AStream.WriteBuffer(LRaw.B1, SizeOf(LRaw.B1));
  AStream.WriteBuffer(LRaw.B2, SizeOf(LRaw.B2));

  if Assigned(ANode.R.Node) then
    LRaw.Right := Cardinal(ANode.R.Node.Index)
  else if Assigned(ANode.R.Subsec) then
    LRaw.Right := Cardinal(ANode.R.Subsec.Index) or GL_VERTEX_32BIT_FLAG
  else
    raise EGlbspLevelException.CreateFmt('Bad right child in V5 node %d', [ANode.Index]);

  if Assigned(ANode.L.Node) then
    LRaw.Left := Cardinal(ANode.L.Node.Index)
  else if Assigned(ANode.L.Subsec) then
    LRaw.Left := Cardinal(ANode.L.Subsec.Index) or GL_VERTEX_32BIT_FLAG
  else
    raise EGlbspLevelException.CreateFmt('Bad left child in V5 node %d', [ANode.Index]);

  AStream.WriteBuffer(LRaw.Right, 4);
  AStream.WriteBuffer(LRaw.Left, 4);
end;

procedure TGlbspLevelWriter.PutZNodes(const ARoot: TGlbspNode; const AStream: TStream);
var
  LRawNum: Cardinal;
begin
  LRawNum := Cardinal(FData.Nodes.Count);
  AStream.WriteBuffer(LRawNum, 4);

  FNodeCurIndex := 0;

  if Assigned(ARoot) then
    PutOneZNode(ARoot, AStream);

  if FNodeCurIndex <> FData.Nodes.Count then
    raise EGlbspLevelException.CreateFmt('PutZNodes miscounted (%d != %d)',
      [FNodeCurIndex, FData.Nodes.Count]);
end;

procedure TGlbspLevelWriter.SaveZDFormat(const ARoot: TGlbspNode);
var
  LLump: TGlbspLump;
  LStream: TBytesStream;
  LPacked: TBytes;
  LMagic: TBytes;
begin
  // SEGS and SSECTORS stay empty
  FWad.CreateLevelLump('SEGS');
  FWad.CreateLevelLump('SSECTORS');

  LLump := FWad.CreateLevelLump('NODES');
  LMagic := Magic('ZNOD');
  LLump.Append(LMagic[0], Length(LMagic));

  LStream := TBytesStream.Create;
  try
    PutZVertices(LStream);
    PutZSubsecs(LStream);
    PutZSegs(LStream);
    PutZNodes(ARoot, LStream);

    // The same zlib as glbsp (1.2.8), with the default compression level
    LPacked := TZlibProvider.Client.Compress(Copy(LStream.Bytes, 0, LStream.Size));
  finally
    LStream.Free;
  end;

  LLump.Append(LPacked[0], Length(LPacked));
end;

procedure TGlbspLevelWriter.PutGLOptions(const AOptions: TGlbspOptions);
var
  LText: AnsiString;
begin
  LText := AnsiString(Format('-v%d -factor %d', [AOptions.SpecVersion, AOptions.Factor]));

  if AOptions.Fast then
    LText := LText + ' -f';
  if AOptions.ForceNormal then
    LText := LText + ' -n';
  if AOptions.MergeVert then
    LText := LText + ' -m';
  if AOptions.PackSides then
    LText := LText + ' -p';
  if AOptions.PruneSect then
    LText := LText + ' -u';
  if AOptions.SkipSelfRef then
    LText := LText + ' -s';
  if AOptions.WindowFx then
    LText := LText + ' -y';

  if AOptions.NoNormal then
    LText := LText + ' -xn';
  if AOptions.NoReject then
    LText := LText + ' -xr';
  if AOptions.NoPrune then
    LText := LText + ' -xu';

  FWad.AddGLTextLine('OPTIONS', LText);
end;

procedure TGlbspLevelWriter.PutGLChecksum;
var
  LCrc: Cardinal;
  LLump: TGlbspLump;
begin
  LCrc := TGlbspUtil.Adler32Begin;

  LLump := FWad.FindLevelLump('VERTEXES');
  if Assigned(LLump) and (LLump.Length > 0) then
    LCrc := TGlbspUtil.Adler32AddBlock(LCrc, @LLump.Data[0], LLump.Length);

  LLump := FWad.FindLevelLump('LINEDEFS');
  if Assigned(LLump) and (LLump.Length > 0) then
    LCrc := TGlbspUtil.Adler32AddBlock(LCrc, @LLump.Data[0], LLump.Length);

  FWad.AddGLTextLine('CHECKSUM', AnsiString(LowerCase(Format('0x%.8x', [LCrc]))));
end;

end.
