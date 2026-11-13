{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - roads, walls, ruins, trees and the   }
{  spatial grid                                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Autotile;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.War.Level.Types, DelphiDoom.War.Autotile.Types,
  DelphiDoom.War.Autotile.Line, DelphiDoom.War.Autotile.Ruins, DelphiDoom.War.Autotile.Forest;

type
  /// <summary>
  ///   autotile.tables.golden.txt, autotile.golden.txt and grid.golden.txt are the output of war_lvl_ref.exe: the
  ///   tables of war_units.c and the functions of war_roads.c, war_walls.c, war_ruins.c, war_trees.c and
  ///   war_map_grid.c of war1 as they are, compiled with gcc (Tools\Verifica\193), on scenarios with a fixed seed
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarAutotile = class(TObject)
  private
    FState: Cardinal;
    function Next: Cardinal;
    function Range(AMax: Integer): Integer;
    function Construct(AType: TWarConstructType): TWarLevelConstruct;
    function Checksum(const ABytes: TBytes): string;
    function LineChecksum(const APieces: TArray<TWarLinePiece>): string;
    function Tree(AX, AY, AAmount: Integer; AType: Byte): TWarTree;
  public
    [Test]
    procedure DovrebbeDareLeStesseTabelleDelCodiceOriginale;
    [Test]
    procedure DovrebbeAggiungereDueVolteLUltimaCellaDiUnaStrada;
    [Test]
    procedure DovrebbeSeguireLaDirezioneNegativaDiUnaStrada;
    [Test]
    procedure DovrebbeDareLaCellaDiUnaStradaDritta;
    [Test]
    procedure DovrebbeDareIlPezzoDellaStradaDaiVicini;
    [Test]
    procedure DovrebbeContareComeVicinoIlBordoDellaMappa;
    [Test]
    procedure DovrebbeCercareEToglierePezziDiUnaStrada;
    [Test]
    procedure DovrebbeUsareLaTabellaDeiMuriPerIMuri;
    [Test]
    procedure DovrebbeAggiungereUnaCellaSola;
    [Test]
    procedure DovrebbeAggiungereUnQuadratoDiRovineSenzaDoppioni;
    [Test]
    procedure DovrebbeDareIlPezzoCentraleELeAngolariDelleRovine;
    [Test]
    procedure DovrebbeToglierePerLeRovineSenzaPezzo;
    [Test]
    procedure DovrebbeCercarePezziDiRovine;
    [Test]
    procedure DovrebbeToglierePerGliAlberiIsolati;
    [Test]
    procedure DovrebbeNonRicalcolareUnAlberoTagliato;
    [Test]
    procedure DovrebbeNonContareUnVicinoSenzaLegna;
    [Test]
    procedure DovrebbeCercareAlberi;
    [Test]
    procedure DovrebbeRiconoscereUnAlberoValido;
    [Test]
    procedure DovrebbeDareLeStesseStradeEMuriDelCodiceOriginale;
    [Test]
    procedure DovrebbeDareLeStesseRovineEAlberiDelCodiceOriginale;
  end;

implementation

uses
  DelphiDoom.MathCore.Crc32, DelphiDoom.War.Autotile.Data, DelphiDoom.Tests.War.RealData;

const
  ROAD_LEFT = 0;
  ROAD_HORIZONTAL = 12;
  ROAD_VERTICAL = 5;
  RUIN_CENTER = 5;
  RUIN_TOP_LEFT = 1;

{ TTestWarAutotile }

function TTestWarAutotile.Next: Cardinal;
begin
  FState := FState * 1103515245 + 12345;
  Result := (FState shr 16) and $7FFF;
end;

function TTestWarAutotile.Range(AMax: Integer): Integer;
begin
  Result := Integer(Next mod Cardinal(AMax));
end;

function TTestWarAutotile.Construct(AType: TWarConstructType): TWarLevelConstruct;
begin
  Result.ConstructType := AType;
  Result.X1 := Byte(Range(70));
  Result.Y1 := Byte(Range(70));
  Result.X2 := Byte(Range(70));
  Result.Y2 := Byte(Range(70));
  Result.Player := Byte(Range(5));
end;

function TTestWarAutotile.Checksum(const ABytes: TBytes): string;
var
  LCrc: TCrc32;
begin
  LCrc := TCrc32.Create;
  try
    if Length(ABytes) > 0 then
      LCrc.Update(ABytes[0], Length(ABytes));
    Result := LowerCase(TCrc32.ToHex(LCrc.Value));
  finally
    LCrc.Free;
  end;
end;

function TTestWarAutotile.LineChecksum(const APieces: TArray<TWarLinePiece>): string;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(APieces) * 4);
  for LIndex := 0 to High(APieces) do
  begin
    LBytes[LIndex * 4] := APieces[LIndex].PieceType;
    LBytes[LIndex * 4 + 1] := Byte(APieces[LIndex].TileX);
    LBytes[LIndex * 4 + 2] := Byte(APieces[LIndex].TileY);
    LBytes[LIndex * 4 + 3] := APieces[LIndex].Player;
  end;
  Result := Checksum(LBytes);
end;

function TTestWarAutotile.Tree(AX, AY, AAmount: Integer; AType: Byte): TWarTree;
begin
  Result.TileType := AType;
  Result.TileX := AX;
  Result.TileY := AY;
  Result.Amount := AAmount;
end;

procedure TTestWarAutotile.DovrebbeDareLeStesseTabelleDelCodiceOriginale;
var
  LGolden: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LRoad: Integer;
  LWall: Integer;
  LRuin: Integer;
  LTree: Integer;
  LIndex: Integer;
begin
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('autotile.tables.golden.txt'));
    LRoad := 0;
    LWall := 0;
    LRuin := 1;
    LTree := 0;
    for LLine in LGolden do
    begin
      LParts := LLine.Split([' ']);
      if LParts[0] = 'TR' then
      begin
        Assert.AreEqual(LRoad, StrToInt(LParts[1]));
        Assert.AreEqual(StrToInt(LParts[2]), WAR_ROAD_DATA[LRoad].Forest);
        Assert.AreEqual(StrToInt(LParts[3]), WAR_ROAD_DATA[LRoad].Swamp);
        Inc(LRoad);
      end
      else if LParts[0] = 'TW' then
      begin
        Assert.AreEqual(LWall, StrToInt(LParts[1]));
        Assert.AreEqual(StrToInt(LParts[2]), WAR_WALL_DATA[LWall].Forest);
        Assert.AreEqual(StrToInt(LParts[3]), WAR_WALL_DATA[LWall].DamagedForest);
        Assert.AreEqual(StrToInt(LParts[4]), WAR_WALL_DATA[LWall].DestroyedForest);
        Assert.AreEqual(StrToInt(LParts[5]), WAR_WALL_DATA[LWall].Swamp);
        Assert.AreEqual(StrToInt(LParts[6]), WAR_WALL_DATA[LWall].DamagedSwamp);
        Assert.AreEqual(StrToInt(LParts[7]), WAR_WALL_DATA[LWall].DestroyedSwamp);
        Inc(LWall);
      end
      else if LParts[0] = 'TU' then
      begin
        Assert.AreEqual(LRuin, StrToInt(LParts[1]));
        Assert.AreEqual(StrToInt(LParts[2]), WAR_RUIN_DATA[LRuin].Forest);
        Assert.AreEqual(StrToInt(LParts[3]), WAR_RUIN_DATA[LRuin].Swamp);
        Inc(LRuin);
      end
      else if LParts[0] = 'TT' then
      begin
        Assert.AreEqual(LTree, StrToInt(LParts[1]));
        Assert.AreEqual(StrToInt(LParts[2]), WAR_TREE_DATA[LTree].Forest);
        Assert.AreEqual(StrToInt(LParts[3]), WAR_TREE_DATA[LTree].Swamp);
        Inc(LTree);
      end
      else if LParts[0] = 'MR' then
      begin
        for LIndex := 0 to 15 do
          Assert.AreEqual(StrToInt(LParts[LIndex + 1]), Integer(WAR_ROAD_TILE_TYPE_MAP[LIndex]));
      end
      else if LParts[0] = 'MW' then
      begin
        for LIndex := 0 to 15 do
          Assert.AreEqual(StrToInt(LParts[LIndex + 1]), Integer(WAR_WALL_TILE_TYPE_MAP[LIndex]));
      end
      else if LParts[0] = 'MU' then
      begin
        for LIndex := 0 to 255 do
          Assert.AreEqual(StrToInt(LParts[LIndex + 1]), Integer(WAR_RUIN_TILE_TYPE_MAP[LIndex]));
      end
      else if LParts[0] = 'MT' then
      begin
        for LIndex := 0 to 255 do
          Assert.AreEqual(StrToInt(LParts[LIndex + 1]), Integer(WAR_TREE_TILE_TYPE_MAP[LIndex]));
      end
      else if LParts[0] = 'MF' then
      begin
        for LIndex := 0 to 255 do
          Assert.AreEqual(StrToInt(LParts[LIndex + 1]), Integer(WAR_FOG_TILE_TYPE_MAP[LIndex]));
      end;
    end;
    Assert.AreEqual(15, LRoad);
    Assert.AreEqual(15, LWall);
    Assert.AreEqual(16, LRuin);
    Assert.AreEqual(20, LTree);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeAggiungereDueVolteLUltimaCellaDiUnaStrada;
var
  LRoad: TWarLine;
  LConstruct: TWarLevelConstruct;
begin
  LRoad := TWarLine.CreateRoad;
  try
    LConstruct.ConstructType := wctRoad;
    LConstruct.X1 := 1;
    LConstruct.Y1 := 1;
    LConstruct.X2 := 3;
    LConstruct.Y2 := 1;
    LConstruct.Player := 0;
    LRoad.AddFromConstruct(LConstruct);
    // (1,1) (2,1) (3,1) and again (3,1): the corner and the end are the same cell
    Assert.AreEqual(4, LRoad.Count);
    Assert.AreEqual(3, LRoad.Pieces[3].TileX);
    Assert.AreEqual(3, LRoad.Pieces[2].TileX);
  finally
    LRoad.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeSeguireLaDirezioneNegativaDiUnaStrada;
var
  LRoad: TWarLine;
  LConstruct: TWarLevelConstruct;
begin
  LRoad := TWarLine.CreateRoad;
  try
    LConstruct.ConstructType := wctRoad;
    LConstruct.X1 := 5;
    LConstruct.Y1 := 5;
    LConstruct.X2 := 3;
    LConstruct.Y2 := 2;
    LConstruct.Player := 1;
    LRoad.AddFromConstruct(LConstruct);
    // x: 5, 4, then (3,5); y: 5, 4, 3, then (3,2)
    Assert.AreEqual(2 + 1 + 3 + 1, LRoad.Count);
    Assert.IsTrue(LRoad.HasPieceAt(4, 5));
    Assert.IsTrue(LRoad.HasPieceAt(3, 3));
    Assert.IsTrue(LRoad.HasPieceAt(3, 2));
    Assert.IsFalse(LRoad.HasPieceAt(5, 2));
  finally
    LRoad.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeDareLaCellaDiUnaStradaDritta;
var
  LRoad: TWarLine;
  LConstruct: TWarLevelConstruct;
begin
  LRoad := TWarLine.CreateRoad;
  try
    LConstruct.ConstructType := wctRoad;
    LConstruct.X1 := 4;
    LConstruct.Y1 := 4;
    LConstruct.X2 := 4;
    LConstruct.Y2 := 4;
    LConstruct.Player := 0;
    LRoad.AddFromConstruct(LConstruct);
    // from and to the same cell: the original adds it twice (the first add after the x loop, then the end)
    Assert.AreEqual(2, LRoad.Count);
  finally
    LRoad.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeDareIlPezzoDellaStradaDaiVicini;
var
  LRoad: TWarLine;
  LPiece: TWarLinePiece;
begin
  LRoad := TWarLine.CreateRoad;
  try
    LRoad.AddPiece(10, 10, 0);
    LRoad.AddPiece(11, 10, 0);
    LRoad.AddPiece(12, 10, 0);
    LRoad.AddPiece(11, 11, 0);
    LRoad.DetermineTypes;
    Assert.IsTrue(LRoad.TryGetPieceAt(10, 10, LPiece));
    Assert.AreEqual(ROAD_LEFT, Integer(LPiece.PieceType));
    // the middle one has left, right and below: a T (index 14 = bits 1, 2 and 3 -> 13)
    Assert.IsTrue(LRoad.TryGetPieceAt(11, 10, LPiece));
    Assert.AreEqual(Integer(WAR_ROAD_TILE_TYPE_MAP[2 or 4 or 8]), Integer(LPiece.PieceType));
    Assert.IsTrue(LRoad.TryGetPieceAt(11, 11, LPiece));
    Assert.AreEqual(Integer(WAR_ROAD_TILE_TYPE_MAP[1]), Integer(LPiece.PieceType));
  finally
    LRoad.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeContareComeVicinoIlBordoDellaMappa;
var
  LRoad: TWarLine;
  LPiece: TWarLinePiece;
begin
  LRoad := TWarLine.CreateRoad;
  try
    LRoad.AddPiece(0, 0, 0);
    LRoad.DetermineTypes;
    // up and left are outside: bits 0 and 3 -> mask 9
    LRoad.TryGetPieceAt(0, 0, LPiece);
    Assert.AreEqual(Integer(WAR_ROAD_TILE_TYPE_MAP[9]), Integer(LPiece.PieceType));
  finally
    LRoad.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeCercareEToglierePezziDiUnaStrada;
var
  LRoad: TWarLine;
  LPiece: TWarLinePiece;
begin
  LRoad := TWarLine.CreateRoad;
  try
    LRoad.AddPiece(5, 5, 2);
    LRoad.AddPiece(6, 5, 3);
    Assert.IsFalse(LRoad.TryGetPieceAt(9, 9, LPiece));
    Assert.AreEqual(0, LPiece.TileX);
    Assert.IsTrue(LRoad.TryGetPieceAt(6, 5, LPiece));
    Assert.AreEqual(3, Integer(LPiece.Player));
    LRoad.RemovePiece(LPiece);
    Assert.AreEqual(1, LRoad.Count);
    Assert.IsFalse(LRoad.HasPieceAt(6, 5));
    // a piece that is not there: nothing happens
    LRoad.RemovePiece(LPiece);
    Assert.AreEqual(1, LRoad.Count);
  finally
    LRoad.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeUsareLaTabellaDeiMuriPerIMuri;
var
  LWall: TWarLine;
  LPiece: TWarLinePiece;
begin
  LWall := TWarLine.CreateWall;
  try
    LWall.AddPiece(20, 20, 0);
    LWall.AddPiece(21, 20, 0);
    LWall.DetermineTypes;
    LWall.TryGetPieceAt(21, 20, LPiece);
    Assert.AreEqual(Integer(WAR_WALL_TILE_TYPE_MAP[8]), Integer(LPiece.PieceType));
  finally
    LWall.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeAggiungereUnaCellaSola;
var
  LRoad: TWarLine;
begin
  LRoad := TWarLine.CreateRoad;
  try
    LRoad.AddPiece(1, 2, 3);
    Assert.AreEqual(1, LRoad.Count);
    Assert.AreEqual(3, Integer(LRoad.Pieces[0].Player));
  finally
    LRoad.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeAggiungereUnQuadratoDiRovineSenzaDoppioni;
var
  LRuins: TWarRuins;
begin
  LRuins := TWarRuins.Create;
  try
    LRuins.AddSquare(10, 10, 3);
    Assert.AreEqual(9, LRuins.Count);
    LRuins.AddSquare(11, 11, 3);
    Assert.AreEqual(9 + 5, LRuins.Count);
  finally
    LRuins.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeDareIlPezzoCentraleELeAngolariDelleRovine;
var
  LRuins: TWarRuins;
  LPiece: TWarRuinPiece;
begin
  LRuins := TWarRuins.Create;
  try
    LRuins.AddSquare(10, 10, 3);
    LRuins.DetermineTypes;
    Assert.AreEqual(9, LRuins.Count);
    LRuins.TryGetPieceAt(11, 11, LPiece);
    Assert.AreEqual(RUIN_CENTER, Integer(LPiece.PieceType));
    LRuins.TryGetPieceAt(10, 10, LPiece);
    Assert.AreEqual(RUIN_TOP_LEFT, Integer(LPiece.PieceType));
  finally
    LRuins.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeToglierePerLeRovineSenzaPezzo;
var
  LRuins: TWarRuins;
begin
  LRuins := TWarRuins.Create;
  try
    LRuins.AddSquare(30, 30, 1);
    LRuins.AddSquare(40, 40, 2);
    Assert.AreEqual(5, LRuins.Count);
    LRuins.DetermineTypes;
    Assert.IsFalse(LRuins.HasPieceAt(30, 30));
  finally
    LRuins.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeCercarePezziDiRovine;
var
  LRuins: TWarRuins;
  LPiece: TWarRuinPiece;
begin
  LRuins := TWarRuins.Create;
  try
    LRuins.AddSquare(10, 10, 3);
    Assert.IsTrue(LRuins.TryGetPieceAt(10, 10, LPiece));
    LRuins.RemovePiece(LPiece);
    Assert.AreEqual(8, LRuins.Count);
    Assert.IsFalse(LRuins.HasPieceAt(10, 10));
    Assert.IsFalse(LRuins.TryGetPieceAt(10, 10, LPiece));
    LRuins.RemovePiece(LPiece);
    Assert.AreEqual(8, LRuins.Count);
  finally
    LRuins.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeToglierePerGliAlberiIsolati;
var
  LForest: TWarForest;
  LIndex: Integer;
begin
  LForest := TWarForest.Create;
  try
    LForest.AddTree(Tree(30, 30, 100, 0));
    for LIndex := 0 to 2 do
    begin
      LForest.AddTree(Tree(10 + LIndex, 10, 100, 0));
      LForest.AddTree(Tree(10 + LIndex, 11, 100, 0));
      LForest.AddTree(Tree(10 + LIndex, 12, 100, 0));
    end;
    LForest.DetermineTiles;
    Assert.AreEqual(9, LForest.Count);
    Assert.IsFalse(LForest.HasTreeAt(30, 30));
  finally
    LForest.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeNonRicalcolareUnAlberoTagliato;
var
  LForest: TWarForest;
  LTree: TWarTree;
begin
  LForest := TWarForest.Create;
  try
    LForest.AddTree(Tree(30, 30, 0, WAR_TREE_CHOPPED));
    LForest.DetermineTiles;
    Assert.AreEqual(1, LForest.Count);
    Assert.IsTrue(LForest.TryGetTreeAt(30, 30, LTree));
    Assert.AreEqual(Integer(WAR_TREE_CHOPPED), Integer(LTree.TileType));
  finally
    LForest.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeNonContareUnVicinoSenzaLegna;
var
  LForest: TWarForest;
  LTree: TWarTree;
begin
  LForest := TWarForest.Create;
  try
    // a tree at (10,10) with a neighbor with no wood only: it has no neighbor, so it gets no tile and goes away
    LForest.AddTree(Tree(10, 10, 5, 0));
    LForest.AddTree(Tree(11, 10, 0, 0));
    LForest.DetermineTiles;
    Assert.IsFalse(LForest.TryGetTreeAt(10, 10, LTree));
  finally
    LForest.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeCercareAlberi;
var
  LForest: TWarForest;
  LTree: TWarTree;
begin
  LForest := TWarForest.Create;
  try
    LForest.AddTree(Tree(3, 4, 7, 0));
    Assert.IsTrue(LForest.HasTreeAt(3, 4));
    Assert.IsFalse(LForest.HasTreeAt(4, 3));
    Assert.IsTrue(LForest.TryGetTreeAt(3, 4, LTree));
    Assert.AreEqual(7, LTree.Amount);
    Assert.IsFalse(LForest.TryGetTreeAt(4, 3, LTree));
    Assert.AreEqual<Integer>(1, Length(LForest.Trees));
  finally
    LForest.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeRiconoscereUnAlberoValido;
var
  LForest: TWarForest;
begin
  LForest := TWarForest.Create;
  try
    LForest.AddTree(Tree(5, 5, 1, 0));
    LForest.AddTree(Tree(5, 6, 1, 0));
    LForest.AddTree(Tree(9, 9, 1, 0));
    Assert.IsTrue(LForest.IsValidTree(Tree(5, 5, 1, 0)));
    Assert.IsTrue(LForest.IsValidTree(Tree(5, 6, 1, 0)));
    Assert.IsFalse(LForest.IsValidTree(Tree(9, 9, 1, 0)));
  finally
    LForest.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeDareLeStesseStradeEMuriDelCodiceOriginale;
var
  LGolden: TStringList;
  LActual: TStringList;
  LScenario: Integer;
  LRoad: TWarLine;
  LWall: TWarLine;
  LCount: Integer;
  LIndex: Integer;
  LRoadConstruct: TWarLevelConstruct;
  LWallConstruct: TWarLevelConstruct;
  LFirst: TWarLinePiece;
  LFound: TWarLinePiece;
  LPieceType: Integer;
  LHasFirst: Integer;
begin
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('autotile.golden.txt'));
    for LScenario := 0 to 119 do
    begin
      FState := 5000 + Cardinal(LScenario);
      LRoad := TWarLine.CreateRoad;
      LWall := TWarLine.CreateWall;
      try
        LCount := 1 + Range(4);
        for LIndex := 0 to LCount - 1 do
        begin
          LRoadConstruct := Construct(wctRoad);
          LRoad.AddFromConstruct(LRoadConstruct);
          LWallConstruct := Construct(wctWall);
          LWall.AddFromConstruct(LWallConstruct);
        end;
        LRoad.DetermineTypes;
        LWall.DetermineTypes;
        LActual.Add(Format('R %d %d %s', [LScenario, LRoad.Count, LineChecksum(LRoad.Pieces)]));
        LActual.Add(Format('W %d %d %s', [LScenario, LWall.Count, LineChecksum(LWall.Pieces)]));
        if LRoad.Count > 0 then
        begin
          LFirst := LRoad.Pieces[0];
          if LRoad.TryGetPieceAt(LFirst.TileX, LFirst.TileY, LFound) then
            LPieceType := LFound.PieceType
          else
            LPieceType := -1;
          LHasFirst := Ord(LRoad.HasPieceAt(LFirst.TileX, LFirst.TileY));
          LActual.Add(Format('r %d %d %d %d', [LScenario, LPieceType, Ord(LRoad.HasPieceAt(99, 99)), LHasFirst]));
          LRoad.RemovePiece(LFirst);
          LActual.Add(Format('rr %d %d', [LScenario, LRoad.Count]));
        end;
      finally
        LWall.Free;
        LRoad.Free;
      end;
      // the lines of this scenario for ruins and trees come from the other test: take them from the golden
      LActual.Add('~' + IntToStr(LScenario));
    end;
    // compare only the lines of roads and walls (R, W, r, rr), in order
    LIndex := 0;
    for LCount := 0 to LGolden.Count - 1 do
      if LGolden[LCount].StartsWith('R ') or LGolden[LCount].StartsWith('W ') or LGolden[LCount].StartsWith('r ') or
        LGolden[LCount].StartsWith('rr ') then
      begin
        while LActual[LIndex].StartsWith('~') do
          Inc(LIndex);
        Assert.AreEqual(LGolden[LCount], LActual[LIndex], 'riga ' + IntToStr(LCount));
        Inc(LIndex);
      end;
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestWarAutotile.DovrebbeDareLeStesseRovineEAlberiDelCodiceOriginale;
var
  LGolden: TStringList;
  LActual: TStringList;
  LScenario: Integer;
  LRoad: TWarLine;
  LWall: TWarLine;
  LRuins: TWarRuins;
  LForest: TWarForest;
  LCount: Integer;
  LIndex: Integer;
  LBefore: Integer;
  LBytes: TBytes;
  LX: Integer;
  LY: Integer;
  LDimension: Integer;
  LTrees: TArray<TWarTree>;
  LRuinPieces: TArray<TWarRuinPiece>;
  LTree: TWarTree;
  LAmount: Integer;
  LLine: string;
begin
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('autotile.golden.txt'));
    for LScenario := 0 to 119 do
    begin
      // the generator is the one of the harness: the same draws in the same order, roads and walls first
      FState := 5000 + Cardinal(LScenario);
      LRoad := TWarLine.CreateRoad;
      LWall := TWarLine.CreateWall;
      try
        LCount := 1 + Range(4);
        for LIndex := 0 to LCount - 1 do
        begin
          LRoad.AddFromConstruct(Construct(wctRoad));
          LWall.AddFromConstruct(Construct(wctWall));
        end;
      finally
        LWall.Free;
        LRoad.Free;
      end;
      LRuins := TWarRuins.Create;
      LForest := TWarForest.Create;
      try
        LCount := 1 + Range(4);
        for LIndex := 0 to LCount - 1 do
        begin
          LX := Range(66);
          LY := Range(66);
          LDimension := 1 + Range(5);
          LRuins.AddSquare(LX, LY, LDimension);
        end;
        LBefore := LRuins.Count;
        LRuins.DetermineTypes;
        LRuinPieces := LRuins.Pieces;
        SetLength(LBytes, Length(LRuinPieces) * 3);
        for LIndex := 0 to High(LRuinPieces) do
        begin
          LBytes[LIndex * 3] := LRuinPieces[LIndex].PieceType;
          LBytes[LIndex * 3 + 1] := Byte(LRuinPieces[LIndex].TileX);
          LBytes[LIndex * 3 + 2] := Byte(LRuinPieces[LIndex].TileY);
        end;
        LActual.Add(Format('U %d %d %d %s', [LScenario, LBefore, LRuins.Count, Checksum(LBytes)]));

        LCount := 5 + Range(120);
        for LIndex := 0 to LCount - 1 do
        begin
          LX := Range(66) - 1;
          LY := Range(66) - 1;
          LAmount := Range(4);
          LTree := Tree(LX, LY, LAmount, 0);
          if Range(8) = 0 then
            LTree.TileType := WAR_TREE_CHOPPED;
          if not LForest.HasTreeAt(LTree.TileX, LTree.TileY) then
            LForest.AddTree(LTree);
        end;
        LBefore := LForest.Count;
        LForest.DetermineTiles;
        LTrees := LForest.Trees;
        SetLength(LBytes, Length(LTrees) * 4);
        for LIndex := 0 to High(LTrees) do
        begin
          LBytes[LIndex * 4] := LTrees[LIndex].TileType;
          LBytes[LIndex * 4 + 1] := Byte(LTrees[LIndex].TileX);
          LBytes[LIndex * 4 + 2] := Byte(LTrees[LIndex].TileY);
          LBytes[LIndex * 4 + 3] := Byte(LTrees[LIndex].Amount);
        end;
        LActual.Add(Format('T %d %d %d %s', [LScenario, LBefore, LForest.Count, Checksum(LBytes)]));
        if LForest.Count > 0 then
          LActual.Add(Format('v %d %d', [LScenario, Ord(LForest.IsValidTree(LTrees[0]))]));
      finally
        LForest.Free;
        LRuins.Free;
      end;
    end;
    LIndex := 0;
    for LLine in LGolden do
      if LLine.StartsWith('U ') or LLine.StartsWith('T ') or LLine.StartsWith('v ') then
      begin
        Assert.AreEqual(LLine, LActual[LIndex], 'riga ' + IntToStr(LIndex));
        Inc(LIndex);
      end;
    Assert.AreEqual(LActual.Count, LIndex);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

end.
