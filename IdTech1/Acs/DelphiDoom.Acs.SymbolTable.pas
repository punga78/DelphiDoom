{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the symbols                               }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.SymbolTable;

interface

uses
  System.Generics.Collections;

type
  TAcsSymbolKind = (
    SY_LABEL,
    SY_SCRIPTVAR,
    SY_MAPVAR,
    SY_WORLDVAR,
    SY_SPECIAL,
    SY_CONSTANT,
    SY_INTERNFUNC
  );

  /// <summary>What a symbol says; only the fields of its kind mean something</summary>
  TAcsSymbolInfo = record
    /// <summary>A variable: its place among the variables of its kind</summary>
    svar: record
      index: Integer;
    end;
    /// <summary>A line special</summary>
    special: record
      value: Integer;
      argCount: Integer;
    end;
    /// <summary>A #define</summary>
    constant: record
      value: Integer;
    end;
    /// <summary>A function of the language</summary>
    internFunc: record
      directCommand: Integer;
      stackCommand: Integer;
      argCount: Integer;
      hasReturnValue: Boolean;
    end;
  end;

  TAcsSymbol = class
  public
    name: string;
    typ: TAcsSymbolKind;
    info: TAcsSymbolInfo;
  end;

  /// <summary>
  ///   The global symbols (functions, specials, constants, map and world variables) and the
  ///   local ones (the variables of the script being compiled, forgotten at the next script)
  /// </summary>
  TAcsSymbolTable = class
  private
    FGlobals: TDictionary<string, TAcsSymbol>;
    FLocals: TDictionary<string, TAcsSymbol>;
    FOwned: TObjectList<TAcsSymbol>;
    function Insert(const AName: string; AKind: TAcsSymbolKind;
      const ATable: TDictionary<string, TAcsSymbol>): TAcsSymbol;
    procedure DefineInternalFunctions;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The symbol is not found by name if there is one with the same name already</summary>
    function InsertGlobal(const AName: string; AKind: TAcsSymbolKind): TAcsSymbol;
    function InsertLocal(const AName: string; AKind: TAcsSymbolKind): TAcsSymbol;
    /// <summary>Globals first, then locals; nil if there is none</summary>
    function Find(const AName: string): TAcsSymbol;
    function FindGlobal(const AName: string): TAcsSymbol;
    function FindLocal(const AName: string): TAcsSymbol;
    procedure FreeLocals;
  end;

implementation

uses
  DelphiDoom.Acs.PCodes;

type
  TInternalFunction = record
    Name: string;
    DirectCommand: Integer;
    StackCommand: Integer;
    ArgCount: Integer;
    HasReturnValue: Boolean;
  end;

const
  INTERNAL_FUNCTIONS: array[0..20] of TInternalFunction = (
    (Name: 'tagwait'; DirectCommand: PCD_TAGWAITDIRECT; StackCommand: PCD_TAGWAIT; ArgCount: 1; HasReturnValue: False),
    (Name: 'polywait'; DirectCommand: PCD_POLYWAITDIRECT; StackCommand: PCD_POLYWAIT; ArgCount: 1; HasReturnValue: False),
    (Name: 'scriptwait'; DirectCommand: PCD_SCRIPTWAITDIRECT; StackCommand: PCD_SCRIPTWAIT; ArgCount: 1; HasReturnValue: False),
    (Name: 'delay'; DirectCommand: PCD_DELAYDIRECT; StackCommand: PCD_DELAY; ArgCount: 1; HasReturnValue: False),
    (Name: 'random'; DirectCommand: PCD_RANDOMDIRECT; StackCommand: PCD_RANDOM; ArgCount: 2; HasReturnValue: True),
    (Name: 'thingcount'; DirectCommand: PCD_THINGCOUNTDIRECT; StackCommand: PCD_THINGCOUNT; ArgCount: 2; HasReturnValue: True),
    (Name: 'changefloor'; DirectCommand: PCD_CHANGEFLOORDIRECT; StackCommand: PCD_CHANGEFLOOR; ArgCount: 2; HasReturnValue: False),
    (Name: 'changeceiling'; DirectCommand: PCD_CHANGECEILINGDIRECT; StackCommand: PCD_CHANGECEILING; ArgCount: 2; HasReturnValue: False),
    (Name: 'lineside'; DirectCommand: PCD_NOP; StackCommand: PCD_LINESIDE; ArgCount: 0; HasReturnValue: True),
    (Name: 'clearlinespecial'; DirectCommand: PCD_NOP; StackCommand: PCD_CLEARLINESPECIAL; ArgCount: 0; HasReturnValue: False),
    (Name: 'playercount'; DirectCommand: PCD_NOP; StackCommand: PCD_PLAYERCOUNT; ArgCount: 0; HasReturnValue: True),
    (Name: 'gametype'; DirectCommand: PCD_NOP; StackCommand: PCD_GAMETYPE; ArgCount: 0; HasReturnValue: True),
    (Name: 'gameskill'; DirectCommand: PCD_NOP; StackCommand: PCD_GAMESKILL; ArgCount: 0; HasReturnValue: True),
    (Name: 'timer'; DirectCommand: PCD_NOP; StackCommand: PCD_TIMER; ArgCount: 0; HasReturnValue: True),
    (Name: 'sectorsound'; DirectCommand: PCD_NOP; StackCommand: PCD_SECTORSOUND; ArgCount: 2; HasReturnValue: False),
    (Name: 'ambientsound'; DirectCommand: PCD_NOP; StackCommand: PCD_AMBIENTSOUND; ArgCount: 2; HasReturnValue: False),
    (Name: 'soundsequence'; DirectCommand: PCD_NOP; StackCommand: PCD_SOUNDSEQUENCE; ArgCount: 1; HasReturnValue: False),
    (Name: 'setlinetexture'; DirectCommand: PCD_NOP; StackCommand: PCD_SETLINETEXTURE; ArgCount: 4; HasReturnValue: False),
    (Name: 'setlineblocking'; DirectCommand: PCD_NOP; StackCommand: PCD_SETLINEBLOCKING; ArgCount: 2; HasReturnValue: False),
    (Name: 'setlinespecial'; DirectCommand: PCD_NOP; StackCommand: PCD_SETLINESPECIAL; ArgCount: 7; HasReturnValue: False),
    (Name: 'thingsound'; DirectCommand: PCD_NOP; StackCommand: PCD_THINGSOUND; ArgCount: 3; HasReturnValue: False)
  );

{ TAcsSymbolTable }

constructor TAcsSymbolTable.Create;
begin
  inherited Create;
  FGlobals := TDictionary<string, TAcsSymbol>.Create;
  FLocals := TDictionary<string, TAcsSymbol>.Create;
  FOwned := TObjectList<TAcsSymbol>.Create(True);
  DefineInternalFunctions;
end;

destructor TAcsSymbolTable.Destroy;
begin
  FOwned.Free;
  FLocals.Free;
  FGlobals.Free;
  inherited Destroy;
end;

procedure TAcsSymbolTable.DefineInternalFunctions;
var
  LIndex: Integer;
  LSymbol: TAcsSymbol;
begin
  for LIndex := Low(INTERNAL_FUNCTIONS) to High(INTERNAL_FUNCTIONS) do
  begin
    LSymbol := InsertGlobal(INTERNAL_FUNCTIONS[LIndex].Name, SY_INTERNFUNC);
    LSymbol.info.internFunc.directCommand := INTERNAL_FUNCTIONS[LIndex].DirectCommand;
    LSymbol.info.internFunc.stackCommand := INTERNAL_FUNCTIONS[LIndex].StackCommand;
    LSymbol.info.internFunc.argCount := INTERNAL_FUNCTIONS[LIndex].ArgCount;
    LSymbol.info.internFunc.hasReturnValue := INTERNAL_FUNCTIONS[LIndex].HasReturnValue;
  end;
end;

function TAcsSymbolTable.Insert(const AName: string; AKind: TAcsSymbolKind;
  const ATable: TDictionary<string, TAcsSymbol>): TAcsSymbol;
begin
  Result := TAcsSymbol.Create;
  Result.name := AName;
  Result.typ := AKind;
  FOwned.Add(Result);
  // a name that is there already keeps its symbol: the new one cannot be found
  if not ATable.ContainsKey(AName) then
    ATable.Add(AName, Result);
end;

function TAcsSymbolTable.InsertGlobal(const AName: string; AKind: TAcsSymbolKind): TAcsSymbol;
begin
  Result := Insert(AName, AKind, FGlobals);
end;

function TAcsSymbolTable.InsertLocal(const AName: string; AKind: TAcsSymbolKind): TAcsSymbol;
begin
  Result := Insert(AName, AKind, FLocals);
end;

function TAcsSymbolTable.FindGlobal(const AName: string): TAcsSymbol;
begin
  if not FGlobals.TryGetValue(AName, Result) then
    Result := nil;
end;

function TAcsSymbolTable.FindLocal(const AName: string): TAcsSymbol;
begin
  if not FLocals.TryGetValue(AName, Result) then
    Result := nil;
end;

function TAcsSymbolTable.Find(const AName: string): TAcsSymbol;
begin
  Result := FindGlobal(AName);
  if not Assigned(Result) then
    Result := FindLocal(AName);
end;

procedure TAcsSymbolTable.FreeLocals;
begin
  // the symbols stay owned until the table goes: the parser may still hold one
  FLocals.Clear;
end;

end.
