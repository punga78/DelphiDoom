{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - the GL lumps (GL_VERT, GL_SEGS, GL_SSECT,       }
{  GL_NODES) as neutral records                                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.GlParser;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Types;

type
  /// <summary>
  ///   Turns the bytes of a GL lump into the records of the latest form of the lump: the old forms
  ///   (V1 and V2) are widened, so the engine reads one kind of record. The version is the one of
  ///   the GL nodes: 0 or 1 for V1 (no magic number), 2 to 5 (see the GL nodes specification).
  ///   A lump that stops in the middle of a record gives the whole records that it has
  /// </summary>
  TNodesGlParser = class sealed
  public
    /// <summary>GL_VERT; from V2 the lump starts with a magic number. Coordinates are 16.16 fixed point</summary>
    class function ParseVertexes(const ABytes: TBytes; AVersion: Integer): TArray<TNodesGlVertex>; static;
    /// <summary>GL_SEGS; V3 has a magic number, V4 and V5 do not</summary>
    class function ParseSegs(const ABytes: TBytes; AVersion: Integer): TArray<TNodesGlSeg>; static;
    /// <summary>GL_SSECT; V3 has a magic number</summary>
    class function ParseSubsectors(const ABytes: TBytes; AVersion: Integer): TArray<TNodesGlSubsector>; static;
    /// <summary>GL_NODES; before V4 the children are 16 bit and the subsector flag is $8000</summary>
    class function ParseNodes(const ABytes: TBytes; AVersion: Integer): TArray<TNodesGlNode>; static;
  end;

implementation

{ TNodesGlParser }

class function TNodesGlParser.ParseVertexes(const ABytes: TBytes;
  AVersion: Integer): TArray<TNodesGlVertex>;
var
  LOffset: Integer;
  LCount: Integer;
  LIndex: Integer;
  LVertex1: TNodesGlVertex1;
begin
  if AVersion >= 2 then
  begin
    LOffset := SizeOf(Cardinal);
    LCount := (Length(ABytes) - LOffset) div SizeOf(TNodesGlVertex);
    if LCount < 0 then
      LCount := 0;
    SetLength(Result, LCount);
    if LCount > 0 then
      Move(ABytes[LOffset], Result[0], LCount * SizeOf(TNodesGlVertex));
  end
  else
  begin
    LCount := Length(ABytes) div SizeOf(TNodesGlVertex1);
    SetLength(Result, LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      Move(ABytes[LIndex * SizeOf(TNodesGlVertex1)], LVertex1, SizeOf(LVertex1));
      Result[LIndex].X := LVertex1.X * 65536;
      Result[LIndex].Y := LVertex1.Y * 65536;
    end;
  end;
end;

class function TNodesGlParser.ParseSegs(const ABytes: TBytes;
  AVersion: Integer): TArray<TNodesGlSeg>;
var
  LOffset: Integer;
  LCount: Integer;
  LIndex: Integer;
  LSeg1: TNodesGlSeg1;
begin
  if AVersion >= 3 then
  begin
    if AVersion = 3 then
      LOffset := SizeOf(Cardinal)
    else
      LOffset := 0;
    LCount := (Length(ABytes) - LOffset) div SizeOf(TNodesGlSeg);
    if LCount < 0 then
      LCount := 0;
    SetLength(Result, LCount);
    if LCount > 0 then
      Move(ABytes[LOffset], Result[0], LCount * SizeOf(TNodesGlSeg));
  end
  else
  begin
    LCount := Length(ABytes) div SizeOf(TNodesGlSeg1);
    SetLength(Result, LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      Move(ABytes[LIndex * SizeOf(TNodesGlSeg1)], LSeg1, SizeOf(LSeg1));
      Result[LIndex].StartVertex := LSeg1.StartVertex;
      Result[LIndex].EndVertex := LSeg1.EndVertex;
      Result[LIndex].Linedef := LSeg1.Linedef;
      Result[LIndex].Side := LSeg1.Side;
      Result[LIndex].PartnerSeg := LSeg1.PartnerSeg;
    end;
  end;
end;

class function TNodesGlParser.ParseSubsectors(const ABytes: TBytes;
  AVersion: Integer): TArray<TNodesGlSubsector>;
var
  LOffset: Integer;
  LCount: Integer;
  LIndex: Integer;
  LSubsector1: TNodesGlSubsector1;
begin
  if AVersion >= 3 then
  begin
    if AVersion = 3 then
      LOffset := SizeOf(Cardinal)
    else
      LOffset := 0;
    LCount := (Length(ABytes) - LOffset) div SizeOf(TNodesGlSubsector);
    if LCount < 0 then
      LCount := 0;
    SetLength(Result, LCount);
    if LCount > 0 then
      Move(ABytes[LOffset], Result[0], LCount * SizeOf(TNodesGlSubsector));
  end
  else
  begin
    LCount := Length(ABytes) div SizeOf(TNodesGlSubsector1);
    SetLength(Result, LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      Move(ABytes[LIndex * SizeOf(TNodesGlSubsector1)], LSubsector1, SizeOf(LSubsector1));
      Result[LIndex].Count := LSubsector1.Count;
      Result[LIndex].FirstSeg := LSubsector1.FirstSeg;
    end;
  end;
end;

class function TNodesGlParser.ParseNodes(const ABytes: TBytes;
  AVersion: Integer): TArray<TNodesGlNode>;

  function WidenChild(AChild: Word): Cardinal;
  begin
    if AChild and NODES_CHILD_SUBSECTOR_V1 <> 0 then
      Result := (AChild and not NODES_CHILD_SUBSECTOR_V1) or NODES_CHILD_SUBSECTOR_V5
    else
      Result := AChild;
  end;

var
  LCount: Integer;
  LIndex: Integer;
  LNode1: TNodesGlNode1;
begin
  if AVersion >= 4 then
  begin
    LCount := Length(ABytes) div SizeOf(TNodesGlNode);
    SetLength(Result, LCount);
    if LCount > 0 then
      Move(ABytes[0], Result[0], LCount * SizeOf(TNodesGlNode));
  end
  else
  begin
    LCount := Length(ABytes) div SizeOf(TNodesGlNode1);
    SetLength(Result, LCount);
    for LIndex := 0 to LCount - 1 do
    begin
      Move(ABytes[LIndex * SizeOf(TNodesGlNode1)], LNode1, SizeOf(LNode1));
      Result[LIndex].X := LNode1.X;
      Result[LIndex].Y := LNode1.Y;
      Result[LIndex].DeltaX := LNode1.DeltaX;
      Result[LIndex].DeltaY := LNode1.DeltaY;
      Move(LNode1.RightBoundingBox, Result[LIndex].RightBoundingBox, SizeOf(LNode1.RightBoundingBox));
      Move(LNode1.LeftBoundingBox, Result[LIndex].LeftBoundingBox, SizeOf(LNode1.LeftBoundingBox));
      Result[LIndex].RightChild := WidenChild(LNode1.RightChild);
      Result[LIndex].LeftChild := WidenChild(LNode1.LeftChild);
    end;
  end;
end;

end.
