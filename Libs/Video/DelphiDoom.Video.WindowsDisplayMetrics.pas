{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the size of the screen from Windows              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.WindowsDisplayMetrics;

interface

uses
  DelphiDoom.Video.Intf;

type
  /// <summary>GetSystemMetrics: asked every time, the user can change the resolution</summary>
  TWindowsDisplayMetrics = class(TInterfacedObject, IDisplayMetrics)
  public
    function GetWidth: Integer;
    function GetHeight: Integer;
  end;

implementation

uses
  Winapi.Windows;

{ TWindowsDisplayMetrics }

function TWindowsDisplayMetrics.GetWidth: Integer;
begin
  Result := GetSystemMetrics(SM_CXSCREEN);
end;

function TWindowsDisplayMetrics.GetHeight: Integer;
begin
  Result := GetSystemMetrics(SM_CYSCREEN);
end;

end.
