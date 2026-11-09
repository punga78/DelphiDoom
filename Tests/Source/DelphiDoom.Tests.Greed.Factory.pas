{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the factory and the composition     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Factory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedFactory = class(TObject)
  private
    FFolder: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAprireUnArchivioDaUnFile;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonEUnArchivio;
    [Test]
    procedure DovrebbeNonAprireUnFileCheNonCe;
    [Test]
    procedure DovrebbeDareLeCorrezioniDellOriginale;
    [Test]
    procedure DovrebbeCreareLeParti;
    [Test]
    procedure DovrebbeTrovareLArchivioNellaPrimaCartellaCheLoHa;
    [Test]
    procedure DovrebbeRifiutareCartelleSenzaArchivio;
    [Test]
    procedure DovrebbeSalvareUnaMappaComeFilePng;
    [Test]
    procedure DovrebbeSalvareUnaImmagineComeFilePng;
    [Test]
    procedure DovrebbeDareIlClassificatore;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Factory, DelphiDoom.Greed.Composition, DelphiDoom.Tests.Greed.Builders;

{ TTestGreedFactory }

procedure TTestGreedFactory.Setup;
begin
  FFolder := TPath.Combine(TPath.GetTempPath, 'ddgreed_f_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FFolder);
  TFile.WriteAllBytes(TPath.Combine(FFolder, 'GREED.BLO'), TGreedTestArchive.Bytes);
  TFile.WriteAllBytes(TPath.Combine(FFolder, 'BAD.BLO'), TBytes.Create(1, 2, 3));
end;

procedure TTestGreedFactory.TearDown;
begin
  TDirectory.Delete(FFolder, True);
end;

procedure TTestGreedFactory.DovrebbeAprireUnArchivioDaUnFile;
var
  LArchive: IGreedArchive;
begin
  LArchive := TGreedFactory.OpenArchiveFile(TPath.Combine(FFolder, 'GREED.BLO'));
  Assert.AreEqual(TGreedTestArchive.LUMP_COUNT, LArchive.LumpCount);
  Assert.AreEqual(TGreedTestArchive.LUMP_PALETTE, LArchive.IndexOf('palette'));
  Assert.AreEqual(GREED_PALETTE_BYTES, Length(LArchive.ReadLump(0)));
end;

procedure TTestGreedFactory.DovrebbeRifiutareUnFileCheNonEUnArchivio;
begin
  Assert.WillRaise(procedure begin TGreedFactory.OpenArchiveFile(TPath.Combine(FFolder, 'BAD.BLO')); end, EGreedDataException);
end;

procedure TTestGreedFactory.DovrebbeNonAprireUnFileCheNonCe;
begin
  Assert.WillRaiseDescendant(procedure begin TGreedFactory.OpenArchiveFile(TPath.Combine(FFolder, 'NONE.BLO')); end, Exception);
end;

procedure TTestGreedFactory.DovrebbeDareLeCorrezioniDellOriginale;
begin
  Assert.IsNotNull(TGreedFactory.CreateLumpFixes);
  Assert.AreEqual(3, Length(TGreedFactory.CreateLumpFixes.Apply(TBytes.Create(1, 2, 3))));
end;

procedure TTestGreedFactory.DovrebbeCreareLeParti;
var
  LArchive: IGreedArchive;
begin
  LArchive := TGreedTestArchive.Open;
  Assert.IsNotNull(TGreedFactory.CreateMapReader);
  Assert.IsNotNull(TGreedFactory.CreateMapLoader(LArchive, nil));
  Assert.IsNotNull(TGreedFactory.CreateLumpClassifier(LArchive));
  Assert.IsNotNull(TGreedFactory.CreateMapRenderer(LArchive));
  Assert.IsNotNull(TGreedFactory.CreateFolderFiles([FFolder]));
end;

procedure TTestGreedFactory.DovrebbeTrovareLArchivioNellaPrimaCartellaCheLoHa;
var
  LArchive: IGreedArchive;
begin
  LArchive := TGreedComposition.OpenArchive([TPath.Combine(FFolder, 'none'), FFolder]);
  Assert.AreEqual(TGreedTestArchive.LUMP_COUNT, LArchive.LumpCount);
end;

procedure TTestGreedFactory.DovrebbeRifiutareCartelleSenzaArchivio;
begin
  Assert.WillRaise(procedure begin TGreedComposition.OpenArchive([TPath.Combine(FFolder, 'none')]); end, EGreedNotFoundException);
  Assert.WillRaise(procedure begin TGreedComposition.OpenArchive([]); end, EGreedNotFoundException);
end;

procedure TTestGreedFactory.DovrebbeSalvareUnaMappaComeFilePng;
var
  LArchive: IGreedArchive;
  LPath: string;
  LBytes: TBytes;
begin
  LArchive := TGreedComposition.OpenArchive([FFolder]);
  LPath := TPath.Combine(FFolder, 'map0.png');
  TGreedComposition.CreateExporter(LArchive, [FFolder]).SaveMap(0, LPath);
  LBytes := TFile.ReadAllBytes(LPath);
  Assert.AreEqual($89, Integer(LBytes[0]));
  Assert.AreEqual(Ord('P'), Integer(LBytes[1]));
end;

procedure TTestGreedFactory.DovrebbeSalvareUnaImmagineComeFilePng;
var
  LArchive: IGreedArchive;
  LPath: string;
begin
  LArchive := TGreedComposition.OpenArchive([FFolder]);
  LPath := TPath.Combine(FFolder, 'sprite.png');
  TGreedComposition.CreateExporter(LArchive, [FFolder]).SaveLump(TGreedTestArchive.LUMP_SPRITE1, LPath);
  Assert.IsTrue(TFile.Exists(LPath));
  Assert.IsTrue(TFile.GetSize(LPath) > 8);
end;

procedure TTestGreedFactory.DovrebbeDareIlClassificatore;
var
  LArchive: IGreedArchive;
begin
  LArchive := TGreedComposition.OpenArchive([FFolder]);
  Assert.AreEqual(Ord(glkPalette), Ord(TGreedComposition.CreateClassifier(LArchive).Classify(0)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedFactory);

end.
