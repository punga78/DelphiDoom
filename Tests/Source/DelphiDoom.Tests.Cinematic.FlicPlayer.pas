{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFlicPlayer (issue #199)                               }
{                                                                              }
{  Three frames of 100 ms each (a FLC with speed 100): frame 0 starts at 0,    }
{  frame 1 at 100, frame 2 at 200, the animation is 300 ms long. The pixel of  }
{  a frame says which one it is (color 1, 2, 3 of the palette, red channel).   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicPlayer;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.Flic.Intf;

type
  [TestFixture]
  [Category('cinematic')]
  TTestFlicPlayer = class(TObject)
  strict private
    function Player(ALooping: Boolean): IFlicPlayer;
    procedure AssertFrame(const AImage: TFlicPlayerImage; AFrame: Integer; AStatus: TFlicPlayerStatus);
  public
    [Test]
    procedure DovrebbeMostrareIlPrimoFotogrammaAlPrimoTempoComunqueSia;
    [Test]
    procedure DovrebbeCambiareFotogrammaQuandoPassaIlRitardo;
    [Test]
    procedure DovrebbeSaltareFotogrammiSeIlTempoVaAvanti;
    [Test]
    procedure DovrebbeFermarsiSullUltimoFotogrammaSenzaCiclo;
    [Test]
    procedure DovrebbeRipartireConIlCiclo;
    [Test]
    procedure DovrebbeRipartireDopoPiuGiriInUnSoloSalto;
    [Test]
    procedure DovrebbeRiavvolgereSeIlTempoTornaIndietro;
    [Test]
    procedure DovrebbeRipartireConResetTime;
    [Test]
    procedure DovrebbeTrattareUnTempoNegativoComeZero;
    [Test]
    procedure DovrebbeSommareIRitardiDiversiDiUnFli;
    [Test]
    procedure DovrebbeDareDimensioniEPixelDelFotogramma;
  end;

implementation

uses
  DelphiDoom.Cinematic.Flic.Types,
  DelphiDoom.Cinematic.Flic.Factory,
  DelphiDoom.Tests.Cinematic.FlicSupport;

{ TTestFlicPlayer }

function TTestFlicPlayer.Player(ALooping: Boolean): IFlicPlayer;
var
  LBuilder: TFlicTestBuilder;
begin
  LBuilder := TFlicTestBuilder.Create(4, 2, False, 100);
  try
    LBuilder.Frame([TFlicTestBuilder.Color256(0, [0, 0, 0, 1, 0, 0, 2, 0, 0, 3, 0, 0]),
      TFlicTestBuilder.ByteRun(4, [1, 1])]);
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [2, 2])]);
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [3, 3])]);
    Result := TFlicFactory.CreatePlayer(TFlicFactory.CreateDecoder(LBuilder.ToBytes), ALooping);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestFlicPlayer.AssertFrame(const AImage: TFlicPlayerImage; AFrame: Integer;
  AStatus: TFlicPlayerStatus);
begin
  Assert.AreEqual(AFrame, AImage.FrameIndex);
  Assert.AreEqual(Ord(AStatus), Ord(AImage.Status));
  // the red channel of the pixel is the color that the frame is made of
  Assert.AreEqual(AFrame + 1, Integer(AImage.Pixels[0] and $FF));
end;

procedure TTestFlicPlayer.DovrebbeMostrareIlPrimoFotogrammaAlPrimoTempoComunqueSia;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(False);
  AssertFrame(LPlayer.ImageForTime(123456), 0, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(123456 + 99), 0, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeCambiareFotogrammaQuandoPassaIlRitardo;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(False);
  LPlayer.ImageForTime(1000);
  AssertFrame(LPlayer.ImageForTime(1100), 1, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(1199), 1, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(1200), 2, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeSaltareFotogrammiSeIlTempoVaAvanti;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(False);
  LPlayer.ImageForTime(1000);
  AssertFrame(LPlayer.ImageForTime(1250), 2, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeFermarsiSullUltimoFotogrammaSenzaCiclo;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(False);
  LPlayer.ImageForTime(1000);
  AssertFrame(LPlayer.ImageForTime(1300), 2, fpsEnded);
  AssertFrame(LPlayer.ImageForTime(5000), 2, fpsEnded);
end;

procedure TTestFlicPlayer.DovrebbeRipartireConIlCiclo;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(True);
  LPlayer.ImageForTime(1000);
  AssertFrame(LPlayer.ImageForTime(1300), 0, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(1450), 1, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeRipartireDopoPiuGiriInUnSoloSalto;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(True);
  LPlayer.ImageForTime(0);
  // 10 turns and 250 ms
  AssertFrame(LPlayer.ImageForTime(3250), 2, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeRiavvolgereSeIlTempoTornaIndietro;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(False);
  LPlayer.ImageForTime(1000);
  AssertFrame(LPlayer.ImageForTime(1250), 2, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(1110), 1, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(1010), 0, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeRipartireConResetTime;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(False);
  LPlayer.ImageForTime(1000);
  AssertFrame(LPlayer.ImageForTime(1500), 2, fpsEnded);
  LPlayer.ResetTime;
  AssertFrame(LPlayer.ImageForTime(9000), 0, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(9100), 1, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeTrattareUnTempoNegativoComeZero;
var
  LPlayer: IFlicPlayer;
begin
  LPlayer := Player(False);
  AssertFrame(LPlayer.ImageForTime(-500), 0, fpsPlaying);
  AssertFrame(LPlayer.ImageForTime(100), 1, fpsPlaying);
end;

procedure TTestFlicPlayer.DovrebbeSommareIRitardiDiversiDiUnFli;
var
  LBuilder: TFlicTestBuilder;
  LPlayer: IFlicPlayer;
begin
  LBuilder := TFlicTestBuilder.Create(4, 2, True, 70);
  try
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [1, 1])], 10);
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [2, 2])], 50);
    LBuilder.Frame([TFlicTestBuilder.ByteRun(4, [3, 3])]);
    LPlayer := TFlicFactory.CreatePlayer(TFlicFactory.CreateDecoder(LBuilder.ToBytes), False);
  finally
    LBuilder.Free;
  end;
  LPlayer.ImageForTime(0);
  // frame 0: 0..9, frame 1: 10..59, frame 2 (speed 70: 1000 ms): 60..1059
  Assert.AreEqual(0, LPlayer.ImageForTime(9).FrameIndex);
  Assert.AreEqual(1, LPlayer.ImageForTime(10).FrameIndex);
  Assert.AreEqual(1, LPlayer.ImageForTime(59).FrameIndex);
  Assert.AreEqual(2, LPlayer.ImageForTime(60).FrameIndex);
end;

procedure TTestFlicPlayer.DovrebbeDareDimensioniEPixelDelFotogramma;
var
  LImage: TFlicPlayerImage;
begin
  LImage := Player(False).ImageForTime(0);
  Assert.AreEqual(4, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  Assert.AreEqual<Integer>(8, Length(LImage.Pixels));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFlicPlayer);

end.
