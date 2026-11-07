{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - the search of the script editor      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.Search;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.SearchHistory,
  DelphiDoom.Ide.SearchSettings;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeSearch = class(TObject)
  strict private
    FHistory: TIdeSearchHistory;
    FSettings: TIdeSearchSettings;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMettereIlTestoNuovoInCima;
    [Test]
    procedure DovrebbeSpostareInCimaUnTestoGiaPresente;
    [Test]
    procedure DovrebbeConsiderareUguali2TestiCheDifferisconoPerMaiuscole;
    [Test]
    procedure DovrebbeIgnorareIlTestoVuoto;
    [Test]
    procedure DovrebbeDareSoloIPrimiDieciTesti;
    [Test]
    procedure DovrebbeRileggereIlTestoDato;
    [Test]
    procedure DovrebbeDareTestoVuotoSeNonCeNulla;
    [Test]
    procedure DovrebbePartireSenzaOpzioniEConCronologieVuote;
    [Test]
    procedure DovrebbeFareLaRicercaDaCima;
    [Test]
    procedure DovrebbeFareLaRicercaDalCursore;
    [Test]
    procedure DovrebbeUnireLeOpzioniDellaRicerca;
    [Test]
    procedure DovrebbeChiedereConfermaESostituireTuttoNelleSostituzioni;
    [Test]
    procedure DovrebbeUsareIlMotoreDelleEspressioniSeRichiesto;
    [Test]
    procedure DovrebbeFareLaRicercaSuccessivaSenzaDaCimaESenzaSostituire;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.SearchPlan;

{ TTestIdeSearch }

procedure TTestIdeSearch.Setup;
begin
  FHistory := TIdeSearchHistory.Create;
  FSettings := TIdeSearchSettings.Create;
end;

procedure TTestIdeSearch.TearDown;
begin
  FSettings.Free;
  FHistory.Free;
end;

procedure TTestIdeSearch.DovrebbeMettereIlTestoNuovoInCima;
begin
  FHistory.Remember('one');
  FHistory.Remember('two');
  Assert.AreEqual(2, FHistory.Count);
  Assert.AreEqual('two', FHistory[0]);
  Assert.AreEqual('one', FHistory[1]);
end;

procedure TTestIdeSearch.DovrebbeSpostareInCimaUnTestoGiaPresente;
begin
  FHistory.Remember('one');
  FHistory.Remember('two');
  FHistory.Remember('three');
  FHistory.Remember('one');
  Assert.AreEqual(3, FHistory.Count);
  Assert.AreEqual('one', FHistory[0]);
  Assert.AreEqual('three', FHistory[1]);
  Assert.AreEqual('two', FHistory[2]);
end;

procedure TTestIdeSearch.DovrebbeConsiderareUguali2TestiCheDifferisconoPerMaiuscole;
begin
  FHistory.Remember('Foo');
  FHistory.Remember('bar');
  FHistory.Remember('FOO');
  Assert.AreEqual(2, FHistory.Count);
  Assert.AreEqual('FOO', FHistory[0]);
end;

procedure TTestIdeSearch.DovrebbeIgnorareIlTestoVuoto;
begin
  FHistory.Remember('');
  Assert.AreEqual(0, FHistory.Count);
end;

procedure TTestIdeSearch.DovrebbeDareSoloIPrimiDieciTesti;
var
  LIndex: Integer;
  LLines: TArray<string>;
begin
  for LIndex := 1 to 15 do
    FHistory.Remember('t' + IntToStr(LIndex));
  Assert.AreEqual(15, FHistory.Count);
  LLines := FHistory.AsText.Split([#13#10]);
  Assert.AreEqual(10, Length(LLines));
  Assert.AreEqual('t15', LLines[0]);
  Assert.AreEqual('t6', LLines[9]);
end;

procedure TTestIdeSearch.DovrebbeRileggereIlTestoDato;
begin
  FHistory.LoadFromText('b'#13#10'a');
  Assert.AreEqual(2, FHistory.Count);
  Assert.AreEqual('b', FHistory[0]);
  Assert.AreEqual('b'#13#10'a', FHistory.AsText);
end;

procedure TTestIdeSearch.DovrebbeDareTestoVuotoSeNonCeNulla;
begin
  Assert.AreEqual('', FHistory.AsText);
end;

procedure TTestIdeSearch.DovrebbePartireSenzaOpzioniEConCronologieVuote;
begin
  Assert.IsFalse(FSettings.Backwards or FSettings.CaseSensitive or FSettings.FromCaret or
    FSettings.SelectionOnly or FSettings.TextAtCaret or FSettings.WholeWords or
    FSettings.RegularExpression);
  Assert.AreEqual('', FSettings.SearchText);
  Assert.AreEqual('', FSettings.ReplaceText);
  Assert.AreEqual(0, FSettings.SearchHistory.Count);
  Assert.AreEqual(0, FSettings.ReplaceHistory.Count);
end;

procedure TTestIdeSearch.DovrebbeFareLaRicercaDaCima;
var
  LPlan: TIdeSearchPlan;
begin
  LPlan := TIdeSearchPlans.ForDialog(FSettings, False, False);
  Assert.IsTrue(LPlan.Flags = [sfEntireScope]);
  Assert.IsFalse(LPlan.UseRegularExpression);
end;

procedure TTestIdeSearch.DovrebbeFareLaRicercaDalCursore;
begin
  Assert.IsTrue(TIdeSearchPlans.ForDialog(FSettings, False, True).Flags = []);
end;

procedure TTestIdeSearch.DovrebbeUnireLeOpzioniDellaRicerca;
begin
  FSettings.Backwards := True;
  FSettings.CaseSensitive := True;
  FSettings.SelectionOnly := True;
  FSettings.WholeWords := True;
  Assert.IsTrue(TIdeSearchPlans.ForDialog(FSettings, False, True).Flags =
    [sfBackwards, sfMatchCase, sfSelectedOnly, sfWholeWord]);
end;

procedure TTestIdeSearch.DovrebbeChiedereConfermaESostituireTuttoNelleSostituzioni;
begin
  Assert.IsTrue(TIdeSearchPlans.ForDialog(FSettings, True, True).Flags =
    [sfPrompt, sfReplace, sfReplaceAll]);
  FSettings.CaseSensitive := True;
  Assert.IsTrue(TIdeSearchPlans.ForDialog(FSettings, True, False).Flags =
    [sfPrompt, sfReplace, sfReplaceAll, sfMatchCase, sfEntireScope]);
end;

procedure TTestIdeSearch.DovrebbeUsareIlMotoreDelleEspressioniSeRichiesto;
begin
  FSettings.RegularExpression := True;
  Assert.IsTrue(TIdeSearchPlans.ForDialog(FSettings, False, True).UseRegularExpression);
  Assert.IsTrue(TIdeSearchPlans.ForSearchAgain(FSettings).UseRegularExpression);
end;

procedure TTestIdeSearch.DovrebbeFareLaRicercaSuccessivaSenzaDaCimaESenzaSostituire;
var
  LPlan: TIdeSearchPlan;
begin
  FSettings.Backwards := True;
  FSettings.WholeWords := True;
  FSettings.FromCaret := False;
  LPlan := TIdeSearchPlans.ForSearchAgain(FSettings);
  Assert.IsTrue(LPlan.Flags = [sfBackwards, sfWholeWord]);
end;

end.
