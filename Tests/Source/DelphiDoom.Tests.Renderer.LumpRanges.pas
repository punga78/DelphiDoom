{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the renderer library - the lump ranges                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Renderer.LumpRanges;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf, DelphiDoom.Logging.Intf, DelphiDoom.Tests.Renderer.Fakes;

type
  [TestFixture]
  [Category('renderer')]
  TTestRendererLumpRanges = class(TObject)
  private
    FDirectory: TFakeLumpDirectory;
    FDirectoryIntf: IRendererLumpDirectory;
    FLog: TFakeLog;
    FLogIntf: ILog;
    FRanges: IRendererLumpRanges;
    procedure Fill(const ANames: array of string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareIlIntervalloDeiFlat;
    [Test]
    procedure DovrebbeUsareIFlatDeiPwadSeVannoPiuLontano;
    [Test]
    procedure DovrebbeUsareLUltimoMarcatoreDiFineDeiFlat;
    [Test]
    procedure DovrebbeFallireSeMancaIlMarcatoreDeiFlat;
    [Test]
    procedure DovrebbeDareIlIntervalloDegliSprite;
    [Test]
    procedure DovrebbeUsareIMarcatoriSSDegliSprite;
    [Test]
    procedure DovrebbePartireDaZeroSenzaMarcatoreDiInizioDegliSprite;
    [Test]
    procedure DovrebbeAvvisareSeIMarcatoriDegliSpriteSonoFuoriPosto;
    [Test]
    procedure DovrebbeFallireSeMancaIlMarcatoreDiFineDegliSprite;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
    [Test]
    procedure DovrebbeDareIlNomeDiUnLumpComeTesto;
    /// <summary>
    ///   Parity: the markers of R_InitFlats and R_InitSpriteLumps of the old r_data.pas, copied
    ///   here as they were, and the library give the same ranges, warnings and errors on
    ///   random WADs
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIVecchiR_InitFlatsER_InitSpriteLumps;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Renderer.Factory, DelphiDoom.Renderer.LumpRanges;

type
  EOldFatal = class(Exception);

  /// <summary>The old code of r_data.pas, with the WAD functions over the fake directory</summary>
  TOldRanges = class
  public
    Directory: TFakeLumpDirectory;
    Warnings: TList<string>;
    firstflat: Integer;
    lastflat: Integer;
    firstspritelump: Integer;
    lastspritelump: Integer;
    function W_GetFirstNumForName(const name: string): Integer;
    function W_GetNumForName(const name: string): Integer;
    procedure R_InitFlats;
    procedure R_InitSpriteLumps;
  end;

function TOldRanges.W_GetFirstNumForName(const name: string): Integer;
begin
  Result := Directory.FirstLumpNamed(name);
  if Result = -1 then
    raise EOldFatal.Create(Format('W_GetNumForName(): %s not found!', [name]));
end;

function TOldRanges.W_GetNumForName(const name: string): Integer;
begin
  Result := Directory.LastLumpNamed(name);
  if Result = -1 then
    raise EOldFatal.Create(Format('W_GetNumForName(): %s not found!', [name]));
end;

procedure TOldRanges.R_InitFlats;
var
  lump: Integer;
begin
  firstflat := W_GetFirstNumForName('F_START') + 1;
  lump := Directory.FirstLumpNamed('FF_START') + 1;
  if lump > 0 then
    if lump < firstflat then
      firstflat := lump;
  lastflat := W_GetNumForName('F_END') - 1;
  lump := Directory.LastLumpNamed('FF_END');
  if lump > lastflat then
    lastflat := lump;
end;

procedure TOldRanges.R_InitSpriteLumps;
var
  i: Integer;
  tmp: Integer;
  lumpname: string;
begin
  firstspritelump := 0;
  for i := 0 to Directory.LumpCount - 1 do
  begin
    lumpname := TRendererLumpRanges.LumpNameAsText(Directory.LumpName(i));
    if (lumpname = 'S_START') or (lumpname = 'SS_START') then
    begin
      firstspritelump := i + 1;
      Break;
    end;
  end;

  lastspritelump := W_GetNumForName('S_END') - 1;
  tmp := Directory.LastLumpNamed('SS_END');
  if tmp > 0 then
  begin
    Dec(tmp);
    if lastspritelump < tmp then
      lastspritelump := tmp;
  end;

  if lastspritelump < firstspritelump then
  begin
    Warnings.Add(Format('R_InitSpriteLumps(): WAD files have missplaced sprite markers (start=%d, end=%d)'#13#10,
      [firstspritelump, lastspritelump]));
    lastspritelump := Directory.LumpCount;
  end;
end;

{ TTestRendererLumpRanges }

procedure TTestRendererLumpRanges.Setup;
begin
  FDirectory := TFakeLumpDirectory.Create;
  FDirectoryIntf := FDirectory;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  FRanges := TRendererFactory.CreateLumpRanges(FDirectoryIntf, FLogIntf);
end;

procedure TTestRendererLumpRanges.TearDown;
begin
  FRanges := nil;
  FLogIntf := nil;
  FDirectoryIntf := nil;
end;

procedure TTestRendererLumpRanges.Fill(const ANames: array of string);
var
  LName: string;
begin
  for LName in ANames do
    FDirectory.Add(LName);
end;

procedure TTestRendererLumpRanges.DovrebbeDareIlIntervalloDeiFlat;
var
  LRange: TRendererLumpRange;
begin
  Fill(['PLAYPAL', 'F_START', 'FLAT1', 'FLAT2', 'F_END', 'TEXTURE1']);
  LRange := FRanges.FlatRange;
  Assert.AreEqual(2, LRange.First);
  Assert.AreEqual(3, LRange.Last);
end;

procedure TTestRendererLumpRanges.DovrebbeUsareIFlatDeiPwadSeVannoPiuLontano;
var
  LRange: TRendererLumpRange;
begin
  Fill(['FF_START', 'NEW1', 'FF_END', 'F_START', 'FLAT1', 'F_END', 'X']);
  LRange := FRanges.FlatRange;
  Assert.AreEqual(1, LRange.First, 'FF_START comes before F_START');
  Assert.AreEqual(4, LRange.Last);
  FDirectory.Names := nil;
  Fill(['F_START', 'FLAT1', 'F_END', 'FF_START', 'NEW1', 'FF_END']);
  LRange := FRanges.FlatRange;
  Assert.AreEqual(1, LRange.First);
  Assert.AreEqual(5, LRange.Last, 'FF_END is after F_END');
end;

procedure TTestRendererLumpRanges.DovrebbeUsareLUltimoMarcatoreDiFineDeiFlat;
begin
  Fill(['F_START', 'A', 'F_END', 'B', 'F_END']);
  Assert.AreEqual(3, FRanges.FlatRange.Last);
end;

procedure TTestRendererLumpRanges.DovrebbeFallireSeMancaIlMarcatoreDeiFlat;
begin
  Fill(['A', 'F_END']);
  try
    FRanges.FlatRange;
    Assert.Fail('No error');
  except
    on E: ERendererException do
      Assert.AreEqual('W_GetNumForName(): F_START not found!', E.Message);
  end;
  FDirectory.Names := nil;
  Fill(['F_START', 'A']);
  try
    FRanges.FlatRange;
    Assert.Fail('No error');
  except
    on E: ERendererException do
      Assert.AreEqual('W_GetNumForName(): F_END not found!', E.Message);
  end;
end;

procedure TTestRendererLumpRanges.DovrebbeDareIlIntervalloDegliSprite;
var
  LRange: TRendererLumpRange;
begin
  Fill(['A', 'S_START', 'TROOA1', 'TROOA2', 'S_END', 'B']);
  LRange := FRanges.SpriteRange;
  Assert.AreEqual(2, LRange.First);
  Assert.AreEqual(3, LRange.Last);
  Assert.AreEqual<Integer>(0, FLog.Others.Count);
end;

procedure TTestRendererLumpRanges.DovrebbeUsareIMarcatoriSSDegliSprite;
var
  LRange: TRendererLumpRange;
begin
  Fill(['S_START', 'TROOA1', 'S_END', 'SS_START', 'NEWA1', 'NEWB1', 'SS_END']);
  LRange := FRanges.SpriteRange;
  Assert.AreEqual(1, LRange.First);
  Assert.AreEqual(5, LRange.Last, 'SS_END is farther than S_END');
end;

procedure TTestRendererLumpRanges.DovrebbePartireDaZeroSenzaMarcatoreDiInizioDegliSprite;
var
  LRange: TRendererLumpRange;
begin
  Fill(['TROOA1', 'TROOA2', 'S_END']);
  LRange := FRanges.SpriteRange;
  Assert.AreEqual(0, LRange.First);
  Assert.AreEqual(1, LRange.Last);
end;

procedure TTestRendererLumpRanges.DovrebbeAvvisareSeIMarcatoriDegliSpriteSonoFuoriPosto;
var
  LRange: TRendererLumpRange;
begin
  Fill(['S_END', 'A', 'S_START', 'B']);
  LRange := FRanges.SpriteRange;
  Assert.AreEqual(3, LRange.First);
  // the number of lumps, not the last one
  Assert.AreEqual(4, LRange.Last);
  Assert.AreEqual<Integer>(1, FLog.Others.Count);
  Assert.AreEqual('R_InitSpriteLumps(): WAD files have missplaced sprite markers (start=3, end=-1)'#13#10,
    FLog.Others[0]);
end;

procedure TTestRendererLumpRanges.DovrebbeFallireSeMancaIlMarcatoreDiFineDegliSprite;
begin
  Fill(['S_START', 'A']);
  try
    FRanges.SpriteRange;
    Assert.Fail('No error');
  except
    on E: ERendererException do
      Assert.AreEqual('W_GetNumForName(): S_END not found!', E.Message);
  end;
end;

procedure TTestRendererLumpRanges.DovrebbeRifiutareDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateLumpRanges(nil, FLogIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRendererFactory.CreateLumpRanges(FDirectoryIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestRendererLumpRanges.DovrebbeDareIlNomeDiUnLumpComeTesto;
var
  LName: TRendererLumpName;
begin
  FillChar(LName, SizeOf(LName), 0);
  LName[0] := 'S';
  LName[1] := '_';
  Assert.AreEqual('S_', TRendererLumpRanges.LumpNameAsText(LName));
  FillChar(LName, SizeOf(LName), Ord('A'));
  Assert.AreEqual('AAAAAAAA', TRendererLumpRanges.LumpNameAsText(LName));
  FillChar(LName, SizeOf(LName), 0);
  Assert.AreEqual('', TRendererLumpRanges.LumpNameAsText(LName));
end;

procedure TTestRendererLumpRanges.DovrebbeFareComeIVecchiR_InitFlatsER_InitSpriteLumps;
const
  NAMES: array[0..11] of string = ('F_START', 'F_END', 'FF_START', 'FF_END', 'S_START', 'S_END',
    'SS_START', 'SS_END', 'FLATX', 'TROOA1', 'PLAYPAL', 'DEMO1');
var
  LScenario: Integer;
  LCount: Integer;
  LIndex: Integer;
  LDirectory: TFakeLumpDirectory;
  LDirectoryIntf: IRendererLumpDirectory;
  LLog: TFakeLog;
  LLogIntf: ILog;
  LOld: TOldRanges;
  LRanges: IRendererLumpRanges;
  LNew: TRendererLumpRange;
  LOldError: string;
  LNewError: string;
  LErrors: Integer;
begin
  RandSeed := 20261116;
  LErrors := 0;
  for LScenario := 1 to 600 do
  begin
    LDirectory := TFakeLumpDirectory.Create;
    LDirectoryIntf := LDirectory;
    LLog := TFakeLog.Create;
    LLogIntf := LLog;
    LCount := 1 + Random(25);
    for LIndex := 1 to LCount do
      LDirectory.Add(NAMES[Random(Length(NAMES))]);
    LRanges := TRendererFactory.CreateLumpRanges(LDirectoryIntf, LLogIntf);
    LOld := TOldRanges.Create;
    try
      LOld.Directory := LDirectory;
      LOld.Warnings := TList<string>.Create;

      // flats
      LOldError := '';
      LNewError := '';
      try
        LOld.R_InitFlats;
      except
        on E: EOldFatal do
          LOldError := E.Message;
      end;
      try
        LNew := LRanges.FlatRange;
      except
        on E: ERendererException do
          LNewError := E.Message;
      end;
      Assert.AreEqual(LOldError, LNewError, 'flat error, scenario ' + IntToStr(LScenario));
      if LOldError = '' then
      begin
        Assert.AreEqual(LOld.firstflat, LNew.First, 'first flat, scenario ' + IntToStr(LScenario));
        Assert.AreEqual(LOld.lastflat, LNew.Last, 'last flat, scenario ' + IntToStr(LScenario));
      end
      else
        Inc(LErrors);

      // sprites
      LOldError := '';
      LNewError := '';
      try
        LOld.R_InitSpriteLumps;
      except
        on E: EOldFatal do
          LOldError := E.Message;
      end;
      try
        LNew := LRanges.SpriteRange;
      except
        on E: ERendererException do
          LNewError := E.Message;
      end;
      Assert.AreEqual(LOldError, LNewError, 'sprite error, scenario ' + IntToStr(LScenario));
      if LOldError = '' then
      begin
        Assert.AreEqual(LOld.firstspritelump, LNew.First, 'first sprite, scenario ' + IntToStr(LScenario));
        Assert.AreEqual(LOld.lastspritelump, LNew.Last, 'last sprite, scenario ' + IntToStr(LScenario));
        Assert.AreEqual<Integer>(LOld.Warnings.Count, LLog.Others.Count);
        for LIndex := 0 to LOld.Warnings.Count - 1 do
          Assert.AreEqual(LOld.Warnings[LIndex], LLog.Others[LIndex]);
      end
      else
        Inc(LErrors);
    finally
      LOld.Warnings.Free;
      LOld.Free;
    end;
  end;
  Assert.IsTrue(LErrors > 50, 'the random WADs reach the errors');
  Assert.IsTrue(LErrors < 1100, 'and the ranges');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRendererLumpRanges);

end.
