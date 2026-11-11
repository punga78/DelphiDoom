{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the options the battle reads          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Options;

interface

type
  /// <summary>The Options:: values that BattlescapeGame and its steps read (the defaults are those of OpenXcom)</summary>
  TXcomBattleOptions = record
    /// <summary>Options::weaponSelfDestruction: the weapons of dead aliens are not dropped</summary>
    WeaponSelfDestruction: Boolean;
    /// <summary>Options::battleNotifyDeath</summary>
    BattleNotifyDeath: Boolean;
    /// <summary>Options::battleAutoEnd</summary>
    BattleAutoEnd: Boolean;
    /// <summary>Options::allowPsionicCapture</summary>
    AllowPsionicCapture: Boolean;
    /// <summary>Options::allowPsiStrengthImprovement</summary>
    AllowPsiStrengthImprovement: Boolean;
    /// <summary>Options::noAlienPanicMessages</summary>
    NoAlienPanicMessages: Boolean;
    /// <summary>Options::battleXcomSpeed and battleAlienSpeed (the interval of the steps)</summary>
    BattleXcomSpeed: Integer;
    BattleAlienSpeed: Integer;
    /// <summary>Options::battleInstantGrenade: a hot grenade explodes where it lands</summary>
    BattleInstantGrenade: Boolean;
    /// <summary>Options::battleFireSpeed, battleUFOExtenderAccuracy, forceFire and the control key</summary>
    FireSpeed: Integer;
    UfoExtenderAccuracy: Boolean;
    ForceFire: Boolean;
    ControlHeld: Boolean;
    class function Default: TXcomBattleOptions; static;
  end;

implementation

class function TXcomBattleOptions.Default: TXcomBattleOptions;
begin
  Result.WeaponSelfDestruction := False;
  Result.BattleNotifyDeath := False;
  Result.BattleAutoEnd := False;
  Result.AllowPsionicCapture := False;
  Result.AllowPsiStrengthImprovement := False;
  Result.NoAlienPanicMessages := False;
  Result.BattleXcomSpeed := 30;
  Result.BattleAlienSpeed := 30;
  Result.BattleInstantGrenade := False;
  Result.FireSpeed := 6;
  Result.UfoExtenderAccuracy := False;
  Result.ForceFire := True;
  Result.ControlHeld := False;
end;

end.
