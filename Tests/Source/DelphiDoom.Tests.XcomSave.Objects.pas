{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom saved game library - the objects one by one    }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSave.Objects;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf, DelphiDoom.Yaml.Factory,
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Random, DelphiDoom.XcomMod.RuleCountry, DelphiDoom.XcomMod.RuleRegion,
  DelphiDoom.XcomMod.RuleResearch, DelphiDoom.XcomSave.NodeWriter, DelphiDoom.XcomSave.GameTime,
  DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.ResearchProject,
  DelphiDoom.XcomSave.Serialization;

type
  [TestFixture]
  [Category('xcom-save')]
  TTestXcomSaveObjects = class(TObject)
  private
    function Node(const AText: string): IYamlNode;
  public
    [Test]
    procedure DovrebbeScrivereIlNodoConGliAssegnamenti;
    [Test]
    procedure DovrebbeTenereUnaSequenzaVuotaComeSequenza;
    [Test]
    procedure DovrebbeAvanzareDiCinqueSecondiEdAnno;
    [Test]
    procedure DovrebbeRiconoscereGliAnniBisestili;
    [Test]
    procedure DovrebbeDareLeChiaviDelTestoDelGiornoSettimanaEMese;
    [Test]
    procedure DovrebbeRifiutareUnMeseFuoriDallaTabella;
    [Test]
    procedure DovrebbeRifiutareUnGiornoDellaSettimanaFuoriDallaTabella;
    [Test]
    procedure DovrebbeDareLaLuceDelGiorno;
    [Test]
    procedure DovrebbeIniziareUnPaeseConUnMeseVuoto;
    [Test]
    procedure DovrebbeSalvareIlPatto;
    [Test]
    procedure DovrebbeRifiutareIlMeseCorrenteDiUnPaeseSenzaFinanziamento;
    [Test]
    procedure DovrebbeEntrarePattoAlProssimoMese;
    [Test]
    procedure DovrebbeTenereAlMassimoDodiciMesi;
    [Test]
    procedure DovrebbeCambiareIlFinanziamentoDelMeseCorrente;
    [Test]
    procedure DovrebbeSommareLAttivitaDellaRegione;
    [Test]
    procedure DovrebbeRifiutareLAttivitaDiUnaRegioneVuota;
    [Test]
    procedure DovrebbeDireCheLaRicercaVaBene;
    [Test]
    procedure DovrebbeDareIlGiudizioDiUnaRicercaConCostoZero;
    [Test]
    procedure DovrebbeFinireLaRicerca;
    [Test]
    procedure DovrebbeLeggereEScrivereGliInteriDiUnoDueQuattroByte;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneNonValida;
    [Test]
    procedure DovrebbeRifiutareUnValoreCheNonEntra;
    [Test]
    procedure DovrebbeScrivereUnDoubleConDiciassetteCifre;
  end;

implementation

{ TTestXcomSaveObjects }

function TTestXcomSaveObjects.Node(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

procedure TTestXcomSaveObjects.DovrebbeScrivereIlNodoConGliAssegnamenti;
var
  LNode: IYamlNode;
begin
  LNode := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetInteger(LNode, 'n', -4);
  TXcomNodeWriter.SetString(LNode, 's', 'text');
  TXcomNodeWriter.SetBoolean(LNode, 'yes', True);
  TXcomNodeWriter.SetBoolean(LNode, 'no', False);
  TXcomNodeWriter.SetIntegers(LNode, 'list', [1, 2]);
  Assert.AreEqual('-4', YamlTextToString(LNode.Find('n').AsString));
  Assert.AreEqual('true', YamlTextToString(LNode.Find('yes').AsString));
  Assert.AreEqual('false', YamlTextToString(LNode.Find('no').AsString));
  Assert.AreEqual(2, LNode.Find('list').Size);
end;

procedure TTestXcomSaveObjects.DovrebbeTenereUnaSequenzaVuotaComeSequenza;
var
  LNode: IYamlNode;
begin
  LNode := TXcomNodeWriter.NewMap;
  TXcomNodeWriter.SetIntegers(LNode, 'list', []);
  Assert.IsTrue(LNode.Find('list').IsSequence);
  Assert.AreEqual(0, LNode.Find('list').Size);
end;

procedure TTestXcomSaveObjects.DovrebbeAvanzareDiCinqueSecondiEdAnno;
var
  LTime: TXcomGameTime;
begin
  LTime := TXcomGameTime.Create(7, 31, 12, 1999, 23, 59, 55);
  try
    Assert.AreEqual(Ord(ttMonth), Ord(LTime.Advance));
    Assert.AreEqual(2000, LTime.Year);
    Assert.AreEqual(1, LTime.Month);
    Assert.AreEqual(1, LTime.Day);
    Assert.AreEqual(1, LTime.Weekday);
    Assert.AreEqual(0, LTime.Hour);
    Assert.AreEqual(Ord(ttFiveSeconds), Ord(LTime.Advance));
    Assert.AreEqual(5, LTime.Second);
  finally
    LTime.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeRiconoscereGliAnniBisestili;
var
  LTime: TXcomGameTime;
begin
  LTime := TXcomGameTime.Create(1, 28, 2, 2000, 23, 59, 55);
  try
    LTime.Advance;
    Assert.AreEqual(29, LTime.Day, '2000 e'' bisestile');
    Assert.AreEqual(2, LTime.Month);
  finally
    LTime.Free;
  end;
  LTime := TXcomGameTime.Create(1, 28, 2, 1900, 23, 59, 55);
  try
    LTime.Advance;
    Assert.AreEqual(1, LTime.Day, '1900 no');
    Assert.AreEqual(3, LTime.Month);
  finally
    LTime.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeDareLeChiaviDelTestoDelGiornoSettimanaEMese;
var
  LTime: TXcomGameTime;
begin
  LTime := TXcomGameTime.Create(1, 1, 1, 1999, 0, 0, 0);
  try
    Assert.AreEqual('STR_SUNDAY', LTime.WeekdayString);
    Assert.AreEqual('STR_JAN', LTime.MonthString);
    Assert.AreEqual('STR_DATE_FIRST', LTime.DayStringKey);
    LTime.Load(Node('day: 22'));
    Assert.AreEqual('STR_DATE_SECOND', LTime.DayStringKey);
    LTime.Load(Node('day: 23'));
    Assert.AreEqual('STR_DATE_THIRD', LTime.DayStringKey);
    LTime.Load(Node('day: 4'));
    Assert.AreEqual('STR_DATE_FOURTH', LTime.DayStringKey);
  finally
    LTime.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeRifiutareUnMeseFuoriDallaTabella;
var
  LTime: TXcomGameTime;
begin
  LTime := TXcomGameTime.Create(1, 1, 13, 1999, 0, 0, 0);
  try
    Assert.WillRaise(
      procedure
      begin
        LTime.MonthString;
      end, EXcomSaveRangeException);
    Assert.WillRaise(
      procedure
      begin
        LTime.Advance;
      end, EXcomSaveRangeException);
  finally
    LTime.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeRifiutareUnGiornoDellaSettimanaFuoriDallaTabella;
var
  LTime: TXcomGameTime;
begin
  LTime := TXcomGameTime.Create(0, 1, 1, 1999, 0, 0, 0);
  try
    Assert.WillRaise(
      procedure
      begin
        LTime.WeekdayString;
      end, EXcomSaveRangeException);
  finally
    LTime.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeDareLaLuceDelGiorno;
var
  LTime: TXcomGameTime;
begin
  LTime := TXcomGameTime.Create(1, 1, 1, 1999, 12, 0, 0);
  try
    Assert.AreEqual(Double(0.25), LTime.Daylight, 'a mezzogiorno sono passate sei ore dalla sera');
  finally
    LTime.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeIniziareUnPaeseConUnMeseVuoto;
var
  LRules: TXcomRuleCountry;
  LCountry: TXcomCountry;
begin
  LRules := TXcomRuleCountry.Create('STR_C');
  try
    LRules.Load(Node('fundingBase: 5'));
    LCountry := TXcomCountry.Create(LRules, True, TXcomRandom.Create(1));
    try
      Assert.AreEqual<Integer>(1, Length(LCountry.Funding));
      Assert.IsTrue(LCountry.Funding[0] mod 1000 = 0);
      Assert.AreEqual<Integer>(1, Length(LCountry.ActivityXcom));
      Assert.AreEqual(2, LCountry.Satisfaction);
      Assert.AreSame(LRules, LCountry.Rules);
    finally
      LCountry.Free;
    end;
    LCountry := TXcomCountry.Create(LRules, False, TXcomRandom.Create(1));
    try
      Assert.AreEqual<Integer>(0, Length(LCountry.Funding));
    finally
      LCountry.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeSalvareIlPatto;
var
  LRules: TXcomRuleCountry;
  LCountry: TXcomCountry;
  LNode: IYamlNode;
begin
  LRules := TXcomRuleCountry.Create('STR_C');
  try
    LCountry := TXcomCountry.Create(LRules, False, TXcomRandom.Create(1));
    try
      LCountry.NewPact := True;
      LNode := LCountry.Save;
      Assert.IsTrue(LNode.Find('newPact').IsDefined);
      Assert.IsFalse(LNode.Find('pact').IsDefined);
      LCountry.Pact := True;
      LNode := LCountry.Save;
      Assert.IsTrue(LNode.Find('pact').IsDefined);
      Assert.IsFalse(LNode.Find('newPact').IsDefined);
      Assert.AreEqual(0, LCountry.Satisfaction);
    finally
      LCountry.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeRifiutareIlMeseCorrenteDiUnPaeseSenzaFinanziamento;
var
  LRules: TXcomRuleCountry;
  LCountry: TXcomCountry;
begin
  LRules := TXcomRuleCountry.Create('STR_C');
  try
    LCountry := TXcomCountry.Create(LRules, False, TXcomRandom.Create(1));
    try
      Assert.WillRaise(
        procedure
        begin
          LCountry.SetFunding(5);
        end, EXcomModException);
      Assert.WillRaise(
        procedure
        begin
          LCountry.NewMonth(0, 0, 0, TXcomRandom.Create(1));
        end, EXcomModException);
    finally
      LCountry.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeEntrarePattoAlProssimoMese;
var
  LRules: TXcomRuleCountry;
  LCountry: TXcomCountry;
begin
  LRules := TXcomRuleCountry.Create('STR_C');
  try
    LCountry := TXcomCountry.Create(LRules, False, TXcomRandom.Create(1));
    try
      LCountry.Funding := [5000];
      LCountry.NewPact := True;
      LCountry.NewMonth(0, 0, 9, TXcomRandom.Create(3));
      Assert.IsTrue(LCountry.Pact);
      Assert.IsFalse(LCountry.NewPact);
      Assert.AreEqual(9, LCountry.ActivityAlien[0]);
      Assert.AreEqual(0, LCountry.Funding[High(LCountry.Funding)]);
    finally
      LCountry.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeTenereAlMassimoDodiciMesi;
var
  LRules: TXcomRuleCountry;
  LCountry: TXcomCountry;
  LMonth: Integer;
begin
  LRules := TXcomRuleCountry.Create('STR_C');
  try
    LCountry := TXcomCountry.Create(LRules, False, TXcomRandom.Create(1));
    try
      LCountry.Funding := [1000];
      LCountry.SetFunding(7000);
      for LMonth := 1 to 20 do
        LCountry.NewMonth(0, 0, 0, TXcomRandom.Create(LMonth));
      Assert.AreEqual<Integer>(12, Length(LCountry.Funding));
      Assert.AreEqual<Integer>(12, Length(LCountry.ActivityXcom));
      Assert.AreEqual<Integer>(12, Length(LCountry.ActivityAlien));
    finally
      LCountry.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeCambiareIlFinanziamentoDelMeseCorrente;
var
  LRules: TXcomRuleCountry;
  LCountry: TXcomCountry;
begin
  LRules := TXcomRuleCountry.Create('STR_C');
  try
    LRules.Load(Node('fundingCap: 8'));
    LCountry := TXcomCountry.Create(LRules, False, TXcomRandom.Create(1));
    try
      LCountry.Funding := [7000];
      LCountry.ActivityXcom := [100];
      LCountry.NewMonth(1000, 0, 0, TXcomRandom.Create(5));
      Assert.IsTrue(LCountry.Funding[1] <= 8000, 'non supera il tetto');
      Assert.IsTrue(LCountry.Satisfaction in [2, 3]);
    finally
      LCountry.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeSommareLAttivitaDellaRegione;
var
  LRules: TXcomRuleRegion;
  LRegion: TXcomRegion;
begin
  LRules := TXcomRuleRegion.Create('STR_R');
  try
    LRegion := TXcomRegion.Create(LRules);
    try
      LRegion.AddActivityXcom(4);
      LRegion.AddActivityXcom(3);
      LRegion.AddActivityAlien(-2);
      Assert.AreEqual(7, LRegion.ActivityXcom[0]);
      Assert.AreEqual(-2, LRegion.ActivityAlien[0]);
      Assert.AreSame(LRules, LRegion.Rules);
    finally
      LRegion.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeRifiutareLAttivitaDiUnaRegioneVuota;
var
  LRules: TXcomRuleRegion;
  LRegion: TXcomRegion;
begin
  LRules := TXcomRuleRegion.Create('STR_R');
  try
    LRegion := TXcomRegion.Create(LRules);
    try
      LRegion.ActivityXcom := nil;
      Assert.WillRaise(
        procedure
        begin
          LRegion.AddActivityXcom(1);
        end, EXcomModException);
      LRegion.ActivityAlien := nil;
      Assert.WillRaise(
        procedure
        begin
          LRegion.AddActivityAlien(1);
        end, EXcomModException);
    finally
      LRegion.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeDireCheLaRicercaVaBene;
var
  LRules: TXcomRuleResearch;
  LProject: TXcomResearchProject;
begin
  LRules := TXcomRuleResearch.Create('STR_T');
  try
    LRules.Load(Node('cost: 100'), 1);
    LProject := TXcomResearchProject.Create(LRules, 100);
    try
      Assert.AreEqual('STR_NONE', LProject.ResearchProgress);
      LProject.Assigned := 5;
      Assert.AreEqual('STR_UNKNOWN', LProject.ResearchProgress);
      LProject.Spent := 50;
      Assert.AreEqual('STR_POOR', LProject.ResearchProgress);
      LProject.Assigned := 13;
      Assert.AreEqual('STR_AVERAGE', LProject.ResearchProgress);
      LProject.Assigned := 25;
      Assert.AreEqual('STR_GOOD', LProject.ResearchProgress);
      LProject.Assigned := 26;
      Assert.AreEqual('STR_EXCELLENT', LProject.ResearchProgress);
      Assert.AreSame(LRules, LProject.Rules);
    finally
      LProject.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeDareIlGiudizioDiUnaRicercaConCostoZero;
var
  LRules: TXcomRuleResearch;
  LProject: TXcomResearchProject;
begin
  LRules := TXcomRuleResearch.Create('STR_T');
  try
    LProject := TXcomResearchProject.Create(LRules, 0);
    try
      LProject.Assigned := 2;
      LProject.Spent := -1;
      Assert.AreEqual('STR_UNKNOWN', LProject.ResearchProgress);
      LProject.Spent := 4;
      Assert.AreEqual('STR_EXCELLENT', LProject.ResearchProgress);
      LProject.Assigned := -2;
      Assert.AreEqual('STR_POOR', LProject.ResearchProgress);
    finally
      LProject.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeFinireLaRicerca;
var
  LRules: TXcomRuleResearch;
  LProject: TXcomResearchProject;
begin
  LRules := TXcomRuleResearch.Create('STR_T');
  try
    LProject := TXcomResearchProject.Create(LRules, 10);
    try
      LProject.Assigned := 6;
      Assert.IsFalse(LProject.Step);
      Assert.IsTrue(LProject.Step);
      Assert.AreEqual(12, LProject.Spent);
      LProject.Cost := 20;
      Assert.AreEqual(20, LProject.Cost);
      Assert.IsFalse(LProject.IsFinished);
    finally
      LProject.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TTestXcomSaveObjects.DovrebbeLeggereEScrivereGliInteriDiUnoDueQuattroByte;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 8);
  TXcomSerialization.SerializeInt(LBuffer, 0, 1, 200);
  Assert.AreEqual(200, TXcomSerialization.UnserializeInt(LBuffer, 0, 1));
  TXcomSerialization.SerializeInt(LBuffer, 2, 2, -3);
  Assert.AreEqual(-3, TXcomSerialization.UnserializeInt(LBuffer, 2, 2));
  TXcomSerialization.SerializeInt(LBuffer, 4, 4, -2);
  Assert.AreEqual(-2, TXcomSerialization.UnserializeInt(LBuffer, 4, 4));
  Assert.AreEqual(Integer($FE), Integer(LBuffer[4]));
end;

procedure TTestXcomSaveObjects.DovrebbeRifiutareUnaDimensioneNonValida;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 8);
  Assert.WillRaise(
    procedure
    begin
      TXcomSerialization.SerializeInt(LBuffer, 0, 3, 1);
    end, EXcomSerializationException);
  Assert.WillRaise(
    procedure
    begin
      TXcomSerialization.UnserializeInt(LBuffer, 0, 3);
    end, EXcomSerializationException);
end;

procedure TTestXcomSaveObjects.DovrebbeRifiutareUnValoreCheNonEntra;
var
  LBuffer: TBytes;
begin
  SetLength(LBuffer, 8);
  Assert.WillRaise(
    procedure
    begin
      TXcomSerialization.SerializeInt(LBuffer, 0, 1, 256);
    end, EXcomSerializationException);
  Assert.WillRaise(
    procedure
    begin
      TXcomSerialization.SerializeInt(LBuffer, 0, 2, 65536);
    end, EXcomSerializationException);
end;

procedure TTestXcomSaveObjects.DovrebbeScrivereUnDoubleConDiciassetteCifre;
begin
  Assert.AreEqual('0.10000000000000001', TXcomSerialization.SerializeDouble(0.1));
  Assert.AreEqual('1e+21', TXcomSerialization.SerializeDouble(1E21));
  Assert.AreEqual('-1.5', TXcomSerialization.SerializeDouble(-1.5));
end;

end.
