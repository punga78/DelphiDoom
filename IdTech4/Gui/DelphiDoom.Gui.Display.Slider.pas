{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - sliders                                           }
{                                                                              }
{  Item_Slider_ThumbPosition, _OverSlider, _HandleKey and Scroll_Slider_       }
{  ThumbFunc of ui_shared.c (Quake III Arena, id Software, GPL v2 or later).   }
{  SLIDER_WIDTH is a double constant in the original: the arithmetic that      }
{  touches it is done in double. Based on the Quake III Arena GPL Source Code  }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.Slider;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Menu, DelphiDoom.Gui.Display.State;

type
  /// <summary>The behaviour of a slider item: the thumb, a click, the drag</summary>
  TGuiSliderLogic = class
  strict private
    FState: TGuiDisplayState;
    function BaseX(const AItem: TGuiItem): Single;
    function CvarValue(const AName: AnsiString): Single;
    procedure SetCvarValue(const AItem: TGuiItem; const AValue: Single);
  public
    constructor Create(const AState: TGuiDisplayState);
    /// <summary>Item_Slider_ThumbPosition: the x of the thumb</summary>
    function ThumbPosition(const AItem: TGuiItem): Single;
    /// <summary>Item_Slider_OverSlider: WINDOW_LB_THUMB over the thumb, 0 elsewhere</summary>
    function OverSlider(const AItem: TGuiItem; const AX, AY: Single): Integer;
    /// <summary>Item_Slider_HandleKey: a click or enter on the slider sets the cvar from the cursor</summary>
    function HandleKey(const AItem: TGuiItem; const AKey: Integer; const ADown: Boolean): Boolean;
    /// <summary>Scroll_Slider_ThumbFunc: the drag of the thumb</summary>
    procedure DragThumb;
  end;

implementation

uses
  DelphiDoom.Gui.Keys, DelphiDoom.Gui.Display.FloatMask;

constructor TGuiSliderLogic.Create(const AState: TGuiDisplayState);
begin
  inherited Create;
  FState := AState;
end;

function TGuiSliderLogic.BaseX(const AItem: TGuiItem): Single;
var
  LSum: Single;
begin
  if AItem.Text <> '' then
  begin
    LSum := AItem.TextRect.X + AItem.TextRect.W;
    Result := LSum + 8;
  end
  else
    Result := AItem.Window.Rect.X;
end;

function TGuiSliderLogic.CvarValue(const AName: AnsiString): Single;
begin
  if Assigned(FState.Script) then
    Result := FState.Script.GetCvarValue(AName)
  else
    Result := 0;
end;

procedure TGuiSliderLogic.SetCvarValue(const AItem: TGuiItem; const AValue: Single);
begin
  if Assigned(FState.Script) then
    FState.Script.SetCvar(AItem.Cvar, AnsiString(Format('%.6f', [Double(AValue)], TFormatSettings.Invariant)));
end;

function TGuiSliderLogic.ThumbPosition(const AItem: TGuiItem): Single;
var
  LValue, LRange: Single;
  LMask: IInterface;
begin
  LMask := TGuiFloatMask.Enter;
  Result := BaseX(AItem);
  // editDef == NULL && cvar: the position of the left end
  if (AItem.DataKind <> gdkEditField) and (AItem.Cvar <> '') then
    Exit;
  LValue := CvarValue(AItem.Cvar);
  if LValue < AItem.EditField.MinVal then
    LValue := AItem.EditField.MinVal
  else if LValue > AItem.EditField.MaxVal then
    LValue := AItem.EditField.MaxVal;
  LRange := AItem.EditField.MaxVal - AItem.EditField.MinVal;
  LValue := LValue - AItem.EditField.MinVal;
  LValue := LValue / LRange;
  LValue := Double(LValue) * GUI_SLIDER_WIDTH;
  Result := Double(Result) + Double(LValue);
end;

function TGuiSliderLogic.OverSlider(const AItem: TGuiItem; const AX, AY: Single): Integer;
var
  LRect: TGuiRect;
begin
  LRect.X := Double(ThumbPosition(AItem)) - GUI_SLIDER_THUMB_WIDTH / 2;
  LRect.Y := AItem.Window.Rect.Y - 2;
  LRect.W := GUI_SLIDER_THUMB_WIDTH;
  LRect.H := GUI_SLIDER_THUMB_HEIGHT;
  if TGuiDisplayState.RectContains(LRect, AX, AY) then
    Result := WINDOW_LB_THUMB
  else
    Result := 0;
end;

function TGuiSliderLogic.HandleKey(const AItem: TGuiItem; const AKey: Integer; const ADown: Boolean): Boolean;
var
  LX, LValue, LWork: Single;
  LTest: TGuiRect;
  LMask: IInterface;
begin
  Result := False;
  LMask := TGuiFloatMask.Enter;
  if ((AItem.Window.Flags and WINDOW_HASFOCUS) <> 0) and (AItem.Cvar <> '') and
    TGuiDisplayState.RectContains(AItem.Window.Rect, FState.CursorX, FState.CursorY) then
  begin
    if (AKey = K_MOUSE1) or (AKey = K_ENTER) or (AKey = K_MOUSE2) or (AKey = K_MOUSE3) then
    begin
      if AItem.DataKind = gdkEditField then
      begin
        LX := BaseX(AItem);
        LTest := AItem.Window.Rect;
        LTest.X := LX;
        LValue := GUI_SLIDER_THUMB_WIDTH / 2;
        LTest.X := LTest.X - LValue;
        LTest.W := GUI_SLIDER_WIDTH + GUI_SLIDER_THUMB_WIDTH / 2;
        if TGuiDisplayState.RectContains(LTest, FState.CursorX, FState.CursorY) then
        begin
          LWork := FState.Input.CursorX - LX;
          LValue := LWork / GUI_SLIDER_WIDTH;
          LValue := LValue * (AItem.EditField.MaxVal - AItem.EditField.MinVal);
          LValue := LValue + AItem.EditField.MinVal;
          SetCvarValue(AItem, LValue);
          Exit(True);
        end;
      end;
    end;
  end;
  // the original leaves a debug line here, for every key the slider does not use
  FState.Input.Print('slider handle key exit'#10);
end;

procedure TGuiSliderLogic.DragThumb;
var
  LX, LValue, LCursor: Single;
  LItem: TGuiItem;
  LMask: IInterface;
begin
  LMask := TGuiFloatMask.Enter;
  LItem := FState.ScrollInfo.Item;
  LX := BaseX(LItem);
  LCursor := FState.Input.CursorX;
  if LCursor < LX then
    LCursor := LX
  else if LCursor > Double(LX) + GUI_SLIDER_WIDTH then
    LCursor := Double(LX) + GUI_SLIDER_WIDTH;
  LValue := LCursor - LX;
  LValue := LValue / GUI_SLIDER_WIDTH;
  LValue := LValue * (LItem.EditField.MaxVal - LItem.EditField.MinVal);
  LValue := LValue + LItem.EditField.MinVal;
  SetCvarValue(LItem, LValue);
end;

end.
