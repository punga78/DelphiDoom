{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TVoxelEditorPalettes (issue #167)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.VoxelEditor.Palettes;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.VoxelEditor.Types;

type
  [TestFixture]
  [Category('voxeleditor')]
  TTestVoxelEditorPalettes = class(TObject)
  public
    [Test]
    procedure DovrebbeFareIlColoreDiWindows;
    [Test]
    procedure DovrebbeTrovareIlColoreEsatto;
    [Test]
    procedure DovrebbeTrovareIlPiuVicino;
    [Test]
    procedure DovrebbeDareIlPrimoSeDueSonoUguali;
    [Test]
    procedure DovrebbeCercareSoloTraDueIndici;
    [Test]
    procedure DovrebbeDareLaScalaDiGrigi;
    [Test]
    procedure DovrebbeDareLePalettedeiGiochi;
    [Test]
    procedure DovrebbeLeggereUnaPalettaDaUnFile;
    [Test]
    procedure DovrebbeDareLaScalaDiGrigiPerUnFileCheNonVa;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Palettes;

procedure TTestVoxelEditorPalettes.DovrebbeFareIlColoreDiWindows;
begin
  Assert.AreEqual(Cardinal($332211), TVoxelEditorPalettes.Rgb($11, $22, $33));
  Assert.AreEqual(Cardinal($FFFFFF), TVoxelEditorPalettes.Rgb(255, 255, 255));
end;

procedure TTestVoxelEditorPalettes.DovrebbeTrovareIlColoreEsatto;
begin
  Assert.AreEqual(77, TVoxelEditorPalettes.FindApproximateIndex(TVoxelEditorPalettes.Gray, $4D4D4D));
end;

procedure TTestVoxelEditorPalettes.DovrebbeTrovareIlPiuVicino;
begin
  Assert.AreEqual(100, TVoxelEditorPalettes.FindApproximateIndex(TVoxelEditorPalettes.Gray, $656463));
  Assert.AreEqual(255, TVoxelEditorPalettes.FindApproximateIndex(TVoxelEditorPalettes.Gray, $FFFFFF));
end;

procedure TTestVoxelEditorPalettes.DovrebbeDareIlPrimoSeDueSonoUguali;
var
  LPalette: TVoxelEditorPalette;
begin
  LPalette := TVoxelEditorPalettes.Gray;
  LPalette[200] := LPalette[10];
  Assert.AreEqual(10, TVoxelEditorPalettes.FindApproximateIndex(LPalette, $0A0A0A));
  // the colors 0 and 2 are both at distance 1 from the color 1: the first one is kept
  LPalette := TVoxelEditorPalettes.Gray;
  LPalette[1] := 2;
  Assert.AreEqual(0, TVoxelEditorPalettes.FindApproximateIndex(LPalette, 1));
end;

procedure TTestVoxelEditorPalettes.DovrebbeCercareSoloTraDueIndici;
begin
  Assert.AreEqual(50, TVoxelEditorPalettes.FindApproximateIndex(TVoxelEditorPalettes.Gray, $FFFFFF, 20, 50));
  Assert.AreEqual(20, TVoxelEditorPalettes.FindApproximateIndex(TVoxelEditorPalettes.Gray, $000000, 20, 50));
end;

procedure TTestVoxelEditorPalettes.DovrebbeDareLaScalaDiGrigi;
begin
  Assert.AreEqual(Cardinal(0), TVoxelEditorPalettes.Gray[0]);
  Assert.AreEqual(Cardinal($808080), TVoxelEditorPalettes.Gray[128]);
  Assert.AreEqual(Cardinal($FFFFFF), TVoxelEditorPalettes.Gray[255]);
end;

procedure TTestVoxelEditorPalettes.DovrebbeDareLePalettedeiGiochi;
var
  LKind: TVoxelEditorPaletteKind;
  LPalette: TVoxelEditorPalette;
begin
  for LKind := vepDoom to vepRadix do
  begin
    LPalette := TVoxelEditorPalettes.OfGame(LKind);
    Assert.AreNotEqual(LPalette[1], LPalette[255]);
  end;
  Assert.AreEqual(Cardinal(0), TVoxelEditorPalettes.OfGame(vepDoom)[0]);
  // the octree and a file are not games: the gray ramp
  Assert.AreEqual(Cardinal($808080), TVoxelEditorPalettes.OfGame(vepOctree)[128]);
  Assert.AreEqual(Cardinal($808080), TVoxelEditorPalettes.OfGame(vepFile)[128]);
  // the second color of Doom is 1F 17 0B (R, G, B): a Windows color has the red in the low byte
  Assert.AreEqual(Cardinal($0B171F), TVoxelEditorPalettes.OfGame(vepDoom)[1]);
end;

procedure TTestVoxelEditorPalettes.DovrebbeLeggereUnaPalettaDaUnFile;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, 768);
  for LIndex := 0 to 255 do
  begin
    LBytes[LIndex * 3] := LIndex;
    LBytes[LIndex * 3 + 1] := 255 - LIndex;
    LBytes[LIndex * 3 + 2] := 7;
  end;
  Assert.AreEqual(Cardinal($07F50A), TVoxelEditorPalettes.FromFileBytes(LBytes)[10]);
  SetLength(LBytes, 1024);
  PCardinal(@LBytes[4 * 3])^ := $01020304;
  Assert.AreEqual(Cardinal($020304), TVoxelEditorPalettes.FromFileBytes(LBytes)[3]);
end;

procedure TTestVoxelEditorPalettes.DovrebbeDareLaScalaDiGrigiPerUnFileCheNonVa;
begin
  Assert.AreEqual(Cardinal($808080), TVoxelEditorPalettes.FromFileBytes(nil)[128]);
  Assert.AreEqual(Cardinal($808080), TVoxelEditorPalettes.FromFileBytes(TBytes.Create(1, 2, 3))[128]);
end;

end.
