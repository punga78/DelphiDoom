{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the collision library - the Quake III collision model: }
{  parity with the C code                                                      }
{                                                                              }
{  Tests\Data\Collision\q3cm.golden.txt is the output of Tools\Verifica\118,   }
{  that is the real cm_load.c, cm_test.c and cm_trace.c of Quake III compiled  }
{  with gcc, on the two synthetic BSPs q3world0.bsp and q3world1.bsp. Each     }
{  line is a query and the answer of the C code; the test loads the same BSP,  }
{  asks the same and compares token by token. Floats are compared as bits:     }
{  exactly at 64 bit (SSE, like the C), up to 4 ULP at 32 bit (x87 keeps       }
{  intermediate results in extended precision).                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Q3Parity;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Collision.Q3.Intf, DelphiDoom.Collision.Q3.ClipMap;

type
  [TestFixture]
  [Category('Collision')]
  TTestQ3Parity = class
  strict private
    FModel: IQ3CollisionModel;
    FMap: TQ3ClipMap;
    FLines: Integer;
    FMismatches: TStringList;
    FTolerance: Integer;
    FLineTolerance: Integer;
    FAdjustCount: Integer;
    FMismatchCount: Integer;
    function DataPath(const AFileName: string): string;
    function Hex(const AToken: string): Cardinal;
    function FloatAt(const AWords: TArray<string>; const AIndex: Integer): Single;
    function VecAt(const AWords: TArray<string>; const AIndex: Integer): TQ3Vec3;
    function IntToToken(const AValue: Integer): string;
    function FloatToken(const AValue: Single): string;
    function TraceAnswer(const ATrace: TQ3Trace): TArray<string>;
    function ListHash(const AValues: TArray<Integer>): Cardinal;
    function Hash(const AHash: Cardinal; const AValue: Cardinal): Cardinal;
    function UlpDistance(const AFirst, ASecond: Cardinal): Int64;
    function SameToken(const AExpected, AActual: string; const AFloat: Boolean): Boolean;
    function Answer(const AWords: TArray<string>): TArray<string>;
    procedure CheckLoad(const AWords: TArray<string>; const AExpected: string);
    procedure CheckHash(const AWords: TArray<string>);
    procedure CheckLine(const ALine: string);
    procedure RunBsp(const AName: string; const ALines: TStringList; const AFirst, ALast: Integer);
  public
    [Test]
    procedure DovrebbeDareLeStesseRispostePerOgniInterrogazioneDelC;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Collision.Q3.Loader,
  DelphiDoom.Collision.Q3.Model, DelphiDoom.Tests.Collision.Q3Support;

const
  TOKEN_BAR = '|';

function TTestQ3Parity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Collision\' + AFileName);
end;

function TTestQ3Parity.Hex(const AToken: string): Cardinal;
begin
  Result := Cardinal(StrToInt64('$' + AToken));
end;

function TTestQ3Parity.FloatAt(const AWords: TArray<string>; const AIndex: Integer): Single;
begin
  Result := FloatOfBits(Hex(AWords[AIndex]));
end;

function TTestQ3Parity.VecAt(const AWords: TArray<string>; const AIndex: Integer): TQ3Vec3;
begin
  Result[0] := FloatAt(AWords, AIndex);
  Result[1] := FloatAt(AWords, AIndex + 1);
  Result[2] := FloatAt(AWords, AIndex + 2);
end;

function TTestQ3Parity.IntToToken(const AValue: Integer): string;
begin
  Result := IntToStr(AValue);
end;

function TTestQ3Parity.FloatToken(const AValue: Single): string;
begin
  Result := FloatBitsHex(AValue);
end;

function TTestQ3Parity.Hash(const AHash: Cardinal; const AValue: Cardinal): Cardinal;
var
  LIndex: Integer;
begin
  Result := AHash;
  for LIndex := 0 to 3 do
    Result := (Result xor ((AValue shr (LIndex * 8)) and 255)) * 16777619;
end;

function TTestQ3Parity.ListHash(const AValues: TArray<Integer>): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 0 to High(AValues) do
    Result := Hash(Result, Cardinal(AValues[LIndex]));
end;

function TTestQ3Parity.UlpDistance(const AFirst, ASecond: Cardinal): Int64;
  function Ordered(const ABits: Cardinal): Int64;
  begin
    if (ABits and $80000000) <> 0 then
      Result := -Int64(ABits and $7FFFFFFF)
    else
      Result := ABits;
  end;
begin
  Result := Abs(Ordered(AFirst) - Ordered(ASecond));
end;

function TTestQ3Parity.SameToken(const AExpected, AActual: string; const AFloat: Boolean): Boolean;
begin
  if AExpected = AActual then
    Exit(True);
  if not AFloat then
    Exit(False);
  Result := UlpDistance(Hex(AExpected), Hex(AActual)) <= FLineTolerance;
end;

function TTestQ3Parity.TraceAnswer(const ATrace: TQ3Trace): TArray<string>;
begin
  Result := [IntToToken(Ord(ATrace.AllSolid)), IntToToken(Ord(ATrace.StartSolid)), FloatToken(ATrace.Fraction),
    FloatToken(ATrace.EndPos[0]), FloatToken(ATrace.EndPos[1]), FloatToken(ATrace.EndPos[2]),
    FloatToken(ATrace.Plane.Normal[0]), FloatToken(ATrace.Plane.Normal[1]), FloatToken(ATrace.Plane.Normal[2]),
    FloatToken(ATrace.Plane.Dist), IntToToken(ATrace.Plane.PlaneType), IntToToken(ATrace.Plane.SignBits),
    IntToToken(ATrace.SurfaceFlags), IntToToken(ATrace.Contents)];
end;

procedure TTestQ3Parity.CheckLoad(const AWords: TArray<string>; const AExpected: string);
var
  LActual: string;
  LPatches, LIndex: Integer;
begin
  LPatches := 0;
  for LIndex := 0 to FMap.NumSurfaces - 1 do
    if FMap.Patches[LIndex].Present then
      Inc(LPatches);
  LActual := Format('load %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d',
    [FMap.NumShaders, FMap.NumPlanes, FMap.NumNodes, FMap.NumLeafs, FMap.NumLeafBrushes, FMap.NumLeafSurfaces,
    FMap.NumSubModels, FMap.NumBrushes, FMap.NumBrushSides, FMap.NumClusters, FMap.ClusterBytes, Ord(FMap.Vised),
    FMap.NumAreas, FMap.NumEntityChars, FMap.NumSurfaces, LPatches]);
  Assert.AreEqual(AExpected, LActual, 'load');
end;

procedure TTestQ3Parity.CheckHash(const AWords: TArray<string>);
var
  LHash: Cardinal;
  LIndex, LK: Integer;
  LKind: string;
  LBytes: TBytes;
begin
  LKind := AWords[1];
  LHash := 2166136261;
  if LKind = 'planes' then
    for LIndex := 0 to FMap.NumPlanes - 1 do
    begin
      LHash := Hash(LHash, BitsOfFloat(FMap.Planes[LIndex].Normal[0]));
      LHash := Hash(LHash, BitsOfFloat(FMap.Planes[LIndex].Normal[1]));
      LHash := Hash(LHash, BitsOfFloat(FMap.Planes[LIndex].Normal[2]));
      LHash := Hash(LHash, BitsOfFloat(FMap.Planes[LIndex].Dist));
      LHash := Hash(LHash, FMap.Planes[LIndex].PlaneType);
      LHash := Hash(LHash, FMap.Planes[LIndex].SignBits);
    end
  else if LKind = 'brushes' then
  begin
    for LIndex := 0 to FMap.NumBrushes - 1 do
    begin
      LHash := Hash(LHash, Cardinal(FMap.Brushes[LIndex].ShaderNum));
      LHash := Hash(LHash, Cardinal(FMap.Brushes[LIndex].Contents));
      LHash := Hash(LHash, Cardinal(FMap.Brushes[LIndex].NumSides));
      LHash := Hash(LHash, Cardinal(FMap.Brushes[LIndex].FirstSide));
      for LK := 0 to 2 do
      begin
        LHash := Hash(LHash, BitsOfFloat(FMap.Brushes[LIndex].Bounds[0][LK]));
        LHash := Hash(LHash, BitsOfFloat(FMap.Brushes[LIndex].Bounds[1][LK]));
      end;
    end;
    for LIndex := 0 to FMap.NumBrushSides - 1 do
    begin
      LHash := Hash(LHash, Cardinal(FMap.BrushSides[LIndex].PlaneNum));
      LHash := Hash(LHash, Cardinal(FMap.BrushSides[LIndex].SurfaceFlags));
      LHash := Hash(LHash, Cardinal(FMap.BrushSides[LIndex].ShaderNum));
    end;
  end
  else if LKind = 'leafs' then
  begin
    for LIndex := 0 to FMap.NumLeafs - 1 do
    begin
      LHash := Hash(LHash, Cardinal(FMap.Leafs[LIndex].Cluster));
      LHash := Hash(LHash, Cardinal(FMap.Leafs[LIndex].Area));
      LHash := Hash(LHash, Cardinal(FMap.Leafs[LIndex].FirstLeafBrush));
      LHash := Hash(LHash, Cardinal(FMap.Leafs[LIndex].NumLeafBrushes));
      LHash := Hash(LHash, Cardinal(FMap.Leafs[LIndex].FirstLeafSurface));
      LHash := Hash(LHash, Cardinal(FMap.Leafs[LIndex].NumLeafSurfaces));
    end;
    for LIndex := 0 to FMap.NumLeafBrushes - 1 do
      LHash := Hash(LHash, Cardinal(FMap.LeafBrushes[LIndex]));
    for LIndex := 0 to FMap.NumLeafSurfaces - 1 do
      LHash := Hash(LHash, Cardinal(FMap.LeafSurfaces[LIndex]));
  end
  else if LKind = 'nodes' then
    for LIndex := 0 to FMap.NumNodes - 1 do
    begin
      LHash := Hash(LHash, Cardinal(FMap.Nodes[LIndex].PlaneNum));
      LHash := Hash(LHash, Cardinal(FMap.Nodes[LIndex].Children[0]));
      LHash := Hash(LHash, Cardinal(FMap.Nodes[LIndex].Children[1]));
    end
  else if LKind = 'models' then
    for LIndex := 0 to FMap.NumSubModels - 1 do
    begin
      for LK := 0 to 2 do
      begin
        LHash := Hash(LHash, BitsOfFloat(FMap.Models[LIndex].Mins[LK]));
        LHash := Hash(LHash, BitsOfFloat(FMap.Models[LIndex].Maxs[LK]));
      end;
      LHash := Hash(LHash, Cardinal(FMap.Models[LIndex].Leaf.NumLeafBrushes));
      LHash := Hash(LHash, Cardinal(FMap.Models[LIndex].Leaf.NumLeafSurfaces));
      if LIndex > 0 then
      begin
        for LK := 0 to FMap.Models[LIndex].Leaf.NumLeafBrushes - 1 do
          LHash := Hash(LHash, Cardinal(FMap.LeafBrushes[FMap.Models[LIndex].Leaf.FirstLeafBrush + LK]));
        for LK := 0 to FMap.Models[LIndex].Leaf.NumLeafSurfaces - 1 do
          LHash := Hash(LHash, Cardinal(FMap.LeafSurfaces[FMap.Models[LIndex].Leaf.FirstLeafSurface + LK]));
      end;
    end
  else if LKind = 'vis' then
  begin
    if FMap.Vised then
      LK := FMap.ClusterBytes * FMap.NumClusters
    else
      LK := FMap.ClusterBytes;
    for LIndex := 0 to LK - 1 do
      LHash := Hash(LHash, FMap.Visibility[LIndex]);
  end
  else if LKind = 'areas' then
    for LIndex := 0 to FMap.NumAreas - 1 do
      LHash := Hash(LHash, Cardinal(FMap.Areas[LIndex].FloodNum))
  else if LKind = 'entities' then
  begin
    // the original copies the whole lump (the string, its NUL)
    LBytes := TEncoding.ANSI.GetBytes(string(FMap.EntityString));
    for LIndex := 0 to FMap.NumEntityChars - 1 do
      if LIndex < Length(LBytes) then
        LHash := Hash(LHash, LBytes[LIndex])
      else
        LHash := Hash(LHash, 0);
  end
  else
    Assert.Fail('unknown hash ' + LKind);
  Assert.AreEqual(AWords[2], IntToHex(LHash, 8).ToLower, 'hash ' + LKind);
end;

function TTestQ3Parity.Answer(const AWords: TArray<string>): TArray<string>;
var
  LCommand: string;
  LTrace: TQ3Trace;
  LLeafs: TArray<Integer>;
  LLast, LCount, LIndex, LModel: Integer;
  LMins, LMaxs: TQ3Vec3;
  LRow: TBytes;
  LBuffer: TBytes;
  LText: string;
begin
  LCommand := AWords[0];
  if LCommand = 'pointleaf' then
    Result := [IntToToken(FModel.PointLeafnum(VecAt(AWords, 1)))]
  else if LCommand = 'pointcontents' then
    Result := [IntToToken(FModel.PointContents(VecAt(AWords, 1), StrToInt(AWords[4])))]
  else if LCommand = 'tpointcontents' then
    Result := [IntToToken(FModel.TransformedPointContents(VecAt(AWords, 1), StrToInt(AWords[4]),
      VecAt(AWords, 5), VecAt(AWords, 8)))]
  else if LCommand = 'boxleafs' then
  begin
    LCount := FModel.BoxLeafnums(VecAt(AWords, 1), VecAt(AWords, 4), StrToInt(AWords[7]), LLeafs, LLast);
    Result := [IntToToken(LCount), IntToToken(LLast), IntToHex(ListHash(LLeafs), 8).ToLower];
  end
  else if LCommand = 'boxbrushes' then
  begin
    LLeafs := FModel.BoxBrushes(VecAt(AWords, 1), VecAt(AWords, 4), StrToInt(AWords[7]));
    Result := [IntToToken(Length(LLeafs)), IntToHex(ListHash(LLeafs), 8).ToLower];
  end
  else if LCommand = 'trace' then
  begin
    LTrace := FModel.BoxTrace(VecAt(AWords, 1), VecAt(AWords, 4), VecAt(AWords, 7), VecAt(AWords, 10),
      StrToInt(AWords[13]), StrToInt(AWords[14]), StrToInt(AWords[15]) <> 0);
    Result := TraceAnswer(LTrace);
  end
  else if LCommand = 'ttrace' then
  begin
    LTrace := FModel.TransformedBoxTrace(VecAt(AWords, 1), VecAt(AWords, 4), VecAt(AWords, 7),
      VecAt(AWords, 10), StrToInt(AWords[13]), StrToInt(AWords[14]), VecAt(AWords, 16), VecAt(AWords, 19),
      StrToInt(AWords[15]) <> 0);
    Result := TraceAnswer(LTrace);
  end
  else if LCommand = 'tempbox' then
    Result := [IntToToken(FModel.TempBoxModel(VecAt(AWords, 1), VecAt(AWords, 4), StrToInt(AWords[7]) <> 0))]
  else if LCommand = 'modelbounds' then
  begin
    LModel := StrToInt(AWords[1]);
    FModel.ModelBounds(LModel, LMins, LMaxs);
    Result := [FloatToken(LMins[0]), FloatToken(LMins[1]), FloatToken(LMins[2]), FloatToken(LMaxs[0]),
      FloatToken(LMaxs[1]), FloatToken(LMaxs[2])];
  end
  else if LCommand = 'inline' then
    Result := [IntToToken(FModel.InlineModel(StrToInt(AWords[1])))]
  else if LCommand = 'counts' then
    Result := [IntToToken(FModel.NumClusters), IntToToken(FModel.NumInlineModels),
      IntToToken(Length(FModel.EntityString))]
  else if LCommand = 'leaf' then
    Result := [IntToToken(FModel.LeafCluster(StrToInt(AWords[1]))), IntToToken(FModel.LeafArea(StrToInt(AWords[1])))]
  else if LCommand = 'pvs' then
  begin
    LRow := FModel.ClusterPVS(StrToInt(AWords[1]));
    SetLength(Result, 0);
    for LIndex := 0 to 3 do
      if LIndex < Length(LRow) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := IntToHex(LRow[LIndex], 2).ToLower;
      end;
  end
  else if LCommand = 'adjust' then
  begin
    FModel.AdjustAreaPortalState(StrToInt(AWords[1]), StrToInt(AWords[2]), StrToInt(AWords[3]) <> 0);
    LText := '';
    for LIndex := 0 to 2 do
      LText := LText + Format('%d%d%d ', [Ord(FModel.AreasConnected(0, LIndex)),
        Ord(FModel.AreasConnected(1, LIndex)), Ord(FModel.AreasConnected(2, LIndex))]);
    SetLength(LBuffer, 64);
    LCount := FModel.WriteAreaBits(LBuffer, FAdjustCount mod 3);
    Inc(FAdjustCount);
    Result := (LText + Format('bits %d %s', [LCount, IntToHex(LBuffer[0], 2).ToLower])).Split([' ']);
  end
  else if LCommand = 'connected' then
    Result := [IntToToken(Ord(FModel.AreasConnected(StrToInt(AWords[1]), StrToInt(AWords[2]))))]
  else if LCommand = 'bits' then
  begin
    SetLength(LBuffer, 64);
    LCount := FModel.WriteAreaBits(LBuffer, StrToInt(AWords[1]));
    Result := [IntToToken(LCount), IntToHex(LBuffer[0], 2).ToLower];
  end
  else if LCommand = 'noareas' then
  begin
    FModel.NoAreas := True;
    SetLength(LBuffer, 64);
    LCount := FModel.WriteAreaBits(LBuffer, 1);
    Result := [IntToToken(Ord(FModel.AreasConnected(0, 2))), IntToToken(LCount), IntToHex(LBuffer[0], 2).ToLower];
    FModel.NoAreas := False;
  end
  else
  begin
    Assert.Fail('unknown query ' + LCommand);
    Result := nil;
  end;
end;

procedure TTestQ3Parity.CheckLine(const ALine: string);
var
  LBar: Integer;
  LWords, LExpected, LActual: TArray<string>;
  LIndex, LFirstFloat, LLastFloat: Integer;
  LOk: Boolean;
begin
  LBar := Pos(TOKEN_BAR, ALine);
  if LBar = 0 then
  begin
    LWords := ALine.Split([' ']);
    if LWords[0] = 'load' then
      CheckLoad(LWords, ALine)
    else if LWords[0] = 'hash' then
      CheckHash(LWords)
    else if LWords[0] = 'areas' then
    begin
      FAdjustCount := 0;
      Assert.AreEqual(StrToInt(LWords[1]), FModel.NumAreas, 'areas');
    end
    else
      Assert.Fail('unknown line ' + ALine);
    Exit;
  end;

  LWords := Trim(Copy(ALine, 1, LBar - 1)).Split([' ']);
  LExpected := Trim(Copy(ALine, LBar + 1, MaxInt)).Split([' ']);
  LActual := Answer(LWords);
  Inc(FLines);
  // at 32 bit the x87 sin and cos of the rotation differ from the C library in the last bits of a
  // double, and a rotated trace amplifies them (seen: 7 ULP); the other queries stay at 4 ULP
  if LWords[0] = 'ttrace' then
    FLineTolerance := FTolerance * 4
  else
    FLineTolerance := FTolerance;

  // the tokens of the answer that are floats
  LFirstFloat := MaxInt;
  LLastFloat := -1;
  if (LWords[0] = 'trace') or (LWords[0] = 'ttrace') then
  begin
    LFirstFloat := 2;
    LLastFloat := 9;
  end
  else if LWords[0] = 'modelbounds' then
  begin
    LFirstFloat := 0;
    LLastFloat := 5;
  end;

  LOk := Length(LExpected) = Length(LActual);
  if LOk then
    for LIndex := 0 to High(LExpected) do
      if not SameToken(LExpected[LIndex], LActual[LIndex], (LIndex >= LFirstFloat) and (LIndex <= LLastFloat)) then
        LOk := False;
  if not LOk then
  begin
    if FMismatches.Count < 8 then
      FMismatches.Add(Format('%s'#13#10'  C:      %s'#13#10'  Pascal: %s', [Trim(Copy(ALine, 1, LBar - 1)),
        string.Join(' ', LExpected), string.Join(' ', LActual)]));
    Inc(FMismatchCount);
  end;
end;

procedure TTestQ3Parity.RunBsp(const AName: string; const ALines: TStringList; const AFirst, ALast: Integer);
var
  LReader: IBspReader;
  LFile: IBspFile;
  LLoader: TQ3ClipMapLoader;
  LIndex: Integer;
begin
  LReader := TBspFactory.CreateReader;
  LFile := LReader.ParseBytes(TFile.ReadAllBytes(DataPath(AName)), AnsiString(AName));
  LLoader := TQ3ClipMapLoader.Create(TBspFactory.CreateValidator, nil);
  try
    FMap := LLoader.Load(LFile, AnsiString(AName));
  finally
    LLoader.Free;
  end;
  // the model owns the map; FMap stays valid as long as FModel does
  FModel := TQ3CollisionModel.Create(FMap);
  for LIndex := AFirst to ALast do
    CheckLine(ALines[LIndex]);
  FModel := nil;
  FMap := nil;
end;

procedure TTestQ3Parity.DovrebbeDareLeStesseRispostePerOgniInterrogazioneDelC;
var
  LGolden: TStringList;
  LStarts: TList<Integer>;
  LIndex: Integer;
begin
  Assert.IsTrue(TFile.Exists(DataPath('q3cm.golden.txt')), 'dati di parita'' non trovati: ' + DataPath('q3cm.golden.txt'));
  FMismatches := TStringList.Create;
  LGolden := TStringList.Create;
  LStarts := TList<Integer>.Create;
  try
    {$IFDEF CPUX64}
    FTolerance := 0;
    {$ELSE}
    FTolerance := 4;
    {$ENDIF}
    FMismatchCount := 0;
    LGolden.LoadFromFile(DataPath('q3cm.golden.txt'));
    for LIndex := 0 to LGolden.Count - 1 do
      if Copy(LGolden[LIndex], 1, 4) = 'bsp ' then
        LStarts.Add(LIndex);
    Assert.AreEqual(2, LStarts.Count, 'bsp sections');
    LStarts.Add(LGolden.Count);
    for LIndex := 0 to LStarts.Count - 2 do
      RunBsp(Copy(LGolden[LStarts[LIndex]], 5, MaxInt), LGolden, LStarts[LIndex] + 1, LStarts[LIndex + 1] - 1);
    Assert.IsTrue(FLines > 2000, 'queries run: ' + IntToStr(FLines));
    Assert.AreEqual(0, FMismatchCount, IntToStr(FMismatchCount) + ' of ' + IntToStr(FLines) + ' queries differ:'#13#10 +
      FMismatches.Text);
  finally
    LStarts.Free;
    LGolden.Free;
    FMismatches.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3Parity);

end.
