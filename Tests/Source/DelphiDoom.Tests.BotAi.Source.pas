{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the source of the bots (PC_ functions), its log and    }
{  its file system (DUnitX)                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Source;

interface

uses
  DUnitX.TestFramework, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Source, DelphiDoom.Tests.BotAi.Support;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotChatSource = class
  strict private
    FImport: TFakeBotImport;
    FImportRef: IBotImport;
    FFiles: TMemoryBotFiles;
    FFilesRef: IBotFileSource;
    function Open(const AText: AnsiString): TBotChatSource;
    function Printed: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareNilSeIlFileMancaSenzaStampare;
    [Test]
    procedure DovrebbeDareITokenConLeStringheTraVirgolette;
    [Test]
    procedure DovrebbeSegnalareUnaStringaAttesaDiversa;
    [Test]
    procedure DovrebbeSegnalareLaFineDelFileMentreAspettaUnaStringa;
    [Test]
    procedure DovrebbeSegnalareUnTipoDiTokenDiverso;
    [Test]
    procedure DovrebbeSegnalareUnNumeroDiTipoDiverso;
    [Test]
    procedure DovrebbeSegnalareUnaPunteggiaturaDiversa;
    [Test]
    procedure DovrebbeAccettareUnNumeroEUnaPunteggiaturaCorretti;
    [Test]
    procedure DovrebbeSegnalareLaFineDelFileMentreAspettaUnToken;
    [Test]
    procedure DovrebbeControllareEPoiRimettereIlToken;
    [Test]
    procedure DovrebbeControllareIlTipoDelToken;
    [Test]
    procedure DovrebbeRimettereLUltimoToken;
    [Test]
    procedure DovrebbeStampareUnAvvisoConFileERiga;
    [Test]
    procedure DovrebbeStampareUnErroreDelloScannerEFinire;
    [Test]
    procedure DovrebbeStampareGliAvvisiDelPreprocessore;
    [Test]
    procedure DovrebbeLeggereUnFileIncluso;
    [Test]
    procedure DovrebbeNonTrovareUnPercorsoAssolutoNeUnFileMancante;
    [Test]
    procedure DovrebbeStampareIlMessaggioDelLog;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types,
  DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.ScriptLog,
  DelphiDoom.BotAi.Chat.ScriptFileSystem;

{ TTestBotChatSource }

procedure TTestBotChatSource.Setup;
begin
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FFiles := TMemoryBotFiles.Create;
  FFilesRef := FFiles;
end;

procedure TTestBotChatSource.TearDown;
begin
  FFilesRef := nil;
  FImportRef := nil;
end;

function TTestBotChatSource.Open(const AText: AnsiString): TBotChatSource;
begin
  FFiles.Add('botfiles/f.c', AText);
  Result := TBotChatSource.Open(FImport, FFiles, 'f.c');
end;

function TTestBotChatSource.Printed: string;
begin
  Result := StringReplace(FImport.Lines.Text, sLineBreak, '/', [rfReplaceAll]);
end;

procedure TTestBotChatSource.DovrebbeDareNilSeIlFileMancaSenzaStampare;
begin
  Assert.IsNull(TBotChatSource.Open(FImport, FFiles, 'missing.c'));
  Assert.AreEqual('', Printed);
end;

procedure TTestBotChatSource.DovrebbeDareITokenConLeStringheTraVirgolette;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('"a b" name 12 ''x'' ;');
  try
    Assert.IsTrue(LSource.ReadToken(LToken));
    Assert.AreEqual('"a b"', string(TBotChatSource.CText(LToken)));
    Assert.IsTrue(LSource.ReadToken(LToken));
    Assert.AreEqual('name', string(TBotChatSource.CText(LToken)));
    Assert.IsTrue(LSource.ReadToken(LToken));
    Assert.AreEqual('12', string(TBotChatSource.CText(LToken)));
    Assert.IsTrue(LSource.ReadToken(LToken));
    Assert.AreEqual('''x''', string(TBotChatSource.CText(LToken)));
    Assert.IsTrue(LSource.ReadToken(LToken));
    Assert.IsFalse(LSource.ReadToken(LToken));
    Assert.AreEqual('f.c', LSource.FileName);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeSegnalareUnaStringaAttesaDiversa;
var
  LSource: TBotChatSource;
begin
  LSource := Open('a');
  try
    Assert.WillRaise(procedure begin LSource.ExpectTokenString('b'); end, EBotChatParseException);
    Assert.AreEqual('P3|file f.c, line 1: expected b, found a\x0A/', Printed);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeSegnalareLaFineDelFileMentreAspettaUnaStringa;
var
  LSource: TBotChatSource;
begin
  LSource := Open('');
  try
    Assert.WillRaise(procedure begin LSource.ExpectTokenString('b'); end, EBotChatParseException);
    Assert.AreEqual('P3|file f.c, line 1: couldn''t find expected b\x0A/', Printed);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeSegnalareUnTipoDiTokenDiverso;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('abc');
  try
    Assert.WillRaise(procedure var LT: TIdToken; begin LSource.ExpectTokenType(TT_STRING, 0, LT); end,
      EBotChatParseException);
    Assert.AreEqual('P3|file f.c, line 1: expected a string, found abc\x0A/', Printed);
  finally
    LSource.Free;
  end;
  FImport.Lines.Clear;
  LSource := Open('"abc"');
  try
    Assert.WillRaise(procedure var LT: TIdToken; begin LSource.ExpectTokenType(TT_NUMBER, 0, LT); end,
      EBotChatParseException);
    Assert.AreEqual('P3|file f.c, line 1: expected a number, found "abc"\x0A/', Printed);
    LToken := TIdToken.Create;
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeSegnalareUnNumeroDiTipoDiverso;
var
  LSource: TBotChatSource;
begin
  LSource := Open('3.5');
  try
    // the original prints an uninitialised buffer before the names of the flags
    Assert.WillRaise(procedure var LT: TIdToken; begin LSource.ExpectTokenType(TT_NUMBER, TT_INTEGER, LT); end,
      EBotChatParseException);
    Assert.AreEqual('P3|file f.c, line 1: expected  integer, found 3.5\x0A/', Printed);
  finally
    LSource.Free;
  end;
  FImport.Lines.Clear;
  LSource := Open('3');
  try
    Assert.WillRaise(procedure var LT: TIdToken; begin LSource.ExpectTokenType(TT_NUMBER, TT_HEX or TT_LONG or TT_UNSIGNED or TT_FLOAT, LT); end,
      EBotChatParseException);
    Assert.IsTrue(Pos('hex long unsigned float', Printed) > 0);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeSegnalareUnaPunteggiaturaDiversa;
var
  LSource: TBotChatSource;
begin
  LSource := Open(';');
  try
    Assert.WillRaise(procedure var LT: TIdToken; begin LSource.ExpectTokenType(TT_PUNCTUATION, P_COMMA, LT); end,
      EBotChatParseException);
    Assert.AreEqual('P3|file f.c, line 1: found ;\x0A/', Printed);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeAccettareUnNumeroEUnaPunteggiaturaCorretti;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('7 ; "s" nm');
  try
    Assert.IsTrue(LSource.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken));
    Assert.AreEqual<Integer>(7, Integer(LToken.GetUnsignedLongValue));
    Assert.IsTrue(LSource.ExpectTokenType(TT_PUNCTUATION, P_SEMICOLON, LToken));
    Assert.IsTrue(LSource.ExpectTokenType(TT_STRING, 0, LToken));
    Assert.IsTrue(LSource.ExpectTokenType(TT_NAME, 0, LToken));
    Assert.AreEqual('', Printed);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeSegnalareLaFineDelFileMentreAspettaUnToken;
var
  LSource: TBotChatSource;
begin
  LSource := Open('');
  try
    Assert.WillRaise(procedure var LT: TIdToken; begin LSource.ExpectAnyToken(LT); end, EBotChatParseException);
    Assert.WillRaise(procedure var LT: TIdToken; begin LSource.ExpectTokenType(TT_NAME, 0, LT); end,
      EBotChatParseException);
    Assert.AreEqual('P3|file f.c, line 1: couldn''t read expected token\x0A/P3|file f.c, line 1: couldn''t read expected token\x0A/', Printed);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeControllareEPoiRimettereIlToken;
var
  LSource: TBotChatSource;
begin
  LSource := Open('a b');
  try
    Assert.IsFalse(LSource.CheckTokenString('x'));
    Assert.IsTrue(LSource.CheckTokenString('a'));
    Assert.IsFalse(LSource.CheckTokenString('"b"'));
    Assert.IsTrue(LSource.CheckTokenString('b'));
    Assert.IsFalse(LSource.CheckTokenString('c'));
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeControllareIlTipoDelToken;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('5 "a" 6');
  try
    Assert.IsFalse(LSource.CheckTokenType(TT_STRING, 0, LToken));
    Assert.IsTrue(LSource.CheckTokenType(TT_NUMBER, TT_INTEGER, LToken));
    Assert.AreEqual<Integer>(5, Integer(LToken.GetUnsignedLongValue));
    Assert.IsTrue(LSource.CheckTokenType(TT_STRING, 0, LToken));
    Assert.IsFalse(LSource.CheckTokenType(TT_NUMBER, TT_FLOAT, LToken));
    Assert.IsTrue(LSource.CheckTokenType(TT_NUMBER, 0, LToken));
    Assert.IsFalse(LSource.CheckTokenType(TT_NUMBER, 0, LToken));
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeRimettereLUltimoToken;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('one two');
  try
    LSource.ReadToken(LToken);
    LSource.UnreadLastToken;
    Assert.IsTrue(LSource.ReadToken(LToken));
    Assert.AreEqual('one', string(LToken.Text));
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeStampareUnAvvisoConFileERiga;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('a'#10'b');
  try
    LSource.ReadToken(LToken);
    LSource.ReadToken(LToken);
    LSource.Warning('careful');
    Assert.AreEqual('P2|file f.c, line 2: careful\x0A/', Printed);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeStampareUnErroreDelloScannerEFinire;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('"never closed'#10'x');
  try
    Assert.IsFalse(LSource.ReadToken(LToken));
    Assert.IsTrue(Pos('P3|file f.c, line 1:', Printed) = 1);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeStampareGliAvvisiDelPreprocessore;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  LSource := Open('#warning "careful"'#10'x');
  try
    Assert.IsTrue(LSource.ReadToken(LToken));
    Assert.AreEqual('x', string(LToken.Text));
    Assert.IsTrue(Pos('P2|file f.c, line 1:', Printed) = 1, Printed);
    Assert.IsTrue(Pos('careful', Printed) > 0, Printed);
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeLeggereUnFileIncluso;
var
  LSource: TBotChatSource;
  LToken: TIdToken;
begin
  FFiles.Add('botfiles/inc.h', '#define ANSWER 42 // a comment'#13#10);
  LSource := Open('#include "inc.h"'#10'ANSWER');
  try
    Assert.IsTrue(LSource.ExpectTokenType(TT_NUMBER, TT_INTEGER, LToken));
    Assert.AreEqual<Integer>(42, Integer(LToken.GetUnsignedLongValue));
  finally
    LSource.Free;
  end;
end;

procedure TTestBotChatSource.DovrebbeNonTrovareUnPercorsoAssolutoNeUnFileMancante;
var
  LSystem: IIdLibFileSystem;
  LFile: TIdLibFileData;
begin
  FFiles.Add('botfiles/dir/a.c', 'text // comment');
  LSystem := TBotScriptFileSystem.Create(FFiles, 'botfiles');
  Assert.IsFalse(LSystem.TryReadFile('', False, LFile));
  Assert.IsFalse(LSystem.TryReadFile('/dir/a.c', False, LFile));
  Assert.IsFalse(LSystem.TryReadFile('nofile.c', False, LFile));
  Assert.IsTrue(LSystem.TryReadFile('dir\\a.c', False, LFile));
  Assert.AreEqual('dir\\a.c', string(LFile.FullPath));
  Assert.AreEqual<Integer>(4, Length(LFile.Data));
  Assert.IsFalse(LSystem.WriteFile('x', nil));
end;

procedure TTestBotChatSource.DovrebbeStampareIlMessaggioDelLog;
var
  LLog: IIdLibLog;
begin
  LLog := TBotScriptLog.Create(FImport);
  LLog.Printf('info');
  LLog.Warning('careful');
  Assert.AreEqual('P1|info/P2|careful\x0A/', Printed);
end;

end.
