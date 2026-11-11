{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom basescape library - the text of the       }
{  stores of the lists of quantities                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBasescape.SpaceText;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomBasescape.SpaceText;

type
  [TestFixture]
  [Category('xcom-basescape')]
  TTestXcomSpaceText = class(TObject)
  public
    [Test]
    procedure DovrebbeScrivereUsatoEDisponibileSenzaOffset;
    [Test]
    procedure DovrebbeScrivereUnOffsetPositivoConIlPiu;
    [Test]
    procedure DovrebbeScrivereUnOffsetNegativoSenzaPiu;
    [Test]
    procedure DovrebbeIgnorareUnOffsetFinoACinqueCentesimi;
    [Test]
    procedure DovrebbeUsareSeiCifreSignificativeComeUnOstream;
  end;

implementation

{ TTestXcomSpaceText }

procedure TTestXcomSpaceText.DovrebbeScrivereUsatoEDisponibileSenzaOffset;
begin
  Assert.AreEqual('12.5:100', TXcomSpaceText.Format(12.5, 0, 100));
end;

procedure TTestXcomSpaceText.DovrebbeScrivereUnOffsetPositivoConIlPiu;
begin
  Assert.AreEqual('10(+2.5):50', TXcomSpaceText.Format(10, 2.5, 50));
end;

procedure TTestXcomSpaceText.DovrebbeScrivereUnOffsetNegativoSenzaPiu;
begin
  Assert.AreEqual('10(-3.0):50', TXcomSpaceText.Format(10, -3, 50));
end;

procedure TTestXcomSpaceText.DovrebbeIgnorareUnOffsetFinoACinqueCentesimi;
begin
  Assert.AreEqual('10:50', TXcomSpaceText.Format(10, 0.05, 50));
  Assert.AreEqual('10:50', TXcomSpaceText.Format(10, -0.05, 50));
end;

procedure TTestXcomSpaceText.DovrebbeUsareSeiCifreSignificativeComeUnOstream;
begin
  Assert.AreEqual('123.457:9', TXcomSpaceText.Format(123.4567891, 0, 9));
end;

end.
