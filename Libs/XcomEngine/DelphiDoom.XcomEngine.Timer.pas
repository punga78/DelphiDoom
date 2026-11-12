{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - Timer of OpenXcom                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Timer;

interface

uses
  DelphiDoom.Clock.Intf, DelphiDoom.XcomEngine.Ticks,
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   Calls a handler of a state or of a surface at a fixed interval of milliseconds, running it more than once
  ///   to catch up (frame skipping) when the game is late. The time comes from an IClock, so a test or a
  ///   screenshot can drive it. The "slow motion" divisor of the debug mode (Timer::gameSlowSpeed) is always 1
  /// </summary>
  TXcomTimer = class
  strict private
    FClock: IClock;
    FStart: Cardinal;
    FFrameSkipStart: Int64;
    FInterval: Cardinal;
    FRunning: Boolean;
    FFrameSkipping: Boolean;
    FMaxFrameSkip: Integer;
    FOnState: TXcomNotify;
    FOnSurface: TXcomNotify;
  public
    /// <param name="AMaxFrameSkip">Options::maxFrameSkip, how many extra calls to catch up</param>
    constructor Create(const AClock: IClock; AInterval: Cardinal; AFrameSkipping: Boolean = False;
      AMaxFrameSkip: Integer = 0);
    /// <summary>Timer::start</summary>
    procedure Start;
    /// <summary>Timer::stop</summary>
    procedure Stop;
    /// <summary>Timer::getTime: milliseconds since the last tick, 0 if stopped</summary>
    function Time: Cardinal;
    function IsRunning: Boolean;
    /// <summary>
    ///   Timer::think. AIsCurrent tells whether the state is still the active one (Game::isState) so the loop
    ///   stops calling a state that a handler has popped; without it only one call per think is made
    /// </summary>
    procedure Think(ACallState, ACallSurface: Boolean; const AIsCurrent: TFunc<Boolean> = nil);
    procedure SetInterval(AInterval: Cardinal);
    procedure OnTimerState(const AHandler: TXcomNotify);
    procedure OnTimerSurface(const AHandler: TXcomNotify);
  end;

implementation

constructor TXcomTimer.Create(const AClock: IClock; AInterval: Cardinal; AFrameSkipping: Boolean;
  AMaxFrameSkip: Integer);
begin
  inherited Create;
  FClock := AClock;
  FInterval := AInterval;
  FFrameSkipping := AFrameSkipping;
  FMaxFrameSkip := AMaxFrameSkip;
end;

procedure TXcomTimer.Start;
begin
  FStart := TXcomTicks.Now(FClock);
  FFrameSkipStart := FStart;
  FRunning := True;
end;

procedure TXcomTimer.Stop;
begin
  FStart := 0;
  FRunning := False;
end;

function TXcomTimer.Time: Cardinal;
begin
  if FRunning then
    Result := TXcomTicks.Now(FClock) - FStart
  else
    Result := 0;
end;

function TXcomTimer.IsRunning: Boolean;
begin
  Result := FRunning;
end;

procedure TXcomTimer.Think(ACallState, ACallSurface: Boolean; const AIsCurrent: TFunc<Boolean>);
var
  LNow: Int64;
  LIndex: Integer;
begin
  LNow := TXcomTicks.Now(FClock);
  if FRunning and ((LNow - FFrameSkipStart) >= FInterval) then
  begin
    LIndex := 0;
    while (LIndex <= FMaxFrameSkip) and FRunning and ((LNow - FFrameSkipStart) >= FInterval) do
    begin
      if ACallState and Assigned(FOnState) then
        FOnState();
      Inc(FFrameSkipStart, FInterval);
      if (not Assigned(AIsCurrent)) or (not FFrameSkipping) or (not AIsCurrent()) then
        Break;
      Inc(LIndex);
    end;
    if FRunning and ACallSurface and Assigned(FOnSurface) then
      FOnSurface();
    FStart := TXcomTicks.Now(FClock);
    if FStart > FFrameSkipStart then
      FFrameSkipStart := FStart;
  end;
end;

procedure TXcomTimer.SetInterval(AInterval: Cardinal);
begin
  FInterval := AInterval;
end;

procedure TXcomTimer.OnTimerState(const AHandler: TXcomNotify);
begin
  FOnState := AHandler;
end;

procedure TXcomTimer.OnTimerSurface(const AHandler: TXcomNotify);
begin
  FOnSurface := AHandler;
end;

end.
