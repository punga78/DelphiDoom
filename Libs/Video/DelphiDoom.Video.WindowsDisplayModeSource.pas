{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the screen modes from Windows                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.WindowsDisplayModeSource;

interface

uses
  System.SysUtils, DelphiDoom.Video.Types, DelphiDoom.Video.Intf;

type
  /// <summary>EnumDisplaySettings of the main screen, every mode as Windows gives it</summary>
  TWindowsDisplayModeSource = class(TInterfacedObject, IDisplayModeSource)
  public
    function ListModes: TArray<TDisplayMode>;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsDisplayModeSource }

function TWindowsDisplayModeSource.ListModes: TArray<TDisplayMode>;
var
  LDevMode: TDevMode;
  LIndex: Integer;
begin
  Result := nil;
  LIndex := 0;
  repeat
    // dmSize must be set, otherwise Windows may refuse the structure
    ZeroMemory(@LDevMode, SizeOf(LDevMode));
    LDevMode.dmSize := SizeOf(LDevMode);
    if not EnumDisplaySettings(nil, LIndex, LDevMode) then
      Break;
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Width := LDevMode.dmPelsWidth;
    Result[High(Result)].Height := LDevMode.dmPelsHeight;
    Result[High(Result)].BitsPerPixel := LDevMode.dmBitsPerPel;
    Inc(LIndex);
  until False;
end;

end.
