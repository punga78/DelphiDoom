{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - TextList of OpenXcom                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.TextList;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.Xcom.Types,
  DelphiDoom.Xcom.Palette,
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Language,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.ScrollableList, DelphiDoom.XcomUi.ComboBoxLink, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.ArrowButton, DelphiDoom.XcomUi.ScrollBar;

type
  /// <summary>
  ///   A list of rows of cells of text with columns, an optional selector under the mouse, arrows beside the rows and
  ///   a scroll bar with two arrows. A wrapped cell takes more than one visual row. It owns its cells, arrows,
  ///   scroll bar and selector. As IXcomScrollableList it is not reference counted: the controls it owns point to it
  /// </summary>
  TXcomTextList = class(TXcomInteractiveSurface, IXcomScrollableList)
  strict private
    FTexts: TObjectList<TObjectList<TXcomText>>;
    FColumns: TList<Integer>;
    /// <summary>For every visual row, the index of the row of cells it belongs to</summary>
    FRows: TList<Integer>;
    FBig: TXcomFont;
    FSmall: TXcomFont;
    FFont: TXcomFont;
    FLang: TXcomLanguage;
    FScroll: Integer;
    FVisibleRows: Integer;
    FSelRow: Integer;
    FColor: Byte;
    FColor2: Byte;
    FAlign: TDictionary<Integer, TXcomTextHAlign>;
    FDot: Boolean;
    FSelectable: Boolean;
    FCondensed: Boolean;
    FContrast: Boolean;
    FWrap: Boolean;
    FFlooding: Boolean;
    FBackground: TXcomSurface;
    FSelector: TXcomSurface;
    FUp: TXcomArrowButton;
    FDown: TXcomArrowButton;
    FScrollBar: TXcomScrollBar;
    FMargin: Integer;
    FScrolling: Boolean;
    FArrowLeft: TObjectList<TXcomArrowButton>;
    FArrowRight: TObjectList<TXcomArrowButton>;
    FArrowPos: Integer;
    FScrollPos: Integer;
    FArrowType: TXcomArrowOrientation;
    FLeftClick: TXcomActionHandler;
    FLeftPress: TXcomActionHandler;
    FLeftRelease: TXcomActionHandler;
    FRightClick: TXcomActionHandler;
    FRightPress: TXcomActionHandler;
    FRightRelease: TXcomActionHandler;
    FArrowsLeftEdge: Integer;
    FArrowsRightEdge: Integer;
    FComboBox: IXcomComboBoxLink;
    FOptions: TXcomOptions;
    FClock: IXcomClock;
    procedure UpdateArrows;
    procedure UpdateVisible;
    procedure NewSelector(AHeight, AY: Integer);
    procedure ApplyPalette(ATarget: TXcomSurface);
    function AlignOf(AColumn: Integer): TXcomTextHAlign;
    function RowHeightOf(AIndex: Integer): Integer;
    function FirstVisibleY(ABase: Integer): Integer;
  protected
    procedure SetX(AValue: Integer); override;
    procedure SetY(AValue: Integer); override;
    procedure MousePress(AAction: TXcomAction); override;
    procedure MouseRelease(AAction: TXcomAction); override;
    procedure MouseClick(AAction: TXcomAction); override;
    procedure MouseOver(AAction: TXcomAction); override;
    procedure MouseOut(AAction: TXcomAction); override;
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(AOptions: TXcomOptions; const AClock: IXcomClock; AWidth, AHeight: Integer; AX: Integer = 0;
      AY: Integer = 0);
    destructor Destroy; override;
    function GetArrowsLeftEdge: Integer;
    function GetArrowsRightEdge: Integer;
    procedure Unpress; override;
    procedure SetCellColor(ARow, AColumn: Integer; AColor: Byte);
    procedure SetRowColor(ARow: Integer; AColor: Byte);
    function GetCellText(ARow, AColumn: Integer): string;
    procedure SetCellText(ARow, AColumn: Integer; const AText: string);
    function GetColumnX(AColumn: Integer): Integer;
    function GetRowY(ARow: Integer): Integer;
    function GetTextHeight(ARow: Integer): Integer;
    function GetNumTextLines(ARow: Integer): Integer;
    /// <summary>TextList::getTexts: the number of rows of cells</summary>
    function GetTexts: Integer;
    /// <summary>TextList::getRows: the number of visual rows (a wrapped cell counts more than once)</summary>
    function GetRows: Integer;
    function GetVisibleRows: Integer;
    /// <summary>addRow(cols, ...): the cells of the row; an empty array adds one empty cell</summary>
    procedure AddRow(const ACells: array of string);
    /// <summary>setColumns(cols, ...): appends the widths of the columns</summary>
    procedure SetColumns(const AWidths: array of Integer);
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage); override;
    procedure SetHeight(AHeight: Integer); override;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetSecondaryColor(AColor: Byte); override;
    function GetSecondaryColor: Byte;
    procedure SetWordWrap(AWrap: Boolean);
    procedure SetHighContrast(AContrast: Boolean); override;
    /// <summary>AColumn -1 sets every column</summary>
    procedure SetAlign(AAlign: TXcomTextHAlign; AColumn: Integer = -1);
    procedure SetDot(ADot: Boolean);
    procedure SetSelectable(ASelectable: Boolean);
    procedure SetBig;
    procedure SetSmall;
    procedure SetCondensed(ACondensed: Boolean);
    /// <summary>The picture the selector and the scroll bar track are made of (not owned)</summary>
    procedure SetBackground(ABackground: TXcomSurface);
    /// <summary>The visual row of the selected row of cells, -1 if there is none</summary>
    function GetSelectedRow: Integer;
    procedure SetMargin(AMargin: Integer);
    function GetMargin: Integer;
    procedure SetArrowColor(AColor: Byte);
    procedure SetArrowColumn(APos: Integer; AType: TXcomArrowOrientation);
    procedure OnLeftArrowClick(const AHandler: TXcomActionHandler);
    procedure OnLeftArrowPress(const AHandler: TXcomActionHandler);
    procedure OnLeftArrowRelease(const AHandler: TXcomActionHandler);
    procedure OnRightArrowClick(const AHandler: TXcomActionHandler);
    procedure OnRightArrowPress(const AHandler: TXcomActionHandler);
    procedure OnRightArrowRelease(const AHandler: TXcomActionHandler);
    procedure ClearList;
    procedure ScrollUp(AToMax: Boolean; AByWheel: Boolean = False);
    procedure ScrollDown(AToMax: Boolean; AByWheel: Boolean = False);
    procedure SetScrolling(AScrolling: Boolean; AScrollPos: Integer = 4);
    procedure Draw; override;
    procedure Blit(ATarget: TXcomSurface); override;
    procedure Think; override;
    procedure Handle(AAction: TXcomAction); override;
    function GetScroll: Integer;
    procedure ScrollTo(AScroll: Integer);
    procedure SetComboBox(const AComboBox: IXcomComboBoxLink);
    function HasComboBox: Boolean;
    procedure SetBorderColor(AColor: Byte); override;
    function GetScrollbarColor: Byte;
    procedure SetFlooding(AFlooding: Boolean);
  end;

implementation

constructor TXcomTextList.Create(AOptions: TXcomOptions; const AClock: IXcomClock; AWidth, AHeight, AX, AY: Integer);
var
  LHeight: Integer;
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FOptions := AOptions;
  FClock := AClock;
  FTexts := TObjectList<TObjectList<TXcomText>>.Create(True);
  FColumns := TList<Integer>.Create;
  FRows := TList<Integer>.Create;
  FAlign := TDictionary<Integer, TXcomTextHAlign>.Create;
  FArrowLeft := TObjectList<TXcomArrowButton>.Create(True);
  FArrowRight := TObjectList<TXcomArrowButton>.Create(True);
  FScrolling := True;
  FArrowPos := -1;
  FScrollPos := 4;
  FArrowType := aoVertical;
  FUp := TXcomArrowButton.Create(FClock, arBigUp, 13, 14, X + Width + FScrollPos, Y);
  FUp.Visible := False;
  FUp.SetTextList(Self);
  FDown := TXcomArrowButton.Create(FClock, arBigDown, 13, 14, X + Width + FScrollPos, Y + Height - 14);
  FDown.Visible := False;
  FDown.SetTextList(Self);
  LHeight := Max(FDown.Y - FUp.Y - FUp.Height, 1);
  FScrollBar := TXcomScrollBar.Create(FUp.Width, LHeight, X + Width + FScrollPos, FUp.Y + FUp.Height);
  FScrollBar.Visible := False;
  FScrollBar.SetTextList(Self);
end;

destructor TXcomTextList.Destroy;
begin
  // the controls point to the list: they go first
  FScrollBar.Free;
  FDown.Free;
  FUp.Free;
  FSelector.Free;
  FArrowRight.Free;
  FArrowLeft.Free;
  FTexts.Free;
  FAlign.Free;
  FRows.Free;
  FColumns.Free;
  inherited Destroy;
end;

function TXcomTextList.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TXcomTextList._AddRef: Integer;
begin
  Result := -1;
end;

function TXcomTextList._Release: Integer;
begin
  Result := -1;
end;

procedure TXcomTextList.SetX(AValue: Integer);
begin
  inherited SetX(AValue);
  FUp.X := X + Width + FScrollPos;
  FDown.X := X + Width + FScrollPos;
  FScrollBar.X := X + Width + FScrollPos;
  if Assigned(FSelector) then
    FSelector.X := X;
end;

procedure TXcomTextList.SetY(AValue: Integer);
begin
  inherited SetY(AValue);
  FUp.Y := Y;
  FDown.Y := Y + Height - 14;
  FScrollBar.Y := FUp.Y + FUp.Height;
  if Assigned(FSelector) then
    FSelector.Y := Y;
end;

function TXcomTextList.GetArrowsLeftEdge: Integer;
begin
  Result := FArrowsLeftEdge;
end;

function TXcomTextList.GetArrowsRightEdge: Integer;
begin
  Result := FArrowsRightEdge;
end;

procedure TXcomTextList.Unpress;
var
  LArrow: TXcomArrowButton;
begin
  inherited Unpress;
  for LArrow in FArrowLeft do
    LArrow.Unpress;
  for LArrow in FArrowRight do
    LArrow.Unpress;
end;

procedure TXcomTextList.SetCellColor(ARow, AColumn: Integer; AColor: Byte);
begin
  FTexts[ARow][AColumn].SetColor(AColor);
  Redraw := True;
end;

procedure TXcomTextList.SetRowColor(ARow: Integer; AColor: Byte);
var
  LText: TXcomText;
begin
  for LText in FTexts[ARow] do
    LText.SetColor(AColor);
  Redraw := True;
end;

function TXcomTextList.GetCellText(ARow, AColumn: Integer): string;
begin
  Result := FTexts[ARow][AColumn].GetText;
end;

procedure TXcomTextList.SetCellText(ARow, AColumn: Integer; const AText: string);
begin
  FTexts[ARow][AColumn].SetText(AText);
  Redraw := True;
end;

function TXcomTextList.GetColumnX(AColumn: Integer): Integer;
begin
  Result := X + FTexts[0][AColumn].X;
end;

function TXcomTextList.GetRowY(ARow: Integer): Integer;
begin
  Result := Y + FTexts[ARow][0].Y;
end;

function TXcomTextList.GetTextHeight(ARow: Integer): Integer;
begin
  Result := FTexts[ARow].First.GetTextHeight;
end;

function TXcomTextList.GetNumTextLines(ARow: Integer): Integer;
begin
  Result := FTexts[ARow].First.GetNumLines;
end;

function TXcomTextList.GetTexts: Integer;
begin
  Result := FTexts.Count;
end;

function TXcomTextList.GetRows: Integer;
begin
  Result := FRows.Count;
end;

function TXcomTextList.GetVisibleRows: Integer;
begin
  Result := FVisibleRows;
end;

function TXcomTextList.AlignOf(AColumn: Integer): TXcomTextHAlign;
begin
  if not FAlign.TryGetValue(AColumn, Result) then
    Result := haLeft;
end;

procedure TXcomTextList.ApplyPalette(ATarget: TXcomSurface);
var
  LPalette: TXcomPalette;
begin
  LPalette := Palette;
  ATarget.SetColors(LPalette.Colors, 0);
end;

procedure TXcomTextList.AddRow(const ACells: array of string);
var
  LCols: Integer;
  LColumnCount: Integer;
  LCells: TObjectList<TXcomText>;
  LRowX: Integer;
  LRowY: Integer;
  LRows: Integer;
  LRowHeight: Integer;
  LIndex: Integer;
  LWidth: Integer;
  LText: TXcomText;
  LMargin: Integer;
  LBuffer: string;
  LTextWidth: Integer;
  LDotWidth: Integer;
  LShape1: TXcomArrowShape;
  LShape2: TXcomArrowShape;
  LArrow: TXcomArrowButton;
  LPalette: TXcomPalette;
begin
  LCols := Length(ACells);
  if LCols > 0 then
    LColumnCount := LCols
  else
    LColumnCount := 1;
  LCells := TObjectList<TXcomText>.Create(True);
  LRowX := 0;
  LRowY := 0;
  LRows := 1;
  LRowHeight := 0;
  if FTexts.Count > 0 then
    LRowY := FTexts.Last.First.Y + FTexts.Last.First.Height + FFont.Spacing;
  LPalette := Palette;
  for LIndex := 0 to LColumnCount - 1 do
  begin
    if FFlooding then
      LWidth := 340
    else
      LWidth := FColumns[LIndex];
    LText := TXcomText.Create(LWidth, FFont.Height, FMargin + LRowX, LRowY);
    LText.SetPalette(@LPalette.Colors[0], 0, 256);
    LText.InitText(FBig, FSmall, FLang);
    LText.SetColor(FColor);
    LText.SetSecondaryColor(FColor2);
    if AlignOf(LIndex) <> haLeft then
      LText.SetAlign(AlignOf(LIndex));
    LText.SetHighContrast(FContrast);
    if FFont = FBig then
      LText.SetBig
    else
      LText.SetSmall;
    if LCols > 0 then
      LText.SetText(ACells[LIndex]);
    // taken before the word wrap, to use it for the height of the row
    LMargin := FFont.Height - LText.GetTextHeight;
    if FWrap and (LText.GetTextWidth > LText.Width) then
    begin
      LText.SetWordWrap(True, True);
      LRows := Max(LRows, LText.GetNumLines);
    end;
    LRowHeight := Max(LRowHeight, LText.GetTextHeight + LMargin);
    // dots between the texts
    if FDot and (LIndex < LCols - 1) then
    begin
      LBuffer := LText.GetText;
      LTextWidth := LText.GetTextWidth;
      LDotWidth := FFont.GetChar(Ord('.')).Crop.W + FFont.Spacing;
      while LTextWidth < FColumns[LIndex] do
      begin
        if AlignOf(LIndex) <> haRight then
        begin
          Inc(LTextWidth, LDotWidth);
          LBuffer := LBuffer + '.';
        end;
        if AlignOf(LIndex) <> haLeft then
        begin
          Inc(LTextWidth, LDotWidth);
          LBuffer := '.' + LBuffer;
        end;
      end;
      LText.SetText(LBuffer);
    end;
    LCells.Add(LText);
    if FCondensed then
      Inc(LRowX, LText.GetTextWidth)
    else
      Inc(LRowX, FColumns[LIndex]);
  end;
  // every cell of the row has the same height
  for LIndex := 0 to LCols - 1 do
    LCells[LIndex].SetHeight(LRowHeight);
  FTexts.Add(LCells);
  for LIndex := 0 to LRows - 1 do
    FRows.Add(FTexts.Count - 1);
  // arrows: the position is relative to the main window, not to the list
  if FArrowPos <> -1 then
  begin
    if FArrowType = aoVertical then
    begin
      LShape1 := arSmallUp;
      LShape2 := arSmallDown;
    end
    else
    begin
      LShape1 := arSmallLeft;
      LShape2 := arSmallRight;
    end;
    LArrow := TXcomArrowButton.Create(FClock, LShape1, 11, 8, X + FArrowPos, Y);
    LArrow.SetListButton;
    LArrow.SetPalette(@LPalette.Colors[0], 0, 256);
    LArrow.SetColor(FUp.GetColor);
    LArrow.OnMouseClick(FLeftClick, 0);
    LArrow.OnMousePress(FLeftPress);
    LArrow.OnMouseRelease(FLeftRelease);
    FArrowLeft.Add(LArrow);
    LArrow := TXcomArrowButton.Create(FClock, LShape2, 11, 8, X + FArrowPos + 12, Y);
    LArrow.SetListButton;
    LArrow.SetPalette(@LPalette.Colors[0], 0, 256);
    LArrow.SetColor(FUp.GetColor);
    LArrow.OnMouseClick(FRightClick, 0);
    LArrow.OnMousePress(FRightPress);
    LArrow.OnMouseRelease(FRightRelease);
    FArrowRight.Add(LArrow);
  end;
  Redraw := True;
  UpdateArrows;
end;

procedure TXcomTextList.SetColumns(const AWidths: array of Integer);
var
  LWidth: Integer;
begin
  for LWidth in AWidths do
    FColumns.Add(LWidth);
end;

procedure TXcomTextList.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LRow: TObjectList<TXcomText>;
  LText: TXcomText;
  LArrow: TXcomArrowButton;
  LColors: TArray<TXcomColor>;
begin
  inherited SetPalette(AColors, AFirst, ACount);
  for LRow in FTexts do
    for LText in LRow do
      LText.SetPalette(AColors, AFirst, ACount);
  for LArrow in FArrowLeft do
    LArrow.SetPalette(AColors, AFirst, ACount);
  for LArrow in FArrowRight do
    LArrow.SetPalette(AColors, AFirst, ACount);
  if Assigned(FSelector) and (ACount > 0) then
  begin
    SetLength(LColors, ACount);
    Move(AColors^, LColors[0], ACount * SizeOf(TXcomColor));
    FSelector.SetColors(LColors, AFirst);
  end;
  FUp.SetPalette(AColors, AFirst, ACount);
  FDown.SetPalette(AColors, AFirst, ACount);
  FScrollBar.SetPalette(AColors, AFirst, ACount);
end;

procedure TXcomTextList.NewSelector(AHeight, AY: Integer);
begin
  FSelector.Free;
  FSelector := TXcomSurface.Create(Width, AHeight, X, AY);
  ApplyPalette(FSelector);
  FSelector.Visible := False;
end;

procedure TXcomTextList.InitText(ABig, ASmall: TXcomFont; ALanguage: TXcomLanguage);
begin
  FBig := ABig;
  FSmall := ASmall;
  FFont := ASmall;
  FLang := ALanguage;
  NewSelector(FFont.Height + FFont.Spacing, Y);
  UpdateVisible;
end;

procedure TXcomTextList.SetHeight(AHeight: Integer);
var
  LHeight: Integer;
begin
  inherited SetHeight(AHeight);
  SetY(Y);
  LHeight := Max(FDown.Y - FUp.Y - FUp.Height, 1);
  FScrollBar.SetHeight(LHeight);
  UpdateVisible;
end;

procedure TXcomTextList.SetColor(AColor: Byte);
var
  LRow: TObjectList<TXcomText>;
  LText: TXcomText;
begin
  FColor := AColor;
  FUp.SetColor(AColor);
  FDown.SetColor(AColor);
  FScrollBar.SetColor(AColor);
  for LRow in FTexts do
    for LText in LRow do
      LText.SetColor(AColor);
end;

function TXcomTextList.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomTextList.SetSecondaryColor(AColor: Byte);
begin
  FColor2 := AColor;
end;

function TXcomTextList.GetSecondaryColor: Byte;
begin
  Result := FColor2;
end;

procedure TXcomTextList.SetWordWrap(AWrap: Boolean);
begin
  FWrap := AWrap;
end;

procedure TXcomTextList.SetHighContrast(AContrast: Boolean);
var
  LRow: TObjectList<TXcomText>;
  LText: TXcomText;
begin
  FContrast := AContrast;
  for LRow in FTexts do
    for LText in LRow do
      LText.SetHighContrast(AContrast);
  FScrollBar.SetHighContrast(AContrast);
end;

procedure TXcomTextList.SetAlign(AAlign: TXcomTextHAlign; AColumn: Integer);
var
  LIndex: Integer;
begin
  if AColumn = -1 then
  begin
    for LIndex := 0 to FColumns.Count - 1 do
      FAlign.AddOrSetValue(LIndex, AAlign);
  end
  else
    FAlign.AddOrSetValue(AColumn, AAlign);
end;

procedure TXcomTextList.SetDot(ADot: Boolean);
begin
  FDot := ADot;
end;

procedure TXcomTextList.SetSelectable(ASelectable: Boolean);
begin
  FSelectable := ASelectable;
end;

procedure TXcomTextList.SetBig;
begin
  FFont := FBig;
  NewSelector(FFont.Height + FFont.Spacing, Y);
  UpdateVisible;
end;

procedure TXcomTextList.SetSmall;
begin
  FFont := FSmall;
  NewSelector(FFont.Height + FFont.Spacing, Y);
  UpdateVisible;
end;

procedure TXcomTextList.SetCondensed(ACondensed: Boolean);
begin
  FCondensed := ACondensed;
end;

function TXcomTextList.GetSelectedRow: Integer;
begin
  if (FRows.Count = 0) or (FSelRow >= FRows.Count) then
    Result := -1
  else
    Result := FRows[FSelRow];
end;

procedure TXcomTextList.SetBackground(ABackground: TXcomSurface);
begin
  FBackground := ABackground;
  FScrollBar.SetBackground(FBackground);
end;

procedure TXcomTextList.SetMargin(AMargin: Integer);
begin
  FMargin := AMargin;
end;

function TXcomTextList.GetMargin: Integer;
begin
  Result := FMargin;
end;

procedure TXcomTextList.SetArrowColor(AColor: Byte);
begin
  FUp.SetColor(AColor);
  FDown.SetColor(AColor);
  FScrollBar.SetColor(AColor);
end;

procedure TXcomTextList.SetArrowColumn(APos: Integer; AType: TXcomArrowOrientation);
begin
  FArrowPos := APos;
  FArrowType := AType;
  FArrowsLeftEdge := X + FArrowPos;
  FArrowsRightEdge := FArrowsLeftEdge + 12 + 11;
end;

procedure TXcomTextList.OnLeftArrowClick(const AHandler: TXcomActionHandler);
var
  LArrow: TXcomArrowButton;
begin
  FLeftClick := AHandler;
  for LArrow in FArrowLeft do
    LArrow.OnMouseClick(AHandler, 0);
end;

procedure TXcomTextList.OnLeftArrowPress(const AHandler: TXcomActionHandler);
var
  LArrow: TXcomArrowButton;
begin
  FLeftPress := AHandler;
  for LArrow in FArrowLeft do
    LArrow.OnMousePress(AHandler);
end;

procedure TXcomTextList.OnLeftArrowRelease(const AHandler: TXcomActionHandler);
var
  LArrow: TXcomArrowButton;
begin
  FLeftRelease := AHandler;
  for LArrow in FArrowLeft do
    LArrow.OnMouseRelease(AHandler);
end;

procedure TXcomTextList.OnRightArrowClick(const AHandler: TXcomActionHandler);
var
  LArrow: TXcomArrowButton;
begin
  FRightClick := AHandler;
  for LArrow in FArrowRight do
    LArrow.OnMouseClick(AHandler, 0);
end;

procedure TXcomTextList.OnRightArrowPress(const AHandler: TXcomActionHandler);
var
  LArrow: TXcomArrowButton;
begin
  FRightPress := AHandler;
  for LArrow in FArrowRight do
    LArrow.OnMousePress(AHandler);
end;

procedure TXcomTextList.OnRightArrowRelease(const AHandler: TXcomActionHandler);
var
  LArrow: TXcomArrowButton;
begin
  FRightRelease := AHandler;
  for LArrow in FArrowRight do
    LArrow.OnMouseRelease(AHandler);
end;

procedure TXcomTextList.ClearList;
begin
  FTexts.Clear;
  ScrollUp(True, False);
  FRows.Clear;
  Redraw := True;
end;

procedure TXcomTextList.ScrollUp(AToMax: Boolean; AByWheel: Boolean);
begin
  if not FScrolling then
    Exit;
  if (FRows.Count > FVisibleRows) and (FScroll > 0) then
  begin
    if AToMax then
      ScrollTo(0)
    else if AByWheel then
      ScrollTo(FScroll - Min(FOptions.MousewheelSpeed, FScroll))
    else
      ScrollTo(FScroll - 1);
  end;
end;

procedure TXcomTextList.ScrollDown(AToMax: Boolean; AByWheel: Boolean);
begin
  if not FScrolling then
    Exit;
  if (FRows.Count > FVisibleRows) and (FScroll < FRows.Count - FVisibleRows) then
  begin
    if AToMax then
      ScrollTo(FRows.Count - FVisibleRows)
    else if AByWheel then
      ScrollTo(FScroll + FOptions.MousewheelSpeed)
    else
      ScrollTo(FScroll + 1);
  end;
end;

procedure TXcomTextList.UpdateArrows;
begin
  FUp.Visible := FRows.Count > FVisibleRows;
  FDown.Visible := FRows.Count > FVisibleRows;
  FScrollBar.Visible := FRows.Count > FVisibleRows;
  FScrollBar.Invalidate;
  FScrollBar.Blit(Self);
end;

procedure TXcomTextList.UpdateVisible;
var
  LY: Integer;
begin
  FVisibleRows := 0;
  LY := 0;
  while LY < Height do
  begin
    Inc(FVisibleRows);
    Inc(LY, FFont.Height + FFont.Spacing);
  end;
  UpdateArrows;
end;

procedure TXcomTextList.SetScrolling(AScrolling: Boolean; AScrollPos: Integer);
begin
  FScrolling := AScrolling;
  if AScrollPos <> FScrollPos then
  begin
    FScrollPos := AScrollPos;
    FUp.X := X + Width + FScrollPos;
    FDown.X := X + Width + FScrollPos;
    FScrollBar.X := X + Width + FScrollPos;
  end;
end;

function TXcomTextList.RowHeightOf(AIndex: Integer): Integer;
begin
  if FTexts[AIndex].Count > 0 then
    Result := FTexts[AIndex].First.Height + FFont.Spacing
  else
    Result := FFont.Height + FFont.Spacing;
end;

function TXcomTextList.FirstVisibleY(ABase: Integer): Integer;
var
  LRow: Integer;
begin
  // for the wrapped items the draw height starts above the visible surface, so that the right row is at the top
  Result := ABase;
  LRow := FScroll;
  while (LRow > 0) and (FRows[LRow] = FRows[LRow - 1]) do
  begin
    Dec(Result, FFont.Height + FFont.Spacing);
    Dec(LRow);
  end;
end;

procedure TXcomTextList.Draw;
var
  LY: Integer;
  LIndex: Integer;
  LText: TXcomText;
begin
  inherited Draw;
  if FRows.Count > 0 then
  begin
    LY := FirstVisibleY(0);
    LIndex := FRows[FScroll];
    while (LIndex < FTexts.Count) and (LIndex < FRows[FScroll] + FVisibleRows) do
    begin
      for LText in FTexts[LIndex] do
      begin
        LText.Y := LY;
        LText.Blit(Self);
      end;
      Inc(LY, RowHeightOf(LIndex));
      Inc(LIndex);
    end;
  end;
end;

procedure TXcomTextList.Blit(ATarget: TXcomSurface);
var
  LY: Integer;
  LMaxY: Integer;
  LIndex: Integer;
begin
  if Visible and not Hidden then
    FSelector.Blit(ATarget);
  inherited Blit(ATarget);
  if Visible and not Hidden then
  begin
    if (FArrowPos <> -1) and (FRows.Count > 0) then
    begin
      LY := FirstVisibleY(Y);
      LMaxY := Y + Height;
      LIndex := FRows[FScroll];
      while (LIndex < FTexts.Count) and (LIndex < FRows[FScroll] + FVisibleRows) and (LY < LMaxY) do
      begin
        FArrowLeft[LIndex].Y := LY;
        FArrowRight[LIndex].Y := LY;
        if LY >= Y then
        begin
          // only the arrows of the texts that have their first row on screen
          FArrowLeft[LIndex].Blit(ATarget);
          FArrowRight[LIndex].Blit(ATarget);
        end;
        Inc(LY, RowHeightOf(LIndex));
        Inc(LIndex);
      end;
    end;
    FUp.Blit(ATarget);
    FDown.Blit(ATarget);
    FScrollBar.Blit(ATarget);
  end;
end;

procedure TXcomTextList.Handle(AAction: TXcomAction);
var
  LStart: Integer;
  LEnd: Integer;
  LEndRow: Integer;
  LIndex: Integer;
begin
  inherited Handle(AAction);
  FUp.Handle(AAction);
  FDown.Handle(AAction);
  FScrollBar.Handle(AAction);
  if (FArrowPos <> -1) and (FRows.Count > 0) then
  begin
    LStart := FRows[FScroll];
    if (FScroll > 0) and (FRows[FScroll] = FRows[FScroll - 1]) then
      // the arrows of the first partly visible line are off screen: not processed
      Inc(LStart);
    LEnd := FRows[FScroll] + 1;
    LEndRow := Min(FRows.Count, FScroll + FVisibleRows);
    for LIndex := FScroll + 1 to LEndRow - 1 do
      if FRows[LIndex] <> FRows[LIndex - 1] then
        Inc(LEnd);
    for LIndex := LStart to LEnd - 1 do
    begin
      FArrowLeft[LIndex].Handle(AAction);
      FArrowRight[LIndex].Handle(AAction);
    end;
  end;
end;

procedure TXcomTextList.Think;
var
  LArrow: TXcomArrowButton;
begin
  inherited Think;
  FUp.Think;
  FDown.Think;
  FScrollBar.Think;
  for LArrow in FArrowLeft do
    LArrow.Think;
  for LArrow in FArrowRight do
    LArrow.Think;
end;

procedure TXcomTextList.MousePress(AAction: TXcomAction);
var
  LAllowScroll: Boolean;
begin
  LAllowScroll := True;
  if FOptions.ChangeValueByMouseWheel <> 0 then
    LAllowScroll := (AAction.AbsoluteXMouse < FArrowsLeftEdge) or (AAction.AbsoluteXMouse > FArrowsRightEdge);
  if LAllowScroll then
  begin
    if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
      ScrollUp(False, True)
    else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
      ScrollDown(False, True);
  end;
  if FSelectable then
  begin
    if FSelRow < FRows.Count then
      inherited MousePress(AAction);
  end
  else
    inherited MousePress(AAction);
end;

procedure TXcomTextList.MouseRelease(AAction: TXcomAction);
begin
  if FSelectable then
  begin
    if FSelRow < FRows.Count then
      inherited MouseRelease(AAction);
  end
  else
    inherited MouseRelease(AAction);
end;

procedure TXcomTextList.MouseClick(AAction: TXcomAction);
begin
  if FSelectable then
  begin
    if FSelRow < FRows.Count then
    begin
      inherited MouseClick(AAction);
      if Assigned(FComboBox) and (AAction.Details^.Button = XCOM_BUTTON_LEFT) then
      begin
        FComboBox.SetSelected(FSelRow);
        FComboBox.ToggleList;
      end;
    end;
  end
  else
    inherited MouseClick(AAction);
end;

procedure TXcomTextList.MouseOver(AAction: TXcomAction);
var
  LRowHeight: Integer;
  LText: TXcomText;
  LY: Integer;
  LActualHeight: Integer;
begin
  if FSelectable then
  begin
    LRowHeight := FFont.Height + FFont.Spacing;
    FSelRow := Max(0, FScroll + Floor(AAction.RelativeYMouse / (LRowHeight * AAction.YScale)));
    if FSelRow < FRows.Count then
    begin
      LText := FTexts[FRows[FSelRow]].First;
      LY := Y + LText.Y;
      LActualHeight := LText.Height + FFont.Spacing;
      if (LY < Y) or (LY + LActualHeight > Y + Height) then
        LActualHeight := LActualHeight div 2;
      if LY < Y then
        LY := Y;
      if FSelector.Height <> LActualHeight then
        NewSelector(LActualHeight, LY);
      FSelector.Y := LY;
      if Assigned(FBackground) then
        FSelector.Copy(FBackground);
      if FContrast then
        FSelector.OffsetBlock(-5)
      else if Assigned(FComboBox) then
        FSelector.Offset(1, XCOM_BACKPOS)
      else
        FSelector.OffsetBlock(-10);
      FSelector.Visible := True;
    end
    else
      FSelector.Visible := False;
  end;
  inherited MouseOver(AAction);
end;

procedure TXcomTextList.MouseOut(AAction: TXcomAction);
begin
  if FSelectable then
    FSelector.Visible := False;
  inherited MouseOut(AAction);
end;

function TXcomTextList.GetScroll: Integer;
begin
  Result := FScroll;
end;

procedure TXcomTextList.ScrollTo(AScroll: Integer);
begin
  if not FScrolling then
    Exit;
  if FRows.Count <= FVisibleRows then
    Exit;
  FScroll := Max(0, Min(AScroll, FRows.Count - FVisibleRows));
  // the C++ draws at once: setting the flag is not enough
  Draw;
  UpdateArrows;
end;

procedure TXcomTextList.SetComboBox(const AComboBox: IXcomComboBoxLink);
begin
  FComboBox := AComboBox;
end;

function TXcomTextList.HasComboBox: Boolean;
begin
  Result := Assigned(FComboBox);
end;

procedure TXcomTextList.SetBorderColor(AColor: Byte);
begin
  FUp.SetColor(AColor);
  FDown.SetColor(AColor);
  FScrollBar.SetColor(AColor);
end;

function TXcomTextList.GetScrollbarColor: Byte;
begin
  Result := FScrollBar.GetColor;
end;

procedure TXcomTextList.SetFlooding(AFlooding: Boolean);
begin
  FFlooding := AFlooding;
end;

end.
