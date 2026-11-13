{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the parser of ANIMDEFS       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.AnimDefsParser;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf, DelphiDoom.Definitions.Factory, DelphiDoom.Tests.Definitions.Fakes;

type
  [TestFixture]
  [Category('definitions')]
  TTestAnimDefsParser = class(TObject)
  private
    FCatalog: TFakeCatalog;
    FCatalogIntf: IDefAnimNameCatalog;
    FLog: TFakeLog;
    FLogIntf: ILog;
    function Parse(const AText: string): TArray<TDefAnimation>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestUnTestoVuotoNonHaAnimazioni;
    [Test]
    procedure TestUnaAnimazioneDiFlatHaITicsDelleSueRighe;
    [Test]
    procedure TestUnaAnimazioneDiTexturePortaIlTipoTexture;
    [Test]
    procedure TestIlNumeroDellImmagineEQuelloDellaRigaPic;
    [Test]
    procedure TestRandDiventaIlMinimoELaDimensioneDellIntervallo;
    [Test]
    procedure TestIlRandConMassimoSottoIlMinimoDaUnIntervalloDiUno;
    [Test]
    procedure TestUnTicsSopra255SiLeggeComeRandomNelFormatoVecchio;
    [Test]
    procedure TestLeParoleChiaveNonDistinguonoLeMaiuscole;
    [Test]
    procedure TestICommentiELeRigheVuoteSonoIgnorati;
    [Test]
    procedure TestUnLAnimazioneConNomeAssenteNelGiocoVieneIgnorata;
    [Test]
    procedure TestUnaAnimazioneIgnorataNonContaPerIlMinimoDiDueFrame;
    [Test]
    procedure TestIlNomeDiUnFlatSiChiedeAllElencoDeiFlat;
    [Test]
    procedure TestIlNomeDiUnaTextureSiChiedeAllElencoDelleTexture;
    [Test]
    procedure TestGliOffsetAnimatiSonoLaBaseELeRigheDiPic;
    [Test]
    procedure TestUnaRigaPicSbagliataTieneLOffsetMaNonIlFrame;
    [Test]
    procedure TestUnaAnimazioneConUnSoloFrameDaErrore;
    [Test]
    procedure TestTroppeAnimazioniDannoErrore;
    [Test]
    procedure TestTroppiFrameDannoErrore;
    [Test]
    procedure TestUnTipoSconosciutoDaUnAvvisoELaLetturaContinua;
    [Test]
    procedure TestUnTipoSconosciutoUsaIlTipoDelloSlotDellaVecchiaAnimazione;
    [Test]
    procedure TestUnNumeroMancanteDaUnAvvisoELaLetturaContinua;
    [Test]
    procedure TestSenzaLogGliAvvisiNonFannoDanni;
    [Test]
    procedure TestDueLettureNonSiInfluenzano;
    [Test]
    procedure TestIFineRigaCrLfEdLfSonoLoStesso;
  end;

implementation

{ TTestAnimDefsParser }

procedure TTestAnimDefsParser.Setup;
begin
  FCatalog := TFakeCatalog.Create(['FWATER1', 'FWATER2', 'LAVA1'], ['BLODGR1', 'BLODGR2', 'SLADRIP1']);
  FCatalogIntf := FCatalog;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
end;

procedure TTestAnimDefsParser.TearDown;
begin
  FLogIntf := nil;
  FCatalogIntf := nil;
end;

function TTestAnimDefsParser.Parse(const AText: string): TArray<TDefAnimation>;
begin
  Result := TDefinitionsFactory.CreateAnimDefsParser(FCatalogIntf, FLogIntf).Parse(AText);
end;

procedure TTestAnimDefsParser.TestUnTestoVuotoNonHaAnimazioni;
begin
  Assert.AreEqual<Integer>(0, Length(Parse('')));
  Assert.AreEqual<Integer>(0, Length(Parse('// solo un commento'#13#10)));
end;

procedure TTestAnimDefsParser.TestUnaAnimazioneDiFlatHaITicsDelleSueRighe;
var
  LAnimations: TArray<TDefAnimation>;
begin
  LAnimations := Parse('flat FWATER1 pic 1 tics 8 pic 2 tics 16 pic 3 tics 4');
  Assert.AreEqual<Integer>(1, Length(LAnimations));
  Assert.IsTrue(LAnimations[0].Kind = TDefAnimKind.Flat);
  Assert.AreEqual('FWATER1', LAnimations[0].Name);
  Assert.AreEqual<Integer>(3, Length(LAnimations[0].Frames));
  Assert.AreEqual(8, LAnimations[0].Frames[0].Tics);
  Assert.AreEqual(16, LAnimations[0].Frames[1].Tics);
  Assert.AreEqual(4, LAnimations[0].Frames[2].PackedTics);
end;

procedure TTestAnimDefsParser.TestUnaAnimazioneDiTexturePortaIlTipoTexture;
var
  LAnimations: TArray<TDefAnimation>;
begin
  LAnimations := Parse('texture BLODGR1 pic 1 tics 8 pic 2 tics 8');
  Assert.IsTrue(LAnimations[0].Kind = TDefAnimKind.Texture);
end;

procedure TTestAnimDefsParser.TestIlNumeroDellImmagineEQuelloDellaRigaPic;
var
  LAnimations: TArray<TDefAnimation>;
begin
  LAnimations := Parse('flat FWATER1 pic 3 tics 8 pic 1 tics 8');
  Assert.AreEqual(3, LAnimations[0].Frames[0].PicNumber);
  Assert.AreEqual(1, LAnimations[0].Frames[1].PicNumber);
end;

procedure TTestAnimDefsParser.TestRandDiventaIlMinimoELaDimensioneDellIntervallo;
var
  LFrame: TDefAnimFrame;
begin
  LFrame := Parse('flat LAVA1 pic 1 rand 5 10 pic 2 tics 1')[0].Frames[0];
  Assert.IsTrue(LFrame.IsRandom);
  Assert.AreEqual(5, LFrame.Tics);
  Assert.AreEqual(10, LFrame.RandomMax);
  Assert.AreEqual(5 * 65536 + 6 * 256, LFrame.PackedTics);
end;

procedure TTestAnimDefsParser.TestIlRandConMassimoSottoIlMinimoDaUnIntervalloDiUno;
var
  LFrame: TDefAnimFrame;
begin
  LFrame := Parse('flat LAVA1 pic 1 rand 10 5 pic 2 tics 1')[0].Frames[0];
  Assert.AreEqual(10 * 65536 - 4 * 256, LFrame.PackedTics);
end;

procedure TTestAnimDefsParser.TestUnTicsSopra255SiLeggeComeRandomNelFormatoVecchio;
var
  LFrame: TDefAnimFrame;
begin
  LFrame := Parse('flat LAVA1 pic 1 tics 300 pic 2 tics 1')[0].Frames[0];
  Assert.IsFalse(LFrame.IsRandom);
  Assert.AreEqual(300, LFrame.PackedTics, 'il valore e quello scritto: e il motore che lo legge come random');
end;

procedure TTestAnimDefsParser.TestLeParoleChiaveNonDistinguonoLeMaiuscole;
begin
  Assert.AreEqual<Integer>(2, Length(Parse('FLAT fwater1 PIC 1 TICS 8 Pic 2 Tics 8')[0].Frames));
end;

procedure TTestAnimDefsParser.TestICommentiELeRigheVuoteSonoIgnorati;
begin
  Assert.AreEqual<Integer>(2, Length(Parse('// acqua'#13#10#13#10'flat FWATER1 // sopra'#13#10'  pic 1 tics 8 ; x'#13#10 +
    '  pic 2 tics 8'#13#10'  // pic 3 tics 8'#13#10)[0].Frames));
end;

procedure TTestAnimDefsParser.TestUnLAnimazioneConNomeAssenteNelGiocoVieneIgnorata;
var
  LAnimations: TArray<TDefAnimation>;
begin
  LAnimations := Parse('flat NOSUCH pic 1 tics 8 pic 2 tics 8 texture BLODGR1 pic 1 tics 8 pic 2 tics 8');
  Assert.AreEqual<Integer>(1, Length(LAnimations));
  Assert.AreEqual('BLODGR1', LAnimations[0].Name);
end;

procedure TTestAnimDefsParser.TestUnaAnimazioneIgnorataNonContaPerIlMinimoDiDueFrame;
begin
  Assert.AreEqual<Integer>(0, Length(Parse('flat NOSUCH pic 1 tics 8')));
end;

procedure TTestAnimDefsParser.TestIlNomeDiUnFlatSiChiedeAllElencoDeiFlat;
begin
  Assert.AreEqual<Integer>(0, Length(Parse('flat BLODGR1 pic 1 tics 8 pic 2 tics 8')), 'BLODGR1 e una texture');
end;

procedure TTestAnimDefsParser.TestIlNomeDiUnaTextureSiChiedeAllElencoDelleTexture;
begin
  Assert.AreEqual<Integer>(0, Length(Parse('texture FWATER1 pic 1 tics 8 pic 2 tics 8')), 'FWATER1 e un flat');
end;

procedure TTestAnimDefsParser.TestGliOffsetAnimatiSonoLaBaseELeRigheDiPic;
var
  LOffsets: TArray<Integer>;
begin
  LOffsets := Parse('flat FWATER1 pic 1 tics 8 pic 3 tics 8 pic 2 tics 8')[0].AnimatedOffsets;
  Assert.AreEqual<Integer>(4, Length(LOffsets));
  Assert.AreEqual(0, LOffsets[0]);
  Assert.AreEqual(0, LOffsets[1]);
  Assert.AreEqual(2, LOffsets[2]);
  Assert.AreEqual(1, LOffsets[3]);
end;

procedure TTestAnimDefsParser.TestUnaRigaPicSbagliataTieneLOffsetMaNonIlFrame;
var
  LAnimation: TDefAnimation;
begin
  LAnimation := Parse('flat FWATER1 pic 1 tics 8 pic 7 foo pic 2 tics 8 pic 3 tics 8')[0];
  Assert.AreEqual<Integer>(3, Length(LAnimation.Frames));
  Assert.AreEqual<Integer>(5, Length(LAnimation.AnimatedOffsets));
  Assert.AreEqual(6, LAnimation.AnimatedOffsets[2]);
  Assert.IsTrue(Pos('Unknown animation type: foo', FLog.Joined) > 0);
end;

procedure TTestAnimDefsParser.TestUnaAnimazioneConUnSoloFrameDaErrore;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Parse('flat FWATER1 pic 1 tics 8');
    end, EDefinitionsException, 'framecount < 2');
end;

procedure TTestAnimDefsParser.TestTroppeAnimazioniDannoErrore;
var
  LText: string;
  LIndex: Integer;
begin
  LText := '';
  for LIndex := 1 to DEFINITIONS_MAX_ANIMATIONS + 1 do
    LText := LText + 'flat FWATER1 pic 1 tics 8 pic 2 tics 8'#10;
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Parse(LText);
    end, EDefinitionsException, 'too many AnimDefs \(128\)');
  Assert.AreEqual<Integer>(DEFINITIONS_MAX_ANIMATIONS, Length(Parse(Copy(LText, 1,
    DEFINITIONS_MAX_ANIMATIONS * Length('flat FWATER1 pic 1 tics 8 pic 2 tics 8'#10)))));
end;

procedure TTestAnimDefsParser.TestTroppiFrameDannoErrore;
var
  LText: string;
  LIndex: Integer;
begin
  LText := '';
  for LIndex := 1 to 65 do
    LText := LText + 'flat FWATER1 pic 1 tics 8 pic 2 tics 8 pic 3 tics 8 pic 4 tics 8 pic 5 tics 8 pic 6 tics 8 pic 7 tics 8 pic 8 tics 8'#10;
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      Parse(LText);
    end, EDefinitionsException, 'too many FrameDefs \(512\)');
end;

procedure TTestAnimDefsParser.TestUnTipoSconosciutoDaUnAvvisoELaLetturaContinua;
var
  LAnimations: TArray<TDefAnimation>;
begin
  LAnimations := Parse('foo FWATER1 pic 1 tics 8 pic 2 tics 8');
  Assert.AreEqual<Integer>(1, Length(LAnimations));
  Assert.IsTrue(Pos('Unknown animation type: foo', FLog.Joined) > 0);
end;

procedure TTestAnimDefsParser.TestUnTipoSconosciutoUsaIlTipoDelloSlotDellaVecchiaAnimazione;
var
  LAnimations: TArray<TDefAnimation>;
begin
  // texture ignorata: lo slot resta quello di una texture
  LAnimations := Parse('texture NOSUCH pic 1 tics 8 foo BLODGR1 pic 1 tics 8 pic 2 tics 8');
  Assert.AreEqual<Integer>(1, Length(LAnimations));
  Assert.IsTrue(LAnimations[0].Kind = TDefAnimKind.Texture);
  // animazione tenuta: lo slot nuovo e un flat
  LAnimations := Parse('texture BLODGR1 pic 1 tics 8 pic 2 tics 8 foo FWATER1 pic 1 tics 8 pic 2 tics 8');
  Assert.AreEqual<Integer>(2, Length(LAnimations));
  Assert.IsTrue(LAnimations[1].Kind = TDefAnimKind.Flat);
end;

procedure TTestAnimDefsParser.TestUnNumeroMancanteDaUnAvvisoELaLetturaContinua;
var
  LAnimation: TDefAnimation;
begin
  LAnimation := Parse('flat FWATER1 pic 4 tics 8 pic tics 8 pic 2 tics 8')[0];
  Assert.IsTrue(Pos('Bad numeric constant "tics"', FLog.Joined) > 0);
  // la riga senza numero non e un frame (il "8" non e tics ne rand), le altre si leggono
  Assert.AreEqual<Integer>(2, Length(LAnimation.Frames));
  Assert.AreEqual(2, LAnimation.Frames[1].PicNumber);
end;

procedure TTestAnimDefsParser.TestSenzaLogGliAvvisiNonFannoDanni;
var
  LAnimations: TArray<TDefAnimation>;
begin
  LAnimations := TDefinitionsFactory.CreateAnimDefsParser(FCatalogIntf, nil).Parse('foo FWATER1 pic 1 tics 8 pic 2 tics 8');
  Assert.AreEqual<Integer>(1, Length(LAnimations));
end;

procedure TTestAnimDefsParser.TestDueLettureNonSiInfluenzano;
var
  LParser: IDefAnimDefsParser;
begin
  LParser := TDefinitionsFactory.CreateAnimDefsParser(FCatalogIntf, FLogIntf);
  Assert.AreEqual<Integer>(1, Length(LParser.Parse('flat FWATER1 pic 1 tics 8 pic 2 tics 8')));
  Assert.AreEqual<Integer>(1, Length(LParser.Parse('flat FWATER2 pic 1 tics 8 pic 2 tics 8')));
end;

procedure TTestAnimDefsParser.TestIFineRigaCrLfEdLfSonoLoStesso;
begin
  Assert.AreEqual<Integer>(2, Length(Parse('flat FWATER1'#13#10'pic 1 tics 8'#13#10'pic 2 tics 8'#13#10)[0].Frames));
  Assert.AreEqual<Integer>(2, Length(Parse('flat FWATER1'#10'pic 1 tics 8'#10'pic 2 tics 8'#10)[0].Frames));
end;

end.
