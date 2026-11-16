{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the contract of a second source of the    }
{  characters of a font of the game                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.FontOverlay.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Font;

type
  /// <summary>
  ///   Called for every font of the game once its pictures are loaded: it can put characters of another source
  ///   (a font of the system) in the font, or leave it as it is. Without one the fonts are the pictures of the game
  /// </summary>
  IXcomFontOverlay = interface
    ['{4D8E1B72-C5A9-4F36-9E0B-A2D7F6138C54}']
    /// <param name="AFontId">The id of the font in Font.dat (FONT_BIG, FONT_SMALL...)</param>
    /// <param name="AFont">Not owned</param>
    procedure Apply(const AFontId: string; AFont: TXcomFont);
  end;

implementation

end.
