{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the rules of the level ask of the game      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of CheckItems,    }
{  CheckHere, TimeUpdate, EndLevel, WarpAnim and Special_Code of raven.pas to   }
{  display.pas, d_ints.pas, d_disk.pas, d_video.pas, utils.pas and event.pas    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Level.Intf;

interface

uses
  DelphiDoom.Greed.Types;

type
  /// <summary>clock of i_windows.pas: the clock of the system, that the original adds to its random numbers</summary>
  IGreedSystemClock = interface
    ['{E2A64B07-93D1-4C5F-8A70-5B1F6D3C9E24}']
    /// <summary>clock: an unsigned 32 bit count that only goes up</summary>
    function Clock: Cardinal;
  end;

  /// <summary>What the pickup of an item asks of the status bar, of the weapon in the hand and of the input</summary>
  IGreedItemHost = interface
    ['{7C19D5A3-0E46-4B82-B3F9-64A8E1D20C75}']
    /// <summary>oldinventory := -2; inventoryleft; inventoryright: the inventory is drawn again</summary>
    procedure RefreshInventory;
    /// <summary>oldshots := -1: the ammunition is drawn again</summary>
    procedure RefreshAmmo;
    /// <summary>loadweapon(n): the pictures of the weapon n</summary>
    procedure LoadWeapon(AWeapon: Integer);
    /// <summary>weaponpic[0].height: the height of the first picture of the weapon in the hand</summary>
    function GetWeaponPictureHeight: Integer;
    /// <summary>ResetMouse: the movement of the mouse that was not read yet is thrown away (a warp)</summary>
    procedure ResetMouse;
  end;

  /// <summary>What the use key (CheckHere) asks of the movement of the player</summary>
  IGreedSwitchHost = interface
    ['{41F8B6C2-D75A-4E03-9C1B-8E2A07F5D369}']
    /// <summary>TryDoor(cx, cy): a door near the place starts to open; the result is not used</summary>
    function TryDoor(ACenterX, ACenterY: TGreedFixed): Boolean;
  end;

  /// <summary>
  ///   The other parts of the game that one TimeUpdate runs, in the order of the original. The spawn areas, the
  ///   bonus item, the charge of the weapons and the sound of the doors are in TGreedLevelRules
  /// </summary>
  IGreedTicParts = interface
    ['{95D0E3F8-2A6B-47C1-B4E5-13C9F7A8D046}']
    /// <summary>UpdateMouse of d_ints.pas (three times in a TimeUpdate)</summary>
    procedure UpdateInput;
    /// <summary>UpdateSound of modplay.pas</summary>
    procedure UpdateSound;
    /// <summary>Process of event.pas: the zones of the script that are running (called only if there are any)</summary>
    procedure RunProcesses;
    /// <summary>memset(reallight, 0): the lights of the tiles are cleared before the sprites think</summary>
    procedure ClearTileLights;
    /// <summary>MoveSprites of sprites.pas</summary>
    procedure MoveSprites;
    /// <summary>CheckElevators of raven.pas (TGreedElevatorRules.Check with the player and fallrate)</summary>
    procedure CheckElevators;
  end;

  /// <summary>What the rules of the level ask of the screen, of the lumps and of the loading of a map</summary>
  IGreedLevelHost = interface
    ['{0B73A9E6-C418-4D2F-A5B7-F6E08D3219CA}']
    /// <summary>oldgoalitem := -1: the goal item of the status bar is drawn again</summary>
    procedure RefreshGoalItem;
    /// <summary>totaleffecttime := n (display.pas): how long the special effect that starts now lasts</summary>
    procedure SetTotalEffectTime(ATics: Integer);
    /// <summary>CA_ReadLump(CA_GetNamedNum(name), colormaps): WARPLIGHTS while warping, LIGHTS after</summary>
    procedure LoadColorMaps(const ALumpName: string);
    /// <summary>SC.ambientlight</summary>
    function GetAmbientLight: Integer;
    /// <summary>
    ///   VI_FadeOut(0, 256, 0, 0, 0, 64); R_ClearRenderBuffer; the screen is cleared and the palette of the game
    ///   is set again: the end of a level, before the next map
    /// </summary>
    procedure FadeOutLevel;
    /// <summary>resetdisplay of display.pas</summary>
    procedure ResetDisplay;
    /// <summary>loadweapon(n)</summary>
    procedure LoadWeapon(AWeapon: Integer);
    /// <summary>newmap(map, activate) and INT_TimerHook(PlayerCommand)</summary>
    procedure NewMap(AMap, AActivate: Integer);
  end;

  /// <summary>What the secret codes ask of the rest of the game</summary>
  IGreedCheatHost = interface
    ['{D8E25F14-6B09-4A7C-91D3-2F5C0A84B6E7}']
    /// <summary>oldshots := -1</summary>
    procedure RefreshAmmo;
    /// <summary>gameepisode := n (m_defs.pas)</summary>
    procedure SetGameEpisode(AEpisode: Integer);
    /// <summary>newmap(map, 2)</summary>
    procedure NewMap(AMap, AActivate: Integer);
    /// <summary>INT_TimerHook(PlayerCommand): after a go code</summary>
    procedure RestoreTimerHook;
    /// <summary>loadweapon(n)</summary>
    procedure LoadWeapon(AWeapon: Integer);
  end;

implementation

end.
