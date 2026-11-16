{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - reading the arguments one after another   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Cursor;

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   ICommandLineCursor over an ICommandLine: it starts after the name of the program. The name of a parameter is
  ///   given in lower case, its values as the command line has them
  /// </summary>
  TCommandLineCursor = class(TInterfacedObject, ICommandLineCursor)
  strict private
    FCommandLine: ICommandLine;
    FPosition: Integer;
    FName: string;
  public
    constructor Create(const ACommandLine: ICommandLine);
    function Next(out AName: string): Boolean;
    function Remaining: Integer;
    function Value: string;
    function IntegerValue: Integer;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types;

const
  SNeedsValue = '%s needs a value';
  SNeedsNumber = '%s needs a whole number, not "%s"';

constructor TCommandLineCursor.Create(const ACommandLine: ICommandLine);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create('ACommandLine');
  FCommandLine := ACommandLine;
  // position 0 is the name of the program
  FPosition := 1;
end;

function TCommandLineCursor.Next(out AName: string): Boolean;
begin
  Result := FPosition < FCommandLine.Count;
  if Result then
  begin
    FName := FCommandLine[FPosition].ToLowerInvariant;
    Inc(FPosition);
  end
  else
    FName := '';
  AName := FName;
end;

function TCommandLineCursor.Remaining: Integer;
begin
  Result := FCommandLine.Count - FPosition;
  if Result < 0 then
    Result := 0;
end;

function TCommandLineCursor.Value: string;
begin
  if Remaining = 0 then
    raise ECommandLineException.CreateFmt(SNeedsValue, [FName]);
  Result := FCommandLine[FPosition];
  Inc(FPosition);
end;

function TCommandLineCursor.IntegerValue: Integer;
var
  LText: string;
begin
  LText := Value;
  if not TryStrToInt(LText, Result) then
    raise ECommandLineException.CreateFmt(SNeedsNumber, [FName, LText]);
end;

end.
