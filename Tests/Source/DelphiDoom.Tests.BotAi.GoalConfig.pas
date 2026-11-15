{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the item file of the goal AI (be_ai_goal.c,            }
{  LoadItemConfig) with files in memory                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.GoalConfig;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('BotAi.Goal')]
  TTestBotItemConfigLoader = class
  public
    [Test]
    procedure DovrebbeLeggereLeDefinizioniDegliOggetti;
    [Test]
    procedure DovrebbeDareNilSeIlFileNonCe;
    [Test]
    procedure DovrebbeDareNilSeUnaDefinizioneNonELaDefinizioneDiUnOggetto;
    [Test]
    procedure DovrebbeDareNilSeLeDefinizioniSuperanoIlLimite;
    [Test]
    procedure DovrebbeAvvisareSeIlFileEVuoto;
    [Test]
    procedure DovrebbeDareNilSeUnCampoEScorretto;
    [Test]
    procedure DovrebbeResistereAFileDiOggettiAlterati;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.LibVars.Intf, DelphiDoom.BotAi.LibVars.Table, DelphiDoom.BotAi.Goal.ItemConfig,
  DelphiDoom.BotAi.Goal.ItemDefinitions, DelphiDoom.BotAi.Goal.ItemConfigLoader, DelphiDoom.Tests.BotAi.Support;

const
  ONE_ITEM = 'iteminfo "item_health"'#10'{'#10'  name "Health"'#10'  index 2'#10'  respawntime 35'#10'}'#10;

type
  TLoaderFixture = class
  strict private
    FImport: TFakeBotImport;
    FImportIntf: IBotImport;
    FFiles: TMemoryBotFiles;
    FFilesIntf: IBotFileSource;
    FVars: TBotLibVarTable;
    FVarsIntf: IBotLibVarStore;
    FDefinitions: TBotItemDefinitions;
    FLoader: TBotItemConfigLoader;
  public
    constructor Create(const AText: AnsiString);
    destructor Destroy; override;
    function Load: TBotItemConfig;
    property Import: TFakeBotImport read FImport;
    property Vars: TBotLibVarTable read FVars;
  end;

constructor TLoaderFixture.Create(const AText: AnsiString);
begin
  inherited Create;
  FImport := TFakeBotImport.Create;
  FImportIntf := FImport;
  FFiles := TMemoryBotFiles.Create;
  FFilesIntf := FFiles;
  if AText <> '' then
    FFiles.Add('botfiles/items.c', AText);
  FVars := TBotLibVarTable.Create;
  FVarsIntf := FVars;
  FDefinitions := TBotItemDefinitions.Create;
  FLoader := TBotItemConfigLoader.Create(FImportIntf, FFilesIntf, FVarsIntf, FDefinitions);
end;

destructor TLoaderFixture.Destroy;
begin
  FLoader.Free;
  FDefinitions.Free;
  inherited Destroy;
end;

function TLoaderFixture.Load: TBotItemConfig;
begin
  Result := FLoader.Load('items.c');
end;

{ TTestBotItemConfigLoader }

procedure TTestBotItemConfigLoader.DovrebbeLeggereLeDefinizioniDegliOggetti;
var
  LFixture: TLoaderFixture;
  LConfig: TBotItemConfig;
begin
  LFixture := TLoaderFixture.Create(ONE_ITEM + ONE_ITEM);
  try
    LConfig := LFixture.Load;
    try
      Assert.IsNotNull(LConfig);
      Assert.AreEqual(2, LConfig.Count);
      Assert.AreEqual(2, LConfig.Info(0).Index);
      Assert.AreEqual(1, LConfig.Info(1).Number);
    finally
      LConfig.Free;
    end;
  finally
    LFixture.Free;
  end;
end;

procedure TTestBotItemConfigLoader.DovrebbeDareNilSeIlFileNonCe;
var
  LFixture: TLoaderFixture;
begin
  LFixture := TLoaderFixture.Create('');
  try
    Assert.IsNull(LFixture.Load);
    Assert.IsTrue(LFixture.Import.Lines.Text.Contains('counldn''t load'), 'avviso del C');
  finally
    LFixture.Free;
  end;
end;

procedure TTestBotItemConfigLoader.DovrebbeDareNilSeUnaDefinizioneNonELaDefinizioneDiUnOggetto;
var
  LFixture: TLoaderFixture;
begin
  LFixture := TLoaderFixture.Create('weaponinfo "x" { }'#10);
  try
    Assert.IsNull(LFixture.Load);
    Assert.IsTrue(LFixture.Import.Lines.Text.Contains('unknown definition'), 'messaggio del C');
  finally
    LFixture.Free;
  end;
end;

procedure TTestBotItemConfigLoader.DovrebbeDareNilSeLeDefinizioniSuperanoIlLimite;
var
  LFixture: TLoaderFixture;
begin
  LFixture := TLoaderFixture.Create(ONE_ITEM + ONE_ITEM);
  try
    LFixture.Vars.SetText('max_iteminfo', '1');
    Assert.IsNull(LFixture.Load);
    Assert.IsTrue(LFixture.Import.Lines.Text.Contains('more than 1 item info defined'), 'messaggio del C');
  finally
    LFixture.Free;
  end;
end;

procedure TTestBotItemConfigLoader.DovrebbeAvvisareSeIlFileEVuoto;
var
  LFixture: TLoaderFixture;
  LConfig: TBotItemConfig;
begin
  LFixture := TLoaderFixture.Create('// no item'#10);
  try
    LConfig := LFixture.Load;
    try
      Assert.IsNotNull(LConfig);
      Assert.AreEqual(0, LConfig.Count);
    finally
      LConfig.Free;
    end;
    Assert.IsTrue(LFixture.Import.Lines.Text.Contains('no item info loaded'), 'avviso del file vuoto');
    // a negative limit cannot come from the text of the variable: the original reads "-3" as 0 (README)
    Assert.AreEqual(Single(256), LFixture.Vars.GetValue('max_iteminfo'), 'limite di default');
  finally
    LFixture.Free;
  end;
end;

procedure TTestBotItemConfigLoader.DovrebbeDareNilSeUnCampoEScorretto;
var
  LFixture: TLoaderFixture;
begin
  LFixture := TLoaderFixture.Create('iteminfo "item_x"'#10'{'#10'  nofield 3'#10'}'#10);
  try
    Assert.IsNull(LFixture.Load);
  finally
    LFixture.Free;
  end;
end;

procedure TTestBotItemConfigLoader.DovrebbeResistereAFileDiOggettiAlterati;
const
  SEED = 20261115;
  ITERATIONS = 300;
var
  LIteration: Integer;
  LMutations: Integer;
  LText: AnsiString;
  LPosition: Integer;
  LFixture: TLoaderFixture;
  LConfig: TBotItemConfig;
begin
  RandSeed := SEED;
  for LIteration := 1 to ITERATIONS do
  begin
    // the file of one item with a few bytes changed, cut or doubled: only a controlled answer is allowed
    LText := ONE_ITEM + ONE_ITEM;
    for LMutations := 0 to Random(5) do
    begin
      LPosition := 1 + Random(Length(LText));
      case Random(3) of
        0: LText[LPosition] := AnsiChar(Random(256));
        1: Delete(LText, LPosition, 1 + Random(8));
        2: Insert(AnsiChar(Random(256)), LText, LPosition);
      end;
      if LText = '' then
        LText := ' ';
    end;
    LFixture := TLoaderFixture.Create(LText);
    try
      LConfig := LFixture.Load;
      LConfig.Free;
    finally
      LFixture.Free;
    end;
  end;
  Assert.Pass('nessuna eccezione sui ' + IntToStr(ITERATIONS) + ' file alterati');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestBotItemConfigLoader);

end.
