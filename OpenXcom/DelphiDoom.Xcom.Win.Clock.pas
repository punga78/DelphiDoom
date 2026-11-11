{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the clock of Windows (SDL_GetTicks and SDL_Delay)      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.Clock;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>IXcomClock on the system: milliseconds since the start (GetTickCount64, cut to 32 bits like SDL_GetTicks)</summary>
  TXcomWinClock = class(TInterfacedObject, IXcomClock)
  public
    function Ticks: Cardinal;
    procedure Delay(AMilliseconds: Cardinal);
  end;

implementation

function TXcomWinClock.Ticks: Cardinal;
begin
  Result := Cardinal(GetTickCount64 and $FFFFFFFF);
end;

procedure TXcomWinClock.Delay(AMilliseconds: Cardinal);
begin
  Sleep(AMilliseconds);
end;

end.
