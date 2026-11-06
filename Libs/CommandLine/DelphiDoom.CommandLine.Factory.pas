{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the factory: the composition root        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Factory;

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the library</summary>
  TCommandLineFactory = class
  public
    class function CreateBuilder: ICommandLineBuilder; static;
    /// <summary>A command line made of the given arguments, the program name first</summary>
    class function CreateCommandLine(const AArguments: TArray<string>): ICommandLine; static;
  end;

implementation

uses
  DelphiDoom.CommandLine.Builder, DelphiDoom.CommandLine.Arguments;

{ TCommandLineFactory }

class function TCommandLineFactory.CreateBuilder: ICommandLineBuilder;
begin
  Result := TCommandLineBuilder.Create;
end;

class function TCommandLineFactory.CreateCommandLine(const AArguments: TArray<string>): ICommandLine;
begin
  Result := TCommandLine.Create(AArguments);
end;

end.
