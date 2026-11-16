{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the drawing of a text asks of the game        }
{                                                                              }
{  Port of war1 (acoto87/war1), war_font.c (context->debugRender.flags), (c)    }
{  2019 Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt). }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Text.Intf;

interface

type
  /// <summary>
  ///   The one thing the text renderer reads of the game: the flag "font" of the debug drawing, that fills the box of every
  ///   glyph and outlines every text and every line. Every scene draws texts, so the flag cannot be read by the map
  /// </summary>
  IWarTextDebug = interface
    ['{4C9E2A71-B3D8-4F05-A6C1-9D27E58B03F4}']
    /// <summary>context->debugRender.flags[WAR_DEBUG_RENDER_FONT]</summary>
    function IsFontOutlineOn: Boolean;
  end;

implementation

end.
