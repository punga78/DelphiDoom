{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the finder of the vertexes of a triangular sector      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Udmf.TriangleFinder;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('udmf')]
  TTestUdmfTriangleFinder = class(TObject)
  public
    [Test]
    procedure DovrebbeTrovareITreVertexiDiUnTriangoloChiuso;
    [Test]
    procedure DovrebbeDareIVertexiNellOrdineDiComparsa;
    [Test]
    procedure DovrebbeDareFalsoSeIVertexiSonoMenoDiTre;
    [Test]
    procedure DovrebbeDareFalsoSeIVertexiSonoPiuDiTre;
    [Test]
    procedure DovrebbeDareFalsoSeUnVertexNonHaValoriExtra;
    [Test]
    procedure DovrebbeAccettareUnVertexUltimoPrimaDelLimite;
    [Test]
    procedure DovrebbeDareFalsoSenzaPunti;
  end;

implementation

uses
  DelphiDoom.Udmf.Apply.TriangleFinder;

{ TTestUdmfTriangleFinder }

procedure TTestUdmfTriangleFinder.DovrebbeTrovareITreVertexiDiUnTriangoloChiuso;
var
  LVertexes: TArray<Integer>;
begin
  Assert.IsTrue(TUdmfTriangleFinder.TryFind([4, 6, 6, 5, 5, 4], 100, LVertexes));
  Assert.AreEqual(3, Integer(Length(LVertexes)));
end;

procedure TTestUdmfTriangleFinder.DovrebbeDareIVertexiNellOrdineDiComparsa;
var
  LVertexes: TArray<Integer>;
begin
  Assert.IsTrue(TUdmfTriangleFinder.TryFind([9, 2, 2, 7, 7, 9], 100, LVertexes));
  Assert.AreEqual(9, LVertexes[0]);
  Assert.AreEqual(2, LVertexes[1]);
  Assert.AreEqual(7, LVertexes[2]);
end;

procedure TTestUdmfTriangleFinder.DovrebbeDareFalsoSeIVertexiSonoMenoDiTre;
var
  LVertexes: TArray<Integer>;
begin
  Assert.IsFalse(TUdmfTriangleFinder.TryFind([1, 2, 2, 1, 1, 2], 100, LVertexes));
  Assert.IsTrue(LVertexes = nil);
end;

procedure TTestUdmfTriangleFinder.DovrebbeDareFalsoSeIVertexiSonoPiuDiTre;
var
  LVertexes: TArray<Integer>;
begin
  Assert.IsFalse(TUdmfTriangleFinder.TryFind([1, 2, 2, 3, 3, 4], 100, LVertexes));
end;

procedure TTestUdmfTriangleFinder.DovrebbeDareFalsoSeUnVertexNonHaValoriExtra;
var
  LVertexes: TArray<Integer>;
begin
  // added by the node builder: its number is not under the count of the text map
  Assert.IsFalse(TUdmfTriangleFinder.TryFind([1, 2, 2, 50, 50, 1], 50, LVertexes));
end;

procedure TTestUdmfTriangleFinder.DovrebbeAccettareUnVertexUltimoPrimaDelLimite;
var
  LVertexes: TArray<Integer>;
begin
  Assert.IsTrue(TUdmfTriangleFinder.TryFind([1, 2, 2, 49, 49, 1], 50, LVertexes));
end;

procedure TTestUdmfTriangleFinder.DovrebbeDareFalsoSenzaPunti;
var
  LVertexes: TArray<Integer>;
begin
  Assert.IsFalse(TUdmfTriangleFinder.TryFind([], 50, LVertexes));
end;

end.
