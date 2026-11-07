{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the IWAD library - the lists of folders                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Iwad.PathList;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Iwad.PathList;

type
  [TestFixture]
  [Category('iwad')]
  TTestIwadPathList = class(TObject)
  public
    [Test]
    procedure DovrebbeDareUnaListaVuotaPerUnTestoVuoto;
    [Test]
    procedure DovrebbeDareUnaSolaCartellaSenzaSeparatore;
    [Test]
    procedure DovrebbeSeparareLeCartelleConIlPuntoEVirgola;
    [Test]
    procedure DovrebbeSaltareLePartiVuote;
    [Test]
    procedure DovrebbeConservareGliSpaziEIlTestoCosiComeE;
    [Test]
    procedure DovrebbeDareUnaListaVuotaPerSoliSeparatori;
  end;

implementation

{ TTestIwadPathList }

procedure TTestIwadPathList.DovrebbeDareUnaListaVuotaPerUnTestoVuoto;
begin
  Assert.AreEqual(0, Integer(Length(TIwadPathList.Split(''))));
end;

procedure TTestIwadPathList.DovrebbeDareUnaSolaCartellaSenzaSeparatore;
var
  LFolders: TArray<string>;
begin
  LFolders := TIwadPathList.Split('C:\Giochi');
  Assert.AreEqual(1, Integer(Length(LFolders)));
  Assert.AreEqual('C:\Giochi', LFolders[0]);
end;

procedure TTestIwadPathList.DovrebbeSeparareLeCartelleConIlPuntoEVirgola;
var
  LFolders: TArray<string>;
begin
  LFolders := TIwadPathList.Split('C:\A;D:\B;E:\C');
  Assert.AreEqual(3, Integer(Length(LFolders)));
  Assert.AreEqual('C:\A', LFolders[0]);
  Assert.AreEqual('D:\B', LFolders[1]);
  Assert.AreEqual('E:\C', LFolders[2]);
end;

procedure TTestIwadPathList.DovrebbeSaltareLePartiVuote;
var
  LFolders: TArray<string>;
begin
  LFolders := TIwadPathList.Split(';C:\A;;D:\B;');
  Assert.AreEqual(2, Integer(Length(LFolders)));
  Assert.AreEqual('C:\A', LFolders[0]);
  Assert.AreEqual('D:\B', LFolders[1]);
end;

procedure TTestIwadPathList.DovrebbeConservareGliSpaziEIlTestoCosiComeE;
var
  LFolders: TArray<string>;
begin
  LFolders := TIwadPathList.Split(' C:\A b ;D:/B');
  Assert.AreEqual(2, Integer(Length(LFolders)));
  Assert.AreEqual(' C:\A b ', LFolders[0]);
  Assert.AreEqual('D:/B', LFolders[1]);
end;

procedure TTestIwadPathList.DovrebbeDareUnaListaVuotaPerSoliSeparatori;
begin
  Assert.AreEqual(0, Integer(Length(TIwadPathList.Split(';;;'))));
end;

end.
