{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - pda, email, video, audio     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Pda;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Types, DelphiDoom.Decl.Pda,
  DelphiDoom.Tests.Decl.Support;

type
  [TestFixture]
  [Category('Decl')]
  TTestDeclPda = class
  strict private
    FKit: TDeclKit;
    function Pda(const AName: AnsiString): IDeclPda;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereIDatiEdElenchi;
    [Test]
    procedure DovrebbeCreareLeDichiarazioniCitate;
    [Test]
    procedure DovrebbeAggiungereSoloSeEsiste;
    [Test]
    procedure DovrebbeAggiungereUnaVoltaSolaConUnique;
    [Test]
    procedure DovrebbeAggiungereDueVolteSenzaUnique;
    [Test]
    procedure DovrebbeTogliereLeAggiunteDopoLaLettura;
    [Test]
    procedure DovrebbeImpostareLaSicurezza;
    [Test]
    procedure DovrebbeRestituireNilFuoriIndice;
    [Test]
    procedure DovrebbeLeggereUnaEmail;
    [Test]
    procedure DovrebbeUnireLeParoleDelTestoDellaEmail;
    [Test]
    procedure DovrebbeSegnalareUnaEmailConTestoSenzaGraffa;
    [Test]
    procedure DovrebbeLeggereUnVideoEIlSuoMaterialeESuono;
    [Test]
    procedure DovrebbeLeggereUnAudio;
    [Test]
    procedure DovrebbeUsareLeDefinizioniDiDefaultDiPdaEmailVideoAudio;
    [Test]
    procedure DovrebbeTenereICampiCheUnaNuovaLetturaNonImposta;
    [Test]
    procedure DovrebbeSegnalareUnErroreDelLexerInOgniTipo;
    [Test]
    procedure DovrebbeDareUnaDimensioneInMemoria;
  end;

implementation

uses
  DelphiDoom.Decl.Email, DelphiDoom.Decl.Video, DelphiDoom.Decl.Audio;

const
  PDA_TEXT =
    'pda mine {'#10 +
    '  name "My PDA" fullname "Full Name" icon "gfx/icon" id "42" post "Marine" title "Title" security "red"'#10 +
    '  pda_email mail1 pda_email "mail2" pda_audio log1 pda_video vid1'#10 +
    '}'#10 +
    'email mail1 { subject "Hello" to "you" from "me" date "today" image "img" text { "a" "b" "c" } }'#10 +
    'video vid1 { name "Vid" preview "pv" video "mat/video" info "inf" audio "snd/video" }'#10 +
    'audio log1 { name "Log" audio "snd/log" info "li" preview "lp" }';

{ TTestDeclPda }

procedure TTestDeclPda.Setup;
begin
  FKit := TDeclKit.Create;
  FKit.Source.Add('def/pda.pda', PDA_TEXT);
  FKit.Start(True, False);
  FKit.Manager.GetRegistry.RegisterDeclFolder('def', '.pda', DECL_PDA);
end;

procedure TTestDeclPda.TearDown;
begin
  FreeAndNil(FKit);
end;

function TTestDeclPda.Pda(const AName: AnsiString): IDeclPda;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_PDA, AName), IDeclPda, Result));
end;

procedure TTestDeclPda.DovrebbeLeggereIDatiEdElenchi;
var
  LPda: IDeclPda;
begin
  LPda := Pda('mine');
  Assert.AreEqual('My PDA', string(LPda.GetPdaName));
  Assert.AreEqual('Full Name', string(LPda.GetFullName));
  Assert.AreEqual('gfx/icon', string(LPda.GetIcon));
  Assert.AreEqual('42', string(LPda.GetID));
  Assert.AreEqual('Marine', string(LPda.GetPost));
  Assert.AreEqual('Title', string(LPda.GetTitle));
  Assert.AreEqual('red', string(LPda.GetSecurity));
  Assert.AreEqual(2, LPda.GetNumEmails);
  Assert.AreEqual(1, LPda.GetNumAudios);
  Assert.AreEqual(1, LPda.GetNumVideos);
end;

procedure TTestDeclPda.DovrebbeCreareLeDichiarazioniCitate;
begin
  Pda('mine');
  // mail2 is not in a file: the pda made a default for it
  Assert.AreEqual(2, FKit.Manager.GetNumDecls(DECL_EMAIL));
  Assert.IsTrue(FKit.Manager.FindType(DECL_EMAIL, 'mail2', False).GetState = dsDefaulted);
  // the video named a material and a sound shader
  Assert.IsTrue(Assigned(FKit.Manager.FindType(DECL_MATERIAL, 'mat/video', False)));
  Assert.IsTrue(Assigned(FKit.Manager.FindType(DECL_SOUND, 'snd/video', False)));
  Assert.IsTrue(Assigned(FKit.Manager.FindType(DECL_SOUND, 'snd/log', False)));
end;

procedure TTestDeclPda.DovrebbeAggiungereSoloSeEsiste;
var
  LPda: IDeclPda;
begin
  LPda := Pda('mine');
  LPda.AddEmail('nothing');
  Assert.AreEqual(2, LPda.GetNumEmails);
  Assert.IsTrue(Pos('Email nothing not found', FKit.LogText) > 0, FKit.LogText);
  LPda.AddVideo('nothing');
  LPda.AddAudio('nothing');
  Assert.IsTrue(Pos('Video nothing not found', FKit.LogText) > 0);
  Assert.IsTrue(Pos('Audio log nothing not found', FKit.LogText) > 0);
end;

procedure TTestDeclPda.DovrebbeAggiungereUnaVoltaSolaConUnique;
var
  LPda: IDeclPda;
begin
  LPda := Pda('mine');
  FKit.Manager.FindType(DECL_EMAIL, 'extra');
  LPda.AddEmail('extra');
  LPda.AddEmail('extra');
  Assert.AreEqual(3, LPda.GetNumEmails);
  // the check is case sensitive, as idStrList::Find
  LPda.AddEmail('EXTRA');
  Assert.AreEqual(4, LPda.GetNumEmails);
end;

procedure TTestDeclPda.DovrebbeAggiungereDueVolteSenzaUnique;
var
  LPda: IDeclPda;
begin
  LPda := Pda('mine');
  FKit.Manager.FindType(DECL_AUDIO, 'extra');
  LPda.AddAudio('extra', False);
  LPda.AddAudio('extra', False);
  Assert.AreEqual(3, LPda.GetNumAudios);
end;

procedure TTestDeclPda.DovrebbeTogliereLeAggiunteDopoLaLettura;
var
  LPda: IDeclPda;
begin
  LPda := Pda('mine');
  FKit.Manager.FindType(DECL_EMAIL, 'extra');
  FKit.Manager.FindType(DECL_VIDEO, 'extra');
  FKit.Manager.FindType(DECL_AUDIO, 'extra');
  LPda.AddEmail('extra');
  LPda.AddVideo('extra');
  LPda.AddAudio('extra');
  LPda.RemoveAddedEmailsAndVideos;
  Assert.AreEqual(2, LPda.GetNumEmails);
  Assert.AreEqual(1, LPda.GetNumVideos);
  // the audio logs stay, as in the original
  Assert.AreEqual(2, LPda.GetNumAudios);
end;

procedure TTestDeclPda.DovrebbeImpostareLaSicurezza;
var
  LPda: IDeclPda;
begin
  LPda := Pda('mine');
  LPda.SetSecurity('blue');
  Assert.AreEqual('blue', string(LPda.GetSecurity));
end;

procedure TTestDeclPda.DovrebbeRestituireNilFuoriIndice;
var
  LPda: IDeclPda;
begin
  LPda := Pda('mine');
  Assert.IsFalse(Assigned(LPda.GetEmailByIndex(-1)));
  Assert.IsFalse(Assigned(LPda.GetEmailByIndex(2)));
  Assert.IsFalse(Assigned(LPda.GetVideoByIndex(1)));
  Assert.IsFalse(Assigned(LPda.GetAudioByIndex(5)));
  Assert.AreEqual('mail1', string(LPda.GetEmailByIndex(0).GetName));
  Assert.AreEqual('vid1', string(LPda.GetVideoByIndex(0).GetName));
  Assert.AreEqual('log1', string(LPda.GetAudioByIndex(0).GetName));
end;

procedure TTestDeclPda.DovrebbeLeggereUnaEmail;
var
  LMail: IDeclEmail;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_EMAIL, 'mail1'), IDeclEmail, LMail));
  Assert.AreEqual('Hello', string(LMail.GetSubject));
  Assert.AreEqual('you', string(LMail.GetTo));
  Assert.AreEqual('me', string(LMail.GetFrom));
  Assert.AreEqual('today', string(LMail.GetDate));
  Assert.AreEqual('img', string(LMail.GetImage));
end;

procedure TTestDeclPda.DovrebbeUnireLeParoleDelTestoDellaEmail;
var
  LMail: IDeclEmail;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_EMAIL, 'mail1'), IDeclEmail, LMail));
  Assert.AreEqual('abc', string(LMail.GetBody));
end;

procedure TTestDeclPda.DovrebbeSegnalareUnaEmailConTestoSenzaGraffa;
var
  LDecl: IDecl;
begin
  FKit.Manager.FindType(DECL_EMAIL, 'bad');
  LDecl := FKit.Manager.FindType(DECL_EMAIL, 'bad');
  LDecl.SetText('email bad { text "x" }');
  LDecl.Invalidate;
  LDecl.EnsureNotPurged;
  Assert.IsTrue(Pos('Email decl ''bad'' had a parse error', FKit.LogText) > 0, FKit.LogText);
end;

procedure TTestDeclPda.DovrebbeLeggereUnVideoEIlSuoMaterialeESuono;
var
  LVideo: IDeclVideo;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_VIDEO, 'vid1'), IDeclVideo, LVideo));
  Assert.AreEqual('Vid', string(LVideo.GetVideoName));
  Assert.AreEqual('pv', string(LVideo.GetPreview));
  Assert.AreEqual('mat/video', string(LVideo.GetRoq));
  Assert.AreEqual('inf', string(LVideo.GetInfo));
  Assert.AreEqual('snd/video', string(LVideo.GetWave));
end;

procedure TTestDeclPda.DovrebbeLeggereUnAudio;
var
  LAudio: IDeclAudio;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_AUDIO, 'log1'), IDeclAudio, LAudio));
  Assert.AreEqual('Log', string(LAudio.GetAudioName));
  Assert.AreEqual('snd/log', string(LAudio.GetWave));
  Assert.AreEqual('li', string(LAudio.GetInfo));
  Assert.AreEqual('lp', string(LAudio.GetPreview));
end;

procedure TTestDeclPda.DovrebbeUsareLeDefinizioniDiDefaultDiPdaEmailVideoAudio;
var
  LVideo: IDeclVideo;
  LAudio: IDeclAudio;
  LMail: IDeclEmail;
begin
  Assert.AreEqual('default pda', string(Pda('absent').GetPdaName));
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_VIDEO, 'absent'), IDeclVideo, LVideo));
  Assert.AreEqual('5', string(LVideo.GetVideoName));
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_AUDIO, 'absent'), IDeclAudio, LAudio));
  Assert.AreEqual('5', string(LAudio.GetAudioName));
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_EMAIL, 'absent'), IDeclEmail, LMail));
  Assert.AreEqual('5', string(LMail.GetTo));
end;

procedure TTestDeclPda.DovrebbeTenereICampiCheUnaNuovaLetturaNonImposta;
var
  LMail: IDeclEmail;
begin
  Assert.IsTrue(Supports(FKit.Manager.FindType(DECL_EMAIL, 'mail1'), IDeclEmail, LMail));
  FKit.Source.Add('def/pda.pda', AnsiString(StringReplace(PDA_TEXT, 'subject "Hello" ', '', [])));
  FKit.Manager.Reload(False);
  // FreeData of an e-mail frees nothing (as the original): the subject of the first parse is still there
  Assert.AreEqual('Hello', string(LMail.GetSubject));
  Assert.AreEqual('abc', string(LMail.GetBody));
end;

procedure TTestDeclPda.DovrebbeSegnalareUnErroreDelLexerInOgniTipo;
const
  TYPES: array[0..3] of Integer = (DECL_PDA, DECL_VIDEO, DECL_AUDIO, DECL_EMAIL);
  NAMES: array[0..3] of string = ('PDA', 'Video', 'Audio', 'Email');
var
  LIndex: Integer;
  LDecl: IDecl;
begin
  for LIndex := 0 to High(TYPES) do
  begin
    FKit.Lines.Clear;
    LDecl := FKit.Manager.FindType(TYPES[LIndex], 'broken' + AnsiString(IntToStr(LIndex)));
    // an unterminated string is an error of the lexer, which is a warning here (no fatal errors)
    LDecl.SetText('x broken { name "never closed }');
    LDecl.Invalidate;
    LDecl.EnsureNotPurged;
    Assert.IsTrue(Pos(NAMES[LIndex] + ' decl ''broken' + IntToStr(LIndex) + ''' had a parse error', FKit.LogText) > 0,
      FKit.LogText);
  end;
end;

procedure TTestDeclPda.DovrebbeDareUnaDimensioneInMemoria;
var
  LIndex: Integer;
  LType: Integer;
begin
  for LType in [DECL_PDA, DECL_VIDEO, DECL_AUDIO, DECL_EMAIL, DECL_TABLE, DECL_SKIN, DECL_ENTITYDEF, DECL_MATERIAL] do
    Assert.IsTrue(FKit.Manager.FindType(LType, 'sized').Size > 0);
  LIndex := FKit.Manager.GetNumDecls(DECL_PDA);
  Assert.AreEqual(2, LIndex);
  FKit.Lines.Clear;
  FKit.Manager.ListType(DECL_PDA, dlmAll);
  Assert.IsTrue(Pos('P: sized\n', FKit.LogText) > 0, FKit.LogText);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclPda);

end.
