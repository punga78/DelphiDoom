{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorDdvoxFormat (issue #167)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Ddvox;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Model;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorDdvoxFormat = class(TObject)
  strict private
    FModel: TVoxelEditorModel;
    function Bytes(const AText: string): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereIlTestoDelVecchio;
    [Test]
    procedure DovrebbeScrivereUnaRigaPiena;
    [Test]
    procedure DovrebbeRileggereCioCheHaScritto;
    [Test]
    procedure DovrebbeLeggereNumeriEsadecimaliESkipInOgniCaso;
    [Test]
    procedure DovrebbeLeggereTraDueDimensioni;
    [Test]
    procedure DovrebbeRifiutareUnFileVuoto;
    [Test]
    procedure DovrebbeRifiutareUnaParolaCheNonEUnNumero;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneFuoriDaiLimiti;
    [Test]
    procedure DovrebbeRifiutareUnSkipCheSupera;
    [Test]
    procedure DovrebbeRifiutareUnSkipSenzaNumero;
    [Test]
    procedure DovrebbeFermarsiQuandoIlCuboEPieno;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Format.Ddvox;

procedure TTestVoxelEditorDdvoxFormat.Setup;
begin
  FModel := TVoxelEditorModel.Create(2);
end;

procedure TTestVoxelEditorDdvoxFormat.TearDown;
begin
  FModel.Free;
end;

function TTestVoxelEditorDdvoxFormat.Bytes(const AText: string): TBytes;
begin
  Result := TEncoding.ANSI.GetBytes(AText);
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeScrivereIlTestoDelVecchio;
begin
  FModel.Put(0, 0, 0, 5);
  Assert.AreEqual('2'#13#10'5, skip 1'#13#10'skip 2'#13#10'skip 2'#13#10'skip 2'#13#10,
    TEncoding.ANSI.GetString(TVoxelEditorDdvoxFormat.Write(FModel)));
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeScrivereUnaRigaPiena;
begin
  FModel.Put(1, 1, 0, 7);
  FModel.Put(1, 1, 1, 8);
  FModel.Put(0, 1, 1, 9);
  Assert.AreEqual('2'#13#10'skip 2'#13#10'skip 1, 9'#13#10'skip 2'#13#10'7, 8'#13#10,
    TEncoding.ANSI.GetString(TVoxelEditorDdvoxFormat.Write(FModel)));
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeRileggereCioCheHaScritto;
var
  LRead: TVoxelEditorModel;
begin
  FModel.Put(0, 1, 0, 100);
  FModel.Put(1, 0, 1, 200);
  LRead := TVoxelEditorModel.Create(1);
  try
    TVoxelEditorDdvoxFormat.Read(TVoxelEditorDdvoxFormat.Write(FModel), LRead);
    Assert.AreEqual(2, LRead.Size);
    Assert.AreEqual(Cardinal(100), LRead.Get(0, 1, 0));
    Assert.AreEqual(Cardinal(200), LRead.Get(1, 0, 1));
    Assert.AreEqual(2, LRead.CountVoxels);
  finally
    LRead.Free;
  end;
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeLeggereNumeriEsadecimaliESkipInOgniCaso;
begin
  TVoxelEditorDdvoxFormat.Read(Bytes('2'#9'$10  0x20,SKIP 1' + #10 + '5' + #13#10 + 'skip 2 skip 2'), FModel);
  Assert.AreEqual(Cardinal($10), FModel.Get(0, 0, 0));
  Assert.AreEqual(Cardinal($20), FModel.Get(0, 0, 1));
  Assert.AreEqual(Cardinal(0), FModel.Get(0, 1, 0));
  Assert.AreEqual(Cardinal(5), FModel.Get(0, 1, 1));
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeLeggereTraDueDimensioni;
begin
  TVoxelEditorDdvoxFormat.Read(Bytes('3 skip 3 skip 3 skip 3 skip 3 skip 3 skip 3 skip 3 skip 3 skip 3'), FModel);
  Assert.AreEqual(3, FModel.Size);
  Assert.AreEqual(0, FModel.CountVoxels);
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeRifiutareUnFileVuoto;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(nil, FModel); end, EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('  '#13#10), FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeRifiutareUnaParolaCheNonEUnNumero;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('hello'), FModel); end, EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('2 abc'), FModel); end, EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('2 0xZZ'), FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeRifiutareUnaDimensioneFuoriDaiLimiti;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('0'), FModel); end, EVoxelEditorException);
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('300 skip 1'), FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeRifiutareUnSkipCheSupera;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('2 skip 3'), FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeRifiutareUnSkipSenzaNumero;
begin
  Assert.WillRaise(procedure begin TVoxelEditorDdvoxFormat.Read(Bytes('2 skip'), FModel); end, EVoxelEditorException);
end;

procedure TTestVoxelEditorDdvoxFormat.DovrebbeFermarsiQuandoIlCuboEPieno;
begin
  TVoxelEditorDdvoxFormat.Read(Bytes('1 5 6 7 8'), FModel);
  Assert.AreEqual(1, FModel.Size);
  Assert.AreEqual(Cardinal(5), FModel.Get(0, 0, 0));
end;

end.
