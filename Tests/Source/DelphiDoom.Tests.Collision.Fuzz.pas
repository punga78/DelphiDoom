{******************************************************************************}
{                                                                              }
{  DelphiDoom: light deterministic fuzzing of the readers of the collision     }
{  library (issue #108): a .cm file that is altered must give a dedicated      }
{  exception or a model, never an access violation or a stray exception        }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Fuzz;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('collision')]
  [Category('fuzz')]
  TTestCollisionFuzz = class(TObject)
  public
    [Test]
    procedure DovrebbeRifiutareOLeggereUnCmAlteratoSenzaErroriImprevisti;
    [Test]
    procedure DovrebbeRifiutareUnCmTroncato;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Rotation,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Model, DelphiDoom.Collision.Factory,
  DelphiDoom.Collision.CmFile.Reader, DelphiDoom.Tests.Collision.Support;

function Seed(var AState: Cardinal): Cardinal;
begin
  AState := AState * 1664525 + 1013904223;
  Result := AState shr 8;
end;

function LoadText: string;
begin
  Result := TFile.ReadAllText(TPath.GetFullPath(ExtractFilePath(ParamStr(0)) +
    '..\..\..\..\Tests\Data\Collision\Doom3\tiles.cm'), TEncoding.ASCII);
end;

/// <summary>A model that was read is used: a handful of queries must not reach outside its arrays</summary>
procedure Query(AModels: TObjectList<TCollisionModel>);
var
  LManager: ICollisionModelManager;
  LTrm: TTraceModel;
  LTrace: TCollisionTrace;
  LIndex: Integer;
  LStep: Integer;
  LRotation: TIdRotation;
begin
  AModels.OwnsObjects := False;
  LManager := TCollisionFactory.CreateManager(CreateDoom3Catalog, nil);
  for LIndex := 0 to AModels.Count - 1 do
    LManager.AddModel(AModels[LIndex]);
  LTrm := TTraceModel.Create;
  try
    LTrm.SetupBox(Bounds3(-8, -8, -8, 8, 8, 8));
    for LIndex := 0 to AModels.Count - 1 do
      for LStep := 0 to 7 do
      begin
        LManager.Translation(LTrace, TGeoVec3.Make(LStep * 60 - 200, 20, 30), TGeoVec3.Make(300 - LStep * 40, 80, 10),
          LTrm, TGeoMat3.Identity, -1, LIndex, TGeoVec3.Origin, TGeoMat3.Identity);
        LManager.Contents(TGeoVec3.Make(LStep * 50, 10, 10), LTrm, TGeoMat3.Identity, -1, LIndex, TGeoVec3.Origin,
          TGeoMat3.Identity);
        LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 30 + LStep * 20);
        LManager.Rotation(LTrace, TGeoVec3.Make(LStep * 40, 30, 20), LRotation, LTrm, TGeoMat3.Identity, -1, LIndex,
          TGeoVec3.Origin, TGeoMat3.Identity);
      end;
  finally
    LTrm.Free;
  end;
  // the manager owns the models now and frees them (its interface goes away at the end of the call)
end;

/// <summary>True if the text was read or refused with the exceptions of the library</summary>
function Survives(const AText: string; out AOther: string): Boolean;
var
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
begin
  Result := True;
  AOther := '';
  LReader := TCollisionFileReader.Create(CreateDoom3Catalog, nil);
  try
    try
      LModels := LReader.Parse(AText);
      if Assigned(LModels) then
        try
          Query(LModels);
        finally
          LModels.Free;
        end;
    except
      on E: ECollisionException do
        ;
      on E: Exception do
      begin
        Result := False;
        AOther := E.ClassName + ': ' + E.Message;
      end;
    end;
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFuzz.DovrebbeRifiutareOLeggereUnCmAlteratoSenzaErroriImprevisti;
const
  Replacements: array[0..9] of string = ('0', '-1', '99999', '2147483647', '-', '(', ')', '"x"', '1e38', '65536');
var
  LText: string;
  LMutated: string;
  LState: Cardinal;
  LRun: Integer;
  LPosition: Integer;
  LLength: Integer;
  LOther: string;
  LFailures: string;
begin
  LText := LoadText;
  LState := 12345;
  LFailures := '';
  for LRun := 1 to 400 do
  begin
    LMutated := LText;
    // overwrite a few characters, or replace a number-like piece with a nasty one
    LPosition := Integer(Seed(LState) mod Cardinal(Length(LMutated))) + 1;
    case Seed(LState) mod 3 of
      0:
        LMutated[LPosition] := Chr(33 + Seed(LState) mod 90);
      1:
        begin
          LLength := Integer(Seed(LState) mod 4);
          Delete(LMutated, LPosition, LLength);
          Insert(Replacements[Seed(LState) mod 10], LMutated, LPosition);
        end;
    else
      begin
        LLength := Integer(Seed(LState) mod 200);
        Delete(LMutated, LPosition, LLength);
      end;
    end;
    if not Survives(LMutated, LOther) then
      LFailures := LFailures + Format(' run %d: %s;', [LRun, LOther]);
  end;
  Assert.AreEqual('', LFailures, 'unexpected exceptions');
end;

procedure TTestCollisionFuzz.DovrebbeRifiutareUnCmTroncato;
var
  LText: string;
  LLength: Integer;
  LOther: string;
  LFailures: string;
begin
  LText := LoadText;
  LFailures := '';
  LLength := 0;
  while LLength < Length(LText) do
  begin
    if not Survives(Copy(LText, 1, LLength), LOther) then
      LFailures := LFailures + Format(' length %d: %s;', [LLength, LOther]);
    Inc(LLength, 211);
  end;
  Assert.AreEqual('', LFailures, 'unexpected exceptions');
end;

end.
