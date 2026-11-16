{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the arguments as they were written        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Verbatim;

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   An immutable command line that keeps the case of every argument (TCommandLine makes them upper case, as the
  ///   engine of Doom wants): for the programs whose arguments are names of files, texts to show or scripts. The
  ///   names of the parameters are still found whatever their case
  /// </summary>
  TVerbatimCommandLine = class(TInterfacedObject, ICommandLine)
  strict private
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

constructor TVerbatimCommandLine.Create(const AItems: TArray<string>);
begin
  inherited Create;
  // a copy: the caller may change its array afterwards
  FItems := Copy(AItems);
end;

function TVerbatimCommandLine.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TVerbatimCommandLine.GetItem(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= Length(FItems)) then
    raise ECommandLineException.CreateFmt(SBadPosition, [AIndex, Length(FItems)]);
  Result := FItems[AIndex];
end;

function TVerbatimCommandLine.IndexOf(const AName: string): Integer;
begin
  for Result := 1 to High(FItems) do
    if SameText(FItems[Result], AName) then
      Exit;
  Result := 0;
end;

function TVerbatimCommandLine.Has(const AName: string): Boolean;
begin
  Result := IndexOf(AName) > 0;
end;

function TVerbatimCommandLine.ValuesAfter(const AName: string): TArray<string>;
var
  LStart: Integer;
  LEnd: Integer;
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

function TVerbatimCommandLine.Text: string;
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
