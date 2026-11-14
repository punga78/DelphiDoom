{******************************************************************************}
{                                                                              }
{  DelphiDoom: the Quake III collision model on the real maps of OpenArena     }
{  (issue #118)                                                                }
{                                                                              }
{  Every .bsp of pak1-maps.pk3, pak6-patch085.pk3 and pak6-patch088.pk3 is     }
{  loaded with the patch collision (DELPHIDOOM_OPENARENA = the baseoa folder  }
{  or a pk3 in it, or Reference\openarena\openarena-0.8.8\baseoa; the tests    }
{  are ignored when there is none, nothing of OpenArena is in the repository). }
{                                                                              }
{  1. coherence: traces from fixed seeds give a fraction in 0..1, a hit has a  }
{     unit normal, a trace that starts in the open is not all solid;           }
{  2. parity: Tests\Data\Collision\OpenArena\<map>.golden.txt (local, ignored  }
{     by git; Tools\Verifica\118\Make-OpenArena-Golden.ps1) has the answers of }
{     the real C code on the same maps: the counts of the loaded data, a hash  }
{     of the collision geometry of every patch (bounds, planes, facets) and    }
{     300 traces and position tests; the model gives the same answers.         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Q3OpenArena;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('collision')]
  [Category('openarena')]
  TTestQ3OpenArena = class(TObject)
  private
    function BaseFolder: string;
  public
    [Test]
    procedure DovrebbeCaricareOgniMappaConLeSuePatch;
    [Test]
    procedure DovrebbeDareTracceCoerentiInOgniMappa;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelCSulleMappeVere;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Zip, System.Math, System.Generics.Collections,
  DUnitX.Exceptions, DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Collision.Q3.Types,
  DelphiDoom.Collision.Q3.Intf, DelphiDoom.Collision.Q3.Factory, DelphiDoom.Collision.Q3.ClipMap,
  DelphiDoom.Collision.Q3.Loader, DelphiDoom.Collision.Q3.Model, DelphiDoom.Collision.Q3.PatchCollide;

const
  PAKS: array[0..2] of string = ('pak1-maps.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3');
  TRACES_PER_MAP = 120;

type
  TMapVisitor = reference to procedure(const AName: string; const ABytes: TBytes);

function TTestQ3OpenArena.BaseFolder: string;
var
  LRelative: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result <> '') and TFile.Exists(Result) then
    Result := TPath.GetDirectoryName(Result);
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  LRelative := '..\..\..\..\Reference\openarena\openarena-0.8.8\baseoa';
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), LRelative));
  if not TDirectory.Exists(Result) then
    raise ETestIgnored.Create('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena): prova ignorata');
end;

procedure VisitMaps(const AFolder: string; const AVisit: TMapVisitor);
var
  LPak, LName: string;
  LZip: TZipFile;
  LBytes: TBytes;
  LCount: Integer;
begin
  LCount := 0;
  for LPak in PAKS do
  begin
    if not TFile.Exists(TPath.Combine(AFolder, LPak)) then
      Continue;
    LZip := TZipFile.Create;
    try
      LZip.Open(TPath.Combine(AFolder, LPak), zmRead);
      for LName in LZip.FileNames do
        if LName.EndsWith('.bsp', True) then
        begin
          LZip.Read(LName, LBytes);
          AVisit(LName, LBytes);
          Inc(LCount);
        end;
    finally
      LZip.Free;
    end;
  end;
  if LCount = 0 then
    raise ETestIgnored.Create('nessuna mappa nei pk3 di OpenArena: prova ignorata');
end;

/// <summary>The bytes of maps/NAME.bsp: the patches replace the maps of the first pak, so they are read first</summary>
function FindMap(const AFolder, AName: string; out ABytes: TBytes): Boolean;
const
  ORDER: array[0..2] of string = ('pak6-patch088.pk3', 'pak6-patch085.pk3', 'pak1-maps.pk3');
var
  LPak: string;
  LZip: TZipFile;
  LName: string;
begin
  for LPak in ORDER do
  begin
    if not TFile.Exists(TPath.Combine(AFolder, LPak)) then
      Continue;
    LZip := TZipFile.Create;
    try
      LZip.Open(TPath.Combine(AFolder, LPak), zmRead);
      for LName in LZip.FileNames do
        if SameText(LName, 'maps/' + AName + '.bsp') then
        begin
          LZip.Read(LName, ABytes);
          Exit(True);
        end;
    finally
      LZip.Free;
    end;
  end;
  Result := False;
end;

function RandomFraction(var AState: Cardinal): Single;
begin
  AState := AState * 1664525 + 1013904223;
  Result := (AState shr 8) / 16777216.0;
end;

function BitsOf(AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

function HexOf(AValue: Single): string;
begin
  Result := LowerCase(IntToHex(BitsOf(AValue), 8));
end;

function FnvStep(AHash, AValue: Cardinal): Cardinal;
var
  LIndex: Integer;
begin
  Result := AHash;
  for LIndex := 0 to 3 do
    Result := (Result xor ((AValue shr (LIndex * 8)) and 255)) * 16777619;
end;

function UlpDistance(AFirst, ASecond: Cardinal): Int64;

  function Ordered(ABits: Cardinal): Int64;
  begin
    if (ABits and $80000000) <> 0 then
      Result := -Int64(ABits and $7FFFFFFF)
    else
      Result := ABits;
  end;

begin
  Result := Abs(Ordered(AFirst) - Ordered(ASecond));
end;

function BitsToSingle(const AText: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + AText));
  Result := PSingle(@LBits)^;
end;

/// <summary>The hash that the C harness (cmgen runmap) writes for the collision geometry of a patch</summary>
function PatchHash(ACollide: TQ3PatchCollide): Cardinal;
var
  LJ, LN: Integer;
  LFacet: TQ3Facet;
begin
  Result := 2166136261;
  for LJ := 0 to 2 do
  begin
    Result := FnvStep(Result, BitsOf(ACollide.Bounds(0)[LJ]));
    Result := FnvStep(Result, BitsOf(ACollide.Bounds(1)[LJ]));
  end;
  for LJ := 0 to ACollide.NumPlanes - 1 do
  begin
    for LN := 0 to 3 do
      Result := FnvStep(Result, BitsOf(ACollide.Plane(LJ).Plane[LN]));
    Result := FnvStep(Result, Cardinal(ACollide.Plane(LJ).SignBits));
  end;
  for LJ := 0 to ACollide.NumFacets - 1 do
  begin
    LFacet := ACollide.Facet(LJ);
    Result := FnvStep(Result, Cardinal(LFacet.SurfacePlane));
    Result := FnvStep(Result, Cardinal(LFacet.NumBorders));
    for LN := 0 to LFacet.NumBorders - 1 do
    begin
      Result := FnvStep(Result, Cardinal(LFacet.BorderPlanes[LN]));
      Result := FnvStep(Result, Cardinal(LFacet.BorderInward[LN]));
      Result := FnvStep(Result, Cardinal(LFacet.BorderNoAdjust[LN]));
    end;
  end;
end;

procedure TTestQ3OpenArena.DovrebbeCaricareOgniMappaConLeSuePatch;
begin
  VisitMaps(BaseFolder,
    procedure(const AName: string; const ABytes: TBytes)
    var
      LModel: IQ3CollisionModel;
    begin
      LModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, ABytes, AnsiString(AName),
        TQ3CollisionFactory.CreatePatchBuilder);
      Assert.IsTrue(LModel.NumInlineModels >= 1, AName + ': no model');
    end);
end;

procedure TTestQ3OpenArena.DovrebbeDareTracceCoerentiInOgniMappa;
begin
  VisitMaps(BaseFolder,
    procedure(const AName: string; const ABytes: TBytes)
    var
      LModel: IQ3CollisionModel;
      LMins, LMaxs: TQ3Vec3;
      LState: Cardinal;
      LRun, LAxis: Integer;
      LStart, LEnd, LBoxMins, LBoxMaxs: TQ3Vec3;
      LTrace, LStuck: TQ3Trace;
      LCapsule: Boolean;
      LLength: Single;
      LCleanStarts: Integer;
    begin
      LModel := TQ3CollisionFactory.CreateFromBytes(TBspFactory.CreateReader, ABytes, AnsiString(AName),
        TQ3CollisionFactory.CreatePatchBuilder);
      LModel.ModelBounds(0, LMins, LMaxs);
      LState := Cardinal(Length(AName)) * 2654435761;
      LCleanStarts := 0;
      for LRun := 1 to TRACES_PER_MAP do
      begin
        for LAxis := 0 to 2 do
        begin
          LStart[LAxis] := LMins[LAxis] + RandomFraction(LState) * (LMaxs[LAxis] - LMins[LAxis]);
          LLength := 20 + RandomFraction(LState) * 600;
          LEnd[LAxis] := LStart[LAxis] + (RandomFraction(LState) - 0.5) * 2 * LLength;
        end;
        // a point, or a box or capsule of the size of a player
        LCapsule := RandomFraction(LState) < 0.3;
        if RandomFraction(LState) < 0.3 then
        begin
          LBoxMins[0] := 0; LBoxMins[1] := 0; LBoxMins[2] := 0;
          LBoxMaxs := LBoxMins;
        end
        else
        begin
          LBoxMins[0] := -15; LBoxMins[1] := -15; LBoxMins[2] := -24;
          LBoxMaxs[0] := 15; LBoxMaxs[1] := 15; LBoxMaxs[2] := 32;
        end;

        // a start that is stuck in a solid says so when it does not move
        LStuck := LModel.BoxTrace(LStart, LStart, LBoxMins, LBoxMaxs, 0, Q3_CONTENTS_SOLID, LCapsule);
        Assert.IsTrue(LStuck.Fraction >= 0, AName + ': position test fraction');
        if LStuck.StartSolid then
          Continue;
        Inc(LCleanStarts);

        LTrace := LModel.BoxTrace(LStart, LEnd, LBoxMins, LBoxMaxs, 0, Q3_CONTENTS_SOLID, LCapsule);
        Assert.IsTrue((LTrace.Fraction >= 0) and (LTrace.Fraction <= 1), AName + ': fraction ' +
          FloatToStr(LTrace.Fraction));
        Assert.IsFalse(LTrace.AllSolid, AName + ': all solid from a clean start');
        if LTrace.Fraction < 1 then
          Assert.IsTrue(Abs(Sqrt(LTrace.Plane.Normal[0] * LTrace.Plane.Normal[0] +
            LTrace.Plane.Normal[1] * LTrace.Plane.Normal[1] + LTrace.Plane.Normal[2] * LTrace.Plane.Normal[2]) - 1) <
            0.01, AName + ': normal of a hit is not a unit vector');
        // Note: the end of a trace can be inside a solid for the C code too (the box is kept away from a
        // surface by an epsilon that a bevel or a patch facet does not always respect); the parity test
        // below compares the model with the C code on those cases
      end;
      Assert.IsTrue(LCleanStarts > 0, AName + ': no start outside the solids');
    end);
end;

procedure TTestQ3OpenArena.DovrebbeDareLeStesseRisposteDelCSulleMappeVere;
var
  LFolder: string;
  LGoldenFolder: string;
  LGolden: string;
  LLines: TStringList;
  LBytes: TBytes;
  LModel: IQ3CollisionModel;
  LMap: TQ3ClipMap;
  LLoader: TQ3ClipMapLoader;
  LFile: IBspFile;
  LLine: string;
  LWords: TArray<string>;
  LExpected: TArray<string>;
  LActual: TArray<string>;
  LBar, LIndex, LMaps, LTraces, LTraceDiffs, LPatches, LPatchDiffs: Integer;
  LTrace: TQ3Trace;
  LTolerance: Integer;
  LOk: Boolean;
  LFirstDiff: string;
  LCollide: TQ3PatchCollide;
  LPatchCount: Integer;
  LText: string;

  function ReadVec(AFrom: Integer): TQ3Vec3;
  begin
    Result[0] := BitsToSingle(LWords[AFrom]);
    Result[1] := BitsToSingle(LWords[AFrom + 1]);
    Result[2] := BitsToSingle(LWords[AFrom + 2]);
  end;

begin
  LFolder := BaseFolder;
  LGoldenFolder := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Collision\OpenArena');
  if (not TDirectory.Exists(LGoldenFolder)) or (Length(TDirectory.GetFiles(LGoldenFolder, '*.golden.txt')) = 0) then
    raise ETestIgnored.Create('nessuna risposta del C (Tools\Verifica\118\Make-OpenArena-Golden.ps1): prova ignorata');
  {$IFDEF CPUX64}
  LTolerance := 0;
  {$ELSE}
  LTolerance := 4;
  {$ENDIF}
  LMaps := 0;
  LTraces := 0;
  LTraceDiffs := 0;
  LPatches := 0;
  LPatchDiffs := 0;
  LFirstDiff := '';
  for LGolden in TDirectory.GetFiles(LGoldenFolder, '*.golden.txt') do
  begin
    LText := ExtractFileName(LGolden);
    LText := Copy(LText, 1, Length(LText) - Length('.golden.txt'));
    if not FindMap(LFolder, LText, LBytes) then
      Continue;
    LFile := TBspFactory.CreateReader.ParseBytes(LBytes, AnsiString(LText));
    LLoader := TQ3ClipMapLoader.Create(TBspFactory.CreateValidator, TQ3CollisionFactory.CreatePatchBuilder);
    try
      LMap := LLoader.Load(LFile, AnsiString(LText));
    finally
      LLoader.Free;
    end;
    LModel := TQ3CollisionModel.Create(LMap);
    Inc(LMaps);
    LLines := TStringList.Create;
    try
      LLines.LoadFromFile(LGolden);
      for LLine in LLines do
      begin
        LBar := Pos('|', LLine);
        if LBar = 0 then
        begin
          // load: the counts
          LWords := LLine.Split([' ']);
          if (Length(LWords) > 0) and (LWords[0] = 'load') then
          begin
            LPatchCount := 0;
            for LIndex := 0 to LMap.NumSurfaces - 1 do
              if LMap.Patches[LIndex].Present then
                Inc(LPatchCount);
            LText := Format('load %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d',
              [LMap.NumShaders, LMap.NumPlanes, LMap.NumNodes, LMap.NumLeafs, LMap.NumLeafBrushes, LMap.NumLeafSurfaces,
              LMap.NumSubModels, LMap.NumBrushes, LMap.NumBrushSides, LMap.NumClusters, LMap.ClusterBytes,
              Ord(LMap.Vised), LMap.NumAreas, LMap.NumEntityChars, LMap.NumSurfaces, LPatchCount]);
            if LText <> LLine then
              Assert.Fail(ExtractFileName(LGolden) + ': ' + LText + ' <> ' + LLine);
          end;
          Continue;
        end;
        LWords := Trim(Copy(LLine, 1, LBar - 1)).Split([' ']);
        LExpected := Trim(Copy(LLine, LBar + 1, MaxInt)).Split([' ']);
        if LWords[0] = 'patchhash' then
        begin
          Inc(LPatches);
          LCollide := LMap.PatchCollides[StrToInt(LWords[1])] as TQ3PatchCollide;
          LText := Format('%d %d %s', [LCollide.NumPlanes, LCollide.NumFacets,
            LowerCase(IntToHex(PatchHash(LCollide), 8))]);
          if LText <> string.Join(' ', LExpected) then
          begin
            Inc(LPatchDiffs);
            if LFirstDiff = '' then
              LFirstDiff := Format('%s patch %s: C %s Delphi %s', [ExtractFileName(LGolden), LWords[1],
                string.Join(' ', LExpected), LText]);
          end;
        end
        else if LWords[0] = 'trace' then
        begin
          Inc(LTraces);
          LTrace := LModel.BoxTrace(ReadVec(1), ReadVec(4), ReadVec(7), ReadVec(10), StrToInt(LWords[13]),
            StrToInt(LWords[14]), StrToInt(LWords[15]) <> 0);
          LActual := [IntToStr(Ord(LTrace.AllSolid)), IntToStr(Ord(LTrace.StartSolid)), HexOf(LTrace.Fraction),
            HexOf(LTrace.EndPos[0]), HexOf(LTrace.EndPos[1]), HexOf(LTrace.EndPos[2]),
            HexOf(LTrace.Plane.Normal[0]), HexOf(LTrace.Plane.Normal[1]), HexOf(LTrace.Plane.Normal[2]),
            HexOf(LTrace.Plane.Dist), IntToStr(LTrace.Plane.PlaneType), IntToStr(LTrace.Plane.SignBits),
            IntToStr(LTrace.SurfaceFlags), IntToStr(LTrace.Contents)];
          LOk := Length(LActual) = Length(LExpected);
          if LOk then
            for LIndex := 0 to High(LExpected) do
              if (LIndex >= 2) and (LIndex <= 9) then
              begin
                if UlpDistance(Cardinal(StrToInt64('$' + LExpected[LIndex])),
                  Cardinal(StrToInt64('$' + LActual[LIndex]))) > LTolerance then
                  LOk := False;
              end
              else if LExpected[LIndex] <> LActual[LIndex] then
                LOk := False;
          if not LOk then
          begin
            Inc(LTraceDiffs);
            if LFirstDiff = '' then
              LFirstDiff := Format('%s: %s'#13#10'  C:      %s'#13#10'  Delphi: %s', [ExtractFileName(LGolden),
                Trim(Copy(LLine, 1, LBar - 1)), string.Join(' ', LExpected), string.Join(' ', LActual)]);
          end;
        end;
      end;
    finally
      LLines.Free;
    end;
    LModel := nil;
  end;
  Assert.IsTrue(LMaps > 0, 'nessuna mappa trovata per le risposte del C');
  System.Writeln(Format('OpenArena: %d maps, %d patches (%d differ), %d traces (%d differ)', [LMaps, LPatches,
    LPatchDiffs, LTraces, LTraceDiffs]));
  Assert.AreEqual(0, LPatchDiffs + LTraceDiffs, Format('%d patches and %d traces differ from the C code, the first: %s',
    [LPatchDiffs, LTraceDiffs, LFirstDiff]));
end;

end.
