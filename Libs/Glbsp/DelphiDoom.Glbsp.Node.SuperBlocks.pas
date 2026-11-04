{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - superblocks: the spatial index of the segs              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of the superblock routines of node.c of glBSP 2.24                     }
{  (C) 2000-2007 Andrew Apted                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Node.SuperBlocks;

interface

uses
  DelphiDoom.Glbsp.Level.Types;

type
  /// <summary>
  ///   Stateless routines on superblocks. A superblock holds the segs that
  ///   lie completely in it, and the sub-blocks hold the others; counting
  ///   the segs of a whole block is then immediate
  /// </summary>
  TGlbspSuperBlocks = class
  public
    /// <summary>
    ///   Relation between a box and the partition line: -1 if the box is on
    ///   the left side, +1 on the right side, 0 if the line crosses the box
    /// </summary>
    class function BoxOnLineSide(const ABox: TGlbspSuperBlock;
      const APart: TGlbspSeg): Integer; static;

    /// <summary>Adds the seg to the smallest block that contains it</summary>
    class procedure AddSegToSuper(ABlock: TGlbspSuperBlock; const ASeg: TGlbspSeg); static;

    /// <summary>
    ///   Increases the counts of the block and of its parents, to account
    ///   for the seg being split
    /// </summary>
    class procedure SplitSegInSuper(ABlock: TGlbspSuperBlock; const ASeg: TGlbspSeg); static;
  end;

implementation

{ TGlbspSuperBlocks }

// -1 for left, +1 for right, 0 for intersect
function PointOnLineSide(const APart: TGlbspSeg; const AX, AY: Double): Integer;
var
  LPerp: Double;
begin
  LPerp := APart.PerpDist(AX, AY);
  if Abs(LPerp) <= DIST_EPSILON then
    Exit(0);
  if LPerp < 0 then
    Result := -1
  else
    Result := 1;
end;

class function TGlbspSuperBlocks.BoxOnLineSide(const ABox: TGlbspSuperBlock;
  const APart: TGlbspSeg): Integer;
var
  LX1, LY1, LX2, LY2: Double;
  LP1, LP2: Integer;
begin
  LX1 := ABox.X1 - IFFY_LEN * 1.5;
  LY1 := ABox.Y1 - IFFY_LEN * 1.5;
  LX2 := ABox.X2 + IFFY_LEN * 1.5;
  LY2 := ABox.Y2 + IFFY_LEN * 1.5;

  // The simple cases: vertical and horizontal lines
  if APart.PdX = 0 then
  begin
    if LX1 > APart.PsX then
      LP1 := 1
    else
      LP1 := -1;
    if LX2 > APart.PsX then
      LP2 := 1
    else
      LP2 := -1;
    if APart.PdY < 0 then
    begin
      LP1 := -LP1;
      LP2 := -LP2;
    end;
  end
  else if APart.PdY = 0 then
  begin
    if LY1 < APart.PsY then
      LP1 := 1
    else
      LP1 := -1;
    if LY2 < APart.PsY then
      LP2 := 1
    else
      LP2 := -1;
    if APart.PdX < 0 then
    begin
      LP1 := -LP1;
      LP2 := -LP2;
    end;
  end
  else if APart.PdX * APart.PdY > 0 then
  begin
    // Positive slope
    LP1 := PointOnLineSide(APart, LX1, LY2);
    LP2 := PointOnLineSide(APart, LX2, LY1);
  end
  else
  begin
    // Negative slope
    LP1 := PointOnLineSide(APart, LX1, LY1);
    LP2 := PointOnLineSide(APart, LX2, LY2);
  end;

  if LP1 = LP2 then
    Result := LP1
  else
    Result := 0;
end;

class procedure TGlbspSuperBlocks.AddSegToSuper(ABlock: TGlbspSuperBlock;
  const ASeg: TGlbspSeg);
var
  LP1, LP2: Boolean;
  LChild: Integer;
  LXMid, LYMid: Integer;
  LSub: TGlbspSuperBlock;
begin
  while True do
  begin
    LXMid := (ABlock.X1 + ABlock.X2) div 2;
    LYMid := (ABlock.Y1 + ABlock.Y2) div 2;

    // Update the seg counts
    if Assigned(ASeg.Linedef) then
      Inc(ABlock.RealNum)
    else
      Inc(ABlock.MiniNum);

    if ABlock.IsLeaf then
    begin
      // A leaf: no subdivision is possible
      ASeg.Next := ABlock.Segs;
      ASeg.Block := ABlock;
      ABlock.Segs := ASeg;
      Exit;
    end;

    if ABlock.X2 - ABlock.X1 >= ABlock.Y2 - ABlock.Y1 then
    begin
      // Wider than high, or square
      LP1 := ASeg.Start.X >= LXMid;
      LP2 := ASeg.EndVertex.X >= LXMid;
    end
    else
    begin
      // Higher than wide
      LP1 := ASeg.Start.Y >= LYMid;
      LP2 := ASeg.EndVertex.Y >= LYMid;
    end;

    if LP1 and LP2 then
      LChild := 1
    else if (not LP1) and (not LP2) then
      LChild := 0
    else
    begin
      // The line crosses the midpoint: it stays in this block
      ASeg.Next := ABlock.Segs;
      ASeg.Block := ABlock;
      ABlock.Segs := ASeg;
      Exit;
    end;

    // The seg lies in one half of the block: the sub-block is created if
    // it does not exist, then the seg is added there
    if not Assigned(ABlock.Subs[LChild]) then
    begin
      LSub := TGlbspSuperBlock.Create;
      ABlock.Subs[LChild] := LSub;
      LSub.Parent := ABlock;

      if ABlock.X2 - ABlock.X1 >= ABlock.Y2 - ABlock.Y1 then
      begin
        if LChild <> 0 then
          LSub.X1 := LXMid
        else
          LSub.X1 := ABlock.X1;
        LSub.Y1 := ABlock.Y1;
        if LChild <> 0 then
          LSub.X2 := ABlock.X2
        else
          LSub.X2 := LXMid;
        LSub.Y2 := ABlock.Y2;
      end
      else
      begin
        LSub.X1 := ABlock.X1;
        if LChild <> 0 then
          LSub.Y1 := LYMid
        else
          LSub.Y1 := ABlock.Y1;
        LSub.X2 := ABlock.X2;
        if LChild <> 0 then
          LSub.Y2 := ABlock.Y2
        else
          LSub.Y2 := LYMid;
      end;
    end;

    ABlock := ABlock.Subs[LChild];
  end;
end;

class procedure TGlbspSuperBlocks.SplitSegInSuper(ABlock: TGlbspSuperBlock;
  const ASeg: TGlbspSeg);
begin
  repeat
    if Assigned(ASeg.Linedef) then
      Inc(ABlock.RealNum)
    else
      Inc(ABlock.MiniNum);
    ABlock := ABlock.Parent;
  until not Assigned(ABlock);
end;

end.
