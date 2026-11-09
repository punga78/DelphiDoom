{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the globals of the C++ as one object  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Context;

interface

uses
  DelphiDoom.XcomMod.Random, DelphiDoom.XcomBattle.Intf;

type
  /// <summary>
  ///   IXcomBattleContext with plain values: the generator, the options the battle reads and the ranges of the
  ///   ruleset (the defaults are the ones of OpenXcom unless the mod changes them)
  /// </summary>
  TXcomBattleContext = class(TInterfacedObject, IXcomBattleContext)
  strict private
    FRandom: IXcomRandom;
    FAlienBleeding: Boolean;
    FAllowPsionicCapture: Boolean;
    FFireDamageMin: Integer;
    FFireDamageMax: Integer;
    FDamageRange: Integer;
    FExplosiveDamageRange: Integer;
    FExplosionHeight: Integer;
  public
    constructor Create(const ARandom: IXcomRandom; AAlienBleeding: Boolean = False;
      AAllowPsionicCapture: Boolean = False; AFireDamageMin: Integer = 5; AFireDamageMax: Integer = 10;
      ADamageRange: Integer = 100; AExplosiveDamageRange: Integer = 50; AExplosionHeight: Integer = 0);
    function Random: IXcomRandom;
    function AlienBleeding: Boolean;
    function AllowPsionicCapture: Boolean;
    function FireDamageRange(AIndex: Integer): Integer;
    function DamageRange: Integer;
    function ExplosiveDamageRange: Integer;
    function ExplosionHeight: Integer;
  end;

implementation

constructor TXcomBattleContext.Create(const ARandom: IXcomRandom; AAlienBleeding, AAllowPsionicCapture: Boolean;
  AFireDamageMin, AFireDamageMax, ADamageRange, AExplosiveDamageRange, AExplosionHeight: Integer);
begin
  inherited Create;
  FRandom := ARandom;
  FAlienBleeding := AAlienBleeding;
  FAllowPsionicCapture := AAllowPsionicCapture;
  FFireDamageMin := AFireDamageMin;
  FFireDamageMax := AFireDamageMax;
  FDamageRange := ADamageRange;
  FExplosiveDamageRange := AExplosiveDamageRange;
  FExplosionHeight := AExplosionHeight;
end;

function TXcomBattleContext.Random: IXcomRandom;
begin
  Result := FRandom;
end;

function TXcomBattleContext.AlienBleeding: Boolean;
begin
  Result := FAlienBleeding;
end;

function TXcomBattleContext.AllowPsionicCapture: Boolean;
begin
  Result := FAllowPsionicCapture;
end;

function TXcomBattleContext.FireDamageRange(AIndex: Integer): Integer;
begin
  if AIndex = 0 then
    Result := FFireDamageMin
  else
    Result := FFireDamageMax;
end;

function TXcomBattleContext.DamageRange: Integer;
begin
  Result := FDamageRange;
end;

function TXcomBattleContext.ExplosiveDamageRange: Integer;
begin
  Result := FExplosiveDamageRange;
end;

function TXcomBattleContext.ExplosionHeight: Integer;
begin
  Result := FExplosionHeight;
end;

end.
