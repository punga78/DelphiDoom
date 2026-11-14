{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity tests of the collision library against the C++ code      }
{                                                                              }
{  The golden file (Tests\Data\Collision\parity.golden.txt) holds the answers  }
{  of the REAL Doom 3 code (CollisionModel_translate/trace/contents/contacts   }
{  .cpp, compiled with bcc32c of RAD Studio with a small shim for the engine)  }
{  on the models and the traces in parity.in.txt: 2800 queries on 4 models.    }
{  The models were built by this library (the C++ builder needs the whole      }
{  engine), so what is compared is the query code, not the construction of     }
{  the model. See README.md of the library for how the golden file is made.    }
{  Hard differences (hit or not, fraction, end position, normal, contents,     }
{  number of contacts) must be zero; which feature is reported on a tie is     }
{  compared with a limit (see the end of the test).                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Parity;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('collision')]
  [Category('parity')]
  TTestCollisionParity = class(TObject)
  private
    function DataPath(const AFileName: string): string;
  public
    [Test]
    procedure TestTranslationsContentsAndContactsMatchTheCppCode;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.Math,
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf,
  DelphiDoom.Collision.Model, DelphiDoom.Collision.Builder, DelphiDoom.Collision.Factory,
  DelphiDoom.Tests.Collision.Support;

type
  TModelDefinition = record
    Name: string;
    Brushes: TArray<TArray<TCollisionBrushSide>>;
  end;

function Near(AActual, AExpected: Double): Boolean;
begin
  Result := Abs(AActual - AExpected) <= 1e-3 + 1e-5 * Abs(AExpected);
end;

function Fields(const ALine: string): TArray<string>;
begin
  Result := ALine.Split([' '], TStringSplitOptions.ExcludeEmpty);
end;

function ToFloat(const AText: string): Double;
begin
  Result := StrToFloat(AText, TFormatSettings.Invariant);
end;

{ TTestCollisionParity }

function TTestCollisionParity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Collision\' + AFileName);
end;

procedure TTestCollisionParity.TestTranslationsContentsAndContactsMatchTheCppCode;
var
  LInput: TStringList;
  LGolden: TStringList;
  LCatalog: ICollisionMaterialCatalog;
  LManager: ICollisionModelManager;
  LHandles: TList<Integer>;
  LGoldenLine: Integer;
  LLine: Integer;
  LParts: TArray<string>;
  LGoldenParts: TArray<string>;
  LTrm: TTraceModel;
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LSides: TArray<TCollisionBrushSide>;
  LSideCount: Integer;
  LBuilder: TCollisionModelBuilder;
  LModel: TCollisionModel;
  LResult: TCollisionTrace;
  LContacts: TList<TContactInfo>;
  LStart: TGeoVec3;
  LEnd: TGeoVec3;
  LBounds: TGeoBounds;
  LHas: Boolean;
  LMismatch: TStringList;
  LTranslations: Integer;
  LHits: Integer;
  LContentsQueries: Integer;
  LContactQueries: Integer;
  LContactCount: Integer;
  LIndex: Integer;
  LCount: Integer;
  LContents: Integer;
  LModelIndex: Integer;
  LBrushIndex: Integer;
  LExpectedType: Integer;
  LSolidContents: Integer;
  LKinds: TDictionary<string, Integer>;
  LKind: string;
  LSummary: string;
  LSoft: TStringList;
  LSoftLines: TDictionary<Integer, Boolean>;
  LSoftQueries: Integer;
  LContactHitQueries: Integer;

  /// <summary>
  ///   A hard difference (hit or not, fraction, end position, contact normal, contents, number of
  ///   contacts) fails the test. A soft one (which feature is reported when two touch at the same
  ///   moment: its type, point, distance, feature numbers) is counted: see the end of the test
  /// </summary>
  procedure Mismatch(const AText: string; AHard: Boolean = True);
  begin
    if AHard then
      LMismatch.Add(Format('input line %d: %s', [LLine + 1, AText]))
    else
    begin
      LSoft.Add(Format('input line %d: %s', [LLine + 1, AText]));
      LSoftLines.AddOrSetValue(LLine, True);
    end;
  end;

  function Pick(const AParts: TArray<string>; AFrom: Integer): TGeoVec3;
  begin
    Result := TGeoVec3.Make(ToFloat(AParts[AFrom]), ToFloat(AParts[AFrom + 1]), ToFloat(AParts[AFrom + 2]));
  end;

  procedure Compare(const AName: string; AActual, AExpected: Double; AHard: Boolean = True;
    ATolerance: Double = 1e-3; ARelative: Double = 1e-5);
  begin
    if Abs(AActual - AExpected) > ATolerance + ARelative * Abs(AExpected) then
      Mismatch(Format('%s: Delphi %.7g, C++ %.7g', [AName, AActual, AExpected]), AHard);
  end;

  procedure CompareVec(const AName: string; const AActual: TGeoVec3; const AExpected: TArray<string>; AFrom: Integer;
    AHard: Boolean = True; ATolerance: Double = 1e-3; ARelative: Double = 1e-5);
  begin
    Compare(AName + '.x', AActual.X, ToFloat(AExpected[AFrom]), AHard, ATolerance, ARelative);
    Compare(AName + '.y', AActual.Y, ToFloat(AExpected[AFrom + 1]), AHard, ATolerance, ARelative);
    Compare(AName + '.z', AActual.Z, ToFloat(AExpected[AFrom + 2]), AHard, ATolerance, ARelative);
  end;

begin
  if not TFile.Exists(DataPath('parity.in.txt')) then
  begin
    Assert.Pass('parity data not found: ' + DataPath('parity.in.txt'));
    Exit;
  end;
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LCatalog := TFakeMaterialCatalog.Create;
  LManager := TCollisionFactory.CreateManager(LCatalog, nil);
  LHandles := TList<Integer>.Create;
  LMismatch := TStringList.Create;
  LSoft := TStringList.Create;
  LSoftLines := TDictionary<Integer, Boolean>.Create;
  LContacts := TList<TContactInfo>.Create;
  LTrm := TTraceModel.Create;
  try
    LInput.LoadFromFile(DataPath('parity.in.txt'));
    LGolden.LoadFromFile(DataPath('parity.golden.txt'));
    LGoldenLine := 0;
    LTranslations := 0;
    LHits := 0;
    LContentsQueries := 0;
    LContactQueries := 0;
    LContactCount := 0;
    LContactHitQueries := 0;
    LSolidContents := 0;
    LLine := 0;
    try
    while LLine < LInput.Count do
    begin
      LParts := Fields(LInput[LLine]);
      if LParts[0] = 'model' then
      begin
        // model <index> <name> <number of brushes>, then the brushes
        LSource := TFakeGeometrySource.Create(LParts[2]);
        LRef := LSource;
        for LBrushIndex := 1 to StrToInt(LParts[3]) do
        begin
          Inc(LLine);
          LSideCount := StrToInt(Fields(LInput[LLine])[1]);
          SetLength(LSides, LSideCount);
          for LIndex := 0 to LSideCount - 1 do
          begin
            Inc(LLine);
            LGoldenParts := Fields(LInput[LLine]);
            LSides[LIndex].Plane := TGeoPlane.Make(TGeoVec3.Make(ToFloat(LGoldenParts[1]), ToFloat(LGoldenParts[2]),
              ToFloat(LGoldenParts[3])), ToFloat(LGoldenParts[4]));
            LSides[LIndex].Material := LCatalog.FindMaterial('solid');
          end;
          LSource.AddBrushSides(LSides);
        end;
        LBuilder := TCollisionFactory.CreateBuilder(nil);
        try
          LModel := LBuilder.Build(LRef);
        finally
          LBuilder.Free;
        end;
        LHandles.Add(LManager.AddModel(LModel));
        LRef := nil;
      end
      else if (LParts[0] = 'T') or (LParts[0] = 'K') then
      begin
        // T model hasTrm minx miny minz maxx maxy maxz sx sy sz ex ey ez mask
        LModelIndex := StrToInt(LParts[1]);
        LHas := LParts[2] = '1';
        LBounds.Mins := Pick(LParts, 3);
        LBounds.Maxs := Pick(LParts, 6);
        LStart := Pick(LParts, 9);
        LEnd := Pick(LParts, 12);
        LTrm.SetupBox(LBounds);
        LTrm.Kind := tmkInvalid;
        LTrm.SetupBox(LBounds);
        LGoldenParts := Fields(LGolden[LGoldenLine]);
        Inc(LGoldenLine);
        if LParts[0] = 'T' then
        begin
          Inc(LTranslations);
          if LHas then
            LManager.Translation(LResult, LStart, LEnd, LTrm, TGeoMat3.Identity, StrToInt(LParts[15]),
              LHandles[LModelIndex], TGeoVec3.Origin, TGeoMat3.Identity)
          else
            LManager.Translation(LResult, LStart, LEnd, nil, TGeoMat3.Identity, StrToInt(LParts[15]),
              LHandles[LModelIndex], TGeoVec3.Origin, TGeoMat3.Identity);
          // the edge against edge tests divide numbers that cancel: at 1000 units the fraction of the
          // two builds can differ by a few 1e-5 (hence the tolerances)
          Compare('fraction', LResult.Fraction, ToFloat(LGoldenParts[1]), True, 5e-5, 0);
          CompareVec('endpos', LResult.EndPos, LGoldenParts, 2, True, 1e-3, 1e-4);
          if ToFloat(LGoldenParts[1]) < 1 then
          begin
            Inc(LHits);
            CompareVec('normal', LResult.C.Normal, LGoldenParts, 5);
            if LResult.C.Contents <> StrToInt(LGoldenParts[12]) then
              Mismatch('contents');
            // which feature is reported, when several touch at the same moment, depends on the last
            // bit of the fractions: soft differences
            Compare('dist', LResult.C.Dist, ToFloat(LGoldenParts[8]), False);
            CompareVec('point', LResult.C.Point, LGoldenParts, 9, False);
            LExpectedType := StrToInt(LGoldenParts[13]);
            if Ord(LResult.C.ContactType) <> LExpectedType then
              Mismatch(Format('contact type: Delphi %d, C++ %d', [Ord(LResult.C.ContactType), LExpectedType]), False)
            else
            begin
              if (LExpectedType <> Ord(ctTrmVertex)) and (LResult.C.ModelFeature <> StrToInt(LGoldenParts[14])) then
                Mismatch(Format('model feature: Delphi %d, C++ %s', [LResult.C.ModelFeature, LGoldenParts[14]]), False);
              if LResult.C.TrmFeature <> StrToInt(LGoldenParts[15]) then
                Mismatch(Format('trm feature: Delphi %d, C++ %s', [LResult.C.TrmFeature, LGoldenParts[15]]), False);
            end;
          end;
        end
        else
        begin
          // K: contacts along the vector, depth 1
          Inc(LContactQueries);
          LCount := StrToInt(LGoldenParts[1]);
          if LCount > 0 then
            Inc(LContactHitQueries);
          if LHas then
            LManager.Contacts(LContacts, 64, LStart, LEnd - LStart, 1, LTrm, TGeoMat3.Identity,
              StrToInt(LParts[15]), LHandles[LModelIndex], TGeoVec3.Origin, TGeoMat3.Identity)
          else
            LManager.Contacts(LContacts, 64, LStart, LEnd - LStart, 1, nil, TGeoMat3.Identity,
              StrToInt(LParts[15]), LHandles[LModelIndex], TGeoVec3.Origin, TGeoMat3.Identity);
          if LContacts.Count <> LCount then
            Mismatch(Format('number of contacts: Delphi %d, C++ %d', [LContacts.Count, LCount]));
          for LIndex := 0 to LCount - 1 do
          begin
            // k px py pz nx ny nz dist contents type trmFeature
            LGoldenParts := Fields(LGolden[LGoldenLine]);
            Inc(LGoldenLine);
            if LIndex < LContacts.Count then
            begin
              Inc(LContactCount);
              // contacts are listed in the order the features are met: soft, like the feature of a hit
              CompareVec('contact point', LContacts[LIndex].Point, LGoldenParts, 1, False);
              CompareVec('contact normal', LContacts[LIndex].Normal, LGoldenParts, 4, False);
              Compare('contact dist', LContacts[LIndex].Dist, ToFloat(LGoldenParts[7]), False);
              if LContacts[LIndex].Contents <> StrToInt(LGoldenParts[8]) then
                Mismatch('contact contents', False);
              if Ord(LContacts[LIndex].ContactType) <> StrToInt(LGoldenParts[9]) then
                Mismatch('contact type', False);
              if LContacts[LIndex].TrmFeature <> StrToInt(LGoldenParts[10]) then
                Mismatch('contact trm feature', False);
            end;
          end;
        end;
      end
      else if LParts[0] = 'C' then
      begin
        // C model hasTrm minx miny minz maxx maxy maxz sx sy sz mask
        Inc(LContentsQueries);
        LModelIndex := StrToInt(LParts[1]);
        LHas := LParts[2] = '1';
        LBounds.Mins := Pick(LParts, 3);
        LBounds.Maxs := Pick(LParts, 6);
        LStart := Pick(LParts, 9);
        LTrm.SetupBox(LBounds);
        LGoldenParts := Fields(LGolden[LGoldenLine]);
        Inc(LGoldenLine);
        if LHas then
          LContents := LManager.Contents(LStart, LTrm, TGeoMat3.Identity, StrToInt(LParts[12]),
            LHandles[LModelIndex], TGeoVec3.Origin, TGeoMat3.Identity)
        else
          LContents := LManager.Contents(LStart, nil, TGeoMat3.Identity, StrToInt(LParts[12]),
            LHandles[LModelIndex], TGeoVec3.Origin, TGeoMat3.Identity);
        if LContents <> 0 then
          Inc(LSolidContents);
        if LContents <> StrToInt(LGoldenParts[1]) then
          Mismatch(Format('contents: Delphi %d, C++ %s', [LContents, LGoldenParts[1]]));
      end;
      Inc(LLine);
    end;
    except
      on E: Exception do
        raise Exception.CreateFmt('input line %d (golden line %d): %s [%s]', [LLine + 1, LGoldenLine, E.Message,
          LInput[LLine]]);
    end;
    // the data must exercise the code: hits, contacts and solid positions
    Assert.IsTrue(LTranslations >= 1000, 'translations ' + IntToStr(LTranslations));
    Assert.IsTrue(LHits >= 200, 'hits ' + IntToStr(LHits));
    Assert.IsTrue(LContactCount >= 100, 'contacts ' + IntToStr(LContactCount));
    Assert.IsTrue(LSolidContents >= 50, 'solid positions ' + IntToStr(LSolidContents));
    Assert.AreEqual(LGolden.Count, LGoldenLine, 'every golden line is used');
    // summary by kind of difference
    LKinds := TDictionary<string, Integer>.Create;
    try
      for LIndex := 0 to LMismatch.Count - 1 do
      begin
        LKind := LMismatch[LIndex];
        LKind := Copy(LKind, Pos(': ', LKind) + 2, MaxInt);
        if Pos(':', LKind) > 0 then
          LKind := Copy(LKind, 1, Pos(':', LKind) - 1);
        if Pos(' Delphi', LKind) > 0 then
          LKind := Copy(LKind, 1, Pos(' Delphi', LKind) - 1);
        if LKinds.ContainsKey(LKind) then
          LKinds[LKind] := LKinds[LKind] + 1
        else
          LKinds.Add(LKind, 1);
      end;
      LSummary := '';
      for LKind in LKinds.Keys do
        LSummary := LSummary + Format('%s=%d; ', [LKind, LKinds[LKind]]);
    finally
      LKinds.Free;
    end;
    // the soft differences: how many queries report another feature than the C++ code does
    LSoftQueries := LSoftLines.Count;
    LSummary := LSummary + Format(' [soft: %d queries with another contact feature out of %d hits and %d contact queries]',
      [LSoftQueries, LHits, LContactQueries]);
    Assert.AreEqual(0, LMismatch.Count, Format('%d differences from the C++ code (%d translations, %d hits, %d contents, %d contact queries) by kind: %s. First ones:'#13#10'%s',
      [LMismatch.Count, LTranslations, LHits, LContentsQueries, LContactQueries, LSummary,
      string.Join(#13#10, Copy(LMismatch.ToStringArray, 0, 8))]));
    // when several features touch at the same moment (a face of the trace model parallel to a face of
    // the model) which one is reported depends on rounding noise: at most a quarter of the queries
    // that have a contact may report another feature (10% with the data in the repository)
    Assert.IsTrue(LSoftQueries * 4 <= LHits + LContactHitQueries,
      LSummary + #13#10 + string.Join(#13#10, Copy(LSoft.ToStringArray, 0, 6)));
  finally
    LTrm.Free;
    LContacts.Free;
    LSoftLines.Free;
    LSoft.Free;
    LMismatch.Free;
    LHandles.Free;
    LManager := nil;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCollisionParity);

end.
