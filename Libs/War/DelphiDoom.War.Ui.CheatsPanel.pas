{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the panel of the cheats                           }
{                                                                              }
{  Port of war1 (acoto87/war1), war_cheats_panel.c, war_cheats.c               }
{  (wcheat_applyCheat) and appendCheatTextInput of war_game.c, (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.CheatsPanel;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Render.Types, DelphiDoom.War.Font.Types, DelphiDoom.War.Text.Types,
  DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Canvas, DelphiDoom.War.Ui.Imui,
  DelphiDoom.War.Ui.CheatTable;

type
  /// <summary>
  ///   The cheat panel of a scene (WarCheatStatus and its functions): Enter opens the line at the top of the screen,
  ///   what is typed goes in it, Enter applies it and closes it, Escape closes it. The feedback of a cheat is shown for
  ///   three seconds. Defects of the original kept: a printable character is refused from 31 characters on but a Tab
  ///   from 39 (the check of the Tab is against STATUS_TEXT_MAX_LENGTH, 40), and the line that is drawn is cut at 39
  ///   characters, "MSG: " included (the buffer of the snprintf)
  /// </summary>
  TWarCheatsPanel = class
  strict private
    FHost: IWarSceneHost;
    FInput: IWarUiInput;
    FImui: TWarImui;
    FCanvas: TWarUiCanvas;
    FEffects: IWarCheatEffects;
    FEnabled: Boolean;
    FVisible: Boolean;
    FPosition: Integer;
    FText: AnsiString;
    FFeedback: Boolean;
    FFeedbackEndRealTime: Double;
    FFeedbackText: AnsiString;
    FDebugTextActive: Boolean;
    FDebugText: AnsiString;
    FCursorX: Single;
    procedure ApplyCheat(const AText: AnsiString);
    procedure HandleEditKeys;
    procedure ComputeCursor;
  public
    constructor Create(const AHost: IWarSceneHost; const AInput: IWarUiInput; const AImui: TWarImui;
      const ACanvas: TWarUiCanvas; const AEffects: IWarCheatEffects);
    /// <summary>wcheatp_createCheatsPanel: enabled, closed and empty (the other scenes never create it: it is off)</summary>
    procedure Enable;
    /// <summary>wcheatp_setCheatsPanelVisible: the text is cleared; the window starts or stops the text input</summary>
    procedure SetVisible(AVisible: Boolean);
    /// <summary>wcheatp_setCheatsFeedback: an empty text clears the feedback</summary>
    procedure SetFeedback(const AText: AnsiString);
    /// <summary>wcheatp_setDebugText</summary>
    procedure SetDebugText(const AText: AnsiString);
    /// <summary>appendCheatTextInput: the characters from 32 to 126, up to 31 in the line, at the cursor</summary>
    procedure AppendTextInput(const AText: AnsiString);
    /// <summary>wcheatp_updateCheatsPanel</summary>
    procedure Update;
    /// <summary>wcheatp_renderCheatsPanel</summary>
    procedure Render;
    property Enabled: Boolean read FEnabled;
    property Visible: Boolean read FVisible;
    property Position: Integer read FPosition;
    property Text: AnsiString read FText;
    property Feedback: Boolean read FFeedback;
    property FeedbackText: AnsiString read FFeedbackText;
    property CursorX: Single read FCursorX;
  end;

implementation

uses
  DelphiDoom.War.Text.Layout;

{ TWarCheatsPanel }

constructor TWarCheatsPanel.Create(const AHost: IWarSceneHost; const AInput: IWarUiInput; const AImui: TWarImui;
  const ACanvas: TWarUiCanvas; const AEffects: IWarCheatEffects);
begin
  inherited Create;
  FHost := AHost;
  FInput := AInput;
  FImui := AImui;
  FCanvas := ACanvas;
  FEffects := AEffects;
  FCursorX := -1;
end;

procedure TWarCheatsPanel.Enable;
begin
  FEnabled := True;
  FVisible := False;
  FPosition := 0;
  FCursorX := -1;
  FText := '';
end;

procedure TWarCheatsPanel.SetVisible(AVisible: Boolean);
begin
  FText := '';
  FPosition := 0;
  FCursorX := -1;
  FVisible := AVisible;
  FHost.SetTextInputActive(AVisible);
end;

procedure TWarCheatsPanel.SetFeedback(const AText: AnsiString);
begin
  FFeedbackText := '';
  if AText <> '' then
  begin
    FFeedback := True;
    FFeedbackEndRealTime := FHost.RealTime + WAR_CHEAT_FEEDBACK_SECONDS;
    FFeedbackText := AText;
  end
  else
  begin
    FFeedback := False;
    FFeedbackEndRealTime := 0;
  end;
end;

procedure TWarCheatsPanel.SetDebugText(const AText: AnsiString);
begin
  if AText <> '' then
  begin
    FDebugText := AText;
    FDebugTextActive := True;
  end
  else
  begin
    FDebugTextActive := False;
    FDebugText := '';
  end;
end;

procedure TWarCheatsPanel.AppendTextInput(const AText: AnsiString);
var
  LIndex: Integer;
  LCode: Integer;
begin
  if (not FEnabled) or (not FVisible) then
    Exit;
  // SDL_StepUTF8 gives code points: the bytes of a multi-byte character are never in 32..126, so they are skipped
  for LIndex := 1 to Length(AText) do
  begin
    LCode := Ord(AText[LIndex]);
    if (LCode >= 32) and (LCode <= 126) then
    begin
      if Length(FText) + 1 < WAR_CHEAT_TEXT_MAX_LENGTH then
      begin
        Insert(AnsiString(AnsiChar(LCode)), FText, FPosition + 1);
        Inc(FPosition);
      end;
    end;
  end;
end;

procedure TWarCheatsPanel.ApplyCheat(const AText: AnsiString);
var
  LDescriptor: TWarCheatDescriptor;
  LArgument: AnsiString;
  LFeedback: AnsiString;
begin
  if not TWarCheatTable.Match(AText, LDescriptor, LArgument) then
    Exit; // "Unknown cheat": the original only logs it
  LFeedback := FEffects.Apply(string(LDescriptor.Text), LArgument);
  if LFeedback <> '' then
    SetFeedback(LFeedback);
end;

procedure TWarCheatsPanel.HandleEditKeys;
var
  LLength: Integer;
begin
  LLength := Length(FText);
  if FInput.IsKeyJustReleased(wkTab) then
  begin
    if 2 <= WAR_STATUS_TEXT_MAX_LENGTH - LLength then
    begin
      Insert(AnsiString(#9), FText, FPosition + 1);
      Inc(FPosition);
    end;
  end
  else if FInput.IsKeyJustReleased(wkBackspace) then
  begin
    if FPosition > 0 then
    begin
      Delete(FText, FPosition, 1);
      Dec(FPosition);
    end;
  end
  else if FInput.IsKeyJustReleased(wkDelete) then
  begin
    if FPosition < LLength then
      Delete(FText, FPosition + 1, 1);
  end
  else if FInput.IsKeyJustReleased(wkRight) then
  begin
    if FPosition < LLength then
      Inc(FPosition);
  end
  else if FInput.IsKeyJustReleased(wkLeft) then
  begin
    if FPosition > 0 then
      Dec(FPosition);
  end
  else if FInput.IsKeyJustReleased(wkHome) then
    FPosition := 0
  else if FInput.IsKeyJustReleased(wkEnd) then
    FPosition := LLength;
end;

procedure TWarCheatsPanel.ComputeCursor;
var
  LParams: TWarFontParams;
  LPrefix: TWarTextSize;
  LTyped: TWarTextSize;
  LSum: Single;
begin
  LParams := Default(TWarFontParams);
  LParams.FontSize := 6;
  LParams.FontData := FCanvas.FontData(0);
  LPrefix := TWarTextLayout.MeasureSingle('MSG: ', 5, LParams);
  LTyped := TWarTextLayout.MeasureSingle(FText, FPosition, LParams);
  LSum := 2 + LPrefix.X;
  FCursorX := LSum + LTyped.X;
end;

procedure TWarCheatsPanel.Update;
begin
  if not FEnabled then
    Exit;
  if FFeedback then
  begin
    if FHost.RealTime >= FFeedbackEndRealTime then
      FFeedback := False;
  end;
  if FVisible then
  begin
    if FInput.IsKeyJustReleased(wkEsc) or FInput.IsKeyJustReleased(wkEnter) then
    begin
      if FInput.IsKeyJustReleased(wkEnter) then
        ApplyCheat(FText);
      SetVisible(False);
      Exit;
    end;
    HandleEditKeys;
    ComputeCursor;
  end
  else
  begin
    FCursorX := -1;
    if FInput.IsKeyJustReleased(wkEnter) then
      SetVisible(True);
  end;
end;

procedure TWarCheatsPanel.Render;
var
  LRect: TWarUiRectArgs;
  LText: TWarUiTextArgs;
begin
  if not FEnabled then
    Exit;
  if FVisible then
  begin
    // a gray translucent bar at the top of the screen
    LRect := TWarUiRectArgs.Default;
    LRect.SizeX := FHost.OriginalWidth;
    LRect.SizeY := 12;
    LRect.Color.R := 100;
    LRect.Color.G := 100;
    LRect.Color.B := 100;
    LRect.Color.A := 160;
    FImui.Rect('panelCheat', LRect);
    LText := TWarUiTextArgs.Default;
    LText.PositionX := 2;
    LText.PositionY := 4;
    LText.FontSize := 6;
    // snprintf into a buffer of 40 bytes: 39 characters
    LText.Text := Copy('MSG: ' + FText, 1, 39);
    FImui.Text('txtCheat', LText);
    if FCursorX >= 0 then
    begin
      LRect := TWarUiRectArgs.Default;
      LRect.PositionX := FCursorX;
      LRect.PositionY := 3;
      LRect.SizeX := 1;
      LRect.SizeY := 7;
      LRect.Color := WAR_COLOR_WHITE;
      FImui.Rect('cursorCheat', LRect);
    end;
  end;
  if FFeedback and (FFeedbackText <> '') then
  begin
    LText := TWarUiTextArgs.Default;
    LText.PositionX := 10;
    LText.PositionY := 20;
    LText.FontIndex := 1;
    LText.FontSize := 8;
    LText.FontColor := WAR_COLOR_YELLOW;
    LText.Text := FFeedbackText;
    FImui.Text('txtCheatFeedback', LText);
  end
  else if FDebugTextActive and (FDebugText <> '') then
  begin
    LText := TWarUiTextArgs.Default;
    LText.PositionX := 10;
    LText.PositionY := 20;
    LText.BoundingsX := FHost.OriginalWidth;
    LText.BoundingsY := FHost.OriginalHeight;
    LText.FontIndex := 1;
    LText.FontSize := 8;
    LText.FontColor := WAR_COLOR_YELLOW;
    LText.Multiline := True;
    LText.Text := FDebugText;
    FImui.Text('txtDebugFeedback', LText);
  end;
end;

end.
