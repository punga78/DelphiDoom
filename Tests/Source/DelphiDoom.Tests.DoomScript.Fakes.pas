{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - the fake host           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Fakes;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Random, DelphiDoom.Scanner.IdDict,
  DelphiDoom.DoomScript.Intf;

type
  /// <summary>
  ///   A host with a clock the test moves by hand, the random generator of idLib with seed 0 and a list
  ///   of the calls the library made to the world ("HOST name arguments")
  /// </summary>
  TDoomScriptFakeHost = class(TInterfacedObject, IDoomScriptHost, IDoomScriptWorld)
  private
    FRandom: TIdRandom;
    FCalls: TStringList;
    FNextSpawn: Integer;
    FFoundEntity: Integer;
  public
    Time: Integer;
    FrameMsec: Integer;
    RealClientTime: Integer;
    DebugScriptOn: Boolean;
    DeveloperOn: Boolean;
    DisassembleOn: Boolean;
    /// <summary>The prefix of the path of the operating system ('' = the paths are not changed)</summary>
    BasePath: AnsiString;
    constructor Create;
    destructor Destroy; override;
    function GetTime: Integer;
    function GetFrameMsec: Integer;
    function GetRealClientTime: Integer;
    function RandomFloat: Single;
    function RelativePathToOSPath(const APath: AnsiString): AnsiString;
    function OSPathToRelativePath(const APath: AnsiString): AnsiString;
    function DebugScript: Boolean;
    function Developer: Boolean;
    function Disassemble: Boolean;
    procedure DebugPrintf(const AText: string);
    function FindEntity(const AName: AnsiString): Integer;
    function SpawnEntity(const ASpawnArgs: TIdDict): Integer;
    procedure CopyEntitySpawnArgs(const AEntityNumber: Integer; const ATarget: TIdDict);
    procedure SetSignal(const AEntityNumber, ASignal, AThreadNum: Integer; const AFunctionName: AnsiString);
    procedure ClearSignalThread(const AEntityNumber, ASignal, AThreadNum: Integer);
    property Calls: TStringList read FCalls;
    /// <summary>What <c>SpawnEntity</c> answers (-1 = nothing spawned)</summary>
    property NextSpawn: Integer read FNextSpawn write FNextSpawn;
    /// <summary>What <c>FindEntity</c> answers</summary>
    property FoundEntity: Integer read FFoundEntity write FFoundEntity;
  end;

implementation

constructor TDoomScriptFakeHost.Create;
begin
  inherited Create;
  FCalls := TStringList.Create;
  FRandom := TIdRandom.Create(0);
  FrameMsec := 16;
  FNextSpawn := -1;
  FFoundEntity := -1;
end;

destructor TDoomScriptFakeHost.Destroy;
begin
  FCalls.Free;
  inherited;
end;

function TDoomScriptFakeHost.GetTime: Integer;
begin
  Result := Time;
end;

function TDoomScriptFakeHost.GetFrameMsec: Integer;
begin
  Result := FrameMsec;
end;

function TDoomScriptFakeHost.GetRealClientTime: Integer;
begin
  Result := RealClientTime;
end;

function TDoomScriptFakeHost.RandomFloat: Single;
begin
  Result := FRandom.RandomFloat;
end;

function TDoomScriptFakeHost.RelativePathToOSPath(const APath: AnsiString): AnsiString;
begin
  Result := BasePath + APath;
end;

function TDoomScriptFakeHost.OSPathToRelativePath(const APath: AnsiString): AnsiString;
begin
  if (BasePath <> '') and (Copy(APath, 1, Length(BasePath)) = BasePath) then
    Result := Copy(APath, Length(BasePath) + 1, MaxInt)
  else if BasePath = '' then
    Result := APath
  else
    Result := '';
end;

function TDoomScriptFakeHost.DebugScript: Boolean;
begin
  Result := DebugScriptOn;
end;

function TDoomScriptFakeHost.Developer: Boolean;
begin
  Result := DeveloperOn;
end;

function TDoomScriptFakeHost.Disassemble: Boolean;
begin
  Result := DisassembleOn;
end;

procedure TDoomScriptFakeHost.DebugPrintf(const AText: string);
begin
  FCalls.Add('DPRINT ' + AText);
end;

function TDoomScriptFakeHost.FindEntity(const AName: AnsiString): Integer;
begin
  FCalls.Add('HOST FindEntity ' + string(AName));
  Result := FFoundEntity;
end;

function TDoomScriptFakeHost.SpawnEntity(const ASpawnArgs: TIdDict): Integer;
var
  LIndex: Integer;
  LPair: TIdKeyValue;
  LText: string;
begin
  LText := 'HOST SpawnEntity';
  for LIndex := 0 to ASpawnArgs.GetNumKeyVals - 1 do
    if ASpawnArgs.TryGetKeyVal(LIndex, LPair) then
      LText := LText + ' ' + string(LPair.Key) + '=' + string(LPair.Value);
  FCalls.Add(LText);
  Result := FNextSpawn;
end;

procedure TDoomScriptFakeHost.CopyEntitySpawnArgs(const AEntityNumber: Integer; const ATarget: TIdDict);
begin
  FCalls.Add(Format('HOST CopyEntitySpawnArgs %d', [AEntityNumber]));
  ATarget.SetValue('copied', AnsiString(IntToStr(AEntityNumber)));
end;

procedure TDoomScriptFakeHost.SetSignal(const AEntityNumber, ASignal, AThreadNum: Integer;
  const AFunctionName: AnsiString);
begin
  FCalls.Add(Format('HOST SetSignal %d %d %d %s', [AEntityNumber, ASignal, AThreadNum, string(AFunctionName)]));
end;

procedure TDoomScriptFakeHost.ClearSignalThread(const AEntityNumber, ASignal, AThreadNum: Integer);
begin
  FCalls.Add(Format('HOST ClearSignalThread %d %d %d', [AEntityNumber, ASignal, AThreadNum]));
end;

end.
