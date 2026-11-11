{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battle library - the vapor trail of a shot, sent to the     }
{  view (the part of Projectile::addVaporCloud that touches the map)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomBattle\CLAUDE.md for the license of this unit                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ViewVapor;

interface

uses
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomBattle.View.Intf, DelphiDoom.XcomBattle.Projectile;

type
  /// <summary>Gives the vapor of a projectile to the view (the map that keeps the particles)</summary>
  TXcomViewVapor = class(TInterfacedObject, IXcomProjectileVapor)
  strict private
    FView: IXcomBattleView;
  public
    constructor Create(const AView: IXcomBattleView);
    procedure AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
  end;

implementation

{ TXcomViewVapor }

constructor TXcomViewVapor.Create(const AView: IXcomBattleView);
begin
  inherited Create;
  FView := AView;
end;

procedure TXcomViewVapor.AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
begin
  FView.AddVaporCloud(AVoxel, ADensity, AColor);
end;

end.
