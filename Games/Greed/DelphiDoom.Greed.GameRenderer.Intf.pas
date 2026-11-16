{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the game asks of the renderer of the view   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the globals of r_public,    }
{  r_render and r_refdef that raven.pas, sprites.pas and event.pas write        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.GameRenderer.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.Random,
  DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Spawner.Intf, DelphiDoom.Greed.SpriteLogic.Intf, DelphiDoom.Greed.Hud.Intf;

type
  /// <summary>
  ///   The renderer as the game uses it. In the original the game and the renderer share globals: the lights that
  ///   the sprites add to the tiles (reallight), the tables that animate walls and flats (walltranslation,
  ///   flattranslation), the tables of the light (colormaps, RF_SetLights), the sky (backdrop), the pictures of the
  ///   monsters that are loaded when they are first needed and the hook that the renderer calls while it draws
  /// </summary>
  IGreedGameRenderer = interface(IGreedSpritePictures)
    ['{58C1E7A3-0D94-4B6F-A2E8-71F3B9C04D56}']
    /// <summary>RF_RenderView(x, y, z, angle) into AFrame; the walls seen are marked in the maps of APlayer</summary>
    procedure RenderView(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY, AZ: TGreedFixed;
      AAngle: Integer; var AFrame: TGreedFrame);
    /// <summary>
    ///   RF_RenderView for the rear view camera (RearView of raven.pas): as RenderView, with the view not moved
    ///   up or down by the look of the player
    /// </summary>
    procedure RenderCamera(const AWorld: IGreedWorld; var APlayer: TGreedPlayerRecord; AX, AY, AZ: TGreedFixed;
      AAngle: Integer; var AFrame: TGreedFrame);
    /// <summary>reallight: 4096 lights that the sprites write and the renderer reads; nil if there are none</summary>
    function TileLights: PGreedTileLights;
    /// <summary>RF_SetLights(blackz)</summary>
    procedure SetLights(ABlackZ: TGreedFixed);
    /// <summary>flattranslation[flat] := picture and walltranslation[wall] := picture</summary>
    procedure SetFlatTranslation(AFlat, APicture: Integer);
    procedure SetWallTranslation(AWall, APicture: Integer);
    /// <summary>CA_ReadLump(CA_GetNamedNum(name), colormaps): LIGHTS, or WARPLIGHTS during a warp</summary>
    procedure LoadColorMaps(const ALumpName: string);
    /// <summary>The sky of the map: 256 x 256 pixels (the BACKDROP of the script)</summary>
    procedure SetBackdrop(const APixels: TBytes);
    /// <summary>RF_CheckActionFlag is called on AHook while a view is drawn; nil for none</summary>
    procedure SetActionHook(const AHook: IGreedRenderActionHook);
    /// <summary>
    ///   fxtimecount := time: the clock of the effects of the walls (glow, flicker), that resetengine puts back to 0
    ///   with the clock of the game
    /// </summary>
    procedure SetEffectsTime(ATime: Integer);
    /// <summary>The light of the tile of the player on the weapon (the HUD paints the weapon); nil if there is none</summary>
    function WeaponLight: IGreedWeaponLight;
    /// <summary>reallight as the HUD reads it (the heat map); nil if there is none</summary>
    function TileLightReader: IGreedTileLights;
  end;

  /// <summary>
  ///   The variables that r_render.pas declares after reallight and that its compiler puts after it in memory, one
  ///   integer each: actionflag (which belongs to the game), then wallglow, wallglowindex, wallrotate, maplight,
  ///   wallflicker1 .. wallflicker4, wallflags, wallcycle, frameon and the first entries of framevalid. Optional
  ///   (asked with Supports): only who plays the game with the defect of the light written outside the map needs it
  /// </summary>
  IGreedRenderMemory = interface
    ['{91F3B6D4-2A7C-4E05-B8C1-5D60E4A927F3}']
    /// <summary>
    ///   The integer AOffset places after actionflag (1 is wallglow, 11 frameon, 12 framevalid[0]) gets AAmount
    ///   less. Nothing for an offset below 1 or past framevalid
    /// </summary>
    procedure SubtractAfterTileLights(AOffset, AAmount: Integer);
  end;

  /// <summary>
  ///   Makes the renderer of a game. The game owns the list of the sprites, the clock of the tics and the sequence
  ///   of the random numbers, and the renderer of the original reads all three: so the game is made first and asks
  ///   for its renderer with them
  /// </summary>
  IGreedGameRendererFactory = interface
    ['{0E9A3D75-B4C2-4F18-96D0-C5A7E1B38F42}']
    function CreateRenderer(ASprites: TGreedLinkedPool<TGreedSprite>; const AClock: IGreedRenderClock;
      const ARandom: IGreedRandom): IGreedGameRenderer;
  end;

implementation

end.
