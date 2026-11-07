{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingFactory                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.Factory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.Factory, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.ThumbnailBuilder;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingFactory = class(TObject)
  public
    [Test]
    procedure TestEveryServiceIsCreated;
    [Test]
    procedure TestPatchReaderWithoutPainterUsesTheStandardOne;
    [Test]
    procedure TestEachCallCreatesANewObject;
    [Test]
    procedure TestServicesWorkTogether;
  end;

implementation

procedure TTestImagingFactory.TestEveryServiceIsCreated;
begin
  Assert.IsNotNull(TImagingFactory.CreateColumnPainter, 'dovrebbe creare il pittore di colonne');
  Assert.IsNotNull(TImagingFactory.CreateColumnRebuilder, 'dovrebbe creare il ricostruttore di colonne');
  Assert.IsNotNull(TImagingFactory.CreateFixedColumnBuilder, 'dovrebbe creare il costruttore di colonne fisse');
  Assert.IsNotNull(TImagingFactory.CreatePatchReader, 'dovrebbe creare il lettore di patch');
  Assert.IsNotNull(TImagingFactory.CreateFlatReader, 'dovrebbe creare il lettore di flat');
  Assert.IsNotNull(TImagingFactory.CreateFlatShrinker, 'dovrebbe creare il riduttore di flat');
  Assert.IsNotNull(TImagingFactory.CreateSpanGrower, 'dovrebbe creare chi ingrandisce i flat');
  Assert.IsNotNull(TImagingFactory.CreateColumnExpander, 'dovrebbe creare chi espande le colonne');
  Assert.IsNotNull(TImagingFactory.CreateHiResTableBuilder, 'dovrebbe creare il costruttore delle tabelle');
  Assert.IsNotNull(TImagingFactory.CreateSineTable, 'dovrebbe creare la tabella dei seni');
  Assert.IsNotNull(TImagingFactory.CreateWallScale, 'dovrebbe creare il calcolo della scala');
  Assert.IsNotNull(TImagingFactory.CreateThumbnailBuilder(TReferenceColorIndex.Create),
    'dovrebbe creare chi riduce lo schermo a miniatura');
end;

procedure TTestImagingFactory.TestPatchReaderWithoutPainterUsesTheStandardOne;
var
  LImage: TImagingPatchImage;
  LPost: TSamplePost;
begin
  LPost.TopDelta := 0;
  LPost.Length := 2;
  LPost.Seed := 1;
  LImage := TImagingFactory.CreatePatchReader(nil).Read(
    TImagingSamples.Patch(1, 2, 0, 0, [TImagingSamples.Column([LPost])], [0]));
  Assert.AreEqual(Integer($FF), Integer(LImage.Opaque[0]), 'dovrebbe dipingere con il pittore standard');
end;

procedure TTestImagingFactory.TestEachCallCreatesANewObject;
begin
  Assert.IsFalse(TImagingFactory.CreateSpanGrower = TImagingFactory.CreateSpanGrower, 'dovrebbe creare un oggetto nuovo a ogni chiamata');
end;

procedure TTestImagingFactory.TestServicesWorkTogether;
var
  LPalette: TImagingPixels;
  LFlat: TImagingFlatImage;
  LGrown: TImagingPixels;
begin
  // un flat letto con la palette e ingrandito: i servizi si passano solo buffer
  LPalette := TImagingSamples.Palette(5);
  LFlat := TImagingFactory.CreateFlatReader.Read(TImagingSamples.RandomBytes(1, 4096), LPalette, 0);
  LGrown := TImagingFactory.CreateSpanGrower.Grow64to256(LFlat.Pixels);
  Assert.AreEqual(256 * 256, Length(LGrown), 'dovrebbe ingrandire il flat letto');
end;

end.
