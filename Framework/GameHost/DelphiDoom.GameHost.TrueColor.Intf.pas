{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the contract of a display of colors          }
{  What a display can also do for a game that composes its frame in true        }
{  color (Xcom32, issue 183)                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.TrueColor.Intf;

interface

uses
  System.SysUtils;

type
  /// <summary>A picture of colors: one $FFRRGGBB value per pixel (blue in the low byte), rows from the top</summary>
  TGameHostTrueColorPixels = TArray<Cardinal>;

  /// <summary>
  ///   What a display that shows a picture of colors also does, beside the pictures of 8 bit pixels with a palette
  ///   of IGameHostVideoDevice. An optional interface: a game asks for it with Supports
  /// </summary>
  IGameHostTrueColorDisplay = interface
    ['{A2C4E6F8-1B3D-4F5A-9C7E-183000000010}']
    /// <summary>
    ///   Shows the picture (AWidth x AHeight pixels). A picture that has not the size of the mode is stretched to
    ///   it, as Present does. False when the display cannot show it now (the caller then calls Present)
    /// </summary>
    function PresentTrueColor(const APixels: TGameHostTrueColorPixels; AWidth, AHeight: Integer): Boolean;
  end;

implementation

end.
