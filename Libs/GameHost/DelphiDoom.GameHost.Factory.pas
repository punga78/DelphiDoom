{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the factory of the window and of GDI         }
{  The only place that knows the classes of the window                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Factory;

interface

uses
  DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Win.Window;

type
  /// <summary>
  ///   Makes the window of a game and the display that draws in it with GDI. The OpenGL display has a factory of
  ///   its own (DelphiDoom.GameHost.OpenGl.Factory), so that a game without it does not link OpenGL
  /// </summary>
  TGameHostFactory = class
  public
    /// <summary>
    ///   A window that gives its events to AEvents, with the keyboard of Windows. It has no handle until a display
    ///   sets a mode; the caller frees it, after the displays that draw in it
    /// </summary>
    class function CreateWindow(const ATitle: string; const AEvents: IGameHostEventSink;
      AHideCursor: Boolean): TGameHostWinWindow; static;
    /// <summary>The display on GDI in the window, which must outlive it</summary>
    class function CreateGdiDevice(AWindow: TGameHostWinWindow): IGameHostVideoDevice; static;
  end;

implementation

uses
  DelphiDoom.GameHost.Win.Keyboard, DelphiDoom.GameHost.Win.MessageTranslator,
  DelphiDoom.GameHost.Win.GdiVideoDevice;

class function TGameHostFactory.CreateWindow(const ATitle: string; const AEvents: IGameHostEventSink;
  AHideCursor: Boolean): TGameHostWinWindow;
begin
  Result := TGameHostWinWindow.Create(ATitle,
    TGameHostWinMessageTranslator.Create(AEvents, TGameHostWinKeyboard.Create), AHideCursor);
end;

class function TGameHostFactory.CreateGdiDevice(AWindow: TGameHostWinWindow): IGameHostVideoDevice;
begin
  Result := TGameHostWinGdiVideoDevice.Create(AWindow);
end;

end.
