{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the builder                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Builder;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.CommandLine.Intf;

type
  /// <summary>Collects the arguments, up to the limit of the engine</summary>
  TCommandLineBuilder = class(TInterfacedObject, ICommandLineBuilder)
  private
    FItems: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AArgument: string): Boolean;
    procedure AddDefaultFile(const AText: string);
    function Count: Integer;
    function Build: ICommandLine;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types, DelphiDoom.CommandLine.Arguments, DelphiDoom.CommandLine.DefaultFile;

{ TCommandLineBuilder }

constructor TCommandLineBuilder.Create;
begin
  inherited Create;
  FItems := TList<string>.Create;
end;

destructor TCommandLineBuilder.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TCommandLineBuilder.Add(const AArgument: string): Boolean;
begin
  Result := (AArgument <> '') and (FItems.Count < COMMANDLINE_MAX_ARGUMENTS);
  if Result then
    FItems.Add(UpperCase(AArgument));
end;

procedure TCommandLineBuilder.AddDefaultFile(const AText: string);
var
  LArgument: string;
begin
  Add(COMMANDLINE_DEFAULT_MARKER);
  for LArgument in TDefaultArgumentsFile.Parse(AText) do
    if not Add(LArgument) then
      Break;
end;

function TCommandLineBuilder.Count: Integer;
begin
  Result := FItems.Count;
end;

function TCommandLineBuilder.Build: ICommandLine;
begin
  Result := TCommandLine.Create(FItems.ToArray);
  FItems.Clear;
end;

end.
