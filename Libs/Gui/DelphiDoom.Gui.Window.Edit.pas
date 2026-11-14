{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiEditWindow (editDef)                          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\EditWindow.h,           }
{  EditWindow.cpp (idEditWindow: the parse). Copyright (C) 1999-2011 id        }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Edit;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Str, DelphiDoom.Gui.Window.Keys,
  DelphiDoom.Gui.Window.Slider, System.Generics.Collections;

type
  /// <summary>
  ///   idEditWindow: the keys <c>maxchars</c>, <c>numeric</c>, <c>wrap</c>, <c>readonly</c>,
  ///   <c>forceScroll</c>, <c>source</c>, <c>password</c>, <c>cvarMax</c> and the variables <c>cvar</c>,
  ///   <c>password</c>, <c>liveUpdate</c>, <c>cvarGroup</c>. Not ported: the file named by <c>source</c> (the
  ///   name is kept), the cvar, the scroll bar, the cursor and the keys.
  /// </summary>
  TGuiEditWindow = class(TGuiWindow)
  strict private
    FMaxChars: Integer;
    FNumeric: Boolean;
    FWrap: Boolean;
    FReadOnly: Boolean;
    FForceScroll: Boolean;
    FCvarMax: Integer;
    FSourceFile: AnsiString;
    FCvarStr: TGuiWinStr;
    FCvarGroup: TGuiWinStr;
    FPassword: TGuiWinBool;
    FLiveUpdate: TGuiWinBool;
    FPaintOffset: Integer;
    FCursorPos: Integer;
    FCursorLine: Integer;
    FLastTextLength: Integer;
    FSizeBias: Single;
    FHasCvar: Boolean;
    FScroller: TGuiSliderWindow;
    FBreaks: TList<Integer>;
    procedure InitCvar;
    procedure UpdateCvar(const ARead: Boolean; const AForce: Boolean = False);
    procedure InitScroller(const AHorizontal: Boolean);
    procedure EnsureCursorVisible;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    function HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString; override;
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
    procedure GainFocus; override;
    procedure Activate(const AActivate: Boolean; var AAct: AnsiString); override;
    procedure RunNamedEvent(const AEventName: AnsiString); override;
    property CursorPos: Integer read FCursorPos;
    property CursorLine: Integer read FCursorLine;
    property PaintOffset: Integer read FPaintOffset;
    property Scroller: TGuiSliderWindow read FScroller;
    property MaxChars: Integer read FMaxChars;
    property Numeric: Boolean read FNumeric;
    property Wrap: Boolean read FWrap;
    property ReadOnly: Boolean read FReadOnly;
    property ForceScroll: Boolean read FForceScroll;
    property CvarMax: Integer read FCvarMax;
    property TextSourceFile: AnsiString read FSourceFile;
    property Password: TGuiWinBool read FPassword;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.DrawContext, DelphiDoom.Gui.Material.Intf,
  DelphiDoom.IdLib.Core.Intf;

constructor TGuiEditWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FCvarStr := TGuiWinStr.Create;
  FCvarGroup := TGuiWinStr.Create;
  FPassword := TGuiWinBool.Create;
  FLiveUpdate := TGuiWinBool.Create;
  FMaxChars := 128;
  FLiveUpdate.Value := True;
  FBreaks := TList<Integer>.Create;
  FScroller := TGuiSliderWindow.Create(AContext, ACreator);
end;

destructor TGuiEditWindow.Destroy;
begin
  FBreaks.Free;
  FLiveUpdate.Free;
  FPassword.Free;
  FCvarGroup.Free;
  FCvarStr.Free;
  inherited Destroy;
end;

function TGuiEditWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if TIdStrings.Icmp(AName, 'maxchars') = 0 then
    FMaxChars := ASource.ParseInt
  else if TIdStrings.Icmp(AName, 'numeric') = 0 then
    FNumeric := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'wrap') = 0 then
    FWrap := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'readonly') = 0 then
    FReadOnly := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'forceScroll') = 0 then
    FForceScroll := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'source') = 0 then
    ParseString(ASource, FSourceFile)
  else if TIdStrings.Icmp(AName, 'password') = 0 then
    FPassword.Value := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'cvarMax') = 0 then
    FCvarMax := ASource.ParseInt
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

function TGuiEditWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
begin
  AOwner := nil;
  if TIdStrings.Icmp(AName, 'cvar') = 0 then
    Exit(FCvarStr);
  if TIdStrings.Icmp(AName, 'password') = 0 then
    Exit(FPassword);
  if TIdStrings.Icmp(AName, 'liveUpdate') = 0 then
    Exit(FLiveUpdate);
  if TIdStrings.Icmp(AName, 'cvarGroup') = 0 then
    Exit(FCvarGroup);
  Result := inherited GetWinVarByName(AName, AFixup, AOwner);
end;

procedure TGuiEditWindow.PostParse;
var
  LFile: TIdLibFileData;
  LSourceText: AnsiString;
begin
  inherited PostParse;
  if FMaxChars = 0 then
    FMaxChars := 10;
  if FSourceFile <> '' then
  begin
    if Assigned(Context.FileSystem) and Context.FileSystem.TryReadFile(FSourceFile, False, LFile) then
    begin
      if Length(LFile.Data) > 0 then
        SetString(LSourceText, PAnsiChar(@LFile.Data[0]), Length(LFile.Data))
      else
        LSourceText := '';
      Text.Value := LSourceText;
    end
    else
      Text.Value := '';
  end;
  InitCvar;
  InitScroller(False);
  EnsureCursorVisible;
  SetFlag(WIN_CANFOCUS);
end;

procedure TGuiEditWindow.InitScroller(const AHorizontal: Boolean);
const
  THUMB_IMAGE = 'guis/assets/scrollbar_thumb.tga';
var
  LBarImage, LName: AnsiString;
  LMaterial: IGuiMaterial;
  LRect: TGuiRectangle;
begin
  LBarImage := 'guis/assets/scrollbarv.tga';
  LName := '_scrollerWinV';
  if AHorizontal then
  begin
    LBarImage := 'guis/assets/scrollbarh.tga';
    LName := '_scrollerWinH';
  end;
  if not Assigned(Context.Materials) then
    Exit;
  LMaterial := Context.Materials.FindMaterial(LBarImage);
  LMaterial.SetGuiSort;
  FSizeBias := LMaterial.GetImageWidth;
  if AHorizontal then
  begin
    FSizeBias := LMaterial.GetImageHeight;
    LRect := TGuiRectangle.Create(0, ClientRect.H - FSizeBias, ClientRect.W, FSizeBias);
  end
  else
    LRect := TGuiRectangle.Create(ClientRect.W - FSizeBias, 0, FSizeBias, ClientRect.H);
  FScroller.InitWithDefaults(LName, LRect, ForeColor.Value, MatColor.Value, LMaterial.GetName, THUMB_IMAGE,
    not AHorizontal, True);
  InsertChild(FScroller, nil);
  FScroller.SetBuddy(Self);
end;

procedure TGuiEditWindow.InitCvar;
begin
  if FCvarStr.AsText = '' then
  begin
    // the original warns only if text.GetName() is NULL, which GetName() never returns: no warning
    FHasCvar := False;
    Exit;
  end;
  FHasCvar := Assigned(Context.Cvars) and Context.Cvars.Exists(FCvarStr.AsText);
  if not FHasCvar then
    Warning(Format('idEditWindow::InitCvar: gui ''%s'' window ''%s'' references undefined cvar ''%s''',
      [string(Context.SourceFile), string(Name), string(FCvarStr.AsText)]));
end;

procedure TGuiEditWindow.UpdateCvar(const ARead: Boolean; const AForce: Boolean);
begin
  if AForce or FLiveUpdate.Value then
  begin
    if FHasCvar then
    begin
      if ARead then
        Text.Value := Context.Cvars.GetString(FCvarStr.AsText)
      else
      begin
        Context.Cvars.SetString(FCvarStr.AsText, Text.AsText);
        if (FCvarMax <> 0) and (Context.Cvars.GetInteger(FCvarStr.AsText) > FCvarMax) then
          Context.Cvars.SetInteger(FCvarStr.AsText, FCvarMax);
      end;
    end;
  end;
end;

procedure TGuiEditWindow.RunNamedEvent(const AEventName: AnsiString);
var
  LGroup: AnsiString;
begin
  if Copy(AEventName, 1, 10) = 'cvar read ' then
  begin
    LGroup := Copy(AEventName, 11, MaxInt);
    if LGroup = FCvarGroup.AsText then
      UpdateCvar(True, True);
  end
  else if Copy(AEventName, 1, 11) = 'cvar write ' then
  begin
    LGroup := Copy(AEventName, 12, MaxInt);
    if LGroup = FCvarGroup.AsText then
      UpdateCvar(False, True);
  end;
end;

procedure TGuiEditWindow.GainFocus;
begin
  FCursorPos := Text.Length;
  EnsureCursorVisible;
end;

procedure TGuiEditWindow.Activate(const AActivate: Boolean; var AAct: AnsiString);
begin
  inherited Activate(AActivate, AAct);
  if AActivate then
  begin
    UpdateCvar(True, True);
    EnsureCursorVisible;
  end;
end;

procedure TGuiEditWindow.EnsureCursorVisible;
var
  LDc: TGuiDrawContext;
  LCursorX, LIndex, LMaxWidth, LLeft, LRight, LFit, LTop: Integer;
  LRect: TGuiRectangle;
  LText: AnsiString;
  LCharWidth: Single;
  LCursor: Integer;
begin
  if FReadOnly then
    FCursorPos := -1
  else if FMaxChars = 1 then
    FCursorPos := 0;
  LDc := Context.DrawContext;
  if not Assigned(LDc) then
    Exit;
  SetFont;
  LText := Text.AsText;
  if not FWrap then
  begin
    LCursorX := 0;
    if FPassword.Value then
      LCursorX := FCursorPos * LDc.CharWidth('*', TextScale.Value)
    else
    begin
      LIndex := 0;
      while (LIndex < Length(LText)) and (LIndex < FCursorPos) do
      begin
        if TIdStrings.IsColor(LText, LIndex) then
          Inc(LIndex, 2)
        else
        begin
          LCursorX := LCursorX + LDc.CharWidth(LText[LIndex + 1], TextScale.Value);
          Inc(LIndex);
        end;
      end;
    end;
    LMaxWidth := TIdMath.Ftoi(GetMaxCharWidth);
    LLeft := LCursorX - LMaxWidth;
    LCharWidth := LCursorX - TextRect.W;
    LCharWidth := LCharWidth + LMaxWidth;
    LRight := TIdMath.Ftoi(LCharWidth);
    if FPaintOffset > LLeft then
      FPaintOffset := LLeft - LMaxWidth * 6;
    if FPaintOffset < LRight then
      FPaintOffset := LRight;
    if FPaintOffset < 0 then
      FPaintOffset := 0;
    FScroller.SetRange(0.0, 0.0, 1.0);
  end
  else
  begin
    FBreaks.Clear;
    LRect := TextRect;
    LRect.W := LRect.W - FSizeBias;
    if (Flags and WIN_FOCUS) <> 0 then
      LCursor := FCursorPos
    else
      LCursor := -1;
    LDc.DrawText(LText, TextScale.Value, TextAlign, LDc.ColorWhite, LRect, True, LCursor, True, FBreaks);
    LCharWidth := GetMaxCharHeight + 5;
    LCharWidth := TextRect.H / LCharWidth;
    LFit := TIdMath.Ftoi(LCharWidth);
    if LFit < FBreaks.Count + 1 then
      FScroller.SetRange(0, FBreaks.Count + 1 - LFit, 1)
    else
      FScroller.SetRange(0.0, 0.0, 1.0);
    if FForceScroll then
      FScroller.SetValue(FBreaks.Count - LFit)
    else if FReadOnly then
    begin
    end
    else
    begin
      FCursorLine := 0;
      for LIndex := 1 to FBreaks.Count - 1 do
      begin
        if FCursorPos >= FBreaks[LIndex] then
          FCursorLine := LIndex
        else
          Break;
      end;
      LTop := TIdMath.FtoiFast(FScroller.GetValue);
      if FCursorLine < LTop then
        FScroller.SetValue(FCursorLine)
      else if FCursorLine >= LTop + LFit then
        FScroller.SetValue((FCursorLine - LFit) + 1);
    end;
  end;
end;

procedure TGuiEditWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LColor: TIdVec4;
  LLength, LIndex: Integer;
  LBuffer: AnsiString;
  LRect: TGuiRectangle;
  LDc: TGuiDrawContext;
  LLineHeight, LTemp: Single;
  LCursor: Integer;
begin
  LColor := ForeColor.Value;
  LDc := Context.DrawContext;
  UpdateCvar(True);
  LLength := Text.Length;
  if LLength <> FLastTextLength then
  begin
    FScroller.SetValue(0.0);
    EnsureCursorVisible;
    FLastTextLength := LLength;
  end;
  if FPassword.Value then
  begin
    LBuffer := '';
    for LIndex := 1 to Length(Text.AsText) do
      LBuffer := LBuffer + '*';
  end
  else
    LBuffer := Text.AsText;
  if FCursorPos > LLength then
    FCursorPos := LLength;
  LRect := TextRect;
  LRect.X := LRect.X - FPaintOffset;
  LRect.W := LRect.W + FPaintOffset;
  if FWrap and (FScroller.GetHigh > 0.0) then
  begin
    LLineHeight := GetMaxCharHeight + 5;
    LTemp := FScroller.GetValue * LLineHeight;
    LRect.Y := LRect.Y - LTemp;
    LRect.W := LRect.W - FSizeBias;
    LRect.H := (FBreaks.Count + 1) * LLineHeight;
  end;
  if Hover and (not NoEvents.Value) and ContainsPoint(Context.CursorX, Context.CursorY) then
    LColor := HoverColor.Value
  else
    Hover := False;
  if (Flags and WIN_FOCUS) <> 0 then
    LColor := HoverColor.Value;
  if (Flags and WIN_FOCUS) <> 0 then
    LCursor := FCursorPos
  else
    LCursor := -1;
  LDc.DrawText(LBuffer, TextScale.Value, 0, LColor, LRect, FWrap, LCursor);
end;

function TGuiEditWindow.HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString;
const
  MAX_EDITFIELD = 4096;
var
  LBuffer: TBytes;
  LKey, LLength, LCount, LOffset: Integer;

  function CtrlDown: Boolean;
  begin
    Result := Assigned(Context.Keys) and Context.Keys.IsDown(GUI_K_CTRL);
  end;

  function TextOfBuffer: AnsiString;
  var
    LEnd: Integer;
  begin
    LEnd := 0;
    while (LEnd < MAX_EDITFIELD) and (LBuffer[LEnd] <> 0) do
      Inc(LEnd);
    SetString(Result, PAnsiChar(@LBuffer[0]), LEnd);
  end;

  procedure Check(const AIndex, ACount: Integer);
  begin
    if (AIndex < 0) or (ACount < 0) or (AIndex + ACount > MAX_EDITFIELD) then
      raise EGuiWindowException.Create('the edit window writes outside its buffer of 4096 bytes');
  end;

  procedure Move(const ASource, ADestination, ACountBytes: Integer);
  begin
    Check(ASource, ACountBytes);
    Check(ADestination, ACountBytes);
    System.Move(LBuffer[ASource], LBuffer[ADestination], ACountBytes);
  end;

begin
  Result := '';
  if FWrap then
  begin
    Result := inherited HandleEvent(AEvent, AUpdateVisuals);
    if Result <> '' then
      Exit;
  end;
  if (AEvent.EventType <> GUI_SE_CHAR) and (AEvent.EventType <> GUI_SE_KEY) then
    Exit;
  // the buffer is static in the original: what an earlier event left behind stays after the end of the text
  LBuffer := Context.EditBuffer;
  LCount := Length(Text.AsText);
  if LCount > MAX_EDITFIELD - 1 then
    LCount := MAX_EDITFIELD - 1;
  if LCount > 0 then
    System.Move(Text.AsText[1], LBuffer[0], LCount);
  LBuffer[LCount] := 0;
  LKey := AEvent.Value;
  LLength := Text.Length;
  if AEvent.EventType = GUI_SE_CHAR then
  begin
    if (AEvent.Value = Context.ConsoleKey) or (AEvent.Value = Context.ConsoleKeyShifted) then
      Exit('');
    AUpdateVisuals := True;
    if (FMaxChars <> 0) and (LLength > FMaxChars) then
      LLength := FMaxChars;
    if ((LKey = GUI_K_ENTER) or (LKey = GUI_K_KP_ENTER)) and (AEvent.Value2 <> 0) then
    begin
      RunScript(seAction);
      RunScript(seEnter);
      Exit(Command);
    end;
    if LKey = GUI_K_ESCAPE then
    begin
      RunScript(seEsc);
      Exit(Command);
    end;
    if FReadOnly then
      Exit('');
    if (LKey = Ord('h') - Ord('a') + 1) or (LKey = GUI_K_BACKSPACE) then
    begin
      if FCursorPos > 0 then
      begin
        if FCursorPos >= LLength then
        begin
          Check(LLength - 1, 1);
          LBuffer[LLength - 1] := 0;
          FCursorPos := LLength - 1;
        end
        else
        begin
          Move(FCursorPos, FCursorPos - 1, LLength + 1 - FCursorPos);
          Dec(FCursorPos);
        end;
        Text.Value := TextOfBuffer;
        UpdateCvar(False);
        RunScript(seAction);
      end;
      Exit('');
    end;
    if FWrap and ((LKey = GUI_K_ENTER) or (LKey = GUI_K_KP_ENTER)) then
    begin
    end
    else if not TIdStrings.CharIsPrintable(LKey) then
      Exit('');
    if FNumeric then
      if ((LKey < Ord('0')) or (LKey > Ord('9'))) and (LKey <> Ord('.')) then
        Exit('');
    if Assigned(Context.DrawContext) and Context.DrawContext.OverStrike then
    begin
      if (FMaxChars <> 0) and (FCursorPos >= FMaxChars) then
        Exit('');
    end
    else
    begin
      if (LLength = MAX_EDITFIELD - 1) or ((FMaxChars <> 0) and (LLength >= FMaxChars)) then
        Exit('');
      Move(FCursorPos, FCursorPos + 1, LLength + 1 - FCursorPos);
    end;
    Check(FCursorPos, 1);
    LBuffer[FCursorPos] := Byte(LKey and $FF);
    Text.Value := TextOfBuffer;
    UpdateCvar(False);
    RunScript(seAction);
    if FCursorPos < LLength + 1 then
      Inc(FCursorPos);
    EnsureCursorVisible;
  end
  else if AEvent.Value2 <> 0 then
  begin
    AUpdateVisuals := True;
    if LKey = GUI_K_DEL then
    begin
      if FReadOnly then
        Exit(Result);
      if FCursorPos < LLength then
      begin
        Move(FCursorPos + 1, FCursorPos, LLength - FCursorPos);
        Text.Value := TextOfBuffer;
        UpdateCvar(False);
        RunScript(seAction);
      end;
      Exit(Result);
    end;
    if LKey = GUI_K_RIGHTARROW then
    begin
      if FCursorPos < LLength then
      begin
        if CtrlDown then
        begin
          while (FCursorPos < LLength) and (LBuffer[FCursorPos] <> Ord(' ')) do
            Inc(FCursorPos);
          while (FCursorPos < LLength) and (LBuffer[FCursorPos] = Ord(' ')) do
            Inc(FCursorPos);
        end
        else if FCursorPos < LLength then
          Inc(FCursorPos);
      end;
      EnsureCursorVisible;
      Exit(Result);
    end;
    if LKey = GUI_K_LEFTARROW then
    begin
      if CtrlDown then
      begin
        while (FCursorPos > 0) and (LBuffer[FCursorPos - 1] = Ord(' ')) do
          Dec(FCursorPos);
        while (FCursorPos > 0) and (LBuffer[FCursorPos - 1] <> Ord(' ')) do
          Dec(FCursorPos);
      end
      else if FCursorPos > 0 then
        Dec(FCursorPos);
      EnsureCursorVisible;
      Exit(Result);
    end;
    if LKey = GUI_K_HOME then
    begin
      if CtrlDown or (FCursorLine <= 0) or (FCursorLine >= FBreaks.Count) then
        FCursorPos := 0
      else
        FCursorPos := FBreaks[FCursorLine];
      EnsureCursorVisible;
      Exit(Result);
    end;
    if LKey = GUI_K_END then
    begin
      if CtrlDown or (FCursorLine < -1) or (FCursorLine >= FBreaks.Count - 1) then
        FCursorPos := LLength
      else
        FCursorPos := FBreaks[FCursorLine + 1] - 1;
      EnsureCursorVisible;
      Exit(Result);
    end;
    if LKey = GUI_K_INS then
    begin
      if (not FReadOnly) and Assigned(Context.DrawContext) then
        Context.DrawContext.OverStrike := not Context.DrawContext.OverStrike;
      Exit(Result);
    end;
    if LKey = GUI_K_DOWNARROW then
    begin
      if CtrlDown then
        FScroller.SetValue(FScroller.GetValue + 1.0)
      else if FCursorLine < FBreaks.Count - 1 then
      begin
        LOffset := FCursorPos - FBreaks[FCursorLine];
        FCursorPos := FBreaks[FCursorLine + 1] + LOffset;
        EnsureCursorVisible;
      end;
    end;
    if LKey = GUI_K_UPARROW then
    begin
      if CtrlDown then
        FScroller.SetValue(FScroller.GetValue - 1.0)
      else if FCursorLine > 0 then
      begin
        LOffset := FCursorPos - FBreaks[FCursorLine];
        FCursorPos := FBreaks[FCursorLine - 1] + LOffset;
        EnsureCursorVisible;
      end;
    end;
    if (LKey = GUI_K_ENTER) or (LKey = GUI_K_KP_ENTER) then
    begin
      RunScript(seAction);
      RunScript(seEnter);
      Exit(Command);
    end;
    if LKey = GUI_K_ESCAPE then
    begin
      RunScript(seEsc);
      Exit(Command);
    end;
  end
  else
  begin
    if (LKey = GUI_K_ENTER) or (LKey = GUI_K_KP_ENTER) then
    begin
      RunScript(seEnterRelease);
      Exit(Command);
    end
    else
      RunScript(seActionRelease);
  end;
end;
end.
