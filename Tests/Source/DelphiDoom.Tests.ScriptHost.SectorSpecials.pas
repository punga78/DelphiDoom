{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the specials of the sectors of the scripts             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The 77 functions are compared with the old psi_map.pas (the unit            }
{  DelphiDoom.Tests.ScriptHost.OldSectorSpecials): same special, same kind and }
{  the same 8 bytes of arguments, for several sets of values (also negative    }
{  and too big for their byte).                                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.SectorSpecials;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.ScriptHost.SectorSpecials.Functions.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Intf,
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>
  ///   The gateway of the tests: it writes every call in the format of the recorders of the old
  ///   code ("name|kind|the 8 bytes") and gives back what the test says
  /// </summary>
  TFakeSectorSpecials = class(TInterfacedObject, IScriptSectorSpecials)
  public
    Log: TStringList;
    Answer: Boolean;
    constructor Create;
    destructor Destroy; override;
    function DoCeiling(var AArguments: TScriptSpecialArguments; const AKind: TScriptCeilingKind): Boolean;
    function CeilingCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
    function DoDoor(var AArguments: TScriptSpecialArguments; const AKind: TScriptDoorKind): Boolean;
    function DoFloor(var AArguments: TScriptSpecialArguments; const AKind: TScriptFloorKind): Boolean;
    function DoFloorAndCeiling(var AArguments: TScriptSpecialArguments; const ARaise: Boolean): Boolean;
    function FloorCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
    function StartFloorWaggle(const ATag, AAmplitude, AFrequency, AOffset, ATime: Integer): Boolean;
    function SpawnLight(var AArguments: TScriptSpecialArguments; const AKind: TScriptLightKind): Boolean;
    procedure ForceLightning(const ATics: Integer);
    function BuildPillar(var AArguments: TScriptSpecialArguments; const ACrush: Boolean): Boolean;
    function OpenPillar(var AArguments: TScriptSpecialArguments): Boolean;
    function DoPlat(var AArguments: TScriptSpecialArguments; const AKind: TScriptPlatKind): Boolean;
    function OpenPolyDoor(var AArguments: TScriptSpecialArguments; const AKind: TScriptPolyDoorKind): Boolean;
    function MovePoly(var AArguments: TScriptSpecialArguments; const ATimesEight, AOverride: Boolean): Boolean;
    function RotatePoly(var AArguments: TScriptSpecialArguments; const ADirection: Integer;
      const AOverride: Boolean): Boolean;
  end;

  [TestFixture]
  [Category('scripthost')]
  TTestScriptHostSectorSpecials = class(TObject)
  strict private
    FSpecials: TFakeSectorSpecials;
    FSpecialsRef: IScriptSectorSpecials;
    FFunctions: IScriptSectorSpecialFunctions;
    FOldLog: TStringList;
    FCompared: Integer;
    procedure CompareCall(const AName: string; const AOld, ANew: TFunc<Boolean>);
    procedure CompareAll(const AValues: TArray<Integer>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareGliStessiArgomentiDelVecchioConValoriNormali;
    [Test]
    procedure DovrebbeDareGliStessiArgomentiDelVecchioConValoriANZero;
    [Test]
    procedure DovrebbeDareGliStessiArgomentiDelVecchioConValoriNegativiEGrandi;
    [Test]
    procedure DovrebbeDareGliStessiArgomentiDelVecchioAiLimitiDeiTipi;
    [Test]
    procedure DovrebbeDareGliStessiArgomentiDelVecchioConVelocitaNegativa;
    [Test]
    procedure DovrebbeDareGliStessiArgomentiDelVecchioQuandoLaSpecialDaFalso;
    [Test]
    procedure DovrebbeConfrontareTutteLeSettantasetteFunzioni;
    [Test]
    procedure DovrebbeScrivereLAltezzaInDueByteSoloNelleFunzioniMoveToValue;
    [Test]
    procedure DovrebbeConservareLaLuceRaiseByValueSenzaIlValore;
    [Test]
    procedure DovrebbeUnireIRisultatiDiFloorAndCeilingLowerRaise;
    [Test]
    procedure DovrebbePassareAlSecondoComandoLaVelocitaDelSoffitto;
    [Test]
    procedure DovrebbeDareSempreVeroConLaFolgore;
    [Test]
    procedure DovrebbeAprireLaPortaDelPolyobjectAlContrarioConVelocitaNegativa;
    [Test]
    procedure DovrebbeDareLeSetteClassiDelGateway;
    [Test]
    procedure DovrebbeRifiutareUnGatewayNil;
  end;

implementation

uses
  System.TypInfo,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.Tests.ScriptHost.OldSectorSpecials;

function ArgumentsText(const AArguments: TScriptSpecialArguments): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := Low(AArguments) to High(AArguments) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + IntToStr(AArguments[LIndex]);
  end;
end;

// The name of a kind as the old and the new code write it, so the two can be compared: the
// engine constant CLEV_LOWERTOMAXFLOOR and the value sckLowerToMaxFloor both give LOWERTOMAXFLOOR
function KindName(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := AText;
  if Pos('_', Result) > 0 then
    Delete(Result, 1, Pos('_', Result))
  else
  begin
    LIndex := 1;
    while (LIndex <= Length(Result)) and (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') do
      Inc(LIndex);
    Delete(Result, 1, LIndex - 1);
  end;
  Result := StringReplace(UpperCase(Result), '_', '', [rfReplaceAll]);
  // the engine writes LITE_MAXNEIGHTBOR
  Result := StringReplace(Result, 'NEIGHTBOR', 'NEIGHBOR', [rfReplaceAll]);
end;

function NormalizedLine(const ALine: string): string;
var
  LParts: TArray<string>;
begin
  LParts := ALine.Split(['|']);
  if Length(LParts) = 3 then
    Result := LParts[0] + '|' + KindName(LParts[1]) + '|' + LParts[2]
  else
    Result := ALine;
end;

{ TFakeSectorSpecials }

constructor TFakeSectorSpecials.Create;
begin
  inherited Create;
  Log := TStringList.Create;
  Answer := True;
end;

destructor TFakeSectorSpecials.Destroy;
begin
  Log.Free;
  inherited;
end;

function TFakeSectorSpecials.DoCeiling(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptCeilingKind): Boolean;
begin
  Log.Add('DoCeiling|' + GetEnumName(TypeInfo(TScriptCeilingKind), Ord(AKind)) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.CeilingCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
begin
  Log.Add('CeilingCrushStop||' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.DoDoor(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptDoorKind): Boolean;
begin
  Log.Add('DoDoor|' + GetEnumName(TypeInfo(TScriptDoorKind), Ord(AKind)) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.DoFloor(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptFloorKind): Boolean;
begin
  Log.Add('DoFloor|' + GetEnumName(TypeInfo(TScriptFloorKind), Ord(AKind)) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.DoFloorAndCeiling(var AArguments: TScriptSpecialArguments;
  const ARaise: Boolean): Boolean;
begin
  Log.Add('DoFloorAndCeiling|' + BoolToStr(ARaise, True) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.FloorCrushStop(var AArguments: TScriptSpecialArguments): Boolean;
begin
  Log.Add('FloorCrushStop||' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.StartFloorWaggle(const ATag, AAmplitude, AFrequency, AOffset,
  ATime: Integer): Boolean;
begin
  Log.Add(Format('StartFloorWaggle||%d,%d,%d,%d,%d', [ATag, AAmplitude, AFrequency, AOffset, ATime]));
  Result := Answer;
end;

function TFakeSectorSpecials.SpawnLight(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptLightKind): Boolean;
begin
  Log.Add('SpawnLight|' + GetEnumName(TypeInfo(TScriptLightKind), Ord(AKind)) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

procedure TFakeSectorSpecials.ForceLightning(const ATics: Integer);
begin
  Log.Add('ForceLightning||' + IntToStr(ATics));
end;

function TFakeSectorSpecials.BuildPillar(var AArguments: TScriptSpecialArguments;
  const ACrush: Boolean): Boolean;
begin
  Log.Add('BuildPillar|' + BoolToStr(ACrush, True) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.OpenPillar(var AArguments: TScriptSpecialArguments): Boolean;
begin
  Log.Add('OpenPillar||' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.DoPlat(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptPlatKind): Boolean;
begin
  Log.Add('DoPlat|' + GetEnumName(TypeInfo(TScriptPlatKind), Ord(AKind)) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.OpenPolyDoor(var AArguments: TScriptSpecialArguments;
  const AKind: TScriptPolyDoorKind): Boolean;
begin
  Log.Add('OpenPolyDoor|' + GetEnumName(TypeInfo(TScriptPolyDoorKind), Ord(AKind)) + '|' + ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.MovePoly(var AArguments: TScriptSpecialArguments;
  const ATimesEight, AOverride: Boolean): Boolean;
begin
  Log.Add('MovePoly|' + BoolToStr(ATimesEight, True) + ',' + BoolToStr(AOverride, True) + '|' +
    ArgumentsText(AArguments));
  Result := Answer;
end;

function TFakeSectorSpecials.RotatePoly(var AArguments: TScriptSpecialArguments;
  const ADirection: Integer; const AOverride: Boolean): Boolean;
begin
  Log.Add('RotatePoly|' + IntToStr(ADirection) + ',' + BoolToStr(AOverride, True) + '|' +
    ArgumentsText(AArguments));
  Result := Answer;
end;

{ TTestScriptHostSectorSpecials }

procedure TTestScriptHostSectorSpecials.Setup;
begin
  FSpecials := TFakeSectorSpecials.Create;
  FSpecialsRef := FSpecials;
  FFunctions := TScriptHostFactory.CreateSectorSpecialFunctions(FSpecialsRef);
  FOldLog := TStringList.Create;
  FCompared := 0;
  OldSpecialsLog :=
    procedure(AText: string)
    begin
      FOldLog.Add(AText);
    end;
end;

procedure TTestScriptHostSectorSpecials.TearDown;
begin
  OldSpecialsLog := nil;
  FreeAndNil(FOldLog);
  FFunctions := nil;
  FSpecialsRef := nil;
end;

procedure TTestScriptHostSectorSpecials.CompareCall(const AName: string; const AOld, ANew: TFunc<Boolean>);
var
  LOldResult: Boolean;
  LNewResult: Boolean;
  LIndex: Integer;
begin
  FOldLog.Clear;
  FSpecials.Log.Clear;
  OldSpecialsResult := FSpecials.Answer;
  LOldResult := AOld();
  LNewResult := ANew();
  Assert.AreEqual(FOldLog.Count, FSpecials.Log.Count, AName + ': number of calls');
  Assert.IsTrue(FOldLog.Count > 0, AName + ': no call');
  for LIndex := 0 to FOldLog.Count - 1 do
    Assert.AreEqual(NormalizedLine(FOldLog[LIndex]), NormalizedLine(FSpecials.Log[LIndex]), AName);
  Assert.AreEqual(LOldResult, LNewResult, AName + ': result');
  Inc(FCompared);
end;

procedure TTestScriptHostSectorSpecials.CompareAll(const AValues: TArray<Integer>);
begin
  CompareCall('Ceiling_CrushAndRaise',
    function: Boolean
    begin
      Result := Old_Ceiling_CrushAndRaise(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.CrushAndRaise(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Ceiling_CrushRaiseAndStay',
    function: Boolean
    begin
      Result := Old_Ceiling_CrushRaiseAndStay(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.CrushRaiseAndStay(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Ceiling_CrushStop',
    function: Boolean
    begin
      Result := Old_Ceiling_CrushStop(AValues[0]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.CrushStop(AValues[0]);
    end);
  CompareCall('Ceiling_LowerAndCrush',
    function: Boolean
    begin
      Result := Old_Ceiling_LowerAndCrush(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.LowerAndCrush(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Ceiling_LowerByValue',
    function: Boolean
    begin
      Result := Old_Ceiling_LowerByValue(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.LowerByValue(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Ceiling_LowerByValueTimes8',
    function: Boolean
    begin
      Result := Old_Ceiling_LowerByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.LowerByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Ceiling_LowerToFloor',
    function: Boolean
    begin
      Result := Old_Ceiling_LowerToFloor(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.LowerToFloor(AValues[0], AValues[1]);
    end);
  CompareCall('Ceiling_LowerToHighestFloor',
    function: Boolean
    begin
      Result := Old_Ceiling_LowerToHighestFloor(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.LowerToHighestFloor(AValues[0], AValues[1]);
    end);
  CompareCall('Ceiling_LowerToLowest',
    function: Boolean
    begin
      Result := Old_Ceiling_LowerToLowest(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.LowerToLowest(AValues[0], AValues[1]);
    end);
  CompareCall('Ceiling_MoveToValueAndCrush',
    function: Boolean
    begin
      Result := Old_Ceiling_MoveToValueAndCrush(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.MoveToValueAndCrush(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Ceiling_MoveToValue',
    function: Boolean
    begin
      Result := Old_Ceiling_MoveToValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.MoveToValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Ceiling_MoveToValueTimes8',
    function: Boolean
    begin
      Result := Old_Ceiling_MoveToValueTimes8(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.MoveToValueTimes8(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Ceiling_RaiseByValue',
    function: Boolean
    begin
      Result := Old_Ceiling_RaiseByValue(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.RaiseByValue(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Ceiling_RaiseByValueTimes8',
    function: Boolean
    begin
      Result := Old_Ceiling_RaiseByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.RaiseByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Ceiling_RaiseToHighestFloor',
    function: Boolean
    begin
      Result := Old_Ceiling_RaiseToHighestFloor(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Ceilings.RaiseToHighestFloor(AValues[0], AValues[1]);
    end);
  CompareCall('Door_Close',
    function: Boolean
    begin
      Result := Old_Door_Close(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Doors.Close(AValues[0], AValues[1]);
    end);
  CompareCall('Door_CloseWaitOpen',
    function: Boolean
    begin
      Result := Old_Door_CloseWaitOpen(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Doors.CloseWaitOpen(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Door_Open',
    function: Boolean
    begin
      Result := Old_Door_Open(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Doors.Open(AValues[0], AValues[1]);
    end);
  CompareCall('Door_Raise',
    function: Boolean
    begin
      Result := Old_Door_Raise(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Doors.RaiseDoor(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('FloorAndCeiling_LowerByValue',
    function: Boolean
    begin
      Result := Old_FloorAndCeiling_LowerByValue(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.FloorAndCeilingLowerByValue(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('FloorAndCeiling_LowerRaise',
    function: Boolean
    begin
      Result := Old_FloorAndCeiling_LowerRaise(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.FloorAndCeilingLowerRaise(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('FloorAndCeiling_RaiseByValue',
    function: Boolean
    begin
      Result := Old_FloorAndCeiling_RaiseByValue(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.FloorAndCeilingRaiseByValue(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_CrushStop',
    function: Boolean
    begin
      Result := Old_Floor_CrushStop(AValues[0]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.CrushStop(AValues[0]);
    end);
  CompareCall('Floor_LowerByValue',
    function: Boolean
    begin
      Result := Old_Floor_LowerByValue(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.LowerByValue(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_LowerByValueTimes8',
    function: Boolean
    begin
      Result := Old_Floor_LowerByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.LowerByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_LowerToHighest',
    function: Boolean
    begin
      Result := Old_Floor_LowerToHighest(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.LowerToHighest(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_LowerToLowestCeiling',
    function: Boolean
    begin
      Result := Old_Floor_LowerToLowestCeiling(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.LowerToLowestCeiling(AValues[0], AValues[1]);
    end);
  CompareCall('Floor_LowerToLowest',
    function: Boolean
    begin
      Result := Old_Floor_LowerToLowest(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.LowerToLowest(AValues[0], AValues[1]);
    end);
  CompareCall('Floor_LowerToNearest',
    function: Boolean
    begin
      Result := Old_Floor_LowerToNearest(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.LowerToNearest(AValues[0], AValues[1]);
    end);
  CompareCall('Floor_MoveToValue',
    function: Boolean
    begin
      Result := Old_Floor_MoveToValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.MoveToValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Floor_MoveToValueTimes8',
    function: Boolean
    begin
      Result := Old_Floor_MoveToValueTimes8(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.MoveToValueTimes8(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Floor_RaiseAndCrushDoom',
    function: Boolean
    begin
      Result := Old_Floor_RaiseAndCrushDoom(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseAndCrushDoom(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_RaiseAndCrush',
    function: Boolean
    begin
      Result := Old_Floor_RaiseAndCrush(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseAndCrush(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_RaiseByTexture',
    function: Boolean
    begin
      Result := Old_Floor_RaiseByTexture(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseByTexture(AValues[0], AValues[1]);
    end);
  CompareCall('Floor_RaiseByValue',
    function: Boolean
    begin
      Result := Old_Floor_RaiseByValue(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseByValue(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_RaiseByValueTimes8',
    function: Boolean
    begin
      Result := Old_Floor_RaiseByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseByValueTimes8(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_RaiseInstant',
    function: Boolean
    begin
      Result := Old_Floor_RaiseInstant(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseInstant(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_LowerInstant',
    function: Boolean
    begin
      Result := Old_Floor_LowerInstant(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.LowerInstant(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_RaiseToCeilingNoChange',
    function: Boolean
    begin
      Result := Old_Floor_RaiseToCeilingNoChange(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseToCeilingNoChange(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Floor_RaiseToHighest',
    function: Boolean
    begin
      Result := Old_Floor_RaiseToHighest(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseToHighest(AValues[0], AValues[1]);
    end);
  CompareCall('Floor_RaiseToLowestCeiling',
    function: Boolean
    begin
      Result := Old_Floor_RaiseToLowestCeiling(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseToLowestCeiling(AValues[0], AValues[1]);
    end);
  CompareCall('Floor_RaiseToNearest',
    function: Boolean
    begin
      Result := Old_Floor_RaiseToNearest(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.RaiseToNearest(AValues[0], AValues[1]);
    end);
  CompareCall('Floor_ToCeilingInstantNoChange',
    function: Boolean
    begin
      Result := Old_Floor_ToCeilingInstantNoChange(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.ToCeilingInstantNoChange(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Floor_Waggle',
    function: Boolean
    begin
      Result := Old_Floor_Waggle(AValues[0], AValues[1], AValues[2], AValues[3], AValues[4]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Floors.Waggle(AValues[0], AValues[1], AValues[2], AValues[3], AValues[4]);
    end);
  CompareCall('Light_ChangeToValue',
    function: Boolean
    begin
      Result := Old_Light_ChangeToValue(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.ChangeToValue(AValues[0], AValues[1]);
    end);
  CompareCall('Light_Fade',
    function: Boolean
    begin
      Result := Old_Light_Fade(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.Fade(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Light_Flicker',
    function: Boolean
    begin
      Result := Old_Light_Flicker(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.Flicker(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Light_ForceLightning',
    function: Boolean
    begin
      Result := Old_Light_ForceLightning;
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.ForceLightning;
    end);
  CompareCall('Light_ForceLightningTics',
    function: Boolean
    begin
      Result := Old_Light_ForceLightningTics(AValues[0]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.ForceLightningTics(AValues[0]);
    end);
  CompareCall('Light_Glow',
    function: Boolean
    begin
      Result := Old_Light_Glow(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.Glow(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Light_LowerByValue',
    function: Boolean
    begin
      Result := Old_Light_LowerByValue(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.LowerByValue(AValues[0], AValues[1]);
    end);
  CompareCall('Light_MaxNeighbor',
    function: Boolean
    begin
      Result := Old_Light_MaxNeighbor(AValues[0]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.MaxNeighbor(AValues[0]);
    end);
  CompareCall('Light_MinNeighbor',
    function: Boolean
    begin
      Result := Old_Light_MinNeighbor(AValues[0]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.MinNeighbor(AValues[0]);
    end);
  CompareCall('Light_RaiseByValue',
    function: Boolean
    begin
      Result := Old_Light_RaiseByValue(AValues[0], AValues[1]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.RaiseByValue(AValues[0], AValues[1]);
    end);
  CompareCall('Light_Strobe',
    function: Boolean
    begin
      Result := Old_Light_Strobe(AValues[0], AValues[1], AValues[2], AValues[3], AValues[4]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.Strobe(AValues[0], AValues[1], AValues[2], AValues[3], AValues[4]);
    end);
  CompareCall('Light_StrobeDoom',
    function: Boolean
    begin
      Result := Old_Light_StrobeDoom(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Lights.StrobeDoom(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Pillar_BuildAndCrush',
    function: Boolean
    begin
      Result := Old_Pillar_BuildAndCrush(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Pillars.BuildAndCrush(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Pillar_Build',
    function: Boolean
    begin
      Result := Old_Pillar_Build(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Pillars.Build(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Pillar_Open',
    function: Boolean
    begin
      Result := Old_Pillar_Open(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Pillars.Open(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Plat_DownByValue',
    function: Boolean
    begin
      Result := Old_Plat_DownByValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.DownByValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Plat_DownWaitUpStay',
    function: Boolean
    begin
      Result := Old_Plat_DownWaitUpStay(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.DownWaitUpStay(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Plat_DownWaitUpStayLip',
    function: Boolean
    begin
      Result := Old_Plat_DownWaitUpStayLip(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.DownWaitUpStayLip(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Plat_PerpetualRaise',
    function: Boolean
    begin
      Result := Old_Plat_PerpetualRaise(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.PerpetualRaise(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Plat_PerpetualRaiseLip',
    function: Boolean
    begin
      Result := Old_Plat_PerpetualRaiseLip(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.PerpetualRaiseLip(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Plat_UpByValue',
    function: Boolean
    begin
      Result := Old_Plat_UpByValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.UpByValue(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Plat_UpNearestWaitDownStay',
    function: Boolean
    begin
      Result := Old_Plat_UpNearestWaitDownStay(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.UpNearestWaitDownStay(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Plat_UpWaitDownStay',
    function: Boolean
    begin
      Result := Old_Plat_UpWaitDownStay(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Plats.UpWaitDownStay(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Polyobj_DoorSlide',
    function: Boolean
    begin
      Result := Old_Polyobj_DoorSlide(AValues[0], AValues[1], AValues[2], AValues[3], AValues[4]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.DoorSlide(AValues[0], AValues[1], AValues[2], AValues[3], AValues[4]);
    end);
  CompareCall('Polyobj_DoorSwing',
    function: Boolean
    begin
      Result := Old_Polyobj_DoorSwing(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.DoorSwing(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Polyobj_Move',
    function: Boolean
    begin
      Result := Old_Polyobj_Move(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.MoveBy(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Polyobj_MoveTimes8',
    function: Boolean
    begin
      Result := Old_Polyobj_MoveTimes8(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.MoveTimes8(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Polyobj_OR_Move',
    function: Boolean
    begin
      Result := Old_Polyobj_OR_Move(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.MoveOverride(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Polyobj_OR_MoveTimes8',
    function: Boolean
    begin
      Result := Old_Polyobj_OR_MoveTimes8(AValues[0], AValues[1], AValues[2], AValues[3]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.MoveTimes8Override(AValues[0], AValues[1], AValues[2], AValues[3]);
    end);
  CompareCall('Polyobj_OR_RotateLeft',
    function: Boolean
    begin
      Result := Old_Polyobj_OR_RotateLeft(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.RotateLeftOverride(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Polyobj_OR_RotateRight',
    function: Boolean
    begin
      Result := Old_Polyobj_OR_RotateRight(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.RotateRightOverride(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Polyobj_RotateLeft',
    function: Boolean
    begin
      Result := Old_Polyobj_RotateLeft(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.RotateLeft(AValues[0], AValues[1], AValues[2]);
    end);
  CompareCall('Polyobj_RotateRight',
    function: Boolean
    begin
      Result := Old_Polyobj_RotateRight(AValues[0], AValues[1], AValues[2]);
    end,
    function: Boolean
    begin
      Result := FFunctions.Polyobjects.RotateRight(AValues[0], AValues[1], AValues[2]);
    end);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareGliStessiArgomentiDelVecchioConValoriNormali;
begin
  CompareAll([10, 20, 30, 40, 50]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareGliStessiArgomentiDelVecchioConValoriANZero;
begin
  CompareAll([0, 0, 0, 0, 0]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareGliStessiArgomentiDelVecchioConValoriNegativiEGrandi;
begin
  CompareAll([-1, -2, 300, 70000, -129]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareGliStessiArgomentiDelVecchioAiLimitiDeiTipi;
begin
  CompareAll([255, 256, 65535, -32768, 32767]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareGliStessiArgomentiDelVecchioConVelocitaNegativa;
begin
  CompareAll([3, -5, 7, -9, 11]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareGliStessiArgomentiDelVecchioQuandoLaSpecialDaFalso;
begin
  FSpecials.Answer := False;
  CompareAll([10, 20, 30, 40, 50]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeConfrontareTutteLeSettantasetteFunzioni;
begin
  CompareAll([1, 2, 3, 4, 5]);
  Assert.AreEqual(77, FCompared);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeScrivereLAltezzaInDueByteSoloNelleFunzioniMoveToValue;
begin
  FFunctions.Ceilings.MoveToValue(7, 8, $1234, 9);
  Assert.AreEqual('DoCeiling|sckMoveToValue|7,8,52,18,9,0,0,0', FSpecials.Log[0]);
  FSpecials.Log.Clear;
  FFunctions.Floors.MoveToValue(7, 8, -2, 9);
  Assert.AreEqual('DoFloor|sfkMoveToValue|7,8,254,255,9,0,0,0', FSpecials.Log[0]);
  FSpecials.Log.Clear;
  FFunctions.Floors.MoveToValueTimes8(7, 8, $1234, 9);
  Assert.AreEqual('DoFloor|sfkMoveToValueTimes8|7,8,52,9,0,0,0,0', FSpecials.Log[0]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeConservareLaLuceRaiseByValueSenzaIlValore;
begin
  // as PS_Light_RaiseByValue always did: the value is not written in the arguments
  FFunctions.Lights.RaiseByValue(5, 99);
  Assert.AreEqual('SpawnLight|slkRaiseByValue|5,0,0,0,0,0,0,0', FSpecials.Log[0]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeUnireIRisultatiDiFloorAndCeilingLowerRaise;
begin
  FSpecials.Answer := False;
  Assert.IsFalse(FFunctions.Floors.FloorAndCeilingLowerRaise(1, 2, 3));
  Assert.AreEqual(2, FSpecials.Log.Count);
  FSpecials.Answer := True;
  Assert.IsTrue(FFunctions.Floors.FloorAndCeilingLowerRaise(1, 2, 3));
end;

procedure TTestScriptHostSectorSpecials.DovrebbePassareAlSecondoComandoLaVelocitaDelSoffitto;
begin
  FFunctions.Floors.FloorAndCeilingLowerRaise(4, 10, 20);
  Assert.AreEqual('DoFloor|sfkLowerFloorToLowest|4,10,0,0,0,0,0,0', FSpecials.Log[0]);
  Assert.AreEqual('DoCeiling|sckRaiseToHighest|4,20,0,0,0,0,0,0', FSpecials.Log[1]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareSempreVeroConLaFolgore;
begin
  FSpecials.Answer := False;
  Assert.IsTrue(FFunctions.Lights.ForceLightning);
  Assert.IsTrue(FFunctions.Lights.ForceLightningTics(35));
  Assert.AreEqual('ForceLightning||0', FSpecials.Log[0]);
  Assert.AreEqual('ForceLightning||35', FSpecials.Log[1]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeAprireLaPortaDelPolyobjectAlContrarioConVelocitaNegativa;
begin
  FFunctions.Polyobjects.DoorSwing(1, -8, 64, 5);
  Assert.AreEqual('OpenPolyDoor|spdSwing|1,8,64,5,1,0,0,0', FSpecials.Log[0]);
  FSpecials.Log.Clear;
  FFunctions.Polyobjects.DoorSwing(1, 8, 64, 5);
  Assert.AreEqual('OpenPolyDoor|spdSwing|1,8,64,5,0,0,0,0', FSpecials.Log[0]);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeDareLeSetteClassiDelGateway;
begin
  Assert.IsNotNull(FFunctions.Doors);
  Assert.IsNotNull(FFunctions.Ceilings);
  Assert.IsNotNull(FFunctions.Floors);
  Assert.IsNotNull(FFunctions.Lights);
  Assert.IsNotNull(FFunctions.Plats);
  Assert.IsNotNull(FFunctions.Pillars);
  Assert.IsNotNull(FFunctions.Polyobjects);
end;

procedure TTestScriptHostSectorSpecials.DovrebbeRifiutareUnGatewayNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TScriptHostFactory.CreateSectorSpecialFunctions(nil);
    end, EArgumentNilException);
end;

end.
