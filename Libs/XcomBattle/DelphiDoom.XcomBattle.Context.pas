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
  ///   IXcomBattleContext with plain values: the generator, the two options the battle reads and the fire damage
  ///   range of the ruleset (5 and 10 unless the mod changes them)
  /// </summary>
  TXcomBattleContext = class(TInterfacedObject, IXcomBattleContext)
  strict private
    FRandom: IXcomRandom;
    FAlienBleeding: Boolean;
    FAllowPsionicCapture: Boolean;
    FFireDamageMin: Integer;
    FFireDamageMax: Integer;
  public
    constructor Create(const ARandom: IXcomRandom; AAlienBleeding: Boolean = False;
      AAllowPsionicCapture: Boolean = False; AFireDamageMin: Integer = 5; AFireDamageMax: Integer = 10);
    function Random: IXcomRandom;
    function AlienBleeding: Boolean;
    function AllowPsionicCapture: Boolean;
    function FireDamageRange(AIndex: Integer): Integer;
  end;

implementation

constructor TXcomBattleContext.Create(const ARandom: IXcomRandom; AAlienBleeding, AAllowPsionicCapture: Boolean;
  AFireDamageMin, AFireDamageMax: Integer);
begin
  inherited Create;
  FRandom := ARandom;
  FAlienBleeding := AAlienBleeding;
  FAllowPsionicCapture := AAllowPsionicCapture;
  FFireDamageMin := AFireDamageMin;
  FFireDamageMax := AFireDamageMax;
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

end.
