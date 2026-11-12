{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - SDL_GetTicks and SDL_Delay on an IClock    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Ticks;

// the milliseconds are a 32 bit counter that wraps around, as SDL_GetTicks: no overflow checks
{$Q-}
{$R-}

interface

uses
  DelphiDoom.Clock.Intf;

type
  /// <summary>
  ///   The two things OpenXcom asks to the time, said to the IClock of Libs\Clock: the milliseconds since the clock
  ///   was first read, cut to 32 bits (SDL_GetTicks), and the wait (SDL_Delay)
  /// </summary>
  TXcomTicks = class
  public
    /// <summary>
    ///   Milliseconds as SDL_GetTicks. It asks for the whole steps at 1000 per second and not for the seconds, so
    ///   a clock that counts milliseconds (the manual one of the screenshots) answers without rounding
    /// </summary>
    class function Now(const AClock: IClock): Cardinal; static;
    /// <summary>SDL_Delay: a wait longer than the clock can take in one call is cut</summary>
    class procedure Delay(const AClock: IClock; AMilliseconds: Cardinal); static;
  end;

implementation

const
  TICKS_PER_SECOND = 1000;
  // the longest wait that is asked to the clock in one call: its Sleep takes a signed number
  MAX_DELAY = Cardinal(High(Integer));

class function TXcomTicks.Now(const AClock: IClock): Cardinal;
begin
  Result := Cardinal(AClock.Steps(TICKS_PER_SECOND));
end;

class procedure TXcomTicks.Delay(const AClock: IClock; AMilliseconds: Cardinal);
begin
  if AMilliseconds > MAX_DELAY then
    AMilliseconds := MAX_DELAY;
  AClock.Sleep(Integer(AMilliseconds));
end;

end.
