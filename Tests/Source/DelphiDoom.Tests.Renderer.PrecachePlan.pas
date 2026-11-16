{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - what a level needs to be loaded }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.PrecachePlan;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererPrecachePlan = class(TObject)
  private
    FPlanner: IRendererPrecachePlanner;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareTabelleDellaDimensioneDelGioco;
    [Test]
    procedure DovrebbeSegnareIFlatDeiSettoriELeAggiunte;
    [Test]
    procedure DovrebbeSegnareLeTextureDeiLatiELeAggiunte;
    [Test]
    procedure DovrebbeSegnareGliSpriteDegliOggetti;
    [Test]
    procedure DovrebbeIgnorareINumeriFuoriDalGioco;
    /// <summary>
    ///   Parity: the tables of what is present of the old R_PrecacheLevel (a byte written for
    ///   each number), copied here as they were, on random levels
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioR_PrecacheLevel;
  end;

implementation

uses
  DelphiDoom.Renderer.Factory;

{ TTestRendererPrecachePlan }

procedure TTestRendererPrecachePlan.Setup;
begin
  FPlanner := TRendererFactory.CreatePrecachePlanner;
end;

procedure TTestRendererPrecachePlan.TearDown;
begin
  FPlanner := nil;
end;

procedure TTestRendererPrecachePlan.DovrebbeDareTabelleDellaDimensioneDelGioco;
var
  LInput: TRendererPrecacheInput;
  LPlan: TRendererPrecachePlan;
begin
  LInput := Default(TRendererPrecacheInput);
  LInput.FlatCount := 7;
  LInput.TextureCount := 9;
  LInput.SpriteCount := 3;
  LPlan := FPlanner.Plan(LInput);
  Assert.AreEqual<Integer>(7, Length(LPlan.FlatPresent));
  Assert.AreEqual<Integer>(9, Length(LPlan.TexturePresent));
  Assert.AreEqual<Integer>(3, Length(LPlan.SpritePresent));
  Assert.IsFalse(LPlan.FlatPresent[3]);
end;

procedure TTestRendererPrecachePlan.DovrebbeSegnareIFlatDeiSettoriELeAggiunte;
var
  LInput: TRendererPrecacheInput;
  LPlan: TRendererPrecachePlan;
begin
  LInput := Default(TRendererPrecacheInput);
  LInput.FlatCount := 6;
  LInput.SectorFlats := [1, 2, 2, 4];
  LInput.ExtraFlats := [5];
  LPlan := FPlanner.Plan(LInput);
  Assert.IsFalse(LPlan.FlatPresent[0]);
  Assert.IsTrue(LPlan.FlatPresent[1]);
  Assert.IsTrue(LPlan.FlatPresent[2]);
  Assert.IsFalse(LPlan.FlatPresent[3]);
  Assert.IsTrue(LPlan.FlatPresent[4]);
  Assert.IsTrue(LPlan.FlatPresent[5]);
end;

procedure TTestRendererPrecachePlan.DovrebbeSegnareLeTextureDeiLatiELeAggiunte;
var
  LInput: TRendererPrecacheInput;
  LPlan: TRendererPrecachePlan;
begin
  LInput := Default(TRendererPrecacheInput);
  LInput.TextureCount := 5;
  LInput.SideTextures := [0, 1, 0];
  LInput.ExtraTextures := [4];
  LPlan := FPlanner.Plan(LInput);
  Assert.IsTrue(LPlan.TexturePresent[0]);
  Assert.IsTrue(LPlan.TexturePresent[1]);
  Assert.IsFalse(LPlan.TexturePresent[2]);
  Assert.IsFalse(LPlan.TexturePresent[3]);
  Assert.IsTrue(LPlan.TexturePresent[4]);
end;

procedure TTestRendererPrecachePlan.DovrebbeSegnareGliSpriteDegliOggetti;
var
  LInput: TRendererPrecacheInput;
  LPlan: TRendererPrecachePlan;
begin
  LInput := Default(TRendererPrecacheInput);
  LInput.SpriteCount := 4;
  LInput.ObjectSprites := [3, 3, 1];
  LPlan := FPlanner.Plan(LInput);
  Assert.IsFalse(LPlan.SpritePresent[0]);
  Assert.IsTrue(LPlan.SpritePresent[1]);
  Assert.IsFalse(LPlan.SpritePresent[2]);
  Assert.IsTrue(LPlan.SpritePresent[3]);
end;

procedure TTestRendererPrecachePlan.DovrebbeIgnorareINumeriFuoriDalGioco;
var
  LInput: TRendererPrecacheInput;
  LPlan: TRendererPrecachePlan;
  LIndex: Integer;
begin
  // -1 is the "no texture" of a side of Heretic and Hexen: the old code wrote before the table
  LInput := Default(TRendererPrecacheInput);
  LInput.FlatCount := 2;
  LInput.TextureCount := 2;
  LInput.SpriteCount := 2;
  LInput.SectorFlats := [-1, 2, 99];
  LInput.SideTextures := [-1, 2, 99];
  LInput.ObjectSprites := [-1, 2, 99];
  LPlan := FPlanner.Plan(LInput);
  for LIndex := 0 to 1 do
  begin
    Assert.IsFalse(LPlan.FlatPresent[LIndex]);
    Assert.IsFalse(LPlan.TexturePresent[LIndex]);
    Assert.IsFalse(LPlan.SpritePresent[LIndex]);
  end;
end;

procedure TTestRendererPrecachePlan.DovrebbeFareComeIlVecchioR_PrecacheLevel;
var
  LRound: Integer;
  LInput: TRendererPrecacheInput;
  LPlan: TRendererPrecachePlan;
  LOldFlats, LOldTextures, LOldSprites: TBytes;
  LIndex: Integer;
begin
  RandSeed := 247;
  for LRound := 1 to 300 do
  begin
    LInput := Default(TRendererPrecacheInput);
    LInput.FlatCount := 1 + Random(60);
    LInput.TextureCount := 1 + Random(200);
    LInput.SpriteCount := 1 + Random(100);
    SetLength(LInput.SectorFlats, Random(40) * 2);
    for LIndex := 0 to High(LInput.SectorFlats) do
      LInput.SectorFlats[LIndex] := Random(LInput.FlatCount);
    SetLength(LInput.SideTextures, Random(80) * 3);
    for LIndex := 0 to High(LInput.SideTextures) do
      LInput.SideTextures[LIndex] := Random(LInput.TextureCount);
    SetLength(LInput.ExtraFlats, Random(4));
    for LIndex := 0 to High(LInput.ExtraFlats) do
      LInput.ExtraFlats[LIndex] := Random(LInput.FlatCount);
    SetLength(LInput.ExtraTextures, 1 + Random(4));
    for LIndex := 0 to High(LInput.ExtraTextures) do
      LInput.ExtraTextures[LIndex] := Random(LInput.TextureCount);
    SetLength(LInput.ObjectSprites, Random(50));
    for LIndex := 0 to High(LInput.ObjectSprites) do
      LInput.ObjectSprites[LIndex] := Random(LInput.SpriteCount);

    // the old code: a zeroed byte table for each, a byte set for each number in use
    SetLength(LOldFlats, LInput.FlatCount);
    SetLength(LOldTextures, LInput.TextureCount);
    SetLength(LOldSprites, LInput.SpriteCount);
    for LIndex := 0 to High(LInput.SectorFlats) do
      LOldFlats[LInput.SectorFlats[LIndex]] := 1;
    for LIndex := 0 to High(LInput.ExtraFlats) do
      LOldFlats[LInput.ExtraFlats[LIndex]] := 1;
    for LIndex := 0 to High(LInput.SideTextures) do
      LOldTextures[LInput.SideTextures[LIndex]] := 1;
    for LIndex := 0 to High(LInput.ExtraTextures) do
      LOldTextures[LInput.ExtraTextures[LIndex]] := 1;
    for LIndex := 0 to High(LInput.ObjectSprites) do
      LOldSprites[LInput.ObjectSprites[LIndex]] := 1;

    LPlan := FPlanner.Plan(LInput);
    for LIndex := 0 to LInput.FlatCount - 1 do
      Assert.AreEqual(LOldFlats[LIndex] <> 0, LPlan.FlatPresent[LIndex]);
    for LIndex := 0 to LInput.TextureCount - 1 do
      Assert.AreEqual(LOldTextures[LIndex] <> 0, LPlan.TexturePresent[LIndex]);
    for LIndex := 0 to LInput.SpriteCount - 1 do
      Assert.AreEqual(LOldSprites[LIndex] <> 0, LPlan.SpritePresent[LIndex]);
  end;
end;

end.
