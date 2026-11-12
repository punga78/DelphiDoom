{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - lay another font of the system over the    }
{  fonts of the game that are loaded (issue 184)                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontReapplier.Intf;

interface

uses
  DelphiDoom.XcomSurface.FontOverlay.Intf;

type
  /// <summary>
  ///   What the resources of the game give so the fonts can change while the game runs (not in OpenXcom: it reads
  ///   its fonts once). The fonts are changed in place: whoever holds one sees the new characters
  /// </summary>
  IXcomFontReapplier = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000022}']
    /// <summary>
    ///   Takes every font back to the pictures of the game and lays the overlay over it (nil: the pictures alone)
    /// </summary>
    procedure ReapplyFonts(const AOverlay: IXcomFontOverlay);
  end;

implementation

end.
