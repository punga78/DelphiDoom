{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the contract of the displays                 }
{  What a game asks to the place where its pictures go                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Video.Intf;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types;

type
  /// <summary>Where the pictures of a game go: a window, or the memory of a test</summary>
  IGameHostVideoDevice = interface
    ['{5D0C2B7E-41A9-4E63-9B58-0F3A6C17D2E4}']
    /// <summary>(Re)creates the display of the given size; the real size is returned</summary>
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    /// <summary>
    ///   Shows the picture (AWidth x AHeight pixels, rows from the top) with the palette. A picture that has not the
    ///   size of the mode is stretched to it
    /// </summary>
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette);
    procedure SetTitle(const ATitle: string);
  end;

  /// <summary>What a display that is a window can also do; taken at the next SetMode</summary>
  IGameHostWindowStyle = interface
    ['{B81F3A96-0D47-4C25-A6E9-73C5D8401F2B}']
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
  end;

  /// <summary>
  ///   Where the window goes, taken at the next SetMode: AFixed puts its corner at (AX, AY), ACentered puts it in
  ///   the middle of the work area; neither leaves the window where the system or the player put it
  /// </summary>
  IGameHostWindowPlacement = interface
    ['{27E9D5C4-8A31-4B0F-95D6-C40E1B7A3F68}']
    procedure SetWindowPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
  end;

  /// <summary>What a display that can scale the picture itself also does (the OpenGL one)</summary>
  IGameHostFilteredDisplay = interface
    ['{E4B6207A-9C5D-4138-8E0B-6A2F91D3C75E}']
    /// <summary>Taken at the next SetMode</summary>
    procedure SetDisplayFilter(const AFilter: TGameHostDisplayFilter);
    /// <summary>
    ///   What is in use since the last SetMode: UseOpenGL false when the context could not be made, Shader empty
    ///   when the shader could not be used
    /// </summary>
    function DisplayFilter: TGameHostDisplayFilter;
    /// <summary>
    ///   Shows the picture (AWidth x AHeight, not scaled) in a display of ADisplayWidth x ADisplayHeight with the
    ///   bands around it; false when the device does not scale (the caller then calls Present)
    /// </summary>
    function PresentUnscaled(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette;
      ADisplayWidth, ADisplayHeight: Integer; const ABands: TGameHostBlackBands): Boolean;
  end;

  /// <summary>
  ///   Where the OpenGL display finds the shader that a filter names. Each game has its own files and format; a
  ///   loader that cannot give the shader says why in its own log
  /// </summary>
  IGameHostShaderLoader = interface
    ['{93A7C1D8-5E20-47B4-A1F6-D8035B9E6C42}']
    function TryLoad(const APath: string; out ASource: TGameHostShaderSource): Boolean;
  end;

  /// <summary>Makes a display; called when the display is first needed and each time the kind of display changes</summary>
  TGameHostVideoDeviceFactory = reference to function: IGameHostVideoDevice;

implementation

end.
