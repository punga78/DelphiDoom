{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MUSINFO library - the loader                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MusInfo.Loader;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.MusInfo.Types,
  DelphiDoom.MusInfo.Intf, DelphiDoom.Tests.MusInfo.Fakes;

type
  /// <summary>A parser that gives what it was told to, and remembers the text it was given</summary>
  TFakeParser = class(TInterfacedObject, IMusInfoParser)
  private
    FEntries: TArray<TMusInfoEntry>;
    FLastText: string;
    FCalls: Integer;
  public
    constructor Create(const AEntries: TArray<TMusInfoEntry>);
    function Parse(const AText: string): TArray<TMusInfoEntry>;
    property LastText: string read FLastText;
    property Calls: Integer read FCalls;
  end;

  /// <summary>A catalog that only collects what is added to it</summary>
  TFakeCatalog = class(TInterfacedObject, IMusInfoCatalog)
  private
    FAdded: TList<TMusInfoEntry>;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AEntry: TMusInfoEntry): Boolean;
    procedure Clear;
    function Find(AMusicId: Integer; const AMapName: string): Integer;
    function Count: Integer;
    function GetEntry(AIndex: Integer): TMusInfoEntry;
    property Added: TList<TMusInfoEntry> read FAdded;
  end;

  [TestFixture]
  [Category('musinfo')]
  TTestMusInfoLoader = class(TObject)
  public
    [Test]
    procedure TestDovrebbeChiedereIlLumpMusinfo;
    [Test]
    procedure TestNonDovrebbeFareNullaSeNonCeIlLump;
    [Test]
    procedure TestDovrebbeDareIlTestoDelLumpAlParser;
    [Test]
    procedure TestDovrebbeAggiungereAlCatalogoLeVociNellOrdineDelParser;
    [Test]
    procedure TestDovrebbeLeggereUnLumpVeroConIlCatalogoVero;
    [Test]
    procedure TestUnaSecondaLetturaDovrebbeAggiungereESostituire;
    [Test]
    procedure TestUnLumpMancanteNonDovrebbeSvuotareIlCatalogo;
    [Test]
    procedure TestDovrebbeRifiutareLeDipendenzeMancanti;
  end;

implementation

uses
  DelphiDoom.MusInfo.Factory;

function MakeEntry(const AMap: string; AId: Integer; const AName: string): TMusInfoEntry;
begin
  Result.MapName := AMap;
  Result.MusicId := AId;
  Result.MusicName := AName;
  Result.MusicNumber := -1;
end;

{ TFakeParser }

constructor TFakeParser.Create(const AEntries: TArray<TMusInfoEntry>);
begin
  inherited Create;
  FEntries := AEntries;
end;

function TFakeParser.Parse(const AText: string): TArray<TMusInfoEntry>;
begin
  FLastText := AText;
  Inc(FCalls);
  Result := FEntries;
end;

{ TFakeCatalog }

constructor TFakeCatalog.Create;
begin
  inherited Create;
  FAdded := TList<TMusInfoEntry>.Create;
end;

destructor TFakeCatalog.Destroy;
begin
  FAdded.Free;
  inherited Destroy;
end;

function TFakeCatalog.Add(const AEntry: TMusInfoEntry): Boolean;
begin
  FAdded.Add(AEntry);
  Result := True;
end;

procedure TFakeCatalog.Clear;
begin
  FAdded.Clear;
end;

function TFakeCatalog.Find(AMusicId: Integer; const AMapName: string): Integer;
begin
  Result := -1;
end;

function TFakeCatalog.Count: Integer;
begin
  Result := FAdded.Count;
end;

function TFakeCatalog.GetEntry(AIndex: Integer): TMusInfoEntry;
begin
  Result := FAdded[AIndex];
end;

{ TTestMusInfoLoader }

procedure TTestMusInfoLoader.TestDovrebbeChiedereIlLumpMusinfo;
var
  LSource: TFakeTextSource;
  LSourceIntf: IMusInfoTextSource;
begin
  LSource := TFakeTextSource.Create(False, '');
  LSourceIntf := LSource;
  TMusInfoFactory.CreateLoader(LSourceIntf, TFakeParser.Create(nil), TFakeCatalog.Create).Load;
  Assert.AreEqual('MUSINFO', LSource.AskedName);
end;

procedure TTestMusInfoLoader.TestNonDovrebbeFareNullaSeNonCeIlLump;
var
  LParser: TFakeParser;
  LParserIntf: IMusInfoParser;
  LCatalog: TFakeCatalog;
  LCatalogIntf: IMusInfoCatalog;
begin
  LParser := TFakeParser.Create(nil);
  LParserIntf := LParser;
  LCatalog := TFakeCatalog.Create;
  LCatalogIntf := LCatalog;
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(False, ''), LParserIntf, LCatalogIntf).Load;
  Assert.AreEqual(0, LParser.Calls, 'senza lump il parser non parte');
  Assert.AreEqual(0, LCatalog.Added.Count);
end;

procedure TTestMusInfoLoader.TestDovrebbeDareIlTestoDelLumpAlParser;
var
  LParser: TFakeParser;
  LParserIntf: IMusInfoParser;
begin
  LParser := TFakeParser.Create(nil);
  LParserIntf := LParser;
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(True, 'MAP01 1 D_ONE'), LParserIntf,
    TFakeCatalog.Create).Load;
  Assert.AreEqual('MAP01 1 D_ONE', LParser.LastText);
  Assert.AreEqual(1, LParser.Calls);
end;

procedure TTestMusInfoLoader.TestDovrebbeAggiungereAlCatalogoLeVociNellOrdineDelParser;
var
  LCatalog: TFakeCatalog;
  LCatalogIntf: IMusInfoCatalog;
begin
  LCatalog := TFakeCatalog.Create;
  LCatalogIntf := LCatalog;
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(True, 'x'),
    TFakeParser.Create([MakeEntry('MAP02', 2, 'D_B'), MakeEntry('MAP01', 1, 'D_A')]),
    LCatalogIntf).Load;
  Assert.AreEqual(2, LCatalog.Added.Count);
  Assert.AreEqual('MAP02', LCatalog.Added[0].MapName);
  Assert.AreEqual('MAP01', LCatalog.Added[1].MapName);
end;

procedure TTestMusInfoLoader.TestDovrebbeLeggereUnLumpVeroConIlCatalogoVero;
var
  LCatalog: IMusInfoCatalog;
begin
  LCatalog := TMusInfoFactory.CreateCatalog(TFakeMusic.Create, nil);
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(True, 'E1M1 1 D_ONE'#13#10'E1M2 2 D_TWO'),
    TMusInfoFactory.CreateParser(nil), LCatalog).Load;
  Assert.AreEqual(2, LCatalog.Count);
  Assert.AreEqual(TFakeMusic.NumberOf('D_TWO'), LCatalog.Find(2, 'E1M2'));
end;

procedure TTestMusInfoLoader.TestUnaSecondaLetturaDovrebbeAggiungereESostituire;
var
  LCatalog: IMusInfoCatalog;
begin
  LCatalog := TMusInfoFactory.CreateCatalog(TFakeMusic.Create, nil);
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(True, 'MAP01 1 D_ONE MAP02 1 D_TWO'),
    TMusInfoFactory.CreateParser(nil), LCatalog).Load;
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(True, 'MAP02 1 D_THREE MAP03 1 D_FOUR'),
    TMusInfoFactory.CreateParser(nil), LCatalog).Load;
  Assert.AreEqual(3, LCatalog.Count);
  Assert.AreEqual(TFakeMusic.NumberOf('D_THREE'), LCatalog.Find(1, 'MAP02'));
end;

procedure TTestMusInfoLoader.TestUnLumpMancanteNonDovrebbeSvuotareIlCatalogo;
var
  LCatalog: IMusInfoCatalog;
begin
  LCatalog := TMusInfoFactory.CreateCatalog(TFakeMusic.Create, nil);
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(True, 'MAP01 1 D_ONE'),
    TMusInfoFactory.CreateParser(nil), LCatalog).Load;
  TMusInfoFactory.CreateLoader(TFakeTextSource.Create(False, ''),
    TMusInfoFactory.CreateParser(nil), LCatalog).Load;
  Assert.AreEqual(1, LCatalog.Count);
end;

procedure TTestMusInfoLoader.TestDovrebbeRifiutareLeDipendenzeMancanti;
begin
  Assert.WillRaise(
    procedure
    begin
      TMusInfoFactory.CreateLoader(nil, TFakeParser.Create(nil), TFakeCatalog.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TMusInfoFactory.CreateLoader(TFakeTextSource.Create(False, ''), nil, TFakeCatalog.Create);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TMusInfoFactory.CreateLoader(TFakeTextSource.Create(False, ''), TFakeParser.Create(nil), nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMusInfoLoader);

end.
