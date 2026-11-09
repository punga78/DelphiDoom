{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSongSelector                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.SongSelector;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.SongSelector;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSongSelector = class(TObject)
  public
    [TestCase('mappa 0', '0,SONG0.S3M,0')]
    [TestCase('mappa 4', '4,SONG0.S3M,73')]
    [TestCase('mappa 9', '9,SONG2.S3M,83')]
    [TestCase('mappa 14', '14,SONG3.S3M,94')]
    [TestCase('mappa 17', '17,SONG1.S3M,45')]
    [TestCase('mappa 20', '20,SONG4.S3M,21')]
    [TestCase('mappa 21', '21,SONG8.MOD,0')]
    [TestCase('mappa 22 da soli', '22,ENDING.MOD,0')]
    [TestCase('mappa 26', '26,SONG4.S3M,33')]
    [TestCase('mappa 31', '31,SONG13.MOD,0')]
    [TestCase('mappa 99', '99,PROBE.MOD,0')]
    [TestCase('mappa sconosciuta', '50,SONG0.S3M,0')]
    [TestCase('mappa negativa', '-3,SONG0.S3M,0')]
    procedure DovrebbeDareIlBranoDellaMappa(AMap: Integer; const AFile: string; APattern: Integer);
    [Test]
    procedure DovrebbeUsareIlBranoDiReteNellaMappaFinale;
    [Test]
    procedure DovrebbeRipetereICinqueBraniNellaDemo;
  end;

implementation

{ TTestGreedSongSelector }

procedure TTestGreedSongSelector.DovrebbeDareIlBranoDellaMappa(AMap: Integer; const AFile: string;
  APattern: Integer);
var
  LSong: TGreedSong;
begin
  LSong := TGreedSongSelector.Select(AMap, False, False);
  Assert.AreEqual(AFile, LSong.FileName);
  Assert.AreEqual(APattern, LSong.Pattern);
end;

procedure TTestGreedSongSelector.DovrebbeUsareIlBranoDiReteNellaMappaFinale;
begin
  Assert.AreEqual('SONG14.MOD', TGreedSongSelector.Select(22, False, True).FileName);
  Assert.AreEqual('ENDING.MOD', TGreedSongSelector.Select(22, False, False).FileName);
end;

procedure TTestGreedSongSelector.DovrebbeRipetereICinqueBraniNellaDemo;
begin
  // 7 mod 5 = 2: the third song of SONG0
  Assert.AreEqual(37, TGreedSongSelector.Select(7, True, False).Pattern);
  Assert.AreEqual(73, TGreedSongSelector.Select(9, True, False).Pattern);
  // 99 mod 5 = 4: the demo does not play PROBE.MOD
  Assert.AreEqual('SONG0.S3M', TGreedSongSelector.Select(99, True, False).FileName);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedSongSelector);

end.
