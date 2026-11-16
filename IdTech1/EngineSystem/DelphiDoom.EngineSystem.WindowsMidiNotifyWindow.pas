{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the notify window of the MIDI player    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.WindowsMidiNotifyWindow;

// The hidden window of i_midi_legacy.pas (issue #185): MCI sends MM_MCINOTIFY to it when a
// song ends. The messages come through the message loop of the engine (I_ProcessWindows).

interface

uses
  Winapi.Windows, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>A window that is never shown and passes the notifications of the sequencer on</summary>
  TWindowsMidiNotifyWindow = class(TInterfacedObject, IMidiNotifyWindow)
  strict private
    FOnNotify: TMidiNotifyEvent;
    FHandle: HWND;
    class var FClassRegistered: Boolean;
    class function WindowProcedure(AWindow: HWND; AMessage: UINT; AWParam: WPARAM;
      ALParam: LPARAM): LRESULT; stdcall; static;
  public
    destructor Destroy; override;
    function Open(const AOnNotify: TMidiNotifyEvent): NativeUInt;
    procedure Close(AHandle: NativeUInt);
  end;

implementation

uses
  Winapi.Messages, Winapi.MMSystem;

const
  WINDOW_CLASS_NAME = 'MIDIPLAYERWNDNOTIFY';
  WINDOW_TITLE = 'Notify Window';

{ TWindowsMidiNotifyWindow }

destructor TWindowsMidiNotifyWindow.Destroy;
begin
  if FHandle <> 0 then
    DestroyWindow(FHandle);
  inherited Destroy;
end;

class function TWindowsMidiNotifyWindow.WindowProcedure(AWindow: HWND; AMessage: UINT;
  AWParam: WPARAM; ALParam: LPARAM): LRESULT;
var
  LOwner: TWindowsMidiNotifyWindow;
begin
  LOwner := TWindowsMidiNotifyWindow(GetWindowLongPtr(AWindow, GWLP_USERDATA));
  case AMessage of
    MM_MCINOTIFY:
      if Assigned(LOwner) and Assigned(LOwner.FOnNotify) then
        LOwner.FOnNotify(AWParam = MCI_NOTIFY_SUCCESSFUL);
    WM_CLOSE:
      begin
        if Assigned(LOwner) then
          LOwner.FHandle := 0;
        DestroyWindow(AWindow);
        Result := 0;
        Exit;
      end;
  end;
  Result := DefWindowProc(AWindow, AMessage, AWParam, ALParam);
end;

function TWindowsMidiNotifyWindow.Open(const AOnNotify: TMidiNotifyEvent): NativeUInt;
var
  LClass: TWndClass;
begin
  FOnNotify := AOnNotify;
  if not FClassRegistered then
  begin
    ZeroMemory(@LClass, SizeOf(LClass));
    LClass.style := CS_DBLCLKS;
    LClass.lpfnWndProc := @WindowProcedure;
    LClass.lpszClassName := WINDOW_CLASS_NAME;
    LClass.hInstance := HInstance;
    LClass.hCursor := LoadCursor(0, IDC_ARROW);
    RegisterClass(LClass);
    FClassRegistered := True;
  end;
  FHandle := CreateWindowEx(0, WINDOW_CLASS_NAME, WINDOW_TITLE, WS_OVERLAPPEDWINDOW,
    Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT),
    Integer(CW_USEDEFAULT), 0, 0, HInstance, nil);
  if FHandle <> 0 then
  begin
    SetWindowLongPtr(FHandle, GWLP_USERDATA, NativeInt(Self));
    ShowWindow(FHandle, SW_HIDE);
  end;
  Result := FHandle;
end;

procedure TWindowsMidiNotifyWindow.Close(AHandle: NativeUInt);
begin
  SendMessage(HWND(AHandle), WM_CLOSE, 0, 0);
end;

end.
