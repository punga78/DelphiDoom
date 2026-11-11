{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - what the battle asks of the screen    }
{  (the calls of BattlescapeGame and of its steps to BattlescapeState, Map and  }
{  Camera: warnings, sounds, animations, the camera)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.View.Intf;

interface

uses
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Model;

type
  /// <summary>
  ///   Everything that the rules of the battle (BattlescapeGame and its steps) ask of the parent state, the map
  ///   and the camera, and that has no effect on the saved battle: messages, sounds, the camera, the sprite cache,
  ///   the animation of the explosions. A battle without a screen uses TXcomBattleNullView; the drawing of the
  ///   battlescape implements it
  /// </summary>
  IXcomBattleView = interface
    ['{6E1B0D43-92C7-4A58-B0F3-5D8A41C7E260}']
    /// <summary>BattlescapeState::warning: a text id of the language (STR_NOT_ENOUGH_TIME_UNITS)</summary>
    procedure Warning(const AMessage: string);
    /// <summary>BattlescapeState::debug</summary>
    procedure Debug(const AMessage: string);
    /// <summary>BattlescapeState::updateSoldierInfo</summary>
    procedure UpdateSoldierInfo;
    /// <summary>Camera::centerOnPosition</summary>
    procedure CenterOnPosition(const APosition: TXcomPosition; AGraphic: Boolean = True);
    /// <summary>Camera::setViewLevel</summary>
    procedure SetViewLevel(ALevel: Integer);
    /// <summary>Camera::isOnScreen (the position in tiles)</summary>
    function IsOnScreen(const APosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
      ABoundary: Boolean): Boolean;
    /// <summary>Map::cacheUnits</summary>
    procedure CacheUnits;
    /// <summary>Map::cacheUnit</summary>
    procedure CacheUnit(const AUnit: TXcomBattleUnit);
    /// <summary>BattlescapeState::setStateInterval (the speed of the steps)</summary>
    procedure SetStateInterval(AMilliseconds: Integer);
    /// <summary>BattlescapeState::showPsiButton</summary>
    procedure ShowPsiButton(AShow: Boolean);
    /// <summary>BattlescapeState::showLaunchButton</summary>
    procedure ShowLaunchButton(AShow: Boolean);
    /// <summary>Map::setUnitDying</summary>
    procedure SetUnitDying(ADying: Boolean);
    /// <summary>Map::setCursorType</summary>
    procedure SetCursorType(ACursorType: Integer; ASize: Integer = 1);
    /// <summary>Sound::play of a sound of the mod (the index of the SoundSet), with the angle of the position</summary>
    procedure PlaySound(ASound: Integer; const APosition: TXcomPosition);
    /// <summary>
    ///   A new explosion sprite (Map::getExplosions()->push_back(new Explosion(...))): the center in voxels, the
    ///   first frame, the delay in frames, and whether it is a big (area) explosion, a hit or a bullet
    /// </summary>
    procedure AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig, AHit: Boolean);
    /// <summary>Map::setProjectile: the projectile in flight that the map draws (a TXcomProjectile), or nil</summary>
    procedure SetProjectile(const AProjectile: TObject);
    /// <summary>Map::setBlastFlash</summary>
    procedure SetBlastFlash(AFlash: Boolean);
    /// <summary>Map::getBlastFlash: the screen is still shown in EGA</summary>
    function BlastFlash: Boolean;
    /// <summary>
    ///   The animation of the explosions of the map (the loop of ExplosionBState::think over
    ///   Map::getExplosions()): true when there is nothing left to animate
    /// </summary>
    function AnimateExplosions: Boolean;
    /// <summary>The player's soldier died: the geoscape forgets it (SavedGame::killSoldier)</summary>
    procedure SoldierKilled(const AUnit: TXcomBattleUnit);
    /// <summary>InfoboxState / InfoboxOKState: a message box about a unit (text id, and whether it needs OK)</summary>
    procedure ShowUnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string; ANeedsConfirmation: Boolean);
    /// <summary>BattlescapeState::finishBattle</summary>
    procedure FinishBattle(AAbort: Boolean; AInExitArea: Integer);
    /// <summary>The NextTurnState that BattlescapeGame::endTurn pushes</summary>
    procedure NextTurn;
  end;

implementation

end.
