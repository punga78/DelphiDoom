{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III sprite, text, fog and light functions    }
{                                                                              }
{  The cases that the golden of the C (q3calc-quads) does not have: errors     }
{  where the original reads past a buffer, and values worked out by hand.      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Q3ShaderSprites;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Decl.Q3Shader.Calc.Types;

type
  [TestFixture]
  [Category('Decl')]
  TTestQ3ShaderSprites = class
  strict private
    FTess: TQ3ShaderTess;
    procedure Buffers(AVertexes: Integer);
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeRifiutareUnQuadFuoriDalBuffer;
    [Test]
    procedure DovrebbeAggiungereUnQuadConGliIndiciDelC;
    [Test]
    procedure DovrebbeRifiutareUnAutospriteSenzaEntita;
    [Test]
    procedure DovrebbeRifiutareUnAutospriteConVertexNonMultipliDiQuattro;
    [Test]
    procedure DovrebbeSaltareGliSpaziNelTesto;
    [Test]
    procedure DovrebbeRifiutareLaNebbiaChePerIlMondoNonEsiste;
    [Test]
    procedure DovrebbeDareLaTabellaDellaNebbiaCheVaDaZeroAUno;
    [Test]
    procedure DovrebbeRifiutareUnaCoordinataDiNebbiaNan;
    [Test]
    procedure DovrebbeDareAlphaZeroAlSpecularDiUnVertexDietro;
    [Test]
    procedure DovrebbeUsareLAmbienteSeLaLuceNonArriva;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Decl.Q3Shader.Calc.QuadStamp, DelphiDoom.Decl.Q3Shader.Calc.SpriteDeform,
  DelphiDoom.Decl.Q3Shader.Calc.FogCalc, DelphiDoom.Decl.Q3Shader.Calc.LightCalc;

procedure TTestQ3ShaderSprites.Buffers(AVertexes: Integer);
begin
  SetLength(FTess.Xyz, AVertexes * 4);
  SetLength(FTess.Normal, AVertexes * 4);
  SetLength(FTess.TexCoords, AVertexes * 4);
  SetLength(FTess.VertexColors, AVertexes * 4);
  SetLength(FTess.Indexes, AVertexes * 3);
end;

procedure TTestQ3ShaderSprites.Setup;
begin
  Finalize(FTess);
  FillChar(FTess, SizeOf(FTess), 0);
  FTess.View.Axis[0][0] := 1;
  FTess.View.Axis[1][1] := 1;
  FTess.View.Axis[2][2] := 1;
end;

procedure TTestQ3ShaderSprites.DovrebbeRifiutareUnQuadFuoriDalBuffer;
var
  LZero: TQ3Vec3;
begin
  FillChar(LZero, SizeOf(LZero), 0);
  Buffers(3);
  Assert.WillRaise(
    procedure
    begin
      TQ3QuadStamp.Add(FTess, LZero, LZero, LZero, 0);
    end, EDeclQ3ShaderCalcException);
end;

procedure TTestQ3ShaderSprites.DovrebbeAggiungereUnQuadConGliIndiciDelC;
var
  LOrigin, LLeft, LUp: TQ3Vec3;
begin
  Buffers(8);
  LOrigin[0] := 10;
  LOrigin[1] := 20;
  LOrigin[2] := 30;
  LLeft[0] := 0;
  LLeft[1] := 1;
  LLeft[2] := 0;
  LUp[0] := 0;
  LUp[1] := 0;
  LUp[2] := 2;
  TQ3QuadStamp.Add(FTess, LOrigin, LLeft, LUp, $04030201);
  Assert.AreEqual(4, FTess.NumVertexes);
  Assert.AreEqual(6, FTess.NumIndexes);
  Assert.AreEqual<Integer>(3, FTess.Indexes[2]);
  Assert.AreEqual<Integer>(2, FTess.Indexes[5]);
  Assert.AreEqual(Double(21), Double(FTess.Xyz[1]));
  Assert.AreEqual(Double(32), Double(FTess.Xyz[2]));
  Assert.AreEqual(Double(19), Double(FTess.Xyz[2 * 4 + 1]));
  Assert.AreEqual(Double(-1), Double(FTess.Normal[0]));
  Assert.AreEqual<Integer>(1, FTess.VertexColors[0]);
  Assert.AreEqual<Integer>(4, FTess.VertexColors[15]);
end;

procedure TTestQ3ShaderSprites.DovrebbeRifiutareUnAutospriteSenzaEntita;
begin
  Buffers(4);
  FTess.NumVertexes := 4;
  Assert.WillRaise(
    procedure
    begin
      TQ3SpriteDeform.AutoSprite(FTess);
    end, EDeclQ3ShaderCalcException);
end;

procedure TTestQ3ShaderSprites.DovrebbeRifiutareUnAutospriteConVertexNonMultipliDiQuattro;
begin
  Buffers(8);
  FTess.NumVertexes := 5;
  FTess.Entity.Present := True;
  Assert.WillRaise(
    procedure
    begin
      TQ3SpriteDeform.AutoSprite2(FTess);
    end, EDeclQ3ShaderCalcException);
end;

procedure TTestQ3ShaderSprites.DovrebbeSaltareGliSpaziNelTesto;
begin
  Buffers(40);
  FTess.NumVertexes := 4;
  FTess.Normal[0] := 1;
  FTess.Xyz[2] := 0;
  FTess.Xyz[4 + 2] := 8;
  TQ3SpriteDeform.DeformText(FTess, 'a b c');
  // three characters, one quad each: the spaces draw nothing
  Assert.AreEqual(12, FTess.NumVertexes);
  Assert.AreEqual(18, FTess.NumIndexes);
end;

procedure TTestQ3ShaderSprites.DovrebbeRifiutareLaNebbiaChePerIlMondoNonEsiste;
var
  LFog: TQ3FogCalc;
  LTexCoords: TArray<Single>;
begin
  LFog := TQ3FogCalc.Create;
  try
    Buffers(4);
    FTess.NumVertexes := 1;
    FTess.FogNumber := 3;
    Assert.WillRaise(
      procedure
      begin
        LFog.CalcFogTexCoords(FTess, LTexCoords);
      end, EDeclQ3ShaderCalcException);
  finally
    LFog.Free;
  end;
end;

procedure TTestQ3ShaderSprites.DovrebbeDareLaTabellaDellaNebbiaCheVaDaZeroAUno;
var
  LFog: TQ3FogCalc;
begin
  LFog := TQ3FogCalc.Create;
  try
    Assert.AreEqual(Double(0), Double(LFog.TableValue(0)));
    Assert.AreEqual(Double(1), Double(LFog.TableValue(Q3_FOG_TABLE_SIZE - 1)));
    // no density before the first texel, and none for a point outside (t under 1/32)
    Assert.AreEqual(Double(0), Double(LFog.FogFactor(0, 0.5)));
    Assert.AreEqual(Double(0), Double(LFog.FogFactor(0.5, 0)));
    Assert.AreEqual(Double(1), Double(LFog.FogFactor(5, 1)));
  finally
    LFog.Free;
  end;
end;

procedure TTestQ3ShaderSprites.DovrebbeRifiutareUnaCoordinataDiNebbiaNan;
var
  LFog: TQ3FogCalc;
  LNan: Single;
begin
  LFog := TQ3FogCalc.Create;
  try
    // the original indexes fogTable[INT_MIN] here; it is an error
    PCardinal(@LNan)^ := $7FC00000;
    Assert.WillRaise(
      procedure
      begin
        LFog.FogFactor(LNan, 1);
      end, EDeclQ3ShaderCalcException);
  finally
    LFog.Free;
  end;
end;

procedure TTestQ3ShaderSprites.DovrebbeDareAlphaZeroAlSpecularDiUnVertexDietro;
var
  LColors: TBytes;
begin
  Buffers(1);
  FTess.NumVertexes := 1;
  // the light is at (-960, 1980, 96), the viewer at the origin, so the reflected ray points away from the viewer
  FTess.Xyz[0] := 0;
  FTess.Xyz[1] := 0;
  FTess.Xyz[2] := 0;
  FTess.Normal[0] := 0;
  FTess.Normal[1] := -1;
  FTess.Normal[2] := 0;
  FTess.ViewOrigin[0] := -1000;
  SetLength(LColors, 4);
  LColors[0] := 9;
  LColors[3] := 77;
  TQ3LightCalc.CalcSpecularAlpha(FTess, LColors);
  Assert.AreEqual<Integer>(9, LColors[0]);
  Assert.AreEqual<Integer>(0, LColors[3]);
end;

procedure TTestQ3ShaderSprites.DovrebbeUsareLAmbienteSeLaLuceNonArriva;
var
  LColors: TBytes;
begin
  Buffers(1);
  FTess.NumVertexes := 1;
  FTess.Normal[2] := -1;
  FTess.Entity.Present := True;
  FTess.Entity.LightDirection[2] := 1;
  FTess.Entity.AmbientLightInt := $FF402010;
  SetLength(LColors, 4);
  TQ3LightCalc.CalcDiffuseColor(FTess, LColors);
  Assert.AreEqual<Integer>($10, LColors[0]);
  Assert.AreEqual<Integer>($FF, LColors[3]);
end;

end.
