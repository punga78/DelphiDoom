{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL level geometry - the checks on the sectors  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SectorPreprocessor;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.GlLevel.Types,
  DelphiDoom.GlLevel.Intf,
  DelphiDoom.Tests.OpenGl.OldSectorPreprocessor;

type
  /// <summary>A level of arrays seen as an IGlSectorWorld (the numbers of the vertexes are given as they are)</summary>
  TGlFakeSectorWorld = class(TInterfacedObject, IGlSectorWorld)
  public
    Level: TOldLevel;
    function GetSectorCount: Integer;
    function GetVertexCount: Integer;
    function GetLineCount(const ASector: Integer): Integer;
    function GetLine(const ASector, ALine: Integer): TGlSectorLine;
    procedure SetNoTextures(const ASector: Integer; const ANoTop, ANoBottom: Boolean);
    procedure MarkIsolated(const ASector, ALine: Integer);
  end;

  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSectorPreprocessor = class(TObject)
  strict private
    function RandomLevel(const ASeed: Integer): TOldLevel;
    function Dump(const ALevel: TOldLevel): string;
    function NewWorldOf(const ALevel: TOldLevel): TGlFakeSectorWorld;
  public
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDelVecchioSu300LivelliCasuali;
    [Test]
    procedure DovrebbeLasciareSenzaTextureUnSettoreSenzaLinee;
    [Test]
    procedure DovrebbeTogliereLeTextureAlSettoreConUnaLineaASingoLato;
    [Test]
    procedure DovrebbeTogliereSoloLeTextureSuperioriSeCeNeUnaInAlto;
    [Test]
    procedure DovrebbeSegnareIsolataUnaLineaChiNonCondivideVertici;
    [Test]
    procedure DovrebbeNonSegnareIsolateLeLineeDiUnAnello;
    [Test]
    procedure DovrebbeFermareIlConteggioAllaPrimaLineaFuoriDallArray;
    [Test]
    procedure DovrebbeNonPortarsiDietroIConteggiDiUnSettoreAlSuccessivo;
    [Test]
    procedure DovrebbeAccettareUnLivelloSenzaSettoriNeVertici;
    [Test]
    procedure DovrebbeSollevareSeIlMondoManca;
  end;

implementation

uses
  DelphiDoom.GlLevel.Factory;

{ TGlFakeSectorWorld }

function TGlFakeSectorWorld.GetSectorCount: Integer;
begin
  Result := Length(Level.Sectors);
end;

function TGlFakeSectorWorld.GetVertexCount: Integer;
begin
  Result := Level.VertexCount;
end;

function TGlFakeSectorWorld.GetLineCount(const ASector: Integer): Integer;
begin
  Result := Length(Level.Sectors[ASector].Lines);
end;

function TGlFakeSectorWorld.GetLine(const ASector, ALine: Integer): TGlSectorLine;
var
  LLine: TOldLine;
begin
  LLine := Level.Sectors[ASector].Lines[ALine];
  Result.Vertex1 := LLine.V1;
  Result.Vertex2 := LLine.V2;
  Result.HasBothSides := (LLine.Sidenum[0] <> -1) and (LLine.Sidenum[1] <> -1);
  Result.FrontTopTexture := LLine.Textures[0, 0];
  Result.FrontBottomTexture := LLine.Textures[0, 1];
  Result.BackTopTexture := LLine.Textures[1, 0];
  Result.BackBottomTexture := LLine.Textures[1, 1];
end;

procedure TGlFakeSectorWorld.SetNoTextures(const ASector: Integer; const ANoTop, ANoBottom: Boolean);
begin
  Level.Sectors[ASector].NoTopTextures := ANoTop;
  Level.Sectors[ASector].NoBottomTextures := ANoBottom;
end;

procedure TGlFakeSectorWorld.MarkIsolated(const ASector, ALine: Integer);
begin
  Level.Sectors[ASector].Lines[ALine].Isolated := True;
end;

{ TTestOpenGlSectorPreprocessor }

function TTestOpenGlSectorPreprocessor.RandomLevel(const ASeed: Integer): TOldLevel;
var
  LSector, LLine, LSide: Integer;
begin
  RandSeed := ASeed;
  Result.VertexCount := 3 + Random(40);
  SetLength(Result.Sectors, 1 + Random(12));
  for LSector := 0 to High(Result.Sectors) do
  begin
    SetLength(Result.Sectors[LSector].Lines, Random(10));
    for LLine := 0 to High(Result.Sectors[LSector].Lines) do
    begin
      Result.Sectors[LSector].Lines[LLine].V1 := Random(Result.VertexCount);
      Result.Sectors[LSector].Lines[LLine].V2 := Random(Result.VertexCount);
      for LSide := 0 to 1 do
      begin
        if Random(5) = 0 then
          Result.Sectors[LSector].Lines[LLine].Sidenum[LSide] := -1
        else
          Result.Sectors[LSector].Lines[LLine].Sidenum[LSide] := Random(100);
        Result.Sectors[LSector].Lines[LLine].SideSector[LSide] := Random(Length(Result.Sectors));
        Result.Sectors[LSector].Lines[LLine].Textures[LSide, 0] := Ord(Random(6) = 0) * Random(300);
        Result.Sectors[LSector].Lines[LLine].Textures[LSide, 1] := Ord(Random(6) = 0) * Random(300);
      end;
    end;
  end;
end;

function TTestOpenGlSectorPreprocessor.Dump(const ALevel: TOldLevel): string;
var
  LSector, LLine: Integer;
begin
  Result := '';
  for LSector := 0 to High(ALevel.Sectors) do
  begin
    Result := Result + Format('S%d %d %d:', [LSector, Ord(ALevel.Sectors[LSector].NoTopTextures),
      Ord(ALevel.Sectors[LSector].NoBottomTextures)]);
    for LLine := 0 to High(ALevel.Sectors[LSector].Lines) do
      Result := Result + IntToStr(Ord(ALevel.Sectors[LSector].Lines[LLine].Isolated));
    Result := Result + #10;
  end;
end;

function TTestOpenGlSectorPreprocessor.NewWorldOf(const ALevel: TOldLevel): TGlFakeSectorWorld;
begin
  Result := TGlFakeSectorWorld.Create;
  Result.Level := ALevel;
  SetLength(Result.Level.Sectors, Length(ALevel.Sectors));
  Result.Level.Sectors := Copy(ALevel.Sectors);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeDareLoStessoRisultatoDelVecchioSu300LivelliCasuali;
var
  LSeed: Integer;
  LOld: TOldLevel;
  LWorld: IGlSectorWorld;
  LFake: TGlFakeSectorWorld;
  LExpected: string;
  LSector: Integer;
begin
  for LSeed := 1 to 300 do
  begin
    LOld := RandomLevel(LSeed);
    LFake := NewWorldOf(LOld);
    LWorld := LFake;
    // the lines of a sector in the arrays are copies: copy the line arrays too
    for LSector := 0 to High(LOld.Sectors) do
      LFake.Level.Sectors[LSector].Lines := Copy(LOld.Sectors[LSector].Lines);
    OldPreprocessSectors(LOld);
    LExpected := Dump(LOld);
    TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
    Assert.AreEqual(LExpected, Dump(LFake.Level), 'seed ' + IntToStr(LSeed));
  end;
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeLasciareSenzaTextureUnSettoreSenzaLinee;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
begin
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  LFake.Level.VertexCount := 3;
  SetLength(LFake.Level.Sectors, 1);
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  Assert.IsTrue(LFake.Level.Sectors[0].NoTopTextures);
  Assert.IsTrue(LFake.Level.Sectors[0].NoBottomTextures);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeTogliereLeTextureAlSettoreConUnaLineaASingoLato;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
begin
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  LFake.Level.VertexCount := 3;
  SetLength(LFake.Level.Sectors, 1);
  SetLength(LFake.Level.Sectors[0].Lines, 1);
  LFake.Level.Sectors[0].Lines[0].Sidenum[0] := 0;
  LFake.Level.Sectors[0].Lines[0].Sidenum[1] := -1;
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  Assert.IsFalse(LFake.Level.Sectors[0].NoTopTextures);
  Assert.IsFalse(LFake.Level.Sectors[0].NoBottomTextures);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeTogliereSoloLeTextureSuperioriSeCeNeUnaInAlto;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
begin
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  LFake.Level.VertexCount := 3;
  SetLength(LFake.Level.Sectors, 1);
  SetLength(LFake.Level.Sectors[0].Lines, 1);
  LFake.Level.Sectors[0].Lines[0].Sidenum[0] := 0;
  LFake.Level.Sectors[0].Lines[0].Sidenum[1] := 1;
  LFake.Level.Sectors[0].Lines[0].Textures[1, 0] := 7;
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  Assert.IsFalse(LFake.Level.Sectors[0].NoTopTextures);
  Assert.IsTrue(LFake.Level.Sectors[0].NoBottomTextures);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeSegnareIsolataUnaLineaChiNonCondivideVertici;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
begin
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  LFake.Level.VertexCount := 4;
  SetLength(LFake.Level.Sectors, 1);
  SetLength(LFake.Level.Sectors[0].Lines, 1);
  LFake.Level.Sectors[0].Lines[0].V1 := 0;
  LFake.Level.Sectors[0].Lines[0].V2 := 1;
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  Assert.IsTrue(LFake.Level.Sectors[0].Lines[0].Isolated);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeNonSegnareIsolateLeLineeDiUnAnello;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
  LLine: Integer;
begin
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  LFake.Level.VertexCount := 3;
  SetLength(LFake.Level.Sectors, 1);
  SetLength(LFake.Level.Sectors[0].Lines, 3);
  for LLine := 0 to 2 do
  begin
    LFake.Level.Sectors[0].Lines[LLine].V1 := LLine;
    LFake.Level.Sectors[0].Lines[LLine].V2 := (LLine + 1) mod 3;
  end;
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  for LLine := 0 to 2 do
    Assert.IsFalse(LFake.Level.Sectors[0].Lines[LLine].Isolated);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeFermareIlConteggioAllaPrimaLineaFuoriDallArray;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
begin
  // the old loop did not advance on a bad line and skipped all the lines after it: the line after the
  // bad one is not counted, so the first line (alone in the count) has no neighbour
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  LFake.Level.VertexCount := 3;
  SetLength(LFake.Level.Sectors, 1);
  SetLength(LFake.Level.Sectors[0].Lines, 3);
  LFake.Level.Sectors[0].Lines[0].V1 := 0;
  LFake.Level.Sectors[0].Lines[0].V2 := 1;
  LFake.Level.Sectors[0].Lines[1].V1 := 1;
  LFake.Level.Sectors[0].Lines[1].V2 := 99;
  LFake.Level.Sectors[0].Lines[2].V1 := 1;
  LFake.Level.Sectors[0].Lines[2].V2 := 2;
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  Assert.IsTrue(LFake.Level.Sectors[0].Lines[0].Isolated, 'prima');
  Assert.IsTrue(LFake.Level.Sectors[0].Lines[2].Isolated, 'dopo');
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeNonPortarsiDietroIConteggiDiUnSettoreAlSuccessivo;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
begin
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  LFake.Level.VertexCount := 3;
  SetLength(LFake.Level.Sectors, 2);
  SetLength(LFake.Level.Sectors[0].Lines, 1);
  SetLength(LFake.Level.Sectors[1].Lines, 1);
  LFake.Level.Sectors[0].Lines[0].V1 := 0;
  LFake.Level.Sectors[0].Lines[0].V2 := 1;
  LFake.Level.Sectors[1].Lines[0].V1 := 0;
  LFake.Level.Sectors[1].Lines[0].V2 := 1;
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  Assert.IsTrue(LFake.Level.Sectors[1].Lines[0].Isolated);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeAccettareUnLivelloSenzaSettoriNeVertici;
var
  LFake: TGlFakeSectorWorld;
  LWorld: IGlSectorWorld;
begin
  LFake := TGlFakeSectorWorld.Create;
  LWorld := LFake;
  TGlLevelFactory.CreateSectorPreprocessor(LWorld).Preprocess;
  Assert.AreEqual(0, LFake.GetSectorCount);
end;

procedure TTestOpenGlSectorPreprocessor.DovrebbeSollevareSeIlMondoManca;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlLevelFactory.CreateSectorPreprocessor(nil);
    end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOpenGlSectorPreprocessor);

end.
