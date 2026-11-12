{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the events of a map ask of the game         }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the constants of event.pas  }
{  and the calls that event.pas makes to sprites.pas, playfli.pas and menu.pas  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Events.Intf;

interface

const
  // ---- the kinds of a zone (zone_t.typ); a zone that was used and can be removed has -1 ----

  GREED_ZONE_REMOVED = -1;
  GREED_ZONE_ACTIVATION = 0;
  GREED_ZONE_MAP = 1;
  GREED_ZONE_SPAWN = 2;
  GREED_ZONE_TRIGGER = 3;
  GREED_ZONE_SOUND = 4;
  GREED_ZONE_FLI = 5;
  GREED_ZONE_AREA_TRIGGER = 6;

  // ---- the planes that a MAPZONE can change (zone_t.layer); the other values of the original are not done ----

  GREED_LAYER_NORTH_WALL = 0;
  GREED_LAYER_WEST_WALL = 2;
  GREED_LAYER_FLOOR = 4;
  GREED_LAYER_CEILING = 6;
  GREED_LAYER_FLOOR_HEIGHT = 8;
  GREED_LAYER_CEILING_HEIGHT = 9;
  GREED_LAYER_LIGHTS = 14;
  GREED_LAYER_EFFECTS = 15;

  /// <summary>A process is the number of its zone plus this</summary>
  GREED_PROCESS_BASE = 1000;
  /// <summary>The sky behind the map: two pictures of 256 x 128, one after the other</summary>
  GREED_BACKDROP_HALF_BYTES = 256 * 128;
  GREED_BACKDROP_BYTES = 2 * GREED_BACKDROP_HALF_BYTES;
  /// <summary>How many FORCELOAD lines a script can have (loadsprites of LoadScript)</summary>
  GREED_MAX_FORCE_LOADS = 16;
  /// <summary>The films of SPAWNFLI: JETTISON.FLI, TMPL_DIE.FLI, KAAL_DIE.FLI</summary>
  GREED_FLI_COUNT = 3;

type
  /// <summary>
  ///   The parts of the game that event.pas calls and that are not the spawner, the sound or the archive: who
  ///   builds the game gives them
  /// </summary>
  IGreedEventHost = interface
    ['{5A9E3C17-48D2-4B6F-9A10-C7E2B4D85F31}']
    /// <summary>ActivationSound(sp) of sprites.pas: ASprite is the index in the pool of the sprites</summary>
    procedure ActivationSound(ASprite: Integer);
    /// <summary>
    ///   The film of a SPAWNFLI zone (0 JETTISON.FLI, 1 TMPL_DIE.FLI, 2 KAAL_DIE.FLI; the original does not check
    ///   the number): DoPlayFLI, then the line of text in font1, colour 8, centred at 160, 185 ("Do not taunt happy
    ///   fun airlock.", "Original recipe or extra crispy?", "Thank you for recycling!") and the screen of the VR
    ///   helmet put back. The events then mark the film as played and the player dies (angst 0)
    /// </summary>
    procedure PlayFli(AMovie: Integer);
    /// <summary>UpdateWait of menu.pas: the picture that turns while a map is loaded</summary>
    procedure UpdateWait;
  end;

implementation

end.
