{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - the arrow that repeats while it is held }
{  down (the press, release and timer handlers of OpenXcom screens like         }
{  ManufactureInfoState: 250 ms for the first step, then every 50 ms)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.HoldRepeater;

interface

uses
  DelphiDoom.Clock.Intf,
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomUi.ArrowButton;

type
  /// <summary>
  ///   Makes an arrow button repeat a step while the left button of the mouse is down: the first step comes after
  ///   250 ms and the next ones every 50 ms. The state that owns it calls Think; it frees it after its surfaces
  /// </summary>
  TXcomHoldRepeater = class
  strict private
    FTimer: TXcomTimer;
    FStep: TProc;
    procedure Press(AAction: TXcomAction);
    procedure Release(AAction: TXcomAction);
    procedure Tick;
  public
    /// <param name="AButton">The arrow (owned by the state)</param>
    /// <param name="AStep">What one step does; it can call Stop (for example when it shows an error)</param>
    constructor Create(const AClock: IClock; AButton: TXcomArrowButton; const AStep: TProc);
    destructor Destroy; override;
    procedure Think;
    procedure Stop;
  end;

implementation

{ TXcomHoldRepeater }

constructor TXcomHoldRepeater.Create(const AClock: IClock; AButton: TXcomArrowButton; const AStep: TProc);
begin
  inherited Create;
  FStep := AStep;
  FTimer := TXcomTimer.Create(AClock, 250);
  FTimer.OnTimerState(Tick);
  AButton.OnMousePress(Press);
  AButton.OnMouseRelease(Release);
end;

destructor TXcomHoldRepeater.Destroy;
begin
  FTimer.Free;
  inherited Destroy;
end;

procedure TXcomHoldRepeater.Press(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    FTimer.Start;
end;

procedure TXcomHoldRepeater.Release(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    Stop;
end;

procedure TXcomHoldRepeater.Stop;
begin
  FTimer.SetInterval(250);
  FTimer.Stop;
end;

procedure TXcomHoldRepeater.Tick;
begin
  FTimer.SetInterval(50);
  FStep();
end;

procedure TXcomHoldRepeater.Think;
begin
  FTimer.Think(True, False);
end;

end.
