{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - the characters a Text placed, kept to   }
{  draw them again at the resolution of the display (issue 184)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.TextInk;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Ink.Types, DelphiDoom.XcomSurface.FontDetail.Intf,
  DelphiDoom.XcomSurface.InkPainter;

type
  /// <summary>
  ///   What a Text drew, character by character: the font, the code, the position in the pixels of the game and
  ///   the color it gave to PaletteShift. The layout is the one of the text at 320 x 200 (the widths of the
  ///   pictures of the font, the line breaks, the alignment); here the same characters are drawn AScale times
  ///   finer on the same cells: with the font of the system where the font has it, with the picture enlarged
  ///   where a character stayed a picture of the game
  /// </summary>
  TXcomTextInk = class
  strict private
    type
      TRun = record
        Font: TXcomFont;
        Code: Cardinal;
        X: Integer;
        Y: Integer;
        Color: TXcomInkColor;
      end;
    var
      FRuns: TList<TRun>;
      FScale: Integer;
      FLayers: IXcomInkLayers;
  public
    /// <param name="ADetail">The detail of one of the fonts of the text, with a scale of 2 or more</param>
    constructor Create(const ADetail: IXcomFontDetail);
    destructor Destroy; override;
    /// <summary>
    ///   The detail the text of two fonts is drawn with: the one of the first font that has one at a scale of 2
    ///   or more; nil when the text is only the one of the picture of the game
    /// </summary>
    class function DetailOf(AFirst, ASecond: TXcomFont): IXcomFontDetail; static;
    /// <summary>The scale of DetailOf, 0 without one</summary>
    class function ScaleOf(AFirst, ASecond: TXcomFont): Integer; static;
    procedure Add(AFont: TXcomFont; ACode: Cardinal; AX, AY, AColor, AMultiplier, AMiddle: Integer);
    function Count: Integer;
    /// <summary>The scale the characters were recorded for</summary>
    property Scale: Integer read FScale;
    property Layers: IXcomInkLayers read FLayers;
    /// <summary>
    ///   Paints the characters as ink. (AX, AY) is where the text is in the buffer and AWidth x AHeight its size,
    ///   in pixels of the game: as on the picture, nothing goes out of the rectangle of the text
    /// </summary>
    procedure PaintTo(var ABuffer: TXcomInkBuffer; AX, AY, AWidth, AHeight: Integer);
    /// <summary>
    ///   Draws the characters on a surface of indexes that is Scale times finer than the game (no alpha); (AX, AY)
    ///   is the corner of the text in the pixels of that surface
    /// </summary>
    procedure DrawTo(ATarget: TXcomSurface; AX, AY: Integer);
  end;

implementation

constructor TXcomTextInk.Create(const ADetail: IXcomFontDetail);
begin
  inherited Create;
  if not Assigned(ADetail) then
    raise EArgumentNilException.Create('ADetail');
  FRuns := TList<TRun>.Create;
  FScale := ADetail.Scale;
  FLayers := ADetail.Layers;
end;

destructor TXcomTextInk.Destroy;
begin
  FRuns.Free;
  inherited Destroy;
end;

class function TXcomTextInk.DetailOf(AFirst, ASecond: TXcomFont): IXcomFontDetail;
begin
  Result := nil;
  if Assigned(AFirst) and Assigned(AFirst.Detail) and (AFirst.Detail.Scale >= 2) then
    Result := AFirst.Detail
  else if Assigned(ASecond) and Assigned(ASecond.Detail) and (ASecond.Detail.Scale >= 2) then
    Result := ASecond.Detail;
end;

class function TXcomTextInk.ScaleOf(AFirst, ASecond: TXcomFont): Integer;
var
  LDetail: IXcomFontDetail;
begin
  Result := 0;
  // the common case first: fonts that only have their pictures
  if (Assigned(AFirst) and Assigned(AFirst.Detail)) or (Assigned(ASecond) and Assigned(ASecond.Detail)) then
  begin
    LDetail := DetailOf(AFirst, ASecond);
    if Assigned(LDetail) then
      Result := LDetail.Scale;
  end;
end;

procedure TXcomTextInk.Add(AFont: TXcomFont; ACode: Cardinal; AX, AY, AColor, AMultiplier, AMiddle: Integer);
var
  LRun: TRun;
begin
  LRun.Font := AFont;
  LRun.Code := ACode;
  LRun.X := AX;
  LRun.Y := AY;
  LRun.Color := TXcomInkColor.Make(AColor, AMultiplier, AMiddle);
  FRuns.Add(LRun);
end;

function TXcomTextInk.Count: Integer;
begin
  Result := FRuns.Count;
end;

procedure TXcomTextInk.PaintTo(var ABuffer: TXcomInkBuffer; AX, AY, AWidth, AHeight: Integer);
var
  LRun: TRun;
  LGlyph: TXcomDetailGlyph;
  LClip: TXcomRect;
begin
  if ABuffer.Scale <> FScale then
    Exit;
  LClip := TXcomRect.Make(AX * FScale, AY * FScale, AWidth * FScale, AHeight * FScale);
  for LRun in FRuns do
    if Assigned(LRun.Font.Detail) and (LRun.Font.Detail.Scale = FScale)
      and LRun.Font.Detail.TryGetGlyph(LRun.Code, LGlyph) then
      TXcomInkPainter.PaintGlyph(ABuffer, LGlyph, (AX + LRun.X) * FScale, (AY + LRun.Y) * FScale, LRun.Color, LClip)
    else
      TXcomInkPainter.PaintEnlarged(ABuffer, LRun.Font.GetChar(LRun.Code), (AX + LRun.X) * FScale,
        (AY + LRun.Y) * FScale, LRun.Color, LClip);
end;

procedure TXcomTextInk.DrawTo(ATarget: TXcomSurface; AX, AY: Integer);
var
  LRun: TRun;
  LGlyph: TXcomDetailGlyph;
begin
  for LRun in FRuns do
    if Assigned(LRun.Font.Detail) and (LRun.Font.Detail.Scale = FScale)
      and LRun.Font.Detail.TryGetGlyph(LRun.Code, LGlyph) then
      TXcomInkPainter.DrawGlyph(ATarget, LGlyph, AX + LRun.X * FScale, AY + LRun.Y * FScale, LRun.Color)
    else
      TXcomInkPainter.DrawEnlarged(ATarget, LRun.Font.GetChar(LRun.Code), AX + LRun.X * FScale,
        AY + LRun.Y * FScale, FScale, LRun.Color);
end;

end.
