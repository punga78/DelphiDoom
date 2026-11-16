{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - geometric helpers on integer coordinates                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of blockmap.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Geometry;

interface

type
  /// <summary>
  ///   Stateless geometry used by several steps of the node builder
  /// </summary>
  TGlbspGeometry = class
  public
    /// <summary>
    ///   True when the line (X1,Y1)-(X2,Y2) touches the box. The line is
    ///   clipped one side at a time, truncating the intermediate points to
    ///   integers, exactly as glbsp does
    /// </summary>
    class function CheckLinedefInsideBox(const AXMin, AYMin, AXMax, AYMax: Integer;
      AX1, AY1, AX2, AY2: Integer): Boolean; static;
  end;

implementation

{ TGlbspGeometry }

class function TGlbspGeometry.CheckLinedefInsideBox(const AXMin, AYMin, AXMax,
  AYMax: Integer; AX1, AY1, AX2, AY2: Integer): Boolean;
var
  LCount: Integer;
  LTemp: Integer;
begin
  LCount := 2;
  while True do
  begin
    if AY1 > AYMax then
    begin
      if AY2 > AYMax then
        Exit(False);
      AX1 := AX1 + Trunc((AX2 - AX1) * Double(AYMax - AY1) / Double(AY2 - AY1));
      AY1 := AYMax;
      LCount := 2;
      Continue;
    end;

    if AY1 < AYMin then
    begin
      if AY2 < AYMin then
        Exit(False);
      AX1 := AX1 + Trunc((AX2 - AX1) * Double(AYMin - AY1) / Double(AY2 - AY1));
      AY1 := AYMin;
      LCount := 2;
      Continue;
    end;

    if AX1 > AXMax then
    begin
      if AX2 > AXMax then
        Exit(False);
      AY1 := AY1 + Trunc((AY2 - AY1) * Double(AXMax - AX1) / Double(AX2 - AX1));
      AX1 := AXMax;
      LCount := 2;
      Continue;
    end;

    if AX1 < AXMin then
    begin
      if AX2 < AXMin then
        Exit(False);
      AY1 := AY1 + Trunc((AY2 - AY1) * Double(AXMin - AX1) / Double(AX2 - AX1));
      AX1 := AXMin;
      LCount := 2;
      Continue;
    end;

    Dec(LCount);
    if LCount = 0 then
      Break;

    // Swap the end points
    LTemp := AX1;
    AX1 := AX2;
    AX2 := LTemp;
    LTemp := AY1;
    AY1 := AY2;
    AY2 := LTemp;
  end;

  // The linedef touches the block
  Result := True;
end;

end.
