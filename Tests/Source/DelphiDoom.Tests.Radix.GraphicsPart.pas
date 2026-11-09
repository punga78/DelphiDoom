{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixGraphicsPart                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.GraphicsPart;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Context, DelphiDoom.Radix.GraphicsPart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixGraphicsPart = class(TObject)
  strict private
    FBuilder: TRadixDatBuilder;
    FWad: IGameWadComposer;
    FAliases: TArray<string>;
    function Palette: TBytes;
    /// <summary>A picture without palette: width, height and the pixels by rows</summary>
    function Plain(AWidth, AHeight: Integer; APixel: Byte): TBytes;
    /// <summary>A picture with its own palette: 2 bytes, width, height, ..., the palette at 32, the pixels at 800</summary>
    function Paletted(AWidth, AHeight: Integer): TBytes;
    procedure Run;
    function HasAlias(const ALine: string): Boolean;
    function ReadWord(const ABytes: TBytes; AOffset: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLeSchermateDiAiutoFinoAlPrimoBuco;
    [Test]
    procedure DovrebbeScrivereIlTitoloELeSchermateDelMenu;
    [Test]
    procedure DovrebbeDareUnAliasAncheAUnaSchermataCheNonCe;
    [Test]
    procedure DovrebbeNumerareLeImmaginiConPaletta;
    [Test]
    procedure DovrebbeNonNumerareUnaImmagineCheNonCe;
    [Test]
    procedure DovrebbeFareLeCifreDelleArmiDa8x9;
    [Test]
    procedure DovrebbeFareBucoIlColoreDelloSfondoDiUnaImmagineSenzaPaletta;
    [Test]
    procedure DovrebbeSaltareLeCifreDelleArmiDiUnaLunghezzaDiversa;
    [Test]
    procedure DovrebbeDareIlTitoloAlPakFileSystem;
  end;

implementation

uses
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory;

{ TTestRadixGraphicsPart }

procedure TTestRadixGraphicsPart.Setup;
begin
  FBuilder := TRadixDatBuilder.Create;
end;

procedure TTestRadixGraphicsPart.TearDown;
begin
  FBuilder.Free;
end;

function TTestRadixGraphicsPart.Palette: TBytes;
var
  LColor: Integer;
begin
  SetLength(Result, 768);
  for LColor := 0 to 255 do
  begin
    Result[LColor * 3] := Byte(LColor);
    Result[LColor * 3 + 1] := Byte(LColor);
    Result[LColor * 3 + 2] := Byte(LColor);
  end;
end;

function TTestRadixGraphicsPart.Plain(AWidth, AHeight: Integer; APixel: Byte): TBytes;
begin
  Result := TRadixDatBuilder.Words(AWidth) + TRadixDatBuilder.Words(AHeight);
  SetLength(Result, 4 + AWidth * AHeight);
  FillChar(Result[4], AWidth * AHeight, APixel);
end;

function TTestRadixGraphicsPart.Paletted(AWidth, AHeight: Integer): TBytes;
var
  LColor: Integer;
begin
  SetLength(Result, 800 + AWidth * AHeight);
  Result[2] := Byte(AWidth);
  Result[4] := Byte(AHeight);
  // a palette that goes from black to white: the color i is 63 * i / 255
  for LColor := 0 to 255 do
  begin
    Result[32 + LColor * 3] := Byte(LColor div 4);
    Result[32 + LColor * 3 + 1] := Byte(LColor div 4);
    Result[32 + LColor * 3 + 2] := Byte(LColor div 4);
  end;
  FillChar(Result[800], AWidth * AHeight, 100);
end;

procedure TTestRadixGraphicsPart.Run;
begin
  FWad := TRadixPartRunner.Run(TRadixGraphicsPart.Create, FBuilder.ToBytes, Palette, FAliases);
end;

function TTestRadixGraphicsPart.HasAlias(const ALine: string): Boolean;
var
  LAlias: string;
begin
  for LAlias in FAliases do
    if LAlias = ALine then
      Exit(True);
  Result := False;
end;

function TTestRadixGraphicsPart.ReadWord(const ABytes: TBytes; AOffset: Integer): Integer;
begin
  Result := PSmallInt(@ABytes[AOffset])^;
end;

procedure TTestRadixGraphicsPart.DovrebbeScrivereLeSchermateDiAiutoFinoAlPrimoBuco;
begin
  FBuilder.Add('OrderInfo[1]', Plain(4, 3, 7));
  FBuilder.Add('OrderInfo[2]', Plain(4, 3, 8));
  // the 3 is missing: the 4 is not read
  FBuilder.Add('OrderInfo[4]', Plain(4, 3, 9));
  Run;
  Assert.IsTrue(FWad.IndexOf('HELP01') >= 0);
  Assert.IsTrue(FWad.IndexOf('HELP02') >= 0);
  Assert.AreEqual(-1, FWad.IndexOf('HELP03'));
  Assert.AreEqual(-1, FWad.IndexOf('HELP04'));
  Assert.IsTrue(HasAlias('HELP02=OrderInfo[2]'));
end;

procedure TTestRadixGraphicsPart.DovrebbeScrivereIlTitoloELeSchermateDelMenu;
var
  LTitle: TBytes;
begin
  FBuilder.Add('MainTitle', Paletted(6, 5));
  FBuilder.Add('DemoDecal', Paletted(3, 2));
  Run;
  LTitle := FWad.LumpData[FWad.IndexOf('TITLEPIC')];
  Assert.AreEqual(6, ReadWord(LTitle, 0));
  Assert.AreEqual(5, ReadWord(LTitle, 2));
  Assert.IsTrue(FWad.IndexOf('M_RADIX') >= 0);
end;

procedure TTestRadixGraphicsPart.DovrebbeDareUnAliasAncheAUnaSchermataCheNonCe;
begin
  Run;
  Assert.AreEqual(-1, FWad.IndexOf('M_BRIEF'));
  Assert.IsTrue(HasAlias('M_BRIEF=BriefScreen'));
  Assert.IsTrue(HasAlias('TITLEPIC=MainTitle'));
end;

procedure TTestRadixGraphicsPart.DovrebbeNumerareLeImmaginiConPaletta;
begin
  FBuilder.Add('SkillButton1', Paletted(2, 2));
  FBuilder.Add('SelectSkill', Paletted(2, 2));
  Run;
  // the order is the one of the code, not the one of the container
  Assert.IsTrue(HasAlias('RADIX001=SelectSkill'));
  Assert.IsTrue(HasAlias('RADIX002=SkillButton1'));
end;

procedure TTestRadixGraphicsPart.DovrebbeNonNumerareUnaImmagineCheNonCe;
begin
  FBuilder.Add('SelectSkill', Paletted(2, 2));
  FBuilder.Add('SkillButton2', Paletted(2, 2));
  Run;
  // SkillButton1 is missing, so SkillButton2 takes the number 2
  Assert.IsTrue(HasAlias('RADIX002=SkillButton2'));
end;

procedure TTestRadixGraphicsPart.DovrebbeFareLeCifreDelleArmiDa8x9;
var
  LLump: TBytes;
  LIndex: Integer;
begin
  SetLength(LLump, 508);
  for LIndex := 0 to 503 do
    LLump[4 + LIndex] := Byte(LIndex mod 100);
  FBuilder.Add('WeaponNumOn', LLump);
  Run;
  // WeaponNumOn is a plain picture too: its alias takes a number first, then 7 digits follow
  Assert.IsTrue(HasAlias('RADIX002=WeaponNumOn1'));
  Assert.IsTrue(HasAlias('RADIX008=WeaponNumOn7'));
  Assert.AreEqual(8, ReadWord(FWad.LumpData[FWad.IndexOf('RADIX002')], 0));
  Assert.AreEqual(9, ReadWord(FWad.LumpData[FWad.IndexOf('RADIX002')], 2));
end;

procedure TTestRadixGraphicsPart.DovrebbeFareBucoIlColoreDelloSfondoDiUnaImmagineSenzaPaletta;
var
  LLump: TBytes;
begin
  // BackViewOn has the hole at 0: every pixel is the hole, so the picture has no post
  LLump := Plain(3, 2, 0);
  FBuilder.Add('BackViewOn', LLump);
  Run;
  // 8 bytes of header, 3 offsets of 4 and 3 columns of the 2 bytes of the end (255, 0)
  Assert.AreEqual(8 + 12 + 6, Length(FWad.LumpData[FWad.IndexOf('RADIX001')]));
end;

procedure TTestRadixGraphicsPart.DovrebbeSaltareLeCifreDelleArmiDiUnaLunghezzaDiversa;
begin
  FBuilder.Add('WeaponNumUse', Plain(2, 2, 1));
  Run;
  Assert.IsFalse(HasAlias('RADIX008=WeaponNumUse7'));
  Assert.IsFalse(HasAlias('RADIX002=WeaponNumUse1'));
end;

procedure TTestRadixGraphicsPart.DovrebbeDareIlTitoloAlPakFileSystem;
var
  LTranslator: IRadixTranslator;
  LPosition: Integer;
  LImage: TBytes;
begin
  LImage := Paletted(2, 2);
  FBuilder.Add('Palette[1]', Palette);
  LPosition := FBuilder.Add('MainTitle', LImage);
  LTranslator := TRadixFactory.CreateTranslator;
  LTranslator.Translate(TRadixFactory.OpenContainerBytes(FBuilder.ToBytes));
  Assert.AreEqual(1, Length(LTranslator.PakEntries));
  Assert.AreEqual(LPosition, LTranslator.PakEntries[0].Position);
  Assert.AreEqual(Length(LImage), LTranslator.PakEntries[0].Size);
  Assert.AreEqual('TITLEPIC.RADIX32', LTranslator.PakEntries[0].Name);
end;

end.
