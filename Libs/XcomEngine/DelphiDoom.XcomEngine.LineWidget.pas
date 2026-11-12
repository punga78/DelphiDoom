{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - a surface of lines that are also drawn     }
{  at the resolution of the window when the screen composes in true color       }
{  (issue 183)                                                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.LineWidget;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.TrueColor.Intf;

type
  /// <summary>
  ///   A surface on which a state draws lines (the lines of the graphs). On the game picture the lines are the
  ///   ones of SDL_gfx, pixel for pixel as before. The widget also remembers them: when it is blitted on a screen
  ///   that composes its frame in true color at a whole scale it leaves, as a detail layer, the same lines drawn
  ///   between the same points on a picture that many times larger, as wide as the lines of the game picture
  ///   look in the window. Without such a screen it is a plain surface
  /// </summary>
  TXcomLineWidget = class(TXcomWidget)
  strict private
    type
      TLine = record
        X1: Integer;
        Y1: Integer;
        X2: Integer;
        Y2: Integer;
        Color: Byte;
      end;
    var
      FHost: TXcomStateHost;
      FLines: TArray<TLine>;
      FLineCount: Integer;
      FDetail: TXcomSurface;
      FDetailScale: Integer;
      FDetailStale: Boolean;
      FLeft: Integer;
      FTop: Integer;
      FRight: Integer;
      FBottom: Integer;
    function LayersOf(ATarget: TXcomSurface): IXcomDetailLayers;
    function DetailPicture(AScale: Integer): TXcomSurface;
  public
    /// <param name="AHost">Whose screen says whether a finer drawing is wanted; not owned, nil: never</param>
    constructor Create(AHost: TXcomStateHost; AWidth, AHeight, AX, AY: Integer);
    destructor Destroy; override;
    /// <summary>lineColor of SDL_gfx on the surface, and the line is remembered for the finer drawing</summary>
    procedure Line(AX1, AY1, AX2, AY2: Integer; AColor: Byte);
    /// <summary>Clears the surface and forgets the lines</summary>
    procedure ClearLines;
    procedure Blit(ATarget: TXcomSurface); override;
    property LineCount: Integer read FLineCount;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Gfx, DelphiDoom.XcomSurface.Stroke, DelphiDoom.XcomEngine.Screen;

constructor TXcomLineWidget.Create(AHost: TXcomStateHost; AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FHost := AHost;
  FDetailStale := True;
end;

destructor TXcomLineWidget.Destroy;
begin
  FDetail.Free;
  inherited Destroy;
end;

procedure TXcomLineWidget.Line(AX1, AY1, AX2, AY2: Integer; AColor: Byte);
begin
  TXcomGfx.DrawLine(Self, AX1, AY1, AX2, AY2, AColor);
  if FLineCount = Length(FLines) then
    SetLength(FLines, FLineCount + 16);
  FLines[FLineCount].X1 := AX1;
  FLines[FLineCount].Y1 := AY1;
  FLines[FLineCount].X2 := AX2;
  FLines[FLineCount].Y2 := AY2;
  FLines[FLineCount].Color := AColor;
  Inc(FLineCount);
  FDetailStale := True;
end;

procedure TXcomLineWidget.ClearLines;
begin
  Clear;
  FLineCount := 0;
  FDetailStale := True;
end;

function TXcomLineWidget.LayersOf(ATarget: TXcomSurface): IXcomDetailLayers;
begin
  Result := nil;
  if (FLineCount = 0) or (not Visible) or Hidden or (not Assigned(FHost)) or (FHost.Screen = nil)
    or (ATarget <> FHost.Screen.GetSurface) then
    Exit;
  Result := FHost.Screen.DetailLayers;
  if Assigned(Result) and (Result.DetailScale < 2) then
    Result := nil;
end;

function TXcomLineWidget.DetailPicture(AScale: Integer): TXcomSurface;
var
  LIndex: Integer;
  LWidth: Integer;
begin
  if FDetailStale or (FDetailScale <> AScale) or (not Assigned(FDetail)) then
  begin
    // the rectangle of the surface the lines are in: the layer is no larger than it needs
    FLeft := Width;
    FTop := Height;
    FRight := -1;
    FBottom := -1;
    for LIndex := 0 to FLineCount - 1 do
    begin
      if FLines[LIndex].X1 < FLeft then
        FLeft := FLines[LIndex].X1;
      if FLines[LIndex].X2 < FLeft then
        FLeft := FLines[LIndex].X2;
      if FLines[LIndex].X1 > FRight then
        FRight := FLines[LIndex].X1;
      if FLines[LIndex].X2 > FRight then
        FRight := FLines[LIndex].X2;
      if FLines[LIndex].Y1 < FTop then
        FTop := FLines[LIndex].Y1;
      if FLines[LIndex].Y2 < FTop then
        FTop := FLines[LIndex].Y2;
      if FLines[LIndex].Y1 > FBottom then
        FBottom := FLines[LIndex].Y1;
      if FLines[LIndex].Y2 > FBottom then
        FBottom := FLines[LIndex].Y2;
    end;
    if FLeft < 0 then
      FLeft := 0;
    if FTop < 0 then
      FTop := 0;
    if FRight > Width - 1 then
      FRight := Width - 1;
    if FBottom > Height - 1 then
      FBottom := Height - 1;
    FreeAndNil(FDetail);
    FDetailScale := AScale;
    FDetailStale := False;
    if (FRight < FLeft) or (FBottom < FTop) then
      Exit(nil);
    FDetail := TXcomSurface.Create((FRight - FLeft + 1) * AScale, (FBottom - FTop + 1) * AScale);
    // as wide as a pixel of the game picture is in the window: the lines keep their weight beside the grid and
    // the text, the slanted ones lose their steps
    LWidth := AScale;
    for LIndex := 0 to FLineCount - 1 do
      TXcomStroke.ScaledLine(FDetail, FLines[LIndex].X1 - FLeft, FLines[LIndex].Y1 - FTop,
        FLines[LIndex].X2 - FLeft, FLines[LIndex].Y2 - FTop, AScale, LWidth, FLines[LIndex].Color);
  end;
  Result := FDetail;
end;

procedure TXcomLineWidget.Blit(ATarget: TXcomSurface);
var
  LLayers: IXcomDetailLayers;
  LDetail: TXcomSurface;
begin
  // nil unless the screen composes in true color at a whole scale: then nothing below is new
  LLayers := LayersOf(ATarget);
  LDetail := nil;
  if Assigned(LLayers) then
    LDetail := DetailPicture(LLayers.DetailScale);
  if not Assigned(LDetail) then
  begin
    inherited Blit(ATarget);
    Exit;
  end;
  LLayers.BeginLayer(ATarget, X + FLeft, Y + FTop, FRight - FLeft + 1, FBottom - FTop + 1);
  inherited Blit(ATarget);
  LLayers.EndLayer(ATarget, LDetail);
end;

end.
