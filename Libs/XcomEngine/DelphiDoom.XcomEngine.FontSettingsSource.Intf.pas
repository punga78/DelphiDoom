{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - where the fonts of the system that are     }
{  laid over the fonts of the game come from (issue 184)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontSettingsSource.Intf;

interface

uses
  DelphiDoom.XcomSurface.Glyph.Types;

type
  /// <summary>The entries of fonts.cfg as they are now, and the moment they are kept</summary>
  IXcomFontSettingsSource = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000024}']
    /// <summary>What the fonts have to be (empty: the pictures of the game)</summary>
    function Settings: TArray<TXcomFontOverlaySettings>;
    /// <summary>The choice is confirmed: it is written to the file, if it changed</summary>
    procedure Commit;
  end;

implementation

end.
