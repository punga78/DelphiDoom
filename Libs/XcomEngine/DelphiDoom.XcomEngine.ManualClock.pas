{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - a clock that only moves when told         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ManualClock;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomClock for tests and screenshots: the time is a number that Delay and Advance increase, so the timers and
  ///   the frame rate of the game run the same way every time, without waiting
  /// </summary>
  TXcomManualClock = class(TInterfacedObject, IXcomClock)
  strict private
    FTicks: Cardinal;
  public
    constructor Create(AStart: Cardinal = 0);
    function Ticks: Cardinal;
    /// <summary>The wait is only an advance of the clock</summary>
    procedure Delay(AMilliseconds: Cardinal);
    procedure Advance(AMilliseconds: Cardinal);
  end;

implementation

constructor TXcomManualClock.Create(AStart: Cardinal);
begin
  inherited Create;
  FTicks := AStart;
end;

function TXcomManualClock.Ticks: Cardinal;
begin
  Result := FTicks;
end;

procedure TXcomManualClock.Delay(AMilliseconds: Cardinal);
begin
  Advance(AMilliseconds);
end;

procedure TXcomManualClock.Advance(AMilliseconds: Cardinal);
begin
  Inc(FTicks, AMilliseconds);
end;

end.
