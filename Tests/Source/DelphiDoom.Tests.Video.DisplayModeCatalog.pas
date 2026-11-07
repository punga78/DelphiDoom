{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the catalog of the screen modes     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.DisplayModeCatalog;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Video.Types, DelphiDoom.Video.Intf,
  DelphiDoom.Video.Factory;

type
  TFakeDisplayModeSource = class(TInterfacedObject, IDisplayModeSource)
  private
    FModes: TArray<TDisplayMode>;
  public
    procedure Add(AWidth, AHeight, ABits: Integer);
    function ListModes: TArray<TDisplayMode>;
  end;

  [TestFixture]
  [Category('video')]
  TTestVideoDisplayModeCatalog = class(TObject)
  private
    FSource: TFakeDisplayModeSource;
    FSourceIntf: IDisplayModeSource;
    FCatalog: IDisplayModeCatalog;
    procedure AddTypicalModes;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareErroreConSorgenteNil;
    [Test]
    procedure DovrebbeEssereVuotoPrimaDelRefresh;
    [Test]
    procedure DovrebbeTenereSoloIModiA32Bit;
    [Test]
    procedure DovrebbeScartareIModiSottoIlMinimo;
    [Test]
    procedure DovrebbeScartareIModiOltreIlMassimo;
    [Test]
    procedure DovrebbeScartareLeRipetizioniDiUnaDimensione;
    [Test]
    procedure DovrebbeOrdinarePerLarghezzaPoiAltezza;
    [Test]
    procedure DovrebbeUsareIModiA16BitSeNonCeNeSonoA32;
    [Test]
    procedure DovrebbeScartareI16BitSottoIl640Per400;
    [Test]
    procedure DovrebbeDareIModiDiRipiegoSeNonCeNeSono;
    [Test]
    procedure DovrebbeRifareLaListaAOgniRefresh;
    [Test]
    procedure DovrebbeSvuotareConClear;
    [Test]
    procedure DovrebbeTrovareLaDimensioneEsatta;
    [Test]
    procedure DovrebbeDareMenoUnoSeLaDimensioneNonCe;
    [Test]
    procedure DovrebbeDareLEsattoComePiuVicino;
    [Test]
    procedure DovrebbeScegliereIlPiuVicino;
    [Test]
    procedure DovrebbePreferireUnModePiuPiccoloAUnoPiuGrande;
    [Test]
    procedure DovrebbeDareMenoUnoComePiuVicinoSenzaModi;
    [Test]
    procedure DovrebbeTrovareLaFinestraEsatta;
    [Test]
    procedure DovrebbeTrovareLaFinestraDelModoPiuVicino;
    [Test]
    procedure DovrebbeDareFalsoPerLaFinestraSenzaModi;
  end;

implementation

{ TFakeDisplayModeSource }

procedure TFakeDisplayModeSource.Add(AWidth, AHeight, ABits: Integer);
begin
  SetLength(FModes, Length(FModes) + 1);
  FModes[High(FModes)].Width := AWidth;
  FModes[High(FModes)].Height := AHeight;
  FModes[High(FModes)].BitsPerPixel := ABits;
end;

function TFakeDisplayModeSource.ListModes: TArray<TDisplayMode>;
begin
  Result := Copy(FModes);
end;

{ TTestVideoDisplayModeCatalog }

procedure TTestVideoDisplayModeCatalog.Setup;
begin
  FSource := TFakeDisplayModeSource.Create;
  FSourceIntf := FSource;
  FCatalog := TVideoFactory.CreateDisplayModeCatalog(FSourceIntf);
end;

procedure TTestVideoDisplayModeCatalog.AddTypicalModes;
begin
  FSource.Add(1024, 768, 32);
  FSource.Add(640, 480, 32);
  FSource.Add(800, 600, 32);
  FCatalog.Refresh(4096, 4096);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeDareErroreConSorgenteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TVideoFactory.CreateDisplayModeCatalog(nil);
    end, EArgumentNilException);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeEssereVuotoPrimaDelRefresh;
begin
  Assert.AreEqual(0, FCatalog.Count);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeTenereSoloIModiA32Bit;
begin
  FSource.Add(640, 480, 16);
  FSource.Add(800, 600, 32);
  FSource.Add(1024, 768, 24);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(1, FCatalog.Count);
  Assert.AreEqual(800, FCatalog[0].Width);
  Assert.AreEqual(32, FCatalog[0].BitsPerPixel);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeScartareIModiSottoIlMinimo;
begin
  FSource.Add(319, 240, 32);
  FSource.Add(640, 199, 32);
  FSource.Add(320, 200, 32);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(1, FCatalog.Count);
  Assert.AreEqual(320, FCatalog[0].Width);
  Assert.AreEqual(200, FCatalog[0].Height);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeScartareIModiOltreIlMassimo;
begin
  FSource.Add(800, 600, 32);
  FSource.Add(1920, 1080, 32);
  FSource.Add(1600, 1200, 32);
  FCatalog.Refresh(1600, 1100);
  Assert.AreEqual(1, FCatalog.Count);
  Assert.AreEqual(800, FCatalog[0].Width);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeScartareLeRipetizioniDiUnaDimensione;
begin
  FSource.Add(800, 600, 32);
  FSource.Add(800, 600, 32);
  FSource.Add(800, 600, 32);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(1, FCatalog.Count);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeOrdinarePerLarghezzaPoiAltezza;
begin
  FSource.Add(1024, 768, 32);
  FSource.Add(800, 600, 32);
  FSource.Add(800, 450, 32);
  FSource.Add(640, 480, 32);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(4, FCatalog.Count);
  Assert.AreEqual(640, FCatalog[0].Width);
  Assert.AreEqual(450, FCatalog[1].Height);
  Assert.AreEqual(600, FCatalog[2].Height);
  Assert.AreEqual(1024, FCatalog[3].Width);
end;

// Il vecchio i_displaymodes aveva questo secondo giro, ma non girava mai (l'indice
// era gia' oltre la fine): senza modi a 32 bit il menu non offriva nulla di vero.
procedure TTestVideoDisplayModeCatalog.DovrebbeUsareIModiA16BitSeNonCeNeSonoA32;
begin
  FSource.Add(800, 600, 16);
  FSource.Add(1024, 768, 24);
  FSource.Add(640, 480, 8);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(2, FCatalog.Count);
  Assert.AreEqual(800, FCatalog[0].Width);
  Assert.AreEqual(1024, FCatalog[1].Width);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeScartareI16BitSottoIl640Per400;
begin
  FSource.Add(320, 240, 16);
  FSource.Add(640, 399, 16);
  FSource.Add(640, 400, 16);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(1, FCatalog.Count);
  Assert.AreEqual(400, FCatalog[0].Height);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeDareIModiDiRipiegoSeNonCeNeSono;
begin
  FSource.Add(640, 480, 8);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(2, FCatalog.Count);
  Assert.AreEqual(320, FCatalog[0].Width);
  Assert.AreEqual(200, FCatalog[0].Height);
  Assert.AreEqual(640, FCatalog[1].Width);
  Assert.AreEqual(400, FCatalog[1].Height);
  Assert.AreEqual(32, FCatalog[1].BitsPerPixel);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeRifareLaListaAOgniRefresh;
begin
  AddTypicalModes;
  Assert.AreEqual(3, FCatalog.Count);
  FCatalog.Refresh(4096, 4096);
  Assert.AreEqual(3, FCatalog.Count);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeSvuotareConClear;
begin
  AddTypicalModes;
  FCatalog.Clear;
  Assert.AreEqual(0, FCatalog.Count);
  Assert.AreEqual(-1, FCatalog.IndexOf(800, 600));
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeTrovareLaDimensioneEsatta;
begin
  AddTypicalModes;
  Assert.AreEqual(0, FCatalog.IndexOf(640, 480));
  Assert.AreEqual(1, FCatalog.IndexOf(800, 600));
  Assert.AreEqual(2, FCatalog.IndexOf(1024, 768));
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeDareMenoUnoSeLaDimensioneNonCe;
begin
  AddTypicalModes;
  Assert.AreEqual(-1, FCatalog.IndexOf(800, 601));
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeDareLEsattoComePiuVicino;
begin
  AddTypicalModes;
  Assert.AreEqual(1, FCatalog.NearestIndex(800, 600));
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeScegliereIlPiuVicino;
begin
  AddTypicalModes;
  // 700x500: a 640x480 distance is 63, a 800x600 one is 141 plus 100 for being bigger
  Assert.AreEqual(0, FCatalog.NearestIndex(700, 500));
  Assert.AreEqual(2, FCatalog.NearestIndex(2000, 1500));
end;

procedure TTestVideoDisplayModeCatalog.DovrebbePreferireUnModePiuPiccoloAUnoPiuGrande;
begin
  AddTypicalModes;
  // 900x700: 800x600 and 1024x768 are as far (141), but the second is bigger: it counts 100 more
  Assert.AreEqual(1, FCatalog.NearestIndex(900, 700));
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeDareMenoUnoComePiuVicinoSenzaModi;
begin
  Assert.AreEqual(-1, FCatalog.NearestIndex(800, 600));
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeTrovareLaFinestraEsatta;
var
  LWidth, LHeight: Integer;
begin
  AddTypicalModes;
  Assert.IsTrue(FCatalog.FindWindowSize(800, 600, LWidth, LHeight));
  Assert.AreEqual(800, LWidth);
  Assert.AreEqual(600, LHeight);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeTrovareLaFinestraDelModoPiuVicino;
var
  LWidth, LHeight: Integer;
begin
  AddTypicalModes;
  Assert.IsTrue(FCatalog.FindWindowSize(700, 500, LWidth, LHeight));
  Assert.AreEqual(640, LWidth);
  Assert.AreEqual(480, LHeight);
end;

procedure TTestVideoDisplayModeCatalog.DovrebbeDareFalsoPerLaFinestraSenzaModi;
var
  LWidth, LHeight: Integer;
begin
  Assert.IsFalse(FCatalog.FindWindowSize(700, 500, LWidth, LHeight));
end;

end.
