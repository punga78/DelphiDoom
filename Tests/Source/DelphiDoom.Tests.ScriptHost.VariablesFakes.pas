{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes of the tests of the variables of the scripts              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.VariablesFakes;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.ScriptHost.Variables.Intf;

type
  /// <summary>Files in memory</summary>
  TFakeVariablesFiles = class(TInterfacedObject, IScriptVariablesFiles)
  public
    Files: TDictionary<string, TBytes>;
    Reads: Integer;
    Writes: Integer;
    constructor Create;
    destructor Destroy; override;
    function ReadFile(const AName: string): TBytes;
    procedure WriteFile(const AName: string; const ABytes: TBytes);
  end;

  /// <summary>Remembers the failures (the application would stop)</summary>
  TFakeVariablesFailure = class(TInterfacedObject, IScriptVariablesFailure)
  public
    Messages: TList<string>;
    constructor Create;
    destructor Destroy; override;
    procedure Report(const AMessage: string);
  end;

implementation

{ TFakeVariablesFiles }

constructor TFakeVariablesFiles.Create;
begin
  inherited Create;
  Files := TDictionary<string, TBytes>.Create;
end;

destructor TFakeVariablesFiles.Destroy;
begin
  Files.Free;
  inherited Destroy;
end;

function TFakeVariablesFiles.ReadFile(const AName: string): TBytes;
begin
  Inc(Reads);
  Result := Files[AName];
end;

procedure TFakeVariablesFiles.WriteFile(const AName: string; const ABytes: TBytes);
begin
  Inc(Writes);
  Files.AddOrSetValue(AName, Copy(ABytes));
end;

{ TFakeVariablesFailure }

constructor TFakeVariablesFailure.Create;
begin
  inherited Create;
  Messages := TList<string>.Create;
end;

destructor TFakeVariablesFailure.Destroy;
begin
  Messages.Free;
  inherited Destroy;
end;

procedure TFakeVariablesFailure.Report(const AMessage: string);
begin
  Messages.Add(AMessage);
end;

end.
