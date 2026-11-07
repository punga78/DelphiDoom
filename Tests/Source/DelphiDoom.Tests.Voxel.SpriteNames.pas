{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the voxel files that become sprites
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.SpriteNames;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Voxel.Intf;

type
  [TestFixture]
  [Category('voxel')]
  TTestVoxelSpriteNames = class(TObject)
  strict private
    function NamesOf(const ALumps: array of string; const AFiles: array of string): IVoxelSpriteNames;
    function EntriesOf(const ANames: IVoxelSpriteNames): string;
  public
    [Test]
    procedure DovrebbeTenereUnFileDiOgniEstensioneDeiVoxel;
    [Test]
    procedure DovrebbeScartareUnaEstensioneSconosciuta;
    [Test]
    procedure DovrebbeTenereUnFileSenzaEstensioneSoloNellaCartellaDeiVoxel;
    [Test]
    procedure DovrebbeAccettareLaBarraAlContrarioEIDoppiSeparatori;
    [Test]
    procedure DovrebbeTenereSoloNomiDiCinqueOSeiCaratteriConLoZero;
    [Test]
    procedure DovrebbeDareIlNomeDelloSpriteConLoZero;
    [Test]
    procedure DovrebbeScartareUnoSpriteCheIlGiocoHa;
    [Test]
    procedure DovrebbeGuardareSoloLeSezioniDegliSprite;
    [Test]
    procedure DovrebbeConfrontareIlLumpConLeMaiuscole;
    [Test]
    procedure DovrebbeScartareUnDoppioneSoloSenzaEstensione;
    [Test]
    procedure DovrebbeLeggereLaDirectoryUnaVolta;
    [Test]
    procedure DovrebbeDareEccezioneSenzaLumps;
    [Test]
    procedure DovrebbeDareLeStesseScelteDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Voxel.Factory, DelphiDoom.Tests.Voxel.Fakes;

type
  /// <summary>
  ///   The old choice of vx_voxelsprite.pas (VX_AddFileName and VX_SpriteExistsInWAD) with the
  ///   functions of d_delphi it used, copied as they were; only W_NumLumps and W_GetNameForNum
  ///   are the fake directory
  /// </summary>
  TOldVoxelSpriteNames = class
  strict private
    FLumps: IVoxelLumpNames;
    class function strupper(const S: string): string; static;
    class function firstword_ch(const inp: string; const splitter: char = ' '): string; static;
    class function fixpathname(const s: string): string; static;
    class function Pos1(const subs, s: string): boolean; static;
    function IndexOf(const S: string): Integer;
    function VX_SpriteExistsInWAD(const filename: string): boolean;
  public
    vx_names: TStringList;
    constructor Create(const ALumps: IVoxelLumpNames);
    destructor Destroy; override;
    procedure VX_AddFileName(const filename: string);
    function _vxsprname(const i: integer): string;
  end;

const
  FOLDER_VOXELS = 'VOXELS';

constructor TOldVoxelSpriteNames.Create(const ALumps: IVoxelLumpNames);
begin
  inherited Create;
  FLumps := ALumps;
  vx_names := TStringList.Create;
end;

destructor TOldVoxelSpriteNames.Destroy;
begin
  vx_names.Free;
  inherited;
end;

class function TOldVoxelSpriteNames.strupper(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(result, L);
  Source := Pointer(S);
  Dest := Pointer(result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then dec(Ch, 32);
    Dest^ := Ch;
    inc(Source);
    inc(Dest);
    dec(L);
  end;
end;

class function TOldVoxelSpriteNames.firstword_ch(const inp: string; const splitter: char = ' '): string;
var
  p, len: integer;
begin
  p := 1;
  len := Length(inp);
  SetLength(result, len);
  while p <= len do
  begin
    if inp[p] = splitter then
      break;
    result[p] := inp[p];
    Inc(p);
  end;
  SetLength(result, p - 1);
end;

class function TOldVoxelSpriteNames.fixpathname(const s: string): string;
var
  i: integer;
  tmp: string;
  last: char;
begin
  tmp := s;
  for i := 1 to Length(tmp) do
    if tmp[i] = '/' then
      tmp[i] := '\';

  result := '';
  last := Chr(0);
  for i := 1 to Length(tmp) do
  begin
    if (last <> '\') or (tmp[i] <> '\') then
      result := result + tmp[i];
    last := tmp[i];
  end;
end;

class function TOldVoxelSpriteNames.Pos1(const subs, s: string): boolean;
var
  len1: integer;
begin
  len1 := Length(subs);
  if Length(s) < len1 then
  begin
    Result := False;
    Exit;
  end;
  Result := CompareMem(PChar(subs), PChar(s), len1 * SizeOf(Char));
end;

function TOldVoxelSpriteNames.IndexOf(const S: string): Integer;
begin
  for result := 0 to vx_names.Count - 1 do
    if AnsiCompareText(vx_names[result], S) = 0 then
      Exit;
  result := -1;
end;

function TOldVoxelSpriteNames.VX_SpriteExistsInWAD(const filename: string): boolean;
var
  check, lumpname: string;
  i: integer;
  in_loop: boolean;
begin
  check := firstword_ch(filename, '.'); // Input is uppercase
  SetLength(check, 5); // SPRITE & FRAME
  in_loop := false;
  for i := 0 to FLumps.LumpCount - 1 do
  begin
    lumpname := FLumps.LumpName(i);
    if (lumpname = 'SS_START') or (lumpname = 'S_START') then
      in_loop := true
    else if (lumpname = 'SS_END') or (lumpname = 'S_END') then
      in_loop := false
    else if in_loop then
    begin
      if Pos1(check, lumpname) then
      begin
        result := true;
        exit;
      end;
    end;
  end;
  result := false;
end;

procedure TOldVoxelSpriteNames.VX_AddFileName(const filename: string);
var
  check: string;
  name: string;
  ext: string;
begin
  check := strupper(filename);
  ext := ExtractFileExt(check);
  if (ext = '.DDVOX') or (ext = '.DDMESH') or (ext = '.KVX') or (ext = '.VOX') or
     ((ext = '') and (Pos(FOLDER_VOXELS + '\', fixpathname(check)) > 0)) then
  begin
    check := ExtractFileName(check);
    name := firstword_ch(check, '.');
    if (Length(name) = 5) or ((Length(name) = 6) and (name[6] = '0')) then
      if IndexOf(name) < 0 then
        if not VX_SpriteExistsInWAD(name) then
          vx_names.Add(name + ext)
  end;
end;

function TOldVoxelSpriteNames._vxsprname(const i: integer): string;
begin
  result := firstword_ch(vx_names.Strings[i], '.');
  if Length(result) = 5 then
    result := result + '0';
end;

{ TTestVoxelSpriteNames }

function TTestVoxelSpriteNames.NamesOf(const ALumps: array of string;
  const AFiles: array of string): IVoxelSpriteNames;
var
  LFile: string;
begin
  Result := TVoxelFactory.CreateSpriteNames(TVoxelFakeLumpNames.Create(ALumps));
  for LFile in AFiles do
    Result.AddFileName(LFile);
end;

function TTestVoxelSpriteNames.EntriesOf(const ANames: IVoxelSpriteNames): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to ANames.Count - 1 do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + ANames.Entry(LIndex) + '=' + ANames.SpriteName(LIndex);
  end;
end;

procedure TTestVoxelSpriteNames.DovrebbeTenereUnFileDiOgniEstensioneDeiVoxel;
begin
  Assert.AreEqual('AAAAA.DDVOX=AAAAA0,BBBBB.DDMESH=BBBBB0,CCCCC.KVX=CCCCC0,DDDDD.VOX=DDDDD0',
    EntriesOf(NamesOf([], ['models\aaaaa.ddvox', 'BBBBB.DDMESH', 'x\ccccc.kvx', 'ddddd.Vox'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeScartareUnaEstensioneSconosciuta;
begin
  Assert.AreEqual('', EntriesOf(NamesOf([], ['aaaaa.png', 'voxels\bbbbb.txt', 'ccccc.kvx2'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeTenereUnFileSenzaEstensioneSoloNellaCartellaDeiVoxel;
begin
  Assert.AreEqual('BBBBB=BBBBB0',
    EntriesOf(NamesOf([], ['aaaaa', 'voxels\bbbbb', 'voxelsx\ccccc'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeAccettareLaBarraAlContrarioEIDoppiSeparatori;
begin
  // the folder is found also with / and \\, but the name of the file is only after a \ (as
  // ExtractFileName gives it): voxels/ccccc has no name of five characters
  Assert.AreEqual('AAAAA=AAAAA0,BBBBB=BBBBB0',
    EntriesOf(NamesOf([], ['pk3\\voxels\\aaaaa', 'pk3/voxels\bbbbb', 'voxels/ccccc'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeTenereSoloNomiDiCinqueOSeiCaratteriConLoZero;
begin
  Assert.AreEqual('AAAAA0.KVX=AAAAA0,BBBBB.KVX=BBBBB0',
    EntriesOf(NamesOf([], ['aaaaa0.kvx', 'bbbbb.kvx', 'ccccc1.kvx', 'dddd.kvx', 'eeeeeee.kvx'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeDareIlNomeDelloSpriteConLoZero;
var
  LNames: IVoxelSpriteNames;
begin
  LNames := NamesOf([], ['possa.ddvox', 'possb0.ddvox']);
  Assert.AreEqual('POSSA0', LNames.SpriteName(0));
  Assert.AreEqual('POSSB0', LNames.SpriteName(1));
end;

procedure TTestVoxelSpriteNames.DovrebbeScartareUnoSpriteCheIlGiocoHa;
begin
  Assert.AreEqual('POSSB.KVX=POSSB0',
    EntriesOf(NamesOf(['S_START', 'POSSA1', 'S_END'], ['possa.kvx', 'possb.kvx'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeGuardareSoloLeSezioniDegliSprite;
begin
  // POSSA and POSSD are out of every section, POSSC is a flat, POSSB is in SS_START
  Assert.AreEqual('POSSA.KVX=POSSA0,POSSC.KVX=POSSC0,POSSD.KVX=POSSD0',
    EntriesOf(NamesOf(['POSSA1', 'F_START', 'POSSC1', 'F_END', 'SS_START', 'S_END', 'POSSD1',
      'SS_START', 'POSSB2', 'SS_END'], ['possa.kvx', 'possb.kvx', 'possc.kvx', 'possd.kvx'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeConfrontareIlLumpConLeMaiuscole;
begin
  // the lump is compared as the WAD has it, the name of the file is in capital letters
  Assert.AreEqual('POSSA.KVX=POSSA0',
    EntriesOf(NamesOf(['S_START', 'possa1', 'POSS', 'S_END'], ['possa.kvx'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeScartareUnDoppioneSoloSenzaEstensione;
begin
  // the old list compared the name with the names and the extensions it had kept: possa.kvx
  // is kept twice, voxels\possb once
  Assert.AreEqual('POSSA.KVX=POSSA0,POSSA.DDVOX=POSSA0,POSSB=POSSB0,POSSA.KVX=POSSA0',
    EntriesOf(NamesOf([], ['possa.kvx', 'possa.ddvox', 'voxels\possb', 'voxels\possb', 'possa.kvx'])));
end;

procedure TTestVoxelSpriteNames.DovrebbeLeggereLaDirectoryUnaVolta;
var
  LLumps: TVoxelFakeLumpNames;
  LNames: IVoxelSpriteNames;
begin
  LLumps := TVoxelFakeLumpNames.Create(['S_START', 'POSSA1', 'S_END']);
  LNames := TVoxelFactory.CreateSpriteNames(LLumps);
  LNames.AddFileName('aaaa.kvx');
  Assert.AreEqual(0, LLumps.CountCalls);
  LNames.AddFileName('possa.kvx');
  LNames.AddFileName('possb.kvx');
  LNames.AddFileName('possc.kvx');
  Assert.AreEqual(1, LLumps.CountCalls);
  Assert.AreEqual(2, LNames.Count);
end;

procedure TTestVoxelSpriteNames.DovrebbeDareEccezioneSenzaLumps;
begin
  Assert.WillRaise(
    procedure
    begin
      TVoxelFactory.CreateSpriteNames(nil);
    end, EArgumentNilException);
end;

procedure TTestVoxelSpriteNames.DovrebbeDareLeStesseScelteDelVecchioCodice;
const
  FOLDERS: array[0..7] of string = ('', 'voxels\', 'VOXELS/', 'pk3/voxels//', 'models\',
    'voxelsx\', 'a/b/Voxels\', 'sprites/');
  STEMS: array[0..9] of string = ('possa', 'POSSB', 'possa0', 'possa1', 'troo', 'trooaa',
    'Bar1a', 'bar1a0', 'x.y', 'sKelA');
  EXTENSIONS: array[0..8] of string = ('', '.kvx', '.KVX', '.ddvox', '.DDMesh', '.vox', '.png',
    '.vox.bak', '.');
  LUMPS: array[0..11] of string = ('S_START', 'S_END', 'SS_START', 'SS_END', 'POSSA1',
    'POSSB0', 'possa2', 'TROOA1', 'BAR1A0', 'SKEL', 'SKELA1C1', 'F_START');
var
  LScenario, LIndex: Integer;
  LLumpNames: TArray<string>;
  LFiles: TArray<string>;
  LLumps: IVoxelLumpNames;
  LOld: TOldVoxelSpriteNames;
  LNew: IVoxelSpriteNames;
  LChecks: Integer;
begin
  RandSeed := 134;
  LChecks := 0;
  for LScenario := 1 to 300 do
  begin
    SetLength(LLumpNames, Random(14));
    for LIndex := 0 to High(LLumpNames) do
      LLumpNames[LIndex] := LUMPS[Random(Length(LUMPS))];
    SetLength(LFiles, Random(25));
    for LIndex := 0 to High(LFiles) do
      LFiles[LIndex] := FOLDERS[Random(Length(FOLDERS))] + STEMS[Random(Length(STEMS))] +
        EXTENSIONS[Random(Length(EXTENSIONS))];

    LLumps := TVoxelFakeLumpNames.Create(LLumpNames);
    LNew := TVoxelFactory.CreateSpriteNames(LLumps);
    LOld := TOldVoxelSpriteNames.Create(LLumps);
    try
      for LIndex := 0 to High(LFiles) do
      begin
        LOld.VX_AddFileName(LFiles[LIndex]);
        LNew.AddFileName(LFiles[LIndex]);
      end;
      Assert.AreEqual(LOld.vx_names.Count, LNew.Count, Format('scenario %d', [LScenario]));
      for LIndex := 0 to LOld.vx_names.Count - 1 do
      begin
        Assert.AreEqual(LOld.vx_names[LIndex], LNew.Entry(LIndex), Format('scenario %d', [LScenario]));
        Assert.AreEqual(LOld._vxsprname(LIndex), LNew.SpriteName(LIndex), Format('scenario %d', [LScenario]));
        Inc(LChecks);
      end;
    finally
      LOld.Free;
    end;
  end;
  // the scenarios keep a good number of files, not only empty lists
  Assert.IsTrue(LChecks > 300, Format('%d files kept', [LChecks]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVoxelSpriteNames);

end.
