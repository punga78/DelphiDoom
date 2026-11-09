{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - the lists of files          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.FileList;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.CommandLine.FileList;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineFileList = class(TObject)
  strict private
    function Join(const AList: string): string;
  public
    [Test]
    procedure DovrebbeDareUnaListaVuotaSeIlTestoEVuoto;
    [Test]
    procedure DovrebbeDareUnaListaVuotaSeIlTestoHaSoloSpazi;
    [Test]
    procedure DovrebbeDareUnSoloNome;
    [Test]
    procedure DovrebbeSeparareConLeVirgole;
    [Test]
    procedure DovrebbeSeparareConIPuntoEVirgola;
    [Test]
    procedure DovrebbePreferireIPuntoEVirgolaSeCeNeSono;
    [Test]
    procedure DovrebbeTogliereGliSpaziAgliEstremiDiOgniNome;
    [Test]
    procedure DovrebbeTenereUnNomeVuotoInMezzo;
    [Test]
    procedure DovrebbeTenereUnNomeVuotoAllInizio;
    [Test]
    procedure DovrebbeIgnorareUnSeparatoreFinale;
    [Test]
    procedure DovrebbeScegliereIlSeparatoreDiOgniPassoSulResto;
  end;

implementation

{ TTestCommandLineFileList }

function TTestCommandLineFileList.Join(const AList: string): string;
begin
  Result := string.Join('|', TCommandLineFileList.Split(AList));
end;

procedure TTestCommandLineFileList.DovrebbeDareUnaListaVuotaSeIlTestoEVuoto;
begin
  Assert.AreEqual(0, Integer(Length(TCommandLineFileList.Split(''))));
end;

procedure TTestCommandLineFileList.DovrebbeDareUnaListaVuotaSeIlTestoHaSoloSpazi;
begin
  Assert.AreEqual(0, Integer(Length(TCommandLineFileList.Split('  '#9' '))));
end;

procedure TTestCommandLineFileList.DovrebbeDareUnSoloNome;
begin
  Assert.AreEqual('A.WAD', Join('A.WAD'));
end;

procedure TTestCommandLineFileList.DovrebbeSeparareConLeVirgole;
begin
  Assert.AreEqual('A.WAD|B.WAD|C.WAD', Join('A.WAD,B.WAD,C.WAD'));
end;

procedure TTestCommandLineFileList.DovrebbeSeparareConIPuntoEVirgola;
begin
  Assert.AreEqual('A.WAD|B.WAD', Join('A.WAD;B.WAD'));
end;

procedure TTestCommandLineFileList.DovrebbePreferireIPuntoEVirgolaSeCeNeSono;
begin
  // as the old recursion: the first name is cut at ';' and keeps its commas
  Assert.AreEqual('A.WAD,B.WAD|C.WAD', Join('A.WAD,B.WAD;C.WAD'));
end;

procedure TTestCommandLineFileList.DovrebbeTogliereGliSpaziAgliEstremiDiOgniNome;
begin
  Assert.AreEqual('A.WAD|B C.WAD|D.WAD', Join('  A.WAD ,B C.WAD,  D.WAD  '));
end;

procedure TTestCommandLineFileList.DovrebbeTenereUnNomeVuotoInMezzo;
begin
  Assert.AreEqual('A||B', Join('A,,B'));
end;

procedure TTestCommandLineFileList.DovrebbeTenereUnNomeVuotoAllInizio;
begin
  Assert.AreEqual('|A', Join(',A'));
end;

procedure TTestCommandLineFileList.DovrebbeIgnorareUnSeparatoreFinale;
begin
  Assert.AreEqual('A', Join('A,'));
  Assert.AreEqual('A', Join('A;'));
end;

procedure TTestCommandLineFileList.DovrebbeScegliereIlSeparatoreDiOgniPassoSulResto;
begin
  // after the cut at ';' the rest has no ';': it is cut at ','
  Assert.AreEqual('A|B|C', Join('A;B,C'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCommandLineFileList);

end.
