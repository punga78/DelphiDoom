{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - a mouse moved by a script                        }
{  The device that the mouse of the game reads when a script of keys has lines  }
{  for the mouse: no cursor of the system is touched                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ScriptMouse;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Input.Types, DelphiDoom.Input.Intf,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.Mouse.Intf;

type
  /// <summary>
  ///   A mouse with no hardware: a cursor that the script moves and that the game puts back where it wants
  ///   (SetPosition), on a window of 320 x 200 pixels, so that a pixel of the cursor is a pixel of the pointer of
  ///   the menus. The steps of a click are taken one for each reading of the position (the game asks for the
  ///   buttons first and for the position after: what a step does to the buttons is seen by the next reading)
  /// </summary>
  TGreedScriptMouse = class(TInterfacedObject, IGreedScriptMouse, IMouseDevice, IScreenSize)
  strict private
    type
      TStepKind = (skCorner, skMove, skPress, skRelease);
      TStep = record
        Kind: TStepKind;
        X: Integer;
        Y: Integer;
      end;
    var
      FX: Integer;
      FY: Integer;
      FButtons: array[TMouseButton] of Boolean;
      FSteps: TQueue<TStep>;
    procedure Push(AKind: TStepKind; AX, AY: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    // IGreedScriptMouse
    procedure Move(ADeltaX, ADeltaY: Integer);
    procedure SetButton(AButton: TGreedMouseButton; ADown: Boolean);
    procedure Click(AX, AY: Integer);
    // IMouseDevice
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
    // IScreenSize
    function GetWidth: Integer;
    function GetHeight: Integer;
    /// <summary>The steps of the clicks that no reading has taken yet</summary>
    function PendingSteps: Integer;
  end;

implementation

const
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;
  DEVICE_BUTTONS: array[TGreedMouseButton] of TMouseButton = (TMouseButton.Left, TMouseButton.Right,
    TMouseButton.Middle);

{ TGreedScriptMouse }

constructor TGreedScriptMouse.Create;
begin
  inherited Create;
  FSteps := TQueue<TStep>.Create;
end;

destructor TGreedScriptMouse.Destroy;
begin
  FSteps.Free;
  inherited Destroy;
end;

procedure TGreedScriptMouse.Push(AKind: TStepKind; AX, AY: Integer);
var
  LStep: TStep;
begin
  LStep.Kind := AKind;
  LStep.X := AX;
  LStep.Y := AY;
  FSteps.Enqueue(LStep);
end;

procedure TGreedScriptMouse.Move(ADeltaX, ADeltaY: Integer);
begin
  FX := FX + ADeltaX;
  FY := FY + ADeltaY;
end;

procedure TGreedScriptMouse.SetButton(AButton: TGreedMouseButton; ADown: Boolean);
begin
  FButtons[DEVICE_BUTTONS[AButton]] := ADown;
end;

procedure TGreedScriptMouse.Click(AX, AY: Integer);
begin
  Push(skCorner, 0, 0);
  Push(skMove, AX, AY);
  Push(skPress, 0, 0);
  Push(skRelease, 0, 0);
end;

procedure TGreedScriptMouse.Initialize;
begin
  // no hardware to start
end;

procedure TGreedScriptMouse.Shutdown;
begin
  FSteps.Clear;
end;

procedure TGreedScriptMouse.GetPosition(out AX, AY: Integer);
var
  LStep: TStep;
begin
  if FSteps.Count > 0 then
  begin
    LStep := FSteps.Dequeue;
    case LStep.Kind of
      skCorner:
        begin
          // further than the screen is wide: the pointer stops at 0, 0
          FX := FX - 2 * SCREEN_WIDTH;
          FY := FY - 2 * SCREEN_HEIGHT;
        end;
      skMove:
        begin
          FX := FX + LStep.X;
          FY := FY + LStep.Y;
        end;
      skPress:
        FButtons[TMouseButton.Left] := True;
      skRelease:
        FButtons[TMouseButton.Left] := False;
    end;
  end;
  AX := FX;
  AY := FY;
end;

procedure TGreedScriptMouse.SetPosition(AX, AY: Integer);
begin
  FX := AX;
  FY := AY;
end;

function TGreedScriptMouse.IsButtonDown(AButton: TMouseButton): Boolean;
begin
  Result := FButtons[AButton];
end;

function TGreedScriptMouse.GetWidth: Integer;
begin
  Result := SCREEN_WIDTH;
end;

function TGreedScriptMouse.GetHeight: Integer;
begin
  Result := SCREEN_HEIGHT;
end;

function TGreedScriptMouse.PendingSteps: Integer;
begin
  Result := FSteps.Count;
end;

end.
