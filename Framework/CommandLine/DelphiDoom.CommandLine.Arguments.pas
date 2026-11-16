{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the arguments                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Arguments;

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf;

type
  /// <summary>An immutable command line: the arguments are made upper case when it is made</summary>
  TCommandLine = class(TInterfacedObject, ICommandLine)
  private
    FItems: TArray<string>;
  public
    constructor Create(const AItems: TArray<string>);
    function GetCount: Integer;
    function GetItem(AIndex: Integer): string;
    function IndexOf(const AName: string): Integer;
    function Has(const AName: string): Boolean;
    function ValuesAfter(const AName: string): TArray<string>;
    function Text: string;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types;

const
  SBadPosition = 'The argument %d does not exist (there are %d)';

{ TCommandLine }

constructor TCommandLine.Create(const AItems: TArray<string>);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FItems, Length(AItems));
  for LIndex := 0 to High(AItems) do
    FItems[LIndex] := UpperCase(AItems[LIndex]);
end;

function TCommandLine.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TCommandLine.GetItem(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= Length(FItems)) then
    raise ECommandLineException.CreateFmt(SBadPosition, [AIndex, Length(FItems)]);
  Result := FItems[AIndex];
end;

function TCommandLine.IndexOf(const AName: string): Integer;
var
  LName: string;
begin
  LName := UpperCase(AName);
  for Result := 1 to High(FItems) do
    if FItems[Result] = LName then
      Exit;
  Result := 0;
end;

function TCommandLine.Has(const AName: string): Boolean;
begin
  Result := IndexOf(AName) > 0;
end;

function TCommandLine.ValuesAfter(const AName: string): TArray<string>;
var
  LStart, LEnd: Integer;
begin
  Result := nil;
  LStart := IndexOf(AName);
  if LStart = 0 then
    Exit;
  LEnd := LStart + 1;
  while (LEnd < Length(FItems)) and ((FItems[LEnd] = '') or (FItems[LEnd][1] <> '-')) do
    Inc(LEnd);
  Result := Copy(FItems, LStart + 1, LEnd - LStart - 1);
end;

function TCommandLine.Text: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to High(FItems) do
  begin
    if LIndex > 1 then
      Result := Result + ' ';
    Result := Result + FItems[LIndex];
  end;
end;

end.
