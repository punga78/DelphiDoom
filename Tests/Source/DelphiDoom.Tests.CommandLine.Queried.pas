{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command line library - TQueriedCommandLine         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.CommandLine.Queried;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.CommandLine.Intf;

type
  [TestFixture]
  [Category('commandline')]
  TTestCommandLineQueried = class(TObject)
  strict private
    FQueried: IQueriedCommandLine;
    function MakeInner: ICommandLine;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeNonTrovareNullaPrimaDiAttach;
    [Test]
    procedure DovrebbeDareTestoVuotoEValoriNilPrimaDiAttach;
    [Test]
    procedure DovrebbeSollevareEccezionePerUnaPosizionePrimaDiAttach;
    [Test]
    procedure DovrebbeRispondereConLaRigaDiComandoAgganciata;
    [Test]
    procedure DovrebbeInoltrareHasValuesAfterTestoEConteggio;
    [Test]
    procedure DovrebbeRicordareIlNomeCercatoAnchePrimaDiAttach;
    [Test]
    procedure DovrebbeRicordareOgniNomeUnaSolaVoltaSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeTenereLaPrimaScritturaDelNome;
    [Test]
    procedure DovrebbeRicordareINomiNellOrdineInCuiSonoStatiCercati;
    [Test]
    procedure DovrebbeRicordareAncheHasEValuesAfter;
    [Test]
    procedure DovrebbeRicordareUnParametroAssente;
    [Test]
    procedure DovrebbeDareUnElencoVuotoSeNessunoCercaNulla;
    [Test]
    procedure DovrebbeSostituireLaRigaDiComandoAgganciata;
    [Test]
    procedure DovrebbeArrivareDallaFabbrica;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types,
  DelphiDoom.CommandLine.Factory;

{ TTestCommandLineQueried }

function TTestCommandLineQueried.MakeInner: ICommandLine;
begin
  Result := TCommandLineFactory.CreateCommandLine(
    TArray<string>.Create('doom32.exe', '-file', 'a.wad', 'b.wad', '-nomusic'));
end;

procedure TTestCommandLineQueried.Setup;
begin
  FQueried := TCommandLineFactory.CreateQueriedCommandLine;
end;

procedure TTestCommandLineQueried.DovrebbeNonTrovareNullaPrimaDiAttach;
begin
  Assert.AreEqual(0, FQueried.IndexOf('-file'));
  Assert.IsFalse(FQueried.Has('-file'));
  Assert.AreEqual(0, FQueried.Count);
end;

procedure TTestCommandLineQueried.DovrebbeDareTestoVuotoEValoriNilPrimaDiAttach;
begin
  Assert.AreEqual('', FQueried.Text);
  Assert.AreEqual(0, Length(FQueried.ValuesAfter('-file')));
end;

procedure TTestCommandLineQueried.DovrebbeSollevareEccezionePerUnaPosizionePrimaDiAttach;
begin
  Assert.WillRaise(
    procedure
    begin
      FQueried[0];
    end, ECommandLineException);
end;

procedure TTestCommandLineQueried.DovrebbeRispondereConLaRigaDiComandoAgganciata;
begin
  FQueried.Attach(MakeInner);
  Assert.AreEqual(1, FQueried.IndexOf('-file'));
  Assert.AreEqual(4, FQueried.IndexOf('-NOMUSIC'));
  Assert.AreEqual(0, FQueried.IndexOf('-missing'));
  Assert.AreEqual('DOOM32.EXE', FQueried[0]);
end;

procedure TTestCommandLineQueried.DovrebbeInoltrareHasValuesAfterTestoEConteggio;
var
  LValues: TArray<string>;
begin
  FQueried.Attach(MakeInner);
  Assert.IsTrue(FQueried.Has('-nomusic'));
  Assert.IsFalse(FQueried.Has('-warp'));
  LValues := FQueried.ValuesAfter('-file');
  Assert.AreEqual(2, Length(LValues));
  Assert.AreEqual('A.WAD', LValues[0]);
  Assert.AreEqual('B.WAD', LValues[1]);
  Assert.AreEqual('-FILE A.WAD B.WAD -NOMUSIC', FQueried.Text);
  Assert.AreEqual(5, FQueried.Count);
end;

procedure TTestCommandLineQueried.DovrebbeRicordareIlNomeCercatoAnchePrimaDiAttach;
var
  LNames: TArray<string>;
begin
  FQueried.IndexOf('-nomusic');
  FQueried.Attach(MakeInner);
  LNames := FQueried.QueriedNames;
  Assert.AreEqual(1, Length(LNames));
  Assert.AreEqual('-nomusic', LNames[0]);
end;

procedure TTestCommandLineQueried.DovrebbeRicordareOgniNomeUnaSolaVoltaSenzaDistinguereLeMaiuscole;
begin
  FQueried.IndexOf('-nomusic');
  FQueried.IndexOf('-NOMUSIC');
  FQueried.IndexOf('-NoMusic');
  Assert.AreEqual(1, Length(FQueried.QueriedNames));
end;

procedure TTestCommandLineQueried.DovrebbeTenereLaPrimaScritturaDelNome;
begin
  FQueried.IndexOf('-NoMusic');
  FQueried.IndexOf('-nomusic');
  Assert.AreEqual('-NoMusic', FQueried.QueriedNames[0]);
end;

procedure TTestCommandLineQueried.DovrebbeRicordareINomiNellOrdineInCuiSonoStatiCercati;
var
  LNames: TArray<string>;
begin
  FQueried.IndexOf('-warp');
  FQueried.IndexOf('-skill');
  FQueried.IndexOf('-warp');
  FQueried.IndexOf('-file');
  LNames := FQueried.QueriedNames;
  Assert.AreEqual(3, Length(LNames));
  Assert.AreEqual('-warp', LNames[0]);
  Assert.AreEqual('-skill', LNames[1]);
  Assert.AreEqual('-file', LNames[2]);
end;

procedure TTestCommandLineQueried.DovrebbeRicordareAncheHasEValuesAfter;
begin
  FQueried.Has('-a');
  FQueried.ValuesAfter('-b');
  FQueried.ValuesAfter('-a');
  Assert.AreEqual(2, Length(FQueried.QueriedNames));
end;

procedure TTestCommandLineQueried.DovrebbeRicordareUnParametroAssente;
begin
  FQueried.Attach(MakeInner);
  Assert.AreEqual(0, FQueried.IndexOf('-assente'));
  Assert.AreEqual('-assente', FQueried.QueriedNames[0]);
end;

procedure TTestCommandLineQueried.DovrebbeDareUnElencoVuotoSeNessunoCercaNulla;
begin
  Assert.AreEqual(0, Length(FQueried.QueriedNames));
end;

procedure TTestCommandLineQueried.DovrebbeSostituireLaRigaDiComandoAgganciata;
begin
  FQueried.Attach(MakeInner);
  FQueried.Attach(TCommandLineFactory.CreateCommandLine(TArray<string>.Create('x.exe', '-warp')));
  Assert.AreEqual(0, FQueried.IndexOf('-file'));
  Assert.AreEqual(1, FQueried.IndexOf('-warp'));
end;

procedure TTestCommandLineQueried.DovrebbeArrivareDallaFabbrica;
var
  LOther: IQueriedCommandLine;
begin
  LOther := TCommandLineFactory.CreateQueriedCommandLine;
  Assert.IsTrue(Assigned(FQueried));
  Assert.IsTrue(Assigned(LOther));
end;

end.
