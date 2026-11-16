{******************************************************************************}
{                                                                              }
{  DelphiDoom: actions library - the registry                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Actions.Registry;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Actions.Intf;

type
  /// <summary>The registry on a list of entries and two dictionaries (name and handler)</summary>
  TActionRegistry = class(TInterfacedObject, IActionRegistry)
  strict private
    FEntries: TList<TActionEntry>;
    FIndexByName: TDictionary<string, Integer>;
    FIndexByHandler: TDictionary<Pointer, Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    function Register(const AName: string; AHandler: Pointer;
      const ADefaultArguments: array of Integer; const ADeclaration: string): Integer;
    function Count: Integer;
    function Entry(AIndex: Integer): TActionEntry;
    function IndexOfName(const AName: string): Integer;
    function IndexOfHandler(AHandler: Pointer): Integer;
    function NameOfHandler(AHandler: Pointer): string;
    function Names: TArray<string>;
    function SortedNames: TArray<string>;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Defaults,
  DelphiDoom.Actions.Names;

resourcestring
  SActionConflict = 'The action %s is already registered with another handler';
  SActionIndexOutOfRange = 'The action index %d is out of range (0..%d)';

{ TActionRegistry }

constructor TActionRegistry.Create;
begin
  inherited Create;
  FEntries := TList<TActionEntry>.Create;
  FIndexByName := TDictionary<string, Integer>.Create;
  FIndexByHandler := TDictionary<Pointer, Integer>.Create;
end;

destructor TActionRegistry.Destroy;
begin
  FIndexByHandler.Free;
  FIndexByName.Free;
  FEntries.Free;
  inherited Destroy;
end;

function TActionRegistry.Register(const AName: string; AHandler: Pointer;
  const ADefaultArguments: array of Integer; const ADeclaration: string): Integer;
var
  LEntry: TActionEntry;
  LKey: string;
  LIndex: Integer;
  LArgument: Integer;
begin
  LEntry.Handler := AHandler;
  LEntry.OriginalName := TActionNames.StripPrefix(AName);
  LEntry.Name := TActionNames.UpperAscii(LEntry.OriginalName);
  SetLength(LEntry.DefaultArguments, Length(ADefaultArguments));
  for LArgument := 0 to High(ADefaultArguments) do
    LEntry.DefaultArguments[LArgument] := ADefaultArguments[LArgument];
  LEntry.Declaration := ADeclaration;

  LKey := TActionNames.Normalize(LEntry.Name);
  if FIndexByName.TryGetValue(LKey, LIndex) then
  begin
    if FEntries[LIndex].Handler <> AHandler then
      raise EActionRegistryException.CreateFmt(SActionConflict, [LEntry.Name]);
  end
  else
    FIndexByName.Add(LKey, FEntries.Count);

  Result := FEntries.Add(LEntry);
  if not FIndexByHandler.ContainsKey(AHandler) then
    FIndexByHandler.Add(AHandler, Result);
end;

function TActionRegistry.Count: Integer;
begin
  Result := FEntries.Count;
end;

function TActionRegistry.Entry(AIndex: Integer): TActionEntry;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    raise EActionRegistryException.CreateFmt(SActionIndexOutOfRange, [AIndex, FEntries.Count - 1]);
  Result := FEntries[AIndex];
  // a copy of the arguments: the caller cannot change the registry
  Result.DefaultArguments := Copy(Result.DefaultArguments);
end;

function TActionRegistry.IndexOfName(const AName: string): Integer;
begin
  if not FIndexByName.TryGetValue(TActionNames.Normalize(AName), Result) then
    Result := -1;
end;

function TActionRegistry.IndexOfHandler(AHandler: Pointer): Integer;
begin
  if not FIndexByHandler.TryGetValue(AHandler, Result) then
    Result := -1;
end;

function TActionRegistry.NameOfHandler(AHandler: Pointer): string;
var
  LIndex: Integer;
begin
  LIndex := IndexOfHandler(AHandler);
  if LIndex < 0 then
    Result := ''
  else
    Result := FEntries[LIndex].Name;
end;

function TActionRegistry.Names: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FEntries.Count);
  for LIndex := 0 to FEntries.Count - 1 do
    Result[LIndex] := FEntries[LIndex].Name;
end;

function TActionRegistry.SortedNames: TArray<string>;
var
  LSet: TList<string>;
  LIndex: Integer;
begin
  LSet := TList<string>.Create;
  try
    for LIndex := 0 to FEntries.Count - 1 do
      if not LSet.Contains(FEntries[LIndex].Name) then
        LSet.Add(FEntries[LIndex].Name);
    LSet.Sort(TComparer<string>.Construct(
      function(const ALeft, ARight: string): Integer
      begin
        Result := CompareStr(ALeft, ARight);
      end));
    Result := LSet.ToArray;
  finally
    LSet.Free;
  end;
end;

end.
