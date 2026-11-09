{******************************************************************************}
{                                                                              }
{  DelphiDoom: XcomGame - the modes of the display of Windows (SDL_ListModes)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.DisplayModes;

interface

uses
  Winapi.Windows, System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.XcomEngine.Intf;

type
  /// <summary>
  ///   IXcomDisplayModes on EnumDisplaySettings: the different sizes the main display supports, from the largest to
  ///   the smallest (the order of SDL_ListModes), at least 8 bits deep
  /// </summary>
  TXcomWinDisplayModes = class(TInterfacedObject, IXcomDisplayModes)
  public
    function Modes: TArray<TXcomDisplayMode>;
  end;

implementation

function TXcomWinDisplayModes.Modes: TArray<TXcomDisplayMode>;
var
  LList: TList<TXcomDisplayMode>;
  LDevMode: TDevMode;
  LIndex: Integer;
  LMode: TXcomDisplayMode;
  LFound: Boolean;
  LOther: TXcomDisplayMode;
begin
  LList := TList<TXcomDisplayMode>.Create;
  try
    FillChar(LDevMode, SizeOf(LDevMode), 0);
    LDevMode.dmSize := SizeOf(LDevMode);
    LIndex := 0;
    while EnumDisplaySettings(nil, LIndex, LDevMode) do
    begin
      if LDevMode.dmBitsPerPel >= 8 then
      begin
        LMode.Width := Integer(LDevMode.dmPelsWidth);
        LMode.Height := Integer(LDevMode.dmPelsHeight);
        LFound := False;
        for LOther in LList do
          if (LOther.Width = LMode.Width) and (LOther.Height = LMode.Height) then
            LFound := True;
        if not LFound then
          LList.Add(LMode);
      end;
      Inc(LIndex);
    end;
    LList.Sort(TComparer<TXcomDisplayMode>.Construct(
      function(const ALeft, ARight: TXcomDisplayMode): Integer
      begin
        Result := ARight.Width - ALeft.Width;
        if Result = 0 then
          Result := ARight.Height - ALeft.Height;
      end));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
