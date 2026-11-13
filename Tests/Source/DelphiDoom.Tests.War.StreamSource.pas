{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the source on a stream and the       }
{  factory                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.StreamSource;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.War.Types,
  DelphiDoom.War.Intf, DelphiDoom.War.StreamSource, DelphiDoom.War.Factory, DelphiDoom.Tests.War.Builders;

type
  [TestFixture]
  [Category('war')]
  TTestWarStreamSource = class(TObject)
  private
    FPath: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLaDimensioneDelFlusso;
    [Test]
    procedure DovrebbeLeggereDaUnaPosizione;
    [Test]
    procedure DovrebbeLeggereZeroByteSenzaToccareIlBuffer;
    [Test]
    procedure DovrebbeRifiutareUnaLetturaOltreLaFine;
    [Test]
    procedure DovrebbeRifiutareUnaPosizioneNegativa;
    [Test]
    procedure DovrebbeVolereUnFlusso;
    [Test]
    procedure DovrebbeLiberareIlFlussoSeLoPossiede;
    [Test]
    procedure DovrebbeAprireUnArchivioDaUnFile;
    [Test]
    procedure DovrebbeAprireUnArchivioDaUnFlussoEUsareIlCatalogo;
    [Test]
    procedure DovrebbeLiberareIlFlussoSeL_ArchivioRifiutaIDati;
  end;

implementation

type
  /// <summary>A stream that says when it is freed</summary>
  TFreedStream = class(TMemoryStream)
  strict private
    FFlag: PBoolean;
  public
    constructor Create(AFlag: PBoolean);
    destructor Destroy; override;
  end;

constructor TFreedStream.Create(AFlag: PBoolean);
begin
  inherited Create;
  FFlag := AFlag;
end;

destructor TFreedStream.Destroy;
begin
  FFlag^ := True;
  inherited Destroy;
end;

{ TTestWarStreamSource }

procedure TTestWarStreamSource.Setup;
var
  LBuilder: TWarArchiveBuilder;
begin
  FPath := TPath.Combine(TPath.GetTempPath, 'DelphiDoomWarTest-' + TGUID.NewGuid.ToString + '.war');
  LBuilder := TWarArchiveBuilder.Create;
  try
    LBuilder.AddUncompressed(WarBytesOf('Warcraft'));
    TFile.WriteAllBytes(FPath, LBuilder.Build($18));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestWarStreamSource.TearDown;
begin
  if TFile.Exists(FPath) then
    TFile.Delete(FPath);
end;

procedure TTestWarStreamSource.DovrebbeDareLaDimensioneDelFlusso;
var
  LStream: TBytesStream;
  LSource: IWarSource;
begin
  LStream := TBytesStream.Create(TBytes.Create(1, 2, 3));
  LSource := TWarStreamSource.Create(LStream, True);
  Assert.AreEqual(Int64(3), LSource.Size);
end;

procedure TTestWarStreamSource.DovrebbeLeggereDaUnaPosizione;
var
  LSource: IWarSource;
  LBuffer: array[0..1] of Byte;
begin
  LSource := TWarStreamSource.Create(TBytesStream.Create(TBytes.Create(10, 20, 30, 40)), True);
  LSource.ReadAt(2, LBuffer, 2);
  Assert.AreEqual(30, Integer(LBuffer[0]));
  Assert.AreEqual(40, Integer(LBuffer[1]));
  // e di nuovo da un'altra: la posizione del flusso non conta
  LSource.ReadAt(0, LBuffer, 1);
  Assert.AreEqual(10, Integer(LBuffer[0]));
end;

procedure TTestWarStreamSource.DovrebbeLeggereZeroByteSenzaToccareIlBuffer;
var
  LSource: IWarSource;
  LBuffer: Byte;
begin
  LSource := TWarStreamSource.Create(TBytesStream.Create(TBytes.Create(1)), True);
  LBuffer := 99;
  LSource.ReadAt(1, LBuffer, 0);
  Assert.AreEqual(99, Integer(LBuffer));
end;

procedure TTestWarStreamSource.DovrebbeRifiutareUnaLetturaOltreLaFine;
var
  LSource: IWarSource;
  LBuffer: array[0..3] of Byte;
begin
  LSource := TWarStreamSource.Create(TBytesStream.Create(TBytes.Create(1, 2, 3)), True);
  Assert.WillRaise(
    procedure
    begin
      LSource.ReadAt(1, LBuffer, 3);
    end, EWarException);
end;

procedure TTestWarStreamSource.DovrebbeRifiutareUnaPosizioneNegativa;
var
  LSource: IWarSource;
  LBuffer: Byte;
begin
  LSource := TWarStreamSource.Create(TBytesStream.Create(TBytes.Create(1, 2, 3)), True);
  Assert.WillRaise(
    procedure
    begin
      LSource.ReadAt(-1, LBuffer, 1);
    end, EWarException);
end;

procedure TTestWarStreamSource.DovrebbeVolereUnFlusso;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarStreamSource.Create(nil, False);
    end, EArgumentNilException);
end;

procedure TTestWarStreamSource.DovrebbeLiberareIlFlussoSeLoPossiede;
var
  LFreed: Boolean;
  LSource: IWarSource;
begin
  LFreed := False;
  LSource := TWarStreamSource.Create(TFreedStream.Create(@LFreed), True);
  Assert.IsFalse(LFreed);
  LSource := nil;
  Assert.IsTrue(LFreed);
end;

procedure TTestWarStreamSource.DovrebbeAprireUnArchivioDaUnFile;
var
  LArchive: IWarArchive;
begin
  LArchive := TWarFactory.OpenFile(FPath, nil);
  Assert.AreEqual(1, LArchive.EntryCount);
  Assert.AreEqual(8, Length(LArchive.ReadRecord(0)));
end;

procedure TTestWarStreamSource.DovrebbeAprireUnArchivioDaUnFlussoEUsareIlCatalogo;
var
  LArchive: IWarArchive;
  LCatalog: IWarCatalog;
begin
  LCatalog := TWarFactory.CreateCatalog;
  // il record 0 del catalogo e' musica: non e' saltato
  LArchive := TWarFactory.OpenStream(TFileStream.Create(FPath, fmOpenRead or fmShareDenyNone), True, LCatalog);
  Assert.IsTrue(LArchive.IsAvailable(0));
end;

procedure TTestWarStreamSource.DovrebbeLiberareIlFlussoSeL_ArchivioRifiutaIDati;
var
  LFreed: Boolean;
begin
  LFreed := False;
  Assert.WillRaise(
    procedure
    begin
      // dati vuoti: non e' un archivio
      TWarFactory.OpenStream(TFreedStream.Create(@LFreed), True, nil);
    end, EWarException);
  Assert.IsTrue(LFreed);
end;

end.
