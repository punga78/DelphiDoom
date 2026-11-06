{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the list of the commands                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CommandLister;

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>Writes the names of the commands that fit a mask, and how many they are (old C_CmdList)</summary>
  TConsoleCommandLister = class
  private
    FRegistry: ICommandRegistry;
    FOutput: IConsoleOutput;
  public
    constructor Create(const ARegistry: ICommandRegistry; const AOutput: IConsoleOutput);
    /// <summary>An empty mask lists them all. The names are sorted</summary>
    procedure List(const AMask: string);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.MaskMatcher;

const
  LINE_BREAK = #13#10;

{ TConsoleCommandLister }

constructor TConsoleCommandLister.Create(const ARegistry: ICommandRegistry;
  const AOutput: IConsoleOutput);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  FRegistry := ARegistry;
  FOutput := AOutput;
end;

procedure TConsoleCommandLister.List(const AMask: string);
var
  LNames: TArray<string>;
  LName: string;
begin
  LNames := FRegistry.Names;
  if AMask <> '' then
    LNames := TConsoleMaskMatcher.Filter(LNames, AMask);
  for LName in LNames do
    FOutput.Write(LName + LINE_BREAK);
  FOutput.Write(Format('%d total commands.', [Length(LNames)]) + LINE_BREAK);
end;

end.
