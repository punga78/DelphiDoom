{******************************************************************************}
{                                                                              }
{  DD_Tools: the fonts of the machine                                           }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.FontCatalog;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.FontEditor.Intf;

type
  /// <summary>
  ///   IFontCatalog with EnumFontFamiliesEx on the screen, as CollectFonts of DD_FONT did: every face name of every
  ///   charset, sorted, without repetitions (the fonts that were added with TWindowsFontInstaller are there too)
  /// </summary>
  TWindowsFontCatalog = class(TInterfacedObject, IFontCatalog)
  public
    function FontNames: TArray<string>;
  end;

implementation

uses
  Winapi.Windows;

function EnumerateFace(var ALogFont: TLogFont; var ATextMetric: TTextMetric; AFontType: Integer;
  AData: Pointer): Integer; stdcall;
var
  LNames: TStringList;
begin
  LNames := TStringList(AData);
  LNames.Add(ALogFont.lfFaceName);
  Result := 1;
end;

{ TWindowsFontCatalog }

function TWindowsFontCatalog.FontNames: TArray<string>;
var
  LContext: HDC;
  LLogFont: TLogFont;
  LNames: TStringList;
begin
  LNames := TStringList.Create;
  try
    LNames.Sorted := True;
    LNames.Duplicates := dupIgnore;
    LNames.CaseSensitive := False;
    LContext := GetDC(0);
    try
      FillChar(LLogFont, SizeOf(LLogFont), 0);
      LLogFont.lfCharSet := DEFAULT_CHARSET;
      EnumFontFamiliesEx(LContext, LLogFont, @EnumerateFace, LPARAM(LNames), 0);
    finally
      ReleaseDC(0, LContext);
    end;
    Result := LNames.ToStringArray;
  finally
    LNames.Free;
  end;
end;

end.
