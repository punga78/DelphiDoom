{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the players of OpenArena       }
{  loaded, skinned, animated and assembled by the Quake III classes            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.Q3OpenArena;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Models.Q3Player.Skin.Intf,
  DelphiDoom.Tests.Models.Q3PlayerSupport,
  DelphiDoom.Tests.Models.Q3PakSupport;

type
  /// <summary>
  ///   The pk3 of OpenArena in Reference\openarena (GPL v2 data, never copied to the repository):
  ///   every model of Tests that has "lower.md3", "upper.md3" and "head.md3" is loaded with its
  ///   default skin and its animation.cfg, the tags and the frames are checked, and the model is
  ///   assembled for a series of animations. The tests are skipped (they pass without running) if the
  ///   files are not there.
  /// </summary>
  [TestFixture]
  [Category('models')]
  TTestModelsQ3OpenArena = class(TObject)
  strict private
    FPaks: TQ3PakFiles;
    FPaksKeeper: IInterface;
    FLog: TFakeQ3Log;
    FLogKeeper: IInterface;
    FLoader: IQ3PlayerModelLoader;
    FModels: TStringList;
    function LoadPlayer(const AModelName: string; out AModel: IQ3PlayerModel): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeCaricareITuttiIGiocatoriDiOpenArena;
    [Test]
    procedure DovrebbeTrovareITagEIFotogrammiDelleAnimazioni;
    [Test]
    procedure DovrebbeDareUnaShaderDiOgniSuperficieDalleSkin;
    [Test]
    procedure DovrebbeAssemblareOgniGiocatoreInTutteLeAnimazioni;
    [Test]
    procedure DovrebbeCaricareLeSkinDiSquadraDeiGiocatori;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Skin.Types,
  DelphiDoom.Models.Q3Player.FloatMath,
  DelphiDoom.Models.Q3Player.Factory;

function TTestModelsQ3OpenArena.LoadPlayer(const AModelName: string; out AModel: IQ3PlayerModel): Boolean;
var
  LRequest: TQ3PlayerModelRequest;
begin
  LRequest.Context.TeamGame := False;
  LRequest.Context.Team := qtFree;
  LRequest.ModelName := AnsiString(AModelName);
  LRequest.SkinName := 'default';
  LRequest.HeadModelName := '';
  LRequest.HeadSkinName := 'default';
  LRequest.TeamName := '';
  Result := FLoader.Load(LRequest, AModel);
end;

procedure TTestModelsQ3OpenArena.Setup;
var
  LFolder, LName, LModel: string;
  LLog: ILog;
begin
  LFolder := FindOpenArenaFolder;
  FModels := TStringList.Create;
  FPaks := nil;
  if LFolder = '' then
    Exit;
  // in the order of the file system of Quake III: a later pak hides the files of the earlier ones (the maps and
  // the textures have no players)
  FPaks := TQ3PakFiles.Create([TPath.Combine(LFolder, 'pak0.pk3'), TPath.Combine(LFolder, 'pak2-players-mature.pk3'),
    TPath.Combine(LFolder, 'pak2-players.pk3'), TPath.Combine(LFolder, 'pak5-TA.pk3'),
    TPath.Combine(LFolder, 'pak6-misc.pk3'), TPath.Combine(LFolder, 'pak6-patch085.pk3'),
    TPath.Combine(LFolder, 'pak6-patch088.pk3')]);
  FPaksKeeper := FPaks;
  FLog := TFakeQ3Log.Create;
  FLogKeeper := FLog;
  LLog := FLog;
  FLoader := TQ3PlayerFactory.CreateModelLoader(FPaks, FPaks, LLog);
  for LName in FPaks.Names('models/players/') do
    if LName.EndsWith('/lower.md3') then
    begin
      LModel := Copy(LName, Length('models/players/') + 1, Length(LName) - Length('models/players/') - Length('/lower.md3'));
      if (Pos('/', LModel) = 0) and (LModel <> '') then
        FModels.Add(LModel);
    end;
  FModels.Sort;
end;

procedure TTestModelsQ3OpenArena.TearDown;
begin
  FLoader := nil;
  FLogKeeper := nil;
  FLog := nil;
  FPaksKeeper := nil;
  FPaks := nil;
  FModels.Free;
end;

procedure TTestModelsQ3OpenArena.DovrebbeCaricareITuttiIGiocatoriDiOpenArena;
var
  LModel: IQ3PlayerModel;
  LName, LFailed: string;
  LLoaded: Integer;
begin
  if FModels.Count = 0 then
    Exit;
  LLoaded := 0;
  LFailed := '';
  for LName in FModels do
    if LoadPlayer(LName, LModel) then
      Inc(LLoaded)
    else
      LFailed := LFailed + ' ' + LName;
  TDUnitX.CurrentRunner.Log(Format('OpenArena: %d players, %d loaded; not loaded:%s', [FModels.Count, LLoaded, LFailed]));
  Assert.IsTrue(FModels.Count >= 10, 'players found: ' + IntToStr(FModels.Count));
  // "sorceress" has no "default" skin in the paks, the original fails on it too (the three skin warnings)
  Assert.IsTrue(LLoaded * 10 >= FModels.Count * 9, 'not loaded:' + LFailed + ' | ' + FLog.Warnings.Text);
end;

procedure TTestModelsQ3OpenArena.DovrebbeTrovareITagEIFotogrammiDelleAnimazioni;
var
  LModel: IQ3PlayerModel;
  LName, LProblems: string;
  LTag: TQ3Orientation;
  LLerper: IQ3TagLerper;
  LIndex, LChecked: Integer;
  LAnimation: TQ3Animation;
begin
  if FModels.Count = 0 then
    Exit;
  LLerper := TQ3PlayerFactory.CreateTagLerper;
  LProblems := '';
  LChecked := 0;
  for LName in FModels do
  begin
    if not LoadPlayer(LName, LModel) then
      Continue;
    Inc(LChecked);
    if not LLerper.LerpTag(LModel.LegsModel, 0, 0, 0, 'tag_torso', LTag) then
      LProblems := LProblems + ' ' + LName + ':tag_torso';
    if not LLerper.LerpTag(LModel.TorsoModel, 0, 0, 0, 'tag_head', LTag) then
      LProblems := LProblems + ' ' + LName + ':tag_head';
    if not LLerper.LerpTag(LModel.TorsoModel, 0, 0, 0, 'tag_weapon', LTag) then
      LProblems := LProblems + ' ' + LName + ':tag_weapon';
    for LIndex := 0 to Q3_MAX_ANIMATIONS - 1 do
    begin
      LAnimation := LModel.Animation.Animations[LIndex];
      if LAnimation.NumFrames = 0 then
        Continue;
      // the legs animations are in the frames of the lower model, the others in the ones of the upper
      if LIndex in [Q3_LEGS_WALKCR .. Q3_LEGS_TURN] then
      begin
        if LAnimation.FirstFrame + LAnimation.NumFrames > LModel.LegsModel.NumFrames then
          LProblems := LProblems + Format(' %s:legs%d(%d+%d>%d)', [LName, LIndex, LAnimation.FirstFrame,
            LAnimation.NumFrames, LModel.LegsModel.NumFrames]);
      end
      else if LAnimation.FirstFrame + LAnimation.NumFrames > LModel.TorsoModel.NumFrames then
        LProblems := LProblems + Format(' %s:torso%d(%d+%d>%d)', [LName, LIndex, LAnimation.FirstFrame,
          LAnimation.NumFrames, LModel.TorsoModel.NumFrames]);
    end;
  end;
  Assert.IsTrue(LChecked > 0);
  Assert.AreEqual('', LProblems);
end;

procedure TTestModelsQ3OpenArena.DovrebbeDareUnaShaderDiOgniSuperficieDalleSkin;
var
  LModel: IQ3PlayerModel;
  LName, LProblems: string;
  LResolver: IQ3SkinShaderResolver;
  LShaders: TArray<AnsiString>;
  LIndex, LChecked, LOwnShaders, LSurfaces, LMissing: Integer;

  procedure CheckPart(const APart: string; const AMesh: IMd3Model; const ASkin: IQ3Skin);
  var
    LShader: Integer;
  begin
    LShaders := LResolver.Resolve(AMesh, ASkin, 0);
    Assert.AreEqual<Integer>(AMesh.NumSurfaces, Length(LShaders));
    Inc(LSurfaces, Length(LShaders));
    for LShader := 0 to High(LShaders) do
      if LShaders[LShader] = '' then
      begin
        Inc(LMissing);
        LProblems := LProblems + Format(' %s:%s:%s', [LName, APart, string(AMesh.Surfaces[LShader].Name)]);
      end;
  end;

begin
  if FModels.Count = 0 then
    Exit;
  LResolver := TQ3PlayerFactory.CreateSkinShaderResolver;
  LProblems := '';
  LChecked := 0;
  LOwnShaders := 0;
  LSurfaces := 0;
  LMissing := 0;
  for LName in FModels do
  begin
    if not LoadPlayer(LName, LModel) then
      Continue;
    Inc(LChecked);
    CheckPart('lower', LModel.LegsModel, LModel.LegsSkin);
    CheckPart('upper', LModel.TorsoModel, LModel.TorsoSkin);
    CheckPart('head', LModel.HeadModel, LModel.HeadSkin);
    // the shader that the MD3 itself names, with no skin (some models leave it empty: the skin gives it)
    LShaders := LResolver.Resolve(LModel.LegsModel, nil, 0);
    for LIndex := 0 to High(LShaders) do
      if LShaders[LIndex] <> '' then
        Inc(LOwnShaders);
  end;
  Assert.IsTrue(LChecked > 0);
  Assert.IsTrue(LOwnShaders > 0);
  // the data of OpenArena is not perfect: a few surfaces of a model have no line in its skin (the original
  // draws them with the default shader and warns in developer mode)
  TDUnitX.CurrentRunner.Log(Format('Surfaces without a shader in the skin: %d of %d:%s', [LMissing, LSurfaces, LProblems]));
  Assert.IsTrue(LMissing * 20 <= LSurfaces, 'too many surfaces without a shader:' + LProblems);
end;

procedure TTestModelsQ3OpenArena.DovrebbeAssemblareOgniGiocatoreInTutteLeAnimazioni;
const
  LEGS: array[0..4] of Integer = (Q3_LEGS_IDLE, Q3_LEGS_RUN, Q3_LEGS_WALK, Q3_LEGS_JUMP, Q3_LEGS_SWIM);
  TORSOS: array[0..3] of Integer = (Q3_TORSO_STAND, Q3_TORSO_ATTACK, Q3_TORSO_GESTURE, Q3_TORSO_DROP);
var
  LModel: IQ3PlayerModel;
  LName: string;
  LAnimator: IQ3PlayerAnimator;
  LAssembler: IQ3PlayerAssembler;
  LPlayer: TQ3PlayerEntity;
  LFrames: TQ3PlayerFrames;
  LAxis: TQ3Axis;
  LLegs, LTorso, LHead, LGun: TQ3Entity;
  LStep, LKind, LChecked: Integer;
begin
  if FModels.Count = 0 then
    Exit;
  LAssembler := TQ3PlayerFactory.CreateAssembler;
  TQ3FloatMath.AxisClear(LAxis);
  LChecked := 0;
  for LName in FModels do
  begin
    if not LoadPlayer(LName, LModel) then
      Continue;
    Inc(LChecked);
    LAnimator := TQ3PlayerFactory.CreateAnimator(LModel.Animation);
    FillChar(LPlayer, SizeOf(LPlayer), 0);
    for LKind := 0 to High(LEGS) do
      for LStep := 0 to 20 do
      begin
        LAnimator.Animate(LPlayer, 1000 + (LKind * 21 + LStep) * 57, LEGS[LKind], TORSOS[LKind mod 4], False, LFrames);
        Assert.IsTrue((LFrames.Legs >= 0) and (LFrames.Legs < LModel.LegsModel.NumFrames) and
          (LFrames.LegsOld >= 0) and (LFrames.LegsOld < LModel.LegsModel.NumFrames), LName + ' legs frame');
        Assert.IsTrue((LFrames.Torso >= 0) and (LFrames.Torso < LModel.TorsoModel.NumFrames) and
          (LFrames.TorsoOld >= 0) and (LFrames.TorsoOld < LModel.TorsoModel.NumFrames), LName + ' torso frame');
        LAssembler.Assemble(LModel.LegsModel, LModel.TorsoModel, TIdVec3.Create(10, 20, 30), LAxis, LAxis, LAxis,
          LFrames, LLegs, LTorso, LHead);
        LAssembler.PositionWeapon(LTorso, LModel.TorsoModel, LGun);
        // the torso is on the legs and the head on the torso: none of them stays at the origin of the player
        Assert.IsFalse((LTorso.Origin.X = 10) and (LTorso.Origin.Y = 20) and (LTorso.Origin.Z = 30), LName + ' torso');
        Assert.IsFalse((LHead.Origin.X = 10) and (LHead.Origin.Y = 20) and (LHead.Origin.Z = 30), LName + ' head');
        Assert.IsTrue((LGun.Origin.X = LGun.Origin.X) and (LGun.Origin.Z = LGun.Origin.Z), LName + ' gun');
      end;
  end;
  Assert.IsTrue(LChecked > 0);
end;

procedure TTestModelsQ3OpenArena.DovrebbeCaricareLeSkinDiSquadraDeiGiocatori;
var
  LRequest: TQ3PlayerModelRequest;
  LModel: IQ3PlayerModel;
  LLoaded: Integer;
  LName: string;
begin
  if FModels.Count = 0 then
    Exit;
  // a team game: the "red" and "blue" skins, with the team folder that the original falls back to
  LLoaded := 0;
  for LName in FModels do
  begin
    LRequest.Context.TeamGame := True;
    LRequest.Context.Team := qtRed;
    LRequest.ModelName := AnsiString(LName);
    LRequest.SkinName := 'red';
    LRequest.HeadModelName := '';
    LRequest.HeadSkinName := 'red';
    LRequest.TeamName := 'Stroggs/';
    if FLoader.Load(LRequest, LModel) then
      Inc(LLoaded);
  end;
  TDUnitX.CurrentRunner.Log(Format('OpenArena team skins: %d of %d players', [LLoaded, FModels.Count]));
  Assert.IsTrue(LLoaded > 0);
end;

end.
