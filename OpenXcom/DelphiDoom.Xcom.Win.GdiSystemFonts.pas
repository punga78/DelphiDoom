{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the font families that Windows has installed            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.GdiSystemFonts;

interface

uses
  Winapi.Windows, System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.SystemFonts.Intf;

type
  /// <summary>IXcomSystemFonts on EnumFontFamiliesEx: every family once, the vertical ones ("@Name") left out</summary>
  TXcomGdiSystemFonts = class(TInterfacedObject, IXcomSystemFonts)
  public
    function Families: TArray<string>;
  end;

implementation

function CollectFamily(const ALogFont: TEnumLogFontEx; const AMetric: TNewTextMetricEx; AFontType: DWORD;
  ALParam: LPARAM): Integer; stdcall;
var
  LNames: TList<string>;
  LName: string;
begin
  LNames := TList<string>(ALParam);
  LName := ALogFont.elfLogFont.lfFaceName;
  if (LName <> '') and (LName[1] <> '@') and not LNames.Contains(LName) then
    LNames.Add(LName);
  Result := 1;
end;

function TXcomGdiSystemFonts.Families: TArray<string>;
var
  LNames: TList<string>;
  LDC: HDC;
  LFilter: TLogFont;
begin
  LNames := TList<string>.Create;
  try
    LDC := GetDC(0);
    try
      LFilter := Default(TLogFont);
      LFilter.lfCharSet := DEFAULT_CHARSET;
      EnumFontFamiliesEx(LDC, LFilter, @CollectFamily, LPARAM(LNames), 0);
    finally
      ReleaseDC(0, LDC);
    end;
    Result := LNames.ToArray;
  finally
    LNames.Free;
  end;
end;

end.
