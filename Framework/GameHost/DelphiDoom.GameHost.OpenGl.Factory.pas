{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the factory of the displays with OpenGL      }
{  The only place that knows the class of the OpenGL display                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.OpenGl.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.GameHost.Video.Intf, DelphiDoom.GameHost.Win.Window;

type
  /// <summary>Makes the displays of a game that can use OpenGL (a program that uses this unit links OpenGL)</summary>
  TGameHostOpenGlFactory = class
  public
    /// <summary>The display on OpenGL in the window, which must outlive it</summary>
    /// <param name="AShaders">Gives the shader that the filter names; nil: no shader is ever used</param>
    /// <param name="ALog">Where the version of OpenGL and the problems go; nil for nowhere</param>
    class function CreateOpenGlDevice(AWindow: TGameHostWinWindow; const AShaders: IGameHostShaderLoader;
      const ALog: ILog): IGameHostVideoDevice; static;
    /// <summary>
    ///   The display that is GDI or OpenGL as its filter says at each mode, and goes back to GDI when OpenGL
    ///   cannot be used. The window must outlive it
    /// </summary>
    class function CreateSelector(AWindow: TGameHostWinWindow; const AShaders: IGameHostShaderLoader;
      const ALog: ILog): IGameHostVideoDevice; static;
  end;

implementation

uses
  DelphiDoom.GameHost.Factory, DelphiDoom.GameHost.VideoDeviceSelector,
  DelphiDoom.GameHost.Win.OpenGlVideoDevice;

class function TGameHostOpenGlFactory.CreateOpenGlDevice(AWindow: TGameHostWinWindow;
  const AShaders: IGameHostShaderLoader; const ALog: ILog): IGameHostVideoDevice;
begin
  Result := TGameHostWinOpenGlVideoDevice.Create(AWindow, AShaders, ALog);
end;

class function TGameHostOpenGlFactory.CreateSelector(AWindow: TGameHostWinWindow;
  const AShaders: IGameHostShaderLoader; const ALog: ILog): IGameHostVideoDevice;
begin
  Result := TGameHostVideoDeviceSelector.Create(
    function: IGameHostVideoDevice
    begin
      Result := TGameHostFactory.CreateGdiDevice(AWindow);
    end,
    function: IGameHostVideoDevice
    begin
      Result := CreateOpenGlDevice(AWindow, AShaders, ALog);
    end, ALog);
end;

end.
