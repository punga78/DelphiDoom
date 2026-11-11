{******************************************************************************}
{                                                                              }
{  DelphiDoom: test of TXcomFlcDecoder against the real FlcPlayer of OpenXcom   }
{  (Tools\Verifica\176\battle\flcgen.cpp): the pixels and the palette of every  }
{  frame of the introduction of UFO (skipped when the game data is not there)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.RealFlc;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types,
  DelphiDoom.Xcom.FlcDecoder;

type
  [TestFixture]
  [Category('XcomRealData')]
  TTestXcomRealFlc = class
  strict private
    FGoldenFolder: string;
    FUfoFolder: string;
    class function Fingerprint(const ABytes: TBytes; ACount: Integer): string; static;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure OgniFotogrammaDellIntroduzioneDiUfoEQuelloDelVeroFlcPlayer;
  end;

implementation

const
  SCREEN_WIDTH = 320;
  SCREEN_HEIGHT = 200;

procedure TTestXcomRealFlc.Setup;
var
  LFolder: string;
  LReference: string;
begin
  FGoldenFolder := '';
  LReference := '';
  LFolder := ExtractFilePath(ParamStr(0));
  while LFolder <> '' do
  begin
    if (FGoldenFolder = '') and TDirectory.Exists(TPath.Combine(LFolder, 'Tests\Data\XcomEngine\flc')) then
      FGoldenFolder := TPath.Combine(LFolder, 'Tests\Data\XcomEngine\flc');
    if (LReference = '') and TDirectory.Exists(TPath.Combine(LFolder, 'Reference\_dati')) then
      LReference := TPath.Combine(LFolder, 'Reference');
    if LFolder = ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder)) then
      Break;
    LFolder := ExtractFilePath(ExcludeTrailingPathDelimiter(LFolder));
  end;
  FUfoFolder := '';
  if LReference <> '' then
  begin
    FUfoFolder := TPath.Combine(LReference, '_dati\xcom_ufo\UFO Enemy Unkown\DOS game');
    if not TFile.Exists(TPath.Combine(FUfoFolder, 'UFOINTRO\UFOINT.FLI')) then
      FUfoFolder := '';
  end;
end;

class function TTestXcomRealFlc.Fingerprint(const ABytes: TBytes; ACount: Integer): string;
var
  LHash: UInt64;
  LIndex: Integer;
begin
  LHash := UInt64($CBF29CE484222325);
  for LIndex := 0 to ACount - 1 do
    LHash := (LHash xor UInt64(ABytes[LIndex])) * UInt64($100000001B3);
  Result := IntToHex(Int64(LHash), 16);
end;

procedure TTestXcomRealFlc.OgniFotogrammaDellIntroduzioneDiUfoEQuelloDelVeroFlcPlayer;
var
  LGolden: TStringList;
  LDecoder: TXcomFlcDecoder;
  LScreen: TBytes;
  LPalette: TBytes;
  LParts: TArray<string>;
  LLine: Integer;
  LFrames: Integer;
  LOffset: Integer;
begin
  if (FUfoFolder = '') or (FGoldenFolder = '') then
  begin
    Assert.Pass('i dati di UFO non ci sono: test saltato');
    Exit;
  end;
  SetLength(LScreen, SCREEN_WIDTH * SCREEN_HEIGHT);
  FillChar(LScreen[0], Length(LScreen), 0);
  SetLength(LPalette, 256 * 3);
  FillChar(LPalette[0], Length(LPalette), 0);
  LGolden := TStringList.Create;
  LDecoder := TXcomFlcDecoder.Create(TFile.ReadAllBytes(TPath.Combine(FUfoFolder, 'UFOINTRO\UFOINT.FLI')));
  try
    LGolden.LoadFromFile(TPath.Combine(FGoldenFolder, 'ufoint.txt'));
    LDecoder.OnPalette :=
      procedure(AFirst, ACount: Integer)
      var
        LIndex: Integer;
        LColor: TXcomColor;
      begin
        for LIndex := AFirst to AFirst + ACount - 1 do
        begin
          LColor := LDecoder.Color(LIndex);
          LPalette[LIndex * 3] := LColor.Red;
          LPalette[LIndex * 3 + 1] := LColor.Green;
          LPalette[LIndex * 3 + 2] := LColor.Blue;
        end;
      end;
    // flc <width> <height> <frames> <speed> <type> screen <w> <h>
    LParts := LGolden[0].Split([' ']);
    Assert.AreEqual(StrToInt(LParts[1]), Integer(LDecoder.Width));
    Assert.AreEqual(StrToInt(LParts[2]), Integer(LDecoder.Height));
    Assert.AreEqual(StrToInt(LParts[3]), Integer(LDecoder.Frames));
    Assert.AreEqual(StrToInt(LParts[4]), Integer(LDecoder.Speed));
    Assert.AreEqual(StrToInt(LParts[5]), Integer(LDecoder.HeaderType));
    Assert.AreEqual(SCREEN_WIDTH, StrToInt(LParts[7]));
    Assert.AreEqual(SCREEN_HEIGHT, StrToInt(LParts[8]));
    LOffset := ((SCREEN_HEIGHT - LDecoder.Height) div 2) * SCREEN_WIDTH;
    LFrames := 0;
    for LLine := 1 to LGolden.Count - 1 do
    begin
      LParts := LGolden[LLine].Split([' ']);
      if LParts[0] = 'end' then
      begin
        Assert.AreEqual(StrToInt(LParts[1]), LDecoder.FrameCount, 'i fotogrammi in tutto');
        Assert.IsTrue(LDecoder.Finished);
        Break;
      end;
      Assert.IsTrue(LDecoder.FindFrame, Format('il fotogramma %s c''e''', [LParts[0]]));
      LDecoder.DecodeFrame(LScreen, SCREEN_WIDTH, LOffset, False);
      Inc(LFrames);
      Assert.AreEqual(StrToInt(LParts[0]), LDecoder.FrameCount);
      Assert.AreEqual(LParts[1], Fingerprint(LScreen, Length(LScreen)),
        Format('i pixel del fotogramma %s', [LParts[0]]));
      Assert.AreEqual(LParts[2], Fingerprint(LPalette, Length(LPalette)),
        Format('la palette del fotogramma %s', [LParts[0]]));
    end;
    Assert.IsTrue(LFrames > 800, Format('%d fotogrammi confrontati', [LFrames]));
  finally
    LDecoder.Free;
    LGolden.Free;
  end;
end;

end.
