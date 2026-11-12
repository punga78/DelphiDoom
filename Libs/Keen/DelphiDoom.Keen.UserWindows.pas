{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the windows and the text of the user manager      }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  US_Print, US_PrintUnsigned, US_PrintSigned, USL_PrintInCenter,               }
{  US_PrintCentered, US_CPrintLine, US_CPrint, US_ClearWindow, US_DrawWindow,   }
{  US_CenterWindow, US_SaveWindow, US_RestoreWindow, USL_XORICursor and         }
{  US_LineInput of id_us.c                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.UserWindows;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.UserIntf;

type
  /// <summary>
  ///   The window of the user manager: a white rectangle with a frame of 8x8 tiles, the place where the next text
  ///   goes (PrintX, PrintY) and the line editor. The numbers are the unsigned 16 bit ones of the C (word)
  /// </summary>
  TKeenUserWindows = class(TInterfacedObject, IKeenUserWindows)
  strict private
    FVideo: IKeenBufferedVideo;
    FInput: IKeenInput;
    FClock: IKeenClock;
    FWindow: TKeenWindowRec;
    procedure XorICursor(AX, AY: Integer; const AText: AnsiString; ACursor: Integer);
  public
    /// <param name="AVideo">The double buffered drawing and the font</param>
    /// <param name="AInput">The keyboard, for the line editor</param>
    /// <param name="AClock">TimeCount, for the blinking of the text cursor</param>
    constructor Create(const AVideo: IKeenBufferedVideo; const AInput: IKeenInput; const AClock: IKeenClock);
    function GetWindow: TKeenWindowRec;
    function GetPrintX: Integer;
    procedure SetPrintX(AValue: Integer);
    function GetPrintY: Integer;
    procedure SetPrintY(AValue: Integer);
    function GetVideo: IKeenBufferedVideo;
    procedure Print(const AText: AnsiString);
    procedure PrintUnsigned(AValue: Cardinal);
    procedure PrintSigned(AValue: Integer);
    procedure PrintInCenter(const AText: AnsiString; const ARect: TKeenRect);
    procedure PrintCentered(const AText: AnsiString);
    procedure CPrintLine(const AText: AnsiString);
    procedure CPrint(const AText: AnsiString);
    procedure ClearWindow;
    procedure DrawWindow(AX, AY, AWidth, AHeight: Integer);
    procedure CenterWindow(AWidth, AHeight: Integer);
    function SaveWindow: TKeenWindowRec;
    procedure RestoreWindow(const AWindow: TKeenWindowRec);
    procedure SetWindow(const AWindow: TKeenWindowRec);
    function LineInput(AX, AY: Integer; var ABuffer: AnsiString; const ADefault: AnsiString; AEscapeOk: Boolean;
      AMaxChars, AMaxWidth: Integer): Boolean;
  end;

implementation

{ TKeenUserWindows }

constructor TKeenUserWindows.Create(const AVideo: IKeenBufferedVideo; const AInput: IKeenInput;
  const AClock: IKeenClock);
begin
  inherited Create;
  if not Assigned(AVideo) then
    raise EArgumentNilException.Create('AVideo');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FVideo := AVideo;
  FInput := AInput;
  FClock := AClock;
end;

function TKeenUserWindows.GetWindow: TKeenWindowRec;
begin
  Result := FWindow;
end;

function TKeenUserWindows.GetPrintX: Integer;
begin
  Result := FWindow.PX;
end;

procedure TKeenUserWindows.SetPrintX(AValue: Integer);
begin
  FWindow.PX := AValue and $FFFF;
end;

function TKeenUserWindows.GetPrintY: Integer;
begin
  Result := FWindow.PY;
end;

procedure TKeenUserWindows.SetPrintY(AValue: Integer);
begin
  FWindow.PY := AValue and $FFFF;
end;

function TKeenUserWindows.GetVideo: IKeenBufferedVideo;
begin
  Result := FVideo;
end;

function TKeenUserWindows.SaveWindow: TKeenWindowRec;
begin
  Result := FWindow;
end;

procedure TKeenUserWindows.RestoreWindow(const AWindow: TKeenWindowRec);
begin
  FWindow := AWindow;
end;

procedure TKeenUserWindows.SetWindow(const AWindow: TKeenWindowRec);
begin
  FWindow.X := AWindow.X and $FFFF;
  FWindow.Y := AWindow.Y and $FFFF;
  FWindow.W := AWindow.W and $FFFF;
  FWindow.H := AWindow.H and $FFFF;
  FWindow.PX := AWindow.PX and $FFFF;
  FWindow.PY := AWindow.PY and $FFFF;
end;

procedure TKeenUserWindows.Print(const AText: AnsiString);
var
  LStart: Integer;
  LEnd: Integer;
  LLine: AnsiString;
  LWidth: Integer;
  LHeight: Integer;
begin
  LStart := 1;
  while LStart <= Length(AText) do
  begin
    LEnd := LStart;
    while (LEnd <= Length(AText)) and (AText[LEnd] <> #10) do
      Inc(LEnd);
    LLine := Copy(AText, LStart, LEnd - LStart);
    FVideo.MeasureString(LLine, LWidth, LHeight);
    FVideo.Px := FWindow.PX;
    FVideo.Py := FWindow.PY;
    FVideo.DrawString(LLine);
    if LEnd <= Length(AText) then
    begin
      // a line feed
      LStart := LEnd + 1;
      FWindow.PX := FWindow.X;
      FWindow.PY := (FWindow.PY + LHeight) and $FFFF;
    end
    else
    begin
      LStart := LEnd;
      FWindow.PX := (FWindow.PX + LWidth) and $FFFF;
    end;
  end;
end;

procedure TKeenUserWindows.PrintUnsigned(AValue: Cardinal);
begin
  Print(AnsiString(UIntToStr(AValue)));
end;

procedure TKeenUserWindows.PrintSigned(AValue: Integer);
begin
  Print(AnsiString(IntToStr(AValue)));
end;

procedure TKeenUserWindows.PrintInCenter(const AText: AnsiString; const ARect: TKeenRect);
var
  LWidth: Integer;
  LHeight: Integer;
  LRectWidth: Integer;
  LRectHeight: Integer;
begin
  FVideo.MeasureString(AText, LWidth, LHeight);
  // word arithmetic: a string wider than the rectangle wraps and the division is unsigned, as in the C
  LRectWidth := (ARect.LR.X - ARect.UL.X) and $FFFF;
  LRectHeight := (ARect.LR.Y - ARect.UL.Y) and $FFFF;
  FVideo.Px := ARect.UL.X + (((LRectWidth - LWidth) and $FFFF) div 2);
  FVideo.Py := ARect.UL.Y + (((LRectHeight - LHeight) and $FFFF) div 2);
  FVideo.DrawString(AText);
end;

procedure TKeenUserWindows.PrintCentered(const AText: AnsiString);
begin
  PrintInCenter(AText, TKeenRect.Make(FWindow.X, FWindow.Y, FWindow.X + FWindow.W, FWindow.Y + FWindow.H));
end;

procedure TKeenUserWindows.CPrintLine(const AText: AnsiString);
var
  LWidth: Integer;
  LHeight: Integer;
begin
  FVideo.MeasureString(AText, LWidth, LHeight);
  if LWidth > FWindow.W then
    raise EKeenException.Create(SKeenPrintTooWide);
  FVideo.Px := FWindow.X + ((FWindow.W - LWidth) div 2);
  FVideo.Py := FWindow.PY;
  FVideo.DrawString(AText);
  FWindow.PY := (FWindow.PY + LHeight) and $FFFF;
end;

procedure TKeenUserWindows.CPrint(const AText: AnsiString);
var
  LStart: Integer;
  LEnd: Integer;
begin
  LStart := 1;
  while LStart <= Length(AText) do
  begin
    LEnd := LStart;
    while (LEnd <= Length(AText)) and (AText[LEnd] <> #10) do
      Inc(LEnd);
    CPrintLine(Copy(AText, LStart, LEnd - LStart));
    if LEnd <= Length(AText) then
      LStart := LEnd + 1
    else
      LStart := LEnd;
  end;
end;

procedure TKeenUserWindows.ClearWindow;
begin
  FVideo.Bar(FWindow.X, FWindow.Y, FWindow.W, FWindow.H, KEEN_WHITE);
  FWindow.PX := FWindow.X;
  FWindow.PY := FWindow.Y;
end;

procedure TKeenUserWindows.DrawWindow(AX, AY, AWidth, AHeight: Integer);
var
  LIndex: Integer;
  LSX: Integer;
  LSY: Integer;
  LSW: Integer;
  LSH: Integer;
begin
  FWindow.X := (AX * 8) and $FFFF;
  FWindow.Y := (AY * 8) and $FFFF;
  FWindow.W := (AWidth * 8) and $FFFF;
  FWindow.H := (AHeight * 8) and $FFFF;
  FWindow.PX := FWindow.X;
  FWindow.PY := FWindow.Y;
  LSX := (AX - 1) * 8;
  LSY := (AY - 1) * 8;
  LSW := (AWidth + 1) * 8;
  LSH := (AHeight + 1) * 8;
  ClearWindow;
  // the frame: the tiles 0, 1, 2 on the top, 6, 7, 8 on the bottom, 3 and 5 on the sides
  FVideo.DrawTile8Masked(LSX, LSY, 0);
  FVideo.DrawTile8Masked(LSX, LSY + LSH, 6);
  LIndex := LSX + 8;
  while LIndex <= LSX + LSW - 8 do
  begin
    FVideo.DrawTile8Masked(LIndex, LSY, 1);
    FVideo.DrawTile8Masked(LIndex, LSY + LSH, 7);
    Inc(LIndex, 8);
  end;
  FVideo.DrawTile8Masked(LIndex, LSY, 2);
  FVideo.DrawTile8Masked(LIndex, LSY + LSH, 8);
  LIndex := LSY + 8;
  while LIndex <= LSY + LSH - 8 do
  begin
    FVideo.DrawTile8Masked(LSX, LIndex, 3);
    FVideo.DrawTile8Masked(LSX + LSW, LIndex, 5);
    Inc(LIndex, 8);
  end;
end;

procedure TKeenUserWindows.CenterWindow(AWidth, AHeight: Integer);
begin
  DrawWindow(((KEEN_MAX_X div 8) - AWidth) div 2, ((KEEN_MAX_Y div 8) - AHeight) div 2, AWidth, AHeight);
end;

procedure TKeenUserWindows.XorICursor(AX, AY: Integer; const AText: AnsiString; ACursor: Integer);
var
  LWidth: Integer;
  LHeight: Integer;
begin
  FVideo.MeasureString(Copy(AText, 1, ACursor), LWidth, LHeight);
  FVideo.Px := AX + LWidth - 1;
  FVideo.Py := AY;
  // the character 128 of the font is the I bar
  FVideo.DrawString(AnsiChar(#$80));
end;

function TKeenUserWindows.LineInput(AX, AY: Integer; var ABuffer: AnsiString; const ADefault: AnsiString;
  AEscapeOk: Boolean; AMaxChars, AMaxWidth: Integer): Boolean;
var
  LRedraw: Boolean;
  LCursorVisible: Boolean;
  LCursorMoved: Boolean;
  LDone: Boolean;
  LScan: Byte;
  LAscii: Byte;
  LText: AnsiString;
  LOld: AnsiString;
  LCursor: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LLastTime: Integer;
begin
  Result := False;
  FVideo.HideCursor;
  LText := ADefault;
  LOld := '';
  LCursor := Length(LText);
  LCursorMoved := True;
  LRedraw := True;
  LCursorVisible := False;
  LDone := False;
  LLastTime := FClock.TimeCount;
  FInput.LastAscii := KEEN_KEY_NONE;
  FInput.LastScan := KEEN_SC_NONE;
  while not LDone do
  begin
    if LCursorVisible then
      XorICursor(AX, AY, LText, LCursor);
    LScan := FInput.LastScan;
    FInput.LastScan := KEEN_SC_NONE;
    LAscii := FInput.LastAscii;
    FInput.LastAscii := KEEN_KEY_NONE;
    case LScan of
      KEEN_SC_LEFTARROW:
        begin
          if LCursor > 0 then
            Dec(LCursor);
          LAscii := KEEN_KEY_NONE;
          LCursorMoved := True;
        end;
      KEEN_SC_RIGHTARROW:
        begin
          if LCursor < Length(LText) then
            Inc(LCursor);
          LAscii := KEEN_KEY_NONE;
          LCursorMoved := True;
        end;
      KEEN_SC_HOME:
        begin
          LCursor := 0;
          LAscii := KEEN_KEY_NONE;
          LCursorMoved := True;
        end;
      KEEN_SC_END:
        begin
          LCursor := Length(LText);
          LAscii := KEEN_KEY_NONE;
          LCursorMoved := True;
        end;
      KEEN_SC_RETURN:
        begin
          ABuffer := LText;
          LDone := True;
          Result := True;
          LAscii := KEEN_KEY_NONE;
        end;
      KEEN_SC_ESCAPE:
        begin
          if AEscapeOk then
          begin
            LDone := True;
            Result := False;
          end;
          LAscii := KEEN_KEY_NONE;
        end;
      KEEN_SC_BACKSPACE:
        begin
          if LCursor > 0 then
          begin
            Delete(LText, LCursor, 1);
            Dec(LCursor);
            LRedraw := True;
          end;
          LAscii := KEEN_KEY_NONE;
          LCursorMoved := True;
        end;
      KEEN_SC_DELETE:
        begin
          if LCursor < Length(LText) then
          begin
            Delete(LText, LCursor + 1, 1);
            LRedraw := True;
          end;
          LAscii := KEEN_KEY_NONE;
          LCursorMoved := True;
        end;
      // keypad 5, up, down, page up, page down, insert: they type nothing
      $4C, KEEN_SC_UPARROW, KEEN_SC_DOWNARROW, KEEN_SC_PGUP, KEEN_SC_PGDN, KEEN_SC_INSERT:
        LAscii := KEEN_KEY_NONE;
    end;
    if LAscii <> KEEN_KEY_NONE then
    begin
      FVideo.MeasureString(LText, LWidth, LHeight);
      // isprint
      if (LAscii >= 32) and (LAscii <= 126) and (Length(LText) < KEEN_MAX_STRING - 1) and
        ((AMaxChars = 0) or (Length(LText) < AMaxChars)) and ((AMaxWidth = 0) or (LWidth < AMaxWidth)) then
      begin
        Insert(AnsiChar(LAscii), LText, LCursor + 1);
        Inc(LCursor);
        LRedraw := True;
      end;
    end;
    if LRedraw then
    begin
      // the old text is XORed away and the new one XORed in
      FVideo.Px := AX;
      FVideo.Py := AY;
      FVideo.DrawString(LOld);
      LOld := LText;
      FVideo.Px := AX;
      FVideo.Py := AY;
      FVideo.DrawString(LText);
      LRedraw := False;
    end;
    if LCursorMoved then
    begin
      LCursorVisible := False;
      LLastTime := FClock.TimeCount - KEEN_TICKBASE;
      LCursorMoved := False;
    end;
    if FClock.TimeCount - LLastTime > KEEN_TICKBASE div 2 then
    begin
      LLastTime := FClock.TimeCount;
      LCursorVisible := not LCursorVisible;
    end;
    if LCursorVisible then
      XorICursor(AX, AY, LText, LCursor);
    FVideo.UpdateScreen;
  end;
  if LCursorVisible then
    XorICursor(AX, AY, LText, LCursor);
  if not Result then
  begin
    FVideo.Px := AX;
    FVideo.Py := AY;
    FVideo.DrawString(LOld);
  end;
  FVideo.ShowCursor;
  FVideo.UpdateScreen;
  FInput.ClearKeysDown;
end;

end.
