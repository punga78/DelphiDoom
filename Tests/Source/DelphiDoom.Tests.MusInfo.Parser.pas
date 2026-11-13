{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MUSINFO library - the parser                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MusInfo.Parser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.MusInfo.Types,
  DelphiDoom.MusInfo.Intf, DelphiDoom.Tests.MusInfo.Fakes;

type
  [TestFixture]
  [Category('musinfo')]
  TTestMusInfoParser = class(TObject)
  private
    FLog: TFakeLog;
    FLogIntf: ILog;
    FParser: IMusInfoParser;
    function ParseText(const AText: string): TArray<TMusInfoEntry>;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure TestDovrebbeLeggereMappeEMusicheInOrdine;
    [Test]
    procedure TestDovrebbeScrivereMapENomiInMaiuscolo;
    [Test]
    procedure TestNonDovrebbeDareIlNumeroDellaMusica;
    [Test]
    procedure TestDovrebbeDareNessunaVoceSeIlTestoEVuoto;
    [Test]
    procedure TestDovrebbeFermarsiSeIlPrimoTokenNonEUnaMappa;
    [Test]
    [TestCase('E1M1', 'E1M1,True')]
    [TestCase('E9M9', 'E9M9,True')]
    [TestCase('MAP01', 'MAP01,True')]
    [TestCase('MAP99', 'MAP99,True')]
    [TestCase('E1M10', 'E1M10,False')]
    [TestCase('MAP1', 'MAP1,False')]
    [TestCase('MAP100', 'MAP100,False')]
    [TestCase('EXM1', 'EXM1,False')]
    [TestCase('MAP0A', 'MAP0A,False')]
    procedure TestDovrebbeRiconoscereIlNomeDiUnaMappa(const AToken: string; AIsMap: Boolean);
    [Test]
    [TestCase('zero', '0,True')]
    [TestCase('massimo', '64,True')]
    [TestCase('oltre', '65,False')]
    [TestCase('negativo', '-1,False')]
    [TestCase('testo', 'abc,False')]
    procedure TestDovrebbeAccettareSoloGliIdNelIntervallo(const AId: string; AAccepted: Boolean);
    [Test]
    [TestCase('hex 0x', '0x10,16')]
    [TestCase('hex dollaro', '$11,17')]
    [TestCase('cancelletto', '#12,12')]
    [TestCase('piu', '+13,13')]
    [TestCase('zeri', '007,7')]
    procedure TestDovrebbeLeggereGliIdNelleForme(const AId: string; AExpected: Integer);
    [Test]
    procedure TestDovrebbeSaltareUnIdFuoriIntervalloEContinuare;
    [Test]
    procedure TestDovrebbeDareUnAvvisoPerUnIdNonValido;
    [Test]
    procedure TestDovrebbeFermarsiAlNomeVuoto;
    [Test]
    procedure TestDovrebbeSaltareUnNomeTroppoLungoConUnAvviso;
    [Test]
    procedure TestDovrebbeAccettareUnNomeDiOttoCaratteri;
    [Test]
    procedure TestDovrebbeDareUnAvvisoSeMancaIlNomeAFineTesto;
    [Test]
    procedure TestDovrebbeIgnorareICommenti;
    [Test]
    procedure TestDovrebbeLeggereIFineRigaCrLfLfECr;
    [Test]
    procedure TestDovrebbeLasciareUnaVoceDuplicataPerIlCatalogo;
    [Test]
    procedure TestDovrebbeFunzionareSenzaLog;
    [Test]
    procedure TestDovrebbeNonTenereStatoTraDueLetture;
  end;

implementation

uses
  DelphiDoom.MusInfo.Factory;

{ TTestMusInfoParser }

procedure TTestMusInfoParser.Setup;
begin
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  FParser := TMusInfoFactory.CreateParser(FLogIntf);
end;

function TTestMusInfoParser.ParseText(const AText: string): TArray<TMusInfoEntry>;
begin
  Result := FParser.Parse(AText);
end;

procedure TTestMusInfoParser.TestDovrebbeLeggereMappeEMusicheInOrdine;
var
  LEntries: TArray<TMusInfoEntry>;
begin
  LEntries := ParseText('MAP01'#13#10'1 D_ONE'#13#10'2 D_TWO'#13#10'E1M2 3 D_THREE'#13#10);
  Assert.AreEqual<Integer>(3, Length(LEntries));
  Assert.AreEqual('MAP01', LEntries[0].MapName);
  Assert.AreEqual(1, LEntries[0].MusicId);
  Assert.AreEqual('D_ONE', LEntries[0].MusicName);
  Assert.AreEqual('MAP01', LEntries[1].MapName);
  Assert.AreEqual(2, LEntries[1].MusicId);
  Assert.AreEqual('E1M2', LEntries[2].MapName);
  Assert.AreEqual(3, LEntries[2].MusicId);
  Assert.AreEqual('', FLog.Warnings);
end;

procedure TTestMusInfoParser.TestDovrebbeScrivereMapENomiInMaiuscolo;
var
  LEntries: TArray<TMusInfoEntry>;
begin
  LEntries := ParseText('map05 2 d_Five');
  Assert.AreEqual<Integer>(1, Length(LEntries));
  Assert.AreEqual('MAP05', LEntries[0].MapName);
  Assert.AreEqual('D_FIVE', LEntries[0].MusicName);
end;

procedure TTestMusInfoParser.TestNonDovrebbeDareIlNumeroDellaMusica;
var
  LEntries: TArray<TMusInfoEntry>;
begin
  LEntries := ParseText('MAP01 1 D_ONE');
  Assert.AreEqual(-1, LEntries[0].MusicNumber, 'il numero lo dà il catalogo');
end;

procedure TTestMusInfoParser.TestDovrebbeDareNessunaVoceSeIlTestoEVuoto;
begin
  Assert.AreEqual<Integer>(0, Length(ParseText('')));
  Assert.AreEqual<Integer>(0, Length(ParseText('   '#13#10#13#10)));
  Assert.AreEqual('', FLog.Warnings);
end;

procedure TTestMusInfoParser.TestDovrebbeFermarsiSeIlPrimoTokenNonEUnaMappa;
begin
  Assert.AreEqual<Integer>(0, Length(ParseText('1 D_ONE'#13#10'MAP01 1 D_TWO')));
  Assert.AreEqual('P_InitMusInfo(): Map name expected but token "1" found'#13#10, FLog.Warnings);
end;

procedure TTestMusInfoParser.TestDovrebbeRiconoscereIlNomeDiUnaMappa(const AToken: string;
  AIsMap: Boolean);
var
  LEntries: TArray<TMusInfoEntry>;
begin
  // after a first map, a token that is not a map name is read as an id: it is not valid, so it
  // is skipped with the word that follows it
  LEntries := ParseText('MAP01 1 D_A ' + AToken + ' 2 D_B');
  if AIsMap then
  begin
    Assert.AreEqual<Integer>(2, Length(LEntries));
    Assert.AreEqual(UpperCase(AToken), LEntries[1].MapName);
  end
  else
  begin
    Assert.AreEqual<Integer>(1, Length(LEntries));
    Assert.IsTrue(Pos('Invalid music id "' + AToken + '"', FLog.Warnings) > 0, FLog.Warnings);
  end;
end;

procedure TTestMusInfoParser.TestDovrebbeAccettareSoloGliIdNelIntervallo(const AId: string;
  AAccepted: Boolean);
var
  LEntries: TArray<TMusInfoEntry>;
begin
  LEntries := ParseText('MAP01 ' + AId + ' D_ONE');
  if AAccepted then
  begin
    Assert.AreEqual<Integer>(1, Length(LEntries));
    Assert.AreEqual('', FLog.Warnings);
  end
  else
  begin
    Assert.AreEqual<Integer>(0, Length(LEntries));
    Assert.AreEqual('P_InitMusInfo(): Invalid music id "' + AId +
      '" found, expected number in range [0, 64]'#13#10, FLog.Warnings);
  end;
end;

procedure TTestMusInfoParser.TestDovrebbeLeggereGliIdNelleForme(const AId: string;
  AExpected: Integer);
var
  LEntries: TArray<TMusInfoEntry>;
begin
  LEntries := ParseText('MAP01 ' + AId + ' D_ONE');
  Assert.AreEqual<Integer>(1, Length(LEntries), FLog.Warnings);
  Assert.AreEqual(AExpected, LEntries[0].MusicId);
end;

procedure TTestMusInfoParser.TestDovrebbeSaltareUnIdFuoriIntervalloEContinuare;
var
  LEntries: TArray<TMusInfoEntry>;
begin
  LEntries := ParseText('MAP01 99 D_BAD 2 D_OK');
  Assert.AreEqual<Integer>(1, Length(LEntries));
  Assert.AreEqual(2, LEntries[0].MusicId);
end;

procedure TTestMusInfoParser.TestDovrebbeDareUnAvvisoPerUnIdNonValido;
begin
  ParseText('MAP01 5.0 D_FLOAT');
  Assert.AreEqual('P_InitMusInfo(): Invalid music id "5.0" found, expected number in range [0, 64]'#13#10,
    FLog.Warnings);
end;

procedure TTestMusInfoParser.TestDovrebbeFermarsiAlNomeVuoto;
begin
  Assert.AreEqual<Integer>(0, Length(ParseText('MAP01 1 "" MAP01 2 D_TWO')), 'dopo un nome vuoto il testo è finito');
  Assert.AreEqual('', FLog.Warnings);
end;

procedure TTestMusInfoParser.TestDovrebbeSaltareUnNomeTroppoLungoConUnAvviso;
var
  LEntries: TArray<TMusInfoEntry>;
begin
  // the old code stopped the whole game here (I_Error in stringtochar8)
  LEntries := ParseText('MAP01 1 D_NINECHAR 2 D_OK');
  Assert.AreEqual<Integer>(1, Length(LEntries));
  Assert.AreEqual('D_OK', LEntries[0].MusicName);
  Assert.AreEqual('P_InitMusInfo(): Music name "D_NINECHAR" is too long, maximum size is 8 characters'#13#10,
    FLog.Warnings);
end;

procedure TTestMusInfoParser.TestDovrebbeAccettareUnNomeDiOttoCaratteri;
begin
  Assert.AreEqual<Integer>(1, Length(ParseText('MAP01 1 D_EIGHTC')));
  Assert.AreEqual('', FLog.Warnings);
end;

procedure TTestMusInfoParser.TestDovrebbeDareUnAvvisoSeMancaIlNomeAFineTesto;
var
  LEntries: TArray<TMusInfoEntry>;
begin
  // as the old code did: the scanner keeps the id as its word, which becomes the name
  LEntries := ParseText('MAP01 7');
  Assert.IsTrue(Pos('TScriptEngine.MustGetString(): Missing string at Line 1', FLog.Warnings) > 0,
    FLog.Warnings);
  Assert.AreEqual<Integer>(1, Length(LEntries));
  Assert.AreEqual('7', LEntries[0].MusicName);
end;

procedure TTestMusInfoParser.TestDovrebbeIgnorareICommenti;
var
  LEntries: TArray<TMusInfoEntry>;
begin
  LEntries := ParseText('// uno'#13#10'MAP01 1 D_ONE // due'#13#10'// MAP02 2 D_NO'#13#10);
  Assert.AreEqual<Integer>(1, Length(LEntries));
end;

procedure TTestMusInfoParser.TestDovrebbeLeggereIFineRigaCrLfLfECr;
begin
  Assert.AreEqual<Integer>(2, Length(ParseText('MAP01'#13#10'1 D_ONE'#13#10'MAP02 2 D_TWO')));
  Assert.AreEqual<Integer>(2, Length(ParseText('MAP01'#10'1 D_ONE'#10'MAP02 2 D_TWO')));
  Assert.AreEqual<Integer>(2, Length(ParseText('MAP01'#13'1 D_ONE'#13'MAP02 2 D_TWO')));
end;

procedure TTestMusInfoParser.TestDovrebbeLasciareUnaVoceDuplicataPerIlCatalogo;
begin
  // joining equal (map, id) pairs is the work of the catalog
  Assert.AreEqual<Integer>(2, Length(ParseText('MAP01 1 D_A MAP01 1 D_B')));
end;

procedure TTestMusInfoParser.TestDovrebbeFunzionareSenzaLog;
var
  LParser: IMusInfoParser;
begin
  LParser := TMusInfoFactory.CreateParser(nil);
  Assert.AreEqual<Integer>(0, Length(LParser.Parse('1 D_ONE')));
  Assert.AreEqual<Integer>(1, Length(LParser.Parse('MAP01 1 D_ONE')));
end;

procedure TTestMusInfoParser.TestDovrebbeNonTenereStatoTraDueLetture;
begin
  Assert.AreEqual<Integer>(1, Length(ParseText('MAP01 1 D_ONE')));
  // the map of the first text is not remembered
  Assert.AreEqual<Integer>(0, Length(ParseText('2 D_TWO')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMusInfoParser);

end.
