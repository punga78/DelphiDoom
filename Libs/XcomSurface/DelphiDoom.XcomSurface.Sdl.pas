{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the SDL 1.2 operations OpenXcom relies on  }
{  on 8 bit surfaces (SDL_BlitSurface with a color key, SDL_FillRect)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit; the SDL behavior    }
{  is rewritten from the documented behavior of SDL 1.2.15                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Sdl;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.XcomSurface.Types;

type
  /// <summary>The part of a blit that is left after the clipping of SDL_UpperBlit</summary>
  TXcomBlitClip = record
    SourceX, SourceY, DestX, DestY, Width, Height: Integer;
  end;

  /// <summary>
  ///   The few SDL 1.2 functions that Surface uses on 8 bit surfaces. A surface is described by its pixels, size and
  ///   palette so this unit does not depend on the Surface class
  /// </summary>
  TXcomSdl = class
  public
    /// <summary>
    ///   SDL_FindColor: the first palette entry nearest to the color (squared distance; the search stops at an
    ///   exact match)
    /// </summary>
    class function FindColor(const APalette: TXcomPalette; ARed, AGreen, ABlue: Byte): Byte; static;
    /// <summary>
    ///   SDL_IntersectRect: the intersection of two rectangles computed with integers; false when it is empty
    /// </summary>
    class function IntersectRect(const AFirst, ASecond: TXcomRect; out AResult: TXcomRect): Boolean; static;
    /// <summary>
    ///   SDL_FillRect on a surface whose clip rectangle is the whole surface; the color is the low byte.
    ///   A rectangle that the clip empties does nothing
    /// </summary>
    class procedure FillRect(APixels: PByte; AWidth, AHeight: Integer; const ARect: TXcomRect;
      AColor: Cardinal); static;
    /// <summary>
    ///   The clipping of SDL_UpperBlit against the source rectangle (nil: the whole source), the source size and the
    ///   destination (whose clip rectangle is the whole surface); false when nothing is left to copy
    /// </summary>
    class function ClipBlit(ASourceWidth, ASourceHeight: Integer; ASourceRect: PXcomRect;
      ADestWidth, ADestHeight: Integer; AX, AY: Integer; out AClip: TXcomBlitClip): Boolean; static;
    /// <summary>
    ///   SDL_UpperBlit between two 8 bit surfaces where the source has color key 0 (a pixel of index 0 is
    ///   transparent). If ASourceRect is nil the whole source is copied. AX and AY are the position in the
    ///   destination; the copy is clipped against the source and the destination as SDL does. If the palettes are
    ///   not identical the source colors are mapped to the nearest destination color (SDL_Map1to1)
    /// </summary>
    class procedure BlitKeyed(ASourcePixels: PByte; ASourceWidth, ASourceHeight: Integer;
      const ASourcePalette: TXcomPalette; ASourceRect: PXcomRect; ADestPixels: PByte;
      ADestWidth, ADestHeight: Integer; const ADestPalette: TXcomPalette; AX, AY: Integer); static;
  end;

implementation

{ TXcomSdl }

class function TXcomSdl.FindColor(const APalette: TXcomPalette; ARed, AGreen, ABlue: Byte): Byte;
var
  LIndex: Integer;
  LRed, LGreen, LBlue: Integer;
  LDistance: Int64;
  LSmallest: Int64;
begin
  Result := 0;
  LSmallest := High(Cardinal);
  for LIndex := 0 to APalette.Count - 1 do
  begin
    LRed := Integer(APalette.Colors[LIndex].Red) - ARed;
    LGreen := Integer(APalette.Colors[LIndex].Green) - AGreen;
    LBlue := Integer(APalette.Colors[LIndex].Blue) - ABlue;
    LDistance := Int64(LRed * LRed + LGreen * LGreen + LBlue * LBlue);
    if LDistance < LSmallest then
    begin
      Result := Byte(LIndex);
      if LDistance = 0 then
        Break;
      LSmallest := LDistance;
    end;
  end;
end;

class function TXcomSdl.IntersectRect(const AFirst, ASecond: TXcomRect; out AResult: TXcomRect): Boolean;
var
  LMin, LMax, LOther: Integer;
begin
  LMin := AFirst.X;
  LMax := LMin + AFirst.W;
  if ASecond.X > LMin then
    LMin := ASecond.X;
  AResult.X := SmallInt(LMin and $FFFF);
  LOther := Integer(ASecond.X) + ASecond.W;
  if LOther < LMax then
    LMax := LOther;
  if LMax - LMin > 0 then
    AResult.W := Word((LMax - LMin) and $FFFF)
  else
    AResult.W := 0;
  LMin := AFirst.Y;
  LMax := LMin + AFirst.H;
  if ASecond.Y > LMin then
    LMin := ASecond.Y;
  AResult.Y := SmallInt(LMin and $FFFF);
  LOther := Integer(ASecond.Y) + ASecond.H;
  if LOther < LMax then
    LMax := LOther;
  if LMax - LMin > 0 then
    AResult.H := Word((LMax - LMin) and $FFFF)
  else
    AResult.H := 0;
  Result := (AResult.W <> 0) and (AResult.H <> 0);
end;

class procedure TXcomSdl.FillRect(APixels: PByte; AWidth, AHeight: Integer; const ARect: TXcomRect;
  AColor: Cardinal);
var
  LClip: TXcomRect;
  LRect: TXcomRect;
  LRow: Integer;
begin
  LClip := TXcomRect.Make(0, 0, AWidth, AHeight);
  if not IntersectRect(ARect, LClip, LRect) then
    Exit;
  for LRow := LRect.Y to LRect.Y + LRect.H - 1 do
    FillChar((APixels + LRow * AWidth + LRect.X)^, LRect.W, Byte(AColor and $FF));
end;

class function TXcomSdl.ClipBlit(ASourceWidth, ASourceHeight: Integer; ASourceRect: PXcomRect;
  ADestWidth, ADestHeight: Integer; AX, AY: Integer; out AClip: TXcomBlitClip): Boolean;
var
  LSourceX, LSourceY, LWidth, LHeight, LMax, LDelta: Integer;
  LDestX, LDestY: Integer;
begin
  LDestX := SmallInt(AX and $FFFF);
  LDestY := SmallInt(AY and $FFFF);
  if Assigned(ASourceRect) then
  begin
    LSourceX := ASourceRect^.X;
    LWidth := ASourceRect^.W;
    if LSourceX < 0 then
    begin
      Inc(LWidth, LSourceX);
      LDestX := SmallInt((LDestX - LSourceX) and $FFFF);
      LSourceX := 0;
    end;
    LMax := ASourceWidth - LSourceX;
    if LMax < LWidth then
      LWidth := LMax;
    LSourceY := ASourceRect^.Y;
    LHeight := ASourceRect^.H;
    if LSourceY < 0 then
    begin
      Inc(LHeight, LSourceY);
      LDestY := SmallInt((LDestY - LSourceY) and $FFFF);
      LSourceY := 0;
    end;
    LMax := ASourceHeight - LSourceY;
    if LMax < LHeight then
      LHeight := LMax;
  end
  else
  begin
    LSourceX := 0;
    LSourceY := 0;
    LWidth := ASourceWidth;
    LHeight := ASourceHeight;
  end;
  // clip against the destination (its clip rectangle is the whole surface)
  LDelta := -LDestX;
  if LDelta > 0 then
  begin
    Dec(LWidth, LDelta);
    LDestX := SmallInt((LDestX + LDelta) and $FFFF);
    Inc(LSourceX, LDelta);
  end;
  LDelta := LDestX + LWidth - ADestWidth;
  if LDelta > 0 then
    Dec(LWidth, LDelta);
  LDelta := -LDestY;
  if LDelta > 0 then
  begin
    Dec(LHeight, LDelta);
    LDestY := SmallInt((LDestY + LDelta) and $FFFF);
    Inc(LSourceY, LDelta);
  end;
  LDelta := LDestY + LHeight - ADestHeight;
  if LDelta > 0 then
    Dec(LHeight, LDelta);
  AClip.SourceX := LSourceX;
  AClip.SourceY := LSourceY;
  AClip.DestX := LDestX;
  AClip.DestY := LDestY;
  AClip.Width := LWidth;
  AClip.Height := LHeight;
  Result := (LWidth > 0) and (LHeight > 0);
end;

class procedure TXcomSdl.BlitKeyed(ASourcePixels: PByte; ASourceWidth, ASourceHeight: Integer;
  const ASourcePalette: TXcomPalette; ASourceRect: PXcomRect; ADestPixels: PByte;
  ADestWidth, ADestHeight: Integer; const ADestPalette: TXcomPalette; AX, AY: Integer);
var
  LClip: TXcomBlitClip;
  LIdentical: Boolean;
  LMap: array[0..XCOM_SURFACE_COLORS - 1] of Byte;
  LIndex, LRow, LColumn: Integer;
  LValue: Byte;
begin
  if not ClipBlit(ASourceWidth, ASourceHeight, ASourceRect, ADestWidth, ADestHeight, AX, AY, LClip) then
    Exit;
  // SDL_Map1to1: an identical palette needs no map
  LIdentical := False;
  if ASourcePalette.Count <= ADestPalette.Count then
    LIdentical := CompareMem(@ASourcePalette.Colors[0], @ADestPalette.Colors[0],
      ASourcePalette.Count * SizeOf(TXcomColor));
  if not LIdentical then
    for LIndex := 0 to ASourcePalette.Count - 1 do
      LMap[LIndex] := FindColor(ADestPalette, ASourcePalette.Colors[LIndex].Red,
        ASourcePalette.Colors[LIndex].Green, ASourcePalette.Colors[LIndex].Blue);
  for LRow := 0 to LClip.Height - 1 do
    for LColumn := 0 to LClip.Width - 1 do
    begin
      LValue := (ASourcePixels + (LClip.SourceY + LRow) * ASourceWidth + LClip.SourceX + LColumn)^;
      if LValue <> 0 then
      begin
        if not LIdentical then
          LValue := LMap[LValue];
        (ADestPixels + (LClip.DestY + LRow) * ADestWidth + LClip.DestX + LColumn)^ := LValue;
      end;
    end;
end;

end.
