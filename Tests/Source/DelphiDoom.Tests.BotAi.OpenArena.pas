{******************************************************************************}
{                                                                              }
{  DelphiDoom: the bot files of OpenArena read by the chat (DUnitX)            }
{                                                                              }
{  The tests read botfiles\ of pak6-misc.pk3 of OpenArena 0.8.8 (GPL v2) where  }
{  it is (DELPHIDOOM_OPENARENA = the pk3, or Reference\openarena); without it   }
{  they are ignored. Nothing of OpenArena is in the repository.                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.OpenArena;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi')]
  [Category('OpenArena')]
  TTestBotOpenArena = class
  strict private
    function Pk3Path: string;
  public
    [Test]
    procedure DovrebbeLeggereISeiFileDelSetupSenzaErrori;
    [Test]
    procedure DovrebbeCaricareLaChatDiTuttiIBot;
    [Test]
    procedure DovrebbeDareLeStesseRisposteConLoStessoSeme;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.Exceptions, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Types,
  DelphiDoom.BotAi.Chat.Intf, DelphiDoom.BotAi.Chat.Types, DelphiDoom.BotAi.Chat.Factory,
  DelphiDoom.BotAi.LibVars.Table, DelphiDoom.BotAi.Random.MsvcRand, DelphiDoom.Tests.BotAi.Support;

const
  MESSAGES: array[0..3] of AnsiString = ('no', 'why', 'ha funny', 'politicians');

{ TTestBotOpenArena }

function TTestBotOpenArena.Pk3Path: string;
var
  LRelative: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result <> '') and TFile.Exists(Result) then
    Exit;
  LRelative := '..\..\..\..\Reference\openarena\openarena-0.8.8\baseoa\pak6-misc.pk3';
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), LRelative));
  if not TFile.Exists(Result) then
    raise ETestIgnored.Create('pak6-misc.pk3 di OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena): prova ignorata');
end;

procedure TTestBotOpenArena.DovrebbeLeggereISeiFileDelSetupSenzaErrori;
var
  LImport: TFakeBotImport;
  LImportRef: IBotImport;
  LLibVars: TBotLibVarTable;
  LLibVarsRef: IBotLibVars;
  LChat: IBotChatSystem;
  LLine: string;
begin
  LImport := TFakeBotImport.Create;
  LImportRef := LImport;
  LLibVars := TBotLibVarTable.Create;
  LLibVarsRef := LLibVars;
  LLibVars.SetText('bot_developer', '1');
  LChat := TBotChatFactory.CreateChatSystem(LImport, TZipBotFiles.Create(Pk3Path), LLibVars, TBotMsvcRandom.Create(1));
  LChat.Setup;
  for LLine in LImport.Lines do
    Assert.IsFalse(LLine.StartsWith('P3|') or LLine.StartsWith('P4|'), LLine);
  Assert.IsTrue(LImport.Lines.IndexOf('P1|loaded syn.c\x0A') >= 0);
  Assert.IsTrue(LImport.Lines.IndexOf('P1|loaded rnd.c\x0A') >= 0);
  Assert.IsTrue(LImport.Lines.IndexOf('P1|loaded match.c\x0A') >= 0);
  Assert.IsTrue(LImport.Lines.IndexOf('P1|loaded rchat.c\x0A') >= 0);
  LChat.Shutdown;
end;

procedure TTestBotOpenArena.DovrebbeCaricareLaChatDiTuttiIBot;
var
  LImport: TFakeBotImport;
  LImportRef: IBotImport;
  LLibVars: TBotLibVarTable;
  LLibVarsRef: IBotLibVars;
  LFiles: TZipBotFiles;
  LFilesRef: IBotFileSource;
  LChat: IBotChatSystem;
  LName: string;
  LData: TBytes;
  LText: AnsiString;
  LStart: Integer;
  LEnd: Integer;
  LState: Integer;
  LCount: Integer;
  LLine: string;
begin
  LImport := TFakeBotImport.Create;
  LImportRef := LImport;
  LLibVars := TBotLibVarTable.Create;
  LLibVarsRef := LLibVars;
  LFiles := TZipBotFiles.Create(Pk3Path);
  LFilesRef := LFiles;
  LChat := TBotChatFactory.CreateChatSystem(LImport, LFiles, LLibVars, TBotMsvcRandom.Create(1));
  LChat.Setup;
  LCount := 0;
  for LName in LFiles.Names do
  begin
    if not (LName.StartsWith('botfiles/bots/') and LName.EndsWith('_t.c')) then
      Continue;
    LFiles.TryReadFile(AnsiString(LName), LData);
    SetLength(LText, Length(LData));
    Move(LData[0], LText[1], Length(LData));
    LStart := Pos('chat "', string(LText));
    Assert.IsTrue(LStart > 0, LName);
    LStart := LStart + 6;
    LEnd := Pos('"', string(LText), LStart);
    LState := LChat.AllocChatState;
    LImport.Lines.Clear;
    Assert.AreEqual<Integer>(BLERR_NOERROR, LChat.LoadChatFile(LState, AnsiString(Copy(LName, Length('botfiles/') + 1, MaxInt)),
      Copy(LText, LStart, LEnd - LStart)), LName + ': ' + LImport.Lines.Text);
    for LLine in LImport.Lines do
      Assert.IsFalse(LLine.StartsWith('P3|') or LLine.StartsWith('P4|'), LLine);
    Inc(LCount);
    LChat.FreeChatState(LState);
  end;
  Assert.IsTrue(LCount >= 20, 'chat dei bot trovate: ' + IntToStr(LCount));
end;

procedure TTestBotOpenArena.DovrebbeDareLeStesseRisposteConLoStessoSeme;
var
  LImport: TFakeBotImport;
  LImportRef: IBotImport;
  LLibVars: TBotLibVarTable;
  LLibVarsRef: IBotLibVars;
  LFirst: string;
  LSecond: string;

  function Run: string;
  var
    LChat: IBotChatSystem;
    LState: Integer;
    LIndex: Integer;
  begin
    LChat := TBotChatFactory.CreateChatSystem(LImport, TZipBotFiles.Create(Pk3Path), LLibVars, TBotMsvcRandom.Create(42));
    LChat.Setup;
    LState := LChat.AllocChatState;
    LChat.SetChatName(LState, 'sarge', 1);
    Result := '';
    for LIndex := 1 to 8 do
    begin
      LImport.CurrentTime := LIndex * 100;
      LChat.ReplyChat(LState, MESSAGES[LIndex mod 4], 2, 2,
        TBotChatVariables.FromTexts(['Bob']));
      Result := Result + string(LChat.GetChatMessage(LState, 256)) + '|';
    end;
    LChat.Shutdown;
  end;

begin
  LImport := TFakeBotImport.Create;
  LImportRef := LImport;
  LLibVars := TBotLibVarTable.Create;
  LLibVarsRef := LLibVars;
  LFirst := Run;
  LSecond := Run;
  Assert.AreEqual(LFirst, LSecond);
  Assert.IsTrue(Length(LFirst) > 8);
end;

end.
