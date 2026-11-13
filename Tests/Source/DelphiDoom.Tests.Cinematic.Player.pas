{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqPlayer                                             }
{                                                                              }
{  The time is a number that the test gives: nothing reads a clock.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.Player;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  DelphiDoom.Cinematic.Intf;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqPlayer = class(TObject)
  strict private
    FFrameCrc: array[0..3] of Cardinal;
    function FourFrames: TBytes;
    function NewPlayer(ALooping: Boolean): IRoqPlayer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeMostrareIlPrimoFotogrammaAlPrimoTempo;
    [Test]
    procedure DovrebbeAvanzareUnFotogrammaOgniCentoMillisecondiADieciFps;
    [Test]
    procedure DovrebbeMisurareIlTempoDalPrimoRichiamo;
    [Test]
    procedure DovrebbeTenereLUltimoFotogrammaESegnareLaFine;
    [Test]
    procedure DovrebbeRiavvolgereSeIlTempoTornaIndietro;
    [Test]
    procedure DovrebbeRicominciareInCicloDopoLUltimoFotogramma;
    [Test]
    procedure DovrebbeTrattareIlTempoNegativoComeZero;
    [Test]
    procedure DovrebbeRipartireConResetTime;
    [Test]
    procedure DovrebbeDareUnaImmagineVuotaSeNonCiSonoFotogrammi;
    [Test]
    procedure DovrebbeDareLeDimensioniDelVideo;
  end;

implementation

uses
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Factory,
  DelphiDoom.Tests.Cinematic.Support;

{ TTestRoqPlayer }

function TTestRoqPlayer.FourFrames: TBytes;
var
  LBuilder: TRoqTestBuilder;
  LIndex: Integer;
begin
  LBuilder := TRoqTestBuilder.Create(10);
  try
    LBuilder.Info(16, 16);
    LBuilder.Codebook(4, 2);
    for LIndex := 0 to 3 do
      LBuilder.FullFrame16(LIndex and 1);
    Result := LBuilder.ToBytes;
  finally
    LBuilder.Free;
  end;
end;

function TTestRoqPlayer.NewPlayer(ALooping: Boolean): IRoqPlayer;
begin
  Result := TCinematicFactory.CreatePlayer(
    TCinematicFactory.CreateDecoder(TCinematicFactory.CreateMemorySource(FourFrames), nil),
    ALooping);
end;

procedure TTestRoqPlayer.Setup;
var
  LDecoder: IRoqDecoder;
  LIndex: Integer;
begin
  LDecoder := TCinematicFactory.CreateDecoder(
    TCinematicFactory.CreateMemorySource(FourFrames), nil);
  for LIndex := 0 to 3 do
  begin
    LDecoder.NextFrame;
    FFrameCrc[LIndex] := PixelsCrc(LDecoder.Frame);
  end;
end;

procedure TTestRoqPlayer.DovrebbeMostrareIlPrimoFotogrammaAlPrimoTempo;
var
  LImage: TRoqPlayerImage;
begin
  LImage := NewPlayer(False).ImageForTime(5000);
  Assert.AreEqual(0, LImage.FrameIndex);
  Assert.AreEqual(Ord(rpsPlaying), Ord(LImage.Status));
  Assert.AreEqual(FFrameCrc[0], PixelsCrc(LImage.Pixels));
end;

procedure TTestRoqPlayer.DovrebbeAvanzareUnFotogrammaOgniCentoMillisecondiADieciFps;
var
  LPlayer: IRoqPlayer;
begin
  LPlayer := NewPlayer(False);
  Assert.AreEqual(0, LPlayer.ImageForTime(1000).FrameIndex);
  Assert.AreEqual(0, LPlayer.ImageForTime(1099).FrameIndex);
  Assert.AreEqual(1, LPlayer.ImageForTime(1100).FrameIndex);
  Assert.AreEqual(2, LPlayer.ImageForTime(1250).FrameIndex);
  Assert.AreEqual(FFrameCrc[3], PixelsCrc(LPlayer.ImageForTime(1300).Pixels));
end;

procedure TTestRoqPlayer.DovrebbeMisurareIlTempoDalPrimoRichiamo;
var
  LPlayer: IRoqPlayer;
begin
  LPlayer := NewPlayer(False);
  // the first call is the start, whatever the number is
  Assert.AreEqual(0, LPlayer.ImageForTime(123456).FrameIndex);
  Assert.AreEqual(1, LPlayer.ImageForTime(123556).FrameIndex);
end;

procedure TTestRoqPlayer.DovrebbeTenereLUltimoFotogrammaESegnareLaFine;
var
  LPlayer: IRoqPlayer;
  LImage: TRoqPlayerImage;
begin
  LPlayer := NewPlayer(False);
  LPlayer.ImageForTime(0);
  LImage := LPlayer.ImageForTime(300);
  Assert.AreEqual(3, LImage.FrameIndex);
  Assert.AreEqual(Ord(rpsPlaying), Ord(LImage.Status));
  LImage := LPlayer.ImageForTime(10000);
  Assert.AreEqual(3, LImage.FrameIndex);
  Assert.AreEqual(Ord(rpsEnded), Ord(LImage.Status));
  Assert.AreEqual(FFrameCrc[3], PixelsCrc(LImage.Pixels));
  // it stays so
  Assert.AreEqual(Ord(rpsEnded), Ord(LPlayer.ImageForTime(20000).Status));
end;

procedure TTestRoqPlayer.DovrebbeRiavvolgereSeIlTempoTornaIndietro;
var
  LPlayer: IRoqPlayer;
  LImage: TRoqPlayerImage;
begin
  LPlayer := NewPlayer(False);
  LPlayer.ImageForTime(0);
  LPlayer.ImageForTime(300);
  LImage := LPlayer.ImageForTime(100);
  Assert.AreEqual(1, LImage.FrameIndex);
  Assert.AreEqual(FFrameCrc[1], PixelsCrc(LImage.Pixels));
end;

procedure TTestRoqPlayer.DovrebbeRicominciareInCicloDopoLUltimoFotogramma;
var
  LPlayer: IRoqPlayer;
  LImage: TRoqPlayerImage;
begin
  LPlayer := NewPlayer(True);
  LPlayer.ImageForTime(0);
  LPlayer.ImageForTime(300);
  LImage := LPlayer.ImageForTime(400);
  Assert.AreEqual(0, LImage.FrameIndex);
  Assert.AreEqual(Ord(rpsPlaying), Ord(LImage.Status));
  // the new start is the time of the call that restarted it
  Assert.AreEqual(1, LPlayer.ImageForTime(500).FrameIndex);
end;

procedure TTestRoqPlayer.DovrebbeTrattareIlTempoNegativoComeZero;
var
  LPlayer: IRoqPlayer;
begin
  LPlayer := NewPlayer(False);
  Assert.AreEqual(0, LPlayer.ImageForTime(-50).FrameIndex);
  Assert.AreEqual(1, LPlayer.ImageForTime(100).FrameIndex);
end;

procedure TTestRoqPlayer.DovrebbeRipartireConResetTime;
var
  LPlayer: IRoqPlayer;
begin
  LPlayer := NewPlayer(False);
  LPlayer.ImageForTime(0);
  Assert.AreEqual(Ord(rpsEnded), Ord(LPlayer.ImageForTime(10000).Status));
  LPlayer.ResetTime;
  Assert.AreEqual(0, LPlayer.ImageForTime(50000).FrameIndex);
  Assert.AreEqual(Ord(rpsPlaying), Ord(LPlayer.ImageForTime(50000).Status));
end;

procedure TTestRoqPlayer.DovrebbeDareUnaImmagineVuotaSeNonCiSonoFotogrammi;
var
  LBuilder: TRoqTestBuilder;
  LPlayer: IRoqPlayer;
  LImage: TRoqPlayerImage;
begin
  LBuilder := TRoqTestBuilder.Create;
  try
    LPlayer := TCinematicFactory.CreatePlayer(TCinematicFactory.CreateDecoder(
      TCinematicFactory.CreateMemorySource(LBuilder.ToBytes), nil), False);
  finally
    LBuilder.Free;
  end;
  LImage := LPlayer.ImageForTime(0);
  Assert.AreEqual(-1, LImage.FrameIndex);
  Assert.AreEqual(Ord(rpsEnded), Ord(LImage.Status));
  Assert.AreEqual(0, Length(LImage.Pixels));
end;

procedure TTestRoqPlayer.DovrebbeDareLeDimensioniDelVideo;
var
  LImage: TRoqPlayerImage;
begin
  LImage := NewPlayer(False).ImageForTime(0);
  Assert.AreEqual(16, LImage.Width);
  Assert.AreEqual(16, LImage.Height);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqPlayer);

end.
