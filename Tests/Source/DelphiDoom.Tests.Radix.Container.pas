{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixContainer                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.Container;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixContainer = class(TObject)
  strict private
    FBuilder: TRadixDatBuilder;
    function Open: IRadixContainer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeContareILump;
    [Test]
    procedure DovrebbeLeggereIByteDiUnLump;
    [Test]
    procedure DovrebbeTrovareIlPrimoLumpConUnNome;
    [Test]
    procedure DovrebbeLeggereUnLumpVuoto;
    [Test]
    procedure DovrebbeDareFalsoPerUnLumpCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaLaFirma;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnaDirectoryFuoriDalFile;
    [Test]
    procedure DovrebbeRifiutareUnLumpFuoriDalFile;
    [Test]
    procedure DovrebbeAvereIRecordDellaDimensioneDelFormato;
    [Test]
    procedure DovrebbeLeggereUnNomeDiTrentaduCaratteriPerIntero;
  end;

implementation

{ TTestRadixContainer }

procedure TTestRadixContainer.Setup;
begin
  FBuilder := TRadixDatBuilder.Create;
  FBuilder.Add('First', [1, 2, 3]);
  FBuilder.Add('Second', [4, 5]);
  FBuilder.Add('First', [9, 9]);
  FBuilder.Add('Empty', nil);
end;

procedure TTestRadixContainer.TearDown;
begin
  FBuilder.Free;
end;

function TTestRadixContainer.Open: IRadixContainer;
begin
  Result := TRadixFactory.OpenContainerBytes(FBuilder.ToBytes);
end;

procedure TTestRadixContainer.DovrebbeContareILump;
begin
  Assert.AreEqual(4, Open.Count);
end;

procedure TTestRadixContainer.DovrebbeLeggereIByteDiUnLump;
var
  LBytes: TBytes;
begin
  Assert.IsTrue(Open.TryRead('Second', LBytes));
  Assert.AreEqual<TBytes>([4, 5], LBytes);
end;

procedure TTestRadixContainer.DovrebbeTrovareIlPrimoLumpConUnNome;
var
  LContainer: IRadixContainer;
begin
  LContainer := Open;
  Assert.AreEqual(0, LContainer.IndexOf('First'));
  Assert.AreEqual<TBytes>([1, 2, 3], LContainer.Read(0));
end;

procedure TTestRadixContainer.DovrebbeLeggereUnLumpVuoto;
var
  LContainer: IRadixContainer;
begin
  LContainer := Open;
  Assert.AreEqual<Integer>(0, Length(LContainer.Read(LContainer.IndexOf('Empty'))));
end;

procedure TTestRadixContainer.DovrebbeDareFalsoPerUnLumpCheNonCe;
var
  LBytes: TBytes;
begin
  Assert.IsFalse(Open.TryRead('Missing', LBytes));
  Assert.AreEqual(-1, Open.IndexOf('Missing'));
end;

procedure TTestRadixContainer.DovrebbeRifiutareUnFileSenzaLaFirma;
var
  LBytes: TBytes;
begin
  LBytes := FBuilder.ToBytes;
  LBytes[0] := Ord('X');
  Assert.WillRaise(
    procedure
    begin
      TRadixFactory.OpenContainerBytes(LBytes);
    end, ERadixException);
end;

procedure TTestRadixContainer.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TRadixFactory.OpenContainerBytes([1, 2, 3]);
    end, ERadixException);
end;

procedure TTestRadixContainer.DovrebbeRifiutareUnaDirectoryFuoriDalFile;
var
  LBytes: TBytes;
begin
  LBytes := FBuilder.ToBytes;
  // the directory is cut: its lumps are not all there
  SetLength(LBytes, Length(LBytes) - 10);
  Assert.WillRaise(
    procedure
    begin
      TRadixFactory.OpenContainerBytes(LBytes);
    end, ERadixException);
end;

procedure TTestRadixContainer.DovrebbeRifiutareUnLumpFuoriDalFile;
var
  LBuilder: TRadixDatBuilder;
  LContainer: IRadixContainer;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('A', [1]);
    LContainer := TRadixFactory.OpenContainerBytes(LBuilder.ToBytes);
    Assert.WillRaise(
      procedure
      begin
        LContainer.ReadAt(1000000, 4);
      end, ERadixException);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixContainer.DovrebbeAvereIRecordDellaDimensioneDelFormato;
begin
  Assert.AreEqual(25, SizeOf(TRadixHeaderRecord));
  Assert.AreEqual(46, SizeOf(TRadixLumpRecord));
  Assert.AreEqual(40, SizeOf(TRadixBitmapRecord));
end;

procedure TTestRadixContainer.DovrebbeLeggereUnNomeDiTrentaduCaratteriPerIntero;
var
  LBuilder: TRadixDatBuilder;
  LContainer: IRadixContainer;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    // 32 characters: no zero ends the name, it is read whole
    LBuilder.Add(StringOfChar('N', 32), [1]);
    LContainer := TRadixFactory.OpenContainerBytes(LBuilder.ToBytes);
    Assert.AreEqual(StringOfChar('N', 32), LContainer.Infos[0].Name);
  finally
    LBuilder.Free;
  end;
end;

end.
