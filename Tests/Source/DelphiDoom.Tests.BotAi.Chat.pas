{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the chat system of the bot AI library (DUnitX), with   }
{  files in memory and the differences from the original                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Chat;

interface

uses
  DUnitX.TestFramework, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Intf, DelphiDoom.BotAi.LibVars.Table,
  DelphiDoom.Tests.BotAi.Support;

type
  [TestFixture]
  [Category('BotAi')]
  TTestBotChatSystem = class
  strict private
    FImport: TFakeBotImport;
    FImportRef: IBotImport;
    FFiles: TMemoryBotFiles;
    FFilesRef: IBotFileSource;
    FLibVars: TBotLibVarTable;
    FLibVarsRef: IBotLibVars;
    FChat: IBotChatSystem;
    procedure NewSystem(const ARandom: IBotRandom);
    procedure AddBasicFiles;
    function Printed: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareISeiFileDelSetupEStamparli;
    [Test]
    procedure DovrebbeCostruireUnMessaggioConVariabileEStringaCasuale;
    [Test]
    procedure DovrebbeSceglierePerPrimaLaRispostaConPrioritaPiuAlta;
    [Test]
    procedure DovrebbeRispondereSoloSeIlNomeDelBotCompare;
    [Test]
    procedure DovrebbeNonRiusareUnMessaggioPrimaDiVentiSecondi;
    [Test]
    procedure DovrebbeInviareIlMessaggioConSayTeamETell;
    [Test]
    procedure DovrebbeSegnalareLaCodaDeiMessaggiDellaConsolePiena;
    [Test]
    procedure DovrebbeDareAlMassimoSessantaquattroStatiDiChat;
    [Test]
    procedure DovrebbeSegnalareUnaManigliaFuoriIntervallo;
    [Test]
    procedure DovrebbeDareLInsiemeDelleVariabiliDelGioco;
    [Test]
    procedure DovrebbeTagliareIlTestoDelMatchAlladimensioneDiUnMessaggio;
    [Test]
    procedure DovrebbeSegnalareUnaVariabileOltreLeOtto;
    [Test]
    procedure DovrebbeSegnalareUnNomeCasualeTroppoLungo;
    [Test]
    procedure DovrebbeCapireUnNumeroEsadecimaleConLettereMaiuscole;
    [Test]
    procedure DovrebbeSegnalareLaParentesiGraffaMancanteConLaRiga;
    [Test]
    procedure DovrebbeTenereValidaLaChatInCacheQuandoUnoStatoNeCaricaUnAltra;
    [Test]
    procedure DovrebbeDareZeroSeLoStatoNonHaUnaChat;
    [Test]
    procedure DovrebbeSegnalareUnIncludeMancante;
    [Test]
    procedure DovrebbeLeggereIlRisultatoDelleVariabiliDiUnMatch;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.BotAi.Types, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Factory;

{ TTestBotChatSystem }

procedure TTestBotChatSystem.Setup;
begin
  FImport := TFakeBotImport.Create;
  FImportRef := FImport;
  FFiles := TMemoryBotFiles.Create;
  FFilesRef := FFiles;
  FLibVars := TBotLibVarTable.Create;
  FLibVarsRef := FLibVars;
  FChat := nil;
end;

procedure TTestBotChatSystem.TearDown;
begin
  FChat := nil;
  FLibVarsRef := nil;
  FFilesRef := nil;
  FImportRef := nil;
end;

procedure TTestBotChatSystem.NewSystem(const ARandom: IBotRandom);
begin
  FChat := TBotChatFactory.CreateChatSystem(FImport, FFiles, FLibVars, ARandom);
end;

procedure TTestBotChatSystem.AddBasicFiles;
begin
  FFiles.Add('botfiles/syn.c', '[("hello", 1), ("hi", 1)]');
  FFiles.Add('botfiles/rnd.c', 'greet = { "yo"; "hey"; }');
  FFiles.Add('botfiles/match.c', '2 { "hello ", 1 = (1, 0); 1, " killed ", 2 = (2, 0); }');
  FFiles.Add('botfiles/rchat.c',
    '[ "hello" ] = 5 { "low"; } [ "hello" ] = 20 { "high"; } [ & name, "bye" ] = 7 { "bye ", 0; }');
  FFiles.Add('botfiles/chats.c',
    'chat "b" { type "t" { "hi ", 0, " ", greet; } type "single" { "only"; } }');
end;

function TTestBotChatSystem.Printed: string;
begin
  Result := StringReplace(FImport.Lines.Text, sLineBreak, '/', [rfReplaceAll]);
end;

procedure TTestBotChatSystem.DovrebbeCaricareISeiFileDelSetupEStamparli;
begin
  AddBasicFiles;
  NewSystem(TSequenceRandom.Create([0]));
  Assert.AreEqual(BLERR_NOERROR, FChat.Setup);
  Assert.AreEqual('P1|loaded syn.c\x0A/P1|loaded rnd.c\x0A/P1|loaded match.c\x0A/P1|loaded rchat.c\x0A/', Printed);
end;

procedure TTestBotChatSystem.DovrebbeCostruireUnMessaggioConVariabileEStringaCasuale;
var
  LHandle: Integer;
begin
  AddBasicFiles;
  // the first number chooses the message, the second the random string (greet is read in reverse: hey, yo)
  NewSystem(TSequenceRandom.Create([0, 0.9]));
  FChat.Setup;
  LHandle := FChat.AllocChatState;
  Assert.AreEqual(BLERR_NOERROR, FChat.LoadChatFile(LHandle, 'chats.c', 'b'));
  FChat.InitialChat(LHandle, 't', 2, TBotChatVariables.FromTexts(['Bob']));
  Assert.AreEqual('hi Bob yo', string(FChat.GetChatMessage(LHandle, 256)));
  Assert.AreEqual(0, FChat.ChatLength(LHandle));
end;

procedure TTestBotChatSystem.DovrebbeSceglierePerPrimaLaRispostaConPrioritaPiuAlta;
var
  LHandle: Integer;
begin
  AddBasicFiles;
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  LHandle := FChat.AllocChatState;
  Assert.IsTrue(FChat.ReplyChat(LHandle, 'oh hello', 2, 2, TBotChatVariables.None));
  Assert.AreEqual('high', string(FChat.GetChatMessage(LHandle, 256)));
  Assert.IsFalse(FChat.ReplyChat(LHandle, 'nothing', 2, 2, TBotChatVariables.None));
end;

procedure TTestBotChatSystem.DovrebbeRispondereSoloSeIlNomeDelBotCompare;
var
  LHandle: Integer;
begin
  AddBasicFiles;
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  LHandle := FChat.AllocChatState;
  FChat.SetChatName(LHandle, 'Zed', 3);
  Assert.IsFalse(FChat.ReplyChat(LHandle, 'bye all', 2, 2, TBotChatVariables.None));
  Assert.IsTrue(FChat.ReplyChat(LHandle, 'bye zed', 2, 2, TBotChatVariables.FromTexts(['Joe'])));
  Assert.AreEqual('bye Joe', string(FChat.GetChatMessage(LHandle, 256)));
end;

procedure TTestBotChatSystem.DovrebbeNonRiusareUnMessaggioPrimaDiVentiSecondi;
var
  LHandle: Integer;
begin
  AddBasicFiles;
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  LHandle := FChat.AllocChatState;
  FChat.LoadChatFile(LHandle, 'chats.c', 'b');
  FImport.CurrentTime := 100;
  FChat.InitialChat(LHandle, 'single', 2, TBotChatVariables.None);
  Assert.AreEqual('only', string(FChat.GetChatMessage(LHandle, 256)));
  // all the messages of the type are recent: the oldest one is used and its time is not changed
  FImport.CurrentTime := 105;
  FChat.InitialChat(LHandle, 'single', 2, TBotChatVariables.None);
  Assert.AreEqual('only', string(FChat.GetChatMessage(LHandle, 256)));
  FChat.ResetChatAI;
end;

procedure TTestBotChatSystem.DovrebbeInviareIlMessaggioConSayTeamETell;
var
  LHandle: Integer;
begin
  AddBasicFiles;
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  LHandle := FChat.AllocChatState;
  FChat.SetChatName(LHandle, 'Zed', 4);
  FChat.LoadChatFile(LHandle, 'chats.c', 'b');
  FImport.Lines.Clear;
  FImport.CurrentTime := 0;
  FChat.InitialChat(LHandle, 'single', 2, TBotChatVariables.None);
  FChat.EnterChat(LHandle, 9, CHAT_TEAM);
  FImport.CurrentTime := 50;
  FChat.InitialChat(LHandle, 'single', 2, TBotChatVariables.None);
  FChat.EnterChat(LHandle, 9, CHAT_TELL);
  FImport.CurrentTime := 100;
  FChat.InitialChat(LHandle, 'single', 2, TBotChatVariables.None);
  FChat.EnterChat(LHandle, 9, CHAT_ALL);
  Assert.AreEqual('E|4|say_team only/E|4|tell 9 only/E|4|say only/', Printed);
end;

procedure TTestBotChatSystem.DovrebbeSegnalareLaCodaDeiMessaggiDellaConsolePiena;
var
  LHandle: Integer;
begin
  FLibVars.SetText('max_messages', '2');
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  LHandle := FChat.AllocChatState;
  FImport.Lines.Clear;
  FChat.QueueConsoleMessage(LHandle, 1, 'a');
  FChat.QueueConsoleMessage(LHandle, 1, 'b');
  FChat.QueueConsoleMessage(LHandle, 1, 'c');
  Assert.AreEqual(2, FChat.NumConsoleMessages(LHandle));
  Assert.AreEqual('P3|empty console message heap\x0A/', Printed);
end;

procedure TTestBotChatSystem.DovrebbeDareAlMassimoSessantaquattroStatiDiChat;
var
  LIndex: Integer;
begin
  NewSystem(TSequenceRandom.Create([0]));
  for LIndex := 1 to 64 do
    Assert.AreEqual(LIndex, FChat.AllocChatState);
  Assert.AreEqual(0, FChat.AllocChatState);
  FChat.FreeChatState(30);
  Assert.AreEqual(30, FChat.AllocChatState);
  FChat.Shutdown;
end;

procedure TTestBotChatSystem.DovrebbeSegnalareUnaManigliaFuoriIntervallo;
begin
  NewSystem(TSequenceRandom.Create([0]));
  Assert.AreEqual(0, FChat.NumConsoleMessages(65));
  Assert.AreEqual(0, FChat.NumConsoleMessages(3));
  Assert.AreEqual('P4|chat state handle 65 out of range\x0A/P4|invalid chat state 3\x0A/', Printed);
  Assert.AreEqual(BLERR_CANNOTLOADICHAT, FChat.LoadChatFile(0, 'a', 'b'));
end;

procedure TTestBotChatSystem.DovrebbeDareLInsiemeDelleVariabiliDelGioco;
var
  LVariables: TBotChatVariables;
begin
  LVariables := TBotChatVariables.FromTexts(['a', 'b']);
  Assert.IsTrue(LVariables.Items[0].IsSet);
  Assert.IsTrue(LVariables.Items[1].IsSet);
  Assert.IsFalse(LVariables.Items[2].IsSet);
  Assert.IsFalse(TBotChatVariables.None.Items[0].IsSet);
end;

procedure TTestBotChatSystem.DovrebbeTagliareIlTestoDelMatchAlladimensioneDiUnMessaggio;
var
  LMatch: TBotMatch;
begin
  AddBasicFiles;
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  // the original copies 256 characters without the zero
  Assert.IsTrue(FChat.FindMatch('hello ' + StringOfChar('x', 400), LMatch, 2));
  Assert.AreEqual(255, Length(LMatch.Text));
end;

procedure TTestBotChatSystem.DovrebbeSegnalareUnaVariabileOltreLeOtto;
var
  LHandle: Integer;
  LMatch: TBotMatch;
begin
  NewSystem(TSequenceRandom.Create([0]));
  LHandle := FChat.AllocChatState;
  LMatch := Default(TBotMatch);
  // variable 8 is outside the match: the original reads what is behind it
  FChat.ConstructChatMessage(LHandle, #1'v8'#1, 2, 0, LMatch, False);
  Assert.AreEqual('P3|BotConstructChat: message \x01v8\x01 variable 8 out of range\x0A/', Printed);
end;

procedure TTestBotChatSystem.DovrebbeSegnalareUnNomeCasualeTroppoLungo;
begin
  FFiles.Add('botfiles/rnd.c', 'a = { "' + StringOfChar('x', 200) + '", ' + StringOfChar('n', 60) + '; }');
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  Assert.IsTrue(Pos('chat message too long', Printed) > 0);
end;

procedure TTestBotChatSystem.DovrebbeCapireUnNumeroEsadecimaleConLettereMaiuscole;
var
  LMatch: TBotMatch;
begin
  // l_script.c accepts only a..f and the letter A as hexadecimal digits: 0xFF is 0x and a name
  FFiles.Add('botfiles/syn.c', '');
  FFiles.Add('botfiles/rnd.c', '');
  FFiles.Add('botfiles/rchat.c', '');
  FFiles.Add('botfiles/match.c', '0xFF { "a", 1 = (3, 4); }');
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  Assert.IsTrue(FChat.FindMatch('a b', LMatch, $FF));
  Assert.AreEqual(3, LMatch.MatchType);
  Assert.AreEqual(4, LMatch.SubType);
end;

procedure TTestBotChatSystem.DovrebbeSegnalareLaParentesiGraffaMancanteConLaRiga;
begin
  FFiles.Add('botfiles/syn.c', '2 { [("a", 1), ("b", 1)]'#10);
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  // the original reports it on the source it has already freed (undefined behaviour)
  Assert.IsTrue(Pos('P3|file syn.c, line 1: missing }', Printed) > 0);
  Assert.IsFalse(Pos('P1|loaded syn.c', Printed) > 0);
end;

procedure TTestBotChatSystem.DovrebbeTenereValidaLaChatInCacheQuandoUnoStatoNeCaricaUnAltra;
var
  LFirst: Integer;
  LSecond: Integer;
  LThird: Integer;
begin
  AddBasicFiles;
  FFiles.Add('botfiles/chats.c', 'chat "a" { type "t" { "one"; "two"; } } chat "b" { type "u" { "x"; } }');
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  LFirst := FChat.AllocChatState;
  LSecond := FChat.AllocChatState;
  LThird := FChat.AllocChatState;
  FChat.LoadChatFile(LFirst, 'chats.c', 'a');
  // the original frees the chat of the first state here, and the cache still points to it
  FChat.LoadChatFile(LFirst, 'chats.c', 'b');
  FChat.LoadChatFile(LSecond, 'chats.c', 'a');
  Assert.AreEqual(2, FChat.NumInitialChats(LSecond, 't'));
  FChat.LoadChatFile(LThird, 'chats.c', 'a');
  Assert.AreEqual(2, FChat.NumInitialChats(LThird, 't'));
end;

procedure TTestBotChatSystem.DovrebbeDareZeroSeLoStatoNonHaUnaChat;
var
  LHandle: Integer;
begin
  NewSystem(TSequenceRandom.Create([0]));
  LHandle := FChat.AllocChatState;
  // the original dereferences a null pointer
  Assert.AreEqual(0, FChat.NumInitialChats(LHandle, 't'));
end;

procedure TTestBotChatSystem.DovrebbeSegnalareUnIncludeMancante;
begin
  FFiles.Add('botfiles/syn.c', '#include "nofile.h"'#10'2 { [("a", 1), ("b", 1)] }');
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  Assert.IsTrue(Pos('P3|file syn.c, line 1:', Printed) > 0);
  Assert.IsTrue(Pos('nofile.h', Printed) > 0);
end;

procedure TTestBotChatSystem.DovrebbeLeggereIlRisultatoDelleVariabiliDiUnMatch;
var
  LMatch: TBotMatch;
begin
  AddBasicFiles;
  NewSystem(TSequenceRandom.Create([0]));
  FChat.Setup;
  Assert.IsTrue(FChat.FindMatch('john killed mary'#10, LMatch, 2));
  Assert.AreEqual(2, LMatch.MatchType);
  Assert.AreEqual('john', string(FChat.MatchVariable(LMatch, 1, 256)));
  Assert.AreEqual('mary', string(FChat.MatchVariable(LMatch, 2, 256)));
  Assert.AreEqual('jo', string(FChat.MatchVariable(LMatch, 1, 3)));
  Assert.AreEqual('', string(FChat.MatchVariable(LMatch, 3, 256)));
  Assert.IsFalse(FChat.FindMatch('john killed mary', LMatch, 4));
end;

end.
