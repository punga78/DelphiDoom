{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the end screen (ENDOOM, ENDTEXT, ENDSTRF)               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Endoom.Intf;

interface

uses
  d_delphi,
  d_event;

const
  /// <summary>The texture of OpenGL that holds the picture of 640x200 pixels</summary>
  ENDOOM_TEXTURE_WIDTH = 1024;
  ENDOOM_TEXTURE_HEIGHT = 256;

type
  /// <summary>
  ///   The text screen shown when the game ends: the composition root gives it to the main loop
  ///   (d_main draws it and frees it), to the game (g_game starts it and gives it the keys), to
  ///   the network loop (d_net makes it tick) and, in OpenGL, to the video (gl_main shows it).
  ///   It was the facade e_endoom.pas
  /// </summary>
  IEngineEndoomScreen = interface
    ['{0B7E5C93-24DA-4F81-A6C2-9D3E18F5B047}']
    /// <summary>Reads DOSFONT and the palette, and starts the count of the screen (E_Init)</summary>
    procedure Initialize;
    /// <summary>
    ///   Draws the lump on the screen (software) or in the texture (OpenGL), again only when
    ///   the picture changed (E_Drawer)
    /// </summary>
    procedure Draw;
    /// <summary>One tic: the blinking, and after ten seconds the program closes (E_Ticker)</summary>
    procedure Tick;
    /// <summary>
    ///   A key released after half a second on the screen closes the program (E_Responder)
    /// </summary>
    function Respond(const AEvent: Pevent_t): Boolean;
    /// <summary>Frees the pictures (E_ShutDown)</summary>
    procedure Shutdown;
    /// <summary>
    ///   OpenGL: the texture, ENDOOM_TEXTURE_WIDTH x ENDOOM_TEXTURE_HEIGHT pixels, after Draw;
    ///   nil before and in the software renderer
    /// </summary>
    function Pixels32: PLongWordArray;
  end;

implementation

end.
