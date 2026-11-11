{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - what the New Battle screen asks of the       }
{  program: the battle it has set up, the equipment of the craft and where its  }
{  choices are kept                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.NewBattle.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo,
  DelphiDoom.XcomSave.MissionSite, DelphiDoom.XcomSave.AlienBase;

type
  /// <summary>
  ///   The battle that NewBattleState::btnOkClick gives to the BattlescapeGenerator. The objects belong to the
  ///   saved game of the session; only one of Base (a base defense, without craft), AlienBase, Ufo and Site is set
  /// </summary>
  TXcomNewBattleChoice = record
    /// <summary>The type of the deployment (for a UFO: STR_UFO_GROUND_ASSAULT or STR_UFO_CRASH_RECOVERY)</summary>
    MissionType: string;
    Craft: TXcomCraft;
    Base: TXcomBase;
    AlienBase: TXcomAlienBase;
    Ufo: TXcomUfo;
    Site: TXcomMissionSite;
    AlienRace: string;
    /// <summary>The terrain chosen in the list (BattlescapeGenerator::setTerrain)</summary>
    Terrain: string;
    /// <summary>0 (day) to 15 (night): setWorldShade</summary>
    Darkness: Integer;
    /// <summary>SavedBattleGame::setDepth: 0, or 1 to 3 under water</summary>
    Depth: Integer;
    /// <summary>setAlienItemlevel: the row of alienItemLevels</summary>
    AlienItemLevel: Integer;
  end;

  /// <summary>The screens and the battle that the New Battle screen opens: the menu library does not know them</summary>
  IXcomNewBattleNavigator = interface
    ['{B2A74E19-6C05-4D83-9E1F-176000000301}']
    /// <summary>CraftInfoState of the first craft of the base (the Equip Craft button)</summary>
    procedure EquipCraft(ABase: TXcomBase);
    /// <summary>BattlescapeGenerator::run and the BriefingState, over the states that are there</summary>
    procedure Launch(const AChoice: TXcomNewBattleChoice);
  end;

  /// <summary>battle.cfg of the user folder of the master mod: the choices of the last New Battle and its base</summary>
  IXcomNewBattleStore = interface
    ['{B2A74E19-6C05-4D83-9E1F-176000000302}']
    /// <summary>The document of the file; nil when there is none or it cannot be read</summary>
    function Load: IYamlNode;
    procedure Save(const ADocument: IYamlNode);
  end;

implementation

end.
