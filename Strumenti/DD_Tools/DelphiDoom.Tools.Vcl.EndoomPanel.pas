{******************************************************************************}
{                                                                              }
{  DD_Tools: the panel of the endoom editor (tools, palettes and the picture)   }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Vcl.EndoomPanel;

interface

uses
  System.SysUtils, System.Classes, System.Types,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.Graphics, Vcl.Buttons,
  DelphiDoom.Endoom.Types,
  DelphiDoom.EndoomEditor.Types,
  DelphiDoom.EndoomEditor.Presenter;

type
  /// <summary>
  ///   The working area of the editor: the buttons of the tools, the palettes of the colors and of the special
  ///   characters on the left, and the picture of the screen, which it only draws (the zoom, the grid, the cursor and
  ///   the selection come from the presenter). What the user does with the mouse goes to the presenter as it is
  /// </summary>
  TEndoomEditorPanel = class(TPanel)
  strict private
    const
      TOOL_COLUMNS = 2;
      TOOL_BUTTON_WIDTH = 120;
      TOOL_BUTTON_HEIGHT = 24;
      SWATCH_SIZE = 24;
      SWATCH_COLUMNS = 8;
      GLYPH_CELL = 16;
      GLYPH_COLUMNS = 16;
      GLYPH_ROWS = 5;
  strict private
    FPresenter: TEndoomEditorPresenter;
    FFont: TBytes;
    FSidePanel: TPanel;
    FScrollBox: TScrollBox;
    FPicture: TPaintBox;
    FForegroundBox: TPaintBox;
    FBackgroundBox: TPaintBox;
    FCharactersBox: TPaintBox;
    FToolButtons: array[TEndoomEditorTool] of TSpeedButton;
    FPixels: TArray<Cardinal>;
    FOverlay: TEndoomEditorOverlay;
    FTool: TEndoomEditorTool;
    FForeground: Integer;
    FBackground: Integer;
    FSpecial1: Integer;
    FSpecial2: Integer;
    class function ColorOf(ARgb: Cardinal): TColor; static;
    procedure CreateTools;
    procedure CreatePalettes;
    procedure ToolClick(ASender: TObject);
    procedure PaintPicture(ASender: TObject);
    procedure PictureMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure PictureMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
    procedure PictureMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure PaintForeground(ASender: TObject);
    procedure PaintBackground(ASender: TObject);
    procedure PaintCharacters(ASender: TObject);
    procedure ForegroundMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure BackgroundMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure CharactersMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
    procedure SizePicture;
  public
    constructor Create(AOwner: TComponent); override;
    /// <summary>Gives the panel the presenter that it tells what the user does, and the font of the screen</summary>
    procedure Attach(const APresenter: TEndoomEditorPresenter; const AFont: TBytes);
    procedure ShowPicture(const APixels: TArray<Cardinal>; const AOverlay: TEndoomEditorOverlay);
    procedure ShowChoices(ATool: TEndoomEditorTool; AForeground, ABackground, ASpecial1, ASpecial2: Integer);
  end;

implementation

uses
  Winapi.Windows;

const
  TOOL_CAPTIONS: array[TEndoomEditorTool] of string = (
    'Free draw', 'Flood fill', 'Rectangle', 'Filled rect.', 'Line', 'Erase text', 'Text', 'Ellipse',
    'Filled ellipse', 'Char + colors', 'Character', 'Text color', 'Frame single', 'Frame dbl. horiz.',
    'Frame dbl. vert.', 'Frame double', 'Frame block', 'Blink on', 'Blink off', 'Select');

{ TEndoomEditorPanel }

constructor TEndoomEditorPanel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  Align := alClient;
  FForeground := 7;
  FSpecial1 := ENDOOM_EDITOR_FIRST_SPECIAL_CODE;
  FSpecial2 := ENDOOM_EDITOR_FIRST_SPECIAL_CODE;
  FSidePanel := TPanel.Create(Self);
  FSidePanel.Parent := Self;
  FSidePanel.Align := alLeft;
  FSidePanel.Width := TOOL_COLUMNS * TOOL_BUTTON_WIDTH + 12;
  FSidePanel.BevelOuter := bvNone;
  FSidePanel.Caption := '';
  FScrollBox := TScrollBox.Create(Self);
  FScrollBox.Parent := Self;
  FScrollBox.Align := alClient;
  FScrollBox.BorderStyle := bsSingle;
  FPicture := TPaintBox.Create(Self);
  FPicture.Parent := FScrollBox;
  FPicture.SetBounds(0, 0, ENDOOM_EDITOR_EXPORT_WIDTH, ENDOOM_EDITOR_EXPORT_HEIGHT);
  FPicture.OnPaint := PaintPicture;
  FPicture.OnMouseDown := PictureMouseDown;
  FPicture.OnMouseMove := PictureMouseMove;
  FPicture.OnMouseUp := PictureMouseUp;
  FPicture.Cursor := crCross;
  CreateTools;
  CreatePalettes;
end;

class function TEndoomEditorPanel.ColorOf(ARgb: Cardinal): TColor;
begin
  Result := TColor(((ARgb and $FF) shl 16) or (ARgb and $FF00) or ((ARgb shr 16) and $FF));
end;

procedure TEndoomEditorPanel.CreateTools;
var
  LTool: TEndoomEditorTool;
  LButton: TSpeedButton;
begin
  for LTool := Low(TEndoomEditorTool) to High(TEndoomEditorTool) do
  begin
    LButton := TSpeedButton.Create(Self);
    LButton.Parent := FSidePanel;
    LButton.GroupIndex := 1;
    LButton.AllowAllUp := False;
    LButton.Tag := Ord(LTool);
    LButton.Caption := TOOL_CAPTIONS[LTool];
    LButton.Hint := TOOL_CAPTIONS[LTool];
    LButton.ShowHint := True;
    LButton.SetBounds(4 + (Ord(LTool) mod TOOL_COLUMNS) * TOOL_BUTTON_WIDTH,
      4 + (Ord(LTool) div TOOL_COLUMNS) * TOOL_BUTTON_HEIGHT, TOOL_BUTTON_WIDTH, TOOL_BUTTON_HEIGHT);
    LButton.OnClick := ToolClick;
    FToolButtons[LTool] := LButton;
  end;
  FToolButtons[eetFreeDraw].Down := True;
end;

procedure TEndoomEditorPanel.CreatePalettes;
var
  LTop: Integer;
begin
  LTop := 4 + ((Ord(High(TEndoomEditorTool)) div TOOL_COLUMNS) + 1) * TOOL_BUTTON_HEIGHT + 12;
  FForegroundBox := TPaintBox.Create(Self);
  FForegroundBox.Parent := FSidePanel;
  FForegroundBox.SetBounds(4, LTop, SWATCH_COLUMNS * SWATCH_SIZE, 2 * SWATCH_SIZE);
  FForegroundBox.OnPaint := PaintForeground;
  FForegroundBox.OnMouseDown := ForegroundMouseDown;
  FForegroundBox.Hint := 'Foreground color';
  FForegroundBox.ShowHint := True;
  Inc(LTop, 2 * SWATCH_SIZE + 8);
  FBackgroundBox := TPaintBox.Create(Self);
  FBackgroundBox.Parent := FSidePanel;
  FBackgroundBox.SetBounds(4, LTop, SWATCH_COLUMNS * SWATCH_SIZE, SWATCH_SIZE);
  FBackgroundBox.OnPaint := PaintBackground;
  FBackgroundBox.OnMouseDown := BackgroundMouseDown;
  FBackgroundBox.Hint := 'Background color';
  FBackgroundBox.ShowHint := True;
  Inc(LTop, SWATCH_SIZE + 8);
  FCharactersBox := TPaintBox.Create(Self);
  FCharactersBox.Parent := FSidePanel;
  FCharactersBox.SetBounds(4, LTop, GLYPH_COLUMNS * GLYPH_CELL, GLYPH_ROWS * GLYPH_CELL);
  FCharactersBox.OnPaint := PaintCharacters;
  FCharactersBox.OnMouseDown := CharactersMouseDown;
  FCharactersBox.Hint := 'Left click: character with colors. Right click: character';
  FCharactersBox.ShowHint := True;
end;

procedure TEndoomEditorPanel.Attach(const APresenter: TEndoomEditorPresenter; const AFont: TBytes);
begin
  FPresenter := APresenter;
  FFont := AFont;
end;

procedure TEndoomEditorPanel.SizePicture;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  LWidth := ENDOOM_EDITOR_EXPORT_WIDTH + ENDOOM_COLUMNS * FOverlay.Zoom;
  LHeight := ENDOOM_EDITOR_EXPORT_HEIGHT + ENDOOM_ROWS * 2 * FOverlay.Zoom;
  if (FPicture.Width <> LWidth) or (FPicture.Height <> LHeight) then
    FPicture.SetBounds(0, 0, LWidth, LHeight);
end;

procedure TEndoomEditorPanel.ShowPicture(const APixels: TArray<Cardinal>; const AOverlay: TEndoomEditorOverlay);
begin
  FPixels := APixels;
  FOverlay := AOverlay;
  SizePicture;
  if AOverlay.CursorVisible then
    FPicture.Cursor := crIBeam
  else
    FPicture.Cursor := crCross;
  FPicture.Invalidate;
end;

procedure TEndoomEditorPanel.ShowChoices(ATool: TEndoomEditorTool; AForeground, ABackground, ASpecial1,
  ASpecial2: Integer);
begin
  FTool := ATool;
  FForeground := AForeground;
  FBackground := ABackground;
  FSpecial1 := ASpecial1;
  FSpecial2 := ASpecial2;
  FToolButtons[ATool].Down := True;
  FForegroundBox.Invalidate;
  FBackgroundBox.Invalidate;
  FCharactersBox.Invalidate;
end;

procedure TEndoomEditorPanel.ToolClick(ASender: TObject);
begin
  if Assigned(FPresenter) then
    FPresenter.SelectTool(TEndoomEditorTool((ASender as TSpeedButton).Tag));
end;

// ---------------------------------------------------------------------------------------------------------------
// the picture
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPanel.PaintPicture(ASender: TObject);
var
  LInfo: TBitmapInfo;
  LCanvas: TCanvas;
  LWidth: Integer;
  LHeight: Integer;
  LStepX: Integer;
  LStepY: Integer;
  LIndex: Integer;
  LRect: TRect;
begin
  LCanvas := FPicture.Canvas;
  LWidth := FPicture.Width;
  LHeight := FPicture.Height;
  if Length(FPixels) = ENDOOM_WIDTH * ENDOOM_HEIGHT then
  begin
    FillChar(LInfo, SizeOf(LInfo), 0);
    LInfo.bmiHeader.biSize := SizeOf(LInfo.bmiHeader);
    LInfo.bmiHeader.biWidth := ENDOOM_WIDTH;
    LInfo.bmiHeader.biHeight := -ENDOOM_HEIGHT;
    LInfo.bmiHeader.biPlanes := 1;
    LInfo.bmiHeader.biBitCount := 32;
    LInfo.bmiHeader.biCompression := BI_RGB;
    SetStretchBltMode(LCanvas.Handle, COLORONCOLOR);
    StretchDIBits(LCanvas.Handle, 0, 0, LWidth, LHeight, 0, 0, ENDOOM_WIDTH, ENDOOM_HEIGHT, @FPixels[0], LInfo,
      DIB_RGB_COLORS, SRCCOPY);
  end
  else
  begin
    LCanvas.Brush.Color := clBlack;
    LCanvas.FillRect(Rect(0, 0, LWidth, LHeight));
  end;
  LStepX := LWidth div ENDOOM_COLUMNS;
  LStepY := LHeight div ENDOOM_ROWS;
  if FOverlay.ShowGrid then
  begin
    LCanvas.Pen.Style := psSolid;
    LCanvas.Pen.Color := RGB(160, 160, 128);
    for LIndex := 1 to ENDOOM_COLUMNS - 1 do
    begin
      LCanvas.MoveTo(LIndex * LStepX - 1, 0);
      LCanvas.LineTo(LIndex * LStepX - 1, LHeight);
    end;
    for LIndex := 1 to ENDOOM_ROWS - 1 do
    begin
      LCanvas.MoveTo(0, LIndex * LStepY - 1);
      LCanvas.LineTo(LWidth, LIndex * LStepY - 1);
    end;
  end;
  if FOverlay.CursorVisible then
  begin
    LCanvas.Pen.Style := psSolid;
    if FOverlay.CursorInverted then
      LCanvas.Pen.Color := clWhite
    else
      LCanvas.Pen.Color := clBlack;
    LCanvas.Brush.Style := bsClear;
    LCanvas.Rectangle(FOverlay.CursorX * LStepX, FOverlay.CursorY * LStepY, (FOverlay.CursorX + 1) * LStepX - 1,
      (FOverlay.CursorY + 1) * LStepY - 1);
  end;
  if FOverlay.SelectionVisible then
  begin
    LRect := Rect(FOverlay.Selection.Left * LStepX, FOverlay.Selection.Top * LStepY,
      (FOverlay.Selection.Right + 1) * LStepX, (FOverlay.Selection.Bottom + 1) * LStepY);
    LCanvas.Pen.Style := psDash;
    LCanvas.Pen.Color := clYellow;
    LCanvas.Brush.Style := bsClear;
    LCanvas.Rectangle(LRect);
  end;
end;

procedure TEndoomEditorPanel.PictureMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState;
  AX, AY: Integer);
begin
  if (AButton = mbLeft) and Assigned(FPresenter) then
    FPresenter.MouseDown(AX, AY);
end;

procedure TEndoomEditorPanel.PictureMouseMove(ASender: TObject; AShift: TShiftState; AX, AY: Integer);
begin
  if Assigned(FPresenter) then
    FPresenter.MouseMove(AX, AY);
end;

procedure TEndoomEditorPanel.PictureMouseUp(ASender: TObject; AButton: TMouseButton; AShift: TShiftState;
  AX, AY: Integer);
begin
  if (AButton = mbLeft) and Assigned(FPresenter) then
    FPresenter.MouseUp(AX, AY);
end;

// ---------------------------------------------------------------------------------------------------------------
// the palettes
// ---------------------------------------------------------------------------------------------------------------

procedure TEndoomEditorPanel.PaintForeground(ASender: TObject);
var
  LColor: Integer;
  LRect: TRect;
  LCanvas: TCanvas;
begin
  LCanvas := FForegroundBox.Canvas;
  for LColor := 0 to ENDOOM_COLOR_COUNT - 1 do
  begin
    LRect := Rect((LColor mod SWATCH_COLUMNS) * SWATCH_SIZE, (LColor div SWATCH_COLUMNS) * SWATCH_SIZE,
      (LColor mod SWATCH_COLUMNS + 1) * SWATCH_SIZE, (LColor div SWATCH_COLUMNS + 1) * SWATCH_SIZE);
    LCanvas.Brush.Color := ColorOf(ENDOOM_COLORS[LColor]);
    LCanvas.FillRect(LRect);
    if LColor = FForeground then
    begin
      LCanvas.Brush.Style := bsClear;
      LCanvas.Pen.Color := clRed;
      LCanvas.Pen.Width := 2;
      LCanvas.Rectangle(LRect.Left + 1, LRect.Top + 1, LRect.Right - 1, LRect.Bottom - 1);
      LCanvas.Pen.Width := 1;
      LCanvas.Brush.Style := bsSolid;
    end;
  end;
end;

procedure TEndoomEditorPanel.PaintBackground(ASender: TObject);
var
  LColor: Integer;
  LRect: TRect;
  LCanvas: TCanvas;
begin
  LCanvas := FBackgroundBox.Canvas;
  for LColor := 0 to ENDOOM_BACKGROUND_COLOR_COUNT - 1 do
  begin
    LRect := Rect(LColor * SWATCH_SIZE, 0, (LColor + 1) * SWATCH_SIZE, SWATCH_SIZE);
    LCanvas.Brush.Color := ColorOf(ENDOOM_COLORS[LColor]);
    LCanvas.FillRect(LRect);
    if LColor = FBackground then
    begin
      LCanvas.Brush.Style := bsClear;
      LCanvas.Pen.Color := clRed;
      LCanvas.Pen.Width := 2;
      LCanvas.Rectangle(LRect.Left + 1, LRect.Top + 1, LRect.Right - 1, LRect.Bottom - 1);
      LCanvas.Pen.Width := 1;
      LCanvas.Brush.Style := bsSolid;
    end;
  end;
end;

procedure TEndoomEditorPanel.PaintCharacters(ASender: TObject);
var
  LIndex: Integer;
  LCode: Integer;
  LPixelX: Integer;
  LPixelY: Integer;
  LFontOffset: Integer;
  LCellX: Integer;
  LCellY: Integer;
  LCanvas: TCanvas;
  LScale: Integer;
begin
  if Length(FFont) < ENDOOM_FONT_SIZE then
    Exit;
  LCanvas := FCharactersBox.Canvas;
  LScale := GLYPH_CELL div ENDOOM_CELL_SIZE;
  for LIndex := 0 to GLYPH_COLUMNS * GLYPH_ROWS - 1 do
  begin
    LCode := ENDOOM_EDITOR_FIRST_SPECIAL_CODE + LIndex;
    LCellX := (LIndex mod GLYPH_COLUMNS) * GLYPH_CELL;
    LCellY := (LIndex div GLYPH_COLUMNS) * GLYPH_CELL;
    for LPixelY := 0 to ENDOOM_CELL_SIZE - 1 do
      for LPixelX := 0 to ENDOOM_CELL_SIZE - 1 do
      begin
        // the character 1 is the first of the font
        LFontOffset := (((LCode - 1) div 16) * ENDOOM_CELL_SIZE + LPixelY) * ENDOOM_FONT_WIDTH +
          ((LCode - 1) mod 16) * ENDOOM_CELL_SIZE + LPixelX;
        if FFont[LFontOffset] <> 0 then
          LCanvas.Brush.Color := ColorOf(ENDOOM_COLORS[FForeground])
        else
          LCanvas.Brush.Color := ColorOf(ENDOOM_COLORS[FBackground]);
        LCanvas.FillRect(Rect(LCellX + LPixelX * LScale, LCellY + LPixelY * LScale,
          LCellX + (LPixelX + 1) * LScale, LCellY + (LPixelY + 1) * LScale));
      end;
    if (LCode = FSpecial1) or (LCode = FSpecial2) then
    begin
      LCanvas.Brush.Style := bsClear;
      if LCode = FSpecial1 then
        LCanvas.Pen.Color := clRed
      else
        LCanvas.Pen.Color := clBlue;
      LCanvas.Rectangle(LCellX, LCellY, LCellX + GLYPH_CELL, LCellY + GLYPH_CELL);
      LCanvas.Brush.Style := bsSolid;
    end;
  end;
end;

procedure TEndoomEditorPanel.ForegroundMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState;
  AX, AY: Integer);
begin
  if Assigned(FPresenter) then
    FPresenter.SelectForeground((AY div SWATCH_SIZE) * SWATCH_COLUMNS + AX div SWATCH_SIZE);
end;

procedure TEndoomEditorPanel.BackgroundMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState;
  AX, AY: Integer);
begin
  if Assigned(FPresenter) then
    FPresenter.SelectBackground(AX div SWATCH_SIZE);
end;

procedure TEndoomEditorPanel.CharactersMouseDown(ASender: TObject; AButton: TMouseButton; AShift: TShiftState;
  AX, AY: Integer);
var
  LCode: Integer;
begin
  if not Assigned(FPresenter) then
    Exit;
  LCode := ENDOOM_EDITOR_FIRST_SPECIAL_CODE + (AY div GLYPH_CELL) * GLYPH_COLUMNS + AX div GLYPH_CELL;
  if LCode > 255 then
    Exit;
  if AButton = mbRight then
  begin
    FPresenter.SelectSpecialCharacter2(LCode);
    FPresenter.SelectTool(eetSpecialCharacter);
  end
  else
  begin
    FPresenter.SelectSpecialCharacter1(LCode);
    FPresenter.SelectTool(eetSpecialCharacterWithBackground);
  end;
end;

end.
