{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - the "used:available" text of the        }
{  stores of the lists of quantities                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SpaceText;

interface

type
  /// <summary>The text of STR_SPACE_USED that PurchaseState, SellState and TransferItemsState build</summary>
  TXcomSpaceText = class
  public
    /// <summary>
    ///   used, then "(+x.x)" or "(-x.x)" when the offset is more than 0.05 in either direction, then ":available".
    ///   The used stores are written as an ostream does (six significant digits)
    /// </summary>
    class function Format(AUsed, AOffset: Double; AAvailable: Integer): string; static;
  end;

implementation

uses
  System.SysUtils;

const
  // a Double, as in the C++ (the literal alone is extended precision here)
  Threshold: Double = 0.05;

class function TXcomSpaceText.Format(AUsed, AOffset: Double; AAvailable: Integer): string;
var
  LSettings: TFormatSettings;
begin
  LSettings := TFormatSettings.Invariant;
  Result := System.SysUtils.Format('%.6g', [AUsed], LSettings);
  if Abs(AOffset) > Threshold then
  begin
    Result := Result + '(';
    if AOffset > Threshold then
      Result := Result + '+';
    Result := Result + System.SysUtils.Format('%.1f', [AOffset], LSettings) + ')';
  end;
  Result := Result + ':' + IntToStr(AAvailable);
end;

end.
