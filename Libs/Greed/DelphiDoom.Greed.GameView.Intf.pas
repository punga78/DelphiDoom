{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the game asks of who draws around the view  }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the calls of raven.pas and  }
{  utils.pas to display.pas, menu.pas, intro.pas, playfli.pas and d_video.pas   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.GameView.Intf;

interface

uses
  DelphiDoom.Greed.Frame.Intf;

type
  /// <summary>
  ///   What UpdateView of raven.pas knows when the view of the level is drawn and the rest (the weapon, the status
  ///   bar, the message) goes over it. The picture of the weapon is drawn only when WeaponVisible is True (the
  ///   player is alive); a WeaponLump of -1 is a weapon without pictures
  /// </summary>
  TGreedViewOverlay = record
    /// <summary>player.angst &lt;&gt; 0</summary>
    WeaponVisible: Boolean;
    /// <summary>The lump of weaponpic[weapmode] (a pic_t)</summary>
    WeaponLump: Integer;
    /// <summary>weaponx and weapony: where the picture goes in the view</summary>
    WeaponX: Integer;
    WeaponY: Integer;
    /// <summary>weapmode: 0 is drawn with VI_DrawMaskedPicToBuffer2, the others with VI_DrawMaskedPicToBuffer</summary>
    WeaponMode: Integer;
    /// <summary>mapmode (0 none, 1 the map, 2 the map that turns), heatmode and motionmode</summary>
    MapMode: Integer;
    HeatMode: Boolean;
    MotionMode: Boolean;
    /// <summary>timecount when the view was drawn</summary>
    TimeCount: Integer;
  end;

  /// <summary>
  ///   Everything that the game shows and that is not the view of the level: the status bar (display.pas), the
  ///   screens between the maps (utils.pas, intro.pas), the films (playfli.pas), the menus (menu.pas). The game
  ///   only says when; who implements it draws. An implementation that does nothing is a game without HUD
  /// </summary>
  IGreedGameView = interface
    ['{D1B64E08-7A25-4C93-B0F6-3E8C5A91D274}']
    /// <summary>oldshots := -1: the ammunition is drawn again</summary>
    procedure RefreshAmmo;
    /// <summary>oldgoalitem := -1: the goal item is drawn again</summary>
    procedure RefreshGoalItem;
    /// <summary>timemsg := 0 (resetengine): the message that was shown goes away</summary>
    procedure ResetMessages;
    /// <summary>resetdisplay of display.pas: everything of the status bar is drawn again</summary>
    procedure ResetDisplay;
    /// <summary>totaleffecttime := n: how long the special effect that starts now lasts (its bar)</summary>
    procedure SetTotalEffectTime(ATics: Integer);
    /// <summary>MissionBriefing(map): the screens before a map of a new game</summary>
    procedure MissionBriefing(AMap: Integer);
    /// <summary>EndGame1, EndGame2 or EndGame3: the end of an episode</summary>
    procedure EndGame(AEpisode: Integer);
    /// <summary>The film of a SPAWNFLI zone and its line of text (see IGreedEventHost.PlayFli)</summary>
    procedure PlayFli(AMovie: Integer);
    /// <summary>StartWait, UpdateWait and EndWait of menu.pas: the picture that turns while a map is loaded</summary>
    procedure StartWait;
    procedure UpdateWait;
    procedure EndWait;
    /// <summary>VI_FadeOut, the screen cleared and the palette of the game again: the end of a level</summary>
    procedure FadeOutLevel;
    /// <summary>ChangeViewSize(biggerScreen) of utils.pas</summary>
    procedure ChangeViewSize(ABigger: Boolean);
    /// <summary>gameepisode := n of a secret code</summary>
    procedure SetGameEpisode(AEpisode: Integer);
    /// <summary>ShowMenu(0): the menu of the game; True if the player chose to quit</summary>
    function ShowMenu: Boolean;
    /// <summary>ShowHelp</summary>
    procedure ShowHelp;
    /// <summary>ShowPause: returns when the game goes on</summary>
    procedure ShowPause;
    /// <summary>ShowQuit: True if the player said yes</summary>
    function ConfirmQuit: Boolean;
    /// <summary>
    ///   The part of UpdateView after RF_RenderView: the holo picture, the rear view, the weapon, the map modes, the
    ///   status bar (updatedisplay) and the message (rewritemsg) go over the view that is in AFrame
    /// </summary>
    procedure DrawOverlay(var AFrame: TGreedFrame; const AOverlay: TGreedViewOverlay);
  end;

implementation

end.
