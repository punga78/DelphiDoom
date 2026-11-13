{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the PWAD in memory                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.PwadAssembler;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Nodes.Types, DelphiDoom.Nodes.PwadAssembler;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesPwadAssembler = class(TObject)
  strict private
    FAssembler: TNodesPwadAssembler;
    function EntryAt(const ABytes: TBytes; AIndex: Integer): TNodesWadEntry;
    function NameOf(const AEntry: TNodesWadEntry): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestSenzaLumpDovrebbeDareSoloLIntestazione;
    [Test]
    procedure TestLIntestazioneDovrebbeDireIdNumeroEPosizioneDellaDirectory;
    [Test]
    procedure TestIDatiDovrebberoSeguireLIntestazioneSenzaPadding;
    [Test]
    procedure TestLaDirectoryDovrebbeDareNomePosizioneEDimensione;
    [Test]
    procedure TestUnLumpVuotoDovrebbeAvereLaPosizioneDellaFineDeiDati;
    [Test]
    procedure TestUnLumpAssenteDovrebbeAvereLaPosizioneZero;
    [Test]
    procedure TestUnaVoceVuotaDovrebbeEssereTuttaZeri;
    [Test]
    procedure TestUnNomeLungoDovrebbeEssereTagliatoAOttoCaratteri;
    [Test]
    procedure TestIlNomeDovrebbeEssereRiempitoConZeri;
    [Test]
    procedure TestUnByteAltoDelNomeDovrebbeEssereConservato;
  end;

implementation

{ TTestNodesPwadAssembler }

procedure TTestNodesPwadAssembler.Setup;
begin
  FAssembler := TNodesPwadAssembler.Create;
end;

procedure TTestNodesPwadAssembler.TearDown;
begin
  FAssembler.Free;
end;

function TTestNodesPwadAssembler.EntryAt(const ABytes: TBytes; AIndex: Integer): TNodesWadEntry;
var
  LHeader: TNodesWadHeader;
begin
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  Move(ABytes[LHeader.DirectoryOffset + AIndex * SizeOf(TNodesWadEntry)], Result, SizeOf(Result));
end;

function TTestNodesPwadAssembler.NameOf(const AEntry: TNodesWadEntry): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to 7 do
    if AEntry.Name[LIndex] <> #0 then
      Result := Result + Char(AEntry.Name[LIndex]);
end;

procedure TTestNodesPwadAssembler.TestSenzaLumpDovrebbeDareSoloLIntestazione;
begin
  Assert.AreEqual<Integer>(12, Length(FAssembler.Build));
end;

procedure TTestNodesPwadAssembler.TestLIntestazioneDovrebbeDireIdNumeroEPosizioneDellaDirectory;
var
  LBytes: TBytes;
  LHeader: TNodesWadHeader;
begin
  FAssembler.AddLump('A', TBytes.Create(1, 2, 3));
  FAssembler.AddLump('B', TBytes.Create(4));
  LBytes := FAssembler.Build;
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  Assert.AreEqual('PWAD', TEncoding.ASCII.GetString(LBytes, 0, 4));
  Assert.AreEqual(2, LHeader.LumpCount);
  Assert.AreEqual(12 + 4, LHeader.DirectoryOffset);
  Assert.AreEqual<Integer>(12 + 4 + 2 * 16, Length(LBytes));
end;

procedure TTestNodesPwadAssembler.TestIDatiDovrebberoSeguireLIntestazioneSenzaPadding;
var
  LBytes: TBytes;
begin
  FAssembler.AddLump('A', TBytes.Create(1, 2, 3));
  FAssembler.AddLump('B', TBytes.Create(4, 5));
  LBytes := FAssembler.Build;
  Assert.AreEqual(Byte(1), LBytes[12]);
  Assert.AreEqual(Byte(3), LBytes[14]);
  Assert.AreEqual(Byte(4), LBytes[15]);
  Assert.AreEqual(Byte(5), LBytes[16]);
end;

procedure TTestNodesPwadAssembler.TestLaDirectoryDovrebbeDareNomePosizioneEDimensione;
var
  LBytes: TBytes;
  LEntry: TNodesWadEntry;
begin
  FAssembler.AddLump('THINGS', TBytes.Create(1, 2, 3));
  FAssembler.AddLump('LINEDEFS', TBytes.Create(4, 5));
  LBytes := FAssembler.Build;
  LEntry := EntryAt(LBytes, 1);
  Assert.AreEqual('LINEDEFS', NameOf(LEntry));
  Assert.AreEqual(15, LEntry.Position);
  Assert.AreEqual(2, LEntry.Size);
end;

procedure TTestNodesPwadAssembler.TestUnLumpVuotoDovrebbeAvereLaPosizioneDellaFineDeiDati;
var
  LBytes: TBytes;
  LEntry: TNodesWadEntry;
begin
  FAssembler.AddEmptyLump('MAP01');
  FAssembler.AddLump('A', TBytes.Create(1, 2, 3));
  FAssembler.AddEmptyLump('SEGS');
  LBytes := FAssembler.Build;
  Assert.AreEqual(12, EntryAt(LBytes, 0).Position);
  LEntry := EntryAt(LBytes, 2);
  Assert.AreEqual(15, LEntry.Position);
  Assert.AreEqual(0, LEntry.Size);
end;

procedure TTestNodesPwadAssembler.TestUnLumpAssenteDovrebbeAvereLaPosizioneZero;
var
  LBytes: TBytes;
  LEntry: TNodesWadEntry;
begin
  FAssembler.AddLump('A', TBytes.Create(1));
  FAssembler.AddAbsentLump('BEHAVIOR');
  LBytes := FAssembler.Build;
  LEntry := EntryAt(LBytes, 1);
  Assert.AreEqual('BEHAVIOR', NameOf(LEntry));
  Assert.AreEqual(0, LEntry.Position);
  Assert.AreEqual(0, LEntry.Size);
end;

procedure TTestNodesPwadAssembler.TestUnaVoceVuotaDovrebbeEssereTuttaZeri;
var
  LBytes: TBytes;
  LEntry: TNodesWadEntry;
begin
  FAssembler.AddBlankEntry;
  LBytes := FAssembler.Build;
  LEntry := EntryAt(LBytes, 0);
  Assert.AreEqual(0, LEntry.Position);
  Assert.AreEqual(0, LEntry.Size);
  Assert.AreEqual('', NameOf(LEntry));
  Assert.AreEqual(1, FAssembler.EntryCount);
end;

procedure TTestNodesPwadAssembler.TestUnNomeLungoDovrebbeEssereTagliatoAOttoCaratteri;
var
  LBytes: TBytes;
begin
  FAssembler.AddEmptyLump('ABCDEFGHIJ');
  LBytes := FAssembler.Build;
  Assert.AreEqual('ABCDEFGH', NameOf(EntryAt(LBytes, 0)));
end;

procedure TTestNodesPwadAssembler.TestIlNomeDovrebbeEssereRiempitoConZeri;
var
  LBytes: TBytes;
  LEntry: TNodesWadEntry;
  LIndex: Integer;
begin
  FAssembler.AddEmptyLump('AB');
  LBytes := FAssembler.Build;
  LEntry := EntryAt(LBytes, 0);
  for LIndex := 2 to 7 do
    Assert.AreEqual(0, Integer(Ord(LEntry.Name[LIndex])));
end;

procedure TTestNodesPwadAssembler.TestUnByteAltoDelNomeDovrebbeEssereConservato;
var
  LBytes: TBytes;
begin
  FAssembler.AddEmptyLump(string(Char(200)) + 'X');
  LBytes := FAssembler.Build;
  Assert.AreEqual(200, Integer(Ord(EntryAt(LBytes, 0).Name[0])));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesPwadAssembler);

end.
