{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - Action of OpenXcom                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Action;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types;

type
  /// <summary>
  ///   An input event with what is needed to turn the mouse position of the window into the position of the
  ///   game (scale and black bands), plus the surface that is handling it. The event is a copy owned by the action
  /// </summary>
  TXcomAction = class
  strict private
    FDetails: TXcomInputEvent;
    FScaleX: Double;
    FScaleY: Double;
    FTopBlackBand: Integer;
    FLeftBlackBand: Integer;
    FMouseX: Integer;
    FMouseY: Integer;
    FSurfaceX: Integer;
    FSurfaceY: Integer;
    FSender: TObject;
    FButtonMask: Integer;
  public
    constructor Create(const AEvent: TXcomInputEvent; AScaleX, AScaleY: Double; ATopBlackBand, ALeftBlackBand: Integer);
    /// <summary>The event; it can be changed (the list buttons rewrite the button of a motion event)</summary>
    function Details: PXcomInputEvent;
    function XScale: Double;
    function YScale: Double;
    /// <summary>Action::setMouseAction</summary>
    procedure SetMouseAction(AMouseX, AMouseY, ASurfaceX, ASurfaceY: Integer);
    function IsMouseAction: Boolean;
    function TopBlackBand: Integer;
    function LeftBlackBand: Integer;
    function XMouse: Integer;
    function YMouse: Integer;
    function AbsoluteXMouse: Double;
    function AbsoluteYMouse: Double;
    function RelativeXMouse: Double;
    function RelativeYMouse: Double;
    /// <summary>The InteractiveSurface that handles the action (TObject: the surface unit uses this one)</summary>
    property Sender: TObject read FSender write FSender;
    /// <summary>The mouse buttons that were down when the event was read (SDL_GetMouseState)</summary>
    property ButtonMask: Integer read FButtonMask write FButtonMask;
  end;

implementation

constructor TXcomAction.Create(const AEvent: TXcomInputEvent; AScaleX, AScaleY: Double; ATopBlackBand,
  ALeftBlackBand: Integer);
begin
  inherited Create;
  FDetails := AEvent;
  FScaleX := AScaleX;
  FScaleY := AScaleY;
  FTopBlackBand := ATopBlackBand;
  FLeftBlackBand := ALeftBlackBand;
  FMouseX := -1;
  FMouseY := -1;
  FSurfaceX := -1;
  FSurfaceY := -1;
end;

function TXcomAction.Details: PXcomInputEvent;
begin
  Result := @FDetails;
end;

function TXcomAction.XScale: Double;
begin
  Result := FScaleX;
end;

function TXcomAction.YScale: Double;
begin
  Result := FScaleY;
end;

procedure TXcomAction.SetMouseAction(AMouseX, AMouseY, ASurfaceX, ASurfaceY: Integer);
begin
  FMouseX := AMouseX - FLeftBlackBand;
  FMouseY := AMouseY - FTopBlackBand;
  FSurfaceX := ASurfaceX;
  FSurfaceY := ASurfaceY;
end;

function TXcomAction.IsMouseAction: Boolean;
begin
  Result := FMouseX <> -1;
end;

function TXcomAction.TopBlackBand: Integer;
begin
  Result := FTopBlackBand;
end;

function TXcomAction.LeftBlackBand: Integer;
begin
  Result := FLeftBlackBand;
end;

function TXcomAction.XMouse: Integer;
begin
  Result := FMouseX;
end;

function TXcomAction.YMouse: Integer;
begin
  Result := FMouseY;
end;

function TXcomAction.AbsoluteXMouse: Double;
begin
  if FMouseX = -1 then
    Result := -1
  else
    Result := FMouseX / FScaleX;
end;

function TXcomAction.AbsoluteYMouse: Double;
begin
  if FMouseY = -1 then
    Result := -1
  else
    Result := FMouseY / FScaleY;
end;

function TXcomAction.RelativeXMouse: Double;
begin
  if FMouseX = -1 then
    Result := -1
  else
    Result := FMouseX - FSurfaceX * FScaleX;
end;

function TXcomAction.RelativeYMouse: Double;
begin
  if FMouseY = -1 then
    Result := -1
  else
    Result := FMouseY - FSurfaceY * FScaleY;
end;

end.
