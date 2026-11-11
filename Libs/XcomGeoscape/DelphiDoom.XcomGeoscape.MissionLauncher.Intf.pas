{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - the way from the geoscape to the battle  }
{  (what ConfirmLandingState::btnYesClick hands to the BattlescapeGenerator)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.MissionLauncher.Intf;

interface

uses
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo, DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase,
  DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   What a mission is made of. A landing has the craft and exactly one of Ufo, Site and AlienBase; the defense
  ///   of a base has Base and no craft; the last mission has only the craft
  /// </summary>
  TXcomMissionRequest = record
    /// <summary>The craft that lands (not owned); nil for the defense of a base</summary>
    Craft: TXcomCraft;
    /// <summary>SavedBattleGame::setMissionType: STR_UFO_CRASH_RECOVERY, STR_UFO_GROUND_ASSAULT or the deployment type</summary>
    MissionType: string;
    Ufo: TXcomUfo;
    Site: TXcomMissionSite;
    AlienBase: TXcomAlienBase;
    /// <summary>setBase: the X-COM base that is attacked (STR_BASE_DEFENSE); not owned</summary>
    Base: TXcomBase;
    /// <summary>setAlienRace</summary>
    AlienRace: string;
    /// <summary>setWorldTexture: the id of a texture of the globe; -1 none (an alien base has none)</summary>
    WorldTexture: Integer;
    /// <summary>setWorldShade: 0..15</summary>
    WorldShade: Integer;
  end;

  /// <summary>
  ///   Starts the battle of a mission: the Battlescape (another library) creates the battle game, runs its generator
  ///   and pushes the briefing. The geoscape only knows this interface; the tests give a fake
  /// </summary>
  IXcomMissionLauncher = interface
    ['{3C71D9A4-5E20-4B86-9F13-176000000205}']
    /// <summary>
    ///   Called by "Yes" of ConfirmLandingState, after the confirmation was popped. A launcher that cannot start the
    ///   battle (not ported) does nothing
    /// </summary>
    procedure BeginMission(const ARequest: TXcomMissionRequest);
  end;

implementation

end.
