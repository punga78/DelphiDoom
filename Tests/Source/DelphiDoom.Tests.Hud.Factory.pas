{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the heads-up display library - the factory             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Hud.Factory;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('hud')]
  TTestHudFactory = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLoStessoOggettoComeModelloEComeVista;
    [Test]
    procedure DovrebbeRifiutareUnServizioMancante;
    [Test]
    procedure DovrebbeDareUnaListaDiGlifiVuota;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Hud.Types, DelphiDoom.Hud.Intf, DelphiDoom.Hud.View,
  DelphiDoom.Hud.Layout, DelphiDoom.Hud.Factory, DelphiDoom.Tests.Hud.Fakes;

{ TTestHudFactory }

procedure TTestHudFactory.DovrebbeDareLoStessoOggettoComeModelloEComeVista;
var
  LWorld: TFakeHudWorld;
  LWorldRef: IInterface;
  LHeadsUp: IHeadsUp;
  LView: IHudView;
begin
  LWorld := TFakeHudWorld.Create;
  LWorldRef := LWorld;
  THudFactory.CreateHeadsUp(DoomHudRules, LWorld, LWorld, LWorld, LWorld, LWorld, LWorld, LHeadsUp, LView);
  Assert.IsNotNull(LHeadsUp);
  Assert.IsNotNull(LView);
  Assert.AreSame(LHeadsUp as TObject, LView as TObject);
end;

procedure TTestHudFactory.DovrebbeRifiutareUnServizioMancante;
var
  LWorld: TFakeHudWorld;
  LWorldRef: IInterface;
  LHeadsUp: IHeadsUp;
  LView: IHudView;
begin
  LWorld := TFakeHudWorld.Create;
  LWorldRef := LWorld;
  Assert.WillRaise(
    procedure
    begin
      THudFactory.CreateHeadsUp(DoomHudRules, LWorld, LWorld, LWorld, LWorld, LWorld, nil, LHeadsUp, LView);
    end,
    EArgumentNilException);
end;

procedure TTestHudFactory.DovrebbeDareUnaListaDiGlifiVuota;
var
  LLayout: THudLayout;
begin
  LLayout := THudFactory.CreateLayout;
  try
    Assert.AreEqual(0, LLayout.Count);
  finally
    LLayout.Free;
  end;
end;

end.
