{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the scanner library - the AUTOLOAD lumps                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Scanner.AutoLoad;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Scanner.AutoLoad.Intf;

type
  TFakeAutoLoadLumps = class(TInterfacedObject, IAutoLoadLumps)
  private
    FNames: TList<string>;
    FTexts: TList<string>;
  public
    TextReads: Integer;
    constructor Create;
    destructor Destroy; override;
    procedure AddLump(const AName, AText: string);
    function GetCount: Integer;
    function NameOf(AIndex: Integer): string;
    function TextOf(AIndex: Integer): string;
  end;

  TFakeAutoLoadSink = class(TInterfacedObject, IAutoLoadFileSink)
  private
    FLumps: TFakeAutoLoadLumps;
  public
    Files: TList<string>;
    TextReadsAtEachFile: TList<Integer>;
    /// <summary>When given, the first file added also adds a lump (as a loaded WAD does)</summary>
    LumpToAdd: string;
    constructor Create(const ALumps: TFakeAutoLoadLumps);
    destructor Destroy; override;
    procedure AddFile(const AFileName: string);
  end;

  [TestFixture]
  [Category('scanner')]
  TTestScannerAutoLoad = class(TObject)
  private
    FLumps: TFakeAutoLoadLumps;
    FLumpsIntf: IAutoLoadLumps;
    FSink: TFakeAutoLoadSink;
    FSinkIntf: IAutoLoadFileSink;
    FReader: IAutoLoadReader;
    function Joined: string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareErroreSenzaLump;
    [Test]
    procedure DovrebbeDareErroreSenzaDestinazione;
    [Test]
    procedure DovrebbeNonFareNullaSenzaLumpAutoload;
    [Test]
    procedure DovrebbeLeggereIFileDiUnLumpAutoload;
    [Test]
    procedure DovrebbeDareIlNomeDelFileCosiComeScritto;
    [Test]
    procedure DovrebbeIgnorareILumpConUnAltroNome;
    [Test]
    procedure DovrebbeLeggereTuttiILumpAutoloadInOrdine;
    [Test]
    procedure DovrebbeTenereUnitiITestiTraVirgolette;
    [Test]
    procedure DovrebbeIgnorareICommenti;
    [Test]
    procedure DovrebbeNonDareFileConUnLumpVuoto;
    [Test]
    procedure DovrebbeDareIFileUnoAllaVolta;
    [Test]
    procedure DovrebbeLeggereSoloILumpPresentiAllAvvio;
    [Test]
    procedure DovrebbeDistinguereMaiuscoleENelNomeDelLump;
  end;

implementation

uses
  DelphiDoom.Scanner.AutoLoad;

{ TFakeAutoLoadLumps }

constructor TFakeAutoLoadLumps.Create;
begin
  inherited Create;
  FNames := TList<string>.Create;
  FTexts := TList<string>.Create;
end;

destructor TFakeAutoLoadLumps.Destroy;
begin
  FNames.Free;
  FTexts.Free;
  inherited Destroy;
end;

procedure TFakeAutoLoadLumps.AddLump(const AName, AText: string);
begin
  FNames.Add(AName);
  FTexts.Add(AText);
end;

function TFakeAutoLoadLumps.GetCount: Integer;
begin
  Result := FNames.Count;
end;

function TFakeAutoLoadLumps.NameOf(AIndex: Integer): string;
begin
  Result := FNames[AIndex];
end;

function TFakeAutoLoadLumps.TextOf(AIndex: Integer): string;
begin
  Inc(TextReads);
  Result := FTexts[AIndex];
end;

{ TFakeAutoLoadSink }

constructor TFakeAutoLoadSink.Create(const ALumps: TFakeAutoLoadLumps);
begin
  inherited Create;
  FLumps := ALumps;
  Files := TList<string>.Create;
  TextReadsAtEachFile := TList<Integer>.Create;
end;

destructor TFakeAutoLoadSink.Destroy;
begin
  Files.Free;
  TextReadsAtEachFile.Free;
  inherited Destroy;
end;

procedure TFakeAutoLoadSink.AddFile(const AFileName: string);
begin
  Files.Add(AFileName);
  TextReadsAtEachFile.Add(FLumps.TextReads);
  if (LumpToAdd <> '') and (Files.Count = 1) then
    FLumps.AddLump(LumpToAdd, 'more.pk3');
end;

{ TTestScannerAutoLoad }

procedure TTestScannerAutoLoad.Setup;
begin
  FLumps := TFakeAutoLoadLumps.Create;
  FLumpsIntf := FLumps;
  FSink := TFakeAutoLoadSink.Create(FLumps);
  FSinkIntf := FSink;
  FReader := TAutoLoadReader.Create(FLumpsIntf, FSinkIntf, nil);
end;

function TTestScannerAutoLoad.Joined: string;
var
  LFile: string;
begin
  Result := '';
  for LFile in FSink.Files do
    Result := Result + '[' + LFile + ']';
end;

procedure TTestScannerAutoLoad.DovrebbeDareErroreSenzaLump;
begin
  Assert.WillRaise(
    procedure
    begin
      TAutoLoadReader.Create(nil, FSinkIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestScannerAutoLoad.DovrebbeDareErroreSenzaDestinazione;
begin
  Assert.WillRaise(
    procedure
    begin
      TAutoLoadReader.Create(FLumpsIntf, nil, nil);
    end, EArgumentNilException);
end;

procedure TTestScannerAutoLoad.DovrebbeNonFareNullaSenzaLumpAutoload;
begin
  FLumps.AddLump('PLAYPAL', 'a.pk3');
  FReader.Load;
  Assert.AreEqual(0, FSink.Files.Count);
end;

procedure TTestScannerAutoLoad.DovrebbeLeggereIFileDiUnLumpAutoload;
begin
  FLumps.AddLump('AUTOLOAD', 'one.pk3 two.pak'#13#10'three.wad');
  FReader.Load;
  Assert.AreEqual('[one.pk3][two.pak][three.wad]', Joined);
end;

procedure TTestScannerAutoLoad.DovrebbeDareIlNomeDelFileCosiComeScritto;
begin
  FLumps.AddLump('AUTOLOAD', 'Mixed.PK3');
  FReader.Load;
  // the name goes to the engine as it is written
  Assert.AreEqual('[Mixed.PK3]', Joined);
end;

procedure TTestScannerAutoLoad.DovrebbeIgnorareILumpConUnAltroNome;
begin
  FLumps.AddLump('AUTOLOAD', 'a.pk3');
  FLumps.AddLump('DEHACKED', 'b.pk3');
  FLumps.AddLump('AUTOLOAD', 'c.pk3');
  FReader.Load;
  Assert.AreEqual('[a.pk3][c.pk3]', Joined);
end;

procedure TTestScannerAutoLoad.DovrebbeLeggereTuttiILumpAutoloadInOrdine;
begin
  FLumps.AddLump('AUTOLOAD', 'first.pk3');
  FLumps.AddLump('AUTOLOAD', 'second.pk3 third.pk3');
  FReader.Load;
  Assert.AreEqual('[first.pk3][second.pk3][third.pk3]', Joined);
end;

procedure TTestScannerAutoLoad.DovrebbeTenereUnitiITestiTraVirgolette;
begin
  FLumps.AddLump('AUTOLOAD', '"my files\big pack.pk3" plain.pk3');
  FReader.Load;
  Assert.AreEqual('[my files\big pack.pk3][plain.pk3]', Joined);
end;

procedure TTestScannerAutoLoad.DovrebbeIgnorareICommenti;
begin
  FLumps.AddLump('AUTOLOAD', '// first the base'#13#10'base.pk3 // and nothing else'#13#10'extra.pk3');
  FReader.Load;
  Assert.AreEqual('[base.pk3][extra.pk3]', Joined);
end;

procedure TTestScannerAutoLoad.DovrebbeNonDareFileConUnLumpVuoto;
begin
  FLumps.AddLump('AUTOLOAD', '');
  FLumps.AddLump('AUTOLOAD', '   '#13#10'  ');
  FReader.Load;
  Assert.AreEqual(0, FSink.Files.Count);
end;

// Un file aggiunto puo' cambiare cio' che c'e' dopo: ogni nome va alla destinazione appena
// letto, prima di leggere il lump seguente (come faceva il vecchio W_AutoLoadPakFiles).
procedure TTestScannerAutoLoad.DovrebbeDareIFileUnoAllaVolta;
begin
  FLumps.AddLump('AUTOLOAD', 'a.pk3');
  FLumps.AddLump('AUTOLOAD', 'b.pk3');
  FReader.Load;
  Assert.AreEqual(2, FSink.Files.Count);
  Assert.AreEqual(1, FSink.TextReadsAtEachFile[0]);
  Assert.AreEqual(2, FSink.TextReadsAtEachFile[1]);
end;

procedure TTestScannerAutoLoad.DovrebbeLeggereSoloILumpPresentiAllAvvio;
begin
  FLumps.AddLump('AUTOLOAD', 'a.pk3');
  FSink.LumpToAdd := 'AUTOLOAD';
  FReader.Load;
  Assert.AreEqual('[a.pk3]', Joined);
  Assert.AreEqual(2, FLumps.GetCount);
end;

procedure TTestScannerAutoLoad.DovrebbeDistinguereMaiuscoleENelNomeDelLump;
begin
  // the engine gives the names of the lumps in upper case: another case is another lump
  FLumps.AddLump('autoload', 'a.pk3');
  FReader.Load;
  Assert.AreEqual(0, FSink.Files.Count);
end;

end.
