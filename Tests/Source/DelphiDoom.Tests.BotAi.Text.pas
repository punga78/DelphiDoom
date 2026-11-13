{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the string rules, the compressor, the generator and    }
{  the library variables of the bot AI library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Text;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotChatText = class
  public
    [Test]
    procedure DovrebbeRiconoscereLeLettereComeNonSpazi;
    [Test]
    procedure DovrebbeTrattareICaratteriAltiComeSpazi;
    [Test]
    procedure DovrebbeConfrontareSenzaMaiuscole;
    [Test]
    procedure DovrebbeTogliereLeTildiSaltandoIlCarattereDopoOgniTilde;
    [Test]
    procedure DovrebbeConservareIlDifettoDiUnifyWhiteSpacesConSpaziMultipli;
    [Test]
    procedure DovrebbeUnireGliSpaziEToglierliAgliEstremi;
    [Test]
    procedure DovrebbeTrovareUnaStringaConEIndice;
    [Test]
    procedure DovrebbeTrovareUnaParolaSoloSeIntera;
    [Test]
    procedure DovrebbeSostituireLeParoleSenzaRipetereLaSostituzioneGiaPresente;
  end;

  [TestFixture]
  [Category('BotAi')]
  TTestBotScriptCompressor = class
  public
    [Test]
    procedure DovrebbeTogliereICommentiDiRigaEDiBlocco;
    [Test]
    procedure DovrebbeUnireGliSpaziEIFineRiga;
    [Test]
    procedure DovrebbeCopiareLeStringheTraVirgolette;
    [Test]
    procedure DovrebbeFermarsiAlPrimoZero;
    [Test]
    procedure DovrebbeNonScrivereLUltimoFineRiga;
  end;

  [TestFixture]
  [Category('BotAi')]
  TTestBotMsvcRandom = class
  public
    [Test]
    procedure DovrebbeDareLaSequenzaDiRandDelRuntimeMicrosoft;
    [Test]
    procedure DovrebbeDareNumeriTraZeroEUno;
    [Test]
    procedure DovrebbeRipartireDalSeme;
  end;

  [TestFixture]
  [Category('BotAi')]
  TTestBotLibVarTable = class
  public
    [Test]
    procedure DovrebbeCreareLaVariabileConIlPredefinito;
    [Test]
    procedure DovrebbeDareZeroPerUnaVariabileMancante;
    [Test]
    procedure DovrebbeIgnorareLeMaiuscoleNeiNomi;
    [Test]
    procedure DovrebbeCambiareIlValore;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Chat.Text, DelphiDoom.BotAi.Chat.ScriptCompressor,
  DelphiDoom.BotAi.Random.MsvcRand, DelphiDoom.BotAi.LibVars.Table;

{ TTestBotChatText }

procedure TTestBotChatText.DovrebbeRiconoscereLeLettereComeNonSpazi;
begin
  Assert.IsFalse(TBotChatText.IsWhiteSpace('a'));
  Assert.IsFalse(TBotChatText.IsWhiteSpace('7'));
  Assert.IsFalse(TBotChatText.IsWhiteSpace(','));
  Assert.IsFalse(TBotChatText.IsWhiteSpace('_'));
  Assert.IsTrue(TBotChatText.IsWhiteSpace('!'));
  Assert.IsTrue(TBotChatText.IsWhiteSpace(' '));
  Assert.IsTrue(TBotChatText.IsWhiteSpace(';'));
end;

procedure TTestBotChatText.DovrebbeTrattareICaratteriAltiComeSpazi;
begin
  Assert.IsTrue(TBotChatText.IsWhiteSpace(AnsiChar(#200)));
  Assert.AreEqual(-56, TBotChatText.SignedChar(AnsiChar(#200)));
end;

procedure TTestBotChatText.DovrebbeConfrontareSenzaMaiuscole;
begin
  Assert.IsTrue(TBotChatText.SameTextAscii('Hello', 'hELLO'));
  Assert.IsFalse(TBotChatText.SameTextAscii('Hello', 'Hell'));
  Assert.AreEqual('Z', string(TBotChatText.UpperAscii('z')));
  Assert.AreEqual('1', string(TBotChatText.UpperAscii('1')));
end;

procedure TTestBotChatText.DovrebbeTogliereLeTildiSaltandoIlCarattereDopoOgniTilde;
begin
  Assert.AreEqual('ab~c', string(TBotChatText.RemoveTildes('a~b~~c~')));
  Assert.AreEqual('~', string(TBotChatText.RemoveTildes('~~~')));
  Assert.AreEqual('clean', string(TBotChatText.RemoveTildes('clean')));
end;

procedure TTestBotChatText.DovrebbeConservareIlDifettoDiUnifyWhiteSpacesConSpaziMultipli;
begin
  // the second run of spaces is not looked at after the first one is taken out: the original does the same
  Assert.AreEqual('a b  c', string(TBotChatText.UnifyWhiteSpaces('a    b  c')));
  Assert.AreEqual('a b', string(TBotChatText.UnifyWhiteSpaces('a      b')));
end;

procedure TTestBotChatText.DovrebbeUnireGliSpaziEToglierliAgliEstremi;
begin
  Assert.AreEqual('hello world', string(TBotChatText.UnifyWhiteSpaces('  hello   world  ')));
  Assert.AreEqual('', string(TBotChatText.UnifyWhiteSpaces('!!!')));
  Assert.AreEqual('', string(TBotChatText.UnifyWhiteSpaces('')));
  Assert.AreEqual('one', string(TBotChatText.UnifyWhiteSpaces('one')));
end;

procedure TTestBotChatText.DovrebbeTrovareUnaStringaConEIndice;
begin
  Assert.AreEqual(6, TBotChatText.StringContains('hello world', 'world', False));
  Assert.AreEqual(6, TBotChatText.StringContains('Hello World', 'world', False));
  Assert.AreEqual(-1, TBotChatText.StringContains('Hello World', 'world', True));
  Assert.AreEqual(-1, TBotChatText.StringContains('short', 'longer string', False));
  Assert.AreEqual(0, TBotChatText.StringContains('abc', '', False));
end;

procedure TTestBotChatText.DovrebbeTrovareUnaParolaSoloSeIntera;
begin
  Assert.AreEqual(5, TBotChatText.StringContainsWord('well hello there', 'hello', False));
  Assert.AreEqual(-1, TBotChatText.StringContainsWord('hellothere', 'hello', False));
  Assert.AreEqual(4, TBotChatText.StringContainsWord('say hello!', 'hello', True));
  Assert.AreEqual(7, TBotChatText.StringContainsWord('helloo hello', 'hello', False));
end;

procedure TTestBotChatText.DovrebbeSostituireLeParoleSenzaRipetereLaSostituzioneGiaPresente;
begin
  Assert.AreEqual('hi there, hello', string(TBotChatText.ReplaceWords('hello there, hello', 'hello', 'hi')));
  Assert.AreEqual('i am here', string(TBotChatText.ReplaceWords('im here', 'im', 'i am')));
  Assert.AreEqual('i am here', string(TBotChatText.ReplaceWords('i am here', 'am', 'i am')));
  Assert.AreEqual('nothing', string(TBotChatText.ReplaceWords('nothing', 'x', 'y')));
end;

{ TTestBotScriptCompressor }

procedure TTestBotScriptCompressor.DovrebbeTogliereICommentiDiRigaEDiBlocco;
begin
  Assert.AreEqual('a'#10'b c', string(TBotScriptCompressor.Compress('a // x'#10'b /* y */ c')));
end;

procedure TTestBotScriptCompressor.DovrebbeUnireGliSpaziEIFineRiga;
begin
  Assert.AreEqual('a b'#10'c', string(TBotScriptCompressor.Compress('a  '#9' b'#13#10#10#13'c')));
end;

procedure TTestBotScriptCompressor.DovrebbeCopiareLeStringheTraVirgolette;
begin
  Assert.AreEqual('x "a  // b'#10'  c" y', string(TBotScriptCompressor.Compress('x   "a  // b'#10'  c"   y')));
end;

procedure TTestBotScriptCompressor.DovrebbeFermarsiAlPrimoZero;
begin
  Assert.AreEqual('ab', string(TBotScriptCompressor.Compress('ab'#0'cd')));
end;

procedure TTestBotScriptCompressor.DovrebbeNonScrivereLUltimoFineRiga;
begin
  Assert.AreEqual('a', string(TBotScriptCompressor.Compress('a'#10#10)));
  Assert.AreEqual('', string(TBotScriptCompressor.Compress('// only a comment')));
  Assert.AreEqual('a', string(TBotScriptCompressor.Compress('a /* open')));
end;

{ TTestBotMsvcRandom }

procedure TTestBotMsvcRandom.DovrebbeDareLaSequenzaDiRandDelRuntimeMicrosoft;
var
  LRandom: TBotMsvcRandom;
begin
  // srand(1) of the Microsoft runtime: 41, 18467, 6334, 26500, 19169
  LRandom := TBotMsvcRandom.Create(1);
  try
    Assert.AreEqual(41, LRandom.Rand);
    Assert.AreEqual(18467, LRandom.Rand);
    Assert.AreEqual(6334, LRandom.Rand);
    Assert.AreEqual(26500, LRandom.Rand);
    Assert.AreEqual(19169, LRandom.Rand);
  finally
    LRandom.Free;
  end;
end;

procedure TTestBotMsvcRandom.DovrebbeDareNumeriTraZeroEUno;
var
  LRandom: TBotMsvcRandom;
  LIndex: Integer;
  LValue: Single;
begin
  LRandom := TBotMsvcRandom.Create(7);
  try
    for LIndex := 1 to 200 do
    begin
      LValue := LRandom.NextFloat;
      Assert.IsTrue((LValue >= 0) and (LValue <= 1));
    end;
  finally
    LRandom.Free;
  end;
end;

procedure TTestBotMsvcRandom.DovrebbeRipartireDalSeme;
var
  LRandom: TBotMsvcRandom;
  LFirst: Integer;
begin
  LRandom := TBotMsvcRandom.Create(5);
  try
    LFirst := LRandom.Rand;
    LRandom.Rand;
    LRandom.SetSeed(5);
    Assert.AreEqual(LFirst, LRandom.Rand);
  finally
    LRandom.Free;
  end;
end;

{ TTestBotLibVarTable }

procedure TTestBotLibVarTable.DovrebbeCreareLaVariabileConIlPredefinito;
var
  LTable: TBotLibVarTable;
begin
  LTable := TBotLibVarTable.Create;
  try
    Assert.AreEqual('syn.c', string(LTable.GetStringOrCreate('synfile', 'syn.c')));
    Assert.AreEqual<Integer>(1024, Round(LTable.GetValueOrCreate('max_messages', '1024')));
    Assert.AreEqual<Integer>(1024, Round(LTable.GetValue('max_messages')));
    // the default is only used the first time
    Assert.AreEqual('syn.c', string(LTable.GetStringOrCreate('synfile', 'other.c')));
  finally
    LTable.Free;
  end;
end;

procedure TTestBotLibVarTable.DovrebbeDareZeroPerUnaVariabileMancante;
var
  LTable: TBotLibVarTable;
begin
  LTable := TBotLibVarTable.Create;
  try
    Assert.AreEqual<Integer>(0, Round(LTable.GetValue('missing')));
  finally
    LTable.Free;
  end;
end;

procedure TTestBotLibVarTable.DovrebbeIgnorareLeMaiuscoleNeiNomi;
var
  LTable: TBotLibVarTable;
begin
  LTable := TBotLibVarTable.Create;
  try
    LTable.SetText('Bot_Developer', '1');
    Assert.AreEqual<Integer>(1, Round(LTable.GetValue('bot_developer')));
  finally
    LTable.Free;
  end;
end;

procedure TTestBotLibVarTable.DovrebbeCambiareIlValore;
var
  LTable: TBotLibVarTable;
begin
  LTable := TBotLibVarTable.Create;
  try
    LTable.SetText('x', '2.5');
    Assert.AreEqual(Double(2.5), Double(LTable.GetValue('x')), Double(0.0001));
    LTable.SetText('x', '4');
    Assert.AreEqual(Double(4.0), Double(LTable.GetValue('x')), Double(0.0001));
  finally
    LTable.Free;
  end;
end;

end.
