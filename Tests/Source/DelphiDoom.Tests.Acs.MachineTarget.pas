{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - the new machine as the target of a   }
{  scenario                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.MachineTarget;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Machine.Types, DelphiDoom.Acs.Machine.Intf,
  DelphiDoom.Logging.Intf, DelphiDoom.Tests.Acs.FakeWorld, DelphiDoom.Tests.Acs.FakeThinkers,
  DelphiDoom.Tests.Acs.Scenario;

type
  /// <summary>The machine of the library, with a fake host, driven by a scenario</summary>
  TAcsMachineTarget = class(TInterfacedObject, IAcsScenarioTarget)
  strict private
    FThinkers: TFakeThinkers;
    FMachine: IAcsMachine;
    FCode: TBytes;
  public
    constructor Create(AWorld: TFakeWorld; const ALog: ILog);
    destructor Destroy; override;
    procedure Load(const ACode: TBytes);
    function Start(ANumber, AMap: Integer; const AArguments: TAcsArguments;
      AActivator, ALine: Pointer; ASide: Integer): Boolean;
    function Suspend(ANumber: Integer): Boolean;
    function Terminate(ANumber: Integer): Boolean;
    procedure CheckStore;
    procedure NewGame;
    procedure TagFinished(ATag: Integer);
    procedure PolyobjectFinished(APolyobject: Integer);
    procedure Tick;
    function Snapshot: TAcsSnapshot;
    property Machine: IAcsMachine read FMachine;
    property Thinkers: TFakeThinkers read FThinkers;
  end;

implementation

uses
  DelphiDoom.Acs.Factory, DelphiDoom.Tests.Acs.FakeHost;

{ TAcsMachineTarget }

constructor TAcsMachineTarget.Create(AWorld: TFakeWorld; const ALog: ILog);
begin
  inherited Create;
  FThinkers := TFakeThinkers.Create;
  FMachine := TAcsFactory.CreateMachine(TFakeAcsHost.Create(AWorld, FThinkers), ALog);
end;

destructor TAcsMachineTarget.Destroy;
begin
  FMachine := nil;
  FThinkers.Free;
  inherited Destroy;
end;

procedure TAcsMachineTarget.Load(const ACode: TBytes);
begin
  FCode := ACode;
  if Length(FCode) > 0 then
    FMachine.Load(@FCode[0], Length(FCode))
  else
    FMachine.Load(nil, 0);
end;

function TAcsMachineTarget.Start(ANumber, AMap: Integer; const AArguments: TAcsArguments;
  AActivator, ALine: Pointer; ASide: Integer): Boolean;
begin
  Result := FMachine.StartScript(ANumber, AMap, AArguments, AActivator, ALine, ASide);
end;

function TAcsMachineTarget.Suspend(ANumber: Integer): Boolean;
begin
  Result := FMachine.SuspendScript(ANumber);
end;

function TAcsMachineTarget.Terminate(ANumber: Integer): Boolean;
begin
  Result := FMachine.TerminateScript(ANumber);
end;

procedure TAcsMachineTarget.CheckStore;
begin
  FMachine.CheckStore;
end;

procedure TAcsMachineTarget.NewGame;
begin
  FMachine.InitNewGame;
end;

procedure TAcsMachineTarget.TagFinished(ATag: Integer);
begin
  FMachine.TagFinished(ATag);
end;

procedure TAcsMachineTarget.PolyobjectFinished(APolyobject: Integer);
begin
  FMachine.PolyobjectFinished(APolyobject);
end;

procedure TAcsMachineTarget.Tick;
var
  LIndex: Integer;
begin
  LIndex := 0;
  while LIndex < FThinkers.Count do
  begin
    if FThinkers.Running(LIndex) then
      FMachine.Execute(PAcsScript(FThinkers.Item(LIndex)));
    Inc(LIndex);
  end;
end;

function TAcsMachineTarget.Snapshot: TAcsSnapshot;
var
  LIndex: Integer;
  LScript: PAcsScript;
begin
  SetLength(Result.States, FMachine.ScriptCount);
  SetLength(Result.WaitValues, FMachine.ScriptCount);
  for LIndex := 0 to FMachine.ScriptCount - 1 do
  begin
    Result.States[LIndex] := Ord(FMachine.ScriptState[LIndex]);
    Result.WaitValues[LIndex] := FMachine.ScriptWaitValue[LIndex];
  end;
  Result.MapVariables := FMachine.MapVariables;
  Result.WorldVariables := FMachine.WorldVariables;
  Result.Store := FMachine.Store;
  SetLength(Result.Scripts, FThinkers.Count);
  for LIndex := 0 to FThinkers.Count - 1 do
  begin
    LScript := PAcsScript(FThinkers.Item(LIndex));
    Result.Scripts[LIndex].Number := LScript.Number;
    Result.Scripts[LIndex].InfoIndex := LScript.InfoIndex;
    Result.Scripts[LIndex].DelayCount := LScript.DelayCount;
    Result.Scripts[LIndex].StackPtr := LScript.StackPtr;
    Result.Scripts[LIndex].IpOffset := NativeInt(LScript.Ip) - NativeInt(FMachine.CodeBase);
    Result.Scripts[LIndex].Side := LScript.Side;
    Result.Scripts[LIndex].Removed := not FThinkers.Running(LIndex);
    Move(LScript.Stack, Result.Scripts[LIndex].Stack, SizeOf(LScript.Stack));
    Move(LScript.Vars, Result.Scripts[LIndex].Vars, SizeOf(LScript.Vars));
  end;
end;

end.
