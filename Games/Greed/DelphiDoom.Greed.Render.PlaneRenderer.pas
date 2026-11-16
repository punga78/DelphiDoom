{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the floors and ceilings of the renderer          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): r_plane.pas                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.PlaneRenderer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.State;

type
  /// <summary>
  ///   Turns the floor and the ceiling of the tile that the state holds into spans, a row at a time (RenderTileEnds
  ///   of the original): the polygon of the four corners, cut at the near plane, is walked down its two edges and each
  ///   row becomes a span of the list. A sloping floor or ceiling is a plane, calculated from three corners, and it
  ///   can be cut in triangles (slopesplitfloor, slopesplitceiling) or have rows cut in pieces of 8 columns
  ///   (slopeprecise) as the original settings say
  /// </summary>
  TGreedPlaneRenderer = class
  strict private
    FState: TGreedRenderState;
    FSlopePrecise: Boolean;
    FSlopeSplitFloor: Boolean;
    FSlopeSplitCeiling: Boolean;
    // mr_*: the row that is walked
    FMrY, FMrX1, FMrX2: Integer;
    FMrShadow: Integer;
    FMrColormap: PByte;
    FMrLight: Integer;
    FMrDeltaHeight: Integer;
    FMrPicture: PByte;
    FSpanKind: TGreedSpanKind;
    FCeilingBit: Boolean;
    FNumVertex: Integer;
    FVertexY: array[0..7] of Integer;
    FVertexX: array[0..7] of Integer;
    FVertexPt: array[0..4] of TGreedClipPoint;
    FPlaneA, FPlaneB, FPlaneC, FPlaneD: Single;
    procedure CopyFloor(ASource, ADest: Integer); overload;
    procedure CopyFloor(ASource1, ASource2, ADest: Integer); overload;
    procedure CopyCeiling(ASource, ADest: Integer); overload;
    procedure CopyCeiling(ASource1, ASource2, ADest: Integer); overload;
    procedure FlatSpan;
    procedure SlopeSpanFast;
    procedure SlopeSpanPrecise;
    procedure SlopeSpan;
    procedure RenderPolygon(AFlat: Boolean);
    procedure CalcPlaneEquation;
    function ZClipPolygon(ACount, AZMin: Integer): Boolean;
    procedure SlopePolygon(ACount: Integer);
    procedure FloorShadow;
    procedure DrawFloor(AFlags: Integer);
    procedure DrawCeiling(AFlags: Integer);
    procedure AddSpanRow(APoint, AX1, AX2, AYH: Integer);
  public
    constructor Create(AState: TGreedRenderState);
    /// <summary>RenderTileEnds: the floor and the ceiling of the current tile</summary>
    procedure RenderTileEnds;
    /// <summary>slopeprecise: the rows of a slope are cut in pieces of 8 columns (the original has it on)</summary>
    property SlopePrecise: Boolean read FSlopePrecise write FSlopePrecise;
    /// <summary>slopesplitfloor: a floor with a slope is drawn as triangles (off in the original)</summary>
    property SlopeSplitFloor: Boolean read FSlopeSplitFloor write FSlopeSplitFloor;
    /// <summary>slopesplitceiling (on in the original)</summary>
    property SlopeSplitCeiling: Boolean read FSlopeSplitCeiling write FSlopeSplitCeiling;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Types, DelphiDoom.Greed.FixedMath, DelphiDoom.Greed.Render.Tables;

type
  FM = TGreedFixedMath;

{ TGreedPlaneRenderer }

constructor TGreedPlaneRenderer.Create(AState: TGreedRenderState);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  FState := AState;
  FSlopePrecise := True;
  FSlopeSplitFloor := False;
  FSlopeSplitCeiling := True;
end;

procedure TGreedPlaneRenderer.CopyFloor(ASource, ADest: Integer);
begin
  FVertexPt[ADest].TX := FState.Vertex[ASource]^.TX;
  FVertexPt[ADest].TY := FState.Vertex[ASource]^.FloorHeight;
  FVertexPt[ADest].TZ := FState.Vertex[ASource]^.TZ;
  FVertexPt[ADest].PX := FState.Vertex[ASource]^.PX;
  FVertexPt[ADest].PY := FState.Vertex[ASource]^.FloorY;
end;

procedure TGreedPlaneRenderer.CopyFloor(ASource1, ASource2, ADest: Integer);
begin
  FVertexPt[ADest].TX := FState.Vertex[ASource1]^.TX div 2 + FState.Vertex[ASource2]^.TX div 2;
  FVertexPt[ADest].TY := FState.Vertex[ASource1]^.FloorHeight div 2 + FState.Vertex[ASource2]^.FloorHeight div 2;
  FVertexPt[ADest].TZ := FState.Vertex[ASource1]^.TZ div 2 + FState.Vertex[ASource2]^.TZ div 2;
  FVertexPt[ADest].PX := (FState.Vertex[ASource1]^.PX + FState.Vertex[ASource2]^.PX) div 2;
  FVertexPt[ADest].PY := (FState.Vertex[ASource1]^.FloorY + FState.Vertex[ASource2]^.FloorY) div 2;
end;

procedure TGreedPlaneRenderer.CopyCeiling(ASource, ADest: Integer);
begin
  FVertexPt[ADest].TX := FState.Vertex[ASource]^.TX;
  FVertexPt[ADest].TY := FState.Vertex[ASource]^.CeilingHeight;
  FVertexPt[ADest].TZ := FState.Vertex[ASource]^.TZ;
  FVertexPt[ADest].PX := FState.Vertex[ASource]^.PX;
  FVertexPt[ADest].PY := FState.Vertex[ASource]^.CeilingY;
end;

procedure TGreedPlaneRenderer.CopyCeiling(ASource1, ASource2, ADest: Integer);
begin
  FVertexPt[ADest].TX := FState.Vertex[ASource1]^.TX div 2 + FState.Vertex[ASource2]^.TX div 2;
  FVertexPt[ADest].TY := FState.Vertex[ASource1]^.CeilingHeight div 2 + FState.Vertex[ASource2]^.CeilingHeight div 2;
  FVertexPt[ADest].TZ := FState.Vertex[ASource1]^.TZ div 2 + FState.Vertex[ASource2]^.TZ div 2;
  FVertexPt[ADest].PX := (FState.Vertex[ASource1]^.PX + FState.Vertex[ASource2]^.PX) div 2;
  FVertexPt[ADest].PY := (FState.Vertex[ASource1]^.CeilingY + FState.Vertex[ASource2]^.CeilingY) div 2;
end;

procedure TGreedPlaneRenderer.AddSpanRow(APoint, AX1, AX2, AYH: Integer);
var
  LSpan: PGreedSpan;
begin
  LSpan := FState.NewSpan(Cardinal(APoint), AX1);
  if LSpan = nil then
    Exit;
  LSpan^.Kind := FSpanKind;
  LSpan^.Picture := FMrPicture;
  LSpan^.X2 := AX2;
  LSpan^.Y := FMrY;
  LSpan^.YH := AYH;
  LSpan^.Shadow := FMrShadow;
  LSpan^.Colormap := FMrColormap;
  LSpan^.Light := FMrLight;
end;

// used for flat floors and ceilings, the coordinates must be preclipped
procedure TGreedPlaneRenderer.FlatSpan;
var
  LPointZ: Integer;
begin
  LPointZ := FM.Divide(FMrDeltaHeight, FState.YSlope^[FMrY + FState.MaxScroll]);
  if LPointZ > GREED_MAX_Z then
    Exit;
  AddSpanRow(LPointZ, FMrX1, FMrX2, 0);
end;

// used for sloping floors and ceilings: the plane equation must be calculated
procedure TGreedPlaneRenderer.SlopeSpanFast;
var
  LPointZ, LPointZ2: Integer;
  LPartial, LDenom: Single;
begin
  LPartial := (FPlaneB / GREED_FRACUNIT) * FState.YSlope^[FMrY + FState.MaxScroll] + FPlaneC;
  LDenom := (FPlaneA / GREED_FRACUNIT) * FState.XSlope^[FMrX1] + LPartial;
  if LDenom < 8000 then
    Exit;
  LPointZ := Trunc(FPlaneD / LDenom * GREED_FRACUNIT);
  if LPointZ > GREED_MAX_Z then
    Exit;
  LDenom := (FPlaneA / GREED_FRACUNIT) * FState.XSlope^[FMrX2] + LPartial;
  if LDenom < 8000 then
    Exit;
  LPointZ2 := Trunc(FPlaneD / LDenom * GREED_FRACUNIT);
  if LPointZ2 > GREED_MAX_Z then
    Exit;
  AddSpanRow(LPointZ, FMrX1, FMrX2, LPointZ2);
end;

procedure TGreedPlaneRenderer.SlopeSpanPrecise;
var
  LPointZ, LPointZ2, LX1, LX2: Integer;
  LPartial, LDenom: Single;
begin
  LX1 := FMrX1;
  LX2 := LX1 + 8;
  if LX2 > FMrX2 then
    LX2 := FMrX2;
  while LX1 < LX2 do
  begin
    LPartial := (FPlaneB / GREED_FRACUNIT) * FState.YSlope^[FMrY + FState.MaxScroll] + FPlaneC;
    LDenom := (FPlaneA / GREED_FRACUNIT) * FState.XSlope^[LX1] + LPartial;
    if LDenom >= 8000 then
    begin
      LPointZ := Trunc(FPlaneD / LDenom * GREED_FRACUNIT);
      if LPointZ <= GREED_MAX_Z then
      begin
        LDenom := (FPlaneA / GREED_FRACUNIT) * FState.XSlope^[LX2] + LPartial;
        if LDenom >= 8000 then
        begin
          LPointZ2 := Trunc(FPlaneD / LDenom * GREED_FRACUNIT);
          if LPointZ2 <= GREED_MAX_Z then
          begin
            AddSpanRow(LPointZ, LX1, LX2, LPointZ2);
          end;
        end;
      end;
    end;
    // _nextpoint
    LX1 := LX2;
    LX2 := LX1 + 8;
    if LX2 > FMrX2 then
      LX2 := FMrX2;
  end;
end;

procedure TGreedPlaneRenderer.SlopeSpan;
begin
  if FSlopePrecise then
    SlopeSpanPrecise
  else
    SlopeSpanFast;
end;

// The vertex list must be preclipped, convex and in clockwise order. Backfaces generate no pixels. The polygon is
// divided into trapezoids that have a constant slope on both sides
procedure TGreedPlaneRenderer.RenderPolygon(AFlat: Boolean);
const
  INFINITE_LOOP = 100;
var
  LStopY, LDeltaX, LDeltaY, LOldX, LCount, LLeftVertex, LRightVertex, LGuard: Integer;
  LLeftFrac, LRightFrac, LLeftStep, LRightStep: Int64;
  S: TGreedRenderState;
begin
  S := FState;
  LLeftFrac := 0;
  LRightFrac := 0;
  LLeftStep := 0;
  LRightStep := 0;
  // find topmost vertex
  LRightVertex := 0;
  for LLeftVertex := 1 to FNumVertex - 1 do
    if FVertexY[LLeftVertex] < FVertexY[LRightVertex] then
      LRightVertex := LLeftVertex;
  // ride down the left and right edges
  FMrY := FVertexY[LRightVertex];
  LLeftVertex := LRightVertex;
  if FMrY >= S.ScrollMax then
    Exit; // totally off bottom

  LCount := 0;
  repeat
    if FMrY = FVertexY[LRightVertex] then
    begin
      LGuard := 0;
      while True do
      begin
        LOldX := FVertexX[LRightVertex];
        Inc(LRightVertex);
        if LRightVertex = FNumVertex then
          LRightVertex := 0;
        LDeltaY := FVertexY[LRightVertex] - FMrY;
        if LDeltaY = 0 then
        begin
          if LLeftVertex = LRightVertex then
            Exit; // the last edge is exactly horizontal
          Inc(LGuard);
          if LGuard > 16 then
            Exit;
          Continue;
        end;
        LDeltaX := FVertexX[LRightVertex] - LOldX;
        LRightFrac := Int64(LOldX) * GREED_FRACUNIT; // fix roundoff
        LRightStep := (LDeltaX * GREED_FRACUNIT) div LDeltaY;
        Break;
      end;
    end;
    if FMrY = FVertexY[LLeftVertex] then
    begin
      LGuard := 0;
      while True do
      begin
        LOldX := FVertexX[LLeftVertex];
        Dec(LLeftVertex);
        if LLeftVertex = -1 then
          LLeftVertex := FNumVertex - 1;
        LDeltaY := FVertexY[LLeftVertex] - FMrY;
        if LDeltaY = 0 then
        begin
          Inc(LGuard);
          if LGuard > 16 then
            Exit;
          Continue;
        end;
        LDeltaX := FVertexX[LLeftVertex] - LOldX;
        LLeftFrac := Int64(LOldX) * GREED_FRACUNIT; // fix roundoff
        LLeftStep := (LDeltaX * GREED_FRACUNIT) div LDeltaY;
        Break;
      end;
    end;
    if FVertexY[LRightVertex] < FVertexY[LLeftVertex] then
      LStopY := FVertexY[LRightVertex]
    else
      LStopY := FVertexY[LLeftVertex];
    // draw a trapezoid
    if LStopY <= S.ScrollMin then
    begin
      LLeftFrac := LLeftFrac + LLeftStep * (LStopY - FMrY);
      LRightFrac := LRightFrac + LRightStep * (LStopY - FMrY);
      FMrY := LStopY;
      Continue;
    end;
    if FMrY < S.ScrollMin then
    begin
      LLeftFrac := LLeftFrac + LLeftStep * (S.ScrollMin - FMrY);
      LRightFrac := LRightFrac + LRightStep * (S.ScrollMin - FMrY);
      FMrY := S.ScrollMin;
    end;
    if LStopY > S.ScrollMax then
      LStopY := S.ScrollMax;
    while FMrY < LStopY do
    begin
      FMrX1 := LLeftFrac div GREED_FRACUNIT;
      FMrX2 := LRightFrac div GREED_FRACUNIT;
      if FMrX1 < S.XClipL then
        FMrX1 := S.XClipL;
      if FMrX2 > S.XClipH then
        FMrX2 := S.XClipH;
      if (FMrX1 < S.XClipH) and (FMrX2 > FMrX1) then
      begin
        if AFlat then
          FlatSpan
        else
          SlopeSpan;
      end;
      LLeftFrac := LLeftFrac + LLeftStep;
      LRightFrac := LRightFrac + LRightStep;
      Inc(FMrY);
    end;
    Inc(LCount);
  until (LRightVertex = LLeftVertex) or (FMrY = S.ScrollMax) or (LCount >= INFINITE_LOOP);
end;

// Calculates the plane equation of the corners 0, 1 and 2 (planeD is actually -planeD)
procedure TGreedPlaneRenderer.CalcPlaneEquation;
var
  LX1, LY1, LZ1, LX2, LY2, LZ2: Integer;
begin
  // two vectors going away from the middle vertex
  LX1 := FVertexPt[0].TX - FVertexPt[1].TX;
  LY1 := FVertexPt[0].TY - FVertexPt[1].TY;
  LZ1 := FVertexPt[0].TZ - FVertexPt[1].TZ;
  LX2 := FVertexPt[2].TX - FVertexPt[1].TX;
  LY2 := FVertexPt[2].TY - FVertexPt[1].TY;
  LZ2 := FVertexPt[2].TZ - FVertexPt[1].TZ;
  // the A, B, C coefficients are the cross product of v1 and v2, shifted to save some precision bits
  FPlaneA := (((LY1 / GREED_FRACUNIT * LZ2) - (LZ1 / GREED_FRACUNIT * LY2)) / 256);
  FPlaneB := (((LZ1 / GREED_FRACUNIT * LX2) - (LX1 / GREED_FRACUNIT * LZ2)) / 256);
  FPlaneC := (((LX1 / GREED_FRACUNIT * LY2) - (LY1 / GREED_FRACUNIT * LX2)) / 256);
  // D is calculated from A, B, C and one of the vertex points
  FPlaneD := (FPlaneA * FVertexPt[0].TX / GREED_FRACUNIT) + (FPlaneB * FVertexPt[0].TY / GREED_FRACUNIT) +
    (FPlaneC * FVertexPt[0].TZ / GREED_FRACUNIT);
end;

function TGreedPlaneRenderer.ZClipPolygon(ACount, AZMin: Integer): Boolean;
var
  LV: Integer;
  LScale: Double;
  LFrac, LClipTX, LClipTY: Double;
  LP1, LP2: ^TGreedClipPoint;
begin
  FNumVertex := 0;
  if AZMin < GREED_MIN_Z then
    AZMin := GREED_MIN_Z; // less than this will cause problems
  LP1 := @FVertexPt[0];
  for LV := 1 to ACount do
  begin
    LP2 := LP1; // p2 is the old point
    if LV <> ACount then
      LP1 := @FVertexPt[LV] // p1 is the new point
    else
      LP1 := @FVertexPt[0];
    if (LP1^.TZ < AZMin) xor (LP2^.TZ < AZMin) then
    begin
      LScale := FState.FScale / AZMin;
      LFrac := (LP1^.TZ - AZMin) / (LP1^.TZ - LP2^.TZ);
      LClipTX := LP1^.TX + (LP2^.TX - LP1^.TX) * LFrac;
      LClipTY := LP1^.TY + (LP2^.TY - LP1^.TY) * LFrac;
      FVertexX[FNumVertex] := FState.CenterX + GreedRint((LClipTX / GREED_FRACUNIT) * LScale);
      FVertexY[FNumVertex] := FState.CenterY - GreedRint((LClipTY / GREED_FRACUNIT) * LScale);
      if FCeilingBit and (FVertexY[FNumVertex] > 1280) then
        Exit(False);
      Inc(FNumVertex);
    end;
    if LP1^.TZ >= AZMin then
    begin
      FVertexX[FNumVertex] := LP1^.PX;
      FVertexY[FNumVertex] := LP1^.PY;
      if FCeilingBit and (FVertexY[FNumVertex] > 1280) then
        Exit(False);
      Inc(FNumVertex);
    end;
  end;
  Result := FNumVertex <> 0;
end;

procedure TGreedPlaneRenderer.SlopePolygon(ACount: Integer);
begin
  CalcPlaneEquation;
  if ZClipPolygon(ACount, GREED_MIN_Z) then
    RenderPolygon(False);
end;

// the lighting effect of the floor of the tile: a color table of the effect, or none
procedure TGreedPlaneRenderer.FloorShadow;
var
  S: TGreedRenderState;
begin
  S := FState;
  FMrShadow := S.MapEffects[S.MapSpot];
  FMrColormap := nil;
  case FMrShadow of
    1: begin FMrColormap := @S.ColorMaps[S.WallGlow * 256]; FMrShadow := -1; end;
    2: begin FMrColormap := @S.ColorMaps[S.WallFlicker1 * 256]; FMrShadow := -1; end;
    3: begin FMrColormap := @S.ColorMaps[S.WallFlicker2 * 256]; FMrShadow := -1; end;
    4: begin FMrColormap := @S.ColorMaps[S.WallFlicker3 * 256]; FMrShadow := -1; end;
    5..8:
      if S.WallCycle = FMrShadow - 5 then
      begin
        FMrColormap := S.ColorMaps;
        FMrShadow := -1;
      end
      else
        FMrShadow := 0;
  end;
end;

procedure TGreedPlaneRenderer.DrawFloor(AFlags: Integer);
var
  LPolyType: Integer;
begin
  LPolyType := (AFlags and GREED_FL_FLOOR) shr GREED_FLS_FLOOR;
  FCeilingBit := False;
  case LPolyType of
    GREED_POLY_FLAT:
      begin
        FSpanKind := gskFlat;
        FMrDeltaHeight := FState.Vertex[0]^.FloorHeight;
        if FMrDeltaHeight < 0 then
        begin
          CopyFloor(0, 0);
          CopyFloor(1, 1);
          CopyFloor(2, 2);
          CopyFloor(3, 3);
          if ZClipPolygon(4, -FMrDeltaHeight) then
            RenderPolygon(True);
        end;
      end;
    GREED_POLY_SLOPE:
      begin
        FSpanKind := gskSlope;
        if not FSlopeSplitFloor then
        begin
          CopyFloor(0, 0);
          CopyFloor(1, 1);
          CopyFloor(2, 2);
          CopyFloor(3, 3);
          SlopePolygon(4);
        end
        else
        begin
          CopyFloor(0, 0);
          CopyFloor(0, 1, 1);
          CopyFloor(0, 3, 2);
          SlopePolygon(3);

          CopyFloor(1, 0);
          CopyFloor(1, 2, 1);
          CopyFloor(1, 0, 2);
          SlopePolygon(3);

          CopyFloor(2, 0);
          CopyFloor(2, 3, 1);
          CopyFloor(1, 2, 2);
          SlopePolygon(3);

          CopyFloor(3, 0);
          CopyFloor(0, 3, 1);
          CopyFloor(2, 3, 2);
          SlopePolygon(3);

          CopyFloor(0, 3, 0);
          CopyFloor(1, 3, 1);
          CopyFloor(2, 3, 2);
          SlopePolygon(3);

          CopyFloor(0, 1, 0);
          CopyFloor(1, 3, 1);
          CopyFloor(0, 3, 2);
          SlopePolygon(3);

          CopyFloor(1, 2, 0);
          CopyFloor(1, 3, 1);
          CopyFloor(0, 1, 2);
          SlopePolygon(3);

          CopyFloor(2, 3, 0);
          CopyFloor(1, 3, 1);
          CopyFloor(1, 2, 2);
          SlopePolygon(3);
        end;
      end;
    GREED_POLY_UL_TO_LR:
      begin
        FSpanKind := gskSlope;
        CopyFloor(0, 0);
        CopyFloor(1, 1);
        CopyFloor(2, 2);
        SlopePolygon(3);
        CopyFloor(2, 0);
        CopyFloor(3, 1);
        CopyFloor(0, 2);
        SlopePolygon(3);
      end;
    GREED_POLY_UR_TO_LL:
      begin
        FSpanKind := gskSlope;
        CopyFloor(0, 0);
        CopyFloor(1, 1);
        CopyFloor(3, 2);
        SlopePolygon(3);
        CopyFloor(1, 0);
        CopyFloor(2, 1);
        CopyFloor(3, 2);
        SlopePolygon(3);
      end;
  end;
end;

procedure TGreedPlaneRenderer.DrawCeiling(AFlags: Integer);
var
  LPolyType, LFlatPic: Integer;
  LTransparent: Boolean;

  procedure PickSlopeKind;
  begin
    if LFlatPic = 63 then
      FSpanKind := gskSky
    else if LTransparent then
      FSpanKind := gskSlopeSky
    else
      FSpanKind := gskSlope;
  end;

begin
  LFlatPic := FState.CeilingPic[FState.MapSpot];
  LTransparent := FState.CeilingFlags[FState.MapSpot] and GREED_WALL_TRANSPARENT <> 0;
  if (LFlatPic >= 0) and (LFlatPic < Length(FState.FlatTranslation)) then
    LFlatPic := FState.FlatTranslation[LFlatPic];
  FMrPicture := FState.FlatAt(LFlatPic);
  if FMrPicture = nil then
    Exit;
  FCeilingBit := True;
  LPolyType := (AFlags and GREED_FL_CEILING) shr GREED_FLS_CEILING;
  case LPolyType of
    GREED_POLY_FLAT:
      begin
        if LFlatPic = 63 then
          FSpanKind := gskSky
        else if LTransparent then
          FSpanKind := gskFlatSky
        else
          FSpanKind := gskFlat;
        FMrDeltaHeight := FState.Vertex[0]^.CeilingHeight;
        if FMrDeltaHeight > 0 then
        begin
          CopyCeiling(3, 0);
          CopyCeiling(2, 1);
          CopyCeiling(1, 2);
          CopyCeiling(0, 3);
          if ZClipPolygon(4, FMrDeltaHeight) then
            RenderPolygon(True);
        end;
      end;
    GREED_POLY_SLOPE:
      begin
        PickSlopeKind;
        if not FSlopeSplitCeiling then
        begin
          CopyCeiling(3, 0);
          CopyCeiling(2, 1);
          CopyCeiling(1, 2);
          CopyCeiling(0, 3);
          SlopePolygon(4);
        end
        else
        begin
          CopyCeiling(3, 0);
          CopyCeiling(2, 3, 1);
          CopyCeiling(0, 3, 2);
          SlopePolygon(3);

          CopyCeiling(2, 0);
          CopyCeiling(1, 2, 1);
          CopyCeiling(2, 3, 2);
          SlopePolygon(3);

          CopyCeiling(1, 0);
          CopyCeiling(0, 1, 1);
          CopyCeiling(1, 2, 2);
          SlopePolygon(3);

          CopyCeiling(0, 0);
          CopyCeiling(0, 3, 1);
          CopyCeiling(0, 1, 2);
          SlopePolygon(3);

          CopyCeiling(0, 3, 0);
          CopyCeiling(3, 2, 1);
          CopyCeiling(1, 3, 2);
          SlopePolygon(3);

          CopyCeiling(0, 3, 0);
          CopyCeiling(1, 3, 1);
          CopyCeiling(1, 0, 2);
          SlopePolygon(3);

          CopyCeiling(3, 2, 0);
          CopyCeiling(2, 1, 1);
          CopyCeiling(1, 3, 2);
          SlopePolygon(3);

          CopyCeiling(1, 2, 0);
          CopyCeiling(1, 0, 1);
          CopyCeiling(1, 3, 2);
          SlopePolygon(3);
        end;
      end;
    GREED_POLY_UL_TO_LR:
      begin
        PickSlopeKind;
        CopyCeiling(3, 0);
        CopyCeiling(2, 1);
        CopyCeiling(1, 2);
        SlopePolygon(3);
        CopyCeiling(3, 0);
        CopyCeiling(1, 1);
        CopyCeiling(0, 2);
        SlopePolygon(3);
      end;
    GREED_POLY_UR_TO_LL:
      begin
        PickSlopeKind;
        CopyCeiling(3, 0);
        CopyCeiling(2, 1);
        CopyCeiling(0, 2);
        SlopePolygon(3);
        CopyCeiling(2, 0);
        CopyCeiling(1, 1);
        CopyCeiling(0, 2);
        SlopePolygon(3);
      end;
  end;
end;

// draw floor and ceiling for the tile
procedure TGreedPlaneRenderer.RenderTileEnds;
var
  S: TGreedRenderState;
  LFlags, LFlatPic: Integer;
begin
  S := FState;
  Inc(S.XClipH);
  LFlags := S.MapFlags[S.MapSpot];
  // draw the floor
  LFlatPic := S.FloorPic[S.MapSpot];
  FloorShadow;
  FMrLight := S.MapLight;
  if (LFlatPic >= 0) and (LFlatPic < Length(S.FlatTranslation)) then
    LFlatPic := S.FlatTranslation[LFlatPic];
  FMrPicture := S.FlatAt(LFlatPic);
  if FMrPicture <> nil then
    DrawFloor(LFlags);
  // draw the ceiling (the shadow and the light of the floor are the ones of the ceiling)
  DrawCeiling(LFlags);
end;

end.

