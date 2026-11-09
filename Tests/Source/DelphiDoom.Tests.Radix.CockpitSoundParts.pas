{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixCockpitPart and TRadixSoundPart                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.CockpitSoundParts;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.CockpitPart, DelphiDoom.Radix.SoundPart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixCockpitSoundParts = class(TObject)
  strict private
    function Cockpit(const ALump: TBytes): IGameWadComposer;
  public
    [Test]
    procedure DovrebbeNonFareNullaSenzaLaCabina;
    [Test]
    procedure DovrebbeScrivereLaCabinaDi320x200;
    [Test]
    procedure DovrebbeMetterePrimoPixelDelPrimoPianoInAlto;
    [Test]
    procedure DovrebbeSaltareIPixelConUnCodiceZero;
    [Test]
    procedure DovrebbeNonFermarsiOltreLaFineDelLump;
    [Test]
    procedure DovrebbeScrivereISuoniEDareLoroUnNome;
    [Test]
    procedure DovrebbeSaltareISuoniCheNonCeranoENumerareConLIndiceGiusto;
    [Test]
    procedure DovrebbeNonScrivereSndinfoSenzaSuoni;
    [Test]
    procedure DovrebbeAvereIQuarantacinqueNomiDeiSuoni;
  end;

implementation

{ TTestRadixCockpitSoundParts }

function TTestRadixCockpitSoundParts.Cockpit(const ALump: TBytes): IGameWadComposer;
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('CockPitOverlay', ALump);
    Result := TRadixPartRunner.Run(TRadixCockpitPart.Create, LBuilder.ToBytes, nil, LAliases);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixCockpitSoundParts.DovrebbeNonFareNullaSenzaLaCabina;
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('Other', TBytes.Create(1));
    Assert.AreEqual(0, TRadixPartRunner.Run(TRadixCockpitPart.Create, LBuilder.ToBytes, nil, LAliases).Count);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixCockpitSoundParts.DovrebbeScrivereLaCabinaDi320x200;
var
  LPatch: TBytes;
  LWad: IGameWadComposer;
begin
  // four sizes of 0, then nothing: an overlay of holes
  LWad := Cockpit(TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0));
  LPatch := LWad.LumpData[LWad.IndexOf('COCKPIT')];
  Assert.AreEqual(320, Integer(PSmallInt(@LPatch[0])^));
  Assert.AreEqual(200, Integer(PSmallInt(@LPatch[2])^));
end;

procedure TTestRadixCockpitSoundParts.DovrebbeMetterePrimoPixelDelPrimoPianoInAlto;
var
  LPatch: TBytes;
  LWad: IGameWadComposer;
  LColumn: Integer;
begin
  // sizes 2, 0, 0, 0; padding to 12; the plane 0 is the pixel 5 and the end
  LWad := Cockpit(TBytes.Create(2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 255));
  LPatch := LWad.LumpData[LWad.IndexOf('COCKPIT')];
  LColumn := PInteger(@LPatch[8])^;
  // post: top delta 0, one pixel, a pad byte, the pixel
  Assert.AreEqual(0, Integer(LPatch[LColumn]));
  Assert.AreEqual(1, Integer(LPatch[LColumn + 1]));
  Assert.AreEqual(5, Integer(LPatch[LColumn + 3]));
end;

procedure TTestRadixCockpitSoundParts.DovrebbeSaltareIPixelConUnCodiceZero;
var
  LPatch: TBytes;
  LWad: IGameWadComposer;
  LColumn: Integer;
begin
  // skip 3 pixels (the position 3 is the column 3 of the plane, x = 0, y = 0 of that interleave)
  // then the pixel 6: the position 3 goes to x = 0, y = 0 + 3 / 80 * 1 ... the plane columns
  LWad := Cockpit(TBytes.Create(4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 6, 255));
  LPatch := LWad.LumpData[LWad.IndexOf('COCKPIT')];
  // the position 80 of the plane is x = 80: x2 = 0, x1 = 1: pixel [0, 1], the second row of column 0
  LColumn := PInteger(@LPatch[8])^;
  Assert.AreEqual(1, Integer(LPatch[LColumn]));
  Assert.AreEqual(6, Integer(LPatch[LColumn + 3]));
end;

procedure TTestRadixCockpitSoundParts.DovrebbeNonFermarsiOltreLaFineDelLump;
begin
  // the plane says 50 codes but the lump ends: the missing bytes are zero, no exception
  Assert.WillNotRaise(
    procedure
    begin
      Cockpit(TBytes.Create(50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5));
    end);
end;

procedure TTestRadixCockpitSoundParts.DovrebbeScrivereISuoniEDareLoroUnNome;
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
  LWad: IGameWadComposer;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('SndShot', TBytes.Create(1, 2, 3));
    LWad := TRadixPartRunner.Run(TRadixSoundPart.Create, LBuilder.ToBytes, nil, LAliases);
  finally
    LBuilder.Free;
  end;
  Assert.AreEqual(3, Length(LWad.LumpData[LWad.IndexOf('DS_00001')]));
  Assert.AreEqual('DS_00001=SndShot', LAliases[0]);
  Assert.AreEqual('// Radix Sounds'#13#10#13#10'radix/SndShot DS_00001'#13#10,
    TEncoding.ANSI.GetString(LWad.LumpData[LWad.IndexOf('SNDINFO')]));
end;

procedure TTestRadixCockpitSoundParts.DovrebbeSaltareISuoniCheNonCeranoENumerareConLIndiceGiusto;
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
  LWad: IGameWadComposer;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('SndSplash', TBytes.Create(9));
    LBuilder.Add('SndScrape', TBytes.Create(8));
    LWad := TRadixPartRunner.Run(TRadixSoundPart.Create, LBuilder.ToBytes, nil, LAliases);
  finally
    LBuilder.Free;
  end;
  // in the order of the names, not of the file
  Assert.AreEqual('DS_00000', LWad.LumpNames[0]);
  Assert.AreEqual('DS_00044', LWad.LumpNames[1]);
  Assert.AreEqual(2, Length(LAliases));
end;

procedure TTestRadixCockpitSoundParts.DovrebbeNonScrivereSndinfoSenzaSuoni;
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('Other', TBytes.Create(1));
    Assert.AreEqual(0, TRadixPartRunner.Run(TRadixSoundPart.Create, LBuilder.ToBytes, nil, LAliases).Count);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixCockpitSoundParts.DovrebbeAvereIQuarantacinqueNomiDeiSuoni;
begin
  Assert.AreEqual(45, Length(TRadixSoundPart.SoundNames));
end;

end.

