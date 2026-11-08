{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - the command line that remembers          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Queried;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.CommandLine.Intf;

type
  /// <summary>
  ///   Answers with the command line attached to it and remembers the parameters that were
  ///   asked for (what M_CheckParm did with its list of known parameters). Without an attached
  ///   command line every parameter is absent
  /// </summary>
  TQueriedCommandLine = class(TInterfacedObject, ICommandLine, IQueriedCommandLine)
  strict private
    FInner: ICommandLine;
    FNames: TList<string>;
    procedure Remember(const AName: string);
  public
    constructor Create;
    destructor Destroy; override;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): string;
    function IndexOf(const AName: string): Integer;
    function Has(const AName: string): Boolean;
    function ValuesAfter(const AName: string): TArray<string>;
    function Text: string;
    procedure Attach(const ACommandLine: ICommandLine);
    function QueriedNames: TArray<string>;
  end;

implementation

uses
  DelphiDoom.CommandLine.Types;

const
  SNoCommandLine = 'The command line was not attached yet: argument %d does not exist';

{ TQueriedCommandLine }

constructor TQueriedCommandLine.Create;
begin
  inherited Create;
  FNames := TList<string>.Create;
end;

destructor TQueriedCommandLine.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

procedure TQueriedCommandLine.Remember(const AName: string);
var
  LIndex: Integer;
begin
  // the same comparison of the old list of parameters (TDStrings.IndexOf)
  for LIndex := 0 to FNames.Count - 1 do
    if AnsiCompareText(FNames[LIndex], AName) = 0 then
      Exit;
  FNames.Add(AName);
end;

procedure TQueriedCommandLine.Attach(const ACommandLine: ICommandLine);
begin
  FInner := ACommandLine;
end;

function TQueriedCommandLine.QueriedNames: TArray<string>;
begin
  Result := FNames.ToArray;
end;

function TQueriedCommandLine.GetCount: Integer;
begin
  if Assigned(FInner) then
    Result := FInner.Count
  else
    Result := 0;
end;

function TQueriedCommandLine.GetItem(AIndex: Integer): string;
begin
  if not Assigned(FInner) then
    raise ECommandLineException.CreateFmt(SNoCommandLine, [AIndex]);
  Result := FInner[AIndex];
end;

function TQueriedCommandLine.IndexOf(const AName: string): Integer;
begin
  Remember(AName);
  if Assigned(FInner) then
    Result := FInner.IndexOf(AName)
  else
    Result := 0;
end;

function TQueriedCommandLine.Has(const AName: string): Boolean;
begin
  Result := IndexOf(AName) > 0;
end;

function TQueriedCommandLine.ValuesAfter(const AName: string): TArray<string>;
begin
  Remember(AName);
  if Assigned(FInner) then
    Result := FInner.ValuesAfter(AName)
  else
    Result := nil;
end;

function TQueriedCommandLine.Text: string;
begin
  if Assigned(FInner) then
    Result := FInner.Text
  else
    Result := '';
end;

end.
