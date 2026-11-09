{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - a map or lump saved as a picture    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PngExporter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Platform.Intf;

type
  /// <summary>A file store that keeps what it is given, and can refuse to write</summary>
  TFakeFiles = class(TInterfacedObject, IFileStore)
  public
    LastName: string;
    LastBytes: TBytes;
    Refuse: Boolean;
    function Exists(const AName: string): Boolean;
    function Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
    function Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
    function Read(const AName: string): TBytes;
    function Delete(const AName: string): Boolean;
    function EnsureDirectory(const APath: string): Boolean;
  end;

  /// <summary>An encoder that remembers what it got and gives 3 bytes</summary>
  TFakeEncoder = class(TInterfacedObject, IGreedImageEncoder)
  public
    Width: Integer;
    Height: Integer;
    PaletteLength: Integer;
    Transparent: Boolean;
    Calls: Integer;
    function Encode(const AImage: TGreedImage; const APalette: TBytes; ATransparentZero: Boolean): TBytes;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedPngExporter = class(TObject)
  private
    FFiles: TFakeFiles;
    FFilesIntf: IFileStore;
    FEncoder: TFakeEncoder;
    FEncoderIntf: IGreedImageEncoder;
    FExporter: IGreedPngExporter;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLaMappaNelFile;
    [Test]
    procedure DovrebbeDareAlCodificatoreLImmagineDellaMappaESenzaTrasparenza;
    [Test]
    procedure DovrebbeDareAlCodificatoreLaPaletteDell_Archivio;
    [Test]
    procedure DovrebbeSalvareUnaImmagineConLoZeroTrasparente;
    [Test]
    procedure DovrebbeSalvareUnMuroSenzaTrasparenza;
    [Test]
    procedure DovrebbeSalvareUnoSpriteConLoZeroTrasparente;
    [Test]
    procedure DovrebbeRifiutareUnLumpCheNonEUnaImmagine;
    [Test]
    procedure DovrebbeRifiutareUnaMappaCheNonCe;
    [Test]
    procedure DovrebbeSegnalareUnFileCheNonSiScrive;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Greed.Factory, DelphiDoom.Greed.PngExporter, DelphiDoom.Tests.Greed.Builders;

{ TFakeFiles }

function TFakeFiles.Exists(const AName: string): Boolean;
begin
  Result := AName = LastName;
end;

function TFakeFiles.Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
begin
  Result := not Refuse;
  if Result then
  begin
    LastName := AName;
    SetLength(LastBytes, ALength);
    Move(ASource^, LastBytes[0], ALength);
  end;
end;

function TFakeFiles.Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
begin
  Result := 0;
end;

function TFakeFiles.Read(const AName: string): TBytes;
begin
  Result := LastBytes;
end;

function TFakeFiles.Delete(const AName: string): Boolean;
begin
  Result := False;
end;

function TFakeFiles.EnsureDirectory(const APath: string): Boolean;
begin
  Result := True;
end;

{ TFakeEncoder }

function TFakeEncoder.Encode(const AImage: TGreedImage; const APalette: TBytes; ATransparentZero: Boolean): TBytes;
begin
  Inc(Calls);
  Width := AImage.Width;
  Height := AImage.Height;
  PaletteLength := Length(APalette);
  Transparent := ATransparentZero;
  Result := TBytes.Create(1, 2, 3);
end;

{ TTestGreedPngExporter }

procedure TTestGreedPngExporter.Setup;
var
  LArchive: IGreedArchive;
begin
  LArchive := TGreedTestArchive.Open;
  FFiles := TFakeFiles.Create;
  FFilesIntf := FFiles;
  FEncoder := TFakeEncoder.Create;
  FEncoderIntf := FEncoder;
  FExporter := TGreedPngExporter.Create(LArchive, TGreedFactory.CreateMapLoader(LArchive, nil),
    TGreedFactory.CreateMapRenderer(LArchive), TGreedFactory.CreateLumpClassifier(LArchive), FEncoderIntf, FFilesIntf);
end;

procedure TTestGreedPngExporter.TearDown;
begin
  FExporter := nil;
  FEncoderIntf := nil;
  FFilesIntf := nil;
end;

procedure TTestGreedPngExporter.DovrebbeScrivereLaMappaNelFile;
begin
  FExporter.SaveMap(0, 'C:\out\map0.png');
  Assert.AreEqual('C:\out\map0.png', FFiles.LastName);
  Assert.AreEqual(3, Length(FFiles.LastBytes));
end;

procedure TTestGreedPngExporter.DovrebbeDareAlCodificatoreLImmagineDellaMappaESenzaTrasparenza;
begin
  FExporter.SaveMap(0, 'x.png');
  Assert.AreEqual(512, FEncoder.Width);
  Assert.AreEqual(512, FEncoder.Height);
  Assert.IsFalse(FEncoder.Transparent);
end;

procedure TTestGreedPngExporter.DovrebbeDareAlCodificatoreLaPaletteDell_Archivio;
begin
  FExporter.SaveMap(0, 'x.png');
  Assert.AreEqual(GREED_PALETTE_BYTES, FEncoder.PaletteLength);
end;

procedure TTestGreedPngExporter.DovrebbeSalvareUnaImmagineConLoZeroTrasparente;
begin
  FExporter.SaveLump(15, 'menu.png');
  Assert.AreEqual(3, FEncoder.Width);
  Assert.AreEqual(2, FEncoder.Height);
  Assert.IsTrue(FEncoder.Transparent);
  Assert.AreEqual('menu.png', FFiles.LastName);
end;

procedure TTestGreedPngExporter.DovrebbeSalvareUnMuroSenzaTrasparenza;
begin
  FExporter.SaveLump(TGreedTestArchive.LUMP_WALL2, 'wall.png');
  Assert.AreEqual(64, FEncoder.Width);
  Assert.AreEqual(64, FEncoder.Height);
  Assert.IsFalse(FEncoder.Transparent);
  FExporter.SaveLump(TGreedTestArchive.LUMP_FLAT1, 'flat.png');
  Assert.IsFalse(FEncoder.Transparent);
end;

procedure TTestGreedPngExporter.DovrebbeSalvareUnoSpriteConLoZeroTrasparente;
begin
  FExporter.SaveLump(TGreedTestArchive.LUMP_SPRITE1, 'sprite.png');
  Assert.AreEqual(3, FEncoder.Width);
  Assert.AreEqual(5, FEncoder.Height);
  Assert.IsTrue(FEncoder.Transparent);
end;

procedure TTestGreedPngExporter.DovrebbeRifiutareUnLumpCheNonEUnaImmagine;
begin
  Assert.WillRaise(procedure begin FExporter.SaveLump(TGreedTestArchive.LUMP_FONT, 'x.png'); end, EGreedDataException);
  Assert.WillRaise(procedure begin FExporter.SaveLump(TGreedTestArchive.LUMP_PALETTE, 'x.png'); end, EGreedDataException);
  Assert.AreEqual(0, FEncoder.Calls);
end;

procedure TTestGreedPngExporter.DovrebbeRifiutareUnaMappaCheNonCe;
begin
  Assert.WillRaise(procedure begin FExporter.SaveMap(99, 'x.png'); end, EGreedNotFoundException);
end;

procedure TTestGreedPngExporter.DovrebbeSegnalareUnFileCheNonSiScrive;
begin
  FFiles.Refuse := True;
  Assert.WillRaise(procedure begin FExporter.SaveMap(0, 'x.png'); end, EGreedException);
end;

procedure TTestGreedPngExporter.DovrebbeVolereLeSueParti;
var
  LArchive: IGreedArchive;
begin
  LArchive := TGreedTestArchive.Open;
  Assert.WillRaise(procedure begin TGreedPngExporter.Create(nil, TGreedFactory.CreateMapLoader(LArchive, nil),
    TGreedFactory.CreateMapRenderer(LArchive), TGreedFactory.CreateLumpClassifier(LArchive), FEncoderIntf, FFilesIntf); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedPngExporter.Create(LArchive, nil,
    TGreedFactory.CreateMapRenderer(LArchive), TGreedFactory.CreateLumpClassifier(LArchive), FEncoderIntf, FFilesIntf); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedPngExporter.Create(LArchive, TGreedFactory.CreateMapLoader(LArchive, nil),
    nil, TGreedFactory.CreateLumpClassifier(LArchive), FEncoderIntf, FFilesIntf); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedPngExporter.Create(LArchive, TGreedFactory.CreateMapLoader(LArchive, nil),
    TGreedFactory.CreateMapRenderer(LArchive), nil, FEncoderIntf, FFilesIntf); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedPngExporter.Create(LArchive, TGreedFactory.CreateMapLoader(LArchive, nil),
    TGreedFactory.CreateMapRenderer(LArchive), TGreedFactory.CreateLumpClassifier(LArchive), nil, FFilesIntf); end,
    EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedPngExporter.Create(LArchive, TGreedFactory.CreateMapLoader(LArchive, nil),
    TGreedFactory.CreateMapRenderer(LArchive), TGreedFactory.CreateLumpClassifier(LArchive), FEncoderIntf, nil); end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedPngExporter);

end.
