{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiSliderWindow (sliderDef)                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\SliderWindow.h,         }
{  SliderWindow.cpp (idSliderWindow: the parse). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Slider;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Float, DelphiDoom.Gui.WinVar.Str,
  DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.Window.Keys, DelphiDoom.IdLib.Math.Vec4;

type
  /// <summary>
  ///   idSliderWindow: the keys <c>step</c> (<c>stepsize</c>), <c>low</c>, <c>high</c>, <c>vertical</c>,
  ///   <c>verticalflip</c>, <c>scrollbar</c>, <c>thumbshader</c> and the variables <c>value</c>, <c>cvar</c>,
  ///   <c>liveUpdate</c>, <c>cvarGroup</c>. Not ported: the thumb material size, the cvar and the mouse.
  /// </summary>
  TGuiSliderWindow = class(TGuiWindow)
  strict private
    FLow: Single;
    FHigh: Single;
    FStepSize: Single;
    FVertical: Boolean;
    FVerticalFlip: Boolean;
    FScrollbar: Boolean;
    FThumbShader: AnsiString;
    FValue: TGuiWinFloat;
    FCvarStr: TGuiWinStr;
    FCvarGroup: TGuiWinStr;
    FLiveUpdate: TGuiWinBool;
    FThumbMat: IGuiMaterial;
    FThumbWidth: Single;
    FThumbHeight: Single;
    FThumbRect: TGuiRectangle;
    FBuddy: TGuiWindow;
    FHasCvar: Boolean;
    FCvarInit: Boolean;
    procedure InitCvar;
    procedure UpdateCvar(const ARead: Boolean; const AForce: Boolean = False);
    procedure FindThumb;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    procedure SetBuddy(const ABuddy: TGuiWindow); override;
    /// <summary>idSliderWindow::SetRange and SetValue (the list and edit windows drive their scroll bar with them)</summary>
    procedure SetRange(const ALow, AHigh, AStep: Single);
    procedure InitWithDefaults(const AName: AnsiString; const ARect: TGuiRectangle; const AForeColor, AMatColor: TIdVec4;
      const ABackground, AThumbShader: AnsiString; const AVertical, AScrollbar: Boolean);
    function GetValue: Single;
    function GetHigh: Single;
    procedure SetValue(const AValue: Single);
    function HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString; override;
    function RouteMouseCoords(const AX, AY: Single): AnsiString; override;
    procedure Draw(const ATime: Integer; const AX, AY: Single); override;
    procedure DrawBackground(const ARect: TGuiRectangle); override;
    procedure Activate(const AActivate: Boolean; var AAct: AnsiString); override;
    procedure RunNamedEvent(const AEventName: AnsiString); override;
    property ThumbRect: TGuiRectangle read FThumbRect;
    property HasCvar: Boolean read FHasCvar;
    property Low: Single read FLow;
    property High: Single read FHigh;
    property StepSize: Single read FStepSize;
    property Vertical: Boolean read FVertical;
    property VerticalFlip: Boolean read FVerticalFlip;
    property Scrollbar: Boolean read FScrollbar;
    property ThumbShader: AnsiString read FThumbShader;
    property Value: TGuiWinFloat read FValue;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Gui.DrawContext;

constructor TGuiSliderWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FValue := TGuiWinFloat.Create;
  FCvarStr := TGuiWinStr.Create;
  FCvarGroup := TGuiWinStr.Create;
  FLiveUpdate := TGuiWinBool.Create;
  FValue.Value := 0.0;
  FLow := 0.0;
  FHigh := 100.0;
  FStepSize := 1.0;
  FLiveUpdate.Value := True;
end;

destructor TGuiSliderWindow.Destroy;
begin
  FLiveUpdate.Free;
  FCvarGroup.Free;
  FCvarStr.Free;
  FValue.Free;
  inherited Destroy;
end;

function TGuiSliderWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if (TIdStrings.Icmp(AName, 'stepsize') = 0) or (TIdStrings.Icmp(AName, 'step') = 0) then
    FStepSize := ASource.ParseFloat
  else if TIdStrings.Icmp(AName, 'low') = 0 then
    FLow := ASource.ParseFloat
  else if TIdStrings.Icmp(AName, 'high') = 0 then
    FHigh := ASource.ParseFloat
  else if TIdStrings.Icmp(AName, 'vertical') = 0 then
    FVertical := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'verticalflip') = 0 then
    FVerticalFlip := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'scrollbar') = 0 then
    FScrollbar := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'thumbshader') = 0 then
    ParseString(ASource, FThumbShader)
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

function TGuiSliderWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
begin
  AOwner := nil;
  if TIdStrings.Icmp(AName, 'value') = 0 then
    Exit(FValue);
  if TIdStrings.Icmp(AName, 'cvar') = 0 then
    Exit(FCvarStr);
  if TIdStrings.Icmp(AName, 'liveUpdate') = 0 then
    Exit(FLiveUpdate);
  if TIdStrings.Icmp(AName, 'cvarGroup') = 0 then
    Exit(FCvarGroup);
  Result := inherited GetWinVarByName(AName, AFixup, AOwner);
end;

procedure TGuiSliderWindow.FindThumb;
begin
  if Assigned(Context.Materials) then
  begin
    FThumbMat := Context.Materials.FindMaterial(FThumbShader);
    FThumbMat.SetGuiSort;
    FThumbWidth := FThumbMat.GetImageWidth;
    FThumbHeight := FThumbMat.GetImageHeight;
  end;
end;

procedure TGuiSliderWindow.PostParse;
begin
  inherited PostParse;
  FValue.Value := 0.0;
  FindThumb;
  SetFlag(WIN_HOLDCAPTURE or WIN_CANFOCUS);
  InitCvar;
end;

procedure TGuiSliderWindow.InitCvar;
begin
  if FCvarStr.AsText = '' then
  begin
    if not Assigned(FBuddy) then
      Warning(Format('idSliderWindow::InitCvar: gui ''%s'' window ''%s'' has an empty cvar string',
        [string(Context.SourceFile), string(Name)]));
    FCvarInit := True;
    FHasCvar := False;
    Exit;
  end;
  FHasCvar := Assigned(Context.Cvars) and Context.Cvars.Exists(FCvarStr.AsText);
  if not FHasCvar then
  begin
    Warning(Format('idSliderWindow::InitCvar: gui ''%s'' window ''%s'' references undefined cvar ''%s''',
      [string(Context.SourceFile), string(Name), string(FCvarStr.AsText)]));
    FCvarInit := True;
  end;
end;

procedure TGuiSliderWindow.UpdateCvar(const ARead: Boolean; const AForce: Boolean);
var
  LState: Single;
begin
  if Assigned(FBuddy) or (not FHasCvar) then
    Exit;
  if AForce or FLiveUpdate.Value then
  begin
    FValue.Value := Context.Cvars.GetFloat(FCvarStr.AsText);
    LState := Context.StateDict.GetFloat(FCvarStr.AsText);
    if FValue.Value <> LState then
    begin
      if ARead then
        Context.StateDict.SetFloat(FCvarStr.AsText, FValue.Value)
      else
      begin
        FValue.Value := Context.StateDict.GetFloat(FCvarStr.AsText);
        Context.Cvars.SetFloat(FCvarStr.AsText, FValue.Value);
      end;
    end;
  end;
end;

procedure TGuiSliderWindow.SetBuddy(const ABuddy: TGuiWindow);
begin
  FBuddy := ABuddy;
end;

procedure TGuiSliderWindow.SetRange(const ALow, AHigh, AStep: Single);
begin
  FLow := ALow;
  FHigh := AHigh;
  FStepSize := AStep;
end;

procedure TGuiSliderWindow.InitWithDefaults(const AName: AnsiString; const ARect: TGuiRectangle; const AForeColor,
  AMatColor: TIdVec4; const ABackground, AThumbShader: AnsiString; const AVertical, AScrollbar: Boolean);
begin
  SetInitialState(AName);
  Rect.Value := ARect;
  ForeColor.Value := AForeColor;
  MatColor.Value := AMatColor;
  if Assigned(Context.Materials) then
  begin
    FThumbMat := Context.Materials.FindMaterial(AThumbShader);
    FThumbMat.SetGuiSort;
    FThumbWidth := FThumbMat.GetImageWidth;
    FThumbHeight := FThumbMat.GetImageHeight;
    SetBackgroundMaterial(Context.Materials.FindMaterial(ABackground));
    GetBackground.SetGuiSort;
  end;
  FVertical := AVertical;
  FScrollbar := AScrollbar;
  SetFlag(WIN_HOLDCAPTURE);
end;

function TGuiSliderWindow.GetValue: Single;
begin
  Result := FValue.Value;
end;

function TGuiSliderWindow.GetHigh: Single;
begin
  Result := FHigh;
end;

procedure TGuiSliderWindow.SetValue(const AValue: Single);
begin
  FValue.Value := AValue;
end;

function TGuiSliderWindow.HandleEvent(const AEvent: TGuiSysEvent; var AUpdateVisuals: Boolean): AnsiString;
var
  LKey: Integer;
begin
  Result := '';
  if not ((AEvent.EventType = GUI_SE_KEY) and (AEvent.Value2 <> 0)) then
    Exit;
  LKey := AEvent.Value;
  if (AEvent.Value2 <> 0) and (LKey = GUI_K_MOUSE1) then
  begin
    SetCapture(Self);
    RouteMouseCoords(0.0, 0.0);
    Exit;
  end;
  if (LKey = GUI_K_RIGHTARROW) or (LKey = GUI_K_KP_RIGHTARROW) or
    ((LKey = GUI_K_MOUSE2) and (Context.CursorY > FThumbRect.Y)) then
    FValue.Value := FValue.Value + FStepSize;
  if (LKey = GUI_K_LEFTARROW) or (LKey = GUI_K_KP_LEFTARROW) or
    ((LKey = GUI_K_MOUSE2) and (Context.CursorY < FThumbRect.Y)) then
    FValue.Value := FValue.Value - FStepSize;
  if Assigned(FBuddy) then
    FBuddy.HandleBuddyUpdate(Self)
  else
  begin
    Context.StateDict.SetFloat(FCvarStr.AsText, FValue.Value);
    UpdateCvar(False);
  end;
end;

procedure TGuiSliderWindow.Draw(const ATime: Integer; const AX, AY: Single);
var
  LColor: TIdVec4;
  LRange, LThumbPos, LTemp: Single;
  LDc: TGuiDrawContext;
begin
  LColor := ForeColor.Value;
  LDc := Context.DrawContext;
  if (not FHasCvar) and (not Assigned(FBuddy)) then
    Exit;
  if (FThumbWidth = 0.0) or (FThumbHeight = 0.0) then
  begin
    FThumbWidth := FThumbMat.GetImageWidth;
    FThumbHeight := FThumbMat.GetImageHeight;
  end;
  UpdateCvar(True);
  if FValue.Value > FHigh then
    FValue.Value := FHigh
  else if FValue.Value < FLow then
    FValue.Value := FLow;
  LRange := FHigh - FLow;
  if LRange <= 0.0 then
    Exit;
  LTemp := FValue.Value - FLow;
  LThumbPos := LTemp / LRange;
  if FVertical then
  begin
    if FVerticalFlip then
      LThumbPos := 1.0 - LThumbPos;
    LTemp := DrawRect.H - FThumbHeight;
    LThumbPos := LThumbPos * LTemp;
    LThumbPos := LThumbPos + DrawRect.Y;
    FThumbRect.Y := LThumbPos;
    FThumbRect.X := DrawRect.X;
  end
  else
  begin
    LTemp := DrawRect.W - FThumbWidth;
    LThumbPos := LThumbPos * LTemp;
    LThumbPos := LThumbPos + DrawRect.X;
    FThumbRect.X := LThumbPos;
    FThumbRect.Y := DrawRect.Y;
  end;
  FThumbRect.W := FThumbWidth;
  FThumbRect.H := FThumbHeight;
  if Hover and (not NoEvents.Value) and ContainsPoint(Context.CursorX, Context.CursorY) then
    LColor := HoverColor.Value
  else
    Hover := False;
  if (Flags and WIN_CAPTURE) <> 0 then
  begin
    LColor := HoverColor.Value;
    Hover := True;
  end;
  LDc.DrawMaterial(FThumbRect.X, FThumbRect.Y, FThumbRect.W, FThumbRect.H, FThumbMat, LColor);
  if (Flags and WIN_FOCUS) <> 0 then
  begin
    LDc.DrawRect(FThumbRect.X + 1.0, FThumbRect.Y + 1.0, FThumbRect.W - 2.0, FThumbRect.H - 2.0, 1.0, LColor);
  end;
end;

procedure TGuiSliderWindow.DrawBackground(const ARect: TGuiRectangle);
var
  LRect: TGuiRectangle;
  LHalf: Single;
begin
  if (not FHasCvar) and (not Assigned(FBuddy)) then
    Exit;
  if FHigh - FLow <= 0.0 then
    Exit;
  LRect := ARect;
  if not FScrollbar then
  begin
    if FVertical then
    begin
      LHalf := FThumbHeight / 2.0;
      LRect.Y := LRect.Y + LHalf;
      LRect.H := LRect.H - FThumbHeight;
    end
    else
    begin
      LHalf := FThumbWidth / 2.0;
      LRect.X := LRect.X + LHalf;
      LRect.W := LRect.W - FThumbWidth;
    end;
  end;
  inherited DrawBackground(LRect);
end;

function TGuiSliderWindow.RouteMouseCoords(const AX, AY: Single): AnsiString;
var
  LRect: TGuiRectangle;
  LPct, LHalf, LTemp: Single;
begin
  Result := '';
  if (Flags and WIN_CAPTURE) = 0 then
    Exit;
  LRect := DrawRect;
  LRect.X := ActualX;
  LRect.Y := ActualY;
  LHalf := FThumbWidth / 2.0;
  LRect.X := LRect.X + LHalf;
  LRect.W := LRect.W - FThumbWidth;
  if FVertical then
  begin
    LHalf := FThumbHeight / 2;
    LRect.Y := LRect.Y + LHalf;
    LRect.H := LRect.H - FThumbHeight;
    if (Context.CursorY >= LRect.Y) and (Context.CursorY <= LRect.Bottom) then
    begin
      LTemp := Context.CursorY - LRect.Y;
      LPct := LTemp / LRect.H;
      if FVerticalFlip then
        LPct := 1.0 - LPct;
      LTemp := FHigh - FLow;
      LTemp := LTemp * LPct;
      FValue.Value := FLow + LTemp;
    end
    else if Context.CursorY < LRect.Y then
    begin
      if FVerticalFlip then
        FValue.Value := FHigh
      else
        FValue.Value := FLow;
    end
    else if FVerticalFlip then
      FValue.Value := FLow
    else
      FValue.Value := FHigh;
  end
  else
  begin
    LHalf := FThumbWidth / 2;
    LRect.X := LRect.X + LHalf;
    LRect.W := LRect.W - FThumbWidth;
    if (Context.CursorX >= LRect.X) and (Context.CursorX <= LRect.Right) then
    begin
      LTemp := Context.CursorX - LRect.X;
      LPct := LTemp / LRect.W;
      LTemp := FHigh - FLow;
      LTemp := LTemp * LPct;
      FValue.Value := FLow + LTemp;
    end
    else if Context.CursorX < LRect.X then
      FValue.Value := FLow
    else
      FValue.Value := FHigh;
  end;
  if Assigned(FBuddy) then
    FBuddy.HandleBuddyUpdate(Self)
  else
    Context.StateDict.SetFloat(FCvarStr.AsText, FValue.Value);
  UpdateCvar(False);
end;

procedure TGuiSliderWindow.Activate(const AActivate: Boolean; var AAct: AnsiString);
begin
  inherited Activate(AActivate, AAct);
  if AActivate then
    UpdateCvar(True, True);
end;

procedure TGuiSliderWindow.RunNamedEvent(const AEventName: AnsiString);
var
  LGroup: AnsiString;
begin
  if TIdStrings.Icmpn(AEventName, 'cvar read ', 10) = 0 then
  begin
    LGroup := Copy(AEventName, 11, MaxInt);
    if LGroup = FCvarGroup.AsText then
      UpdateCvar(True, True);
  end
  else if TIdStrings.Icmpn(AEventName, 'cvar write ', 11) = 0 then
  begin
    LGroup := Copy(AEventName, 12, MaxInt);
    if LGroup = FCvarGroup.AsText then
      UpdateCvar(False, True);
  end;
end;
end.
