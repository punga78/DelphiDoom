{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the clock of the game on the clock of the engine        }
{  What SDL_GetTicks and SDL_Delay did                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.HostClock;

interface

uses
  System.SysUtils, DelphiDoom.Clock.Intf, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomClock on the IClock of Libs\Clock: the milliseconds since the clock was first read, cut to 32 bits as
  ///   SDL_GetTicks (they start from zero when the game starts, as with SDL), and the wait of SDL_Delay
  /// </summary>
  TXcomHostClock = class(TInterfacedObject, IXcomClock)
  strict private
    FClock: IClock;
  public
    constructor Create(const AClock: IClock);
    function Ticks: Cardinal;
    procedure Delay(AMilliseconds: Cardinal);
  end;

implementation

const
  MILLISECONDS_PER_SECOND = 1000.0;
  // the longest wait that is asked to the clock in one call: its Sleep takes a signed number
  MAX_DELAY = Cardinal(High(Integer));

constructor TXcomHostClock.Create(const AClock: IClock);
begin
  inherited Create;
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FClock := AClock;
end;

function TXcomHostClock.Ticks: Cardinal;
begin
  // the counter of SDL wraps around after 49 days: so does this one
  Result := Cardinal(Trunc(FClock.Seconds * MILLISECONDS_PER_SECOND) and $FFFFFFFF);
end;

procedure TXcomHostClock.Delay(AMilliseconds: Cardinal);
begin
  if AMilliseconds > MAX_DELAY then
    AMilliseconds := MAX_DELAY;
  FClock.Sleep(Integer(AMilliseconds));
end;

end.
