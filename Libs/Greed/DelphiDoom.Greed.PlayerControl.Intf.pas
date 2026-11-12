{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the control of the player asks around       }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the commands that           }
{  ControlMovement of raven.pas reads and the calls it makes to other units     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PlayerControl.Intf;

interface

uses
  DelphiDoom.Greed.Types;

const
  /// <summary>
  ///   The value of TGreedGameState.MSprite while the sprite that moves is the probe of the game (msprite := @probe
  ///   of the original): the probe is not in the pool, so it is not an index and it is not GREED_POOL_NIL
  /// </summary>
  GREED_SPRITE_PROBE = -2;

type
  /// <summary>
  ///   What the player can ask in a tic. The first 19 are the buttons of the original (in_button[bt_*], in its
  ///   order), the others are the keys that ControlMovement reads straight from the keyboard (the key of the
  ///   original is in the comment). Which key gives which command is decided by the adapter of the program: in the
  ///   original some keys give two commands (SPACE is gcUse and gcRestart, LEFT SHIFT is gcRun and gcShift, ALT is
  ///   gcStrafe and gcAlt)
  /// </summary>
  TGreedCommand = (
    /// bt_north .. bt_motionmode
    gcNorth, gcEast, gcSouth, gcWest, gcFire, gcStrafe, gcUse, gcRun, gcJump, gcUseItem, gcRearView, gcLookUp,
    gcLookDown, gcCenterView, gcSlideLeft, gcSlideRight, gcInventoryLeft, gcInventoryRight, gcMotionMode,
    /// SC_ESCAPE: the menu
    gcMenu,
    /// SC_LSHIFT with F1 .. F5: the settings of the VR helmet
    gcShift,
    /// SC_F1: the help (with gcShift the VR angle goes down, and the help opens too)
    gcHelp,
    /// SC_F2 with gcShift: the VR angle goes up
    gcVrAngleUp,
    /// SC_F3 with gcShift: the near VR distance
    gcVrDistanceNear,
    /// SC_F4: the quick exit (with gcShift the far VR distance, and the quick exit too)
    gcQuickExit,
    /// SC_F5: the briefing of the mission (with gcShift the VR settings go back to the default, and the briefing too)
    gcBriefing,
    /// SC_F6: a message to the other players (net game only)
    gcNetMessage,
    /// SC_F7: another song
    gcNewSong,
    /// SC_F9 and SC_F10: the size of the view
    gcViewBigger, gcViewSmaller,
    /// SC_ALT and SC_Q together: the quick exit
    gcAlt, gcQuit,
    /// SC_P
    gcPause,
    /// SC_MINUS and SC_PLUS: the zoom of the map
    gcMapZoomOut, gcMapZoomIn,
    /// SC_M, SC_H, SC_TAB
    gcMapMode, gcHeatMode, gcGoalItem,
    /// SC_CAPSLOCK and SC_NUMLOCK
    gcAutoRun, gcAutoTarget,
    /// SC_SPACE when the player is dead
    gcRestart,
    /// SC_1 .. SC_5
    gcWeapon1, gcWeapon2, gcWeapon3, gcWeapon4, gcWeapon5);

  /// <summary>The buttons of the mouse: mbt_fire (left), mbt_use (right), mbt_north (middle)</summary>
  TGreedMouseButton = (gmbFire, gmbUse, gmbNorth);

  /// <summary>
  ///   The state of the commands as INT_ReadControls of d_ints.pas leaves it (the original reads the keys on the odd
  ///   tics, just before ControlMovement uses them). The class has no scan codes: the adapter of the program maps
  ///   the keys to the commands
  /// </summary>
  IGreedControls = interface
    ['{B5E0D7A4-3C19-4F86-A2D7-90C4E6B1F358}']
    /// <summary>keyboard[k] &lt;&gt; 0 or in_button[b] &lt;&gt; 0: the command is held down</summary>
    function IsDown(ACommand: TGreedCommand): Boolean;
    /// <summary>keyboard[k] = 1: held down and not eaten since it went down</summary>
    function IsFresh(ACommand: TGreedCommand): Boolean;
    /// <summary>eat_key(k): the command is not fresh any more until it is released and pressed again</summary>
    procedure Eat(ACommand: TGreedCommand);
    /// <summary>
    ///   newascii and lastascii: True once for each character typed since the last call (the last one typed, upper
    ///   case), then False
    /// </summary>
    function TakeCharacter(out ACharacter: Char): Boolean;
    /// <summary>mouse.flags: the buttons of the mouse that are down</summary>
    function IsMouseDown(AButton: TGreedMouseButton): Boolean;
    /// <summary>mouse.dx and mouse.dy: how far the mouse went since the last reading (left and up are positive)</summary>
    function GetMouseDeltaX: Integer;
    function GetMouseDeltaY: Integer;
    property MouseDeltaX: Integer read GetMouseDeltaX;
    property MouseDeltaY: Integer read GetMouseDeltaY;
  end;

  /// <summary>
  ///   What the control of the player calls in parts of the game that are other classes: the switches on the walls
  ///   (CheckForSwitch and SwitchWall of raven.pas) and the lights of the renderer (RF_SetLights of r_public.pas)
  /// </summary>
  IGreedPlayerControlHost = interface
    ['{4A7C9E12-D8B3-4065-B1F4-27E5A0C36D89}']
    /// <summary>CheckForSwitch(x, y, angle, doubleswitch): True if the player faces a switch of that tile</summary>
    function CheckForSwitch(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean): Boolean;
    /// <summary>SwitchWall(x, y, angle, doubleswitch): the picture of the switch changes</summary>
    procedure SwitchWall(ATileX, ATileY, AAngle: Integer; ADoubleSwitch: Boolean);
    /// <summary>RF_SetLights(blackz): the distance at which the view is black</summary>
    procedure SetLights(ABlackZ: TGreedFixed);
  end;

  /// <summary>
  ///   The pictures of the weapon in the hands of the player (weaponpic and loadweapon of utils.pas): the control of
  ///   the weapons needs their size to know when a weapon that is being changed is out of the view
  /// </summary>
  IGreedWeaponView = interface
    ['{E19B6D03-7F4A-4C52-98E6-3B0D5A71C2F4}']
    /// <summary>loadweapon(n): the pictures of the weapon n replace the ones of the weapon before</summary>
    procedure LoadWeapon(AWeapon: Integer);
    /// <summary>weaponpic[mode].width and .height of the weapon that is loaded</summary>
    function PictureWidth(AMode: Integer): Integer;
    function PictureHeight(AMode: Integer): Integer;
  end;

  /// <summary>The weapons of the player (TGreedPlayerWeapons)</summary>
  IGreedPlayerWeapons = interface
    ['{8D2F5B67-A1C4-4E90-B3D8-6C0E4F9A1257}']
    /// <summary>chargeweapons: the weapons of the player get 20 of charge at their rate, up to 100</summary>
    procedure ChargeWeapons;
    /// <summary>GetTargetAngle(n, pz): the vertical angle of a shot</summary>
    function GetTargetAngle(AOffset: Integer; AHeight: TGreedFixed): Integer;
    /// <summary>fireweapon: the weapon in the hands shoots if there is ammunition</summary>
    procedure FireWeapon;
    /// <summary>The loop "update weapon to be displayed" at the end of PlayLoop</summary>
    procedure AdvanceWeaponMode;
    /// <summary>
    ///   The part of UpdateView that places the picture of the weapon and carries on a change of weapon; AUpdate is
    ///   update &lt;&gt; 0 of the original (a new image and not the same one drawn again)
    /// </summary>
    procedure UpdateWeaponView(AUpdate: Boolean; AWindowWidth, AWindowHeight: Integer; out AWeaponX,
      AWeaponY: Integer);
  end;

implementation

end.
