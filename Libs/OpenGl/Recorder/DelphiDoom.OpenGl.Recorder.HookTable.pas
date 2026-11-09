{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - the table of the functions to hook       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.HookTable;

interface

uses
  System.Generics.Collections,
  DelphiDoom.OpenGl.Recorder.Intf;

type
  /// <summary>
  ///   A list of (name, variable, thunk) that implements IGlHookTable. The generated unit fills it
  ///   (it knows the variables of the binding); the tests fill it with variables of their own.
  ///   The originals go to the array the thunks read from, if one is given, otherwise to an array
  ///   of the table.
  /// </summary>
  TGlHookTable = class(TInterfacedObject, IGlHookTable)
  strict private
    type
      TEntry = record
        Name: string;
        Slot: PPointer;
        Thunk: Pointer;
      end;
  strict private
    FEntries: TList<TEntry>;
    FOriginals: PPointerArray;
    FOwnOriginals: TArray<Pointer>;
  public
    /// <summary>AOriginals is the array the thunks read the original functions from (nil: the table keeps its own)</summary>
    constructor Create(const AOriginals: PPointerArray = nil);
    destructor Destroy; override;
    /// <summary>Adds a function: its name, the address of its variable, the address of its thunk</summary>
    procedure Add(const AName: string; const ASlot: PPointer; const AThunk: Pointer);
    function Count: Integer;
    function Name(const AIndex: Integer): string;
    function Slot(const AIndex: Integer): PPointer;
    function Thunk(const AIndex: Integer): Pointer;
    procedure SetOriginal(const AIndex: Integer; const AValue: Pointer);
    /// <summary>The original saved for a function (for the tests)</summary>
    function Original(const AIndex: Integer): Pointer;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.OpenGl.Recorder.Types;

resourcestring
  SGlHookTableIndex = 'The hook table has no function number %d';

{ TGlHookTable }

constructor TGlHookTable.Create(const AOriginals: PPointerArray);
begin
  inherited Create;
  FEntries := TList<TEntry>.Create;
  FOriginals := AOriginals;
end;

destructor TGlHookTable.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TGlHookTable.Add(const AName: string; const ASlot: PPointer; const AThunk: Pointer);
var
  LEntry: TEntry;
begin
  LEntry.Name := AName;
  LEntry.Slot := ASlot;
  LEntry.Thunk := AThunk;
  FEntries.Add(LEntry);
  if not Assigned(FOriginals) then
    SetLength(FOwnOriginals, FEntries.Count);
end;

function TGlHookTable.Count: Integer;
begin
  Result := FEntries.Count;
end;

function TGlHookTable.Name(const AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    raise EGlRecorderException.CreateFmt(SGlHookTableIndex, [AIndex]);
  Result := FEntries[AIndex].Name;
end;

function TGlHookTable.Slot(const AIndex: Integer): PPointer;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    raise EGlRecorderException.CreateFmt(SGlHookTableIndex, [AIndex]);
  Result := FEntries[AIndex].Slot;
end;

function TGlHookTable.Thunk(const AIndex: Integer): Pointer;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    raise EGlRecorderException.CreateFmt(SGlHookTableIndex, [AIndex]);
  Result := FEntries[AIndex].Thunk;
end;

procedure TGlHookTable.SetOriginal(const AIndex: Integer; const AValue: Pointer);
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    raise EGlRecorderException.CreateFmt(SGlHookTableIndex, [AIndex]);
  if Assigned(FOriginals) then
    FOriginals^[AIndex] := AValue
  else
    FOwnOriginals[AIndex] := AValue;
end;

function TGlHookTable.Original(const AIndex: Integer): Pointer;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    raise EGlRecorderException.CreateFmt(SGlHookTableIndex, [AIndex]);
  if Assigned(FOriginals) then
    Result := FOriginals^[AIndex]
  else
    Result := FOwnOriginals[AIndex];
end;

end.
