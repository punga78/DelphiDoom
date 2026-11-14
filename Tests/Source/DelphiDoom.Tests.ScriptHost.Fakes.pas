{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes of the tests of the script host                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.Fakes;

interface

uses
  System.Generics.Collections,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.MathCore.Types,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.System.Intf;

type
  /// <summary>A unit of script with the declarations and the routines that the test gives</summary>
  TFakeScriptGroup = class(TInterfacedObject, IScriptFunctionGroup)
  strict private
    FUnitName: string;
    FDeclarations: TArray<string>;
    FCodes: TArray<Pointer>;
    FDescribed: Integer;
  public
    constructor Create(const AUnitName: string; const ADeclarations: array of string;
      const ACodes: array of Pointer);
    function UnitName: string;
    procedure Describe(const ATable: IScriptFunctionTable);
    /// <summary>How many times the registry asked for the functions</summary>
    property Described: Integer read FDescribed;
  end;

  /// <summary>A table that only remembers what it is given</summary>
  TFakeFunctionTable = class(TInterfacedObject, IScriptFunctionTable)
  public
    Declarations: TList<string>;
    Codes: TList<Pointer>;
    ResultTypes: TList<string>;
    ExportDeclarations: TList<string>;
    /// <summary>The Self of every function: nil for a plain routine</summary>
    Instances: TList<TObject>;
    constructor Create;
    destructor Destroy; override;
    procedure Add(const ADeclaration: string; const ACode: Pointer);
    procedure AddWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const ACode: Pointer);
    procedure AddMethod(const ADeclaration: string; const AInstance: TObject; const ACode: Pointer);
    procedure AddMethodWithCustomResult(const ADeclaration, AResultType, AExportDeclaration: string;
      const AInstance: TObject; const ACode: Pointer);
  end;

  TFakeOutput = class(TInterfacedObject, IScriptSystemOutput)
  public
    Written: string;
    Debug: string;
    procedure WriteText(const AText: string);
    procedure WriteDebug(const AText: string);
    function FormatText(const AFormat: string; const AArguments: array of const): string;
  end;

  TFakeEnvironment = class(TInterfacedObject, IScriptSystemEnvironment)
  public
    Time: Integer;
    function LevelTime: Integer;
    function FineSine(const AAngle: LongWord): Integer;
    function FineCosine(const AAngle: LongWord): Integer;
    function FineTangent(const AAngle: LongWord): Integer;
  end;

  TFakeConsole = class(TInterfacedObject, IScriptSystemConsole)
  public
    Commands: string;
    LastName: string;
    LastValue: string;
    procedure AddCommand(const ACommand: string);
    function GetString(const AName: string): string;
    function GetInteger(const AName: string): Integer;
    function GetBoolean(const AName: string): Boolean;
    function SetString(const AName, AValue: string): Boolean;
    function SetInteger(const AName: string; const AValue: Integer): Boolean;
    function SetBoolean(const AName: string; const AValue: Boolean): Boolean;
  end;

  /// <summary>Gives the numbers that the test asks for; the other methods do nothing</summary>
  TFakeRandom = class(TInterfacedObject, IGameRandom)
  strict private
    FIndex: Integer;
  public
    Numbers: TArray<Integer>;
    function NextMenu: Integer;
    function NextPlay: Integer;
    function NextNonCompatible: Integer;
    function NextUnpredictable: Integer;
    function NextSystem: Integer;
    function NextWithIndex(var AIndex: Integer): Integer;
    function FromSeed(const ASeed: Integer): Integer;
    procedure Clear;
    procedure SavePlayIndex;
    function RestorePlayIndex: Boolean;
    function HitscanAngle(const ASpread: TFixed): Integer;
    function HitscanSlope(const ASpread: TFixed): Integer;
    function GetMenuIndex: Integer;
    procedure SetMenuIndex(const AValue: Integer);
    function GetPlayIndex: Integer;
    procedure SetPlayIndex(const AValue: Integer);
    function GetNonCompatibleIndex: Integer;
    procedure SetNonCompatibleIndex(const AValue: Integer);
    function GetSystemIndex: Integer;
    procedure SetSystemIndex(const AValue: Integer);
    function GetSystemSeed: Integer;
    procedure SetSystemSeed(const AValue: Integer);
  end;

var
  /// <summary>What RecordValue and RecordText of the routines below were called with</summary>
  GRecordedValue: Integer;
  GRecordedText: string;

/// <summary>A host routine of the tests: remembers the value (register convention, like the PS_* ones)</summary>
procedure RecordValue(const AValue: Integer);

/// <summary>A host routine with a text</summary>
procedure RecordText(const AText: string);

/// <summary>A host function with a result</summary>
function AddNumbers(const AFirst, ASecond: Integer): Integer;

/// <summary>
///   The declarations of a unit of script as the golden of the registration of Doom has them (the
///   file of Tests\Data\ScriptHost, made by the old code); empty if the file is not there
/// </summary>
function GoldenDeclarations(const AUnitName: string): TArray<string>;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils;

procedure RecordValue(const AValue: Integer);
begin
  GRecordedValue := AValue;
end;

procedure RecordText(const AText: string);
begin
  GRecordedText := AText;
end;

function AddNumbers(const AFirst, ASecond: Integer): Integer;
begin
  Result := AFirst + ASecond;
end;

function GoldenDeclarations(const AUnitName: string): TArray<string>;
var
  LFile: string;
  LLines: TStringList;
  LList: TList<string>;
  LIndex: Integer;
begin
  LFile := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\ScriptHost\Doom.registration.golden.txt'));
  SetLength(Result, 0);
  if not TFile.Exists(LFile) then
    Exit;
  LLines := TStringList.Create;
  LList := TList<string>.Create;
  try
    LLines.LoadFromFile(LFile);
    LIndex := LLines.IndexOf('unit ' + AUnitName);
    if LIndex < 0 then
      Exit;
    Inc(LIndex);
    while (LIndex < LLines.Count) and not LLines[LIndex].StartsWith('unit ') and
      not LLines[LIndex].StartsWith('[') do
    begin
      if Trim(LLines[LIndex]) <> '' then
        LList.Add(LLines[LIndex]);
      Inc(LIndex);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
    LLines.Free;
  end;
end;

{ TFakeScriptGroup }

constructor TFakeScriptGroup.Create(const AUnitName: string; const ADeclarations: array of string;
  const ACodes: array of Pointer);
var
  LIndex: Integer;
begin
  inherited Create;
  FUnitName := AUnitName;
  SetLength(FDeclarations, Length(ADeclarations));
  for LIndex := 0 to High(ADeclarations) do
    FDeclarations[LIndex] := ADeclarations[LIndex];
  SetLength(FCodes, Length(ACodes));
  for LIndex := 0 to High(ACodes) do
    FCodes[LIndex] := ACodes[LIndex];
end;

function TFakeScriptGroup.UnitName: string;
begin
  Result := FUnitName;
end;

procedure TFakeScriptGroup.Describe(const ATable: IScriptFunctionTable);
var
  LIndex: Integer;
begin
  Inc(FDescribed);
  for LIndex := 0 to High(FDeclarations) do
    if LIndex <= High(FCodes) then
      ATable.Add(FDeclarations[LIndex], FCodes[LIndex])
    else
      ATable.Add(FDeclarations[LIndex], nil);
end;

{ TFakeFunctionTable }

constructor TFakeFunctionTable.Create;
begin
  inherited Create;
  Declarations := TList<string>.Create;
  Codes := TList<Pointer>.Create;
  ResultTypes := TList<string>.Create;
  ExportDeclarations := TList<string>.Create;
  Instances := TList<TObject>.Create;
end;

destructor TFakeFunctionTable.Destroy;
begin
  Instances.Free;
  ExportDeclarations.Free;
  ResultTypes.Free;
  Codes.Free;
  Declarations.Free;
  inherited Destroy;
end;

procedure TFakeFunctionTable.Add(const ADeclaration: string; const ACode: Pointer);
begin
  Declarations.Add(ADeclaration);
  Codes.Add(ACode);
  ResultTypes.Add('');
  ExportDeclarations.Add(ADeclaration);
  Instances.Add(nil);
end;

procedure TFakeFunctionTable.AddWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const ACode: Pointer);
begin
  Declarations.Add(ADeclaration);
  Codes.Add(ACode);
  ResultTypes.Add(AResultType);
  ExportDeclarations.Add(AExportDeclaration);
  Instances.Add(nil);
end;

procedure TFakeFunctionTable.AddMethod(const ADeclaration: string; const AInstance: TObject;
  const ACode: Pointer);
begin
  Add(ADeclaration, ACode);
  Instances[Instances.Count - 1] := AInstance;
end;

procedure TFakeFunctionTable.AddMethodWithCustomResult(const ADeclaration, AResultType,
  AExportDeclaration: string; const AInstance: TObject; const ACode: Pointer);
begin
  AddWithCustomResult(ADeclaration, AResultType, AExportDeclaration, ACode);
  Instances[Instances.Count - 1] := AInstance;
end;

{ TFakeOutput }

procedure TFakeOutput.WriteText(const AText: string);
begin
  Written := Written + AText;
end;

procedure TFakeOutput.WriteDebug(const AText: string);
begin
  Debug := Debug + AText;
end;

function TFakeOutput.FormatText(const AFormat: string; const AArguments: array of const): string;
begin
  Result := System.SysUtils.Format(AFormat, AArguments);
end;

{ TFakeEnvironment }

function TFakeEnvironment.LevelTime: Integer;
begin
  Result := Time;
end;

function TFakeEnvironment.FineSine(const AAngle: LongWord): Integer;
begin
  Result := Integer(AAngle) + 1000;
end;

function TFakeEnvironment.FineCosine(const AAngle: LongWord): Integer;
begin
  Result := Integer(AAngle) + 2000;
end;

function TFakeEnvironment.FineTangent(const AAngle: LongWord): Integer;
begin
  Result := Integer(AAngle) + 3000;
end;

{ TFakeConsole }

procedure TFakeConsole.AddCommand(const ACommand: string);
begin
  Commands := Commands + ACommand + '|';
end;

function TFakeConsole.GetString(const AName: string): string;
begin
  LastName := AName;
  Result := 'text of ' + AName;
end;

function TFakeConsole.GetInteger(const AName: string): Integer;
begin
  LastName := AName;
  Result := Length(AName);
end;

function TFakeConsole.GetBoolean(const AName: string): Boolean;
begin
  LastName := AName;
  Result := AName = 'yes';
end;

function TFakeConsole.SetString(const AName, AValue: string): Boolean;
begin
  LastName := AName;
  LastValue := AValue;
  Result := AName <> 'unknown';
end;

function TFakeConsole.SetInteger(const AName: string; const AValue: Integer): Boolean;
begin
  LastName := AName;
  LastValue := IntToStr(AValue);
  Result := AName <> 'unknown';
end;

function TFakeConsole.SetBoolean(const AName: string; const AValue: Boolean): Boolean;
begin
  LastName := AName;
  LastValue := BoolToStr(AValue, True);
  Result := AName <> 'unknown';
end;

{ TFakeRandom }

function TFakeRandom.NextMenu: Integer;
begin
  Result := 0;
end;

function TFakeRandom.NextPlay: Integer;
begin
  Result := Numbers[FIndex mod Length(Numbers)];
  Inc(FIndex);
end;

function TFakeRandom.NextNonCompatible: Integer;
begin
  Result := 0;
end;

function TFakeRandom.NextUnpredictable: Integer;
begin
  Result := 0;
end;

function TFakeRandom.NextSystem: Integer;
begin
  Result := 0;
end;

function TFakeRandom.NextWithIndex(var AIndex: Integer): Integer;
begin
  Result := 0;
end;

function TFakeRandom.FromSeed(const ASeed: Integer): Integer;
begin
  Result := 0;
end;

procedure TFakeRandom.Clear;
begin
end;

procedure TFakeRandom.SavePlayIndex;
begin
end;

function TFakeRandom.RestorePlayIndex: Boolean;
begin
  Result := False;
end;

function TFakeRandom.HitscanAngle(const ASpread: TFixed): Integer;
begin
  Result := 0;
end;

function TFakeRandom.HitscanSlope(const ASpread: TFixed): Integer;
begin
  Result := 0;
end;

function TFakeRandom.GetMenuIndex: Integer;
begin
  Result := 0;
end;

procedure TFakeRandom.SetMenuIndex(const AValue: Integer);
begin
end;

function TFakeRandom.GetPlayIndex: Integer;
begin
  Result := FIndex;
end;

procedure TFakeRandom.SetPlayIndex(const AValue: Integer);
begin
  FIndex := AValue;
end;

function TFakeRandom.GetNonCompatibleIndex: Integer;
begin
  Result := 0;
end;

procedure TFakeRandom.SetNonCompatibleIndex(const AValue: Integer);
begin
end;

function TFakeRandom.GetSystemIndex: Integer;
begin
  Result := 0;
end;

procedure TFakeRandom.SetSystemIndex(const AValue: Integer);
begin
end;

function TFakeRandom.GetSystemSeed: Integer;
begin
  Result := 0;
end;

procedure TFakeRandom.SetSystemSeed(const AValue: Integer);
begin
end;

end.
