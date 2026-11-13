{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - TDeclManager, TDeclFile      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Manager;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Types,
  DelphiDoom.Tests.Decl.Support;

type
  [TestFixture]
  [Category('Decl')]
  TTestDeclManager = class
  strict private
    FKit: TDeclKit;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCanonizzareIlNome;
    [Test]
    procedure DovrebbeTroncareIlNomeLungo;
    [Test]
    procedure DovrebbeCrearePerDifettoUnaDichiarazioneMancante;
    [Test]
    procedure DovrebbeNonCrearePerDifettoSeRichiestoCosi;
    [Test]
    procedure DovrebbeUsareIlNomeVuotoPerNomeVuoto;
    [Test]
    procedure DovrebbeLeggereIlFileUnaSolaVolta;
    [Test]
    procedure DovrebbeInterpretareAllaPrimaRichiesta;
    [Test]
    procedure DovrebbeRestituireSempreLoStessoOggetto;
    [Test]
    procedure DovrebbeTenereIlTestoComprensivoDelCommentoPrecedente;
    [Test]
    procedure DovrebbeSegnalareUnTipoNonRegistrato;
    [Test]
    procedure DovrebbeIgnorareLaRegistrazioneDiUnTipoGiaPresente;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiTipoFuoriLimite;
    [Test]
    procedure DovrebbeTrovareTipoDaNomeEViceversa;
    [Test]
    procedure DovrebbeSegnalareUnaDefinizioneRipetutaNelloStessoFile;
    [Test]
    procedure DovrebbeSegnalareUnaDefinizioneRipetutaInUnAltroFile;
    [Test]
    procedure DovrebbeSaltareUnaParentesiSenzaNome;
    [Test]
    procedure DovrebbeSegnalareUnTipoSenzaDefinizioneAFineFile;
    [Test]
    procedure DovrebbeSegnalareUnaGraffaMancante;
    [Test]
    procedure DovrebbeUsareIlTipoDiDefaultDellaCartella;
    [Test]
    procedure DovrebbeSegnalareNessunTipoSenzaTipoDiDefault;
    [Test]
    procedure DovrebbeSaltareLeDichiarazioniDiModelExport;
    [Test]
    procedure DovrebbeCercareInTutteLeSottocartelleInOrdine;
    [Test]
    procedure DovrebbeNonRicaricareUnFileInvariato;
    [Test]
    procedure DovrebbeRicaricareUnFileCambiato;
    [Test]
    procedure DovrebbeRiparseSubitoUnaDichiarazioneInUso;
    [Test]
    procedure DovrebbeRendereDefaultUnaDichiarazioneTolta;
    [Test]
    procedure DovrebbeRicaricareUnFileDaNome;
    [Test]
    procedure DovrebbeSvuotareEIdentificareAlCaricoDelLivello;
    [Test]
    procedure DovrebbeNonSvuotareChiELettoFuoriDalCaricoDelLivello;
    [Test]
    procedure DovrebbeContareLeDichiarazioniEdArrivarciPerIndice;
    [Test]
    procedure DovrebbeNonInterpretareCercandoPerIndiceSenzaForzare;
    [Test]
    procedure DovrebbeSegnalareUnIndiceFuoriLimite;
    [Test]
    procedure DovrebbeCambiareIlChecksumCambiandoIlTesto;
    [Test]
    procedure DovrebbeEscludereDalChecksumLeImplicite;
    [Test]
    procedure DovrebbeEscludereDalChecksumLePda;
    [Test]
    procedure DovrebbeCreareUnaNuovaDichiarazione;
    [Test]
    procedure DovrebbeRestituireLaNuovaSeEsisteGia;
    [Test]
    procedure DovrebbeRinominareUnaDichiarazione;
    [Test]
    procedure DovrebbeRifiutareDiRinominareUnaMancante;
    [Test]
    procedure DovrebbeSostituireIlTestoNelFileSorgente;
    [Test]
    procedure DovrebbeRifiutareDiScrivereUnaImplicita;
    [Test]
    procedure DovrebbeRifiutareDiScrivereSeIlFileCambiato;
    [Test]
    procedure DovrebbeAccorgersiCheIlFileSorgenteCambia;
    [Test]
    procedure DovrebbeElencareLeDichiarazioni;
    [Test]
    procedure DovrebbeStampareUnaDichiarazione;
    [Test]
    procedure DovrebbeScrivereLeRigheDiTouch;
    [Test]
    procedure DovrebbeSegnalareIlFileCheNonSiLegge;
    [Test]
    procedure DovrebbeFermareUnaDefinizioneDiDefaultSenzaFine;
  end;

implementation

uses
  System.Classes, DelphiDoom.Decl.Manager, DelphiDoom.Decl.Base, DelphiDoom.Decl.Skin,
  DelphiDoom.Decl.Source.Memory;

type
  /// <summary>A type whose default definition parses by defaulting again: it never ends</summary>
  TRunawayDecl = class(TDecl)
  public
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
  end;

function TRunawayDecl.DefaultDefinition: AnsiString;
begin
  Result := '{ }';
end;

function TRunawayDecl.Parse(const AText: AnsiString): Boolean;
begin
  MakeDefault;
  Result := False;
end;

const
  FILE_SKINS = 'skins/a.skin';

{ TTestDeclManager }

procedure TTestDeclManager.Setup;
begin
  FKit := TDeclKit.Create;
end;

procedure TTestDeclManager.TearDown;
begin
  FreeAndNil(FKit);
end;

procedure TTestDeclManager.DovrebbeCanonizzareIlNome;
begin
  Assert.AreEqual('models/mon/imp', string(TDeclManager.MakeNameCanonical('Models\MON/Imp.TGA')));
  Assert.AreEqual('a.b', string(TDeclManager.MakeNameCanonical('A.B.c')));
  Assert.AreEqual('', string(TDeclManager.MakeNameCanonical('')));
  Assert.AreEqual('noext', string(TDeclManager.MakeNameCanonical('NoExt')));
end;

procedure TTestDeclManager.DovrebbeTroncareIlNomeLungo;
begin
  Assert.AreEqual<Integer>(1023, Length(TDeclManager.MakeNameCanonical(AnsiString(StringOfChar('x', 2000)))));
end;

procedure TTestDeclManager.DovrebbeCrearePerDifettoUnaDichiarazioneMancante;
var
  LDecl: IDecl;
begin
  FKit.Start(True, False);
  LDecl := FKit.Manager.FindType(DECL_ENTITYDEF, 'monster_nothing');
  Assert.IsTrue(Assigned(LDecl));
  Assert.IsTrue(LDecl.IsImplicit);
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  Assert.AreEqual('monster_nothing', string(LDecl.GetName));
  Assert.AreEqual('<implicit file>', string(LDecl.GetFileName));
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_ENTITYDEF));
end;

procedure TTestDeclManager.DovrebbeNonCrearePerDifettoSeRichiestoCosi;
begin
  FKit.Start(True, False);
  Assert.IsFalse(Assigned(FKit.Manager.FindType(DECL_ENTITYDEF, 'missing', False)));
  Assert.AreEqual(0, FKit.Manager.GetNumDecls(DECL_ENTITYDEF));
end;

procedure TTestDeclManager.DovrebbeUsareIlNomeVuotoPerNomeVuoto;
begin
  FKit.Start(True, False);
  Assert.AreEqual('_emptyname', string(FKit.Manager.FindType(DECL_TABLE, '').GetName));
end;

procedure TTestDeclManager.DovrebbeLeggereIlFileUnaSolaVolta;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'skin two { }');
  FKit.Start;
  Assert.AreEqual(1, FKit.Source.ReadCount);
  FKit.Manager.FindType(DECL_SKIN, 'one');
  FKit.Manager.FindType(DECL_SKIN, 'two');
  Assert.AreEqual(1, FKit.Source.ReadCount);
end;

procedure TTestDeclManager.DovrebbeInterpretareAllaPrimaRichiesta;
var
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { model "a" }');
  FKit.Start;
  LDecl := FKit.Manager.DeclByIndex(DECL_SKIN, 0, False);
  Assert.IsTrue(LDecl.GetState = dsUnparsed);
  Assert.IsFalse(LDecl.IsValid);
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'one');
  Assert.IsTrue(LDecl.GetState = dsParsed);
  Assert.IsTrue(LDecl.IsValid);
  Assert.IsTrue(LDecl.EverReferenced);
end;

procedure TTestDeclManager.DovrebbeRestituireSempreLoStessoOggetto;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  Assert.IsTrue(FKit.Manager.FindType(DECL_SKIN, 'one') = FKit.Manager.FindType(DECL_SKIN, 'ONE'));
  Assert.IsTrue(FKit.Manager.FindType(DECL_SKIN, 'one') = FKit.Manager.DeclByIndex(DECL_SKIN, 0));
end;

procedure TTestDeclManager.DovrebbeTenereIlTestoComprensivoDelCommentoPrecedente;
var
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'// about two'#10'skin two { model "x" }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'two');
  // the text starts where the previous declaration ended, as the original
  Assert.AreEqual(''#10'// about two'#10'skin two { model "x" }', string(LDecl.GetText));
  Assert.AreEqual(Length(LDecl.GetText), LDecl.GetTextLength);
  // and so does its line: the line the previous declaration ended on
  Assert.AreEqual(1, LDecl.GetLineNum);
end;

procedure TTestDeclManager.DovrebbeSegnalareUnTipoNonRegistrato;
begin
  FKit.Start(False);
  Assert.WillRaise(
    procedure
    begin
      FKit.Manager.FindType(DECL_SKIN, 'x');
    end, EDeclException);
  Assert.WillRaise(
    procedure
    begin
      FKit.Manager.GetNumDecls(77);
    end, EDeclException);
end;

procedure TTestDeclManager.DovrebbeIgnorareLaRegistrazioneDiUnTipoGiaPresente;
begin
  FKit.Start(False);
  FKit.Manager.GetRegistry.RegisterDeclType('first', DECL_FIRST_FREE, function: IDecl begin Result := TDecl.Create; end);
  FKit.Manager.GetRegistry.RegisterDeclType('second', DECL_FIRST_FREE, function: IDecl begin Result := TDecl.Create; end);
  Assert.AreEqual('first', string(FKit.Manager.GetRegistry.GetDeclNameFromType(DECL_FIRST_FREE)));
  Assert.IsTrue(Pos('type ''second'' already exists', FKit.LogText) > 0);
end;

procedure TTestDeclManager.DovrebbeRifiutareUnNumeroDiTipoFuoriLimite;
begin
  FKit.Start(False);
  Assert.WillRaise(
    procedure
    begin
      FKit.Manager.GetRegistry.RegisterDeclType('far', DECL_MAX_TYPES, function: IDecl begin Result := TDecl.Create; end);
    end, EDeclException);
end;

procedure TTestDeclManager.DovrebbeTrovareTipoDaNomeEViceversa;
begin
  FKit.Start(True, False);
  Assert.AreEqual(DECL_ENTITYDEF, FKit.Manager.GetRegistry.GetDeclTypeFromName('ENTITYDEF'));
  Assert.AreEqual(DECL_MAX_TYPES, FKit.Manager.GetRegistry.GetDeclTypeFromName('nothing'));
  Assert.AreEqual('articulatedFigure', string(FKit.Manager.GetRegistry.GetDeclNameFromType(DECL_AF)));
  Assert.AreEqual(DECL_MAPDEF + 1, FKit.Manager.GetRegistry.GetNumDeclTypes);
  // DECL_MODELDEF and DECL_MODELEXPORT are not registered: a gap
  Assert.WillRaise(
    procedure
    begin
      FKit.Manager.GetRegistry.GetDeclNameFromType(DECL_MODELDEF);
    end, EDeclException);
end;

procedure TTestDeclManager.DovrebbeSegnalareUnaDefinizioneRipetutaNelloStessoFile;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { model "first" }'#10'skin one { model "second" }');
  FKit.Start;
  Assert.IsTrue(Pos('skin ''one'' previously defined at skins/a.skin:1', FKit.LogText) > 0, FKit.LogText);
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_SKIN));
end;

procedure TTestDeclManager.DovrebbeSegnalareUnaDefinizioneRipetutaInUnAltroFile;
begin
  FKit.Source.Add('skins/a.skin', 'skin one { model "first" }');
  FKit.Source.Add('skins/b.skin', #10'skin one { model "second" }');
  FKit.Start;
  Assert.IsTrue(Pos('skin ''one'' previously defined at skins/a.skin:1', FKit.LogText) > 0, FKit.LogText);
  Assert.AreEqual('skins/a.skin', string(FKit.Manager.FindType(DECL_SKIN, 'one').GetFileName));
end;

procedure TTestDeclManager.DovrebbeSaltareUnaParentesiSenzaNome;
begin
  FKit.Source.Add(FILE_SKINS, 'skin { model "x" } skin ok { }');
  FKit.Start;
  Assert.IsTrue(Pos('Missing decl name', FKit.LogText) > 0);
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_SKIN));
  Assert.AreEqual('ok', string(FKit.Manager.DeclByIndex(DECL_SKIN, 0, False).GetName));
end;

procedure TTestDeclManager.DovrebbeSegnalareUnTipoSenzaDefinizioneAFineFile;
begin
  FKit.Source.Add(FILE_SKINS, 'skin ok { } skin');
  FKit.Start;
  Assert.IsTrue(Pos('Type without definition at end of file', FKit.LogText) > 0);
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_SKIN));
end;

procedure TTestDeclManager.DovrebbeSegnalareUnaGraffaMancante;
begin
  FKit.Source.Add(FILE_SKINS, 'skin broken oops skin ok { }');
  FKit.Start;
  Assert.IsTrue(Pos('Expecting ''{'' but found ''oops''', FKit.LogText) > 0, FKit.LogText);
  Assert.IsFalse(Assigned(FKit.Manager.FindType(DECL_SKIN, 'broken', False)));
end;

procedure TTestDeclManager.DovrebbeUsareIlTipoDiDefaultDellaCartella;
begin
  FKit.Source.Add(FILE_SKINS, 'plain { model "x" }');
  FKit.Start;
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_SKIN));
  Assert.AreEqual('plain', string(FKit.Manager.FindType(DECL_SKIN, 'plain', False).GetName));
end;

procedure TTestDeclManager.DovrebbeSegnalareNessunTipoSenzaTipoDiDefault;
begin
  FKit.Source.Add('defs/a.def', 'plain { }');
  FKit.Start(True, False);
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_MAX_TYPES);
  Assert.IsTrue(Pos('No type', FKit.LogText) > 0);
  Assert.AreEqual(0, FKit.Manager.GetNumDecls(DECL_ENTITYDEF));
end;

procedure TTestDeclManager.DovrebbeSaltareLeDichiarazioniDiModelExport;
begin
  FKit.Source.Add('defs/a.def', 'entityDef one { "a" "1" }');
  FKit.Start(True, False);
  FKit.Manager.GetRegistry.RegisterDeclType('export', DECL_MODELEXPORT, function: IDecl begin Result := TDecl.Create; end);
  FKit.Source.Add('defs/b.def', 'export skip { "x" }'#10'entityDef two { }');
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_ENTITYDEF);
  Assert.AreEqual(2, FKit.Manager.GetNumDecls(DECL_ENTITYDEF));
  Assert.AreEqual(0, FKit.Manager.GetNumDecls(DECL_MODELEXPORT));
end;

procedure TTestDeclManager.DovrebbeCercareInTutteLeSottocartelleInOrdine;
begin
  FKit.Source.Add('skins/z.skin', 'skin zed { }');
  FKit.Source.Add('skins/sub/b.skin', 'skin bee { }');
  FKit.Source.Add('skins/A.SKIN', 'skin ay { }');
  FKit.Source.Add('skins/other.txt', 'skin no { }');
  FKit.Start;
  Assert.AreEqual(3, FKit.Manager.GetNumDecls(DECL_SKIN));
  Assert.AreEqual('ay', string(FKit.Manager.DeclByIndex(DECL_SKIN, 0, False).GetName));
  Assert.AreEqual('bee', string(FKit.Manager.DeclByIndex(DECL_SKIN, 1, False).GetName));
  Assert.AreEqual('zed', string(FKit.Manager.DeclByIndex(DECL_SKIN, 2, False).GetName));
  Assert.AreEqual('skins/sub/b.skin', string(FKit.Manager.DeclByIndex(DECL_SKIN, 1, False).GetFileName));
end;

procedure TTestDeclManager.DovrebbeNonRicaricareUnFileInvariato;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  FKit.Manager.Reload(False);
  Assert.AreEqual(1, FKit.Source.ReadCount);
  FKit.Manager.Reload(True);
  Assert.AreEqual(2, FKit.Source.ReadCount);
end;

procedure TTestDeclManager.DovrebbeRicaricareUnFileCambiato;
var
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { model "a" }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'one');
  FKit.Source.Add(FILE_SKINS, 'skin one { model "a" model "b" }'#10'skin two { }');
  FKit.Manager.Reload(False);
  Assert.AreEqual(2, FKit.Manager.GetNumDecls(DECL_SKIN));
  Assert.AreEqual('skin one { model "a" model "b" }', string(LDecl.GetText));
end;

procedure TTestDeclManager.DovrebbeRiparseSubitoUnaDichiarazioneInUso;
var
  LSkin: IDeclSkin;
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { model "a" }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'one');
  FKit.Source.Add(FILE_SKINS, 'skin one { model "b" }');
  FKit.Manager.Reload(False);
  // reparsed in place: no new FindType needed
  Assert.IsTrue(LDecl.GetState = dsParsed);
  Assert.IsTrue(Supports(LDecl, IDeclSkin, LSkin));
  Assert.AreEqual('b', string(LSkin.GetAssociatedModel(0)));
end;

procedure TTestDeclManager.DovrebbeRendereDefaultUnaDichiarazioneTolta;
var
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { model "a" }'#10'skin two { }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'two');
  FKit.Source.Add(FILE_SKINS, 'skin one { model "a" }');
  FKit.Manager.Reload(False);
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  // a declaration that lost its text sits at the end of its file
  Assert.AreEqual(1, LDecl.GetLineNum);
end;

procedure TTestDeclManager.DovrebbeRicaricareUnFileDaNome;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'skin two { }');
  FKit.Manager.ReloadFile('SKINS/A.SKIN', False);
  Assert.AreEqual(2, FKit.Manager.GetNumDecls(DECL_SKIN));
  FKit.Manager.ReloadFile('skins/none.skin', False);
end;

procedure TTestDeclManager.DovrebbeSvuotareEIdentificareAlCaricoDelLivello;
var
  LDecl: IDecl;
begin
  FKit.Start(True, False);
  FKit.Manager.BeginLevelLoad;
  LDecl := FKit.Manager.FindType(DECL_ENTITYDEF, 'in_level');
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  FKit.Manager.EndLevelLoad;
  FKit.Manager.BeginLevelLoad;
  // purged: the next find parses again
  Assert.IsTrue(LDecl.GetState = dsUnparsed);
  FKit.Manager.FindType(DECL_ENTITYDEF, 'in_level');
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  FKit.Manager.EndLevelLoad;
end;

procedure TTestDeclManager.DovrebbeNonSvuotareChiELettoFuoriDalCaricoDelLivello;
var
  LDecl: IDecl;
begin
  FKit.Start(True, False);
  LDecl := FKit.Manager.FindType(DECL_ENTITYDEF, 'menu_graphic');
  FKit.Manager.BeginLevelLoad;
  Assert.IsTrue(LDecl.GetState = dsDefaulted);
  FKit.Manager.EndLevelLoad;
end;

procedure TTestDeclManager.DovrebbeContareLeDichiarazioniEdArrivarciPerIndice;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'skin two { }');
  FKit.Start;
  Assert.AreEqual(2, FKit.Manager.GetNumDecls(DECL_SKIN));
  Assert.AreEqual(0, FKit.Manager.DeclByIndex(DECL_SKIN, 0).GetIndex);
  Assert.AreEqual(1, FKit.Manager.DeclByIndex(DECL_SKIN, 1).GetIndex);
end;

procedure TTestDeclManager.DovrebbeNonInterpretareCercandoPerIndiceSenzaForzare;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  FKit.Manager.DeclByIndex(DECL_SKIN, 0, False);
  Assert.IsTrue(FKit.Manager.DeclByIndex(DECL_SKIN, 0, False).GetState = dsUnparsed);
  Assert.IsFalse(FKit.Manager.DeclByIndex(DECL_SKIN, 0, False).EverReferenced);
end;

procedure TTestDeclManager.DovrebbeSegnalareUnIndiceFuoriLimite;
begin
  FKit.Start(True, False);
  Assert.WillRaise(
    procedure
    begin
      FKit.Manager.DeclByIndex(DECL_SKIN, 0);
    end, EDeclException);
end;

procedure TTestDeclManager.DovrebbeCambiareIlChecksumCambiandoIlTesto;
var
  LBefore, LAfter: Integer;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { model "a" }');
  FKit.Start;
  LBefore := FKit.Manager.GetChecksum;
  Assert.AreEqual(LBefore, FKit.Manager.GetChecksum);
  FKit.Source.Add(FILE_SKINS, 'skin one { model "b" }');
  FKit.Manager.Reload(False);
  LAfter := FKit.Manager.GetChecksum;
  Assert.AreNotEqual(LBefore, LAfter);
end;

procedure TTestDeclManager.DovrebbeEscludereDalChecksumLeImplicite;
var
  LBefore: Integer;
begin
  FKit.Start(True, False);
  LBefore := FKit.Manager.GetChecksum;
  FKit.Manager.FindType(DECL_ENTITYDEF, 'implicit_one');
  Assert.AreEqual(LBefore, FKit.Manager.GetChecksum);
end;

procedure TTestDeclManager.DovrebbeEscludereDalChecksumLePda;
var
  LBefore: Integer;
begin
  FKit.Source.Add('defs/a.def', 'entityDef one { }');
  FKit.Start(True, False);
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_ENTITYDEF);
  LBefore := FKit.Manager.GetChecksum;
  FKit.Source.Add('defs/p.def', 'pda mine { name "x" }');
  FKit.Manager.GetRegistry.RegisterDeclFolder('defs', '.def', DECL_ENTITYDEF);
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_PDA));
  Assert.AreEqual(LBefore, FKit.Manager.GetChecksum);
end;

procedure TTestDeclManager.DovrebbeCreareUnaNuovaDichiarazione;
var
  LDecl: IDecl;
begin
  FKit.Start(True, False);
  LDecl := FKit.Manager.CreateNewDecl(DECL_SKIN, 'New\Skin.Ext', 'skins\fresh.skin');
  Assert.AreEqual('new/skin', string(LDecl.GetName));
  Assert.AreEqual('skins/fresh.skin', string(LDecl.GetFileName));
  Assert.AreEqual('skin new/skin {'#10#9'"*"'#9'"_default"'#10'}', string(LDecl.GetText));
  Assert.IsTrue(LDecl.GetState = dsParsed);
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_SKIN));
  Assert.AreEqual(0, LDecl.GetIndex);
  Assert.IsFalse(LDecl.IsImplicit);
end;

procedure TTestDeclManager.DovrebbeRestituireLaNuovaSeEsisteGia;
begin
  FKit.Start(True, False);
  Assert.IsTrue(FKit.Manager.CreateNewDecl(DECL_SKIN, 'a', 'skins/x.skin') =
    FKit.Manager.CreateNewDecl(DECL_SKIN, 'A', 'skins/y.skin'));
  Assert.AreEqual(1, FKit.Manager.GetNumDecls(DECL_SKIN));
end;

procedure TTestDeclManager.DovrebbeRinominareUnaDichiarazione;
var
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'skin two { }'#10'skin three { }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'two');
  Assert.IsTrue(FKit.Manager.RenameDecl(DECL_SKIN, 'two', 'Renamed'));
  Assert.AreEqual('renamed', string(LDecl.GetName));
  Assert.IsTrue(FKit.Manager.FindType(DECL_SKIN, 'renamed', False) = LDecl);
  Assert.IsFalse(Assigned(FKit.Manager.FindType(DECL_SKIN, 'two', False)));
  Assert.IsTrue(Assigned(FKit.Manager.FindType(DECL_SKIN, 'one', False)));
  Assert.IsTrue(Assigned(FKit.Manager.FindType(DECL_SKIN, 'three', False)));
end;

procedure TTestDeclManager.DovrebbeRifiutareDiRinominareUnaMancante;
begin
  FKit.Start(True, False);
  Assert.IsFalse(FKit.Manager.RenameDecl(DECL_SKIN, 'nothing', 'x'));
end;

procedure TTestDeclManager.DovrebbeSostituireIlTestoNelFileSorgente;
var
  LDecl: IDecl;
  LText: AnsiString;
  LTime: Int64;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'skin two { }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'one');
  LDecl.SetText('skin one { model "longer text" }');
  Assert.IsTrue(LDecl.ReplaceSourceFileText);
  FKit.Source.TryReadFile(FILE_SKINS, LText, LTime);
  Assert.AreEqual('skin one { model "longer text" }'#10'skin two { }', string(LText));
  // the offsets of the other declarations moved with it: a second replace on "two" keeps the first
  FKit.Manager.FindType(DECL_SKIN, 'two').SetText(#10'skin two { model "x" }');
  Assert.IsTrue(FKit.Manager.FindType(DECL_SKIN, 'two').ReplaceSourceFileText);
  FKit.Source.TryReadFile(FILE_SKINS, LText, LTime);
  Assert.AreEqual('skin one { model "longer text" }'#10'skin two { model "x" }', string(LText));
  Assert.IsFalse(LDecl.SourceFileChanged);
end;

procedure TTestDeclManager.DovrebbeRifiutareDiScrivereUnaImplicita;
var
  LDecl: IDecl;
begin
  FKit.Start(True, False);
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'nowhere');
  Assert.IsFalse(LDecl.ReplaceSourceFileText);
  Assert.IsTrue(Pos('Can''t save implicit declaration nowhere.', FKit.LogText) > 0);
end;

procedure TTestDeclManager.DovrebbeRifiutareDiScrivereSeIlFileCambiato;
var
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'one');
  FKit.Source.Add(FILE_SKINS, 'skin one { } // edited elsewhere');
  Assert.IsFalse(LDecl.ReplaceSourceFileText);
  Assert.IsTrue(Pos('has been modified outside of the engine', FKit.LogText) > 0);
end;

procedure TTestDeclManager.DovrebbeAccorgersiCheIlFileSorgenteCambia;
var
  LDecl: IDecl;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  LDecl := FKit.Manager.FindType(DECL_SKIN, 'one');
  Assert.IsFalse(LDecl.SourceFileChanged);
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  Assert.IsTrue(LDecl.SourceFileChanged);
  FKit.Source.Remove(FILE_SKINS);
  Assert.IsTrue(LDecl.SourceFileChanged);
  Assert.IsFalse(FKit.Manager.FindType(DECL_SKIN, 'implicit').SourceFileChanged);
end;

procedure TTestDeclManager.DovrebbeElencareLeDichiarazioni;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'skin two { }');
  FKit.Start;
  FKit.Manager.FindType(DECL_SKIN, 'two');
  FKit.Lines.Clear;
  FKit.Manager.ListType(DECL_SKIN, dlmAll);
  // one (unparsed, never referenced) and two (parsed, referenced)
  Assert.IsTrue(Pos('P:    0: ', FKit.LogText) > 0, FKit.LogText);
  Assert.IsTrue(Pos('P: one\n', FKit.LogText) > 0, FKit.LogText);
  Assert.IsTrue(Pos('P: *', FKit.LogText) > 0, FKit.LogText);
  Assert.IsTrue(Pos('P: two\n', FKit.LogText) > 0, FKit.LogText);
  Assert.IsTrue(Pos('P: 2 of 2 skin\n', FKit.LogText) > 0, FKit.LogText);
  FKit.Lines.Clear;
  FKit.Manager.ListType(DECL_SKIN, dlmCurrent);
  Assert.IsTrue(Pos('P: 1 of 2 skin\n', FKit.LogText) > 0, FKit.LogText);
end;

procedure TTestDeclManager.DovrebbeStampareUnaDichiarazione;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  FKit.Lines.Clear;
  FKit.Manager.PrintType(DECL_SKIN, 'one');
  Assert.IsTrue(Pos('source: skins/a.skin:1', FKit.LogText) > 0);
  Assert.IsTrue(Pos('Unparsed.', FKit.LogText) > 0);
  Assert.IsTrue(Pos('Never referenced.', FKit.LogText) > 0);
  FKit.Lines.Clear;
  FKit.Manager.PrintType(DECL_SKIN, 'none');
  Assert.IsTrue(Pos('skin ''none'' not found.', FKit.LogText) > 0);
end;

procedure TTestDeclManager.DovrebbeScrivereLeRigheDiTouch;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }'#10'skin two { }');
  FKit.Start;
  FKit.Manager.FindType(DECL_SKIN, 'two');
  Assert.AreEqual('touch skin two'#10, string(FKit.Manager.WritePrecacheCommands));
end;

procedure TTestDeclManager.DovrebbeSegnalareIlFileCheNonSiLegge;
begin
  FKit.Source.Add(FILE_SKINS, 'skin one { }');
  FKit.Start;
  FKit.Source.Remove(FILE_SKINS);
  Assert.WillRaise(
    procedure
    begin
      FKit.Manager.Reload(True);
    end, EDeclException);
end;

procedure TTestDeclManager.DovrebbeFermareUnaDefinizioneDiDefaultSenzaFine;
begin
  FKit.Start(False);
  FKit.Manager.GetRegistry.RegisterDeclType('runaway', DECL_FIRST_FREE,
    function: IDecl begin Result := TRunawayDecl.Create; end);
  Assert.WillRaise(
    procedure
    begin
      FKit.Manager.FindType(DECL_FIRST_FREE, 'loop');
    end, EDeclException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclManager);

end.
