{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - an explosion or a hit in the list of  }
{  steps (ExplosionBState)                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ExplosionState;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.State.Intf, DelphiDoom.XcomBattle.Host.Intf;

type
  /// <summary>
  ///   The step that carries an explosion (a grenade, a blast, a unit that explodes when it dies) or the hit of a
  ///   bullet: the animation starts in Init and when it is over Think applies the effects with the tile engine
  /// </summary>
  TXcomExplosionState = class(TInterfacedObject, IXcomBattleState)
  strict private
    FHost: IXcomBattleHost;
    FUnit: TXcomBattleUnit;
    FCenter: TXcomPosition;
    FItem: TXcomBattleItem;
    FTile: TXcomTile;
    FLowerWeapon: Boolean;
    FCosmetic: Boolean;
  public
    /// <param name="ACenter">Center in voxels</param>
    /// <param name="AItem">Item involved (a grenade), or nil</param>
    /// <param name="AUnit">Unit that causes it, or nil</param>
    /// <param name="ATile">Tile that explodes (a chained explosion), or nil</param>
    /// <param name="ALowerWeapon">Whether the unit puts the weapon down at the end</param>
    /// <param name="ACosmetic">Only the animation, without effects</param>
    constructor Create(const AHost: IXcomBattleHost; const ACenter: TXcomPosition; const AItem: TXcomBattleItem;
      const AUnit: TXcomBattleUnit; const ATile: TXcomTile; ALowerWeapon: Boolean = True; ACosmetic: Boolean = False);
    procedure Init;
    procedure Think;
    procedure Cancel;
    procedure Deinit;
    function StateName: string;
    property Center: TXcomPosition read FCenter;
    property Item: TXcomBattleItem read FItem;
    property CausingUnit: TXcomBattleUnit read FUnit;
    property Tile: TXcomTile read FTile;
    property LowerWeapon: Boolean read FLowerWeapon;
    property Cosmetic: Boolean read FCosmetic;
  end;

implementation

const
  SNotYetPorted = 'The animation and the effects of the explosion step are ported with BattlescapeGame';

constructor TXcomExplosionState.Create(const AHost: IXcomBattleHost; const ACenter: TXcomPosition;
  const AItem: TXcomBattleItem; const AUnit: TXcomBattleUnit; const ATile: TXcomTile; ALowerWeapon, ACosmetic: Boolean);
begin
  inherited Create;
  FHost := AHost;
  FCenter := ACenter;
  FItem := AItem;
  FUnit := AUnit;
  FTile := ATile;
  FLowerWeapon := ALowerWeapon;
  FCosmetic := ACosmetic;
end;

procedure TXcomExplosionState.Init;
begin
  raise EXcomBattleException.Create(SNotYetPorted);
end;

procedure TXcomExplosionState.Think;
begin
  raise EXcomBattleException.Create(SNotYetPorted);
end;

procedure TXcomExplosionState.Cancel;
begin
  // explosions cannot be cancelled
end;

procedure TXcomExplosionState.Deinit;
begin
end;

function TXcomExplosionState.StateName: string;
begin
  Result := 'ExplosionBState';
end;

end.
