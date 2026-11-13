{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the articulatedFigure declaration - parity with the    }
{  real C++                                                                    }
{                                                                              }
{  Runs Tests\Data\Decl\afs.input.txt with TDeclArticulatedFigure and compares }
{  the output with afs.golden.txt, which is what the real DeclAF.cpp of Doom 3 }
{  printed for the same file (see Tests\Data\Decl\README.md).                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.ArticulatedFigureGolden;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Decl.Intf,
  DelphiDoom.Decl.ArticulatedFigure.Types, DelphiDoom.Tests.Decl.ArticulatedFigureSupport;

type
  /// <summary>The interpreter of the cases: the same operations and output lines as the driver of the C++ harness</summary>
  TArticulatedFigureGoldenRunner = class
  strict private
    FKit: TArticulatedFigureKit;
    FFigures: TDictionary<string, IDecl>;
    procedure Emit(const ALine: string);
    class function Bits(const AValue: Single): string; static;
    class function BitsList(const AValues: array of Single): string; static;
    class function Words(const AText: string): TArray<string>; static;
    class function Join(const AWords: TArray<string>; const AFrom: Integer): string; static;
    class function VectorLine(const AVector: TAfVector): string; static;
    procedure Dump(const ADecl: IDecl);
    procedure Flush(const AName, AText: string);
    procedure Execute(const AOperation: string);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Runs every case of the text and returns the output lines (the caller frees them)</summary>
    function RunAll(const AInput: TStrings): TStringList;
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclArticulatedFigureGolden = class
  strict private
    function DataFolder: string;
    function LinesMatch(const AExpected, AActual: string): Boolean;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroDeclAF;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Decl.Types, DelphiDoom.Decl.ArticulatedFigure.Intf,
  DelphiDoom.Decl.ArticulatedFigure, DelphiDoom.Decl.ArticulatedFigure.Contents,
  DelphiDoom.Decl.ArticulatedFigure.Writer, DelphiDoom.Tests.Scanner.IdFakes;

{ TArticulatedFigureGoldenRunner }

constructor TArticulatedFigureGoldenRunner.Create;
begin
  inherited Create;
  FFigures := TDictionary<string, IDecl>.Create;
end;

destructor TArticulatedFigureGoldenRunner.Destroy;
begin
  FFigures.Free;
  inherited Destroy;
end;

procedure TArticulatedFigureGoldenRunner.Emit(const ALine: string);
begin
  FKit.Lines.Add(ALine);
end;

class function TArticulatedFigureGoldenRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := IntToHex(PCardinal(@LValue)^, 8);
end;

class function TArticulatedFigureGoldenRunner.BitsList(const AValues: array of Single): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AValues) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + Bits(AValues[LIndex]);
  end;
end;

class function TArticulatedFigureGoldenRunner.Words(const AText: string): TArray<string>;
var
  LList: TStringList;
  LIndex: Integer;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ' ';
    LList.StrictDelimiter := True;
    LList.DelimitedText := Trim(AText);
    SetLength(Result, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
      Result[LIndex] := LList[LIndex];
  finally
    LList.Free;
  end;
end;

class function TArticulatedFigureGoldenRunner.Join(const AWords: TArray<string>; const AFrom: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := AFrom to High(AWords) do
  begin
    if LIndex > AFrom then
      Result := Result + ' ';
    Result := Result + AWords[LIndex];
  end;
end;

class function TArticulatedFigureGoldenRunner.VectorLine(const AVector: TAfVector): string;
begin
  Result := Format('k=%d j1=[%s] j2=[%s] v=%s s=[%s]', [Ord(AVector.Kind), TFakeIdLibLog.Escape(AVector.Joint1),
    TFakeIdLibLog.Escape(AVector.Joint2), BitsList([AVector.Vec.X, AVector.Vec.Y, AVector.Vec.Z]),
    TFakeIdLibLog.Escape(TAfWriter.VectorToString(AVector, 3))]);
end;

procedure TArticulatedFigureGoldenRunner.Dump(const ADecl: IDecl);
var
  LFigure: IDeclArticulatedFigure;
  LSettings: TAfSettings;
  LBody: TAfBody;
  LConstraint: TAfConstraint;
  LIndex, LRow, LColumn: Integer;
  LInertia: array[0..8] of Single;
begin
  Supports(ADecl, IDeclArticulatedFigure, LFigure);
  LSettings := LFigure.GetSettings;
  Emit(Format('af %s mod=%d model=[%s] skin=[%s] mass=%s susp=%s,%s,%s,%s nm=%s,%s,%s mv=%s,%s cont=%d clip=%d self=%d nb=%d nc=%d',
    [string(ADecl.GetName), Ord(LSettings.Modified), TFakeIdLibLog.Escape(LSettings.Model),
    TFakeIdLibLog.Escape(LSettings.Skin), Bits(LSettings.TotalMass), Bits(LSettings.SuspendVelocity.X),
    Bits(LSettings.SuspendVelocity.Y), Bits(LSettings.SuspendAcceleration.X), Bits(LSettings.SuspendAcceleration.Y),
    Bits(LSettings.NoMoveTime), Bits(LSettings.NoMoveTranslation), Bits(LSettings.NoMoveRotation),
    Bits(LSettings.MinMoveTime), Bits(LSettings.MaxMoveTime), LSettings.Contents, LSettings.ClipMask,
    Ord(LSettings.SelfCollision), LFigure.GetNumBodies, LFigure.GetNumConstraints]));
  Emit(' fr=' + BitsList([LSettings.DefaultLinearFriction, LSettings.DefaultAngularFriction,
    LSettings.DefaultContactFriction, LSettings.DefaultConstraintFriction]));
  for LIndex := 0 to LFigure.GetNumBodies - 1 do
  begin
    LBody := LFigure.GetBody(LIndex);
    for LRow := 0 to 2 do
      for LColumn := 0 to 2 do
        LInertia[LRow * 3 + LColumn] := LBody.InertiaScale.Rows[LRow].Items[LColumn];
    Emit(Format('body %d name=[%s] joint=[%s] mod=%d mt=%d sides=%d width=%s dens=%s cont=%d clip=%d self=%d fr=%s,%s,%s ang=%s inertia=%s contained=[%s]',
      [LIndex, TFakeIdLibLog.Escape(LBody.Name), TFakeIdLibLog.Escape(LBody.JointName), Ord(LBody.JointMod),
      Ord(LBody.ModelType), LBody.NumSides, Bits(LBody.Width), Bits(LBody.Density), LBody.Contents, LBody.ClipMask,
      Ord(LBody.SelfCollision), Bits(LBody.LinearFriction), Bits(LBody.AngularFriction), Bits(LBody.ContactFriction),
      BitsList([LBody.Angles.Pitch, LBody.Angles.Yaw, LBody.Angles.Roll]), BitsList(LInertia),
      TFakeIdLibLog.Escape(LBody.ContainedJoints)]));
    Emit(' v1 ' + VectorLine(LBody.V1));
    Emit(' v2 ' + VectorLine(LBody.V2));
    Emit(' org ' + VectorLine(LBody.Origin));
    Emit(' fdir ' + VectorLine(LBody.FrictionDirection));
    Emit(' mdir ' + VectorLine(LBody.ContactMotorDirection));
  end;
  for LIndex := 0 to LFigure.GetNumConstraints - 1 do
  begin
    LConstraint := LFigure.GetConstraint(LIndex);
    Emit(Format('con %d name=[%s] type=%d b1=[%s] b2=[%s] fric=%s sc=%s,%s,%s,%s,%s,%s lim=%d la=%s,%s,%s',
      [LIndex, TFakeIdLibLog.Escape(LConstraint.Name), Ord(LConstraint.ConstraintType),
      TFakeIdLibLog.Escape(LConstraint.Body1), TFakeIdLibLog.Escape(LConstraint.Body2), Bits(LConstraint.Friction),
      Bits(LConstraint.Stretch), Bits(LConstraint.Compress), Bits(LConstraint.Damping), Bits(LConstraint.RestLength),
      Bits(LConstraint.MinLength), Bits(LConstraint.MaxLength), LConstraint.Limit, Bits(LConstraint.LimitAngles[0]),
      Bits(LConstraint.LimitAngles[1]), Bits(LConstraint.LimitAngles[2])]));
    Emit(' anchor ' + VectorLine(LConstraint.Anchor));
    Emit(' anchor2 ' + VectorLine(LConstraint.Anchor2));
    Emit(' shaft0 ' + VectorLine(LConstraint.Shaft[0]));
    Emit(' shaft1 ' + VectorLine(LConstraint.Shaft[1]));
    Emit(' axis ' + VectorLine(LConstraint.Axis));
    Emit(' limaxis ' + VectorLine(LConstraint.LimitAxis));
  end;
end;

procedure TArticulatedFigureGoldenRunner.Flush(const AName, AText: string);
var
  LParsed: Boolean;
  LDecl: IDecl;
begin
  Emit('> decl ' + AName);
  LDecl := FKit.Make(AnsiString(AName), AnsiString(AText), LParsed);
  // what the driver of the C++ does: it keeps the whole text in the declaration
  LDecl.SetText(AnsiString('articulatedFigure ' + AName + #10 + AText));
  Emit(Format('ret=%d', [Ord(LParsed)]));
  FFigures.AddOrSetValue(AName, LDecl);
  Dump(LDecl);
end;

procedure TArticulatedFigureGoldenRunner.Execute(const AOperation: string);
var
  LWords: TArray<string>;
  LDecl: IDecl;
  LEditor: IDeclArticulatedFigureEditor;
  LFigure: IDeclArticulatedFigure;
  LResolver: TFakeJointResolver;
  LResolverIntf: IAfJointResolver;
  LMask, LEqual, LIndex: Integer;
  LParts: TArray<string>;
  LText: AnsiString;
  LParsed: Boolean;
  LMod: TAfJointMod;
  LSettings: TAfSettings;
begin
  LWords := Words(AOperation);
  Emit('> ' + Join(LWords, 0));
  if LWords[0] = 'contents' then
  begin
    LMask := TAfContents.ContentsFromString(AnsiString(Join(LWords, 1)));
    Emit(Format('contents %d -> [%s]', [LMask, string(TAfContents.ContentsToString(LMask))]));
    Exit;
  end;
  if LWords[0] = 'tostr' then
  begin
    Emit(Format('tostr [%s]', [string(TAfContents.ContentsToString(StrToInt(LWords[1])))]));
    Exit;
  end;
  if LWords[0] = 'jointmod' then
  begin
    LMod := TAfContents.JointModFromString(AnsiString(LWords[1]));
    Emit(Format('jointmod %d [%s]', [Ord(LMod), string(TAfContents.JointModToString(LMod))]));
    Exit;
  end;
  FFigures.TryGetValue(LWords[1], LDecl);
  Supports(LDecl, IDeclArticulatedFigure, LFigure);
  Supports(LDecl, IDeclArticulatedFigureEditor, LEditor);
  if LWords[0] = 'dump' then
    Dump(LDecl)
  else if LWords[0] = 'finish' then
  begin
    LResolver := TFakeJointResolver.Create;
    LResolverIntf := LResolver;
    for LIndex := 2 to High(LWords) do
    begin
      LEqual := Pos('=', LWords[LIndex]);
      LParts := Copy(LWords[LIndex], LEqual + 1, MaxInt).Split([',']);
      LResolver.Add(Copy(LWords[LIndex], 1, LEqual - 1), StrToFloat(LParts[0], TFormatSettings.Invariant),
        StrToFloat(LParts[1], TFormatSettings.Invariant), StrToFloat(LParts[2], TFormatSettings.Invariant));
    end;
    LFigure.Finish(LResolverIntf);
    Dump(LDecl);
  end
  else if LWords[0] = 'save' then
  begin
    LDecl.SetText('');
    LSettings := LFigure.GetSettings;
    LSettings.Modified := True;
    LFigure.SetSettings(LSettings);
    LEditor.Save;
    Emit(Format('saved replaced=%d modified=%d text=%s', [Ord(FKit.BaseOf(LDecl.GetName).Replaced),
      Ord(LFigure.GetSettings.Modified), TFakeIdLibLog.Escape(LDecl.GetText)]));
  end
  else if LWords[0] = 'newbody' then
  begin
    LEditor.NewBody(AnsiString(LWords[2]));
    Dump(LDecl);
  end
  else if LWords[0] = 'renamebody' then
  begin
    LEditor.RenameBody(AnsiString(LWords[2]), AnsiString(LWords[3]));
    Dump(LDecl);
  end
  else if LWords[0] = 'deletebody' then
  begin
    LEditor.DeleteBody(AnsiString(LWords[2]));
    Dump(LDecl);
  end
  else if LWords[0] = 'newcon' then
  begin
    LEditor.NewConstraint(AnsiString(LWords[2]));
    Dump(LDecl);
  end
  else if LWords[0] = 'renamecon' then
  begin
    LEditor.RenameConstraint(AnsiString(LWords[2]), AnsiString(LWords[3]));
    Dump(LDecl);
  end
  else if LWords[0] = 'deletecon' then
  begin
    LEditor.DeleteConstraint(AnsiString(LWords[2]));
    Dump(LDecl);
  end
  else if LWords[0] = 'freedata' then
  begin
    TDeclArticulatedFigure(LDecl as TObject).FreeData;
    Dump(LDecl);
  end
  else if LWords[0] = 'reload' then
  begin
    LText := LDecl.GetText;
    TDeclArticulatedFigure(LDecl as TObject).FreeData;
    LParsed := TDeclArticulatedFigure(LDecl as TObject).Parse(LText);
    Emit(Format('ret=%d', [Ord(LParsed)]));
    Dump(LDecl);
  end
  else if LWords[0] = 'makedefault' then
  begin
    LDecl.MakeDefault;
    Dump(LDecl);
  end;
end;

function TArticulatedFigureGoldenRunner.RunAll(const AInput: TStrings): TStringList;
var
  LLine, LName, LText: string;
  LInDecl: Boolean;
  LParts: TArray<string>;

  procedure FlushDeclaration;
  begin
    if LInDecl then
      Flush(LName, LText);
    LInDecl := False;
  end;

begin
  FKit := TArticulatedFigureKit.Create;
  LInDecl := False;
  try
    for LLine in AInput do
    begin
      if LLine.StartsWith('@case ') then
      begin
        FlushDeclaration;
        FFigures.Clear;
        Emit('## ' + Copy(LLine, 7, MaxInt));
      end
      else if LLine = '@end' then
        FlushDeclaration
      else if LLine.StartsWith('@decl ') then
      begin
        FlushDeclaration;
        LParts := Words(Copy(LLine, 7, MaxInt));
        LName := LParts[1];
        LText := '';
        LInDecl := True;
      end
      else if LLine.StartsWith('@op ') then
      begin
        FlushDeclaration;
        Execute(Copy(LLine, 5, MaxInt));
      end
      else if LInDecl then
        LText := LText + LLine + #10;
    end;
    FlushDeclaration;
  finally
    FFigures.Clear;
    // the lines of the kit are copied: they go with the kit
    Result := TStringList.Create;
    Result.Assign(FKit.Lines);
    FreeAndNil(FKit);
  end;
end;

{ TTestDeclArticulatedFigureGolden }

// the floats are written as their bits: the lines must be the same, as the C++ of the reference gave them
function TTestDeclArticulatedFigureGolden.LinesMatch(const AExpected, AActual: string): Boolean;
begin
  Result := AExpected = AActual;
end;

function TTestDeclArticulatedFigureGolden.DataFolder: string;
begin
  Result := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Decl\');
end;

procedure TTestDeclArticulatedFigureGolden.DovrebbeDareLeStesseRisposteDelVeroDeclAF;
var
  LInput, LGolden, LActual: TStringList;
  LRunner: TArticulatedFigureGoldenRunner;
  LIndex: Integer;
begin
  LInput := TStringList.Create;
  LGolden := TStringList.Create;
  LRunner := TArticulatedFigureGoldenRunner.Create;
  LActual := nil;
  try
    LInput.LoadFromFile(DataFolder + 'afs.input.txt', TEncoding.ANSI);
    LGolden.LoadFromFile(DataFolder + 'afs.golden.txt', TEncoding.ANSI);
    LActual := LRunner.RunAll(LInput);
    for LIndex := 0 to LGolden.Count - 1 do
      if (LIndex >= LActual.Count) or not LinesMatch(LGolden[LIndex], LActual[LIndex]) then
      begin
        LActual.SaveToFile(ChangeFileExt(ParamStr(0), '.afs.actual.txt'));
        if LIndex < LActual.Count then
          Assert.Fail(Format('line %d: expected [%s] but got [%s]', [LIndex + 1, LGolden[LIndex], LActual[LIndex]]))
        else
          Assert.Fail(Format('line %d: expected [%s] but the output ended', [LIndex + 1, LGolden[LIndex]]));
      end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
  finally
    LActual.Free;
    LRunner.Free;
    LGolden.Free;
    LInput.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclArticulatedFigureGolden);

end.
