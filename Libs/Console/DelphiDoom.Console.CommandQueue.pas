{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the commands that wait                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CommandQueue;

interface

uses
  System.Generics.Collections, DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   The commands that the game asks to the console (old C_AddCommand): they run at the next
  ///   event, not where they are asked. Until the console is enabled they are dropped
  /// </summary>
  TConsoleCommandQueue = class
  private
    FInterpreter: IConsoleInterpreter;
    FPending: TList<string>;
    FEnabled: Boolean;
  public
    constructor Create(const AInterpreter: IConsoleInterpreter);
    destructor Destroy; override;
    procedure Enqueue(const ACommand: string);
    /// <summary>
    ///   Runs what is waiting, in order. A command that asks for another one does not run it
    ///   now: it waits for the next call
    /// </summary>
    procedure ExecutePending;
    function Count: Integer;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

implementation

uses
  System.SysUtils;

{ TConsoleCommandQueue }

constructor TConsoleCommandQueue.Create(const AInterpreter: IConsoleInterpreter);
begin
  inherited Create;
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create('AInterpreter');
  FInterpreter := AInterpreter;
  FPending := TList<string>.Create;
end;

destructor TConsoleCommandQueue.Destroy;
begin
  FPending.Free;
  inherited Destroy;
end;

procedure TConsoleCommandQueue.Enqueue(const ACommand: string);
begin
  if FEnabled then
    FPending.Add(ACommand);
end;

procedure TConsoleCommandQueue.ExecutePending;
var
  LCommands: TArray<string>;
  LCommand: string;
begin
  LCommands := FPending.ToArray;
  FPending.Clear;
  for LCommand in LCommands do
    FInterpreter.Execute(LCommand);
end;

function TConsoleCommandQueue.Count: Integer;
begin
  Result := FPending.Count;
end;

end.
