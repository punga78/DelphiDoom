{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the fonts the system has (issue 184)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.SystemFonts.Intf;

interface

type
  /// <summary>
  ///   The families of fonts that are installed (Windows: EnumFontFamiliesEx), the one place of the choice of the
  ///   fonts that touches the system. A fake gives a fixed list in the tests
  /// </summary>
  IXcomSystemFonts = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000021}']
    /// <summary>The family names, without the vertical ones ("@Name"), each once, in no particular order</summary>
    function Families: TArray<string>;
  end;

implementation

end.
