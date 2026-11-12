{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the fallback of Text to the pictures of the game   }
{  when a big font that got the characters of a font of the system no longer    }
{  fits (issue 184: the time buttons of the geoscape)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.TextOriginal;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomEngine.State,
  DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>
  ///   The big font of the fake resources has characters 6 pixels wide (7 with the spacing). Widen lays over it,
  ///   as a font of the system would, pictures 12 pixels wide (13 with the spacing) for the letters A to F
  /// </summary>
  [TestFixture]
  [Category('XcomUi')]
  TTestXcomTextOriginal = class
  strict private
    FWorld: TTestWorld;
    FText: TXcomText;
    function Big: TXcomFont;
    function Small: TXcomFont;
    procedure Widen;
    function NewText(AWidth, AHeight: Integer): TXcomText;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnTestoCheEntraDovrebbeUsareIlFontNuovo;
    [Test]
    procedure UnTestoCheNonEntraPiuDovrebbeUsareLeImmaginiDelGioco;
    [Test]
    procedure UnTestoCheNonEntraNemmenoConLeImmaginiDovrebbePassareAlFontPiccolo;
    [Test]
    procedure SenzaOriginaleDovrebbePassareAlFontPiccoloComeOpenXcom;
    [Test]
    procedure UnTestoCheFinisceConUnPuntoDovrebbeRestareColFontNuovo;
    [Test]
    procedure IlTestoSuccessivoDovrebbeRipartireDalFontNuovo;
    [Test]
    procedure IlPulsanteDovrebbeDisegnareIlTestoConLeImmaginiDelGioco;
  end;

implementation

type
  TFlatState = class(TXcomState)
  end;

procedure TTestXcomTextOriginal.Setup;
begin
  FWorld := TTestWorld.Create;
end;

procedure TTestXcomTextOriginal.TearDown;
begin
  FreeAndNil(FText);
  FWorld.Free;
end;

function TTestXcomTextOriginal.Big: TXcomFont;
begin
  Result := FWorld.Resources.GetFont('FONT_BIG');
end;

function TTestXcomTextOriginal.Small: TXcomFont;
begin
  Result := FWorld.Resources.GetFont('FONT_SMALL');
end;

procedure TTestXcomTextOriginal.Widen;
var
  LSurface: TXcomSurface;
  LCell: Integer;
  LX: Integer;
  LY: Integer;
begin
  Big.KeepOriginal;
  LSurface := TXcomSurface.Create(14 * 6, 10);
  for LCell := 0 to 5 do
    for LY := 1 to 8 do
      for LX := 0 to 11 do
        LSurface.SetPixel(LCell * 14 + LX, LY, 1);
  Big.Init(Big.AddImage(14, 10, 1, LSurface), TXcomFont.CodePoints('ABCDEF'));
end;

function TTestXcomTextOriginal.NewText(AWidth, AHeight: Integer): TXcomText;
begin
  FreeAndNil(FText);
  FText := TXcomText.Create(AWidth, AHeight, 0, 0);
  FText.InitText(Big, Small, FWorld.Game.Language);
  FText.SetBig;
  Result := FText;
end;

procedure TTestXcomTextOriginal.UnTestoCheEntraDovrebbeUsareIlFontNuovo;
begin
  Widen;
  NewText(60, 12).SetText('ABCD');
  Assert.IsTrue(FText.GetFont = Big);
  Assert.AreEqual(4 * 13, FText.GetTextWidth);
end;

procedure TTestXcomTextOriginal.UnTestoCheNonEntraPiuDovrebbeUsareLeImmaginiDelGioco;
begin
  Widen;
  // 5 * 13 = 65 does not fit in 40, the 5 * 7 = 35 of the pictures of the game do
  NewText(40, 12).SetText('ABCDE');
  Assert.IsTrue(FText.GetFont = Big.Original);
  Assert.AreEqual(5 * 7, FText.GetTextWidth);
  FText.Blit(FWorld.Game.Screen.GetSurface);
  // the picture of the game: its characters start at the column 1 of the cell and end at the 6
  Assert.AreNotEqual(0, Integer(FText.GetPixel(0, 1)));
  Assert.AreEqual(0, Integer(FText.GetPixel(6, 1)));
  Assert.AreNotEqual(0, Integer(FText.GetPixel(7, 1)));
end;

procedure TTestXcomTextOriginal.UnTestoCheNonEntraNemmenoConLeImmaginiDovrebbePassareAlFontPiccolo;
begin
  Widen;
  NewText(30, 12).SetText('ABCDE');
  Assert.IsTrue(FText.GetFont = Small);
end;

procedure TTestXcomTextOriginal.SenzaOriginaleDovrebbePassareAlFontPiccoloComeOpenXcom;
begin
  NewText(30, 12).SetText('ABCDE');
  Assert.IsTrue(Big.Original = nil);
  Assert.IsTrue(FText.GetFont = Small);
  NewText(40, 12).SetText('ABCDE');
  Assert.IsTrue(FText.GetFont = Big);
end;

procedure TTestXcomTextOriginal.UnTestoCheFinisceConUnPuntoDovrebbeRestareColFontNuovo;
begin
  Widen;
  NewText(40, 12).SetText('ABCDE.');
  Assert.IsTrue(FText.GetFont = Big);
end;

procedure TTestXcomTextOriginal.IlTestoSuccessivoDovrebbeRipartireDalFontNuovo;
begin
  Widen;
  NewText(40, 12).SetText('ABCDE');
  Assert.IsTrue(FText.GetFont = Big.Original);
  FText.SetText('AB');
  Assert.IsTrue(FText.GetFont = Big);
end;

procedure TTestXcomTextOriginal.IlPulsanteDovrebbeDisegnareIlTestoConLeImmaginiDelGioco;
var
  LState: TXcomState;
  LButton: TXcomTextButton;
begin
  Widen;
  LState := TFlatState.Create(FWorld.Game);
  try
    // a time button of the geoscape: a big text with word wrap in a small button
    LButton := TXcomTextButton.Create(40, 14, 0, 0);
    LState.Add(LButton);
    LButton.SetBig;
    LButton.SetText('ABCDE');
    Assert.IsTrue(LButton.GetFont = Big.Original);
  finally
    LState.Free;
  end;
end;

end.
