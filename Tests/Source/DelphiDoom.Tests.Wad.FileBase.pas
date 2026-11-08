{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TWadFileBase                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.FileBase;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types;

type
  [TestFixture]
  [Category('wad')]
  TTestWadFileBase = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlNomeSenzaEstensioneInMaiuscolo;
    [Test]
    procedure DovrebbeTogliereLaCartellaConLaBarraNormale;
    [Test]
    procedure DovrebbeTogliereLaCartellaConLaBarraInversa;
    [Test]
    procedure DovrebbeFermarsiAlPrimoPunto;
    [Test]
    procedure DovrebbeDareUnaStringaVuotaSeIlPercorsoFinisceConUnaBarra;
    [Test]
    procedure DovrebbeAccettareUnNomeDiOttoCaratteri;
    [Test]
    procedure DovrebbeSollevareEWadExceptionSeIlNomeHaPiuDiOttoCaratteri;
    [Test]
    procedure DovrebbeMaiuscolareSoloLeLettereAscii;
  end;

implementation

uses
  DelphiDoom.Wad.FileBase;

{ TTestWadFileBase }

procedure TTestWadFileBase.DovrebbeDareIlNomeSenzaEstensioneInMaiuscolo;
begin
  Assert.AreEqual('DEMO1', TWadFileBase.Extract('demo1.lmp'));
  Assert.AreEqual('DEMO1', TWadFileBase.Extract('demo1'));
end;

procedure TTestWadFileBase.DovrebbeTogliereLaCartellaConLaBarraNormale;
begin
  Assert.AreEqual('MYDEMO', TWadFileBase.Extract('c:/games/doom/mydemo.lmp'));
end;

procedure TTestWadFileBase.DovrebbeTogliereLaCartellaConLaBarraInversa;
begin
  Assert.AreEqual('MYDEMO', TWadFileBase.Extract('C:\games\doom\mydemo.lmp'));
end;

procedure TTestWadFileBase.DovrebbeFermarsiAlPrimoPunto;
begin
  Assert.AreEqual('A', TWadFileBase.Extract('a.b.c'));
end;

procedure TTestWadFileBase.DovrebbeDareUnaStringaVuotaSeIlPercorsoFinisceConUnaBarra;
begin
  Assert.AreEqual('', TWadFileBase.Extract('c:\games\'));
  Assert.AreEqual('', TWadFileBase.Extract(''));
end;

procedure TTestWadFileBase.DovrebbeAccettareUnNomeDiOttoCaratteri;
begin
  Assert.AreEqual('ABCDEFGH', TWadFileBase.Extract('abcdefgh.wad'));
end;

procedure TTestWadFileBase.DovrebbeSollevareEWadExceptionSeIlNomeHaPiuDiOttoCaratteri;
begin
  Assert.WillRaise(
    procedure
    begin
      TWadFileBase.Extract('abcdefghi.wad');
    end,
    EWadException);
end;

procedure TTestWadFileBase.DovrebbeMaiuscolareSoloLeLettereAscii;
begin
  Assert.AreEqual('A_1' + Char($E9), TWadFileBase.Extract('a_1' + Char($E9) + '.x'));
end;

end.
