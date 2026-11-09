{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the variables of the scripts                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Variables;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Variables.Intf,
  DelphiDoom.ScriptHost.Variables.Types,
  DelphiDoom.Tests.ScriptHost.VariablesFakes;

type
  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostVariables = class(TObject)
  private
    FFiles: TFakeVariablesFiles;
    FFilesRef: IScriptVariablesFiles;
    FFailure: TFakeVariablesFailure;
    FFailureRef: IScriptVariablesFailure;
    FVariables: IScriptVariables;
    function NewVariables: IScriptVariables;
    function Saved(const AVariables: IScriptVariables): TBytes;
    function BytesOf(const AValues: array of Byte): TBytes;
    procedure SameFloat(const AExpected: Single; const AActual: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareZeroEStringaVuotaPerUnaVariabileCheNonEsiste;
    [Test]
    procedure DovrebbeCrearePutLaVariabileDelSuoTipo;
    [Test]
    procedure DovrebbeNonDistinguereLeMaiuscoleNeiNomi;
    [Test]
    procedure DovrebbeLeggereUnIntCommeFloatEUnFloatCommeIntArrotondato;
    [Test]
    procedure DovrebbeDareLaPrecedenzaAlTipoGiusto;
    [Test]
    procedure DovrebbeUsareNomeEIndiceNegliArray;
    [Test]
    procedure DovrebbeDareLaPosizioneEAggiornareSeIlNomeEsiste;
    [Test]
    procedure DovrebbeCercareConIlNomeEsattoInHas;
    [Test]
    procedure DovrebbeSvuotareConClear;
    [Test]
    procedure DovrebbeTrovareMigliaiaDiNomiAnchePerLeCollisioni;

    [Test]
    procedure DovrebbeScrivereIByteDelSalvataggioComeIlVecchioCodice;
    [Test]
    procedure DovrebbeScrivereUnaListaVuotaConTreContatori;
    [Test]
    procedure DovrebbeDareUnaStructureSizeUgualeAiByteScritti;
    [Test]
    procedure DovrebbeNonScrivereOltreStructureSize;
    [Test]
    procedure DovrebbeRileggereCiOCheHaScritto;
    [Test]
    procedure DovrebbeRileggereNomiNonAsciiELunghi;
    [Test]
    procedure DovrebbeSostituireLeVariabiliCheCeranoNelCaricamento;
    [Test]
    procedure DovrebbeDareIByteLettiDalCaricamento;
    [Test]
    procedure DovrebbeDareErroreSeIlBufferFinisceTroppoPresto;
    [Test]
    procedure DovrebbeDareErroreSeUnContatoreONegativo;

    [Test]
    procedure DovrebbeScrivereUnFileConLaLunghezzaEIDati;
    [Test]
    procedure DovrebbeRileggereUnFile;
    [Test]
    procedure DovrebbeSegnalareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeSegnalareUnFileConLunghezzaSbagliata;
    [Test]
    procedure DovrebbeSegnalareUnFileTroncato;
    [Test]
    procedure DovrebbeDareErroreSeIServiziSononil;
  end;

implementation

{ TTestScriptHostVariables }

procedure TTestScriptHostVariables.Setup;
begin
  FFiles := TFakeVariablesFiles.Create;
  FFilesRef := FFiles;
  FFailure := TFakeVariablesFailure.Create;
  FFailureRef := FFailure;
  FVariables := NewVariables;
end;

procedure TTestScriptHostVariables.TearDown;
begin
  FVariables := nil;
  FFilesRef := nil;
  FFailureRef := nil;
end;

function TTestScriptHostVariables.NewVariables: IScriptVariables;
begin
  Result := TScriptHostFactory.CreateVariables(FFilesRef, FFailureRef);
end;

procedure TTestScriptHostVariables.SameFloat(const AExpected: Single; const AActual: Single);
begin
  Assert.AreEqual(Double(AExpected), Double(AActual));
end;

function TTestScriptHostVariables.BytesOf(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

function TTestScriptHostVariables.Saved(const AVariables: IScriptVariables): TBytes;
begin
  SetLength(Result, AVariables.StructureSize);
  if Length(Result) > 0 then
    Assert.AreEqual(Length(Result), AVariables.SaveToBuffer(@Result[0]));
end;

procedure TTestScriptHostVariables.DovrebbeDareZeroEStringaVuotaPerUnaVariabileCheNonEsiste;
begin
  Assert.AreEqual(0, FVariables.IntVal['NONE']);
  SameFloat(0, FVariables.FloatVal['NONE']);
  Assert.AreEqual('', FVariables.StrVal['NONE']);
  // reading does not create
  Assert.AreEqual(0, FVariables.IntegerCount + FVariables.FloatCount + FVariables.StringCount);
end;

procedure TTestScriptHostVariables.DovrebbeCrearePutLaVariabileDelSuoTipo;
begin
  FVariables.IntVal['A'] := 5;
  FVariables.FloatVal['B'] := 2.5;
  FVariables.StrVal['C'] := 'text';
  Assert.AreEqual(5, FVariables.IntVal['A']);
  SameFloat(2.5, FVariables.FloatVal['B']);
  Assert.AreEqual('text', FVariables.StrVal['C']);
  Assert.AreEqual(1, FVariables.IntegerCount);
  Assert.AreEqual(1, FVariables.FloatCount);
  Assert.AreEqual(1, FVariables.StringCount);
end;

procedure TTestScriptHostVariables.DovrebbeNonDistinguereLeMaiuscoleNeiNomi;
begin
  FVariables.IntVal['Score'] := 3;
  Assert.AreEqual(3, FVariables.IntVal['SCORE']);
  Assert.AreEqual(3, FVariables.IntVal['score']);
  FVariables.IntVal['SCORE'] := 4;
  Assert.AreEqual(1, FVariables.IntegerCount);
  Assert.AreEqual(4, FVariables.IntVal['Score']);
end;

procedure TTestScriptHostVariables.DovrebbeLeggereUnIntCommeFloatEUnFloatCommeIntArrotondato;
begin
  FVariables.IntVal['I'] := 7;
  FVariables.FloatVal['F'] := 2.6;
  SameFloat(7, FVariables.FloatVal['I']);
  Assert.AreEqual(3, FVariables.IntVal['F']);
  FVariables.FloatVal['H'] := 2.5;
  // Round of the RTL: to the even number
  Assert.AreEqual(2, FVariables.IntVal['H']);
end;

procedure TTestScriptHostVariables.DovrebbeDareLaPrecedenzaAlTipoGiusto;
begin
  FVariables.IntVal['X'] := 1;
  FVariables.FloatVal['X'] := 9.5;
  Assert.AreEqual(1, FVariables.IntVal['X']);
  SameFloat(9.5, FVariables.FloatVal['X']);
end;

procedure TTestScriptHostVariables.DovrebbeUsareNomeEIndiceNegliArray;
begin
  FVariables.IntValArray['arr', 3] := 33;
  FVariables.FloatValArray['arr', 4] := 4.5;
  FVariables.StrValArray['arr', 5] := 'five';
  Assert.AreEqual(33, FVariables.IntVal['ARR[3]']);
  Assert.AreEqual(33, FVariables.IntValArray['Arr', 3]);
  SameFloat(4.5, FVariables.FloatVal['arr[4]']);
  Assert.AreEqual('five', FVariables.StrVal['ARR[5]']);
  Assert.AreEqual(0, FVariables.IntValArray['arr', 2]);
  FVariables.IntValArray['arr', -1] := 1;
  Assert.AreEqual(1, FVariables.IntVal['ARR[-1]']);
end;

procedure TTestScriptHostVariables.DovrebbeDareLaPosizioneEAggiornareSeIlNomeEsiste;
begin
  Assert.AreEqual(0, FVariables.AddString('a', 'x'));
  Assert.AreEqual(1, FVariables.AddString('b', 'y'));
  Assert.AreEqual(0, FVariables.AddString('A', 'z'));
  Assert.AreEqual(2, FVariables.StringCount);
  Assert.AreEqual('z', FVariables.StrVal['a']);
  Assert.AreEqual(0, FVariables.AddInteger('n', 1));
  Assert.AreEqual(0, FVariables.AddInteger('N', 2));
  Assert.AreEqual(2, FVariables.IntVal['n']);
  Assert.AreEqual(0, FVariables.AddFloat('f', 1));
  Assert.AreEqual(1, FVariables.AddFloat('g', 2));
  Assert.AreEqual(2, FVariables.FloatCount);
end;

procedure TTestScriptHostVariables.DovrebbeCercareConIlNomeEsattoInHas;
begin
  FVariables.StrVal['abc'] := 'x';
  FVariables.IntVal['abc'] := 1;
  FVariables.FloatVal['abc'] := 1;
  // the names are in upper case in the lists: the consoles command look them up as typed
  Assert.IsTrue(FVariables.HasString('ABC'));
  Assert.IsFalse(FVariables.HasString('abc'));
  Assert.IsTrue(FVariables.HasInteger('ABC'));
  Assert.IsTrue(FVariables.HasFloat('ABC'));
  Assert.IsFalse(FVariables.HasFloat('ABD'));
end;

procedure TTestScriptHostVariables.DovrebbeSvuotareConClear;
begin
  FVariables.IntVal['A'] := 1;
  FVariables.StrVal['B'] := 'b';
  FVariables.FloatVal['C'] := 1;
  FVariables.Clear;
  Assert.AreEqual(0, FVariables.IntVal['A']);
  Assert.AreEqual('', FVariables.StrVal['B']);
  Assert.AreEqual(0, FVariables.IntegerCount + FVariables.StringCount + FVariables.FloatCount);
  // and they can be created again
  FVariables.IntVal['A'] := 2;
  Assert.AreEqual(2, FVariables.IntVal['A']);
end;

procedure TTestScriptHostVariables.DovrebbeTrovareMigliaiaDiNomiAnchePerLeCollisioni;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 9999 do
    FVariables.IntValArray['var', LIndex] := LIndex * 3;
  Assert.AreEqual(10000, FVariables.IntegerCount);
  // more names than chains (8192): some chains have more than one name
  for LIndex := 9999 downto 0 do
    Assert.AreEqual(LIndex * 3, FVariables.IntValArray['VAR', LIndex]);
  Assert.AreEqual(0, FVariables.IntValArray['var', 10000]);
end;

procedure TTestScriptHostVariables.DovrebbeScrivereIByteDelSalvataggioComeIlVecchioCodice;
var
  LExpected: TBytes;
  LActual: TBytes;
begin
  FVariables.StrVal['ab'] := 'XY';
  FVariables.IntVal['n'] := 7;
  FVariables.FloatVal['f'] := 1.5;
  // the format of the savegames: counts and integers of 4 bytes, strings with the length and
  // 2 bytes (UTF-16) for each character, floats of 4 bytes: strings, integers, floats
  LExpected := BytesOf([
    1, 0, 0, 0,
    2, 0, 0, 0, $41, 0, $42, 0,
    2, 0, 0, 0, $58, 0, $59, 0,
    1, 0, 0, 0,
    1, 0, 0, 0, $4E, 0,
    7, 0, 0, 0,
    1, 0, 0, 0,
    1, 0, 0, 0, $46, 0,
    0, 0, $C0, $3F]);
  Assert.AreEqual(Length(LExpected), FVariables.StructureSize);
  Assert.AreEqual(Length(LExpected), Length(Saved(FVariables)));
  LActual := Saved(FVariables);
  Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected)));
end;

procedure TTestScriptHostVariables.DovrebbeScrivereUnaListaVuotaConTreContatori;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  Assert.AreEqual(12, FVariables.StructureSize);
  LBytes := Saved(FVariables);
  for LIndex := 0 to High(LBytes) do
    Assert.AreEqual(0, Integer(LBytes[LIndex]));
end;

procedure TTestScriptHostVariables.DovrebbeDareUnaStructureSizeUgualeAiByteScritti;
var
  LIndex: Integer;
  LBuffer: TBytes;
begin
  // the defect fixed in the old class: the size counted the characters as bytes
  FVariables.StrVal['name'] := 'value';
  Assert.AreEqual(12 + (4 + 8) + (4 + 10), FVariables.StructureSize);
  for LIndex := 0 to 40 do
  begin
    FVariables.StrValArray['s', LIndex] := StringOfChar('x', LIndex);
    FVariables.IntValArray['i', LIndex] := LIndex;
    FVariables.FloatValArray['f', LIndex] := LIndex / 2;
    SetLength(LBuffer, FVariables.StructureSize + 16);
    Assert.AreEqual(FVariables.StructureSize, FVariables.SaveToBuffer(@LBuffer[0]));
  end;
end;

procedure TTestScriptHostVariables.DovrebbeNonScrivereOltreStructureSize;
var
  LBuffer: TBytes;
  LSize: Integer;
  LIndex: Integer;
begin
  FVariables.StrVal['a'] := 'abc';
  FVariables.IntVal['b'] := 1;
  FVariables.FloatVal['c'] := 2;
  LSize := FVariables.StructureSize;
  SetLength(LBuffer, LSize + 8);
  FillChar(LBuffer[0], Length(LBuffer), $AA);
  FVariables.SaveToBuffer(@LBuffer[0]);
  for LIndex := LSize to LSize + 7 do
    Assert.AreEqual(Integer($AA), Integer(LBuffer[LIndex]));
end;

procedure TTestScriptHostVariables.DovrebbeRileggereCiOCheHaScritto;
var
  LOther: IScriptVariables;
  LBytes: TBytes;
begin
  FVariables.StrVal['title'] := 'Hello';
  FVariables.StrVal['empty'] := '';
  FVariables.IntVal['count'] := -123456;
  FVariables.IntVal['big'] := MaxInt;
  FVariables.FloatVal['ratio'] := 0.25;
  FVariables.FloatVal['neg'] := -1e10;
  LBytes := Saved(FVariables);
  LOther := NewVariables;
  Assert.AreEqual(Length(LBytes), LOther.LoadFromBuffer(@LBytes[0]));
  Assert.AreEqual('Hello', LOther.StrVal['title']);
  Assert.IsTrue(LOther.HasString('EMPTY'));
  Assert.AreEqual('', LOther.StrVal['empty']);
  Assert.AreEqual(-123456, LOther.IntVal['count']);
  Assert.AreEqual(MaxInt, LOther.IntVal['big']);
  SameFloat(0.25, LOther.FloatVal['ratio']);
  SameFloat(-1e10, LOther.FloatVal['neg']);
  Assert.AreEqual(2, LOther.StringCount);
  Assert.AreEqual(2, LOther.IntegerCount);
  Assert.AreEqual(2, LOther.FloatCount);
end;

procedure TTestScriptHostVariables.DovrebbeRileggereNomiNonAsciiELunghi;
var
  LOther: IScriptVariables;
  LBytes: TBytes;
  LLongName: string;
  LText: string;
begin
  LLongName := StringOfChar('N', 300);
  LText := 'caff' + #$00E8 + ' ' + #$20AC + ' ' + #$D83D + #$DE00;
  FVariables.StrVal[#$00C0#$00C8#$00CC] := LText;
  FVariables.IntVal[LLongName] := 99;
  LBytes := Saved(FVariables);
  LOther := NewVariables;
  LOther.LoadFromBuffer(@LBytes[0]);
  Assert.AreEqual(LText, LOther.StrVal[#$00C0#$00C8#$00CC]);
  Assert.AreEqual(99, LOther.IntVal[LLongName]);
  Assert.AreEqual(Length(LBytes), LOther.StructureSize);
end;

procedure TTestScriptHostVariables.DovrebbeSostituireLeVariabiliCheCeranoNelCaricamento;
var
  LOther: IScriptVariables;
  LBytes: TBytes;
begin
  FVariables.IntVal['new'] := 1;
  LBytes := Saved(FVariables);
  LOther := NewVariables;
  LOther.IntVal['old'] := 2;
  LOther.StrVal['older'] := 'x';
  LOther.LoadFromBuffer(@LBytes[0]);
  Assert.AreEqual(1, LOther.IntegerCount);
  Assert.AreEqual(0, LOther.StringCount);
  Assert.AreEqual(0, LOther.IntVal['old']);
  Assert.AreEqual(1, LOther.IntVal['new']);
end;

procedure TTestScriptHostVariables.DovrebbeDareIByteLettiDalCaricamento;
var
  LBytes: TBytes;
begin
  FVariables.StrVal['a'] := 'bb';
  LBytes := Saved(FVariables);
  // more bytes after the data: the load reads only the data
  SetLength(LBytes, Length(LBytes) + 5);
  Assert.AreEqual(FVariables.StructureSize, FVariables.LoadFromBuffer(@LBytes[0]));
end;

procedure TTestScriptHostVariables.DovrebbeDareErroreSeIlBufferFinisceTroppoPresto;
var
  LBytes: TBytes;
begin
  FVariables.StrVal['name'] := 'value';
  FVariables.IntVal['n'] := 1;
  LBytes := Saved(FVariables);
  Assert.WillRaise(
    procedure
    begin
      FVariables.LoadFromBufferBounded(@LBytes[0], Length(LBytes) - 1);
    end, EScriptVariablesException);
  Assert.WillRaise(
    procedure
    begin
      FVariables.LoadFromBufferBounded(@LBytes[0], 2);
    end, EScriptVariablesException);
  // a string that says it is longer than the buffer
  LBytes := BytesOf([1, 0, 0, 0, $FF, $FF, $FF, $7F, 0, 0]);
  Assert.WillRaise(
    procedure
    begin
      FVariables.LoadFromBufferBounded(@LBytes[0], Length(LBytes));
    end, EScriptVariablesException);
end;

procedure TTestScriptHostVariables.DovrebbeDareErroreSeUnContatoreONegativo;
var
  LBytes: TBytes;
begin
  LBytes := BytesOf([$FF, $FF, $FF, $FF, 0, 0, 0, 0, 0, 0, 0, 0]);
  Assert.WillRaise(
    procedure
    begin
      FVariables.LoadFromBufferBounded(@LBytes[0], Length(LBytes));
    end, EScriptVariablesException);
  // a string with a negative length
  LBytes := BytesOf([1, 0, 0, 0, $FF, $FF, $FF, $FF, 0, 0, 0, 0, 0, 0, 0, 0]);
  Assert.WillRaise(
    procedure
    begin
      FVariables.LoadFromBufferBounded(@LBytes[0], Length(LBytes));
    end, EScriptVariablesException);
end;

procedure TTestScriptHostVariables.DovrebbeScrivereUnFileConLaLunghezzaEIDati;
var
  LFile: TBytes;
  LData: TBytes;
begin
  FVariables.IntVal['n'] := 7;
  FVariables.SaveToFile('world.dat');
  Assert.AreEqual(1, FFiles.Writes);
  LFile := FFiles.Files['world.dat'];
  LData := Saved(FVariables);
  Assert.AreEqual(Length(LData) + 4, Length(LFile));
  Assert.AreEqual(Length(LData), Integer(PInteger(@LFile[0])^));
  Assert.IsTrue(CompareMem(@LData[0], @LFile[4], Length(LData)));
end;

procedure TTestScriptHostVariables.DovrebbeRileggereUnFile;
var
  LOther: IScriptVariables;
begin
  FVariables.StrVal['s'] := 'text';
  FVariables.FloatVal['f'] := 3.5;
  FVariables.SaveToFile('world.dat');
  LOther := NewVariables;
  LOther.LoadFromFile('world.dat');
  Assert.AreEqual('text', LOther.StrVal['s']);
  SameFloat(3.5, LOther.FloatVal['f']);
  Assert.AreEqual(0, FFailure.Messages.Count);
end;

procedure TTestScriptHostVariables.DovrebbeSegnalareUnFileTroppoCorto;
begin
  FFiles.Files.Add('short.dat', BytesOf([1, 2]));
  Assert.WillRaise(
    procedure
    begin
      FVariables.LoadFromFile('short.dat');
    end, EScriptVariablesException);
  Assert.AreEqual(1, FFailure.Messages.Count);
  Assert.IsTrue(Pos('short.dat', FFailure.Messages[0]) > 0);
end;

procedure TTestScriptHostVariables.DovrebbeSegnalareUnFileConLunghezzaSbagliata;
var
  LFile: TBytes;
begin
  FVariables.IntVal['n'] := 7;
  FVariables.SaveToFile('world.dat');
  // bytes after the data
  LFile := FFiles.Files['world.dat'];
  SetLength(LFile, Length(LFile) + 4);
  FFiles.Files.AddOrSetValue('long.dat', LFile);
  Assert.WillRaise(
    procedure
    begin
      NewVariables.LoadFromFile('long.dat');
    end, EScriptVariablesException);
  Assert.AreEqual(1, FFailure.Messages.Count);
  Assert.IsTrue(Pos('long.dat', FFailure.Messages[0]) > 0);
end;

procedure TTestScriptHostVariables.DovrebbeSegnalareUnFileTroncato;
var
  LFile: TBytes;
begin
  FVariables.StrVal['name'] := 'value';
  FVariables.SaveToFile('world.dat');
  LFile := Copy(FFiles.Files['world.dat'], 0, 14);
  FFiles.Files.AddOrSetValue('cut.dat', LFile);
  Assert.WillRaise(
    procedure
    begin
      NewVariables.LoadFromFile('cut.dat');
    end, EScriptVariablesException);
  Assert.AreEqual(1, FFailure.Messages.Count);
end;

procedure TTestScriptHostVariables.DovrebbeDareErroreSeIServiziSononil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateVariables(nil, FFailureRef);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateVariables(FFilesRef, nil);
    end, EArgumentNilException);
end;

end.
