{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - the shared types                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Types;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('automap')]
  TTestAutomapTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereLeStesseDimensioniDeiVecchiRecord;
    [Test]
    procedure DovrebbeAvereLeCostantiDelVecchioCodice;
    [Test]
    procedure DovrebbeConservareIlPiGrecoDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Automap.Types, DelphiDoom.MathCore.Types;

{ TTestAutomapTypes }

procedure TTestAutomapTypes.DovrebbeAvereLeStesseDimensioniDeiVecchiRecord;
begin
  // mpoint_t, mline_t, fpoint_t and fline_t were records of integers without padding
  Assert.AreEqual(8, SizeOf(TAutomapPoint));
  Assert.AreEqual(16, SizeOf(TAutomapLine));
  Assert.AreEqual(8, SizeOf(TAutomapFramePoint));
  Assert.AreEqual(16, SizeOf(TAutomapFrameLine));
end;

procedure TTestAutomapTypes.DovrebbeAvereLeCostantiDelVecchioCodice;
begin
  Assert.AreEqual(4096, AUTOMAP_MAPUNIT);
  Assert.AreEqual(16, AUTOMAP_FRACTOMAPUNIT);
  Assert.AreEqual(4, AUTOMAP_FRACTOMAPBITS);
  Assert.AreEqual(16 * 4096, AUTOMAP_PLAYERRADIUS);
  Assert.AreEqual(10, AUTOMAP_MAX_MARKS);
  Assert.AreEqual(FIXED_ONE div 5, AUTOMAP_INITIAL_SCALE);
  Assert.AreEqual(66846, AUTOMAP_ZOOM_IN);
  Assert.AreEqual(64250, AUTOMAP_ZOOM_OUT);
end;

procedure TTestAutomapTypes.DovrebbeConservareIlPiGrecoDelVecchioCodice;
begin
  // difetto conservato: D_PI era 3.141592657, non il pi greco; i personaggi ruotano con quello
  Assert.IsTrue(AUTOMAP_PI <> Pi);
  Assert.IsTrue(Abs(AUTOMAP_PI - Pi) < 1e-8);
end;

end.
