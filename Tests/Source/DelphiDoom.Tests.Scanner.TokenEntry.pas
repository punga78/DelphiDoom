{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the names of an entry of a token list (DUnitX)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.TokenEntry;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('scanner')]
  TTestScannerTokenEntry = class
  public
    [Test]
    procedure DovrebbeDareUnNomeSolaSenzaVirgole;
    [Test]
    procedure DovrebbeSpezzareLeVirgoleEPulireOgniNome;
    [Test]
    procedure DovrebbeDareNienteSeLeVirgoleSonoDaSole;
    [Test]
    procedure ListsTokenDovrebbeIgnorareLeVoceSingole;
    [Test]
    procedure ListsTokenDovrebbeConservareIlDifettoDelPrimoNome;
    [Test]
    procedure ListsTokenDovrebbeConfrontareSenzaMaiuscole;
    [Test]
    procedure IndexOfTokenDovrebbePreferireLaRicercaSemplice;
    [Test]
    procedure IndexOfTokenDovrebbeDareMenoUnoSeManca;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioElencoSuVociCasuali;
    [Test]
    procedure DovrebbeDareGliStessiNomiDelVecchioAllTokensWithIndex;
    [Test]
    procedure DovrebbeValutareGliInteriCometeVecchiaFunzione;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.Scanner.TokenEntry,
  DelphiDoom.Tests.InfoTables.LegacyTokens;

const
  Alphabet: array[0..9] of string = ('A', 'b', 'S_X', ',', ',', ' ', #9, #13#10, #10, '=');

function RandomEntry(const ASeed: Integer): string;
var
  LLength: Integer;
  LIndex: Integer;
begin
  Result := '';
  LLength := Random(8);
  for LIndex := 1 to LLength do
    Result := Result + Alphabet[Random(Length(Alphabet))];
  if ASeed < 0 then
    Result := '';
end;

procedure TTestScannerTokenEntry.DovrebbeDareUnNomeSolaSenzaVirgole;
var
  LNames: TArray<string>;
begin
  LNames := TScannerTokenEntry.Split('  S_PLAY ');
  Assert.AreEqual(1, Length(LNames));
  Assert.AreEqual('S_PLAY', LNames[0]);
  LNames := TScannerTokenEntry.Split('');
  Assert.AreEqual(1, Length(LNames));
  Assert.AreEqual('', LNames[0]);
end;

procedure TTestScannerTokenEntry.DovrebbeSpezzareLeVirgoleEPulireOgniNome;
var
  LNames: TArray<string>;
begin
  LNames := TScannerTokenEntry.Split(' S_A , S_B,S_C ');
  Assert.AreEqual(3, Length(LNames));
  Assert.AreEqual('S_A', LNames[0]);
  Assert.AreEqual('S_B', LNames[1]);
  Assert.AreEqual('S_C', LNames[2]);
end;

procedure TTestScannerTokenEntry.DovrebbeDareNienteSeLeVirgoleSonoDaSole;
begin
  Assert.AreEqual(0, Length(TScannerTokenEntry.Split(' , ')));
end;

procedure TTestScannerTokenEntry.ListsTokenDovrebbeIgnorareLeVoceSingole;
begin
  Assert.IsFalse(TScannerTokenEntry.ListsToken('S_A', 'S_A'));
  Assert.IsTrue(TScannerTokenEntry.ListsToken('S_A, S_B', 'S_B'));
end;

procedure TTestScannerTokenEntry.ListsTokenDovrebbeConservareIlDifettoDelPrimoNome;
var
  LOld: TLegacyTokenList;
begin
  // TDStringList.Put ignores index 0: the old list did not trim the first name
  LOld := TLegacyTokenList.Create;
  try
    LOld.Add('S_A , S_B');
    Assert.AreEqual(-1, LOld.IndexOfToken('S_A'));
    Assert.AreEqual(0, LOld.IndexOfToken('S_B'));
  finally
    LOld.Free;
  end;
  Assert.IsFalse(TScannerTokenEntry.ListsToken('S_A , S_B', 'S_A'));
  Assert.IsTrue(TScannerTokenEntry.ListsToken('S_A , S_B', 'S_B'));
  Assert.IsTrue(TScannerTokenEntry.ListsToken('S_A, S_B', 'S_A'));
end;

procedure TTestScannerTokenEntry.ListsTokenDovrebbeConfrontareSenzaMaiuscole;
begin
  Assert.IsTrue(TScannerTokenEntry.ListsToken('S_A, S_B', 's_b'));
  Assert.IsFalse(TScannerTokenEntry.ListsToken('S_A, S_B', 'S_C'));
end;

procedure TTestScannerTokenEntry.IndexOfTokenDovrebbePreferireLaRicercaSemplice;
begin
  // the second entry matches as a whole, the first one only lists the name
  Assert.AreEqual(1, TScannerTokenEntry.IndexOfToken(['X, Y', 'Y'], 'Y'));
  Assert.AreEqual(0, TScannerTokenEntry.IndexOfToken(['X, Y', 'Z'], 'Y'));
end;

procedure TTestScannerTokenEntry.IndexOfTokenDovrebbeDareMenoUnoSeManca;
begin
  Assert.AreEqual(-1, TScannerTokenEntry.IndexOfToken(['X, Y', 'Z'], 'W'));
  Assert.AreEqual(-1, TScannerTokenEntry.IndexOfToken([], 'W'));
end;

procedure TTestScannerTokenEntry.DovrebbeDareGliStessiRisultatiDelVecchioElencoSuVociCasuali;
var
  LOld: TLegacyTokenList;
  LRound: Integer;
  LEntry: Integer;
  LEntries: TArray<string>;
  LToken: string;
  LNames: TArray<string>;
begin
  RandSeed := 185;
  for LRound := 1 to 3000 do
  begin
    LOld := TLegacyTokenList.Create;
    try
      SetLength(LEntries, 1 + Random(5));
      for LEntry := 0 to High(LEntries) do
      begin
        LEntries[LEntry] := RandomEntry(LEntry);
        LOld.Add(LEntries[LEntry]);
      end;
      LToken := RandomEntry(LRound);
      if Random(3) = 0 then
      begin
        LNames := TScannerTokenEntry.Split(LEntries[Random(Length(LEntries))]);
        if Length(LNames) > 0 then
          LToken := LNames[Random(Length(LNames))];
      end;
      Assert.AreEqual(LOld.IndexOfToken(LToken), TScannerTokenEntry.IndexOfToken(LEntries, LToken),
        'round ' + IntToStr(LRound) + ' token "' + LToken + '" entries ' + string.Join('|', LEntries).Replace(#13, '<CR>').Replace(#10, '<LF>').Replace(#9, '<TAB>'));
    finally
      LOld.Free;
    end;
  end;
end;

procedure TTestScannerTokenEntry.DovrebbeDareGliStessiNomiDelVecchioAllTokensWithIndex;
var
  LOld: TLegacyTokenList;
  LAll: TDStringList;
  LRound: Integer;
  LEntry: Integer;
  LNames: TArray<string>;
  LPosition: Integer;
  LName: Integer;
begin
  RandSeed := 186;
  for LRound := 1 to 2000 do
  begin
    LOld := TLegacyTokenList.Create;
    try
      for LEntry := 0 to Random(5) do
        LOld.Add(RandomEntry(LEntry));
      LAll := LOld.AllTokensWithIndex;
      try
        LPosition := 0;
        for LEntry := 0 to LOld.Count - 1 do
        begin
          LNames := TScannerTokenEntry.Split(LOld[LEntry]);
          for LName := 0 to High(LNames) do
          begin
            Assert.AreEqual(LAll[LPosition], LNames[LName]);
            Assert.AreEqual(LEntry, (LAll.Objects[LPosition] as TInteger).intnum);
            Inc(LPosition);
          end;
        end;
        Assert.AreEqual(LAll.Count, LPosition);
      finally
        for LEntry := 0 to LAll.Count - 1 do
          LAll.Objects[LEntry].Free;
        LAll.Free;
      end;
    finally
      LOld.Free;
    end;
  end;
end;

procedure TTestScannerTokenEntry.DovrebbeValutareGliInteriCometeVecchiaFunzione;
const
  Tokens: array[0..4] of string = ('S_B', 'x', '12', '-3', 'S_C');
var
  LToken: string;
begin
  for LToken in Tokens do
    Assert.AreEqual(Legacy_EvalueateIntToken(LToken, ['S_A', 'S_B, S_C', 'x']),
      Legacy_EvalueateIntToken(LToken, ['S_A', 'S_B, S_C', 'x']));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScannerTokenEntry);

end.
