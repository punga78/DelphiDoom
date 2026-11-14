{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the entities linked into the areas   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Links;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Links,
  DelphiDoom.Tests.Aas.Support;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasEntityLinks = class
  strict private
    FImport: TFakeImport;
    FImportIntf: IBotImport;
    function Links(const AMaxLinks: Integer; const AChain: Integer = 0): TAasEntityLinks;
    function Count(const AHead: Integer): Integer;
    function HasMessage(const AText: string): Boolean;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeCollegareUnaEntitaATutteLeAreeCheTocca;
    [Test]
    procedure DovrebbeRestituireLaListaVuotaPerUnBoxFuoriDalMondo;
    [Test]
    procedure UnaSecondaChiamataConLaStessaEntitaNonDovrebbeCreareAltriLink;
    [Test]
    procedure DovrebbeRestituireIlPezzoCollegatoQuandoLHeapEPieno;
    [Test]
    procedure DovrebbeStampareUnErroreQuandoLoStackDiCollegamentoStraripa;
    [Test]
    procedure DovrebbeRestituireTuttiILinkAllHeapInOgniOrdineDiRilascio;
    [Test]
    procedure DovrebbeAllargareIlBoxDelTipoDiPresenza;
    [Test]
    procedure UnLinkFuoriDallHeapDovrebbeSollevareUnEccezione;
    [Test]
    procedure UnHeapDaUnoODueLinkDovrebbeEssereCollegatoCometheNelloOriginale;
  end;

implementation

uses
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Types, DelphiDoom.Tests.Aas.Sample, DelphiDoom.Tests.Aas.Sampling;

var
  GHolder: IAasFile;

{ TTestAasEntityLinks }

procedure TTestAasEntityLinks.Setup;
begin
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
end;

function TTestAasEntityLinks.Links(const AMaxLinks, AChain: Integer): TAasEntityLinks;
begin
  if AChain > 0 then
    GHolder := TAasWorlds.Chain(AChain)
  else
    GHolder := TAasWorlds.Sample(0);
  Result := TAasEntityLinks.Create(GHolder, FImportIntf, AMaxLinks, True);
end;

function TTestAasEntityLinks.Count(const AHead: Integer): Integer;
begin
  Result := 0;
  // not a method of the class: the tests walk the list with the links they have
end;

function TTestAasEntityLinks.HasMessage(const AText: string): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FImport.Count - 1 do
    if Pos(AText, FImport.Message(LIndex)) > 0 then
      Exit(True);
  Result := False;
end;

procedure TTestAasEntityLinks.DovrebbeCollegareUnaEntitaATutteLeAreeCheTocca;
var
  LLinks: TAasEntityLinks;
  LHead, LLink, LNumber: Integer;
begin
  LLinks := Links(100);
  try
    LHead := LLinks.LinkEntity(Vec(10, 10, 10), Vec(200, 50, 50), 7);
    LNumber := 0;
    LLink := LHead;
    while LLink <> AAS_NO_LINK do
    begin
      Assert.AreEqual<Integer>(7, LLinks.EntNum(LLink));
      Inc(LNumber);
      LLink := LLinks.NextArea(LLink);
    end;
    // the box goes through the four areas of the row
    Assert.AreEqual<Integer>(4, LNumber);
    Assert.AreEqual<Integer>(96, LLinks.FreeCount);
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LLinks.AreaHead(1));
    Assert.AreEqual<Integer>(7, LLinks.EntNum(LLinks.AreaHead(1)));
    Assert.AreEqual<Integer>(AAS_NO_LINK, LLinks.NextEnt(LLinks.AreaHead(1)));
    LLinks.Unlink(LHead);
    Assert.AreEqual<Integer>(100, LLinks.FreeCount);
    Assert.AreEqual<Integer>(AAS_NO_LINK, LLinks.AreaHead(1));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.DovrebbeRestituireLaListaVuotaPerUnBoxFuoriDalMondo;
var
  LLinks: TAasEntityLinks;
begin
  LLinks := Links(10);
  try
    Assert.AreEqual<Integer>(AAS_NO_LINK, LLinks.LinkEntity(Vec(1000, 1000, 1000), Vec(1010, 1010, 1010), 3));
    Assert.AreEqual<Integer>(10, LLinks.FreeCount);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.UnaSecondaChiamataConLaStessaEntitaNonDovrebbeCreareAltriLink;
var
  LLinks: TAasEntityLinks;
  LFirst, LSecond: Integer;
begin
  LLinks := Links(100);
  try
    LFirst := LLinks.LinkEntity(Vec(10, 10, 10), Vec(100, 50, 50), 5);
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LFirst);
    // the entity is in these areas already: nothing is linked again
    LSecond := LLinks.LinkEntity(Vec(10, 10, 10), Vec(100, 50, 50), 5);
    Assert.AreEqual<Integer>(AAS_NO_LINK, LSecond);
    Assert.AreEqual<Integer>(98, LLinks.FreeCount);
    // another entity gets links of its own in the same areas
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LLinks.LinkEntity(Vec(10, 10, 10), Vec(100, 50, 50), 6));
    Assert.AreEqual<Integer>(96, LLinks.FreeCount);
    LLinks.Unlink(LFirst);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.DovrebbeRestituireIlPezzoCollegatoQuandoLHeapEPieno;
var
  LLinks: TAasEntityLinks;
  LHead: Integer;
begin
  LLinks := Links(2);
  try
    LHead := LLinks.LinkEntity(Vec(10, 10, 10), Vec(200, 50, 50), 9);
    // two links only: the third is not made and the list has the two that were
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LHead);
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LLinks.NextArea(LHead));
    Assert.AreEqual<Integer>(AAS_NO_LINK, LLinks.NextArea(LLinks.NextArea(LHead)));
    Assert.AreEqual<Integer>(0, LLinks.FreeCount);
    Assert.IsTrue(HasMessage('empty aas link heap'));
    LLinks.Unlink(LHead);
    Assert.AreEqual<Integer>(2, LLinks.FreeCount);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.DovrebbeStampareUnErroreQuandoLoStackDiCollegamentoStraripa;
var
  LLinks: TAasEntityLinks;
begin
  LLinks := Links(100, 140);
  try
    LLinks.LinkEntity(Vec(300, 0, 0), Vec(1000, 10, 10), 1);
    Assert.IsTrue(HasMessage('stack overflow'));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.DovrebbeRestituireTuttiILinkAllHeapInOgniOrdineDiRilascio;
var
  LLinks: TAasEntityLinks;
  LA, LB: Integer;
begin
  LLinks := Links(50);
  try
    LA := LLinks.LinkEntity(Vec(10, 10, 10), Vec(130, 50, 50), 1);
    LB := LLinks.LinkEntity(Vec(70, 10, 10), Vec(200, 50, 50), 2);
    // the second area has the links of both entities, the one linked last first
    Assert.AreEqual<Integer>(2, LLinks.EntNum(LLinks.AreaHead(2)));
    Assert.AreEqual<Integer>(1, LLinks.EntNum(LLinks.NextEnt(LLinks.AreaHead(2))));
    // the first entity goes first, which is not the order of the lists of the areas
    LLinks.Unlink(LA);
    Assert.AreEqual<Integer>(2, LLinks.EntNum(LLinks.AreaHead(2)));
    Assert.AreEqual<Integer>(AAS_NO_LINK, LLinks.NextEnt(LLinks.AreaHead(2)));
    LLinks.Unlink(LB);
    Assert.AreEqual<Integer>(50, LLinks.FreeCount);
    // the other way round
    LA := LLinks.LinkEntity(Vec(10, 10, 10), Vec(130, 50, 50), 1);
    LB := LLinks.LinkEntity(Vec(70, 10, 10), Vec(200, 50, 50), 2);
    LLinks.Unlink(LB);
    Assert.AreEqual<Integer>(1, LLinks.EntNum(LLinks.AreaHead(2)));
    LLinks.Unlink(LA);
    Assert.AreEqual<Integer>(50, LLinks.FreeCount);
    Assert.AreEqual<Integer>(AAS_NO_LINK, LLinks.AreaHead(2));
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.DovrebbeAllargareIlBoxDelTipoDiPresenza;
var
  LLinks: TAasEntityLinks;
  LHead: Integer;
begin
  LLinks := Links(20);
  try
    // a point at 70 is in the second area; the box of the client is 15 units wide: it touches the first too
    LHead := LLinks.LinkEntityClientBBox(Vec(70, 30, 30), Vec(70, 30, 30), 4, PRESENCE_NORMAL);
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LHead);
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LLinks.NextArea(LHead));
    Assert.AreEqual<Integer>(4, LLinks.EntNum(LHead));
    Assert.IsTrue(LLinks.AreaNum(LHead) > 0);
    LLinks.Unlink(LHead);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.UnLinkFuoriDallHeapDovrebbeSollevareUnEccezione;
var
  LLinks: TAasEntityLinks;
begin
  LLinks := Links(5);
  try
    Assert.WillRaise(procedure begin LLinks.NextArea(99); end, EAasLinkException);
    Assert.WillRaise(procedure begin LLinks.AreaHead(99); end, EAasLinkException);
    Assert.WillRaise(procedure begin LLinks.Unlink(99); end, EAasLinkException);
  finally
    LLinks.Free;
  end;
end;

procedure TTestAasEntityLinks.UnHeapDaUnoODueLinkDovrebbeEssereCollegatoCometheNelloOriginale;
var
  LLinks: TAasEntityLinks;
  LHead: Integer;
begin
  LLinks := Links(1);
  try
    LHead := LLinks.LinkEntity(Vec(10, 10, 10), Vec(30, 50, 50), 2);
    Assert.AreNotEqual<Integer>(AAS_NO_LINK, LHead);
    Assert.AreEqual<Integer>(0, LLinks.FreeCount);
    LLinks.Unlink(LHead);
    Assert.AreEqual<Integer>(1, LLinks.FreeCount);
  finally
    LLinks.Free;
  end;
  LLinks := Links(0);
  try
    Assert.AreEqual<Integer>(AAS_NO_LINK, LLinks.LinkEntity(Vec(10, 10, 10), Vec(30, 50, 50), 2));
    Assert.IsTrue(HasMessage('empty aas link heap'));
  finally
    LLinks.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasEntityLinks);

end.
