{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - the test PK3 of the issue #48        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.Pk3;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   Reads Tests\Data\Pk3\zpktest.pk3 (a PK3 of textures, flats, voxels and sounds) and
  ///   zpkhires.wad (a PWAD with HI_START/HI_END, TX_START/TX_END and PK3ENTRY) with the classes
  ///   of the library, without the engine: container, list of the entries, bytes of every entry
  ///   against the loose files of Tests\Data\Pk3\src and the signatures that w_pak.pas looks at
  ///   to tell the images apart. The files come from Make-Pk3.ps1 (see the README of the folder)
  /// </summary>
  [TestFixture]
  [Category('wad')]
  [Category('pk3')]
  TTestWadPk3 = class(TObject)
  private
    FDataDir: string;
    FPk3: IWadSource;
    FHires: IWadSource;
    function SourceBytes(const AEntryName: string): TBytes;
    function IndexOfEntry(const ASource: IWadSource; const AName: string): Integer;
    function EntryBytes(const ASource: IWadSource; const AName: string): TBytes;
    function StartsWith(const ABytes: TBytes; const AMagic: array of Byte; AOffset: Integer = 0): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAprireIlPk3ComeZip;
    [Test]
    procedure DovrebbeElencareLeQuindiciVociDelPk3;
    [Test]
    procedure DovrebbeLeggereOgniVoceUgualeAlFileSciolto;
    [Test]
    procedure DovrebbeDareLeDimensioniDelleVociUgualiAQuelleDeiFile;
    [Test]
    procedure DovrebbeTrovareLeIntestazioniDelleImmaginiDelPk3;
    [Test]
    procedure DovrebbeTrovareLeIntestazioniDeiSuoniDelPk3;
    [Test]
    procedure DovrebbeLeggereIlTestoDiVoxeldef;
    [Test]
    procedure DovrebbeAprireIlWadDelleImmaginiAdAltaRisoluzione;
    [Test]
    procedure DovrebbeTrovareLeImmaginiTraHiStartEHiEnd;
    [Test]
    procedure DovrebbeTrovareLeImmaginiTraTxStartETxEnd;
    [Test]
    procedure DovrebbeLeggereLAliasDelSuonoInPk3Entry;
    [Test]
    procedure DovrebbeUnireIlPk3EIlWadInUnaDirectory;
  end;

implementation

uses
  DelphiDoom.Wad.Factory;

const
  ENTRY_NAMES: array[0..14] of string = (
    'TEXTURES/ZPKPNG.PNG', 'TEXTURES/ZPKTGA.TGA', 'TEXTURES/ZPKBMP.BMP', 'TEXTURES/ZPKJPG.JPG',
    'TEXTURES/ZPKPCX.PCX', 'TEXTURES/ZPKPAT.PATCH', 'TEXTURES/ZPKFLT.FLAT', 'FLATS/ZPKFLAT.PNG',
    'VOXELS/ZVKAA.KVX', 'VOXELS/ZVDAA.DDVOX', 'VOXELS/ZVSAA.VOX', 'VOXELDEF',
    'SOUNDS/ZPKWAV.WAV', 'SOUNDS/ZPKOGG.OGG', 'SOUNDS/ZPKFLC.FLAC');

  HIRES_LUMPS: array[0..14] of string = (
    'HI_START', 'ZWTGA', 'ZWPNG', 'ZWBMP', 'ZWJPG', 'ZWPCX', 'ZWPAT', 'ZWFLT', 'HI_END',
    'TX_START', 'ZXPNG', 'ZXTGA', 'TX_END', 'ZWSND', 'PK3ENTRY');

  MAGIC_PNG: array[0..3] of Byte = ($89, $50, $4E, $47);
  MAGIC_TGA: array[0..3] of Byte = (0, 0, 2, 0);
  MAGIC_BMP: array[0..1] of Byte = ($42, $4D);
  MAGIC_JFIF: array[0..3] of Byte = ($4A, $46, $49, $46);
  MAGIC_PCX: array[0..1] of Byte = ($0A, $05);
  MAGIC_PATCH: array[0..3] of Byte = (64, 0, 64, 0);
  MAGIC_OGG: array[0..3] of Byte = ($4F, $67, $67, $53);
  MAGIC_FLAC: array[0..3] of Byte = ($66, $4C, $61, $43);
  MAGIC_RIFF: array[0..3] of Byte = ($52, $49, $46, $46);
  MAGIC_WAVE: array[0..3] of Byte = ($57, $41, $56, $45);

{ TTestWadPk3 }

procedure TTestWadPk3.Setup;
begin
  FDataDir := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..\Tests\Data\Pk3'));
  FPk3 := TWadFactory.OpenPath(TPath.Combine(FDataDir, 'zpktest.pk3'));
  FHires := TWadFactory.OpenPath(TPath.Combine(FDataDir, 'zpkhires.wad'));
end;

procedure TTestWadPk3.TearDown;
begin
  FPk3 := nil;
  FHires := nil;
end;

function TTestWadPk3.SourceBytes(const AEntryName: string): TBytes;
begin
  // the entry names are in capitals and have forward slashes; the files of src are found
  // by their name without caring about the case (Windows)
  Result := TFile.ReadAllBytes(TPath.Combine(TPath.Combine(FDataDir, 'src'),
    StringReplace(AEntryName, '/', '\', [rfReplaceAll])));
end;

function TTestWadPk3.IndexOfEntry(const ASource: IWadSource; const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to ASource.Count - 1 do
    if ASource.Entries[LIndex].Name = AName then
      Exit(LIndex);
  Result := -1;
end;

function TTestWadPk3.EntryBytes(const ASource: IWadSource; const AName: string): TBytes;
var
  LIndex: Integer;
begin
  LIndex := IndexOfEntry(ASource, AName);
  Assert.IsTrue(LIndex >= 0, 'voce assente: ' + AName);
  Result := ASource.ReadEntry(LIndex);
end;

function TTestWadPk3.StartsWith(const ABytes: TBytes; const AMagic: array of Byte;
  AOffset: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := Length(ABytes) >= AOffset + Length(AMagic);
  if Result then
    for LIndex := 0 to High(AMagic) do
      if ABytes[AOffset + LIndex] <> AMagic[LIndex] then
        Exit(False);
end;

procedure TTestWadPk3.DovrebbeAprireIlPk3ComeZip;
begin
  Assert.AreEqual(Ord(TWadSourceKind.Zip), Ord(FPk3.Kind), 'dovrebbe riconoscere uno ZIP dai primi byte');
  Assert.AreEqual(Length(ENTRY_NAMES), Integer(FPk3.Count), 'dovrebbe avere una voce per file');
end;

procedure TTestWadPk3.DovrebbeElencareLeQuindiciVociDelPk3;
var
  LName: string;
begin
  for LName in ENTRY_NAMES do
    Assert.IsTrue(IndexOfEntry(FPk3, LName) >= 0, 'dovrebbe avere la voce ' + LName);
end;

procedure TTestWadPk3.DovrebbeLeggereOgniVoceUgualeAlFileSciolto;
var
  LName: string;
  LExpected, LActual: TBytes;
begin
  for LName in ENTRY_NAMES do
  begin
    LExpected := SourceBytes(LName);
    LActual := EntryBytes(FPk3, LName);
    Assert.AreEqual(Integer(Length(LExpected)), Integer(Length(LActual)), 'dimensione di ' + LName);
    Assert.IsTrue(CompareMem(@LExpected[0], @LActual[0], Length(LExpected)), 'byte di ' + LName);
  end;
end;

procedure TTestWadPk3.DovrebbeDareLeDimensioniDelleVociUgualiAQuelleDeiFile;
var
  LName: string;
begin
  for LName in ENTRY_NAMES do
    Assert.AreEqual(Integer(Length(SourceBytes(LName))), FPk3.Entries[IndexOfEntry(FPk3, LName)].Size,
      'Size di ' + LName);
end;

procedure TTestWadPk3.DovrebbeTrovareLeIntestazioniDelleImmaginiDelPk3;
var
  LBytes: TBytes;
begin
  LBytes := EntryBytes(FPk3, 'TEXTURES/ZPKPNG.PNG');
  Assert.IsTrue(StartsWith(LBytes, MAGIC_PNG), 'PNG');
  // w_pak.pas tells a PNG by the bytes 1..3 ("PNG")
  Assert.IsTrue(StartsWith(LBytes, [$50, $4E, $47], 1), 'PNG: i byte 1..3');
  Assert.IsTrue(StartsWith(EntryBytes(FPk3, 'FLATS/ZPKFLAT.PNG'), MAGIC_PNG), 'PNG dei flat');
  Assert.IsTrue(StartsWith(EntryBytes(FPk3, 'TEXTURES/ZPKTGA.TGA'), MAGIC_TGA), 'TGA: tipo 2, nessuna mappa');
  Assert.IsTrue(StartsWith(EntryBytes(FPk3, 'TEXTURES/ZPKBMP.BMP'), MAGIC_BMP), 'BMP');
  LBytes := EntryBytes(FPk3, 'TEXTURES/ZPKJPG.JPG');
  Assert.IsTrue(StartsWith(LBytes, [$FF, $D8]), 'JPEG: SOI');
  Assert.IsTrue(StartsWith(LBytes, MAGIC_JFIF, 6), 'JPEG: JFIF ai byte 6..9, come cerca w_pak');
  Assert.IsTrue(StartsWith(EntryBytes(FPk3, 'TEXTURES/ZPKPCX.PCX'), MAGIC_PCX), 'PCX: versione 5');
  Assert.IsTrue(StartsWith(EntryBytes(FPk3, 'TEXTURES/ZPKPAT.PATCH'), MAGIC_PATCH), 'patch 64x64');
  Assert.AreEqual(4096, Integer(Length(EntryBytes(FPk3, 'TEXTURES/ZPKFLT.FLAT'))), 'flat 64x64');
end;

procedure TTestWadPk3.DovrebbeTrovareLeIntestazioniDeiSuoniDelPk3;
var
  LBytes: TBytes;
begin
  LBytes := EntryBytes(FPk3, 'SOUNDS/ZPKWAV.WAV');
  Assert.IsTrue(StartsWith(LBytes, MAGIC_RIFF), 'WAV: RIFF');
  Assert.IsTrue(StartsWith(LBytes, MAGIC_WAVE, 8), 'WAV: WAVE');
  Assert.IsTrue(StartsWith(EntryBytes(FPk3, 'SOUNDS/ZPKOGG.OGG'), MAGIC_OGG), 'OGG: OggS');
  Assert.IsTrue(StartsWith(EntryBytes(FPk3, 'SOUNDS/ZPKFLC.FLAC'), MAGIC_FLAC), 'FLAC: fLaC');
end;

procedure TTestWadPk3.DovrebbeLeggereIlTestoDiVoxeldef;
var
  LText: string;
  LBytes: TBytes;
begin
  LBytes := EntryBytes(FPk3, 'VOXELDEF');
  LText := TEncoding.ASCII.GetString(LBytes);
  Assert.IsTrue(Pos('voxeldef "zvkaa.kvx"', LText) > 0, 'dovrebbe nominare il KVX');
  Assert.IsTrue(Pos('voxeldef "zvdaa.ddvox"', LText) > 0, 'dovrebbe nominare il DDVOX');
  Assert.IsTrue(Pos('voxeldef "zvsaa.vox"', LText) > 0, 'dovrebbe nominare il VOX');
  Assert.IsTrue(Pos('replaces sprite treda', LText) > 0, 'dovrebbe sostituire uno sprite di Doom');
end;

procedure TTestWadPk3.DovrebbeAprireIlWadDelleImmaginiAdAltaRisoluzione;
var
  LIndex: Integer;
begin
  Assert.AreEqual(Ord(TWadSourceKind.Wad), Ord(FHires.Kind), 'dovrebbe essere un WAD');
  Assert.AreEqual(Length(HIRES_LUMPS), Integer(FHires.Count), 'dovrebbe avere 15 lump');
  for LIndex := 0 to High(HIRES_LUMPS) do
    Assert.AreEqual(HIRES_LUMPS[LIndex], FHires.Entries[LIndex].Name, 'lump ' + IntToStr(LIndex));
end;

procedure TTestWadPk3.DovrebbeTrovareLeImmaginiTraHiStartEHiEnd;
var
  LFirst, LLast, LIndex: Integer;
  LBytes: TBytes;
begin
  LFirst := IndexOfEntry(FHires, 'HI_START');
  LLast := IndexOfEntry(FHires, 'HI_END');
  Assert.AreEqual(7, LLast - LFirst - 1, 'dovrebbe avere sette immagini');
  // w_pak.pas looks at the first 128 bytes of each lump between the markers: the same bytes
  // of the files of the PK3
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 1), MAGIC_TGA), 'TGA');
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 2), [$50, $4E, $47], 1), 'PNG');
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 3), MAGIC_BMP), 'BMP');
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 4), MAGIC_JFIF, 6), 'JPEG');
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 5), MAGIC_PCX), 'PCX');
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 6), MAGIC_PATCH), 'patch');
  Assert.AreEqual(4096, FHires.Entries[LFirst + 7].Size, 'flat');
  for LIndex := LFirst + 1 to LLast - 1 do
  begin
    LBytes := FHires.ReadEntry(LIndex);
    Assert.AreEqual(Integer(Length(LBytes)), FHires.Entries[LIndex].Size, 'Size di ' + FHires.Entries[LIndex].Name);
  end;
end;

procedure TTestWadPk3.DovrebbeTrovareLeImmaginiTraTxStartETxEnd;
var
  LFirst: Integer;
begin
  LFirst := IndexOfEntry(FHires, 'TX_START');
  Assert.AreEqual(IndexOfEntry(FHires, 'TX_END'), LFirst + 3, 'dovrebbe avere due immagini');
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 1), [$50, $4E, $47], 1), 'PNG');
  Assert.IsTrue(StartsWith(FHires.ReadEntry(LFirst + 2), MAGIC_TGA), 'TGA');
end;

procedure TTestWadPk3.DovrebbeLeggereLAliasDelSuonoInPk3Entry;
var
  LList: TStringList;
  LLine: string;
  LAliases: TStringList;
  LPosition: Integer;
begin
  LList := TStringList.Create;
  LAliases := TStringList.Create;
  try
    LList.Text := TEncoding.ASCII.GetString(EntryBytes(FHires, 'PK3ENTRY'));
    // as in w_pak.pas: comments after // are cut, the spaces removed, what is left is NAME=path
    for LLine in LList do
    begin
      LPosition := Pos('//', LLine);
      if LPosition > 0 then
        LAliases.Add(Trim(Copy(LLine, 1, LPosition - 1)))
      else
        LAliases.Add(Trim(LLine));
    end;
    for LPosition := LAliases.Count - 1 downto 0 do
      if LAliases[LPosition] = '' then
        LAliases.Delete(LPosition);
    Assert.AreEqual(1, LAliases.Count, 'dovrebbe avere una sola riga utile');
    Assert.AreEqual('sounds/zwsnd.wav', LAliases.Values['ZWSND'], 'dovrebbe legare ZWSND al nome lungo');
    Assert.IsTrue(IndexOfEntry(FHires, 'ZWSND') >= 0, 'il lump del suono dovrebbe esserci');
    Assert.IsTrue(StartsWith(EntryBytes(FHires, 'ZWSND'), MAGIC_RIFF), 'il lump e'' un WAV');
  finally
    LAliases.Free;
    LList.Free;
  end;
end;

procedure TTestWadPk3.DovrebbeUnireIlPk3EIlWadInUnaDirectory;
var
  LDirectory: IWadDirectory;
  LFinder: IWadFinder;
begin
  LDirectory := TWadFactory.CreateDirectory;
  LDirectory.AddSource(FHires);
  LDirectory.AddSource(FPk3);
  Assert.AreEqual(Integer(FHires.Count + FPk3.Count), LDirectory.Count, 'dovrebbe avere i lump di tutti e due');
  LFinder := TWadFactory.CreateFinder(LDirectory);
  Assert.IsTrue(LFinder.CheckNumForName('ZWPNG') >= 0, 'dovrebbe trovare un lump del WAD');
  Assert.IsTrue(LFinder.CheckNumForName('VOXELDEF') >= 0, 'dovrebbe trovare VOXELDEF del PK3');
  Assert.AreEqual(-1, LFinder.CheckNumForName('ZPKPNG'), 'i nomi lunghi del PK3 non sono lump di 8 caratteri');
end;

end.
