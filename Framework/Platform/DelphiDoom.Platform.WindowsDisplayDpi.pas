{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - the pixel density of the screen              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.WindowsDisplayDpi;

interface

uses
  DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   IDisplayDpi on functions found in the DLLs at run time (they do not exist on the old
  ///   systems, and a program that imports them would not start there)
  /// </summary>
  TWindowsDisplayDpi = class(TInterfacedObject, IDisplayDpi)
  public
    function SetAwareness: Boolean;
    function WindowDpi(AWindow: NativeUInt): Integer;
  end;

implementation

uses
  Winapi.Windows;

const
  DEFAULT_DPI = 96;
  PROCESS_SYSTEM_DPI_AWARE = 1;
  PROCESS_PER_MONITOR_DPI_AWARE = 2;

type
  TSetProcessDpiAware = function: BOOL; stdcall;
  TSetProcessDpiAwareness = function(AValue: Integer): HRESULT; stdcall;
  TGetDpiForWindow = function(AWindow: HWND): UINT; stdcall;

{ TWindowsDisplayDpi }

function TWindowsDisplayDpi.SetAwareness: Boolean;
var
  LSetAwareness: TSetProcessDpiAwareness;
  LSetAware: TSetProcessDpiAware;
  LModule: HMODULE;
begin
  Result := False;
  LModule := LoadLibrary('Shcore.dll');
  if LModule <> 0 then
  begin
    try
      LSetAwareness := GetProcAddress(LModule, 'SetProcessDpiAwareness');
      if Assigned(LSetAwareness) then
      begin
        Result := LSetAwareness(PROCESS_PER_MONITOR_DPI_AWARE) = S_OK;
        if not Result then
          Result := LSetAwareness(PROCESS_SYSTEM_DPI_AWARE) = S_OK;
      end;
    finally
      FreeLibrary(LModule);
    end;
    Exit;
  end;

  LSetAware := GetProcAddress(GetModuleHandle('user32.dll'), 'SetProcessDPIAware');
  if Assigned(LSetAware) then
    Result := LSetAware;
end;

function TWindowsDisplayDpi.WindowDpi(AWindow: NativeUInt): Integer;
var
  LGetDpi: TGetDpiForWindow;
begin
  LGetDpi := GetProcAddress(GetModuleHandle('user32.dll'), 'GetDpiForWindow');
  if Assigned(LGetDpi) then
    Result := Integer(LGetDpi(AWindow))
  else
    Result := DEFAULT_DPI;
end;

end.
