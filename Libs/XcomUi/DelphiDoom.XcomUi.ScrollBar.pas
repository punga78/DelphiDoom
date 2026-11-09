{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - ScrollBar of OpenXcom                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.ScrollBar;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Types,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Math, DelphiDoom.XcomUi.ScrollableList;

type
  /// <summary>
  ///   The scroll bar of a list: a track (the background of the list darkened or lightened) and a thumb that is
  ///   dragged with the mouse. It owns two surfaces that follow its position and size
  /// </summary>
  TXcomScrollBar = class(TXcomInteractiveSurface)
  strict private
    FList: IXcomScrollableList;
    FColor: Byte;
    FPressed: Boolean;
    FContrast: Boolean;
    FTrack: TXcomSurface;
    FThumb: TXcomSurface;
    FThumbRect: TXcomRect;
    FOffset: Integer;
    FBackground: TXcomSurface;
    procedure DrawTrack;
    procedure DrawThumb;
  protected
    procedure SetX(AValue: Integer); override;
    procedure SetY(AValue: Integer); override;
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    procedure SetHeight(AHeight: Integer); override;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetHighContrast(AContrast: Boolean); override;
    /// <summary>The list this bar scrolls (not owned)</summary>
    procedure SetTextList(const AList: IXcomScrollableList);
    /// <summary>The picture the track is made of (not owned)</summary>
    procedure SetBackground(ABackground: TXcomSurface);
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Blit(ATarget: TXcomSurface); override;
    procedure Handle(AAction: TXcomAction); override;
    procedure Draw; override;
    property ThumbRect: TXcomRect read FThumbRect;
  end;

implementation

constructor TXcomScrollBar.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FTrack := TXcomSurface.Create(AWidth - 2, AHeight, AX + 1, AY);
  FThumb := TXcomSurface.Create(AWidth, AHeight, AX, AY);
end;

destructor TXcomScrollBar.Destroy;
begin
  FThumb.Free;
  FTrack.Free;
  inherited Destroy;
end;

procedure TXcomScrollBar.SetX(AValue: Integer);
begin
  inherited SetX(AValue);
  FTrack.X := AValue + 1;
  FThumb.X := AValue;
end;

procedure TXcomScrollBar.SetY(AValue: Integer);
begin
  inherited SetY(AValue);
  FTrack.Y := AValue;
  FThumb.Y := AValue;
end;

procedure TXcomScrollBar.SetHeight(AHeight: Integer);
begin
  inherited SetHeight(AHeight);
  FTrack.SetHeight(AHeight);
  FThumb.SetHeight(AHeight);
  Redraw := True;
end;

procedure TXcomScrollBar.SetColor(AColor: Byte);
begin
  FColor := AColor;
end;

function TXcomScrollBar.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomScrollBar.SetHighContrast(AContrast: Boolean);
begin
  FContrast := AContrast;
end;

procedure TXcomScrollBar.SetTextList(const AList: IXcomScrollableList);
begin
  FList := AList;
end;

procedure TXcomScrollBar.SetBackground(ABackground: TXcomSurface);
begin
  FBackground := ABackground;
end;

procedure TXcomScrollBar.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LColors: TArray<TXcomColor>;
begin
  inherited SetPalette(AColors, AFirst, ACount);
  if ACount <= 0 then
    Exit;
  SetLength(LColors, ACount);
  Move(AColors^, LColors[0], ACount * SizeOf(TXcomColor));
  FTrack.SetColors(LColors, AFirst);
  FThumb.SetColors(LColors, AFirst);
end;

procedure TXcomScrollBar.Handle(AAction: TXcomAction);
var
  LCursorY: Integer;
  LY: Integer;
  LScale: Double;
begin
  inherited Handle(AAction);
  if FPressed and Assigned(FList) and
    ((AAction.Details^.Kind = ekMouseMotion) or (AAction.Details^.Kind = ekMouseDown)) then
  begin
    LCursorY := Trunc(AAction.AbsoluteYMouse - Y);
    LY := TXcomMath.Clamp(LCursorY + FOffset, 0, Height - FThumbRect.H + 1);
    LScale := FList.GetRows / Height;
    FList.ScrollTo(TXcomMath.RoundToInt(LY * LScale));
  end;
end;

procedure TXcomScrollBar.Blit(ATarget: TXcomSurface);
begin
  inherited Blit(ATarget);
  if Visible and not Hidden then
  begin
    FTrack.Blit(ATarget);
    FThumb.Blit(ATarget);
    Invalidate;
  end;
end;

procedure TXcomScrollBar.MousePress(AAction: TXcomAction);
var
  LCursorY: Integer;
begin
  inherited MousePress(AAction);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    LCursorY := Trunc(AAction.AbsoluteYMouse - Y);
    if (LCursorY >= FThumbRect.Y) and (LCursorY < FThumbRect.Y + FThumbRect.H) then
      FOffset := FThumbRect.Y - LCursorY
    else
      FOffset := -FThumbRect.H div 2;
    FPressed := True;
  end
  else if Assigned(FList) and (AAction.Details^.Button = XCOM_BUTTON_WHEELUP) then
    FList.ScrollUp(False, True)
  else if Assigned(FList) and (AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN) then
    FList.ScrollDown(False, True);
end;

procedure TXcomScrollBar.MouseRelease(AAction: TXcomAction);
begin
  inherited MouseRelease(AAction);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FPressed := False;
    FOffset := 0;
  end;
end;

procedure TXcomScrollBar.Draw;
begin
  inherited Draw;
  DrawTrack;
  DrawThumb;
end;

procedure TXcomScrollBar.DrawTrack;
begin
  if Assigned(FBackground) then
  begin
    FTrack.Copy(FBackground);
    if Assigned(FList) and FList.HasComboBox then
      FTrack.Offset(1, XCOM_BACKPOS)
    else
      FTrack.OffsetBlock(-5);
  end;
end;

procedure TXcomScrollBar.DrawThumb;
var
  LScale: Double;
  LX: Integer;
  LY: Integer;
  LW: Integer;
  LH: Integer;
  LRows: Integer;
begin
  LRows := 0;
  if Assigned(FList) then
    LRows := FList.GetRows;
  if LRows > 0 then
    LScale := Height / LRows
  else
    LScale := 0.0;
  LX := 0;
  LY := 0;
  if Assigned(FList) then
    LY := Floor(FList.GetScroll * LScale);
  LW := FThumb.Width;
  LH := 0;
  if Assigned(FList) then
    LH := Ceil(FList.GetVisibleRows * LScale);
  FThumbRect := TXcomRect.Make(LX, LY, LW, LH);
  FThumb.Clear;
  // the rectangle is drawn with its width and height one less, then shrinking
  LW := LW - 1;
  LH := LH - 1;
  FThumb.DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(FColor + 2));
  Inc(LX);
  Inc(LY);
  FThumb.DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(FColor + 5));
  Dec(LW);
  Dec(LH);
  FThumb.DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(FColor + 4));
  FThumb.SetPixel(FThumbRect.X, FThumbRect.Y, Byte(FColor + 1));
  FThumb.SetPixel(FThumbRect.X, FThumbRect.Y + FThumbRect.H - 1, Byte(FColor + 4));
  FThumb.SetPixel(FThumbRect.X + FThumbRect.W - 1, FThumbRect.Y, Byte(FColor + 4));
  // hollow it out
  if LH - 4 > 0 then
  begin
    Inc(LX);
    Inc(LY);
    LW := LW - 3;
    LH := LH - 3;
    FThumb.DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(FColor + 5));
    Inc(LX);
    Inc(LY);
    FThumb.DrawRect(TXcomRect.Make(LX, LY, LW, LH), Byte(FColor + 2));
    Dec(LW);
    Dec(LH);
    FThumb.DrawRect(TXcomRect.Make(LX, LY, LW, LH), 0);
    FThumb.SetPixel(FThumbRect.X + 2 + FThumbRect.W - 1 - 4, FThumbRect.Y + 2 + FThumbRect.H - 1 - 4,
      Byte(FColor + 1));
    FThumb.SetPixel(FThumbRect.X + 2, FThumbRect.Y + 2 + FThumbRect.H - 1 - 4, Byte(FColor + 4));
    FThumb.SetPixel(FThumbRect.X + 2 + FThumbRect.W - 1 - 4, FThumbRect.Y + 2, Byte(FColor + 4));
  end;
end;

end.
