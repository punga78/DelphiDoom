{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Wad library - TPakIndex                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Wad.PakIndex;

interface

{$Q-}
{$R-}

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Wad.Pak.Intf;

type
  [TestFixture]
  [Category('wad')]
  TTestWadPakIndex = class(TObject)
  strict private
    FIndex: IPakIndex;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereVuotoAllInizio;
    [Test]
    procedure DovrebbeMettereIlNomeInMaiuscoloConLeBarreRovesciate;
    [Test]
    procedure DovrebbeTagliareIlNomeA255EIlNomeCortoA64;
    [Test]
    procedure DovrebbeSollevareUnEccezioneFuoriDallElenco;
    [Test]
    procedure DovrebbeTrovareIlPercorsoInteroSenzaDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeNonCorreggereLeBarreDelPercorsoIntero;
    [Test]
    procedure DovrebbeDareLUltimoAggiuntoTraNomiUguali;
    [Test]
    procedure DovrebbeTrovarePerNomeCorto;
    [Test]
    procedure DovrebbeIgnorareUnAltroNomeNellaStessaCatena;
    [Test]
    procedure DovrebbeTrovareConCartellaSenzaConfrontareLeCartelle;
    [Test]
    procedure DovrebbePreferireLaCartellaCheContieneDirettamenteIlFile;
    [Test]
    procedure DovrebbePreferireUnPercorsoCheContieneLaCartella;
    [Test]
    procedure DovrebbeDareLUltimoAggiuntoSenzaCartellePreferite;
    [Test]
    procedure DovrebbeSeguireLeRegoleDellaRicercaSeriale;
    [Test]
    procedure DovrebbeDareTuttiINomiCortiUgualiDalPrimo;
    [Test]
    procedure DovrebbeDareMenoUnoSeNonTrova;
    [Test]
    procedure DovrebbeAvereLImmagineDi588Byte;
    [Test]
    procedure DovrebbeCalcolareIlHashGlobaleComeIlVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Wad.Pak.Index;

type
  // the old TPakEntry of w_pak, up to its field Hash: the global hash read these bytes
  TOldPakEntry = record
    Pak: string[255];
    Name: string[255];
    ShortName: string[64];
    Offset, Size: Integer;
    Hash: Integer;
    Source: Integer;
  end;

// The old TPakManager.AddEntry and AddEntryToHashTable, written again from the old code, on the
// image of the entry (strupper, fixpathname, fshortname with the d_delphi rules)
procedure OldGlobalHash(var AHash: Cardinal; const AName, AContainer: string; AEntry, ASize: Integer);
var
  LEntry: TOldPakEntry;
  LName: string;
  LShort: string;
  LIndex: Integer;
  LByte: PByte;
begin
  FillChar(LEntry, SizeOf(LEntry), 0);
  LEntry.Pak := ShortString(AContainer);
  LName := UpperCase(AName).Replace('/', '\');
  while Pos('\\', LName) > 0 do
    LName := LName.Replace('\\', '\');
  LEntry.Name := ShortString(LName);
  LShort := string(LEntry.Name);
  LShort := Copy(LShort, LastDelimiter('\/', LShort) + 1, MaxInt);
  LEntry.ShortName := ShortString(LShort);
  LEntry.Offset := AEntry;
  LEntry.Size := ASize;
  LByte := @LEntry;
  for LIndex := 0 to Integer(@TOldPakEntry(nil^).Hash) - 1 do
  begin
    if LByte^ = 0 then
      Inc(AHash)
    else
      AHash := ((AHash shl 7) or (AHash shr 25)) + LByte^;
    Inc(LByte);
  end;
end;

{ TTestWadPakIndex }

procedure TTestWadPakIndex.Setup;
begin
  FIndex := TPakIndex.Create;
end;

procedure TTestWadPakIndex.TearDown;
begin
  FIndex := nil;
end;

procedure TTestWadPakIndex.DovrebbeEssereVuotoAllInizio;
begin
  Assert.AreEqual(0, FIndex.Count);
  Assert.AreEqual(Cardinal(0), FIndex.GlobalHash);
  Assert.AreEqual(-1, FIndex.FindShort('x'));
  Assert.AreEqual(0, Integer(Length(FIndex.Matching('x'))));
end;

procedure TTestWadPakIndex.DovrebbeMettereIlNomeInMaiuscoloConLeBarreRovesciate;
var
  LEntry: TPakIndexEntry;
begin
  FIndex.Add('textures//Foo.png', 'C:\GAME.PK3', 2, 7, 10);
  LEntry := FIndex.Entry(0);
  Assert.AreEqual('TEXTURES\FOO.PNG', LEntry.Name);
  Assert.AreEqual('FOO.PNG', LEntry.ShortName);
  Assert.AreEqual('C:\GAME.PK3', LEntry.Container);
  Assert.AreEqual(2, LEntry.Source);
  Assert.AreEqual(7, LEntry.Entry);
  Assert.AreEqual(10, LEntry.Size);
end;

procedure TTestWadPakIndex.DovrebbeTagliareIlNomeA255EIlNomeCortoA64;
var
  LEntry: TPakIndexEntry;
begin
  FIndex.Add(StringOfChar('a', 300), 'P', 0, 0, 1);
  FIndex.Add('dir\' + StringOfChar('b', 70), 'P', 0, 1, 1);
  LEntry := FIndex.Entry(0);
  Assert.AreEqual(255, Length(LEntry.Name));
  Assert.AreEqual(64, Length(LEntry.ShortName));
  Assert.AreEqual(StringOfChar('B', 64), FIndex.Entry(1).ShortName);
  // a short name longer than 64 is never found: the old code compared it with the cut one
  Assert.AreEqual(-1, FIndex.FindShort(StringOfChar('b', 70)));
  Assert.AreEqual(1, FIndex.FindShort(StringOfChar('b', 64)));
end;

procedure TTestWadPakIndex.DovrebbeSollevareUnEccezioneFuoriDallElenco;
begin
  FIndex.Add('a', 'P', 0, 0, 1);
  Assert.WillRaise(
    procedure
    begin
      FIndex.Entry(1);
    end, EWadException);
  Assert.WillRaise(
    procedure
    begin
      FIndex.Entry(-1);
    end, EWadException);
end;

procedure TTestWadPakIndex.DovrebbeTrovareIlPercorsoInteroSenzaDistinguereLeMaiuscole;
begin
  FIndex.Add('data/sub/actordef.txt', 'P', 0, 0, 1);
  Assert.AreEqual(0, FIndex.FindFull('Data\Sub\ACTORDEF.txt'));
  Assert.AreEqual(-1, FIndex.FindFull('actordef.txt'));
end;

procedure TTestWadPakIndex.DovrebbeNonCorreggereLeBarreDelPercorsoIntero;
begin
  FIndex.Add('data/sub/actordef.txt', 'P', 0, 0, 1);
  Assert.AreEqual(-1, FIndex.FindFull('data/sub/actordef.txt'));
end;

procedure TTestWadPakIndex.DovrebbeDareLUltimoAggiuntoTraNomiUguali;
begin
  FIndex.Add('a\x.txt', 'P', 0, 0, 1);
  FIndex.Add('a\x.txt', 'Q', 1, 0, 1);
  Assert.AreEqual(1, FIndex.FindFull('a\x.txt'));
  Assert.AreEqual(1, FIndex.FindShort('x.txt'));
end;

procedure TTestWadPakIndex.DovrebbeTrovarePerNomeCorto;
begin
  FIndex.Add('sprites\bar.tga', 'P', 0, 0, 1);
  Assert.AreEqual(0, FIndex.FindShort('other/dir\BAR.TGA'));
end;

procedure TTestWadPakIndex.DovrebbeIgnorareUnAltroNomeNellaStessaCatena;
begin
  // 'A' (65) and '@A' (64 shl 7 + 65 = 8257) are in the same chain of the table
  FIndex.Add('A', 'P', 0, 0, 1);
  FIndex.Add('@A', 'P', 0, 1, 1);
  Assert.AreEqual(0, FIndex.FindShort('a'));
  Assert.AreEqual(1, FIndex.FindShort('@a'));
end;

procedure TTestWadPakIndex.DovrebbeTrovareConCartellaSenzaConfrontareLeCartelle;
begin
  FIndex.Add('a\b\foo.png', 'P', 0, 0, 1);
  FIndex.Add('xfoo.png', 'P', 0, 1, 1);
  Assert.AreEqual(0, FIndex.FindWithDirectory('other\foo.png'));
  FIndex.Add('foo.png', 'P', 0, 2, 1);
  Assert.AreEqual(2, FIndex.FindWithDirectory('foo.png'));
end;

procedure TTestWadPakIndex.DovrebbePreferireLaCartellaCheContieneDirettamenteIlFile;
begin
  FIndex.Add('voxels\t.ddvox', 'P', 0, 0, 1);
  FIndex.Add('doom\voxels\t.ddvox', 'P', 0, 1, 1);
  FIndex.Add('heretic\voxels\t.ddvox', 'P', 0, 2, 1);
  FIndex.Add('doomx\t.ddvox', 'P', 0, 3, 1);
  Assert.AreEqual(1, FIndex.FindPreferred('t.ddvox', ['DOOM\VOXELS\', 'HERETIC\']));
end;

procedure TTestWadPakIndex.DovrebbePreferireUnPercorsoCheContieneLaCartella;
begin
  FIndex.Add('voxels\t.ddvox', 'P', 0, 0, 1);
  FIndex.Add('heretic\voxels\t.ddvox', 'P', 0, 1, 1);
  FIndex.Add('doomx\t.ddvox', 'P', 0, 2, 1);
  Assert.AreEqual(1, FIndex.FindPreferred('t.ddvox', ['HERETIC\']));
  // right inside the second preferred folder wins over containing the first one
  Assert.AreEqual(0, FIndex.FindPreferred('t.ddvox', ['HERETIC\', 'VOXELS\']));
end;

procedure TTestWadPakIndex.DovrebbeDareLUltimoAggiuntoSenzaCartellePreferite;
begin
  FIndex.Add('voxels\t.ddvox', 'P', 0, 0, 1);
  FIndex.Add('doomx\t.ddvox', 'P', 0, 1, 1);
  Assert.AreEqual(1, FIndex.FindPreferred('t.ddvox', []));
  Assert.AreEqual(1, FIndex.FindPreferredSerial('t.ddvox', []));
end;

procedure TTestWadPakIndex.DovrebbeSeguireLeRegoleDellaRicercaSeriale;
begin
  FIndex.Add('voxels\t.ddvox', 'P', 0, 0, 1);
  FIndex.Add('doom\voxels\t.ddvox', 'P', 0, 1, 1);
  FIndex.Add('heretic\voxels\t.ddvox', 'P', 0, 2, 1);
  FIndex.Add('doomx\t.ddvox', 'P', 0, 3, 1);
  // the first folder that the path contains, then the last added: no rule for "right inside"
  Assert.AreEqual(2, FIndex.FindPreferredSerial('t.ddvox', ['VOXELS\']));
  Assert.AreEqual(1, FIndex.FindPreferredSerial('t.ddvox', ['DOOM\VOXELS\', 'VOXELS\']));
  Assert.AreEqual(3, FIndex.FindPreferredSerial('t.ddvox', ['NONE\']));
end;

procedure TTestWadPakIndex.DovrebbeDareTuttiINomiCortiUgualiDalPrimo;
var
  LFound: TArray<Integer>;
begin
  FIndex.Add('a\gldefs', 'P', 0, 0, 1);
  FIndex.Add('other', 'P', 0, 1, 1);
  FIndex.Add('GLDEFS', 'Q', 1, 0, 1);
  LFound := FIndex.Matching('x\GlDefs');
  Assert.AreEqual(2, Integer(Length(LFound)));
  Assert.AreEqual(0, LFound[0]);
  Assert.AreEqual(2, LFound[1]);
end;

procedure TTestWadPakIndex.DovrebbeDareMenoUnoSeNonTrova;
begin
  FIndex.Add('a\b.txt', 'P', 0, 0, 1);
  Assert.AreEqual(-1, FIndex.FindFull('a\c.txt'));
  Assert.AreEqual(-1, FIndex.FindShort('c.txt'));
  Assert.AreEqual(-1, FIndex.FindWithDirectory('c.txt'));
  Assert.AreEqual(-1, FIndex.FindPreferred('c.txt', ['A\']));
  Assert.AreEqual(-1, FIndex.FindPreferredSerial('c.txt', ['A\']));
end;

procedure TTestWadPakIndex.DovrebbeAvereLImmagineDi588Byte;
begin
  Assert.AreEqual(588, Integer(SizeOf(TPakEntryImage)));
  Assert.AreEqual(Integer(@TOldPakEntry(nil^).Hash), Integer(SizeOf(TPakEntryImage)));
end;

procedure TTestWadPakIndex.DovrebbeCalcolareIlHashGlobaleComeIlVecchioCodice;
const
  NAMES: array[0..5] of string = ('textures/Foo.png', 'a', 'dir//double.txt', 'caff'#$E8'.png',
    'deep\path\with\many\folders\and\a\rather\long\name\that\goes\on\file.txt', 'x');
var
  LExpected: Cardinal;
  LIndex: Integer;
begin
  LExpected := 0;
  for LIndex := 0 to High(NAMES) do
  begin
    FIndex.Add(NAMES[LIndex], 'C:\GAMES\TEST.PK3', 0, LIndex, LIndex * 13);
    OldGlobalHash(LExpected, NAMES[LIndex], 'C:\GAMES\TEST.PK3', LIndex, LIndex * 13);
  end;
  FIndex.Add(StringOfChar('z', 300), 'Q', 1, 9, 9);
  OldGlobalHash(LExpected, StringOfChar('z', 300), 'Q', 9, 9);
  Assert.AreEqual(LExpected, FIndex.GlobalHash);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWadPakIndex);

end.
