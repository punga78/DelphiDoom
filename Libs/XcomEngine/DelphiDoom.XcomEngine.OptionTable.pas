{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the table of the options of OpenXcom       }
{  (Options::create: id, type, default, description and category of each one)   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.OptionTable;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.OptionInfo;

type
  /// <summary>The options that OpenXcom registers (OptionInfo), in the order of Options::create</summary>
  TXcomOptionTable = class
  public
    /// <summary>All the options (the Windows build: the defaults of the non-DINGOO, non-MorphOS, non-mobile branches)</summary>
    class function All: TArray<TXcomOptionInfo>; static;
    /// <summary>The option with the id (compared as it is written), or False</summary>
    class function TryFind(const AId: string; out AInfo: TXcomOptionInfo): Boolean; static;
  end;

implementation

const
  OPTIONS: array[0..190] of TXcomOptionInfo = (
    (Id: 'displayWidth'; Kind: okInt; DefaultValue: 640; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'displayHeight'; Kind: okInt; DefaultValue: 400; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'fullscreen'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'asyncBlit'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'keyboardMode'; Kind: okInt; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'maxFrameSkip'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'traceAI'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'verboseLogging'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'StereoSound'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'geoscapeScale'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battlescapeScale'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'useScaleFilter'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'useHQXFilter'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'useXBRZFilter'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'useOpenGL'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'checkOpenGLErrors'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'useOpenGLShader'; Kind: okString; DefaultValue: 0; DefaultText: 'Shaders/Raw.OpenGL.shader'; Description: ''; Category: ''),
    (Id: 'vSyncForOpenGL'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'useOpenGLSmoothing'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'debug'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'debugUi'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'soundVolume'; Kind: okInt; DefaultValue: 84; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'musicVolume'; Kind: okInt; DefaultValue: 84; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'uiVolume'; Kind: okInt; DefaultValue: 42; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'language'; Kind: okString; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleScrollSpeed'; Kind: okInt; DefaultValue: 8; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleEdgeScroll'; Kind: okInt; DefaultValue: 2; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleDragScrollButton'; Kind: okInt; DefaultValue: 2; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'dragScrollTimeTolerance'; Kind: okInt; DefaultValue: 300; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'dragScrollPixelTolerance'; Kind: okInt; DefaultValue: 10; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleFireSpeed'; Kind: okInt; DefaultValue: 6; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleXcomSpeed'; Kind: okInt; DefaultValue: 30; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleAlienSpeed'; Kind: okInt; DefaultValue: 30; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleNewPreviewPath'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'fpsCounter'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'globeDetail'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'globeRadarLines'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'globeFlightPaths'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'globeAllRadarsOnBaseBuild'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'audioSampleRate'; Kind: okInt; DefaultValue: 22050; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'audioBitDepth'; Kind: okInt; DefaultValue: 16; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'audioChunkSize'; Kind: okInt; DefaultValue: 1024; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'pauseMode'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleNotifyDeath'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'showFundsOnGeoscape'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'allowResize'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'windowedModePositionX'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'windowedModePositionY'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'borderless'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'captureMouse'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'battleTooltips'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'keepAspectRatio'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'nonSquarePixelRatio'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'cursorInBlackBandsInFullscreen'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'cursorInBlackBandsInWindow'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'cursorInBlackBandsInBorderlessWindow'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'saveOrder'; Kind: okInt; DefaultValue: 3; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'geoClockSpeed'; Kind: okInt; DefaultValue: 80; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'dogfightSpeed'; Kind: okInt; DefaultValue: 30; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'geoScrollSpeed'; Kind: okInt; DefaultValue: 20; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'geoDragScrollButton'; Kind: okInt; DefaultValue: 2; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'preferredMusic'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'preferredSound'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'preferredVideo'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'wordwrap'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'musicAlwaysLoop'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'touchEnabled'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'rootWindowedMode'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'lazyLoadResources'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'backgroundMute'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'playIntro'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: 'STR_PLAYINTRO'; Category: 'STR_GENERAL'),
    (Id: 'autosave'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: 'STR_AUTOSAVE'; Category: 'STR_GENERAL'),
    (Id: 'autosaveFrequency'; Kind: okInt; DefaultValue: 5; DefaultText: ''; Description: 'STR_AUTOSAVE_FREQUENCY'; Category: 'STR_GENERAL'),
    (Id: 'newSeedOnLoad'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_NEWSEEDONLOAD'; Category: 'STR_GENERAL'),
    (Id: 'mousewheelSpeed'; Kind: okInt; DefaultValue: 3; DefaultText: ''; Description: 'STR_MOUSEWHEEL_SPEED'; Category: 'STR_GENERAL'),
    (Id: 'changeValueByMouseWheel'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: 'STR_CHANGEVALUEBYMOUSEWHEEL'; Category: 'STR_GENERAL'),
    (Id: 'soldierDiaries'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'maximizeInfoScreens'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_MAXIMIZE_INFO_SCREENS'; Category: 'STR_GENERAL'),
    (Id: 'geoDragScrollInvert'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_DRAGSCROLLINVERT'; Category: 'STR_GEOSCAPE'),
    (Id: 'aggressiveRetaliation'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_AGGRESSIVERETALIATION'; Category: 'STR_GEOSCAPE'),
    (Id: 'customInitialBase'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_CUSTOMINITIALBASE'; Category: 'STR_GEOSCAPE'),
    (Id: 'allowBuildingQueue'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_ALLOWBUILDINGQUEUE'; Category: 'STR_GEOSCAPE'),
    (Id: 'craftLaunchAlways'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_CRAFTLAUNCHALWAYS'; Category: 'STR_GEOSCAPE'),
    (Id: 'storageLimitsEnforced'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_STORAGELIMITSENFORCED'; Category: 'STR_GEOSCAPE'),
    (Id: 'canSellLiveAliens'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_CANSELLLIVEALIENS'; Category: 'STR_GEOSCAPE'),
    (Id: 'anytimePsiTraining'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_ANYTIMEPSITRAINING'; Category: 'STR_GEOSCAPE'),
    (Id: 'globeSeasons'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_GLOBESEASONS'; Category: 'STR_GEOSCAPE'),
    (Id: 'globeSurfaceCache'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: ''; Category: ''),
    (Id: 'psiStrengthEval'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_PSISTRENGTHEVAL'; Category: 'STR_GEOSCAPE'),
    (Id: 'canTransferCraftsWhileAirborne'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_CANTRANSFERCRAFTSWHILEAIRBORNE'; Category: 'STR_GEOSCAPE'),
    (Id: 'retainCorpses'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_RETAINCORPSES'; Category: 'STR_GEOSCAPE'),
    (Id: 'fieldPromotions'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_FIELDPROMOTIONS'; Category: 'STR_GEOSCAPE'),
    (Id: 'meetingPoint'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_MEETINGPOINT'; Category: 'STR_GEOSCAPE'),
    (Id: 'battleDragScrollInvert'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_DRAGSCROLLINVERT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'sneakyAI'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_SNEAKYAI'; Category: 'STR_BATTLESCAPE'),
    (Id: 'battleUFOExtenderAccuracy'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_BATTLEUFOEXTENDERACCURACY'; Category: 'STR_BATTLESCAPE'),
    (Id: 'showMoreStatsInInventoryView'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_SHOWMORESTATSININVENTORYVIEW'; Category: 'STR_BATTLESCAPE'),
    (Id: 'battleHairBleach'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: 'STR_BATTLEHAIRBLEACH'; Category: 'STR_BATTLESCAPE'),
    (Id: 'battleInstantGrenade'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_BATTLEINSTANTGRENADE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'includePrimeStateInSavedLayout'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_INCLUDE_PRIMESTATE_IN_SAVED_LAYOUT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'battleExplosionHeight'; Kind: okInt; DefaultValue: 0; DefaultText: ''; Description: 'STR_BATTLEEXPLOSIONHEIGHT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'battleAutoEnd'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_BATTLEAUTOEND'; Category: 'STR_BATTLESCAPE'),
    (Id: 'battleSmoothCamera'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_BATTLESMOOTHCAMERA'; Category: 'STR_BATTLESCAPE'),
    (Id: 'disableAutoEquip'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_DISABLEAUTOEQUIP'; Category: 'STR_BATTLESCAPE'),
    (Id: 'battleConfirmFireMode'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_BATTLECONFIRMFIREMODE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'weaponSelfDestruction'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_WEAPONSELFDESTRUCTION'; Category: 'STR_BATTLESCAPE'),
    (Id: 'allowPsionicCapture'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_ALLOWPSIONICCAPTURE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'allowPsiStrengthImprovement'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_ALLOWPSISTRENGTHIMPROVEMENT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'strafe'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_STRAFE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'forceFire'; Kind: okBool; DefaultValue: 1; DefaultText: ''; Description: 'STR_FORCE_FIRE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'skipNextTurnScreen'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_SKIPNEXTTURNSCREEN'; Category: 'STR_BATTLESCAPE'),
    (Id: 'noAlienPanicMessages'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_NOALIENPANICMESSAGES'; Category: 'STR_BATTLESCAPE'),
    (Id: 'alienBleeding'; Kind: okBool; DefaultValue: 0; DefaultText: ''; Description: 'STR_ALIENBLEEDING'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyOk'; Kind: okKey; DefaultValue: 13; DefaultText: ''; Description: 'STR_OK'; Category: 'STR_GENERAL'),
    (Id: 'keyCancel'; Kind: okKey; DefaultValue: 27; DefaultText: ''; Description: 'STR_CANCEL'; Category: 'STR_GENERAL'),
    (Id: 'keyScreenshot'; Kind: okKey; DefaultValue: 293; DefaultText: ''; Description: 'STR_SCREENSHOT'; Category: 'STR_GENERAL'),
    (Id: 'keyFps'; Kind: okKey; DefaultValue: 288; DefaultText: ''; Description: 'STR_FPS_COUNTER'; Category: 'STR_GENERAL'),
    (Id: 'keyQuickSave'; Kind: okKey; DefaultValue: 286; DefaultText: ''; Description: 'STR_QUICK_SAVE'; Category: 'STR_GENERAL'),
    (Id: 'keyQuickLoad'; Kind: okKey; DefaultValue: 290; DefaultText: ''; Description: 'STR_QUICK_LOAD'; Category: 'STR_GENERAL'),
    (Id: 'keyGeoLeft'; Kind: okKey; DefaultValue: 276; DefaultText: ''; Description: 'STR_ROTATE_LEFT'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoRight'; Kind: okKey; DefaultValue: 275; DefaultText: ''; Description: 'STR_ROTATE_RIGHT'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoUp'; Kind: okKey; DefaultValue: 273; DefaultText: ''; Description: 'STR_ROTATE_UP'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoDown'; Kind: okKey; DefaultValue: 274; DefaultText: ''; Description: 'STR_ROTATE_DOWN'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoZoomIn'; Kind: okKey; DefaultValue: 43; DefaultText: ''; Description: 'STR_ZOOM_IN'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoZoomOut'; Kind: okKey; DefaultValue: 45; DefaultText: ''; Description: 'STR_ZOOM_OUT'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoSpeed1'; Kind: okKey; DefaultValue: 49; DefaultText: ''; Description: 'STR_5_SECONDS'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoSpeed2'; Kind: okKey; DefaultValue: 50; DefaultText: ''; Description: 'STR_1_MINUTE'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoSpeed3'; Kind: okKey; DefaultValue: 51; DefaultText: ''; Description: 'STR_5_MINUTES'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoSpeed4'; Kind: okKey; DefaultValue: 52; DefaultText: ''; Description: 'STR_30_MINUTES'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoSpeed5'; Kind: okKey; DefaultValue: 53; DefaultText: ''; Description: 'STR_1_HOUR'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoSpeed6'; Kind: okKey; DefaultValue: 54; DefaultText: ''; Description: 'STR_1_DAY'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoIntercept'; Kind: okKey; DefaultValue: 105; DefaultText: ''; Description: 'STR_INTERCEPT'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoBases'; Kind: okKey; DefaultValue: 98; DefaultText: ''; Description: 'STR_BASES'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoGraphs'; Kind: okKey; DefaultValue: 103; DefaultText: ''; Description: 'STR_GRAPHS'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoUfopedia'; Kind: okKey; DefaultValue: 117; DefaultText: ''; Description: 'STR_UFOPAEDIA_UC'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoOptions'; Kind: okKey; DefaultValue: 27; DefaultText: ''; Description: 'STR_OPTIONS_UC'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoFunding'; Kind: okKey; DefaultValue: 102; DefaultText: ''; Description: 'STR_FUNDING_UC'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoToggleDetail'; Kind: okKey; DefaultValue: 9; DefaultText: ''; Description: 'STR_TOGGLE_COUNTRY_DETAIL'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyGeoToggleRadar'; Kind: okKey; DefaultValue: 114; DefaultText: ''; Description: 'STR_TOGGLE_RADAR_RANGES'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect1'; Kind: okKey; DefaultValue: 49; DefaultText: ''; Description: 'STR_SELECT_BASE_1'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect2'; Kind: okKey; DefaultValue: 50; DefaultText: ''; Description: 'STR_SELECT_BASE_2'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect3'; Kind: okKey; DefaultValue: 51; DefaultText: ''; Description: 'STR_SELECT_BASE_3'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect4'; Kind: okKey; DefaultValue: 52; DefaultText: ''; Description: 'STR_SELECT_BASE_4'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect5'; Kind: okKey; DefaultValue: 53; DefaultText: ''; Description: 'STR_SELECT_BASE_5'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect6'; Kind: okKey; DefaultValue: 54; DefaultText: ''; Description: 'STR_SELECT_BASE_6'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect7'; Kind: okKey; DefaultValue: 55; DefaultText: ''; Description: 'STR_SELECT_BASE_7'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBaseSelect8'; Kind: okKey; DefaultValue: 56; DefaultText: ''; Description: 'STR_SELECT_BASE_8'; Category: 'STR_GEOSCAPE'),
    (Id: 'keyBattleLeft'; Kind: okKey; DefaultValue: 276; DefaultText: ''; Description: 'STR_SCROLL_LEFT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleRight'; Kind: okKey; DefaultValue: 275; DefaultText: ''; Description: 'STR_SCROLL_RIGHT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleUp'; Kind: okKey; DefaultValue: 273; DefaultText: ''; Description: 'STR_SCROLL_UP'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleDown'; Kind: okKey; DefaultValue: 274; DefaultText: ''; Description: 'STR_SCROLL_DOWN'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleLevelUp'; Kind: okKey; DefaultValue: 280; DefaultText: ''; Description: 'STR_VIEW_LEVEL_ABOVE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleLevelDown'; Kind: okKey; DefaultValue: 281; DefaultText: ''; Description: 'STR_VIEW_LEVEL_BELOW'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterUnit'; Kind: okKey; DefaultValue: 278; DefaultText: ''; Description: 'STR_CENTER_SELECTED_UNIT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattlePrevUnit'; Kind: okKey; DefaultValue: 304; DefaultText: ''; Description: 'STR_PREVIOUS_UNIT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleNextUnit'; Kind: okKey; DefaultValue: 9; DefaultText: ''; Description: 'STR_NEXT_UNIT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleDeselectUnit'; Kind: okKey; DefaultValue: 92; DefaultText: ''; Description: 'STR_DESELECT_UNIT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleUseLeftHand'; Kind: okKey; DefaultValue: 113; DefaultText: ''; Description: 'STR_USE_LEFT_HAND'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleUseRightHand'; Kind: okKey; DefaultValue: 101; DefaultText: ''; Description: 'STR_USE_RIGHT_HAND'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleInventory'; Kind: okKey; DefaultValue: 105; DefaultText: ''; Description: 'STR_INVENTORY'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleMap'; Kind: okKey; DefaultValue: 109; DefaultText: ''; Description: 'STR_MINIMAP'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleOptions'; Kind: okKey; DefaultValue: 27; DefaultText: ''; Description: 'STR_OPTIONS'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleEndTurn'; Kind: okKey; DefaultValue: 8; DefaultText: ''; Description: 'STR_END_TURN'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleAbort'; Kind: okKey; DefaultValue: 97; DefaultText: ''; Description: 'STR_ABORT_MISSION'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleStats'; Kind: okKey; DefaultValue: 115; DefaultText: ''; Description: 'STR_UNIT_STATS'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleKneel'; Kind: okKey; DefaultValue: 107; DefaultText: ''; Description: 'STR_KNEEL'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleReload'; Kind: okKey; DefaultValue: 114; DefaultText: ''; Description: 'STR_RELOAD'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattlePersonalLighting'; Kind: okKey; DefaultValue: 108; DefaultText: ''; Description: 'STR_TOGGLE_PERSONAL_LIGHTING'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleReserveNone'; Kind: okKey; DefaultValue: 282; DefaultText: ''; Description: 'STR_DONT_RESERVE_TIME_UNITS'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleReserveSnap'; Kind: okKey; DefaultValue: 283; DefaultText: ''; Description: 'STR_RESERVE_TIME_UNITS_FOR_SNAP_SHOT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleReserveAimed'; Kind: okKey; DefaultValue: 284; DefaultText: ''; Description: 'STR_RESERVE_TIME_UNITS_FOR_AIMED_SHOT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleReserveAuto'; Kind: okKey; DefaultValue: 285; DefaultText: ''; Description: 'STR_RESERVE_TIME_UNITS_FOR_AUTO_SHOT'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleReserveKneel'; Kind: okKey; DefaultValue: 106; DefaultText: ''; Description: 'STR_RESERVE_TIME_UNITS_FOR_KNEEL'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleZeroTUs'; Kind: okKey; DefaultValue: 127; DefaultText: ''; Description: 'STR_EXPEND_ALL_TIME_UNITS'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy1'; Kind: okKey; DefaultValue: 49; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_1'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy2'; Kind: okKey; DefaultValue: 50; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_2'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy3'; Kind: okKey; DefaultValue: 51; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_3'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy4'; Kind: okKey; DefaultValue: 52; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_4'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy5'; Kind: okKey; DefaultValue: 53; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_5'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy6'; Kind: okKey; DefaultValue: 54; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_6'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy7'; Kind: okKey; DefaultValue: 55; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_7'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy8'; Kind: okKey; DefaultValue: 56; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_8'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy9'; Kind: okKey; DefaultValue: 57; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_9'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleCenterEnemy10'; Kind: okKey; DefaultValue: 48; DefaultText: ''; Description: 'STR_CENTER_ON_ENEMY_10'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyBattleVoxelView'; Kind: okKey; DefaultValue: 291; DefaultText: ''; Description: 'STR_SAVE_VOXEL_VIEW'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyInvCreateTemplate'; Kind: okKey; DefaultValue: 99; DefaultText: ''; Description: 'STR_CREATE_INVENTORY_TEMPLATE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyInvApplyTemplate'; Kind: okKey; DefaultValue: 118; DefaultText: ''; Description: 'STR_APPLY_INVENTORY_TEMPLATE'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyInvClear'; Kind: okKey; DefaultValue: 120; DefaultText: ''; Description: 'STR_CLEAR_INVENTORY'; Category: 'STR_BATTLESCAPE'),
    (Id: 'keyInvAutoEquip'; Kind: okKey; DefaultValue: 122; DefaultText: ''; Description: 'STR_AUTO_EQUIP'; Category: 'STR_BATTLESCAPE'),
    (Id: 'FPS'; Kind: okInt; DefaultValue: 60; DefaultText: ''; Description: 'STR_FPS_LIMIT'; Category: 'STR_GENERAL'),
    (Id: 'FPSInactive'; Kind: okInt; DefaultValue: 30; DefaultText: ''; Description: 'STR_FPS_INACTIVE_LIMIT'; Category: 'STR_GENERAL')
  );

class function TXcomOptionTable.All: TArray<TXcomOptionInfo>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(OPTIONS));
  for LIndex := 0 to High(OPTIONS) do
    Result[LIndex] := OPTIONS[LIndex];
end;

class function TXcomOptionTable.TryFind(const AId: string; out AInfo: TXcomOptionInfo): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(OPTIONS) do
    if OPTIONS[LIndex].Id = AId then
    begin
      AInfo := OPTIONS[LIndex];
      Exit(True);
    end;
  Result := False;
end;

end.