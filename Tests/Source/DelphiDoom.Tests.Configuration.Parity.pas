{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the configuration library - parity of the table of     }
{  the options with the old code                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Configuration.Parity;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Configuration.Intf,
  DelphiDoom.Tests.Configuration.Legacy;

type
  /// <summary>
  ///   The same random tables and the same random operations (load, save, reset, force, reads
  ///   of the scripts, reads and writes of the console) on the copy of the old code and on the
  ///   classes; after every operation every variable, the lines of the file and the messages
  ///   must be the same
  /// </summary>
  [TestFixture]
  [Category('configuration')]
  TTestConfigurationParity = class(TObject)
  strict private
    FFormat: IConfigurationFormat;
    FRandom: Cardinal;
    FOldIntegers, FNewIntegers: TArray<Integer>;
    FOldBooleans, FNewBooleans: TArray<Boolean>;
    FOldStrings, FNewStrings: TArray<string>;
    FCommands: TStringList;
    FOldLog, FNewLog: TStringList;
    FLegacy: TLegacyDefaults;
    FTable: IConfigurationTable;
    FStore: IConfigurationTableStore;
    FSink: IConfigurationResetSink;
    function Next(ARange: Integer): Integer;
    function RandomName: string;
    function RandomValueText: string;
    procedure BuildWorld(ACount: Integer);
    procedure FreeWorld;
    function RandomDocument: IConfigurationDocument;
    procedure CompareState(const AContext: string);
    procedure RunStep(const AContext: string);
    function NewScriptString(const AName: string): string;
    function NewScriptInteger(const AName: string): Integer;
    function NewScriptBoolean(const AName: string): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuTabelleCasuali;
    [Test]
    procedure DovrebbeLeggereEScrivereUnFileCompletoComeIlVecchioCodice;
    [Test]
    procedure DovrebbeDareGliStessiNomiPerLeMaschere;
  end;

implementation

uses
  DelphiDoom.Configuration.Types,
  DelphiDoom.Configuration.Factory,
  DelphiDoom.Tests.Configuration.Fakes;

const
  NAME_POOL: array[0..13] of string = ('screenblocks', 'usemouse', 'mouse_sensitivity', 'chatmacro0',
    'Display', 'display', 'detaillevel', 'drawfps', 'key_right', 'Sound', 'savegamepath',
    'snd_channels', 'showmessages', 'gl_fog');
  SCENARIOS = 300;
  STEPS = 120;

{ TTestConfigurationParity }

procedure TTestConfigurationParity.Setup;
begin
  FFormat := TConfigurationFactory.CreateFormat;
  FCommands := TStringList.Create;
  FOldLog := TStringList.Create;
  FNewLog := TStringList.Create;
  FRandom := 185;
end;

procedure TTestConfigurationParity.TearDown;
begin
  FreeWorld;
  FCommands.Free;
  FOldLog.Free;
  FNewLog.Free;
end;

function TTestConfigurationParity.Next(ARange: Integer): Integer;
begin
  // a small generator of its own: the scenarios do not depend on System.Random
  FRandom := FRandom * 1664525 + 1013904223;
  Result := Integer((FRandom shr 8) mod Cardinal(ARange));
end;

function TTestConfigurationParity.RandomName: string;
begin
  Result := NAME_POOL[Next(Length(NAME_POOL))];
  if Next(6) = 0 then
    Result := UpperCase(Result);
end;

function TTestConfigurationParity.RandomValueText: string;
begin
  case Next(9) of
    0: Result := IntToStr(Next(2000) - 1000);
    1: Result := '0x' + IntToHex(Next(65536), 1);
    2: Result := '$' + IntToHex(Next(4096), 1);
    3: Result := '#' + IntToStr(Next(300));
    4: Result := 'yes';
    5: Result := 'false';
    6: Result := '''' + Char(Ord('a') + Next(26)) + '''';
    7: Result := '';
  else
    Result := 'text' + IntToStr(Next(50)) + ' =x';
  end;
end;

procedure TTestConfigurationParity.FreeWorld;
begin
  FreeAndNil(FLegacy);
  FTable := nil;
  FStore := nil;
  FSink := nil;
end;

procedure TTestConfigurationParity.BuildWorld(ACount: Integer);
var
  LIndex: Integer;
  LItems: TArray<IConfigurationItem>;
  LDefaults: TConfigurationDefaults;
  LKind: legacy_ttype_t;
  LCommand: Integer;
const
  KINDS: array[legacy_ttype_t] of TConfigurationItemKind = (cikString, cikInteger, cikBoolean, cikGroup);
begin
  FreeWorld;
  FOldLog.Clear;
  FNewLog.Clear;
  FCommands.Clear;
  for LCommand := 0 to Next(4) do
    FCommands.Add(LowerCase(RandomName));

  SetLength(FOldIntegers, ACount);
  SetLength(FNewIntegers, ACount);
  SetLength(FOldBooleans, ACount);
  SetLength(FNewBooleans, ACount);
  SetLength(FOldStrings, ACount);
  SetLength(FNewStrings, ACount);
  FLegacy := TLegacyDefaults.Create(FFormat, FCommands, FOldLog);
  FLegacy.netgame := Next(2) = 0;
  SetLength(FLegacy.defaults, ACount);
  SetLength(LItems, ACount);
  for LIndex := 0 to ACount - 1 do
  begin
    LKind := legacy_ttype_t(Next(4));
    LDefaults.StringValue := 'd' + IntToStr(Next(10));
    LDefaults.IntegerValue := Next(100) - 50;
    LDefaults.BooleanValue := Next(2) = 0;
    FOldIntegers[LIndex] := Next(1000);
    FOldBooleans[LIndex] := Next(2) = 0;
    FOldStrings[LIndex] := 'v' + IntToStr(Next(1000));
    FNewIntegers[LIndex] := FOldIntegers[LIndex];
    FNewBooleans[LIndex] := FOldBooleans[LIndex];
    FNewStrings[LIndex] := FOldStrings[LIndex];

    FLegacy.defaults[LIndex].name := LowerCase(RandomName);
    if (LKind = tGroup) and (Next(2) = 0) then
      FLegacy.defaults[LIndex].name := RandomName;
    FLegacy.defaults[LIndex]._type := LKind;
    FLegacy.defaults[LIndex].setable := Next(4);
    FLegacy.defaults[LIndex].defaultsvalue := LDefaults.StringValue;
    FLegacy.defaults[LIndex].defaultivalue := LDefaults.IntegerValue;
    FLegacy.defaults[LIndex].defaultbvalue := LDefaults.BooleanValue;
    FLegacy.defaults[LIndex].oldlocation := nil;
    case LKind of
      tInteger: FLegacy.defaults[LIndex].location := @FOldIntegers[LIndex];
      tBoolean: FLegacy.defaults[LIndex].location := @FOldBooleans[LIndex];
      tString: FLegacy.defaults[LIndex].location := @FOldStrings[LIndex];
    else
      FLegacy.defaults[LIndex].location := nil;
    end;

    if LKind = tGroup then
      LItems[LIndex] := TConfigurationFactory.CreateItem(FLegacy.defaults[LIndex].name, cikGroup,
        FLegacy.defaults[LIndex].setable, LDefaults, nil)
    else
      LItems[LIndex] := TConfigurationFactory.CreateItem(FLegacy.defaults[LIndex].name, KINDS[LKind],
        FLegacy.defaults[LIndex].setable, LDefaults,
        TFakeConfigurationValue.Create(@FNewIntegers[LIndex], @FNewBooleans[LIndex], @FNewStrings[LIndex]));
  end;
  FTable := TConfigurationFactory.CreateTable(LItems);
  FStore := TConfigurationFactory.CreateTableStore(FTable, FFormat);
  FSink := TFakeResetSink.Create(FCommands, FNewLog);
end;

function TTestConfigurationParity.RandomDocument: IConfigurationDocument;
var
  LLines: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LLines, 1 + Next(25));
  LLines[0] := '[Delphi Doom ver 2.07]';
  for LIndex := 1 to High(LLines) do
    case Next(10) of
      0: LLines[LIndex] := '';
      1: LLines[LIndex] := '[' + RandomName + ']';
      2: LLines[LIndex] := 'unknown_key=' + RandomValueText;
    else
      LLines[LIndex] := RandomName + '=' + RandomValueText;
    end;
  Result := FFormat.Parse(LLines);
end;

// TEngineScriptConsole.GetString/GetInteger/GetBoolean, with the conversion of the copy
function TTestConfigurationParity.NewScriptString(const AName: string): string;
var
  LItem: IConfigurationItem;
begin
  LItem := FTable.FindValue(LowerCase(AName));
  if not Assigned(LItem) then
    Exit('');
  case LItem.Kind of
    cikString: Result := LItem.ActualString;
    cikInteger: Result := IntToStr(LItem.ActualInteger);
  else
    if LItem.ActualBoolean then
      Result := 'true'
    else
      Result := 'false';
  end;
end;

function TTestConfigurationParity.NewScriptInteger(const AName: string): Integer;
var
  LItem: IConfigurationItem;
begin
  LItem := FTable.FindValue(LowerCase(AName));
  if not Assigned(LItem) then
    Exit(0);
  case LItem.Kind of
    cikString: Result := StrToIntDef(LItem.ActualString, 0);
    cikInteger: Result := LItem.ActualInteger;
  else
    if LItem.ActualBoolean then
      Result := 1
    else
      Result := 0;
  end;
end;

function TTestConfigurationParity.NewScriptBoolean(const AName: string): Boolean;
var
  LItem: IConfigurationItem;
begin
  LItem := FTable.FindValue(LowerCase(AName));
  if not Assigned(LItem) then
    Exit(False);
  case LItem.Kind of
    cikString: Result := LItem.ActualString <> '';
    cikInteger: Result := LItem.ActualInteger <> 0;
  else
    Result := LItem.ActualBoolean;
  end;
end;

procedure TTestConfigurationParity.CompareState(const AContext: string);
var
  LIndex: Integer;
  LOldWriter, LNewWriter: IConfigurationWriter;
  LOldLines, LNewLines: TArray<string>;
begin
  for LIndex := 0 to High(FOldIntegers) do
  begin
    if FOldIntegers[LIndex] <> FNewIntegers[LIndex] then
      Assert.Fail(Format('%s: integer %d: %d <> %d', [AContext, LIndex, FOldIntegers[LIndex], FNewIntegers[LIndex]]));
    if FOldBooleans[LIndex] <> FNewBooleans[LIndex] then
      Assert.Fail(Format('%s: boolean %d', [AContext, LIndex]));
    if FOldStrings[LIndex] <> FNewStrings[LIndex] then
      Assert.Fail(Format('%s: string %d: "%s" <> "%s"', [AContext, LIndex, FOldStrings[LIndex], FNewStrings[LIndex]]));
    if FLegacy.defaults[LIndex].setable <> FTable.Item(LIndex).Setable then
      Assert.Fail(Format('%s: setable %d', [AContext, LIndex]));
  end;
  LOldWriter := FFormat.CreateWriter('[h]');
  LNewWriter := FFormat.CreateWriter('[h]');
  FLegacy.Save(LOldWriter);
  FStore.Write(LNewWriter);
  LOldLines := LOldWriter.Lines;
  LNewLines := LNewWriter.Lines;
  if Length(LOldLines) <> Length(LNewLines) then
    Assert.Fail(AContext + ': lines of the file');
  for LIndex := 0 to High(LOldLines) do
    if LOldLines[LIndex] <> LNewLines[LIndex] then
      Assert.Fail(Format('%s: line %d: "%s" <> "%s"', [AContext, LIndex, LOldLines[LIndex], LNewLines[LIndex]]));
  if FOldLog.Text <> FNewLog.Text then
    Assert.Fail(AContext + ': messages: ' + FOldLog.Text + ' <> ' + FNewLog.Text);
end;

procedure TTestConfigurationParity.RunStep(const AContext: string);
var
  LName: string;
  LInteger: Integer;
  LBoolean: Boolean;
  LText: string;
  LDocument: IConfigurationDocument;
  LIndex: Integer;
  LItem: IConfigurationItem;
begin
  LName := RandomName;
  case Next(12) of
    0:
      begin
        FLegacy.ResetAll;
        FStore.ResetAll;
      end;
    1:
      begin
        LDocument := RandomDocument;
        FLegacy.Apply(LDocument);
        FStore.Apply(LDocument);
      end;
    2:
      begin
        FLegacy.Reset(LName);
        if FLegacy.netgame then
          FStore.Reset(LName, CONFIGURATION_SET_NETWORK, FSink)
        else
          FStore.Reset(LName, CONFIGURATION_SET_SINGLEPLAYER, FSink);
      end;
    3:
      begin
        LInteger := Next(500);
        Assert.AreEqual(FLegacy.ForceInteger(LName, LInteger), FStore.ForceInteger(LName, LInteger), AContext);
      end;
    4:
      begin
        LBoolean := Next(2) = 0;
        Assert.AreEqual(FLegacy.ForceBoolean(LName, LBoolean), FStore.ForceBoolean(LName, LBoolean), AContext);
      end;
    5:
      begin
        LText := 'forced' + IntToStr(Next(9));
        Assert.AreEqual(FLegacy.ForceString(LName, LText), FStore.ForceString(LName, LText), AContext);
      end;
    6: Assert.AreEqual(FLegacy.ScriptGetString(LName), NewScriptString(LName), False, AContext);
    7: Assert.AreEqual(FLegacy.ScriptGetInteger(LName), NewScriptInteger(LName), AContext);
    8: Assert.AreEqual(FLegacy.ScriptGetBoolean(LName), NewScriptBoolean(LName), AContext);
  else
    // the console on a row that is not a group (TEngineConsoleVariableSource skips the groups)
    LIndex := Next(FTable.Count);
    LItem := FTable.Item(LIndex);
    case LItem.Kind of
      cikInteger:
        begin
          Assert.AreEqual(FLegacy.ConsoleGetInteger(LIndex), LItem.GetInteger, AContext);
          LInteger := Next(300);
          FLegacy.ConsoleSetInteger(LIndex, LInteger);
          LItem.SetInteger(LInteger);
        end;
      cikBoolean:
        begin
          Assert.AreEqual(FLegacy.ConsoleGetBoolean(LIndex), LItem.GetBoolean, AContext);
          LBoolean := Next(2) = 0;
          FLegacy.ConsoleSetBoolean(LIndex, LBoolean);
          LItem.SetBoolean(LBoolean);
        end;
      cikString:
        begin
          Assert.AreEqual(FLegacy.ConsoleGetString(LIndex), LItem.GetString, False, AContext);
          LText := 'console' + IntToStr(Next(9));
          FLegacy.ConsoleSetString(LIndex, LText);
          LItem.SetString(LText);
        end;
    end;
  end;
  CompareState(AContext);
end;

procedure TTestConfigurationParity.DovrebbeDareGliStessiRisultatiDelVecchioCodiceSuTabelleCasuali;
var
  LScenario: Integer;
  LStep: Integer;
begin
  for LScenario := 1 to SCENARIOS do
  begin
    BuildWorld(1 + Next(40));
    CompareState(Format('scenario %d start', [LScenario]));
    for LStep := 1 to STEPS do
      RunStep(Format('scenario %d step %d', [LScenario, LStep]));
  end;
  Assert.Pass;
end;

procedure TTestConfigurationParity.DovrebbeLeggereEScrivereUnFileCompletoComeIlVecchioCodice;
var
  LScenario: Integer;
  LDocument: IConfigurationDocument;
begin
  // as M_LoadDefaults then M_SaveDefaults: the defaults, the file over them, the file written
  for LScenario := 1 to SCENARIOS do
  begin
    BuildWorld(1 + Next(60));
    FLegacy.ResetAll;
    FStore.ResetAll;
    LDocument := RandomDocument;
    FLegacy.Apply(LDocument);
    FStore.Apply(LDocument);
    CompareState(Format('file %d', [LScenario]));
  end;
  Assert.Pass;
end;

procedure TTestConfigurationParity.DovrebbeDareGliStessiNomiPerLeMaschere;
var
  LScenario: Integer;
  LOld, LNew: TArray<string>;
  LIndex: Integer;
begin
  for LScenario := 1 to 100 do
  begin
    BuildWorld(1 + Next(40));
    LOld := FLegacy.MaskNames;
    LNew := FStore.Names;
    Assert.AreEqual(Length(LOld), Length(LNew));
    for LIndex := 0 to High(LOld) do
      Assert.AreEqual(LOld[LIndex], LNew[LIndex], False);
  end;
end;

end.
