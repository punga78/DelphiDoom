{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - IBotWeaponSystem, the weapon AI of the bots            }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the interface of    }
{  code\game\be_ai_weap.h. Based on the Quake III Arena GPL Source Code        }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Weapon.Intf;

interface

uses
  DelphiDoom.BotAi.Weapon.Types, DelphiDoom.BotAi.Weapon.Config;

type
  /// <summary>be_ai_weap.h with the handles of the original: weapon states 1..64</summary>
  IBotWeaponSystem = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F78}']
    /// <summary>BotSetupWeaponAI: loads the file of the variable <c>weaponconfig</c> (weapons.c); BLERR_NOERROR or BLERR_CANNOTLOADWEAPONCONFIG</summary>
    function Setup: Integer;
    /// <summary>BotShutdownWeaponAI</summary>
    procedure Shutdown;
    /// <summary>BotAllocWeaponState: 0 if all 64 are in use</summary>
    function AllocWeaponState: Integer;
    /// <summary>BotFreeWeaponState</summary>
    procedure FreeWeaponState(const AHandle: Integer);
    /// <summary>BotResetWeaponState (it does not change anything: the original keeps the weights)</summary>
    procedure ResetWeaponState(const AHandle: Integer);
    /// <summary>BotLoadWeaponWeights: BLERR_NOERROR, BLERR_CANNOTLOADWEAPONWEIGHTS or BLERR_CANNOTLOADWEAPONCONFIG</summary>
    function LoadWeaponWeights(const AHandle: Integer; const AFileName: AnsiString): Integer;
    /// <summary>BotGetWeaponInfo: false (and an error printed) if the weapon number or the state is wrong</summary>
    function GetWeaponInfo(const AHandle, AWeapon: Integer; out AInfo: TBotWeaponInfo): Boolean;
    /// <summary>BotChooseBestFightWeapon: the number of the weapon with the best weight (above 0), 0 if none</summary>
    function ChooseBestFightWeapon(const AHandle: Integer; const AInventory: TArray<Integer>): Integer;
    /// <summary>weaponconfig: nil until Setup succeeds</summary>
    function Config: TBotWeaponConfig;
  end;

implementation

end.
