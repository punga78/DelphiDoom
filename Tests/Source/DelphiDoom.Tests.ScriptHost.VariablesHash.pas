{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the hash table and the hash list of the variables      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.VariablesHash;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Variables.HashTable,
  DelphiDoom.ScriptHost.Variables.HashList;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostVariablesHash = class(TObject)
  private
    FList: TScriptHashStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareZeroPerUnNomeVuoto;
    [Test]
    procedure DovrebbeDareIlValoreDelVecchioHash;
    [Test]
    procedure DovrebbeDareSempreUnaCatenaValida;
    [Test]
    procedure DovrebbeUsareSoloIlByteBassoDiOgniCarattere;
    [Test]
    procedure DovrebbeDareMenoUnoSeLaListaELaTabellaSonoVuote;
    [Test]
    procedure DovrebbeTrovareLaPosizioneDiOgniStringaAggiunta;
    [Test]
    procedure DovrebbeDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeTrovareStringheDellaStessaCatena;
    [Test]
    procedure DovrebbeTrovareStringheConPiuDiCinqueRicerche;
    [Test]
    procedure DovrebbeRifareLaTabellaSeSiInserisceInMezzo;
    [Test]
    procedure DovrebbeUsareLaRicercaDellaListaSeOrdinata;
    [Test]
    procedure DovrebbeDareMenoUnoSeUnaRicercaRecenteNonEPiuValida;
    [Test]
    procedure DovrebbeIndicizzareUnaListaGiaPiena;
  end;

implementation

{ TTestScriptHostVariablesHash }

procedure TTestScriptHostVariablesHash.Setup;
begin
  FList := TScriptHashStringList.Create;
end;

procedure TTestScriptHostVariablesHash.TearDown;
begin
  FList.Free;
end;

procedure TTestScriptHostVariablesHash.DovrebbeDareZeroPerUnNomeVuoto;
begin
  Assert.AreEqual(0, TScriptHashTable.HashOf(''));
end;

procedure TTestScriptHostVariablesHash.DovrebbeDareIlValoreDelVecchioHash;
begin
  // (5381 * 33 + 65) and 8191 ; ((5381 * 33 + 65) * 33 + 66) and 8191
  Assert.AreEqual(5606, TScriptHashTable.HashOf('A'));
  Assert.AreEqual(4840, TScriptHashTable.HashOf('AB'));
end;

procedure TTestScriptHostVariablesHash.DovrebbeDareSempreUnaCatenaValida;
var
  LIndex: Integer;
  LHash: Integer;
begin
  for LIndex := 0 to 2000 do
  begin
    LHash := TScriptHashTable.HashOf('NAME' + IntToStr(LIndex * 7919) + StringOfChar('Z', LIndex mod 50));
    Assert.IsTrue((LHash >= 0) and (LHash < 8192));
  end;
end;

procedure TTestScriptHostVariablesHash.DovrebbeUsareSoloIlByteBassoDiOgniCarattere;
begin
  // the first version of the engine took Ord(char) in a Byte: $0141 is $41
  Assert.AreEqual(TScriptHashTable.HashOf('A'), TScriptHashTable.HashOf(#$0141));
end;

procedure TTestScriptHostVariablesHash.DovrebbeDareMenoUnoSeLaListaELaTabellaSonoVuote;
begin
  Assert.AreEqual(-1, FList.IndexOf('ANYTHING'));
  Assert.AreEqual(-1, FList.IndexOf(''));
end;

procedure TTestScriptHostVariablesHash.DovrebbeTrovareLaPosizioneDiOgniStringaAggiunta;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 499 do
    Assert.AreEqual(LIndex, FList.Add('V' + IntToStr(LIndex)));
  for LIndex := 499 downto 0 do
    Assert.AreEqual(LIndex, FList.IndexOf('V' + IntToStr(LIndex)));
  Assert.AreEqual(-1, FList.IndexOf('V500'));
end;

procedure TTestScriptHostVariablesHash.DovrebbeDistinguereLeMaiuscole;
begin
  FList.Add('ABC');
  Assert.AreEqual(0, FList.IndexOf('ABC'));
  Assert.AreEqual(-1, FList.IndexOf('abc'));
end;

procedure TTestScriptHostVariablesHash.DovrebbeTrovareStringheDellaStessaCatena;
var
  LFirst: string;
  LSecond: string;
  LIndex: Integer;
begin
  // two different names with the same hash
  LFirst := 'A0';
  LSecond := '';
  for LIndex := 0 to 100000 do
    if (('B' + IntToStr(LIndex)) <> LFirst) and
      (TScriptHashTable.HashOf('B' + IntToStr(LIndex)) = TScriptHashTable.HashOf(LFirst)) then
    begin
      LSecond := 'B' + IntToStr(LIndex);
      Break;
    end;
  Assert.AreNotEqual('', LSecond);
  FList.Add(LFirst);
  FList.Add(LSecond);
  Assert.AreEqual(1, FList.IndexOf(LSecond));
  Assert.AreEqual(0, FList.IndexOf(LFirst));
  Assert.AreEqual(1, FList.IndexOf(LSecond));
end;

procedure TTestScriptHostVariablesHash.DovrebbeTrovareStringheConPiuDiCinqueRicerche;
var
  LIndex: Integer;
  LRound: Integer;
begin
  for LIndex := 0 to 19 do
    FList.Add('N' + IntToStr(LIndex));
  // the last 5 positions found are kept, the others are found again through the chain
  for LRound := 1 to 3 do
    for LIndex := 0 to 19 do
      Assert.AreEqual(LIndex, FList.IndexOf('N' + IntToStr(LIndex)));
end;

procedure TTestScriptHostVariablesHash.DovrebbeRifareLaTabellaSeSiInserisceInMezzo;
begin
  FList.Add('B');
  FList.Add('C');
  Assert.AreEqual(1, FList.IndexOf('C'));
  FList.Insert(0, 'A');
  Assert.AreEqual(0, FList.IndexOf('A'));
  Assert.AreEqual(1, FList.IndexOf('B'));
  Assert.AreEqual(2, FList.IndexOf('C'));
end;

procedure TTestScriptHostVariablesHash.DovrebbeUsareLaRicercaDellaListaSeOrdinata;
begin
  FList.Sorted := True;
  FList.Add('B');
  FList.Add('A');
  FList.Add('C');
  Assert.AreEqual(0, FList.IndexOf('A'));
  Assert.AreEqual(2, FList.IndexOf('C'));
  Assert.AreEqual(-1, FList.IndexOf('D'));
end;

procedure TTestScriptHostVariablesHash.DovrebbeDareMenoUnoSeUnaRicercaRecenteNonEPiuValida;
begin
  FList.Add('A');
  FList.Add('B');
  Assert.AreEqual(1, FList.IndexOf('B'));
  // the string at the position found before is another one now
  FList.Delete(1);
  Assert.AreEqual(-1, FList.IndexOf('B'));
  Assert.AreEqual(0, FList.IndexOf('A'));
end;

procedure TTestScriptHostVariablesHash.DovrebbeIndicizzareUnaListaGiaPiena;
var
  LTable: TScriptHashTable;
  LStrings: TStringList;
begin
  LStrings := TStringList.Create;
  LTable := TScriptHashTable.Create;
  try
    LStrings.Add('ONE');
    LStrings.Add('TWO');
    LTable.AssignStringList(LStrings);
    Assert.AreEqual(1, LTable.CheckPos('TWO'));
    Assert.AreEqual(0, LTable.CheckPos('ONE'));
    Assert.AreEqual(-1, LTable.CheckPos('THREE'));
    // assigning again forgets what was there
    LStrings.Clear;
    LStrings.Add('THREE');
    LTable.AssignStringList(LStrings);
    Assert.AreEqual(0, LTable.CheckPos('THREE'));
    Assert.AreEqual(-1, LTable.CheckPos('TWO'));
  finally
    LTable.Free;
    LStrings.Free;
  end;
end;

end.
