{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the contract of the drawing of the heads-up display    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Hud.Intf;

{$I Doom32.inc}

interface

type
  /// <summary>
  ///   What hu_stuff.pas asks of the drawing of the heads-up display, once for every frame (never
  ///   for a character or a pixel): the drawing reads the model through IHudView
  /// </summary>
  IHudScreen = interface
    ['{6D3A91E7-B4C8-4F52-A0D9-8E17C25F3B60}']
    /// <summary>The fonts are loaded: the widths of the glyphs are read and the crosshairs loaded (end of HU_Init)</summary>
    procedure Initialize;
    /// <summary>Draws the heads-up display of a frame (HU_Drawer)</summary>
    procedure Draw;
    /// <summary>Erases the borders where the text was (HU_Erase)</summary>
    procedure Erase;
    /// <summary>Rows the messages took in the last frame, in OpenGL (HU_Height)</summary>
    function Height: Integer;
{$IFDEF STRIFE}
    /// <summary>Writes text in the yellow font of Strife, that goes to the next row at the edge (HUlib_drawYellowText)</summary>
    procedure DrawYellowText(const AX, AY: Integer; const AText: string; const AScreen: Integer);
{$ENDIF}
  end;

implementation

end.
