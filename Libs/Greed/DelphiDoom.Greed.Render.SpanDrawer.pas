{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the drawing of the spans of the renderer         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): DrawSpans, DrawSprite,      }
{  DrawDoorPost and the post and row loops of r_spans.pas                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.SpanDrawer;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Render.State;

type
  /// <summary>
  ///   Sorts the spans of the frame from the farthest to the nearest and draws them into the picture: the rows of the
  ///   floors and ceilings (flat or sloping, with the sky behind the transparent ones), the posts of the doors, the
  ///   steps and the transparent walls, and the sprites column by column. Drawing from the back to the front is how
  ///   the renderer solves what hides what
  /// </summary>
  TGreedSpanDrawer = class
  strict private
    FState: TGreedRenderState;
    // mr_*: the row that is mapped
    FMrCount, FMrXFrac, FMrYFrac, FMrXStep, FMrYStep: Integer;
    FMrDest: PByte;
    FMrColormap: PByte;
    FMrPicture: PByte;
    FPointZ: Integer;
    FSpanX: Integer;
    procedure ScaleMaskedPost;
    procedure ScaleTransPost;
    procedure MapRow;
    procedure DrawDoorPost(ASpan: PGreedSpan);
    procedure DrawSprite(ASpan: PGreedSpan);
    procedure DrawSkyRow(ASpan: PGreedSpan; ACenter, AWidthHalf: Integer; var AX2: Integer; AOverlay: Boolean);
    function RowColormap(ASpan: PGreedSpan): Boolean;
    procedure DrawPendingPost(ASpan: PGreedSpan; AMasked: Boolean);
  public
    constructor Create(AState: TGreedRenderState);
    /// <summary>DrawSpans: sorts the list and draws it</summary>
    procedure DrawSpans;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.FixedMath,
  DelphiDoom.Greed.Render.SpanSorter, DelphiDoom.Greed.Render.WallRenderer;

type
  FM = TGreedFixedMath;

{ TGreedSpanDrawer }

constructor TGreedSpanDrawer.Create(AState: TGreedRenderState);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  FState := AState;
end;

procedure TGreedSpanDrawer.ScaleMaskedPost;
var
  S: TGreedRenderState;
  LDest: PByte;
  LColor: Byte;
begin
  S := FState;
  S.SpDest := S.SpDest - S.WindowWidth * (S.SpCount - 1); // go to the top
  LDest := S.Buffer + S.SpDest;
  while S.SpCount > 0 do
  begin
    LColor := S.SpSource[S.SpFrac div GREED_FRACUNIT];
    if LColor <> 0 then
      LDest^ := S.SpColormap[LColor];
    Inc(LDest, S.WindowWidth);
    S.SpFrac := S.SpFrac + S.SpFracStep;
    S.SpFrac := S.SpFrac and S.SpLoopValue;
    Dec(S.SpCount);
  end;
  S.SpDest := LDest - S.Buffer;
end;

procedure TGreedSpanDrawer.ScaleTransPost;
var
  S: TGreedRenderState;
  LDest: PByte;
  LColor: Byte;
begin
  S := FState;
  S.SpDest := S.SpDest - S.WindowWidth * (S.SpCount - 1); // go to the top
  LDest := S.Buffer + S.SpDest;
  while S.SpCount > 0 do
  begin
    Dec(S.SpCount);
    if S.SpCount = 0 then
      Break;
    LColor := S.SpSource[S.SpFrac div GREED_FRACUNIT];
    if LColor <> 0 then
      LDest^ := S.Transparency[((S.SpColormap[LColor] - 1) and 255) * 256 + LDest^];
    Inc(LDest, S.WindowWidth);
    S.SpFrac := S.SpFrac + S.SpFracStep;
    S.SpFrac := S.SpFrac and S.SpLoopValue;
  end;
  S.SpDest := LDest - S.Buffer;
end;

procedure TGreedSpanDrawer.MapRow;
var
  LSpot: Integer;
begin
  while FMrCount > 0 do
  begin
    LSpot := (FMrYFrac shr (GREED_FRACBITS - 6)) and (63 * 64) + ((FMrXFrac div GREED_FRACUNIT) and 63);
    FMrDest^ := FMrColormap[FMrPicture[LSpot]];
    Inc(FMrDest);
    FMrXFrac := FMrXFrac + FMrXStep;
    FMrYFrac := FMrYFrac + FMrYStep;
    Dec(FMrCount);
  end;
end;

procedure TGreedSpanDrawer.DrawDoorPost(ASpan: PGreedSpan);
var
  S: TGreedRenderState;
  LTop, LBottom, LTopY, LBottomY, LFracAdjust, LScale, LLight: Integer;
begin
  S := FState;
  LScale := FM.Mul(FPointZ, S.IScale);
  S.SpSource := ASpan^.Picture;

  S.SpColormap := S.ColorMaps;
  if ASpan^.Shadow = 0 then
  begin
    LLight := (FPointZ div GREED_FRACUNIT) + ASpan^.Light;
    if LLight > GREED_MAX_Z_LIGHT then
      Exit;
    S.SpColormap := S.LightColormap(LLight);
  end
  else if ASpan^.Shadow = 1 then
    S.SpColormap := @S.ColorMaps[S.WallGlow * 256]
  else if ASpan^.Shadow = 2 then
    S.SpColormap := @S.ColorMaps[S.WallFlicker1 * 256]
  else if ASpan^.Shadow = 3 then
    S.SpColormap := @S.ColorMaps[S.WallFlicker2 * 256]
  else if ASpan^.Shadow = 4 then
    S.SpColormap := @S.ColorMaps[S.WallFlicker3 * 256]
  else if (ASpan^.Shadow >= 5) and (ASpan^.Shadow <= 8) then
  begin
    if S.WallCycle = ASpan^.Shadow - 5 then
      S.SpColormap := S.ColorMaps
    else
      S.SpColormap := S.LightColormap((FPointZ div GREED_FRACUNIT) + ASpan^.Light);
  end
  else if ASpan^.Shadow = 9 then
    S.SpColormap := S.LightColormap((FPointZ div GREED_FRACUNIT) + ASpan^.Light + S.WallFlicker4);

  S.SpFracStep := FM.Mul(FPointZ, S.IScale);
  LTop := FM.Divide(ASpan^.Y, LScale);
  LTopY := LTop div GREED_FRACUNIT;
  LFracAdjust := LTop and (GREED_FRACUNIT - 1);
  S.SpFrac := FM.Mul(LFracAdjust, S.SpFracStep);
  LTopY := S.CenterY - LTopY;
  S.SpLoopValue := 256 * GREED_FRACUNIT - 1;
  if LTopY < S.ScrollMin then
  begin
    S.SpFrac := S.SpFrac + (S.ScrollMin - LTopY) * LScale;
    while S.SpFrac > S.SpLoopValue do
      S.SpFrac := S.SpFrac - S.SpLoopValue - 1;
    LTopY := S.ScrollMin;
  end;
  LBottom := FM.Divide(ASpan^.YH, LScale);
  if LBottom >= (S.CenterY + S.ScrollMin) * GREED_FRACUNIT then
    LBottomY := S.ScrollMax - 1
  else
    LBottomY := S.CenterY + (LBottom div GREED_FRACUNIT);
  if (LBottomY <= S.ScrollMin) or (LTopY >= S.ScrollMax) then
    Exit;
  S.SpCount := LBottomY - LTopY + 1;
  S.SpDest := (LBottomY - S.ScrollMin) * S.WindowWidth + FSpanX;

  if ASpan^.Kind = gskMaskedDoor then
    ScaleMaskedPost
  else
    TGreedWallRenderer.ScalePostOf(S);
end;

procedure TGreedSpanDrawer.DrawSprite(ASpan: PGreedSpan);
var
  S: TGreedRenderState;
  LLeftX, LScale, LXFrac, LFracStep, LShapeBottom, LTopHeight, LBottomHeight: Integer;
  LPost, LX, LTopY, LBottomY, LLight, LShadow, LBitShift: Integer;
  LValue: Int64;
  LSpecial: TGreedSpecialType;
  LPic, LColumn: PByte;
  LWidth, LColumnOffset: Integer;
begin
  S := FState;
  // floor shadows
  LSpecial := TGreedSpecialType(ASpan^.Shadow div 256);
  LShadow := ASpan^.Shadow and 255;

  S.SpColormap := S.ColorMaps; // st_maxlight
  if LSpecial = gstTransparent then
    S.SpColormap := S.ColorMaps
  else if LShadow = 0 then
  begin
    LLight := (FPointZ div GREED_FRACUNIT) + ASpan^.Light;
    if LLight > GREED_MAX_Z_LIGHT then
      Exit;
    S.SpColormap := S.LightColormap(LLight);
  end
  else if ASpan^.Shadow = 1 then
    S.SpColormap := @S.ColorMaps[S.WallGlow * 256]
  else if ASpan^.Shadow = 2 then
    S.SpColormap := @S.ColorMaps[S.WallFlicker1 * 256]
  else if ASpan^.Shadow = 3 then
    S.SpColormap := @S.ColorMaps[S.WallFlicker2 * 256]
  else if ASpan^.Shadow = 4 then
    S.SpColormap := @S.ColorMaps[S.WallFlicker3 * 256]
  else if (ASpan^.Shadow >= 5) and (ASpan^.Shadow <= 8) then
  begin
    if S.WallCycle = ASpan^.Shadow - 5 then
      S.SpColormap := S.ColorMaps
    else
      S.SpColormap := S.LightColormap((FPointZ div GREED_FRACUNIT) + ASpan^.Light);
  end
  else if LShadow = 9 then
    S.SpColormap := S.LightColormap((FPointZ div GREED_FRACUNIT) + ASpan^.Light + S.WallFlicker4);

  LPic := ASpan^.Picture;
  if LPic = nil then
    Exit;
  LBitShift := GREED_FRACBITS - ASpan^.Scale;

  LShapeBottom := ASpan^.Y;
  // project the x and height
  LScale := FM.Divide(S.FScale, FPointZ);
  LFracStep := FM.ShiftLeft(FM.Mul(FPointZ, S.IScale), ASpan^.Scale);
  S.SpFracStep := LFracStep;
  LLeftX := ASpan^.X2;
  LLeftX := LLeftX - FM.ShiftLeft(PSmallInt(LPic)^, LBitShift);
  LValue := FM.Mul64(LLeftX, LScale);
  LValue := LValue div GREED_FRACUNIT;
  LX := S.CenterX + LValue;
  // step through the shape, drawing posts where visible
  LXFrac := 0;
  if LX < 0 then
  begin
    LXFrac := LXFrac - LFracStep * LX;
    LX := 0;
  end;
  S.SpLoopValue := 256 * GREED_FRACUNIT - 1;
  LWidth := PSmallInt(LPic + 2)^;

  while LX < S.WindowWidth do
  begin
    LPost := LXFrac div GREED_FRACUNIT;
    if LPost >= LWidth then
      Exit; // shape finished drawing
    LXFrac := LXFrac + LFracStep;
    if (FPointZ >= S.WallZ[LX]) and ((FPointZ >= S.WallZ[LX] + GREED_TILE_UNIT) or
      ((LSpecial <> gstNoClip) and (LSpecial <> gstTransparent))) then
    begin
      Inc(LX);
      Continue;
    end;
    // if the offset of the column is zero then there is no data for the post
    LColumnOffset := PSmallInt(LPic + 4 + LPost * 2)^;
    if LColumnOffset = 0 then
    begin
      Inc(LX);
      Continue;
    end;
    LColumn := LPic + LColumnOffset;
    LTopHeight := LShapeBottom + FM.ShiftLeft(LColumn[0], LBitShift);
    LBottomHeight := LShapeBottom + FM.ShiftLeft(LColumn[1], LBitShift);
    Inc(LColumn, 2);

    // scale a post
    LValue := FM.Mul64(LBottomHeight, LScale);
    LValue := LValue div GREED_FRACUNIT;
    LBottomY := S.CenterY - LValue;
    if LBottomY < S.ScrollMin then
    begin
      Inc(LX);
      Continue;
    end;
    if LBottomY >= S.ScrollMax then
      LBottomY := S.ScrollMax - 1;

    LValue := FM.Mul64(LTopHeight, LScale);
    LValue := LValue div GREED_FRACUNIT;
    LTopY := S.CenterY - LValue;
    if LTopY < S.ScrollMin then
    begin
      S.SpFrac := (S.ScrollMin - LTopY) * S.SpFracStep;
      LTopY := S.ScrollMin;
    end
    else
      S.SpFrac := 0;

    if LTopY >= S.ScrollMax then
    begin
      Inc(LX);
      Continue;
    end;

    S.SpCount := LBottomY - LTopY;
    S.SpDest := (LBottomY - S.ScrollMin) * S.WindowWidth + LX;
    S.SpSource := LColumn;
    if LSpecial = gstTransparent then
      ScaleTransPost
    else
      ScaleMaskedPost;
    Inc(LX);
  end;
end;

// the part of the sky that shows through a transparent ceiling (AOverlay) or the whole sky row
procedure TGreedSpanDrawer.DrawSkyRow(ASpan: PGreedSpan; ACenter, AWidthHalf: Integer; var AX2: Integer;
  AOverlay: Boolean);
var
  S: TGreedRenderState;
  LPX, LPY, LH1, LX, LX1, LA, LAFrac1, LCount: Integer;
  LDest: PByte;
begin
  S := FState;
  LPY := ASpan^.Y - S.ScrollMin;
  LPX := FSpanX;
  LCount := ASpan^.X2 - FSpanX;
  LDest := S.Buffer + LPY * S.WindowWidth + LPX;
  if S.WindowHeight = 400 then
    LPY := ASpan^.Y + 128
  else if S.WindowHeight = 200 then
    LPY := ASpan^.Y + 64;
  LH1 := (S.HFrac * LPY) div GREED_FRACUNIT;
  if LH1 <= 0 then
    LH1 := 0
  else if LH1 >= 255 then
    LH1 := 255;
  if LPX <= AWidthHalf then
  begin
    LAFrac1 := S.AFrac;
    LA := ((GREED_TAN_ANGLES div 2) * GREED_FRACUNIT) + S.AFrac * (AWidthHalf - LPX);
    while (LPX <= AWidthHalf) and (LCount > 0) do
    begin
      LX := S.BackTangents^[(LA div GREED_FRACUNIT) and (GREED_TAN_ANGLES * 2 - 1)] * 320 div S.WindowWidth;
      AX2 := (ACenter - LX + 320 - 257);
      AX2 := AX2 and 255;
      if (not AOverlay) or (LDest^ = 255) then
        LDest^ := S.Backdrop[LH1 * 256 + AX2];
      LA := LA - S.AFrac;
      Inc(LPX);
      Dec(LCount);
      Inc(LDest);
    end;
    S.AFrac := LAFrac1;
  end;
  if LPX > AWidthHalf then
  begin
    LAFrac1 := S.AFrac;
    LA := ((GREED_TAN_ANGLES div 2) * GREED_FRACUNIT) + S.AFrac * (LPX - AWidthHalf);
    while LCount > 0 do
    begin
      LX1 := ACenter + S.BackTangents^[(LA div GREED_FRACUNIT) and (GREED_TAN_ANGLES * 2 - 1)] * 320 div S.WindowWidth;
      LX1 := LX1 and 255;
      if (not AOverlay) or (LDest^ = 255) then
        LDest^ := S.Backdrop[LH1 * 256 + LX1];
      LA := LA + S.AFrac;
      Inc(LPX);
      Dec(LCount);
      Inc(LDest);
    end;
    S.AFrac := LAFrac1;
  end;
end;

// the color table of a floor or ceiling row; False if the row is too far to be seen
function TGreedSpanDrawer.RowColormap(ASpan: PGreedSpan): Boolean;
var
  S: TGreedRenderState;
  LLight: Integer;
begin
  S := FState;
  Result := True;
  if (ASpan^.Shadow = 0) or ((ASpan^.Colormap = nil) and (ASpan^.Shadow <> 9)) then
  begin
    LLight := (FPointZ div GREED_FRACUNIT) + ASpan^.Light;
    if LLight > GREED_MAX_Z_LIGHT then
      Exit(False);
    FMrColormap := S.LightColormap(LLight);
  end
  else if ASpan^.Shadow = 9 then
  begin
    LLight := (FPointZ div GREED_FRACUNIT) + ASpan^.Light + S.WallFlicker4;
    if LLight > GREED_MAX_Z_LIGHT then
      Exit(False);
    FMrColormap := S.LightColormap(LLight);
  end
  else
    FMrColormap := ASpan^.Colormap;
end;

// the post of a transparent wall or step that waited in the pending lists
procedure TGreedSpanDrawer.DrawPendingPost(ASpan: PGreedSpan; AMasked: Boolean);
var
  S: TGreedRenderState;
  LIndex: Integer;
begin
  S := FState;
  LIndex := ASpan^.X2;
  S.SpDest := S.PendingDest[LIndex];
  S.SpSource := ASpan^.Picture;
  S.SpColormap := S.PendingColormap[LIndex];
  S.SpFrac := ASpan^.Y;
  S.SpFracStep := ASpan^.YH;
  S.SpCount := S.PendingCount[LIndex];
  S.SpLoopValue := ASpan^.Light * GREED_FRACUNIT - 1;
  if AMasked then
    ScaleMaskedPost
  else
    TGreedWallRenderer.ScalePostOf(S);
end;

// Spans farther than MAXZ away should not have been entered into the list
procedure TGreedSpanDrawer.DrawSpans;
var
  S: TGreedRenderState;
  LTagIndex, LSpanNum, LX2, LLastZ, LLen, LZeroCosine, LZeroSine, LZeroXFrac, LZeroYFrac, LXF2, LYF2: Integer;
  LAngle, LPY, LY1, LW, LCenter, LCount: Integer;
  LSpan: PGreedSpan;
  LDest: PByte;
  LColor: Byte;
  LRow: Integer;
begin
  S := FState;
  // set up backdrop stuff
  LW := S.WindowWidth div 2;
  LCenter := S.ViewAngle and 255;

  // set up for drawing
  S.SpColormap := S.ColorMaps;
  if S.NumSpans > 1 then
    TGreedSpanSorter.Sort(S.SpanTags, S.NumSpans);

  LAngle := S.ViewFineAngle + S.PixelAngle^[0];
  LAngle := LAngle and (GREED_TAN_ANGLES * 4 - 1);
  LZeroCosine := S.Cosines^[LAngle];
  LZeroSine := S.Sines^[LAngle];
  // draw from back to front
  LX2 := -1;
  LLastZ := -1;
  LZeroXFrac := 0;
  LZeroYFrac := 0;
  for LTagIndex := 0 to S.NumSpans - 1 do
  begin
    FPointZ := Integer(S.SpanTags[LTagIndex].Point);
    LSpanNum := S.SpanTags[LTagIndex].Span;
    LSpan := @S.Spans[LSpanNum];
    FSpanX := S.SpansX[LSpanNum];
    case LSpan^.Kind of
      gskFlat, gskFlatSky:
        begin
          // floor / ceiling span
          if FPointZ <> LLastZ then
          begin
            LLastZ := FPointZ;
            FMrXStep := FM.Mul(FPointZ, S.XScale);
            FMrYStep := FM.Mul(FPointZ, S.YScale);
            // calculate starting texture point
            LLen := FM.Divide(FPointZ, S.PixelCosine^[0]);
            FMrXFrac := S.ViewX + FM.Mul(LLen, LZeroCosine);
            LZeroXFrac := FMrXFrac;
            FMrYFrac := S.ViewY - FM.Mul(LLen, LZeroSine);
            LZeroYFrac := FMrYFrac;
            LX2 := 0;
          end;
          if FSpanX <> LX2 then
          begin
            FMrXFrac := LZeroXFrac + FMrXStep * FSpanX;
            FMrYFrac := LZeroYFrac + FMrYStep * FSpanX;
          end;

          // floor shadows
          if not RowColormap(LSpan) then
            Continue;

          LY1 := LSpan^.Y - S.ScrollMin;
          if (LY1 >= S.WindowHeight) or (LY1 < 0) then
            Continue;

          FMrDest := S.Buffer + LY1 * S.WindowWidth + FSpanX;
          FMrPicture := LSpan^.Picture;
          LX2 := LSpan^.X2;

          if (LX2 > S.WindowWidth) or (LX2 < 0) then
            Continue;

          FMrCount := LX2 - FSpanX;
          MapRow;

          if LSpan^.Kind = gskFlatSky then
            DrawSkyRow(LSpan, LCenter, LW, LX2, True);
        end;

      gskSky:
        begin
          LPY := LSpan^.Y - S.ScrollMin;
          if (LPY >= S.WindowHeight) or (LPY < 0) then
            Continue;
          if (LSpan^.X2 > S.WindowWidth) or (LSpan^.X2 < 0) then
            Continue;
          DrawSkyRow(LSpan, LCenter, LW, LX2, False);
        end;

      gskStep:
        DrawPendingPost(LSpan, False);

      gskShape:
        DrawSprite(LSpan);

      gskSlope, gskSlopeSky:
        begin
          // sloping floor / ceiling span
          LLastZ := -1; // we are going to get out of order here, so
          if not RowColormap(LSpan) then
            Continue;

          LX2 := LSpan^.X2;
          LY1 := LSpan^.Y - S.ScrollMin;

          if (LY1 >= S.WindowHeight) or (LY1 < 0) then
            Continue;
          if (LX2 > S.WindowWidth) or (LX2 < 0) then
            Continue;

          FMrDest := S.Buffer + LY1 * S.WindowWidth + FSpanX;
          FMrPicture := LSpan^.Picture;
          FMrCount := LX2 - FSpanX;
          // calculate starting texture point
          LLen := FM.Divide(FPointZ, S.PixelCosine^[FSpanX]);
          LAngle := S.ViewFineAngle + S.PixelAngle^[FSpanX];
          LAngle := LAngle and (GREED_TAN_ANGLES * 4 - 1);
          FMrXFrac := S.ViewX + FM.Mul(LLen, S.Cosines^[LAngle]);
          FMrYFrac := S.ViewY - FM.Mul(LLen, S.Sines^[LAngle]);
          // calculate ending texture point (yh is pointz2 for the ending point)
          LLen := FM.Divide(LSpan^.YH, S.PixelCosine^[LX2]);
          LAngle := S.ViewFineAngle + S.PixelAngle^[LX2];
          LAngle := LAngle and (GREED_TAN_ANGLES * 4 - 1);
          LXF2 := S.ViewX + FM.Mul(LLen, S.Cosines^[LAngle]);
          LYF2 := S.ViewY - FM.Mul(LLen, S.Sines^[LAngle]);
          if FMrCount = 0 then
            Continue; // the original divides by zero here
          FMrXStep := (LXF2 - FMrXFrac) div FMrCount;
          FMrYStep := (LYF2 - FMrYFrac) div FMrCount;
          MapRow;

          if LSpan^.Kind = gskSlopeSky then
            DrawSkyRow(LSpan, LCenter, LW, LX2, True);
        end;

      gskDoor, gskMaskedDoor:
        DrawDoorPost(LSpan);

      gskTransparentWall:
        DrawPendingPost(LSpan, True);

      gskInvisibleWall:
        begin
          LRow := LSpan^.X2;
          S.SpDest := S.PendingDest[LRow];
          S.SpSource := LSpan^.Picture;
          S.SpColormap := S.PendingColormap[LRow];
          S.SpFrac := LSpan^.Y;
          S.SpFracStep := LSpan^.YH;
          S.SpCount := S.PendingCount[LRow];
          S.SpLoopValue := LSpan^.Light * GREED_FRACUNIT - 1;
          S.SpDest := S.SpDest - S.WindowWidth * (S.SpCount - 1); // go to the top
          LDest := S.Buffer + S.SpDest;
          LCount := S.SpCount;
          while LCount > 0 do
          begin
            Dec(LCount);
            LColor := S.SpSource[S.SpFrac div GREED_FRACUNIT];
            if LColor <> 0 then
              LDest^ := S.Transparency[((S.SpColormap[LColor] - 1) and 255) * 256 + LDest^];
            Inc(LDest, S.WindowWidth);
            S.SpFrac := S.SpFrac + S.SpFracStep;
            S.SpFrac := S.SpFrac and S.SpLoopValue;
          end;
          S.SpCount := 0;
          S.SpDest := LDest - S.Buffer;
        end;
    end;
  end;
end;

end.
