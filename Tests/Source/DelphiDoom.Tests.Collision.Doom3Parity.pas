{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity tests of the Doom 3 collision library (issue #108)       }
{                                                                              }
{  Tests\Data\Collision\Doom3\<map>.cm is the file that the REAL Doom 3 code   }
{  (neo\cm\CollisionModel_load.cpp and _files.cpp, built with bcc32c by        }
{  Tools\Verifica\108) writes for <map>.map, and <map>.queries.golden.txt the  }
{  answers of that code, on the model read back from that file, to scripted    }
{  translations, rotations, position tests and contact searches (every float   }
{  as its bits). The library reads the same file and answers the same         }
{  queries. Hard differences (a hit that is not a hit, the fraction, the end   }
{  position and axis, the contents, the number of contacts) must be zero; the  }
{  feature reported when several touch at the same instant is compared with a  }
{  declared limit.                                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Doom3Parity;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('collision')]
  [Category('parity')]
  TTestDoom3Parity = class(TObject)
  private
    function DataPath(const AFileName: string): string;
    procedure RunMap(const AName: string);
  public
    [Test]
    procedure DovrebbeRispondereCometeCppSullaStanza;
    [Test]
    procedure DovrebbeRispondereCometeCppSulleTegole;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Rotation, DelphiDoom.MathCore.Float.GeometryAdapter,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Factory,
  DelphiDoom.Tests.Collision.Support;

const
  /// <summary>Tolerance on a float that is a position, a distance or a direction (x87 against SSE, tie breaks)</summary>
  ABSOLUTE_TOLERANCE = 2E-3;
  RELATIVE_TOLERANCE = 2E-5;
  /// <summary>Tolerance on the fraction of a movement</summary>
  FRACTION_TOLERANCE = 2E-5;
  /// <summary>Share of the queries with a hit whose contact feature may differ (ties between touching elements)</summary>
  MAX_SOFT_SHARE = 0.25;

type
  TSections = TArray<TArray<string>>;

function BitsToSingle(const AText: string): Single;
var
  LBits: Cardinal;
begin
  LBits := Cardinal(StrToInt64('$' + Copy(AText, 2, MaxInt)));
  Result := PSingle(@LBits)^;
end;

function Sections(const ALine: string): TSections;
var
  LParts: TArray<string>;
  LIndex: Integer;
begin
  LParts := ALine.Split(['|']);
  SetLength(Result, Length(LParts));
  for LIndex := 0 to High(LParts) do
    Result[LIndex] := LParts[LIndex].Split([' '], TStringSplitOptions.ExcludeEmpty);
end;

function ReadVec(const AParts: TArray<string>; AFrom: Integer): TGeoVec3;
begin
  Result := TGeoVec3.Make(BitsToSingle(AParts[AFrom]), BitsToSingle(AParts[AFrom + 1]), BitsToSingle(AParts[AFrom + 2]));
end;

function ReadMat(const AParts: TArray<string>; AFrom: Integer): TGeoMat3;
begin
  Result.Rows[0] := ReadVec(AParts, AFrom);
  Result.Rows[1] := ReadVec(AParts, AFrom + 3);
  Result.Rows[2] := ReadVec(AParts, AFrom + 6);
end;

function Close(AActual, AExpected: Single): Boolean;
begin
  Result := Abs(AActual - AExpected) <= ABSOLUTE_TOLERANCE + RELATIVE_TOLERANCE * Abs(AExpected);
end;

function CloseVec(const AActual: TGeoVec3; const AParts: TArray<string>; AFrom: Integer): Boolean;
begin
  Result := Close(AActual.X, BitsToSingle(AParts[AFrom])) and Close(AActual.Y, BitsToSingle(AParts[AFrom + 1])) and
    Close(AActual.Z, BitsToSingle(AParts[AFrom + 2]));
end;

{ TTestDoom3Parity }

function TTestDoom3Parity.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Collision\Doom3\' + AFileName);
end;

procedure TTestDoom3Parity.RunMap(const AName: string);
var
  LCatalog: ICollisionMaterialCatalog;
  LManager: ICollisionModelManager;
  LStream: TFileStream;
  LGolden: TStringList;
  LLine: Integer;
  LLoop: Integer;
  LKindCounts: string;
  LKindLoop: Char;
  LHardLine: string;
  LSections: TSections;
  LKind: Char;
  LModel: Integer;
  LMask: Integer;
  LTrm: TTraceModel;
  LTrmAxis: TGeoMat3;
  LModelOrigin: TGeoVec3;
  LModelAxis: TGeoMat3;
  LTrace: TCollisionTrace;
  LContacts: TList<TContactInfo>;
  LHard: TStringList;
  LQueries: Integer;
  LHits: Integer;
  LSoft: Integer;
  LRotation: TIdRotation;
  LContents: Integer;
  LExpectedCount: Integer;
  LIndex: Integer;
  LParts: TArray<string>;
  LBounds: TGeoBounds;
  LTranslations: Integer;
  LRotations: Integer;
  LContentQueries: Integer;
  LContactQueries: Integer;
  LRotationHits: Integer;

  procedure Fail(const AText: string);
  begin
    LHard.Add(Format('%s line %d: %s', [LKind, LLine + 1, AText]));
  end;

  function MakeTrm(const AParts: TArray<string>): TTraceModel;
  begin
    Result := nil;
    case AParts[0][1] of
      'B':
        begin
          LBounds.Mins := ReadVec(AParts, 1);
          LBounds.Maxs := ReadVec(AParts, 4);
          Result := TTraceModel.Create;
          Result.SetupBox(LBounds);
        end;
      'Y':
        begin
          LBounds.Mins := ReadVec(AParts, 1);
          LBounds.Maxs := ReadVec(AParts, 4);
          Result := TTraceModel.Create;
          Result.SetupCylinder(LBounds, StrToInt(AParts[7]));
        end;
      'N':
        begin
          Result := TTraceModel.Create;
          Result.SetupBone(BitsToSingle(AParts[1]), BitsToSingle(AParts[2]));
        end;
    end;
  end;

  function MaterialName(const AContact: TContactInfo): string;
  begin
    if Assigned(AContact.Material) then
      Result := AContact.Material.Name
    else
      Result := '-';
  end;

  /// <summary>Compares a contact written as type n(3) dist contents material feature feature point(3), from AFrom; true if the feature numbers agree</summary>
  function CompareContact(const AContact: TContactInfo; const AParts: TArray<string>; AFrom: Integer;
    ACheckType: Boolean): Boolean;
  var
    LFeature: Integer;
  begin
    // normal, distance and point are hard when the type is the same, the features are the soft part
    Result := True;
    if not CloseVec(AContact.Normal, AParts, AFrom + 1) then
      Fail('contact normal');
    // when two elements touch at the same instant the other one may be reported (another type, plane distance
    // and point); only the normal, the contents and the material are then compared
    if (Ord(AContact.ContactType) = StrToInt(AParts[AFrom])) and
      not Close(AContact.Dist, BitsToSingle(AParts[AFrom + 4])) then
      Fail(Format('contact dist Delphi %.6g C++ %.6g (type %d/%s)', [AContact.Dist, BitsToSingle(AParts[AFrom + 4]),
        Ord(AContact.ContactType), AParts[AFrom]]));
    if AContact.Contents <> StrToInt(AParts[AFrom + 5]) then
      Fail('contact contents');
    if MaterialName(AContact) <> AParts[AFrom + 6] then
      Fail('contact material ' + MaterialName(AContact) + ' / ' + AParts[AFrom + 6]);
    if ACheckType and (Ord(AContact.ContactType) <> StrToInt(AParts[AFrom])) then
      Result := False;
    LFeature := AContact.ModelFeature;
    if AContact.ContactType = ctTrmVertex then
      Dec(LFeature);
    if (LFeature <> StrToInt(AParts[AFrom + 7])) or (AContact.TrmFeature <> StrToInt(AParts[AFrom + 8])) then
      Result := False;
    if not CloseVec(AContact.Point, AParts, AFrom + 9) then
      Result := False;
  end;

  procedure CompareTrace(const AOutput: TArray<string>; ASoftIfHit: Boolean);
  var
    LHit: Boolean;
    LRow: Integer;
  begin
    LHit := BitsToSingle(AOutput[0]) < 1;
    if (LTrace.Fraction < 1) <> LHit then
    begin
      Fail(Format('hit %s, fraction Delphi %.6g C++ %.6g', [BoolToStr(LTrace.Fraction < 1, True), LTrace.Fraction,
        BitsToSingle(AOutput[0])]));
      Exit;
    end;
    if Abs(LTrace.Fraction - BitsToSingle(AOutput[0])) > FRACTION_TOLERANCE then
      Fail(Format('fraction Delphi %.7g C++ %.7g', [LTrace.Fraction, BitsToSingle(AOutput[0])]));
    if not CloseVec(LTrace.EndPos, AOutput, 1) then
      Fail(Format('end position Delphi %.5g %.5g %.5g C++ %.5g %.5g %.5g', [LTrace.EndPos.X, LTrace.EndPos.Y,
        LTrace.EndPos.Z, BitsToSingle(AOutput[1]), BitsToSingle(AOutput[2]), BitsToSingle(AOutput[3])]));
    for LRow := 0 to 2 do
      if not CloseVec(LTrace.EndAxis.Rows[LRow], AOutput, 4 + 3 * LRow) then
        Fail('end axis');
    if LHit then
    begin
      Inc(LHits);
      if not CompareContact(LTrace.C, AOutput, 13, True) then
        Inc(LSoft);
    end;
  end;

begin
  LCatalog := CreateDoom3Catalog;
  LManager := TCollisionFactory.CreateManager(LCatalog, nil);
  LStream := TFileStream.Create(DataPath(AName + '.cm'), fmOpenRead or fmShareDenyWrite);
  try
    Assert.IsTrue(LManager.LoadModelFile(LStream, 0) > 0, 'the .cm file is not read');
  finally
    LStream.Free;
  end;

  LGolden := TStringList.Create;
  LHard := TStringList.Create;
  try
    LGolden.LoadFromFile(DataPath(AName + '.queries.golden.txt'));
    LQueries := 0;
    LHits := 0;
    LSoft := 0;
    LTranslations := 0;
    LRotations := 0;
    LContentQueries := 0;
    LContactQueries := 0;
    LRotationHits := 0;
    for LLoop := 0 to LGolden.Count - 1 do
    begin
      LLine := LLoop;
      if (LGolden[LLine] = '') or (LGolden[LLine][1] = '#') then
        Continue;
      LSections := Sections(LGolden[LLine]);
      LParts := LSections[0];
      LKind := LParts[0][1];
      LModel := StrToInt(LParts[1]);
      LMask := StrToInt(LParts[2]);
      LTrm := MakeTrm(LSections[2]);
      try
        LTrmAxis := ReadMat(LSections[3], 0);
        LModelOrigin := ReadVec(LSections[4], 0);
        LModelAxis := ReadMat(LSections[4], 3);
        Inc(LQueries);
        case LKind of
          'T':
            begin
              Inc(LTranslations);
              LManager.Translation(LTrace, ReadVec(LSections[1], 0), ReadVec(LSections[1], 3), LTrm, LTrmAxis,
                LMask, LModel, LModelOrigin, LModelAxis);
              CompareTrace(LSections[5], True);
            end;
          'R':
            begin
              Inc(LRotations);
              LRotation := TIdRotation.Create(TIdGeometryAdapter.ToId(ReadVec(LSections[1], 3)),
                TIdGeometryAdapter.ToId(ReadVec(LSections[1], 6)), BitsToSingle(LSections[1][9]));
              LManager.Rotation(LTrace, ReadVec(LSections[1], 0), LRotation, LTrm, LTrmAxis, LMask, LModel,
                LModelOrigin, LModelAxis);
              if LTrace.Fraction < 1 then
                Inc(LRotationHits);
              CompareTrace(LSections[5], True);
            end;
          'C':
            begin
              Inc(LContentQueries);
              LContents := LManager.Contents(ReadVec(LSections[1], 0), LTrm, LTrmAxis, LMask, LModel, LModelOrigin,
                LModelAxis);
              if LContents <> StrToInt(LSections[5][0]) then
                Fail(Format('contents Delphi %d C++ %s', [LContents, LSections[5][0]]));
            end;
          'K':
            begin
              Inc(LContactQueries);
              LContacts := TList<TContactInfo>.Create;
              try
                LExpectedCount := StrToInt(LSections[5][0]);
                LParts := LGolden[LLine].Split(['|']);
                LParts := LParts[High(LParts)].Split([';']);
                LIndex := LManager.Contacts(LContacts, 32, ReadVec(LSections[1], 0),
                  ReadVec(LSections[1], 3), BitsToSingle(LSections[1][6]), LTrm, LTrmAxis, LMask, LModel,
                  LModelOrigin, LModelAxis);
                if LIndex <> LExpectedCount then
                  Fail(Format('contacts Delphi %d C++ %d', [LIndex, LExpectedCount]))
                else
                  for LIndex := 0 to LExpectedCount - 1 do
                    if not CompareContact(LContacts[LIndex],
                      LParts[LIndex + 1].Split([' '], TStringSplitOptions.ExcludeEmpty), 0, True) then
                    begin
                      Inc(LSoft);
                      Break;
                    end;
              finally
                LContacts.Free;
              end;
            end;
        end;
      finally
        LTrm.Free;
      end;
    end;

    if LHard.Count > 0 then
    begin
      LKindCounts := '';
      for LKindLoop := 'C' to 'T' do
        if CharInSet(LKindLoop, ['T', 'R', 'C', 'K']) then
        begin
          LIndex := 0;
          for LHardLine in LHard do
            if LHardLine[1] = LKindLoop then
              Inc(LIndex);
          LKindCounts := LKindCounts + Format(' %s=%d', [LKindLoop, LIndex]);
        end;
      Assert.Fail(Format('%s: %d hard differences in %d queries (%s); first: %s', [AName, LHard.Count, LQueries,
        LKindCounts, LHard.Text.Substring(0, 2500)]));
    end;
    Assert.IsTrue(LQueries > 300, 'too few queries');
    Assert.IsTrue(LRotationHits > 20, 'too few rotations that hit something');
    Assert.IsTrue(LSoft <= MAX_SOFT_SHARE * (LHits + LContactQueries),
      Format('%s: %d contacts with another feature out of %d hits', [AName, LSoft, LHits + LContactQueries]));
    System.Writeln(Format('%s: %d queries (%d T, %d R with %d hits, %d C, %d K), %d tie-break differences',
      [AName, LQueries, LTranslations, LRotations, LRotationHits, LContentQueries, LContactQueries, LSoft]));
  finally
    LHard.Free;
    LGolden.Free;
  end;
end;

procedure TTestDoom3Parity.DovrebbeRispondereCometeCppSullaStanza;
begin
  RunMap('room');
end;

procedure TTestDoom3Parity.DovrebbeRispondereCometeCppSulleTegole;
begin
  RunMap('tiles');
end;

end.
