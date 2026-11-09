{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - InteractiveSurface of OpenXcom            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.InteractiveSurface;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Widget;

type
  /// <summary>The handler of an action (ActionHandler: a method of the state; here a closure of the state)</summary>
  TXcomActionHandler = reference to procedure(AAction: TXcomAction);

  /// <summary>
  ///   A surface that reacts to the mouse and the keyboard: it keeps the handlers (per mouse button and per key),
  ///   knows if the mouse is over it and which buttons are down, and calls the handlers when the actions say so
  /// </summary>
  TXcomInteractiveSurface = class(TXcomWidget)
  strict private
    FClick: TDictionary<Integer, TXcomActionHandler>;
    FPress: TDictionary<Integer, TXcomActionHandler>;
    FRelease: TDictionary<Integer, TXcomActionHandler>;
    FIn: TXcomActionHandler;
    FOver: TXcomActionHandler;
    FOut: TXcomActionHandler;
    FKeyPress: TDictionary<Integer, TXcomActionHandler>;
    FKeyRelease: TDictionary<Integer, TXcomActionHandler>;
    FButtonsPressed: Integer;
    FHovered: Boolean;
    FFocused: Boolean;
    FListButton: Boolean;
    procedure CallHandlers(AHandlers: TDictionary<Integer, TXcomActionHandler>; AAction: TXcomAction);
    procedure CallKeyHandlers(AHandlers: TDictionary<Integer, TXcomActionHandler>; AAction: TXcomAction);
    function ButtonMask(AButton: Integer): Integer; inline;
  protected
    procedure SetVisible(AValue: Boolean); override;
    procedure MousePress(AAction: TXcomAction); virtual;
    procedure MouseRelease(AAction: TXcomAction); virtual;
    procedure MouseClick(AAction: TXcomAction); virtual;
    procedure MouseIn(AAction: TXcomAction); virtual;
    procedure MouseOver(AAction: TXcomAction); virtual;
    procedure MouseOut(AAction: TXcomAction); virtual;
    procedure KeyboardPress(AAction: TXcomAction); virtual;
    procedure KeyboardRelease(AAction: TXcomAction); virtual;
    property ButtonsPressed: Integer read FButtonsPressed write FButtonsPressed;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    /// <summary>
    ///   InteractiveSurface::isButtonHandled: some handler is set for the button (or for any button when 0)
    /// </summary>
    function IsButtonHandled(AButton: Integer = 0): Boolean; virtual;
    function IsButtonPressed(AButton: Integer = 0): Boolean;
    procedure SetButtonPressed(AButton: Integer; APressed: Boolean);
    /// <summary>InteractiveSurface::handle: decides what the action means for this surface and calls the handlers</summary>
    procedure Handle(AAction: TXcomAction); virtual;
    procedure SetFocus(AFocus: Boolean); virtual;
    function IsFocused: Boolean;
    /// <summary>InteractiveSurface::unpress: releases a pressed button without a real release event</summary>
    procedure Unpress; virtual;
    procedure OnMouseClick(const AHandler: TXcomActionHandler; AButton: Integer = XCOM_BUTTON_LEFT);
    procedure OnMousePress(const AHandler: TXcomActionHandler; AButton: Integer = XCOM_BUTTON_LEFT);
    procedure OnMouseRelease(const AHandler: TXcomActionHandler; AButton: Integer = XCOM_BUTTON_LEFT);
    procedure OnMouseIn(const AHandler: TXcomActionHandler);
    procedure OnMouseOver(const AHandler: TXcomActionHandler);
    procedure OnMouseOut(const AHandler: TXcomActionHandler);
    /// <summary>A key of 0 (SDLK_UNKNOWN) is ignored; XCOM_KEY_ANY catches every key</summary>
    procedure OnKeyboardPress(const AHandler: TXcomActionHandler; AKey: Integer = XCOM_KEY_ANY);
    procedure OnKeyboardRelease(const AHandler: TXcomActionHandler; AKey: Integer = XCOM_KEY_ANY);
    /// <summary>InteractiveSurface::setListButton: the surface tracks the buttons while the mouse moves over it</summary>
    procedure SetListButton;
    function IsHovered: Boolean;
  end;

implementation

constructor TXcomInteractiveSurface.Create(AWidth, AHeight, AX, AY: Integer);
begin
  inherited Create(AWidth, AHeight, AX, AY);
  FClick := TDictionary<Integer, TXcomActionHandler>.Create;
  FPress := TDictionary<Integer, TXcomActionHandler>.Create;
  FRelease := TDictionary<Integer, TXcomActionHandler>.Create;
  FKeyPress := TDictionary<Integer, TXcomActionHandler>.Create;
  FKeyRelease := TDictionary<Integer, TXcomActionHandler>.Create;
  FFocused := True;
end;

destructor TXcomInteractiveSurface.Destroy;
begin
  FKeyRelease.Free;
  FKeyPress.Free;
  FRelease.Free;
  FPress.Free;
  FClick.Free;
  inherited Destroy;
end;

function TXcomInteractiveSurface.ButtonMask(AButton: Integer): Integer;
begin
  Result := 1 shl (AButton - 1);
end;

function TXcomInteractiveSurface.IsButtonHandled(AButton: Integer): Boolean;
begin
  Result := FClick.ContainsKey(0) or FPress.ContainsKey(0) or FRelease.ContainsKey(0);
  if (not Result) and (AButton <> 0) then
    Result := FClick.ContainsKey(AButton) or FPress.ContainsKey(AButton) or FRelease.ContainsKey(AButton);
end;

function TXcomInteractiveSurface.IsButtonPressed(AButton: Integer): Boolean;
begin
  if AButton = 0 then
    Result := FButtonsPressed <> 0
  else
    Result := (FButtonsPressed and ButtonMask(AButton)) <> 0;
end;

procedure TXcomInteractiveSurface.SetButtonPressed(AButton: Integer; APressed: Boolean);
begin
  if APressed then
    FButtonsPressed := FButtonsPressed or ButtonMask(AButton)
  else
    FButtonsPressed := FButtonsPressed and not ButtonMask(AButton);
end;

procedure TXcomInteractiveSurface.SetVisible(AValue: Boolean);
begin
  inherited SetVisible(AValue);
  if not Visible then
    Unpress;
end;

procedure TXcomInteractiveSurface.Handle(AAction: TXcomAction);
var
  LDetails: PXcomInputEvent;
  LButton: Integer;
  LInside: Boolean;
begin
  if (not Visible) or Hidden then
    Exit;
  AAction.Sender := Self;
  LDetails := AAction.Details;
  if LDetails^.Kind in [ekMouseUp, ekMouseDown, ekMouseMotion] then
    AAction.SetMouseAction(LDetails^.X, LDetails^.Y, X, Y);
  if AAction.IsMouseAction then
  begin
    LInside := (AAction.AbsoluteXMouse >= X) and (AAction.AbsoluteXMouse < X + Width) and
      (AAction.AbsoluteYMouse >= Y) and (AAction.AbsoluteYMouse < Y + Height);
    if LInside then
    begin
      if not FHovered then
      begin
        FHovered := True;
        MouseIn(AAction);
      end;
      if FListButton and (LDetails^.Kind = ekMouseMotion) then
      begin
        FButtonsPressed := AAction.ButtonMask;
        for LButton := 1 to XCOM_BUTTON_COUNT do
          if IsButtonPressed(LButton) then
          begin
            LDetails^.Button := LButton;
            MousePress(AAction);
          end;
      end;
      MouseOver(AAction);
    end
    else if FHovered then
    begin
      FHovered := False;
      MouseOut(AAction);
      if FListButton and (LDetails^.Kind = ekMouseMotion) then
        for LButton := 1 to XCOM_BUTTON_COUNT do
        begin
          if IsButtonPressed(LButton) then
            SetButtonPressed(LButton, False);
          LDetails^.Button := LButton;
          MouseRelease(AAction);
        end;
    end;
  end;
  if LDetails^.Kind = ekMouseDown then
  begin
    if FHovered and not IsButtonPressed(LDetails^.Button) then
    begin
      SetButtonPressed(LDetails^.Button, True);
      MousePress(AAction);
    end;
  end
  else if LDetails^.Kind = ekMouseUp then
  begin
    if IsButtonPressed(LDetails^.Button) then
    begin
      SetButtonPressed(LDetails^.Button, False);
      MouseRelease(AAction);
      if FHovered then
        MouseClick(AAction);
    end;
  end;
  if FFocused then
  begin
    if LDetails^.Kind = ekKeyDown then
      KeyboardPress(AAction)
    else if LDetails^.Kind = ekKeyUp then
      KeyboardRelease(AAction);
  end;
end;

procedure TXcomInteractiveSurface.SetFocus(AFocus: Boolean);
begin
  FFocused := AFocus;
end;

function TXcomInteractiveSurface.IsFocused: Boolean;
begin
  Result := FFocused;
end;

procedure TXcomInteractiveSurface.Unpress;
var
  LEvent: TXcomInputEvent;
  LAction: TXcomAction;
begin
  if IsButtonPressed then
  begin
    FButtonsPressed := 0;
    LEvent := TXcomInputEvent.Make(ekMouseUp);
    LEvent.Button := XCOM_BUTTON_LEFT;
    LAction := TXcomAction.Create(LEvent, 0.0, 0.0, 0, 0);
    try
      MouseRelease(LAction);
    finally
      LAction.Free;
    end;
  end;
end;

procedure TXcomInteractiveSurface.CallHandlers(AHandlers: TDictionary<Integer, TXcomActionHandler>;
  AAction: TXcomAction);
var
  LHandler: TXcomActionHandler;
begin
  // the handler of "any button" runs first, then the one of the button (a handler may free this surface's state,
  // so the second lookup is done after the first call as the C++ does with the iterators taken before)
  if AHandlers.TryGetValue(0, LHandler) then
    LHandler(AAction);
  if AHandlers.TryGetValue(AAction.Details^.Button, LHandler) then
    LHandler(AAction);
end;

procedure TXcomInteractiveSurface.CallKeyHandlers(AHandlers: TDictionary<Integer, TXcomActionHandler>;
  AAction: TXcomAction);
var
  LHandler: TXcomActionHandler;
  LModified: Boolean;
begin
  if AHandlers.TryGetValue(XCOM_KEY_ANY, LHandler) then
    LHandler(AAction);
  LModified := (AAction.Details^.Modifiers and (XCOM_KMOD_CTRL or XCOM_KMOD_ALT or XCOM_KMOD_SHIFT)) <> 0;
  if (not LModified) and AHandlers.TryGetValue(AAction.Details^.Key, LHandler) then
    LHandler(AAction);
end;

procedure TXcomInteractiveSurface.MousePress(AAction: TXcomAction);
begin
  CallHandlers(FPress, AAction);
end;

procedure TXcomInteractiveSurface.MouseRelease(AAction: TXcomAction);
begin
  CallHandlers(FRelease, AAction);
end;

procedure TXcomInteractiveSurface.MouseClick(AAction: TXcomAction);
begin
  CallHandlers(FClick, AAction);
end;

procedure TXcomInteractiveSurface.MouseIn(AAction: TXcomAction);
begin
  if Assigned(FIn) then
    FIn(AAction);
end;

procedure TXcomInteractiveSurface.MouseOver(AAction: TXcomAction);
begin
  if Assigned(FOver) then
    FOver(AAction);
end;

procedure TXcomInteractiveSurface.MouseOut(AAction: TXcomAction);
begin
  if Assigned(FOut) then
    FOut(AAction);
end;

procedure TXcomInteractiveSurface.KeyboardPress(AAction: TXcomAction);
begin
  CallKeyHandlers(FKeyPress, AAction);
end;

procedure TXcomInteractiveSurface.KeyboardRelease(AAction: TXcomAction);
begin
  CallKeyHandlers(FKeyRelease, AAction);
end;

procedure TXcomInteractiveSurface.OnMouseClick(const AHandler: TXcomActionHandler; AButton: Integer);
begin
  if Assigned(AHandler) then
    FClick.AddOrSetValue(AButton, AHandler)
  else
    FClick.Remove(AButton);
end;

procedure TXcomInteractiveSurface.OnMousePress(const AHandler: TXcomActionHandler; AButton: Integer);
begin
  if Assigned(AHandler) then
    FPress.AddOrSetValue(AButton, AHandler)
  else
    FPress.Remove(AButton);
end;

procedure TXcomInteractiveSurface.OnMouseRelease(const AHandler: TXcomActionHandler; AButton: Integer);
begin
  if Assigned(AHandler) then
    FRelease.AddOrSetValue(AButton, AHandler)
  else
    FRelease.Remove(AButton);
end;

procedure TXcomInteractiveSurface.OnMouseIn(const AHandler: TXcomActionHandler);
begin
  FIn := AHandler;
end;

procedure TXcomInteractiveSurface.OnMouseOver(const AHandler: TXcomActionHandler);
begin
  FOver := AHandler;
end;

procedure TXcomInteractiveSurface.OnMouseOut(const AHandler: TXcomActionHandler);
begin
  FOut := AHandler;
end;

procedure TXcomInteractiveSurface.OnKeyboardPress(const AHandler: TXcomActionHandler; AKey: Integer);
begin
  if AKey = XCOM_KEY_UNKNOWN then
    Exit;
  if Assigned(AHandler) then
    FKeyPress.AddOrSetValue(AKey, AHandler)
  else
    FKeyPress.Remove(AKey);
end;

procedure TXcomInteractiveSurface.OnKeyboardRelease(const AHandler: TXcomActionHandler; AKey: Integer);
begin
  if AKey = XCOM_KEY_UNKNOWN then
    Exit;
  if Assigned(AHandler) then
    FKeyRelease.AddOrSetValue(AKey, AHandler)
  else
    FKeyRelease.Remove(AKey);
end;

procedure TXcomInteractiveSurface.SetListButton;
begin
  FListButton := True;
end;

function TXcomInteractiveSurface.IsHovered: Boolean;
begin
  Result := FHovered;
end;

end.
