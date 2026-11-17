{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TEngineGlSceneFog - OpenGL call flow against the text   }
{  of gl_render.pas of before the class, for each game                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.SceneFog;

{$I Doom32.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Tests.OpenGl.FakeGlLog;

type
  /// <summary>
  ///   The fog only calls OpenGL (fake functions that log, no context) and reads the options, the fixed
  ///   colormap of the displayed player and the game specific state (custom colormap of Doom and Strife,
  ///   fog of the level of Hexen). The project of each game defines its game, so the branches of the class
  ///   are the ones of that game: the calls are compared with the old gld_StartFog and gld_StartWhiteFog,
  ///   copied here from the text of before the class, on every combination of the inputs
  /// </summary>
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlSceneFog = class(TObject)
  strict private
    FFakeGl: TFakeGlLog;
    function Run(const AProc: TProc): TStringList;
    procedure SetInputs(AUseFog, AUseWhiteFog: Boolean; AFixedColormap, ADensityIndex: Integer;
      AWithCustomColormap, ALevelFog: Boolean);
    procedure CompareAll(const AOld, ANew: TProc; const AWhite: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeSpegnereLaNebbiaSeNonSiUsa;
    [Test]
    procedure DovrebbeSpegnereLaNebbiaConLaColormapFissaDelGiocatore;
    [Test]
    procedure DovrebbeUsareIlGiocatoreMostrato;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerLaNebbiaSuTutteLeCombinazioni;
    [Test]
    procedure DovrebbeSpegnereLaNebbiaBiancaSeNonSiUsa;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioPerLaNebbiaBiancaSuTutteLeCombinazioni;
    [Test]
    procedure DovrebbeAccendereLaNebbiaComeUltimaChiamataConLeSueImpostazioni;
    [Test]
    procedure DovrebbeUsareLeRegoleDelGiocoPerIlColoreDellaNebbia;
  end;

implementation

uses
  dglOpenGL,
  d_player,
  g_game,
  gl_defs,
  r_colormaps,
  r_data,
  DelphiDoom.Engine.GlScene.Fog;

const
  GL_FOG_ENABLE = $0B60;

var
  GColormaps: array[0..1] of customcolormap_t;

function FloatBits(const AValue: Single): string;
begin
  Result := IntToHex(PCardinal(@AValue)^, 8);
end;

// The text of before the classes (gl_render.pas, commit before ondata2-177-1), only the names of the
// locals and the players of the session changed.

procedure OldStartFog;
var
  FogColor: array[0..3] of TGLfloat;
begin
  if use_fog then
    if TGameSession.Players[displayplayer].fixedcolormap = 0 then
    begin
{$IFDEF DOOM_OR_STRIFE}
      if customcolormap <> nil then
      begin
        glFogf(GL_FOG_DENSITY, customcolormap.fog_density * fog_density / 1000.0);

        FogColor[0] := customcolormap.fog_r;
        FogColor[1] := customcolormap.fog_g;
        FogColor[2] := customcolormap.fog_b;
        FogColor[3] := 0.0;
      end
      else
      begin
        glFogf(GL_FOG_DENSITY, fog_density / 1000.0);

        FogColor[0] := 0.0;
        FogColor[1] := 0.0;
        FogColor[2] := 0.0;
        FogColor[3] := 0.0;
      end;

      glFogfv(GL_FOG_COLOR, @FogColor);
{$ENDIF}
{$IFDEF HERETIC}
      glFogf(GL_FOG_DENSITY, fog_density / 1000.0);

      FogColor[0] := 0.0;
      FogColor[1] := 0.0;
      FogColor[2] := 0.0;
      FogColor[3] := 0.0;

      glFogfv(GL_FOG_COLOR, @FogColor);
{$ENDIF}
{$IFDEF HEXEN}
      glFogf(GL_FOG_DENSITY, fog_density / 1000.0);
      if LevelUseFog then
      begin
        FogColor[0] := 1.0;
        FogColor[1] := 1.0;
        FogColor[2] := 1.0;
        FogColor[3] := 0.0;
      end
      else
      begin
        FogColor[0] := 0.0;
        FogColor[1] := 0.0;
        FogColor[2] := 0.0;
        FogColor[3] := 0.0;
      end;

      glFogfv(GL_FOG_COLOR, @FogColor);
{$ENDIF}

      glEnable(GL_FOG);
      exit;
    end;

  glDisable(GL_FOG);
end;

procedure OldStartWhiteFog;
var
  FogColor: array[0..3] of TGLfloat;
begin
  if use_white_fog then
    if TGameSession.Players[displayplayer].fixedcolormap = 0 then
    begin
      glFogf(GL_FOG_DENSITY, white_fog_density / 1000.0);

  {$IFDEF DOOM_OR_STRIFE}
      if customcolormap <> nil then
      begin
        FogColor[0] := (customcolormap.fog_r + 1.0) / 2.0;
        FogColor[1] := (customcolormap.fog_g + 1.0) / 2.0;
        FogColor[2] := (customcolormap.fog_b + 1.0) / 2.0;
        FogColor[3] := 0.0;
      end
      else
      begin
        FogColor[0] := 1.0;
        FogColor[1] := 1.0;
        FogColor[2] := 1.0;
        FogColor[3] := 0.0;
      end;
  {$ENDIF}
  {$IFDEF HERETIC_OR_HEXEN}
      FogColor[0] := 1.0;
      FogColor[1] := 1.0;
      FogColor[2] := 1.0;
      FogColor[3] := 0.0;
  {$ENDIF}

      glFogfv(GL_FOG_COLOR, @FogColor);
      glEnable(GL_FOG);
      exit;
    end;

  glDisable(GL_FOG);
end;

{ TTestOpenGlSceneFog }

procedure TTestOpenGlSceneFog.Setup;
begin
  FFakeGl := TFakeGlLog.Create;
  FFakeGl.Install;
  FillChar(TGameSession.Players, SizeOf(TGameSession.Players), 0);
  displayplayer := 0;
  use_fog := False;
  fog_density := 100;
  use_white_fog := True;
  white_fog_density := 200;
  customcolormap := nil;
  LevelUseFog := False;
  GColormaps[0].fog_r := 0.25;
  GColormaps[0].fog_g := 0.5;
  GColormaps[0].fog_b := 0.75;
  GColormaps[0].fog_density := 1.5;
  GColormaps[1].fog_r := 0.1;
  GColormaps[1].fog_g := 1.0;
  GColormaps[1].fog_b := 0.0;
  GColormaps[1].fog_density := 7.25;
end;

procedure TTestOpenGlSceneFog.TearDown;
begin
  customcolormap := nil;
  FFakeGl.Restore;
  FreeAndNil(FFakeGl);
end;

function TTestOpenGlSceneFog.Run(const AProc: TProc): TStringList;
begin
  TFakeGlLog.Clear;
  AProc;
  Result := TStringList.Create;
  Result.Assign(TFakeGlLog.Lines);
end;

procedure TTestOpenGlSceneFog.SetInputs(AUseFog, AUseWhiteFog: Boolean; AFixedColormap, ADensityIndex: Integer;
  AWithCustomColormap, ALevelFog: Boolean);
const
  Densities: array[0..2] of Integer = (0, 100, 333);
begin
  use_fog := AUseFog;
  use_white_fog := AUseWhiteFog;
  TGameSession.Players[displayplayer].fixedcolormap := AFixedColormap;
  fog_density := Densities[ADensityIndex];
  white_fog_density := Densities[2 - ADensityIndex] + 7;
  if AWithCustomColormap then
    customcolormap := @GColormaps[ADensityIndex mod 2]
  else
    customcolormap := nil;
  LevelUseFog := ALevelFog;
end;

procedure TTestOpenGlSceneFog.CompareAll(const AOld, ANew: TProc; const AWhite: Boolean);
var
  LUseFog, LWithCustom, LLevelFog: Boolean;
  LFixed, LDensity: Integer;
  LOld, LNew: TStringList;
  LCases: Integer;
begin
  LCases := 0;
  for LUseFog in [False, True] do
    for LFixed in [0, 1, 32] do
      for LDensity := 0 to 2 do
        for LWithCustom in [False, True] do
          for LLevelFog in [False, True] do
          begin
            SetInputs(LUseFog, LUseFog, LFixed, LDensity, LWithCustom, LLevelFog);
            LOld := Run(AOld);
            try
              LNew := Run(ANew);
              try
                Assert.IsTrue(LOld.Count > 0, 'il vecchio non ha chiamato OpenGL');
                Assert.AreEqual(LOld.Text, LNew.Text,
                  Format('fog=%s fisso=%d densita=%d custom=%s livello=%s bianca=%s',
                    [BoolToStr(LUseFog, True), LFixed, LDensity, BoolToStr(LWithCustom, True),
                     BoolToStr(LLevelFog, True), BoolToStr(AWhite, True)]));
                Inc(LCases);
              finally
                LNew.Free;
              end;
            finally
              LOld.Free;
            end;
          end;
  Assert.AreEqual<Integer>(2 * 3 * 3 * 2 * 2, LCases);
end;

procedure TTestOpenGlSceneFog.DovrebbeSpegnereLaNebbiaSeNonSiUsa;
var
  LLines: TStringList;
begin
  SetInputs(False, True, 0, 1, True, True);
  LLines := Run(procedure begin TEngineGlSceneFog.Start end);
  try
    Assert.AreEqual(1, LLines.Count);
    Assert.AreEqual('glDisable 0B60', LLines[0]);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneFog.DovrebbeSpegnereLaNebbiaConLaColormapFissaDelGiocatore;
var
  LLines: TStringList;
begin
  SetInputs(True, True, 32, 1, True, True);
  LLines := Run(procedure begin TEngineGlSceneFog.Start end);
  try
    Assert.AreEqual('glDisable 0B60', LLines.Text.Trim);
  finally
    LLines.Free;
  end;
  LLines := Run(procedure begin TEngineGlSceneFog.StartWhite end);
  try
    Assert.AreEqual('glDisable 0B60', LLines.Text.Trim);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneFog.DovrebbeUsareIlGiocatoreMostrato;
var
  LLines: TStringList;
begin
  displayplayer := 2;
  SetInputs(True, True, 0, 1, False, False);
  TGameSession.Players[0].fixedcolormap := 5;
  TGameSession.Players[2].fixedcolormap := 0;
  LLines := Run(procedure begin TEngineGlSceneFog.Start end);
  try
    Assert.AreNotEqual('glDisable 0B60', LLines.Text.Trim, 'ha guardato il giocatore 0');
  finally
    LLines.Free;
  end;
  TGameSession.Players[2].fixedcolormap := 5;
  LLines := Run(procedure begin TEngineGlSceneFog.Start end);
  try
    Assert.AreEqual('glDisable 0B60', LLines.Text.Trim);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneFog.DovrebbeDareLeStesseChiamateDelVecchioPerLaNebbiaSuTutteLeCombinazioni;
begin
  CompareAll(
    procedure begin OldStartFog end,
    procedure begin TEngineGlSceneFog.Start end,
    False);
end;

procedure TTestOpenGlSceneFog.DovrebbeSpegnereLaNebbiaBiancaSeNonSiUsa;
var
  LLines: TStringList;
begin
  SetInputs(True, False, 0, 1, True, True);
  LLines := Run(procedure begin TEngineGlSceneFog.StartWhite end);
  try
    Assert.AreEqual('glDisable 0B60', LLines.Text.Trim);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneFog.DovrebbeDareLeStesseChiamateDelVecchioPerLaNebbiaBiancaSuTutteLeCombinazioni;
begin
  CompareAll(
    procedure begin OldStartWhiteFog end,
    procedure begin TEngineGlSceneFog.StartWhite end,
    True);
end;

procedure TTestOpenGlSceneFog.DovrebbeAccendereLaNebbiaComeUltimaChiamataConLeSueImpostazioni;
var
  LLines: TStringList;
begin
  SetInputs(True, True, 0, 1, False, False);
  LLines := Run(procedure begin TEngineGlSceneFog.Start end);
  try
    Assert.AreEqual(3, LLines.Count, 'densita, colore, accensione');
    Assert.IsTrue(LLines[0].StartsWith('glFogf 0B62 '), LLines[0]);
    Assert.IsTrue(LLines[1].StartsWith('glFogfv 0B66 '), LLines[1]);
    Assert.AreEqual('glEnable 0B60', LLines[2]);
  finally
    LLines.Free;
  end;
  LLines := Run(procedure begin TEngineGlSceneFog.StartWhite end);
  try
    Assert.AreEqual(3, LLines.Count);
    Assert.AreEqual('glEnable 0B60', LLines[2]);
  finally
    LLines.Free;
  end;
end;

procedure TTestOpenGlSceneFog.DovrebbeUsareLeRegoleDelGiocoPerIlColoreDellaNebbia;
var
  LLines: TStringList;
  LBlack, LWhite: string;
  LDensity: Single;
begin
  LBlack := 'glFogfv 0B66 00000000 00000000 00000000 00000000';
  LWhite := 'glFogfv 0B66 3F800000 3F800000 3F800000 00000000';
  // the index 1 of the densities is 100 and picks the second custom colormap (0.1, 1.0, 0.0, density 7.25)
  SetInputs(True, True, 0, 1, True, True);
  LLines := Run(procedure begin TEngineGlSceneFog.Start end);
  try
{$IFDEF DOOM_OR_STRIFE}
    // the colour of the custom colormap and its density times the option
    LDensity := GColormaps[1].fog_density * fog_density / 1000.0;
    Assert.AreEqual('glFogf 0B62 ' + FloatBits(LDensity), LLines[0]);
    Assert.AreEqual('glFogfv 0B66 ' + FloatBits(0.1) + ' ' + FloatBits(1.0) + ' ' + FloatBits(0.0) + ' ' +
      FloatBits(0.0), LLines[1]);
{$ENDIF}
{$IFDEF HERETIC}
    // Heretic ignores the level and has no custom colormap
    Assert.AreEqual(LBlack, LLines[1]);
{$ENDIF}
{$IFDEF HEXEN}
    // Hexen: white fog in the levels that have it
    Assert.AreEqual(LWhite, LLines[1]);
{$ENDIF}
  finally
    LLines.Free;
  end;
{$IFDEF HEXEN}
  LevelUseFog := False;
  LLines := Run(procedure begin TEngineGlSceneFog.Start end);
  try
    Assert.AreEqual(LBlack, LLines[1]);
  finally
    LLines.Free;
  end;
{$ENDIF}
  Assert.IsNotEmpty(LWhite);
  LDensity := 0;
  Assert.AreEqual<Single>(0, LDensity);
end;

end.
