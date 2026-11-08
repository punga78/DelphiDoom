{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the column lookup of a texture   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.TextureLookup;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf, DelphiDoom.Logging.Intf,
  DelphiDoom.Tests.Renderer.Fakes;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererTextureLookup = class(TObject)
  private
    FSource: TFakePatchSource;
    FSourceIntf: IRendererPatchSource;
    FLog: TFakeLog;
    FLogIntf: ILog;
    FLookup: IRendererTextureLookup;
    FLump: TArray<Integer>;
    FOffset: TArray<Integer>;
    procedure AddPatch(AWidth: Integer; const APostCounts: TArray<Integer>);
    procedure PrepareTables(AWidth: Integer);
    function MakeTexture(ANumber, AWidth, AHeight: Integer; const ALumps,
      AOrigins: array of Integer): TRendererTextureInfo;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnaSorgenteNulla;
    [Test]
    procedure DovrebbeRifiutareUnLogNullo;
    [Test]
    procedure DovrebbeTenereLaColonnaNellaPatchSeNeHaUnaSola;
    [Test]
    procedure DovrebbeDareZeroSeNessunaColonnaVaNelBlocco;
    [Test]
    procedure DovrebbeSegnareLeColonneSenzaPatch;
    [Test]
    procedure DovrebbeAvvisareLeColonneSenzaPatchDiUnaTexturaSemplice;
    [Test]
    procedure DovrebbeLasciareLeColonneSenzaPatchComeLeHaDate;
    [Test]
    procedure DovrebbeIgnorareUnaPatchChePatchNonE;
    [Test]
    procedure DovrebbeMettereNelBloccoCompostoLeColonneDiPiuPatch;
    [Test]
    procedure DovrebbeAvvisareUnaColonnaSenzaPatchDiUnaTexturaComposta;
    [Test]
    procedure DovrebbeLeggereLeColonneDellaPatchDallOrigine;
    [Test]
    procedure DovrebbeTagliareUnaPatchOltreLaLarghezzaDellaTextura;
    [Test]
    procedure DovrebbeAprireUnaPatchAllaVolta;
    [Test]
    procedure DovrebbeAvvisareUnBloccoOltre64k;
    [Test]
    procedure DovrebbeNonAvvisareUnBloccoDentro64k;
    [Test]
    procedure DovrebbeFallireSeLeTabelleSonoTroppoCorte;
    [Test]
    procedure DovrebbeFallireConUnaLarghezzaNegativa;
    /// <summary>
    ///   Parity: R_GenerateLookup of the old r_data.pas, copied here as it was (over the bytes
    ///   of the patches), and the library give the same tables, the same size of the block
    ///   and the same warnings on random textures
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_GenerateLookup;
  end;

implementation

uses
  DelphiDoom.Renderer.Factory;

const
  SENTINEL_LUMP = -3;
  SENTINEL_OFFSET = 424242;

type
  /// <summary>What the old procedure left in the tables of the texture</summary>
  TOldLookup = record
    Lump: TArray<SmallInt>;
    Offset: TArray<Integer>;
    CompositeSize: Integer;
  end;

/// <summary>
///   The old R_GenerateLookup, with the same loops and the same names: the zone memory and
///   the pointers are the bytes of the patch and offsets in them
/// </summary>
procedure OldGenerateLookup(const ATexture: TRendererTextureInfo;
  const APatches: TArray<TBytes>; var AOld: TOldLookup; const AWarnings: TList<string>);
var
  patchcount: TArray<Integer>;
  postcount: TArray<Integer>;
  x, x1, x2, i, csize, pat, col: Integer;
  bytes: TBytes;
  texturecompositesize: Integer;
  patchwidth: Integer;
begin
  texturecompositesize := 0;
  SetLength(patchcount, ATexture.Width);
  SetLength(postcount, ATexture.Width);

  for i := 0 to High(ATexture.Patches) do
  begin
    pat := ATexture.Patches[i].Lump;
    if (pat < 0) or (pat > High(APatches)) or (Length(APatches[pat]) = 0) then
      Continue;
    bytes := APatches[pat];
    patchwidth := TFakePatchBytes.ReadSmall(bytes, 0);
    x1 := ATexture.Patches[i].OriginX;
    x2 := x1 + patchwidth;

    if x1 < 0 then
      x := 0
    else
      x := x1;

    if x2 > ATexture.Width then
      x2 := ATexture.Width;

    while x < x2 do
    begin
      col := TFakePatchBytes.ReadInt(bytes, 8 + 4 * (x - x1));
      while bytes[col] <> $FF do
      begin
        postcount[x] := postcount[x] + 1;
        col := col + bytes[col + 1] + 4;
      end;
      patchcount[x] := patchcount[x] + 1;
      AOld.Lump[x] := pat;
      AOld.Offset[x] := TFakePatchBytes.ReadInt(bytes, 8 + 4 * (x - x1)) + 3;
      Inc(x);
    end;
  end;

  if Length(ATexture.Patches) > 1 then
  begin
    csize := 0;
    for x := 0 to ATexture.Width - 1 do
    begin
      if patchcount[x] <= 0 then
      begin
        AWarnings.Add(Format('R_GenerateLookup(): column (%d) without a patch (%s, column=%d)'#13#10,
          [x, ATexture.Name, x]));
        AOld.Lump[x] := -2;
      end
      else
      begin
        AOld.Lump[x] := -1;
        AOld.Offset[x] := csize + 3;
        csize := csize + 4 * postcount[x] + 1;
      end;
      csize := csize + ATexture.Height;
    end;
    texturecompositesize := csize;
  end
  else
  begin
    for x := 0 to ATexture.Width - 1 do
    begin
      if patchcount[x] = 0 then
      begin
        AWarnings.Add(Format('R_GenerateLookup(): column (%d) without a patch (%s)'#13#10,
          [x, ATexture.Name]));
        AOld.Lump[x] := -2;
      end
      else if patchcount[x] > 1 then
      begin
        AOld.Lump[x] := -1;
        AOld.Offset[x] := texturecompositesize;

        if texturecompositesize > $10000 - ATexture.Height then
          AWarnings.Add(Format('R_GenerateLookup(): texture %d is > 64k'#13#10, [ATexture.Number]));

        texturecompositesize := texturecompositesize + ATexture.Height;
      end;
    end;
  end;

  if texturecompositesize > $10000 - ATexture.Height then
    AWarnings.Add(Format('R_GenerateLookup(): texture %d is > 64k'#13#10, [ATexture.Number]));
  AOld.CompositeSize := texturecompositesize;
end;

{ TTestRendererTextureLookup }

procedure TTestRendererTextureLookup.Setup;
begin
  FSource := TFakePatchSource.Create;
  FSourceIntf := FSource;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  FLookup := TRendererFactory.CreateTextureLookup(FSourceIntf, FLogIntf);
end;

procedure TTestRendererTextureLookup.TearDown;
begin
  FLookup := nil;
  FLogIntf := nil;
  FLog := nil;
  FSourceIntf := nil;
  FSource := nil;
end;

procedure TTestRendererTextureLookup.AddPatch(AWidth: Integer;
  const APostCounts: TArray<Integer>);
begin
  SetLength(FSource.Patches, Length(FSource.Patches) + 1);
  FSource.Patches[High(FSource.Patches)] := TFakePatchBytes.Build(AWidth, APostCounts);
end;

procedure TTestRendererTextureLookup.PrepareTables(AWidth: Integer);
var
  LIndex: Integer;
begin
  SetLength(FLump, AWidth);
  SetLength(FOffset, AWidth);
  for LIndex := 0 to AWidth - 1 do
  begin
    FLump[LIndex] := SENTINEL_LUMP;
    FOffset[LIndex] := SENTINEL_OFFSET;
  end;
end;

function TTestRendererTextureLookup.MakeTexture(ANumber, AWidth, AHeight: Integer;
  const ALumps, AOrigins: array of Integer): TRendererTextureInfo;
var
  LIndex: Integer;
begin
  Result.Number := ANumber;
  Result.Name := 'WALL';
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Patches, Length(ALumps));
  for LIndex := 0 to High(ALumps) do
  begin
    Result.Patches[LIndex].Lump := ALumps[LIndex];
    Result.Patches[LIndex].OriginX := AOrigins[LIndex];
  end;
end;

procedure TTestRendererTextureLookup.DovrebbeRifiutareUnaSorgenteNulla;
begin
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateTextureLookup(nil, FLogIntf);
    end,
    EArgumentNilException);
end;

procedure TTestRendererTextureLookup.DovrebbeRifiutareUnLogNullo;
begin
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateTextureLookup(FSourceIntf, nil);
    end,
    EArgumentNilException);
end;

procedure TTestRendererTextureLookup.DovrebbeTenereLaColonnaNellaPatchSeNeHaUnaSola;
var
  LTexture: TRendererTextureInfo;
  LSize: Integer;
  LColumn: Integer;
begin
  AddPatch(4, TArray<Integer>.Create(1, 2, 3, 1));
  LTexture := MakeTexture(0, 4, 64, [0], [0]);
  PrepareTables(4);

  LSize := FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(0, LSize);
  for LColumn := 0 to 3 do
  begin
    Assert.AreEqual(0, FLump[LColumn], 'lump della colonna');
    Assert.AreEqual(TFakePatchBytes.ReadInt(FSource.Patches[0], 8 + 4 * LColumn) + 3,
      FOffset[LColumn], 'offset della colonna');
  end;
  Assert.AreEqual(0, FLog.DevWarnings.Count);
end;

procedure TTestRendererTextureLookup.DovrebbeDareZeroSeNessunaColonnaVaNelBlocco;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(2, TArray<Integer>.Create(1, 1));
  LTexture := MakeTexture(0, 2, 32, [0], [0]);
  PrepareTables(2);

  Assert.AreEqual(0, FLookup.Build(LTexture, FLump, FOffset));
end;

procedure TTestRendererTextureLookup.DovrebbeSegnareLeColonneSenzaPatch;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(2, TArray<Integer>.Create(1, 1));
  LTexture := MakeTexture(0, 4, 32, [0], [0]);
  PrepareTables(4);

  FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(0, FLump[0]);
  Assert.AreEqual(0, FLump[1]);
  Assert.AreEqual(RENDERER_COLUMN_WITHOUT_PATCH, FLump[2]);
  Assert.AreEqual(RENDERER_COLUMN_WITHOUT_PATCH, FLump[3]);
end;

procedure TTestRendererTextureLookup.DovrebbeAvvisareLeColonneSenzaPatchDiUnaTexturaSemplice;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(1, TArray<Integer>.Create(1));
  LTexture := MakeTexture(0, 3, 32, [0], [0]);
  PrepareTables(3);

  FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(2, FLog.DevWarnings.Count);
  Assert.AreEqual('R_GenerateLookup(): column (1) without a patch (WALL)'#13#10,
    FLog.DevWarnings[0]);
  Assert.AreEqual('R_GenerateLookup(): column (2) without a patch (WALL)'#13#10,
    FLog.DevWarnings[1]);
  Assert.AreEqual(0, FLog.Others.Count, 'solo avvisi da sviluppatore');
end;

procedure TTestRendererTextureLookup.DovrebbeLasciareLeColonneSenzaPatchComeLeHaDate;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(1, TArray<Integer>.Create(1));
  LTexture := MakeTexture(0, 2, 32, [0], [0]);
  PrepareTables(2);

  FLookup.Build(LTexture, FLump, FOffset);

  // the offset of a column that nothing covers is never read by the renderer
  Assert.AreEqual(SENTINEL_OFFSET, FOffset[1]);
end;

procedure TTestRendererTextureLookup.DovrebbeIgnorareUnaPatchChePatchNonE;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(2, TArray<Integer>.Create(1, 1));
  // the lump 1 has no bytes, the lump -1 does not exist
  SetLength(FSource.Patches, 2);
  LTexture := MakeTexture(0, 2, 32, [1, -1], [0, 0]);
  PrepareTables(2);

  FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(RENDERER_COLUMN_WITHOUT_PATCH, FLump[0]);
  Assert.AreEqual(RENDERER_COLUMN_WITHOUT_PATCH, FLump[1]);
  Assert.AreEqual(0, FSource.OpenCount, 'non si apre cio che non e una patch');
end;

procedure TTestRendererTextureLookup.DovrebbeMettereNelBloccoCompostoLeColonneDiPiuPatch;
var
  LTexture: TRendererTextureInfo;
  LSize: Integer;
begin
  // the patch 0 covers the columns 0..2 (one post each), the patch 1 the columns 2..4 (two each)
  AddPatch(3, TArray<Integer>.Create(1, 1, 1));
  AddPatch(3, TArray<Integer>.Create(2, 2, 2));
  LTexture := MakeTexture(0, 5, 10, [0, 1], [0, 2]);
  PrepareTables(5);

  LSize := FLookup.Build(LTexture, FLump, FOffset);

  // a column takes 4 bytes for each post, one for the end and the pixels of the height
  Assert.AreEqual(91, LSize);
  Assert.AreEqual(RENDERER_COLUMN_COMPOSITE, FLump[0]);
  Assert.AreEqual(RENDERER_COLUMN_COMPOSITE, FLump[4]);
  Assert.AreEqual(3, FOffset[0]);
  Assert.AreEqual(18, FOffset[1]);
  Assert.AreEqual(33, FOffset[2], 'la colonna 2 ha i post di tutte e due');
  Assert.AreEqual(56, FOffset[3]);
  Assert.AreEqual(75, FOffset[4]);
  Assert.AreEqual(0, FLog.DevWarnings.Count);
end;

procedure TTestRendererTextureLookup.DovrebbeAvvisareUnaColonnaSenzaPatchDiUnaTexturaComposta;
var
  LTexture: TRendererTextureInfo;
  LSize: Integer;
begin
  AddPatch(1, TArray<Integer>.Create(1));
  AddPatch(1, TArray<Integer>.Create(1));
  // the column 1 has no patch; the block still has the height of the texture for it
  LTexture := MakeTexture(0, 3, 10, [0, 1], [0, 2]);
  PrepareTables(3);

  LSize := FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(RENDERER_COLUMN_WITHOUT_PATCH, FLump[1]);
  Assert.AreEqual(5 + 10 + 10 + 5 + 10, LSize);
  Assert.AreEqual(1, FLog.DevWarnings.Count);
  Assert.AreEqual('R_GenerateLookup(): column (1) without a patch (WALL, column=1)'#13#10,
    FLog.DevWarnings[0]);
end;

procedure TTestRendererTextureLookup.DovrebbeLeggereLeColonneDellaPatchDallOrigine;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(5, TArray<Integer>.Create(1, 2, 3, 1, 2));
  // the first two columns of the patch are out of the texture on the left
  LTexture := MakeTexture(0, 3, 32, [0], [-2]);
  PrepareTables(3);

  FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(TFakePatchBytes.ReadInt(FSource.Patches[0], 8 + 4 * 2) + 3, FOffset[0]);
  Assert.AreEqual(TFakePatchBytes.ReadInt(FSource.Patches[0], 8 + 4 * 3) + 3, FOffset[1]);
  Assert.AreEqual(TFakePatchBytes.ReadInt(FSource.Patches[0], 8 + 4 * 4) + 3, FOffset[2]);
end;

procedure TTestRendererTextureLookup.DovrebbeTagliareUnaPatchOltreLaLarghezzaDellaTextura;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(6, TArray<Integer>.Create(1, 1, 1, 1, 1, 1));
  LTexture := MakeTexture(0, 4, 32, [0], [2]);
  PrepareTables(4);

  FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(RENDERER_COLUMN_WITHOUT_PATCH, FLump[0]);
  Assert.AreEqual(RENDERER_COLUMN_WITHOUT_PATCH, FLump[1]);
  Assert.AreEqual(0, FLump[2]);
  Assert.AreEqual(0, FLump[3]);
end;

procedure TTestRendererTextureLookup.DovrebbeAprireUnaPatchAllaVolta;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(2, TArray<Integer>.Create(1, 1));
  AddPatch(2, TArray<Integer>.Create(1, 1));
  AddPatch(2, TArray<Integer>.Create(1, 1));
  LTexture := MakeTexture(0, 6, 16, [0, 1, 2], [0, 2, 4]);
  PrepareTables(6);

  FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(3, FSource.OpenCount);
  Assert.AreEqual(1, FSource.MaxOpen, 'ogni patch torna alla cache prima della successiva');
  Assert.AreEqual(0, FSource.OpenNow);
end;

procedure TTestRendererTextureLookup.DovrebbeAvvisareUnBloccoOltre64k;
var
  LTexture: TRendererTextureInfo;
  LSize: Integer;
begin
  AddPatch(4, TArray<Integer>.Create(1, 1, 1, 1));
  AddPatch(4, TArray<Integer>.Create(1, 1, 1, 1));
  LTexture := MakeTexture(7, 4, 20000, [0, 1], [0, 0]);
  PrepareTables(4);

  LSize := FLookup.Build(LTexture, FLump, FOffset);

  Assert.IsTrue(LSize > RENDERER_COMPOSITE_LIMIT - 20000);
  Assert.AreEqual(1, FLog.DevWarnings.Count);
  Assert.AreEqual('R_GenerateLookup(): texture 7 is > 64k'#13#10, FLog.DevWarnings[0]);
end;

procedure TTestRendererTextureLookup.DovrebbeNonAvvisareUnBloccoDentro64k;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(4, TArray<Integer>.Create(1, 1, 1, 1));
  AddPatch(4, TArray<Integer>.Create(1, 1, 1, 1));
  LTexture := MakeTexture(7, 4, 128, [0, 1], [0, 0]);
  PrepareTables(4);

  FLookup.Build(LTexture, FLump, FOffset);

  Assert.AreEqual(0, FLog.DevWarnings.Count);
end;

procedure TTestRendererTextureLookup.DovrebbeFallireSeLeTabelleSonoTroppoCorte;
var
  LTexture: TRendererTextureInfo;
begin
  AddPatch(4, TArray<Integer>.Create(1, 1, 1, 1));
  LTexture := MakeTexture(0, 4, 32, [0], [0]);
  PrepareTables(3);

  Assert.WillRaise(
    procedure
    begin
      FLookup.Build(LTexture, FLump, FOffset);
    end,
    ERendererException);
end;

procedure TTestRendererTextureLookup.DovrebbeFallireConUnaLarghezzaNegativa;
var
  LTexture: TRendererTextureInfo;
begin
  LTexture := MakeTexture(0, -1, 32, [], []);
  PrepareTables(0);

  Assert.WillRaise(
    procedure
    begin
      FLookup.Build(LTexture, FLump, FOffset);
    end,
    ERendererException);
end;

procedure TTestRendererTextureLookup.DovrebbeFareComeIlVecchioR_GenerateLookup;
var
  LCase: Integer;
  LPatchIndex: Integer;
  LPostCounts: TArray<Integer>;
  LWidth: Integer;
  LHeight: Integer;
  LPatchCount: Integer;
  LLumps: TArray<Integer>;
  LOrigins: TArray<Integer>;
  LTexture: TRendererTextureInfo;
  LOld: TOldLookup;
  LOldWarnings: TList<string>;
  LNewSize: Integer;
  LColumn: Integer;
  LWarning: Integer;
  LCompared: Integer;
begin
  RandSeed := 20260711;
  // six patches of random width and posts, then a lump without bytes
  for LPatchIndex := 0 to 5 do
  begin
    LWidth := 1 + Random(12);
    SetLength(LPostCounts, LWidth);
    for LColumn := 0 to LWidth - 1 do
      LPostCounts[LColumn] := Random(5);
    AddPatch(LWidth, LPostCounts);
  end;
  SetLength(FSource.Patches, 7);

  LCompared := 0;
  LOldWarnings := TList<string>.Create;
  try
    for LCase := 1 to 400 do
    begin
      LWidth := 1 + Random(30);
      if Random(10) = 0 then
        LHeight := 6000 + Random(20000)
      else
        LHeight := 1 + Random(150);
      LPatchCount := Random(5);
      SetLength(LLumps, LPatchCount);
      SetLength(LOrigins, LPatchCount);
      for LPatchIndex := 0 to LPatchCount - 1 do
      begin
        LLumps[LPatchIndex] := Random(8) - 1;
        LOrigins[LPatchIndex] := Random(LWidth + 13) - 8;
      end;
      LTexture := MakeTexture(LCase, LWidth, LHeight, LLumps, LOrigins);

      PrepareTables(LWidth);
      SetLength(LOld.Lump, LWidth);
      SetLength(LOld.Offset, LWidth);
      for LColumn := 0 to LWidth - 1 do
      begin
        LOld.Lump[LColumn] := SENTINEL_LUMP;
        LOld.Offset[LColumn] := SENTINEL_OFFSET;
      end;
      LOldWarnings.Clear;
      FLog.DevWarnings.Clear;

      OldGenerateLookup(LTexture, FSource.Patches, LOld, LOldWarnings);
      LNewSize := FLookup.Build(LTexture, FLump, FOffset);

      Assert.AreEqual(LOld.CompositeSize, LNewSize, Format('dimensione del blocco (caso %d)', [LCase]));
      for LColumn := 0 to LWidth - 1 do
      begin
        Assert.AreEqual(Integer(LOld.Lump[LColumn]), Integer(SmallInt(FLump[LColumn])),
          Format('lump (caso %d, colonna %d)', [LCase, LColumn]));
        Assert.AreEqual(LOld.Offset[LColumn], FOffset[LColumn],
          Format('offset (caso %d, colonna %d)', [LCase, LColumn]));
        Inc(LCompared);
      end;
      Assert.AreEqual(LOldWarnings.Count, FLog.DevWarnings.Count,
        Format('numero di avvisi (caso %d)', [LCase]));
      for LWarning := 0 to LOldWarnings.Count - 1 do
        Assert.AreEqual(LOldWarnings[LWarning], FLog.DevWarnings[LWarning],
          Format('avviso %d (caso %d)', [LWarning, LCase]));
    end;
  finally
    LOldWarnings.Free;
  end;
  Assert.IsTrue(LCompared > 1000, 'il confronto ha coperto abbastanza colonne');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRendererTextureLookup);

end.
