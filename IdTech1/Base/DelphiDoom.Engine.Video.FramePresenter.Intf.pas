{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the contracts of the output of the software video      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Video.FramePresenter.Intf;

interface

uses
  System.Types;

type
  /// <summary>
  ///   Where the frame of the software renderer goes: the window of the game. Called once for each frame, never for
  ///   each pixel or column
  /// </summary>
  IEngineFramePresenter = interface
    ['{8A3E5C71-0B24-4D96-A7F8-C1E390D2B654}']
    /// <summary>
    ///   Shows the frame (AWidth x AHeight pixels of 32 bits, blue in the low byte, rows from the top, no padding)
    ///   in ADestination (coordinates of the client area of the window), stretched when the sizes differ; ATimes
    ///   times (at least one: the benchmark option r_blitmultiplier)
    /// </summary>
    procedure Present(AFrame: Pointer; AWidth, AHeight: Integer; const ADestination: TRect; ATimes: Integer);
  end;

  /// <summary>The resolution of the screen, for the exclusive full screen mode</summary>
  IEngineDisplayResolution = interface
    ['{5F1D9B38-72A6-4E03-8C54-E6B01A93D7F2}']
    /// <summary>Changes the screen to AWidth x AHeight at 32 bits; false when the system refuses</summary>
    function Change(AWidth, AHeight: Integer): Boolean;
    /// <summary>Gives back the resolution that the user chose for the desktop</summary>
    procedure Restore;
  end;

implementation

end.
