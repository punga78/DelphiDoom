{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the parts of a game, for the adapters between    }
{  them                                                                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game.Parts;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Random,
  DelphiDoom.Greed.Sound.Intf, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.GameView.Intf,
  DelphiDoom.Greed.GameRenderer.Intf, DelphiDoom.Greed.Spawner, DelphiDoom.Greed.Events,
  DelphiDoom.Greed.SpriteLogic, DelphiDoom.Greed.SpriteDeath, DelphiDoom.Greed.PlayerRules,
  DelphiDoom.Greed.PlayerMovement, DelphiDoom.Greed.PlayerControl, DelphiDoom.Greed.PlayerWeapons,
  DelphiDoom.Greed.WeaponPictures, DelphiDoom.Greed.ElevatorRules, DelphiDoom.Greed.DoorRules,
  DelphiDoom.Greed.ItemRules, DelphiDoom.Greed.SwitchRules, DelphiDoom.Greed.LevelRules,
  DelphiDoom.Greed.CheatCodes, DelphiDoom.Greed.MapSession, DelphiDoom.Greed.Inventory;

type
  /// <summary>
  ///   What TGreedGame is made of, in one place: the adapters that answer the parts (the hosts of
  ///   DelphiDoom.Greed.Game.Hosts.*) are made before the parts and find here the ones that are made after them.
  ///   Each part still gets its dependencies from its constructor as interfaces; this object is only how the
  ///   adapters reach the concrete parts of the same game. The parts that are classes are owned by TGreedGame, the
  ///   ones that are interfaces are released by it before the hosts
  /// </summary>
  TGreedGameParts = class
  public
    // ---- given to the game ----
    Archive: IGreedArchive;
    Random: IGreedRandom;
    Clock: IGreedSystemClock;
    Effects: IGreedSoundEffects;
    Music: IGreedMusic;
    View: IGreedGameView;
    Messages: IGreedMessages;
    Controls: IGreedControls;
    // ---- made by the game ----
    World: IGreedWorld;
    Sprites: TGreedLinkedPool<TGreedSprite>;
    Elevators: TGreedLinkedPool<TGreedElevator>;
    State: TGreedGameState;
    Renderer: IGreedGameRenderer;
    Spawner: TGreedSpawner;
    SpawnerIntf: IGreedSpawner;
    Events: TGreedEvents;
    EventsIntf: IGreedEventRunner;
    WeaponPictures: TGreedWeaponPictures;
    WeaponView: IGreedWeaponView;
    Weapons: TGreedPlayerWeapons;
    WeaponsIntf: IGreedPlayerWeapons;
    SpriteLogic: TGreedSpriteLogic;
    Death: TGreedSpriteDeath;
    PlayerRules: TGreedPlayerRules;
    Movement: TGreedPlayerMovement;
    ElevatorRules: TGreedElevatorRules;
    DoorRules: TGreedDoorRules;
    Control: TGreedPlayerControl;
    Items: TGreedItemRules;
    Switches: TGreedSwitchRules;
    Level: TGreedLevelRules;
    Cheats: TGreedCheatCodes;
    Session: TGreedMapSession;
    Inventory: TGreedInventory;
    // ---- the settings of the game (SC of the original) and the globals that are of no part ----
    /// <summary>SC.ambientlight</summary>
    AmbientLight: Integer;
    /// <summary>lowresolution of raven.pas</summary>
    LowResolution: Boolean;
    /// <summary>nethurtsoundtime of utils.pas</summary>
    NetHurtSoundTime: Integer;
    /// <summary>gameepisode of m_defs.pas</summary>
    GameEpisode: Integer;
  end;

implementation

end.
