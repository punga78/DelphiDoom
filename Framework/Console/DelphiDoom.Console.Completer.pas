{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - completion with TAB                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Completer;

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Finds the names of the commands and of the variables that start with what the user
  ///   typed. The old console had no completion: this is new, and does not change the old rules
  /// </summary>
  TConsoleCompleter = class
  private
    FRegistry: ICommandRegistry;
    FVariables: IConsoleVariableSource;
  public
    /// <summary>AVariables may be nil: then only the commands are completed</summary>
    constructor Create(const ARegistry: ICommandRegistry; const AVariables: IConsoleVariableSource);
    /// <summary>The names in lower case, sorted, without repetitions. An empty prefix gives all of them</summary>
    function Candidates(const APrefix: string): TArray<string>;
    /// <summary>The longest start that all the names share (empty if there are none)</summary>
    class function CommonPrefix(const ANames: TArray<string>): string; static;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Console.Text;

{ TConsoleCompleter }

constructor TConsoleCompleter.Create(const ARegistry: ICommandRegistry;
  const AVariables: IConsoleVariableSource);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  FRegistry := ARegistry;
  FVariables := AVariables;
end;

function TConsoleCompleter.Candidates(const APrefix: string): TArray<string>;
var
  LFound: TList<string>;
  LPrefix: string;
  LName: string;
  LIndex: Integer;

  procedure AddIfFits(const AName: string);
  var
    LLower: string;
  begin
    LLower := TConsoleText.LowerCase(AName);
    if TConsoleText.StartsWith(LPrefix, LLower) and not LFound.Contains(LLower) then
      LFound.Add(LLower);
  end;

begin
  LPrefix := TConsoleText.LowerCase(APrefix);
  LFound := TList<string>.Create;
  try
    for LName in FRegistry.Names do
      AddIfFits(LName);
    if Assigned(FVariables) then
      for LIndex := 0 to FVariables.Count - 1 do
        AddIfFits(FVariables.Item(LIndex).Name);
    LFound.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer
      begin
        Result := CompareStr(ALeft, ARight);
      end));
    Result := LFound.ToArray;
  finally
    LFound.Free;
  end;
end;

class function TConsoleCompleter.CommonPrefix(const ANames: TArray<string>): string;
var
  LIndex: Integer;
  LLength: Integer;
begin
  if Length(ANames) = 0 then
    Exit('');
  Result := ANames[0];
  for LIndex := 1 to High(ANames) do
  begin
    LLength := 0;
    while (LLength < Length(Result)) and (LLength < Length(ANames[LIndex])) and
      (Result[LLength + 1] = ANames[LIndex][LLength + 1]) do
      Inc(LLength);
    Result := Copy(Result, 1, LLength);
  end;
end;

end.
