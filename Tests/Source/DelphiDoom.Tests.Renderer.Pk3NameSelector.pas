{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the images of a PK3             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.Pk3NameSelector;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

type
  /// <summary>A fake of the engine: some lumps, some textures, the extensions of the decoders</summary>
  TFakePk3Catalog = class(TInterfacedObject, IRendererPk3Catalog)
  public
    Lumps: TStringList;
    Textures: TStringList;
    constructor Create;
    destructor Destroy; override;
    function IsTextureExtension(const AExtension: string): Boolean;
    function HasLump(const AName: string): Boolean;
    function TextureNumber(const AName: string): Integer;
  end;

  [TestFixture]
  [Category('renderer')]
  TTestRendererPk3NameSelector = class(TObject)
  private
    FSelector: IRendererPk3NameSelector;
    FHash: IRendererPk3TextHash;
    FCatalog: TFakePk3Catalog;
    FCatalogRef: IRendererPk3Catalog;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFareTexturesEFlatDelleImmaginiInTextures;
    [Test]
    procedure DovrebbeFareSoloFlatDelleImmaginiInFlats;
    [Test]
    procedure DovrebbeSaltareLeImmaginiConUnLumpNelWad;
    [Test]
    procedure DovrebbeSaltareINomiLunghiOConDuePunti;
    [Test]
    procedure DovrebbeSaltareLeEstensioniNonImmagine;
    [Test]
    procedure DovrebbeSaltareLeCartelleDiverse;
    [Test]
    procedure DovrebbeFareFlatLeTexturesGiaPresenti;
    [Test]
    procedure DovrebbeDareLeListeOrdinateESenzaDoppioni;
    [Test]
    procedure DovrebbeFallireSenzaCatalogo;
    [Test]
    procedure DovrebbeDareLoStessoHashDelVecchioTesto;
    [Test]
    procedure DovrebbeDareZeroPerUnTestoVuoto;
    /// <summary>
    ///   Parity: the old R_AddTextureFileName (with a list of strings for t_names and f_names),
    ///   copied here as it was, on random names of files
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_AddTextureFileName;
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Renderer.Factory;

{ TFakePk3Catalog }

constructor TFakePk3Catalog.Create;
begin
  inherited Create;
  Lumps := TStringList.Create;
  Textures := TStringList.Create;
end;

destructor TFakePk3Catalog.Destroy;
begin
  Textures.Free;
  Lumps.Free;
  inherited Destroy;
end;

function TFakePk3Catalog.IsTextureExtension(const AExtension: string): Boolean;
begin
  Result := (AExtension = '.PNG') or (AExtension = '.JPG') or (AExtension = '.TGA');
end;

function TFakePk3Catalog.HasLump(const AName: string): Boolean;
begin
  Result := Lumps.IndexOf(AName) >= 0;
end;

function TFakePk3Catalog.TextureNumber(const AName: string): Integer;
begin
  if Textures.IndexOf(AName) >= 0 then
    Result := Textures.IndexOf(AName) + 1
  else
    Result := -1;
end;

{ TTestRendererPk3NameSelector }

procedure TTestRendererPk3NameSelector.Setup;
begin
  FSelector := TRendererFactory.CreatePk3NameSelector;
  FHash := TRendererFactory.CreatePk3TextHash;
  FCatalog := TFakePk3Catalog.Create;
  FCatalogRef := FCatalog;
end;

procedure TTestRendererPk3NameSelector.TearDown;
begin
  FCatalogRef := nil;
  FCatalog := nil;
  FHash := nil;
  FSelector := nil;
end;

procedure TTestRendererPk3NameSelector.DovrebbeFareTexturesEFlatDelleImmaginiInTextures;
var
  LNames: TRendererPk3Names;
begin
  LNames := FSelector.Select(['textures\brick.png'], FCatalogRef);
  Assert.AreEqual<Integer>(1, Length(LNames.Textures));
  Assert.AreEqual('BRICK', LNames.Textures[0]);
  Assert.AreEqual<Integer>(1, Length(LNames.Flats));
  Assert.AreEqual('BRICK', LNames.Flats[0]);
end;

procedure TTestRendererPk3NameSelector.DovrebbeFareSoloFlatDelleImmaginiInFlats;
var
  LNames: TRendererPk3Names;
begin
  LNames := FSelector.Select(['flats\floor1.png'], FCatalogRef);
  Assert.AreEqual<Integer>(0, Length(LNames.Textures));
  Assert.AreEqual<Integer>(1, Length(LNames.Flats));
  Assert.AreEqual('FLOOR1', LNames.Flats[0]);
end;

procedure TTestRendererPk3NameSelector.DovrebbeSaltareLeImmaginiConUnLumpNelWad;
var
  LNames: TRendererPk3Names;
begin
  FCatalog.Lumps.Add('BRICK');
  LNames := FSelector.Select(['textures\brick.png'], FCatalogRef);
  Assert.AreEqual<Integer>(0, Length(LNames.Flats));
end;

procedure TTestRendererPk3NameSelector.DovrebbeSaltareINomiLunghiOConDuePunti;
var
  LNames: TRendererPk3Names;
begin
  LNames := FSelector.Select(['textures\toolongname.png', 'textures\a.b.png'], FCatalogRef);
  Assert.AreEqual<Integer>(0, Length(LNames.Flats));
end;

procedure TTestRendererPk3NameSelector.DovrebbeSaltareLeEstensioniNonImmagine;
var
  LNames: TRendererPk3Names;
begin
  LNames := FSelector.Select(['textures\readme.txt', 'textures\noext'], FCatalogRef);

  Assert.AreEqual<Integer>(0, Length(LNames.Flats));
end;

procedure TTestRendererPk3NameSelector.DovrebbeSaltareLeCartelleDiverse;
var
  LNames: TRendererPk3Names;
begin
  LNames := FSelector.Select(['sprites/imp.png'], FCatalogRef);
  Assert.AreEqual<Integer>(0, Length(LNames.Flats));
end;

procedure TTestRendererPk3NameSelector.DovrebbeFareFlatLeTexturesGiaPresenti;
var
  LNames: TRendererPk3Names;
begin
  FCatalog.Textures.Add('BRICK');
  LNames := FSelector.Select(['textures\brick.png'], FCatalogRef);
  Assert.AreEqual<Integer>(0, Length(LNames.Textures));
  Assert.AreEqual<Integer>(1, Length(LNames.Flats));
end;

procedure TTestRendererPk3NameSelector.DovrebbeDareLeListeOrdinateESenzaDoppioni;
var
  LNames: TRendererPk3Names;
begin
  LNames := FSelector.Select(['textures\zeta.png', 'textures\alfa.png', 'textures\ZETA.jpg',
    'flats\mid.png'], FCatalogRef);
  Assert.AreEqual<Integer>(2, Length(LNames.Textures));
  Assert.AreEqual('ALFA', LNames.Textures[0]);
  Assert.AreEqual('ZETA', LNames.Textures[1]);
  Assert.AreEqual<Integer>(3, Length(LNames.Flats));
  Assert.AreEqual('MID', LNames.Flats[1]);
end;

procedure TTestRendererPk3NameSelector.DovrebbeFallireSenzaCatalogo;
begin
  Assert.WillRaise(
    procedure
    begin
      FSelector.Select(['a'], nil);
    end, ERendererException);
end;

procedure TTestRendererPk3NameSelector.DovrebbeDareLoStessoHashDelVecchioTesto;
var
  LText: string;
  LExpected: Integer;
  LIndex: Integer;
  LByte: Byte;
begin
  // the old Hash, copied here as it was
  LText := 'BRICK'#13#10'ZETA'#13#10 + Char($0141) + #13#10;
  LByte := Ord(LText[1]);
  LExpected := 5381 * 33 + LByte;
  for LIndex := 2 to Length(LText) do
  begin
    LByte := Ord(LText[LIndex]);
    LExpected := LExpected * 33 + LByte;
  end;
  Assert.AreEqual(LExpected, FHash.Compute(LText));
end;

procedure TTestRendererPk3NameSelector.DovrebbeDareZeroPerUnTestoVuoto;
begin
  Assert.AreEqual(0, FHash.Compute(''));
end;

// as the old code: the hash wraps around
{$Q-}
{$R-}

procedure TTestRendererPk3NameSelector.DovrebbeFareComeIlVecchioR_AddTextureFileName;
const
  FOLDERS: array[0..4] of string = ('textures/', 'flats\', 'textures//', 'sprites/', 'Textures\sub/');
  NAMES: array[0..7] of string = ('wall', 'brick', 'a.b', 'toolongname1', 'Sky', 'floor', 'x', 'ab');
  EXTENSIONS: array[0..4] of string = ('.png', '.PNG', '.jpg', '.txt', '');
var
  LRound: Integer;
  LEntries: TArray<string>;
  LIndex: Integer;
  LNames: TRendererPk3Names;
  LOldTextures, LOldFlats: TStringList;
  LUpper, LName, LExt, LPath: string;
  LIsTexture, LIsFlat: Boolean;
  LCatalog: TFakePk3Catalog;
  LCatalogRef: IRendererPk3Catalog;
  LDot: Integer;
  LKnown: Integer;

  function Upper(const S: string): string;
  var
    K: Integer;
  begin
    Result := S;
    for K := 1 to Length(Result) do
      if (Result[K] >= 'a') and (Result[K] <= 'z') then
        Result[K] := Char(Ord(Result[K]) - 32);
  end;

  function Fix(const S: string): string;
  var
    K: Integer;
    Last: Char;
    Tmp: string;
  begin
    Tmp := S;
    for K := 1 to Length(Tmp) do
      if Tmp[K] = '/' then
        Tmp[K] := '\';
    Result := '';
    Last := #0;
    for K := 1 to Length(Tmp) do
    begin
      if (Last <> '\') or (Tmp[K] <> '\') then
        Result := Result + Tmp[K];
      Last := Tmp[K];
    end;
  end;

begin
  RandSeed := 2471;
  for LRound := 1 to 300 do
  begin
    LCatalog := TFakePk3Catalog.Create;
    LCatalogRef := LCatalog;
    for LIndex := 0 to High(NAMES) do
    begin
      if Random(4) = 0 then
        LCatalog.Lumps.Add(Upper(NAMES[LIndex]));
      if Random(4) = 0 then
        LCatalog.Textures.Add(Upper(NAMES[LIndex]));
    end;
    SetLength(LEntries, Random(20));
    for LIndex := 0 to High(LEntries) do
      LEntries[LIndex] := FOLDERS[Random(Length(FOLDERS))] + NAMES[Random(Length(NAMES))] +
        EXTENSIONS[Random(Length(EXTENSIONS))];

    // the old procedure
    LOldTextures := TStringList.Create;
    LOldFlats := TStringList.Create;
    try
      for LIndex := 0 to High(LEntries) do
      begin
        LUpper := Upper(LEntries[LIndex]);
        LExt := ExtractFileExt(LUpper);
        if not LCatalog.IsTextureExtension(LExt) then
          Continue;
        LPath := Fix(LUpper);
        LIsTexture := Pos('TEXTURES\', LPath) > 0;
        LIsFlat := Pos('FLATS\', LPath) > 0;
        if not (LIsTexture or LIsFlat) then
          Continue;
        LUpper := ExtractFileName(LUpper);
        LDot := Pos('.', LUpper);
        if LDot = 0 then
          LName := LUpper
        else
          LName := Copy(LUpper, 1, LDot - 1);
        if LName + LExt <> LUpper then
          Continue;
        if Length(LName) > 8 then
          Continue;
        if LCatalog.Lumps.IndexOf(LName) >= 0 then
          Continue;
        if LIsTexture then
          if LOldTextures.IndexOf(LName) < 0 then
          begin
            LKnown := LCatalog.TextureNumber(LName);
            if LKnown <= 0 then
            begin
              LOldTextures.Add(LName);
              LOldFlats.Add(LName);
              Continue;
            end;
          end;
        if LOldFlats.IndexOf(LName) < 0 then
          LOldFlats.Add(LName);
      end;
      // the old code sorted with the "<" of the strings
      LOldTextures.CaseSensitive := True;
      LOldFlats.CaseSensitive := True;

      LNames := FSelector.Select(LEntries, LCatalogRef);
      Assert.AreEqual<Integer>(LOldTextures.Count, Length(LNames.Textures));
      Assert.AreEqual<Integer>(LOldFlats.Count, Length(LNames.Flats));
      for LIndex := 0 to LOldTextures.Count - 1 do
        Assert.IsTrue(LOldTextures.IndexOf(LNames.Textures[LIndex]) >= 0);
      for LIndex := 0 to LOldFlats.Count - 1 do
        Assert.IsTrue(LOldFlats.IndexOf(LNames.Flats[LIndex]) >= 0);
      for LIndex := 1 to High(LNames.Flats) do
        Assert.IsTrue(CompareStr(LNames.Flats[LIndex - 1], LNames.Flats[LIndex]) < 0);
    finally
      LOldFlats.Free;
      LOldTextures.Free;
    end;
  end;
end;

end.
