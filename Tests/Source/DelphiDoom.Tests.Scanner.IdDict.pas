{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - TIdDict, TIdLangDict and         }
{  TIdCNumbers                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.IdDict;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Scanner.IdDict,
  DelphiDoom.Scanner.IdLangDict, DelphiDoom.Tests.Scanner.IdFakes;

type
  [TestFixture]
  [Category('IdDict')]
  TTestIdDict = class
  strict private
    FLog: TFakeIdLibLog;
    FLogIntf: IIdLibLog;
    FDict: TIdDict;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleNelleChiavi;
    [Test]
    procedure DovrebbeTenereLaMaiuscolaDellaPrimaChiaveEL_OrdineDiInserimento;
    [Test]
    procedure DovrebbeIgnorareUnaChiaveVuotaEAvvisareNellaRicerca;
    [Test]
    procedure DovrebbeDareIValoriPredefinitiESePresentiLaChiave;
    [Test]
    procedure DovrebbeLeggereNumeriBooleaniEVettori;
    [Test]
    procedure DovrebbeScrivereNumeriBooleaniEVettori;
    [Test]
    procedure DovrebbeCancellareMantenendoLOrdine;
    [Test]
    procedure DovrebbeCopiareAssegnareETrasferire;
    [Test]
    procedure DovrebbeAggiungereIDefaultSoloSeMancano;
    [Test]
    procedure DovrebbeCercareUnPrefissoDopoUnAltraCorrispondenza;
    [Test]
    procedure DovrebbeScegliereAlCasoUnValoreConPrefisso;
    [Test]
    procedure DovrebbeDareLaStessaSommaConUnAltroOrdine;
    [Test]
    procedure DovrebbeFareIlGiroDaByte;
    [Test]
    procedure DovrebbeRifiutareUnaStringaTroppoLungaEUnFlussoTroncato;
    [Test]
    procedure DovrebbeLeggereUnBloccoDaUnaSorgenteDiToken;
    [Test]
    procedure DovrebbeSegnalareUnaChiaveRipetutaNelBlocco;
    [Test]
    procedure DovrebbeStampareLeCoppie;
    [Test]
    procedure DovrebbeDareFalsoPerUnIndiceFuoriIntervallo;
  end;

  [TestFixture]
  [Category('IdDict')]
  TTestIdLangDict = class
  strict private
    FLog: TFakeIdLibLog;
    FLogIntf: IIdLibLog;
    FFileSystem: TFakeIdLibFileSystem;
    FFileSystemIntf: IIdLibFileSystem;
    FLang: TIdLangDict;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareUnFileDiStringhe;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileMancaOEVuoto;
    [Test]
    procedure DovrebbeAggiungereALCaricamentoSeNonSiPulisce;
    [Test]
    procedure DovrebbeDareLUltimaStringaConLoStessoId;
    [Test]
    procedure DovrebbeGenerareUnaChiaveNuovaEPoiRiusarla;
    [Test]
    procedure DovrebbeEscludereLeStringheDaNonTradurre;
    [Test]
    procedure DovrebbePartireDallIdDiBase;
    [Test]
    procedure DovrebbeScrivereIlFile;
    [Test]
    procedure DovrebbeSollevareSeNonPuoScrivere;
    [Test]
    procedure DovrebbeAggiungereUnaCoppiaCosiCom;
  end;

  [TestFixture]
  [Category('IdDict')]
  TTestIdCNumbers = class
  public
    [Test]
    [TestCase('semplice', '42,42')]
    [TestCase('con segno', '-17abc,-17')]
    [TestCase('spazi', '  +8,8')]
    [TestCase('senza cifre', 'abc,0')]
    [TestCase('saturato alto', '99999999999,2147483647')]
    [TestCase('saturato basso', '-99999999999,-2147483648')]
    procedure DovrebbeLeggereUnIntero(const AText: string; const AExpected: Integer);
    [Test]
    [TestCase('semplice', '2.5,2.5')]
    [TestCase('esponente', '1e3x,1000')]
    [TestCase('esponente senza cifre', '1e,1')]
    [TestCase('solo punto', '.5,0.5')]
    [TestCase('senza cifre', '-.,0')]
    [TestCase('con segno', '-3.25,-3.25')]
    procedure DovrebbeLeggereUnReale(const AText: string; const AExpected: Double);
    [Test]
    procedure DovrebbeLeggereFinoAlPrimoErrore;
    [Test]
    procedure DovrebbeLeggereTreNumeriConLeVirgoleDelleEsponenti;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.IdLib.Math.Vec2, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.IdLib.Math.Random, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Scanner.IdParser,
  DelphiDoom.Scanner.IdParser.Intf;

{ TTestIdDict }

procedure TTestIdDict.Setup;
begin
  FLog := TFakeIdLibLog.Create;
  FLogIntf := FLog;
  FDict := TIdDict.Create(FLogIntf);
end;

procedure TTestIdDict.TearDown;
begin
  FDict.Free;
  FLogIntf := nil;
end;

procedure TTestIdDict.DovrebbeIgnorareLeMaiuscoleNelleChiavi;
begin
  FDict.SetValue('Alpha', '1');
  Assert.AreEqual('1', string(FDict.GetString('ALPHA')));
  FDict.SetValue('aLPHA', '2');
  Assert.AreEqual(1, FDict.GetNumKeyVals);
  Assert.AreEqual('2', string(FDict.GetString('alpha')));
end;

procedure TTestIdDict.DovrebbeTenereLaMaiuscolaDellaPrimaChiaveEL_OrdineDiInserimento;
var
  LKeyValue: TIdKeyValue;
begin
  FDict.SetValue('Zeta', '1');
  FDict.SetValue('alpha', '2');
  FDict.SetValue('ZETA', '3');
  Assert.IsTrue(FDict.TryGetKeyVal(0, LKeyValue));
  Assert.AreEqual('Zeta', string(LKeyValue.Key));
  Assert.AreEqual('3', string(LKeyValue.Value));
  Assert.IsTrue(FDict.TryGetKeyVal(1, LKeyValue));
  Assert.AreEqual('alpha', string(LKeyValue.Key));
end;

procedure TTestIdDict.DovrebbeIgnorareUnaChiaveVuotaEAvvisareNellaRicerca;
var
  LKeyValue: TIdKeyValue;
begin
  FDict.SetValue('', 'x');
  Assert.AreEqual(0, FDict.GetNumKeyVals);
  Assert.IsFalse(FDict.FindKey('', LKeyValue));
  Assert.IsTrue(FLog.Lines.Count > 0);
  // the original returns NULL (0) for an empty key in FindKeyIndex
  Assert.AreEqual(0, FDict.FindKeyIndex(''));
end;

procedure TTestIdDict.DovrebbeDareIValoriPredefinitiESePresentiLaChiave;
var
  LText: AnsiString;
  LInt: Integer;
  LFloat: Single;
  LBool: Boolean;
begin
  FDict.SetValue('k', 'v');
  Assert.AreEqual('def', string(FDict.GetString('zz', 'def')));
  Assert.IsTrue(FDict.GetString('k', 'def', LText));
  Assert.AreEqual('v', string(LText));
  Assert.IsFalse(FDict.GetString('zz', 'def', LText));
  Assert.AreEqual('def', string(LText));
  Assert.IsFalse(FDict.GetInt('zz', '12', LInt));
  Assert.AreEqual(12, LInt);
  Assert.IsFalse(FDict.GetFloat('zz', '1.5', LFloat));
  Assert.AreEqual(Single(1.5), LFloat);
  Assert.IsFalse(FDict.GetBool('zz', '3', LBool));
  Assert.IsTrue(LBool);
  Assert.AreEqual(7, FDict.GetInt('zz', '7'));
  Assert.AreEqual(Single(0), FDict.GetFloat('zz'));
  Assert.IsFalse(FDict.GetBool('zz'));
  Assert.AreEqual('', string(FDict.GetString('zz')));
end;

procedure TTestIdDict.DovrebbeLeggereNumeriBooleaniEVettori;
var
  LVec3: TIdVec3;
  LVec2: TIdVec2;
  LVec4: TIdVec4;
begin
  FDict.SetValue('i', '-12 rest');
  FDict.SetValue('f', '2.25');
  FDict.SetValue('b', '1');
  FDict.SetValue('v3', '1 2 3');
  FDict.SetValue('v3short', '4 5');
  FDict.SetValue('v2', '7 8');
  FDict.SetValue('v4', '1 2 3 4');
  Assert.AreEqual(-12, FDict.GetInt('i'));
  Assert.AreEqual(Single(2.25), FDict.GetFloat('f'));
  Assert.IsTrue(FDict.GetBool('b'));
  LVec3 := FDict.GetVector('v3');
  Assert.AreEqual(Single(3), LVec3.Z);
  LVec3 := FDict.GetVector('v3short');
  Assert.AreEqual(Single(5), LVec3.Y);
  Assert.AreEqual(Single(0), LVec3.Z);
  LVec3 := FDict.GetVector('missing', '9 9 9');
  Assert.AreEqual(Single(9), LVec3.X);
  LVec2 := FDict.GetVec2('v2');
  Assert.AreEqual(Single(8), LVec2.Y);
  LVec2 := FDict.GetVec2('missing');
  Assert.AreEqual(Single(0), LVec2.X);
  LVec4 := FDict.GetVec4('v4');
  Assert.AreEqual(Single(4), LVec4.W);
  LVec4 := FDict.GetVec4('missing');
  Assert.AreEqual(Single(0), LVec4.W);
  Assert.IsFalse(FDict.GetVector('missing', '', LVec3));
  Assert.IsTrue(FDict.GetVector('v3', '', LVec3));
  Assert.IsTrue(FDict.GetVec2('v2', '', LVec2));
  Assert.IsTrue(FDict.GetVec4('v4', '', LVec4));
  Assert.IsFalse(FDict.GetVec4('x', '1 1 1 1', LVec4));
  Assert.AreEqual(Single(1), LVec4.Z);
end;

procedure TTestIdDict.DovrebbeScrivereNumeriBooleaniEVettori;
begin
  FDict.SetInt('i', -3);
  FDict.SetBool('b', True);
  FDict.SetFloat('f', 0.5);
  FDict.SetVector('v3', TIdVec3.Create(1, 2.5, 3));
  FDict.SetVec2('v2', TIdVec2.Create(1, 2));
  FDict.SetVec4('v4', TIdVec4.Create(1, 2, 3, 4));
  Assert.AreEqual('-3', string(FDict.GetString('i')));
  Assert.AreEqual('1', string(FDict.GetString('b')));
  Assert.AreEqual('0.500000', string(FDict.GetString('f')));
  Assert.AreEqual('1 2.5 3', string(FDict.GetString('v3')));
  Assert.AreEqual('1 2', string(FDict.GetString('v2')));
  Assert.AreEqual('1 2 3 4', string(FDict.GetString('v4')));
end;

procedure TTestIdDict.DovrebbeCancellareMantenendoLOrdine;
var
  LKeyValue: TIdKeyValue;
begin
  FDict.SetValue('a', '1');
  FDict.SetValue('b', '2');
  FDict.SetValue('c', '3');
  FDict.Delete('B');
  FDict.Delete('zzz');
  Assert.AreEqual(2, FDict.GetNumKeyVals);
  FDict.TryGetKeyVal(1, LKeyValue);
  Assert.AreEqual('c', string(LKeyValue.Key));
  Assert.AreEqual(-1, FDict.FindKeyIndex('b'));
  Assert.AreEqual(1, FDict.FindKeyIndex('C'));
end;

procedure TTestIdDict.DovrebbeCopiareAssegnareETrasferire;
var
  LOther: TIdDict;
begin
  FDict.SetValue('a', '1');
  FDict.SetValue('b', '2');
  LOther := TIdDict.Create(FLogIntf);
  try
    LOther.SetValue('A', 'x');
    LOther.SetValue('z', 'z');
    LOther.Copy(FDict);
    Assert.AreEqual(3, LOther.GetNumKeyVals);
    Assert.AreEqual('1', string(LOther.GetString('a')));
    LOther.Copy(LOther);
    Assert.AreEqual(3, LOther.GetNumKeyVals);
    LOther.Assign(FDict);
    Assert.AreEqual(2, LOther.GetNumKeyVals);
    LOther.Assign(LOther);
    Assert.AreEqual(2, LOther.GetNumKeyVals);
    LOther.SetValue('only', 'o');
    FDict.TransferKeyValues(LOther);
    Assert.AreEqual(3, FDict.GetNumKeyVals);
    Assert.AreEqual(0, LOther.GetNumKeyVals);
    FDict.TransferKeyValues(FDict);
    Assert.AreEqual(3, FDict.GetNumKeyVals);
    FDict.Clear;
    Assert.AreEqual(0, FDict.GetNumKeyVals);
  finally
    LOther.Free;
  end;
end;

procedure TTestIdDict.DovrebbeAggiungereIDefaultSoloSeMancano;
var
  LDefaults: TIdDict;
begin
  LDefaults := TIdDict.Create(FLogIntf);
  try
    LDefaults.SetValue('a', 'default');
    LDefaults.SetValue('b', 'default');
    FDict.SetValue('A', 'mine');
    FDict.SetDefaults(LDefaults);
    Assert.AreEqual(2, FDict.GetNumKeyVals);
    Assert.AreEqual('mine', string(FDict.GetString('a')));
    Assert.AreEqual('default', string(FDict.GetString('b')));
  finally
    LDefaults.Free;
  end;
end;

procedure TTestIdDict.DovrebbeCercareUnPrefissoDopoUnAltraCorrispondenza;
var
  LFirst: Integer;
begin
  FDict.SetValue('x', '0');
  FDict.SetValue('Item_1', '1');
  FDict.SetValue('y', '0');
  FDict.SetValue('item_2', '2');
  LFirst := FDict.MatchPrefix('ITEM_');
  Assert.AreEqual(1, LFirst);
  Assert.AreEqual(3, FDict.MatchPrefix('item_', LFirst));
  Assert.AreEqual(-1, FDict.MatchPrefix('item_', 3));
  Assert.AreEqual(-1, FDict.MatchPrefix('none'));
  // a match at index 0 searches from the start, as the original does
  FDict.SetValue('item_0', '0');
  Assert.AreEqual(1, FDict.MatchPrefix('item_', 0));
end;

procedure TTestIdDict.DovrebbeScegliereAlCasoUnValoreConPrefisso;
var
  LRandom, LCopy: TIdRandom;
  LExpected: Integer;
begin
  FDict.SetValue('m_a', 'A');
  FDict.SetValue('m_b', 'B');
  FDict.SetValue('m_c', 'C');
  LRandom := TIdRandom.Create(5);
  LCopy := TIdRandom.Create(5);
  LExpected := LCopy.RandomInt(3);
  Assert.AreEqual(string(AnsiString(Chr(Ord('A') + LExpected))), string(FDict.RandomPrefix('m_', LRandom)));
  Assert.AreEqual('', string(FDict.RandomPrefix('none', LRandom)));
end;

procedure TTestIdDict.DovrebbeDareLaStessaSommaConUnAltroOrdine;
var
  LOther: TIdDict;
begin
  LOther := TIdDict.Create;
  try
    FDict.SetValue('a', '1');
    FDict.SetValue('b', '2');
    LOther.SetValue('b', '2');
    LOther.SetValue('a', '1');
    Assert.AreEqual(FDict.Checksum, LOther.Checksum);
    LOther.SetValue('a', '9');
    Assert.AreNotEqual(FDict.Checksum, LOther.Checksum);
    FDict.Clear;
    Assert.AreEqual(Integer(0), FDict.Checksum);
  finally
    LOther.Free;
  end;
end;

procedure TTestIdDict.DovrebbeFareIlGiroDaByte;
var
  LBytes: TBytes;
  LPosition: Integer;
  LOther: TIdDict;
begin
  FDict.SetValue('Name', 'Imp');
  FDict.SetValue('empty', '');
  LBytes := FDict.WriteToBytes;
  Assert.AreEqual(4 + 5 + 4 + 6 + 1, Length(LBytes));
  Assert.AreEqual(Byte(2), LBytes[0]);
  LOther := TIdDict.Create;
  try
    LOther.SetValue('junk', 'x');
    LPosition := 0;
    LOther.ReadFromBytes(LBytes, LPosition);
    Assert.AreEqual(Length(LBytes), LPosition);
    Assert.AreEqual(2, LOther.GetNumKeyVals);
    Assert.AreEqual('Imp', string(LOther.GetString('name')));
    Assert.AreEqual(FDict.Checksum, LOther.Checksum);
  finally
    LOther.Free;
  end;
end;

procedure TTestIdDict.DovrebbeRifiutareUnaStringaTroppoLungaEUnFlussoTroncato;
var
  LBytes: TBytes;
  LPosition: Integer;
begin
  FDict.SetValue('k', StringOfChar('x', 1100));
  Assert.WillRaise(
    procedure
    begin
      FDict.WriteToBytes;
    end, EIdLibException);
  FDict.Clear;
  FDict.SetValue('k', 'v');
  LBytes := FDict.WriteToBytes;
  SetLength(LBytes, Length(LBytes) - 1);
  Assert.WillRaise(
    procedure
    var
      LIndex: Integer;
    begin
      LIndex := 0;
      FDict.ReadFromBytes(LBytes, LIndex);
    end, EIdLibException);
  SetLength(LBytes, 2);
  Assert.WillRaise(
    procedure
    var
      LIndex: Integer;
    begin
      LIndex := 0;
      FDict.ReadFromBytes(LBytes, LIndex);
    end, EIdLibException);
  SetLength(LBytes, 4 + 1100);
  FillChar(LBytes[0], Length(LBytes), 65);
  LBytes[0] := 1;
  LBytes[1] := 0;
  LBytes[2] := 0;
  LBytes[3] := 0;
  LPosition := 0;
  Assert.WillRaise(
    procedure
    var
      LIndex: Integer;
    begin
      LIndex := 0;
      FDict.ReadFromBytes(LBytes, LIndex);
    end, EIdLibException);
  Assert.AreEqual(0, LPosition);
end;

procedure TTestIdDict.DovrebbeLeggereUnBloccoDaUnaSorgenteDiToken;
var
  LParser: TIdParser;
begin
  LParser := TIdParser.Create(LEXFL_NOSTRINGCONCAT, FLogIntf);
  try
    LParser.LoadMemory('{ "a" "1" "b" "2" }', 'dict');
    Assert.IsTrue(FDict.Parse(LParser));
    Assert.AreEqual(2, FDict.GetNumKeyVals);
    Assert.AreEqual('2', string(FDict.GetString('b')));
  finally
    LParser.Free;
  end;
end;

procedure TTestIdDict.DovrebbeSegnalareUnaChiaveRipetutaNelBlocco;
var
  LParser: TIdParser;
begin
  LParser := TIdParser.Create(LEXFL_NOSTRINGCONCAT, FLogIntf);
  try
    LParser.LoadMemory('{ "a" "1" "A" "2" }', 'dict');
    Assert.IsFalse(FDict.Parse(LParser));
    Assert.AreEqual('2', string(FDict.GetString('a')));
    Assert.AreEqual('W: file dict, line 1: ''A'' already defined', FLog.Lines[0]);
  finally
    LParser.Free;
  end;
end;

procedure TTestIdDict.DovrebbeStampareLeCoppie;
begin
  FDict.SetValue('a', '1');
  FDict.SetValue('b', 'two');
  FDict.Print;
  Assert.AreEqual('P: a = 1\n', FLog.Lines[0]);
  Assert.AreEqual('P: b = two\n', FLog.Lines[1]);
  // without a log it is silent
  FDict.Free;
  FDict := TIdDict.Create;
  FDict.SetValue('a', '1');
  FDict.Print;
  Assert.AreEqual(2, FLog.Lines.Count);
end;

procedure TTestIdDict.DovrebbeDareFalsoPerUnIndiceFuoriIntervallo;
var
  LKeyValue: TIdKeyValue;
begin
  FDict.SetValue('a', '1');
  Assert.IsFalse(FDict.TryGetKeyVal(1, LKeyValue));
  Assert.IsFalse(FDict.TryGetKeyVal(-1, LKeyValue));
  Assert.AreEqual('', string(LKeyValue.Key));
end;

{ TTestIdLangDict }

procedure TTestIdLangDict.Setup;
begin
  FLog := TFakeIdLibLog.Create;
  FLogIntf := FLog;
  FFileSystem := TFakeIdLibFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FLang := TIdLangDict.Create(FLogIntf, FFileSystemIntf);
end;

procedure TTestIdLangDict.TearDown;
begin
  FLang.Free;
  FFileSystemIntf := nil;
  FLogIntf := nil;
end;

procedure TTestIdLangDict.DovrebbeCaricareUnFileDiStringhe;
begin
  FFileSystem.Add('en.lang', '// table'#10'{'#10#9'"#str_00001"'#9'"One"'#10#9'"#str_00002"'#9'"Two\tTab"'#10'}'#10);
  Assert.IsTrue(FLang.Load('en.lang'));
  Assert.AreEqual(2, FLang.GetNumKeyVals);
  Assert.AreEqual('One', string(FLang.GetString('#str_00001')));
  Assert.AreEqual('Two'#9'Tab', string(FLang.GetString('#str_00002')));
  Assert.AreEqual('P: 2 strings read from en.lang\n', FLog.Lines[0]);
end;

procedure TTestIdLangDict.DovrebbeDareFalsoSeIlFileMancaOEVuoto;
var
  LEmpty: TIdLangDict;
begin
  Assert.IsFalse(FLang.Load('nofile.lang'));
  FFileSystem.Add('empty.lang', '');
  Assert.IsFalse(FLang.Load('empty.lang'));
  LEmpty := TIdLangDict.Create;
  try
    Assert.IsFalse(LEmpty.Load('x'));
  finally
    LEmpty.Free;
  end;
end;

procedure TTestIdLangDict.DovrebbeAggiungereALCaricamentoSeNonSiPulisce;
begin
  FFileSystem.Add('a.lang', '{ "#str_00001" "A" }');
  FFileSystem.Add('b.lang', '{ "#str_00002" "B" }');
  FLang.Load('a.lang');
  FLang.Load('b.lang', False);
  Assert.AreEqual(2, FLang.GetNumKeyVals);
  FLang.Load('b.lang', True);
  Assert.AreEqual(1, FLang.GetNumKeyVals);
end;

procedure TTestIdLangDict.DovrebbeDareLUltimaStringaConLoStessoId;
begin
  FLang.AddKeyVal('#str_00001', 'first');
  FLang.AddKeyVal('#str_00001', 'second');
  Assert.AreEqual('second', string(FLang.GetString('#str_00001')));
  Assert.AreEqual('plain', string(FLang.GetString('plain')));
  Assert.AreEqual('', string(FLang.GetString('')));
  Assert.AreEqual('#str_77', string(FLang.GetString('#str_77')));
  Assert.AreEqual('W: Unknown string id #str_77', FLog.Lines[0]);
end;

procedure TTestIdLangDict.DovrebbeGenerareUnaChiaveNuovaEPoiRiusarla;
begin
  Assert.AreEqual('#str_00000000', string(FLang.AddString('Hello')));
  Assert.AreEqual('#str_00000000', string(FLang.AddString('Hello')));
  Assert.AreEqual('#str_00000001', string(FLang.AddString('World')));
  Assert.AreEqual(2, FLang.GetNumKeyVals);
end;

procedure TTestIdLangDict.DovrebbeEscludereLeStringheDaNonTradurre;
begin
  Assert.AreEqual('x', string(FLang.AddString('x')));
  Assert.AreEqual('', string(FLang.AddString('')));
  Assert.AreEqual('#str_5', string(FLang.AddString('#str_5')));
  Assert.AreEqual('GUI::a', string(FLang.AddString('GUI::a')));
  Assert.AreEqual('$var', string(FLang.AddString('$var')));
  Assert.AreEqual('123 456', string(FLang.AddString('123 456')));
  Assert.AreEqual(0, FLang.GetNumKeyVals);
end;

procedure TTestIdLangDict.DovrebbePartireDallIdDiBase;
begin
  FLang.BaseId := 100;
  Assert.AreEqual('#str_00000100', string(FLang.AddString('Base')));
  Assert.AreEqual('#str_00000101', string(FLang.AddString('Next')));
  Assert.AreEqual(100, FLang.BaseId);
end;

procedure TTestIdLangDict.DovrebbeScrivereIlFile;
begin
  FLang.AddKeyVal('#str_00001', 'tab'#9'nl'#13#10'q');
  FLang.Save('out.lang');
  Assert.AreEqual('// string table'#10'// english'#10'//'#10#10'{'#10#9'"#str_00001"'#9'"tab\tnl\n\nq"'#10#10'}'#10,
    string(FFileSystem.Content('out.lang')));
end;

procedure TTestIdLangDict.DovrebbeSollevareSeNonPuoScrivere;
var
  LNoFileSystem: TIdLangDict;
begin
  LNoFileSystem := TIdLangDict.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LNoFileSystem.Save('x');
      end, EIdLibException);
  finally
    LNoFileSystem.Free;
  end;
end;

procedure TTestIdLangDict.DovrebbeAggiungereUnaCoppiaCosiCom;
var
  LKeyValue: TIdKeyValue;
begin
  FLang.AddKeyVal('free key', 'free value');
  Assert.IsTrue(FLang.TryGetKeyVal(0, LKeyValue));
  Assert.AreEqual('free key', string(LKeyValue.Key));
  Assert.IsFalse(FLang.TryGetKeyVal(1, LKeyValue));
  Assert.IsFalse(FLang.TryGetKeyVal(-1, LKeyValue));
  FLang.Clear;
  Assert.AreEqual(0, FLang.GetNumKeyVals);
end;

{ TTestIdCNumbers }

procedure TTestIdCNumbers.DovrebbeLeggereUnIntero(const AText: string; const AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TIdCNumbers.Atoi(AnsiString(AText)));
end;

procedure TTestIdCNumbers.DovrebbeLeggereUnReale(const AText: string; const AExpected: Double);
begin
  Assert.AreEqual(AExpected, TIdCNumbers.Atof(AnsiString(AText)), 1E-12);
end;

procedure TTestIdCNumbers.DovrebbeLeggereFinoAlPrimoErrore;
var
  LValues: array[0..2] of Single;
begin
  LValues[0] := 9;
  LValues[1] := 9;
  LValues[2] := 9;
  Assert.AreEqual(2, TIdCNumbers.ScanFloats('1.5 -2 abc 4', LValues));
  Assert.AreEqual(Single(1.5), LValues[0]);
  Assert.AreEqual(Single(-2), LValues[1]);
  Assert.AreEqual(Single(9), LValues[2]);
  Assert.AreEqual(0, TIdCNumbers.ScanFloats('', LValues));
  Assert.AreEqual(0, TIdCNumbers.ScanFloats('x', LValues));
  Assert.AreEqual(0, TIdCNumbers.ScanFloats('-', LValues));
end;

procedure TTestIdCNumbers.DovrebbeLeggereTreNumeriConLeVirgoleDelleEsponenti;
var
  LValues: array[0..2] of Single;
begin
  Assert.AreEqual(3, TIdCNumbers.ScanFloats('1e2 2E-1 +3', LValues));
  Assert.AreEqual(Single(100), LValues[0]);
  Assert.AreEqual(Single(0.2), LValues[1]);
  Assert.AreEqual(Single(3), LValues[2]);
end;

end.
