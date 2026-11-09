{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedContainer                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.Container;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Speed.Intf;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedContainer = class(TObject)
  strict private
    function Open(const ABytes: TBytes): ISpeedContainer;
    function Sample: ISpeedContainer;
  public
    [Test]
    procedure DovrebbeLeggereIFileDelContenitore;
    [Test]
    procedure DovrebbeOrdinareIFilePerNumeroEPoiPerNome;
    [Test]
    procedure DovrebbeTrovareUnFilePerNomeEsatto;
    [Test]
    procedure DovrebbeNonTrovareUnNomeCheNonCe;
    [Test]
    procedure DovrebbeNonDistinguereMaiuscoleNellOrdineMaSiNellaRicerca;
    [Test]
    procedure DovrebbeDareIlPrimoFileSeUnNomeERipetuto;
    [Test]
    procedure DovrebbeLeggereIFileDiUnContenitoreCostruitoAlContrario;
    [Test]
    procedure DovrebbeLeggereUnFileVuoto;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareLaFirmaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnaDirectoryFuoriDalFile;
    [Test]
    procedure DovrebbeRifiutareUnFileFuoriDalContenitoreQuandoSiLegge;
    [Test]
    procedure DovrebbeRifiutareUnIndiceSbagliato;
    [Test]
    procedure DovrebbeLeggerePiuDelladimensioneDichiarataSeIlContenitoreLoHa;
    [Test]
    procedure DovrebbeLasciarePerdereLaLetturaOltreLaFineDelContenitore;
    [Test]
    procedure DovrebbeTogliereGliSpaziDalNome;
    [Test]
    procedure DovrebbeRifiutareUnoStreamNil;
    [Test]
    procedure DovrebbeAprireUnFileSuDisco;
    [Test]
    procedure DovrebbeDareLaDimensioneDelContenitore;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Container,
  DelphiDoom.Tests.Speed.JclBuilder;

{ TTestSpeedContainer }

function TTestSpeedContainer.Open(const ABytes: TBytes): ISpeedContainer;
begin
  Result := TSpeedContainer.Create(TBytesStream.Create(ABytes), True);
end;

function TTestSpeedContainer.Sample: ISpeedContainer;
var
  LBuilder: TJclBuilder;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('MENUS.S3M', TBytes.Create(1, 2, 3));
    LBuilder.Add('10.IS2', TBytes.Create(10));
    LBuilder.Add('2.IS2', TBytes.Create(2, 2));
    LBuilder.Add('GRAFS.PAL', TBytes.Create(7, 7, 7, 7));
    Result := Open(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestSpeedContainer.DovrebbeLeggereIFileDelContenitore;
var
  LContainer: ISpeedContainer;
  LData: TBytes;
begin
  LContainer := Sample;
  Assert.AreEqual(4, LContainer.Count);
  Assert.IsTrue(LContainer.TryRead('GRAFS.PAL', LData));
  Assert.AreEqual(4, Length(LData));
  Assert.AreEqual<Byte>(7, LData[3]);
  Assert.IsTrue(LContainer.TryRead('MENUS.S3M', LData));
  Assert.AreEqual<Byte>(3, LData[2]);
end;

procedure TTestSpeedContainer.DovrebbeOrdinareIFilePerNumeroEPoiPerNome;
var
  LContainer: ISpeedContainer;
begin
  LContainer := Sample;
  // the names without a number are 0: GRAFS.PAL, MENUS.S3M; then 2, then 10
  Assert.AreEqual('GRAFS.PAL', LContainer.Entries[0].Name);
  Assert.AreEqual('MENUS.S3M', LContainer.Entries[1].Name);
  Assert.AreEqual('2.IS2', LContainer.Entries[2].Name);
  Assert.AreEqual('10.IS2', LContainer.Entries[3].Name);
end;

procedure TTestSpeedContainer.DovrebbeTrovareUnFilePerNomeEsatto;
var
  LContainer: ISpeedContainer;
begin
  LContainer := Sample;
  Assert.AreEqual(2, LContainer.IndexOf('2.IS2'));
  Assert.AreEqual(2, LContainer.Entries[2].Size);
end;

procedure TTestSpeedContainer.DovrebbeNonTrovareUnNomeCheNonCe;
var
  LData: TBytes;
begin
  Assert.AreEqual(-1, Sample.IndexOf('NOPE.BIN'));
  Assert.IsFalse(Sample.TryRead('NOPE.BIN', LData));
  Assert.AreEqual(0, Length(LData));
end;

procedure TTestSpeedContainer.DovrebbeNonDistinguereMaiuscoleNellOrdineMaSiNellaRicerca;
begin
  // the old code compared the names as they are: a name in lower case is another name
  Assert.AreEqual(-1, Sample.IndexOf('grafs.pal'));
end;

procedure TTestSpeedContainer.DovrebbeDareIlPrimoFileSeUnNomeERipetuto;
var
  LBuilder: TJclBuilder;
  LContainer: ISpeedContainer;
  LData: TBytes;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('A.BIN', TBytes.Create(1));
    LBuilder.Add('A.BIN', TBytes.Create(2));
    LContainer := Open(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(2, LContainer.Count);
  Assert.IsTrue(LContainer.TryRead('A.BIN', LData));
  // the sort is stable: the first added stays first
  Assert.AreEqual<Byte>(1, LData[0]);
end;

procedure TTestSpeedContainer.DovrebbeLeggereIFileDiUnContenitoreCostruitoAlContrario;
var
  LContainer: ISpeedContainer;
  LIndex: Integer;
  LTotal: Integer;
begin
  // the data are one after the other and every file is found by its distance from the directory
  LContainer := TSpeedContainer.Create(TBytesStream.Create(TJclBuilder.SyntheticGame), True);
  LTotal := 0;
  for LIndex := 0 to LContainer.Count - 1 do
    LTotal := LTotal + Length(LContainer.Read(LIndex));
  Assert.IsTrue(LTotal > 300000);
  Assert.IsTrue(LContainer.IndexOf('GRAFS.DAT') >= 0);
  Assert.AreEqual(70 * 4096, Length(LContainer.Read(LContainer.IndexOf('GRAFS.DAT'))));
end;

procedure TTestSpeedContainer.DovrebbeLeggereUnFileVuoto;
var
  LBuilder: TJclBuilder;
  LContainer: ISpeedContainer;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('EMPTY.BIN', nil);
    LContainer := Open(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(0, Length(LContainer.Read(0)));
end;

procedure TTestSpeedContainer.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      Open(TBytes.Create(1, 2, 3));
    end, ESpeedException);
end;

procedure TTestSpeedContainer.DovrebbeRifiutareLaFirmaSbagliata;
var
  LBytes: TBytes;
begin
  LBytes := TJclBuilder.RandomBytes(1, 200, 255);
  Assert.WillRaise(
    procedure
    begin
      Open(LBytes);
    end, ESpeedException);
end;

procedure TTestSpeedContainer.DovrebbeRifiutareUnaDirectoryFuoriDalFile;
var
  LBuilder: TJclBuilder;
  LBytes: TBytes;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('A.BIN', TBytes.Create(1));
    LBytes := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
  // the offset of the directory is bigger than the file
  PInteger(@LBytes[Length(LBytes) - 4])^ := 100000;
  Assert.WillRaise(
    procedure
    begin
      Open(LBytes);
    end, ESpeedException);
end;

procedure TTestSpeedContainer.DovrebbeRifiutareUnFileFuoriDalContenitoreQuandoSiLegge;
var
  LBuilder: TJclBuilder;
  LContainer: ISpeedContainer;
begin
  LBuilder := TJclBuilder.Create;
  try
    // declares 1000 bytes and has 1
    LBuilder.AddWithDeclaredSize('A.BIN', TBytes.Create(1), 1000);
    LContainer := Open(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.WillRaise(
    procedure
    begin
      LContainer.Read(0);
    end, ESpeedException);
end;

procedure TTestSpeedContainer.DovrebbeRifiutareUnIndiceSbagliato;
var
  LContainer: ISpeedContainer;
begin
  LContainer := Sample;
  Assert.WillRaise(
    procedure
    begin
      LContainer.Read(99);
    end, ESpeedException);
  Assert.WillRaise(
    procedure
    begin
      LContainer.Entries[-1];
    end, ESpeedException);
end;

procedure TTestSpeedContainer.DovrebbeLeggerePiuDelladimensioneDichiarataSeIlContenitoreLoHa;
var
  LBuilder: TJclBuilder;
  LContainer: ISpeedContainer;
  LData: TBytes;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.AddWithDeclaredSize('A.BIN', TBytes.Create(1, 2, 3, 4, 5, 6), 2);
    LContainer := Open(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(2, Length(LContainer.Read(0)));
  LData := LContainer.ReadAtLeast(0, 5);
  Assert.AreEqual(5, Length(LData));
  Assert.AreEqual<Byte>(5, LData[4]);
  // asking for less than the entry has gives the entry
  Assert.AreEqual(2, Length(LContainer.ReadAtLeast(0, 1)));
end;

procedure TTestSpeedContainer.DovrebbeLasciarePerdereLaLetturaOltreLaFineDelContenitore;
var
  LBuilder: TJclBuilder;
  LContainer: ISpeedContainer;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('A.BIN', TBytes.Create(1, 2));
    LContainer := Open(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  // there are not 100000 bytes after the start: the entry is given as it is
  Assert.AreEqual(2, Length(LContainer.ReadAtLeast(0, 100000)));
end;

procedure TTestSpeedContainer.DovrebbeTogliereGliSpaziDalNome;
var
  LBuilder: TJclBuilder;
  LContainer: ISpeedContainer;
begin
  LBuilder := TJclBuilder.Create;
  try
    LBuilder.Add('SPACE.BIN  ', TBytes.Create(1));
    LContainer := Open(LBuilder.Build);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual('SPACE.BIN', LContainer.Entries[0].Name);
end;

procedure TTestSpeedContainer.DovrebbeRifiutareUnoStreamNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedContainer.Create(nil, False);
    end, EArgumentNilException);
end;

procedure TTestSpeedContainer.DovrebbeAprireUnFileSuDisco;
var
  LPath: string;
  LContainer: ISpeedContainer;
begin
  LPath := TPath.Combine(TPath.GetTempPath, TPath.GetGUIDFileName + '.jcl');
  TFile.WriteAllBytes(LPath, TJclBuilder.SyntheticGame);
  try
    LContainer := TSpeedContainer.Create(TFileStream.Create(LPath, fmOpenRead or fmShareDenyNone), True);
    Assert.IsTrue(LContainer.IndexOf('GRAFS.PAL') >= 0);
    LContainer := nil;
  finally
    TFile.Delete(LPath);
  end;
end;

procedure TTestSpeedContainer.DovrebbeDareLaDimensioneDelContenitore;
var
  LBytes: TBytes;
begin
  LBytes := TJclBuilder.SyntheticGame;
  Assert.AreEqual(Length(LBytes), Open(LBytes).Size);
end;

end.
