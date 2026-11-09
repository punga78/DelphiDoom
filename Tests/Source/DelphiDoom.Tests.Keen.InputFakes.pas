{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - fakes for the input manager          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.InputFakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Keen.Intf;

type
  TFakeKeenMouse = class(TInterfacedObject, IKeenMouse)
  public
    Present: Boolean;
    DeltaX: Integer;
    DeltaY: Integer;
    Buttons: Word;
    constructor Create;
    function IsPresent: Boolean;
    procedure GetDelta(out ADeltaX, ADeltaY: Integer);
    function GetButtons: Word;
  end;

  TFakeKeenJoysticks = class(TInterfacedObject, IKeenJoysticks)
  public
    Present: array[0..1] of Boolean;
    X: array[0..1] of Word;
    Y: array[0..1] of Word;
    Buttons: array[0..1] of Word;
    function IsPresent(AJoy: Integer): Boolean;
    procedure GetAbs(AJoy: Integer; out AX, AY: Word);
    function GetButtons(AJoy: Integer): Word;
  end;

  /// <summary>A pump that does what the test says at each look: for the loops that wait for a key</summary>
  TFakeKeenPump = class(TInterfacedObject, IKeenInputPump)
  public
    Calls: Integer;
    OnPump: TProc<Integer>;
    procedure Pump;
  end;

implementation

{ TFakeKeenMouse }

constructor TFakeKeenMouse.Create;
begin
  inherited Create;
  Present := True;
end;

function TFakeKeenMouse.IsPresent: Boolean;
begin
  Result := Present;
end;

procedure TFakeKeenMouse.GetDelta(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := DeltaX;
  ADeltaY := DeltaY;
end;

function TFakeKeenMouse.GetButtons: Word;
begin
  Result := Buttons;
end;

{ TFakeKeenJoysticks }

function TFakeKeenJoysticks.IsPresent(AJoy: Integer): Boolean;
begin
  Result := Present[AJoy];
end;

procedure TFakeKeenJoysticks.GetAbs(AJoy: Integer; out AX, AY: Word);
begin
  AX := X[AJoy];
  AY := Y[AJoy];
end;

function TFakeKeenJoysticks.GetButtons(AJoy: Integer): Word;
begin
  Result := Buttons[AJoy];
end;

{ TFakeKeenPump }

procedure TFakeKeenPump.Pump;
begin
  Inc(Calls);
  if Assigned(OnPump) then
    OnPump(Calls);
end;

end.
