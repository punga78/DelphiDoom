{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - Unicode::formatFunding of OpenXcom      }
{  (an amount of money with a dollar sign and the thousands apart)              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.Funding;

interface

type
  /// <summary>formatNumber and formatFunding of Unicode.cpp</summary>
  TXcomFunding = class
  public
    /// <summary>formatNumber: groups of three digits separated by the no-break space of the text of the game, with a currency before</summary>
    class function FormatNumber(AValue: Int64; const ACurrency: string): string; static;
    /// <summary>formatFunding: formatNumber with the dollar sign</summary>
    class function Format(AValue: Int64): string; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.XcomUi.Types;

class function TXcomFunding.FormatNumber(AValue: Int64; const ACurrency: string): string;
var
  LNegative: Boolean;
  LSpacer: Integer;
begin
  LNegative := AValue < 0;
  if LNegative then
    Result := IntToStr(-AValue)
  else
    Result := IntToStr(AValue);
  LSpacer := Length(Result) - 3;
  while (LSpacer > 0) and (LSpacer < Length(Result)) do
  begin
    Insert(Char(XCOM_TOKEN_NBSP), Result, LSpacer + 1);
    Dec(LSpacer, 3);
  end;
  if ACurrency <> '' then
    Result := ACurrency + Result;
  if LNegative then
    Result := '-' + Result;
end;

class function TXcomFunding.Format(AValue: Int64): string;
begin
  Result := FormatNumber(AValue, '$');
end;

end.
