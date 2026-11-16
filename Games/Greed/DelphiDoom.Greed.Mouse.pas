{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the mouse of the game                            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): INT_ReadMouse, ResetMouse,  }
{  MouseGetClick, MouseShow, MouseHide and I_SynchronizeInput of d_ints.pas     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Mouse;

interface

uses
  System.SysUtils, DelphiDoom.Input.Types, DelphiDoom.Input.Intf, DelphiDoom.Greed.PlayerControl.Intf,
  DelphiDoom.Greed.Mouse.Intf;

const
  /// <summary>I_IGNORETICKS (TICRATE div 2): the readings that are skipped after the window gets the focus</summary>
  GREED_MOUSE_IGNORED_READINGS = 35;
  /// <summary>The bits of mouse.flags</summary>
  GREED_MOUSE_FLAG_LEFT = 1;
  GREED_MOUSE_FLAG_RIGHT = 2;
  GREED_MOUSE_FLAG_MIDDLE = 4;

type
  /// <summary>
  ///   The mouse of d_ints.pas on the devices of Framework\Input: the cursor and the buttons (IMouseDevice: lbuttondown,
  ///   rbuttondown, mbuttondown, getcursorposfunc and setcursorposfunc of the original), the size of the window
  ///   (IScreenSize: I_WindowWidth and I_WindowHeight) and, if given, when the program listens (IInputGate: the
  ///   window is in the foreground). A reading takes the three buttons, how far the cursor is from the place where
  ///   the reading before left it (the middle of the window; 0, 0 before the first reading, as mlastx and mlasty
  ///   of the original) and puts the cursor back in the middle. While the pointer of the menus is shown it moves
  ///   by the same distance scaled to the screen of 320 x 200 and stays in 0..319, 0..199. With a gate nothing is
  ///   read while the program does not listen (the state stays the one of the last reading) and the first 35
  ///   readings after it listens again are skipped (ignoretics).
  ///   Difference from the original: a window with no size does not move the pointer (the original divides by 0)
  /// </summary>
  TGreedMouse = class(TInterfacedObject, IGreedMouse)
  strict private
    FDevice: IMouseDevice;
    FScreen: IScreenSize;
    FGate: IInputGate;
    FFlags: Integer;
    FOldFlags: Integer;
    FDeltaX: Integer;
    FDeltaY: Integer;
    FLastX: Integer;
    FLastY: Integer;
    FPointerX: Single;
    FPointerY: Single;
    FVisible: Boolean;
    FMenuEnabled: Boolean;
    FListening: Boolean;
    FIgnoredReadings: Integer;
    function MayRead: Boolean;
  public
    /// <summary>AGate can be nil (the program always listens). EArgumentNilException if ADevice or AScreen is nil</summary>
    constructor Create(const ADevice: IMouseDevice; const AScreen: IScreenSize; const AGate: IInputGate);
    procedure Read;
    procedure Reset;
    function IsDown(AButton: TGreedMouseButton): Boolean;
    function GetDeltaX: Integer;
    function GetDeltaY: Integer;
    function TakeClick(out AX, AY: Integer): Boolean;
    procedure Show;
    procedure Hide;
    function IsVisible: Boolean;
    function GetPointerX: Single;
    function GetPointerY: Single;
    function GetMenuEnabled: Boolean;
    procedure SetMenuEnabled(AValue: Boolean);
    /// <summary>mouse.flags and mouse.oldflags of the last reading</summary>
    property Flags: Integer read FFlags;
    property OldFlags: Integer read FOldFlags;
  end;

implementation

const
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;
  BUTTON_FLAGS: array[TGreedMouseButton] of Integer = (GREED_MOUSE_FLAG_LEFT, GREED_MOUSE_FLAG_RIGHT,
    GREED_MOUSE_FLAG_MIDDLE);

{ TGreedMouse }

constructor TGreedMouse.Create(const ADevice: IMouseDevice; const AScreen: IScreenSize; const AGate: IInputGate);
begin
  inherited Create;
  if not Assigned(ADevice) then
    raise EArgumentNilException.Create('ADevice');
  if not Assigned(AScreen) then
    raise EArgumentNilException.Create('AScreen');
  FDevice := ADevice;
  FScreen := AScreen;
  FGate := AGate;
  FPointerX := GREED_MOUSE_START_X;
  FPointerY := GREED_MOUSE_START_Y;
  // menuusemouse: boolean = true
  FMenuEnabled := True;
end;

function TGreedMouse.MayRead: Boolean;
begin
  if not Assigned(FGate) then
    Exit(True);
  // INT_ReadControls leaves at once while the window is in the background
  if not FGate.IsInputAllowed then
  begin
    FListening := False;
    Exit(False);
  end;
  // I_SynchronizeInput(true): about half a second without input when the window gets the focus again
  if not FListening then
  begin
    FListening := True;
    FIgnoredReadings := GREED_MOUSE_IGNORED_READINGS;
  end;
  if FIgnoredReadings > 0 then
  begin
    Dec(FIgnoredReadings);
    Exit(False);
  end;
  Result := True;
end;

procedure TGreedMouse.Read;
var
  LFlags: Integer;
  LX: Integer;
  LY: Integer;
  LWidth: Integer;
  LHeight: Integer;
begin
  if not MayRead then
    Exit;
  LFlags := 0;
  if FDevice.IsButtonDown(TMouseButton.Left) then
    LFlags := LFlags or GREED_MOUSE_FLAG_LEFT;
  if FDevice.IsButtonDown(TMouseButton.Right) then
    LFlags := LFlags or GREED_MOUSE_FLAG_RIGHT;
  if FDevice.IsButtonDown(TMouseButton.Middle) then
    LFlags := LFlags or GREED_MOUSE_FLAG_MIDDLE;
  FDevice.GetPosition(LX, LY);
  FOldFlags := FFlags;
  FFlags := LFlags;
  FDeltaX := FLastX - LX;
  FDeltaY := FLastY - LY;
  if FVisible then
  begin
    LWidth := FScreen.Width;
    LHeight := FScreen.Height;
    if (LWidth > 0) and (LHeight > 0) then
    begin
      FPointerX := FPointerX - FDeltaX * SCREEN_WIDTH / LWidth;
      if FPointerX < 0.0 then
        FPointerX := 0.0
      else if FPointerX > SCREEN_WIDTH - 1 then
        FPointerX := SCREEN_WIDTH - 1;
      FPointerY := FPointerY - FDeltaY * SCREEN_HEIGHT / LHeight;
      if FPointerY < 0.0 then
        FPointerY := 0.0
      else if FPointerY > SCREEN_HEIGHT - 1 then
        FPointerY := SCREEN_HEIGHT - 1;
    end;
  end;
  Reset;
end;

procedure TGreedMouse.Reset;
begin
  FLastX := FScreen.Width div 2;
  FLastY := FScreen.Height div 2;
  FDevice.SetPosition(FLastX, FLastY);
end;

function TGreedMouse.IsDown(AButton: TGreedMouseButton): Boolean;
begin
  Result := (FFlags and BUTTON_FLAGS[AButton]) <> 0;
end;

function TGreedMouse.GetDeltaX: Integer;
begin
  Result := FDeltaX;
end;

function TGreedMouse.GetDeltaY: Integer;
begin
  Result := FDeltaY;
end;

function TGreedMouse.TakeClick(out AX, AY: Integer): Boolean;
begin
  AX := 0;
  AY := 0;
  if not FMenuEnabled then
    Exit(False);
  Result := ((FFlags and GREED_MOUSE_FLAG_LEFT) <> 0) and ((FOldFlags and GREED_MOUSE_FLAG_LEFT) = 0);
  if Result then
  begin
    // the same click is not given twice
    FOldFlags := FOldFlags or GREED_MOUSE_FLAG_LEFT;
    AX := Round(FPointerX);
    AY := Round(FPointerY);
  end;
end;

procedure TGreedMouse.Show;
begin
  FVisible := FMenuEnabled;
end;

procedure TGreedMouse.Hide;
begin
  FVisible := False;
end;

function TGreedMouse.IsVisible: Boolean;
begin
  Result := FVisible;
end;

function TGreedMouse.GetPointerX: Single;
begin
  Result := FPointerX;
end;

function TGreedMouse.GetPointerY: Single;
begin
  Result := FPointerY;
end;

function TGreedMouse.GetMenuEnabled: Boolean;
begin
  Result := FMenuEnabled;
end;

procedure TGreedMouse.SetMenuEnabled(AValue: Boolean);
begin
  FMenuEnabled := AValue;
end;

end.
