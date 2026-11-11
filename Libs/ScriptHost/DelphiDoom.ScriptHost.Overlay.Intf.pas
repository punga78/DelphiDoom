{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what the overlay drawer asks of the engine        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Overlay.Intf;

interface

uses
  DelphiDoom.ScriptHost.Overlay.Types;

type
  /// <summary>
  ///   The video, the lumps and the clock that the overlay drawer reads and writes (in the engine
  ///   v_video, r_hires, w_wad, hu_stuff and the level time; in the tests a fake). The drawer
  ///   calls it once for each drawer or character, never for each pixel
  /// </summary>
  IOverlayCanvas = interface
    ['{5B13E8A7-92C4-4F60-A1D5-6E07B3C98F24}']
    /// <summary>Width of the screen the overlay is flashed over, in pixels</summary>
    function ScreenWidth: Integer;
    /// <summary>Height of the screen the overlay is flashed over, in pixels</summary>
    function ScreenHeight: Integer;
    /// <summary>The tics of the level so far</summary>
    function LevelTime: Integer;
    /// <summary>The palette index nearest to a color</summary>
    function FindColorIndex(const ARed, AGreen, ABlue: Byte): Byte;
    /// <summary>The lump of a patch or a sprite, or a negative number if there is none</summary>
    function FindPatchLump(const AName: string): Integer;
    /// <summary>The patch of a lump (the engine keeps it in memory)</summary>
    function CachePatch(const ALump: Integer): Pointer;
    /// <summary>The patch of the font for a character, or nil if the font has no such character</summary>
    function FontPatch(const AChar: Char): Pointer;
    /// <summary>True on the first frame of a tic (the drawers are drawn again only then)</summary>
    function IsFirstInterpolation: Boolean;
    /// <summary>A warning for the player of the game (a patch that does not exist, an unknown drawer)</summary>
    procedure Warning(const AText: string);
    /// <summary>Tells the renderer that the background behind the overlay must be drawn again</summary>
    procedure MarkScreenDirty;
    /// <summary>Puts the overlay over the frame, with the threads of the engine when it uses them</summary>
    procedure Flash(const AData: TOverlayFlashData);
  end;

implementation

end.
