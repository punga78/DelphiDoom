{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the fonts chosen in the options take       }
{  effect while the game runs (issue 184)                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontReloader.Intf;

interface

uses
  DelphiDoom.XcomEngine.Resources.Intf;

type
  /// <summary>
  ///   What a font overlay can tell the user once it was applied: the fonts of the system that could not be used
  ///   as chosen, in words that mean something to a player (the log has the technical ones)
  /// </summary>
  IXcomFontNotices = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000025}']
    function Notices: TArray<string>;
  end;

  /// <summary>
  ///   What the options do when they are confirmed: the choice of the fonts is kept (fonts.cfg) and the fonts of the
  ///   game are laid again. Without one in the host nothing happens
  /// </summary>
  IXcomFontReloader = interface
    ['{7F3B1C90-5A2E-4D67-8B14-183000000023}']
    /// <returns>
    ///   What the user has to be told, one text for each font of the system that could not be used as chosen (not
    ///   installed, too large for the cells of the game); empty when everything was applied
    /// </returns>
    function Reload(const AResources: IXcomResources): TArray<string>;
  end;

implementation

end.
