{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - the list of the thinkers of the      }
{  scripts                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.FakeThinkers;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  /// <summary>
  ///   What the engine does with the thinkers of the scripts: they run in the order they were
  ///   added, one that is added while the others run runs in the same tic, one that is removed does
  ///   not run any more. The memory of a script is zeroed and freed with the list
  /// </summary>
  TFakeThinkers = class
  strict private
    FItems: TList<Pointer>;
    FRemoved: TList<Boolean>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A block of memory with all zeroes, in the list</summary>
    function Allocate(ASize: Integer): Pointer;
    procedure Remove(AItem: Pointer);
    function IsRemoved(AItem: Pointer): Boolean;
    function Count: Integer;
    function Item(AIndex: Integer): Pointer;
    function Running(AIndex: Integer): Boolean;
    procedure Clear;
  end;

implementation

{ TFakeThinkers }

constructor TFakeThinkers.Create;
begin
  inherited Create;
  FItems := TList<Pointer>.Create;
  FRemoved := TList<Boolean>.Create;
end;

destructor TFakeThinkers.Destroy;
begin
  Clear;
  FRemoved.Free;
  FItems.Free;
  inherited Destroy;
end;

procedure TFakeThinkers.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FItems.Count - 1 do
    FreeMem(FItems[LIndex]);
  FItems.Clear;
  FRemoved.Clear;
end;

function TFakeThinkers.Allocate(ASize: Integer): Pointer;
begin
  GetMem(Result, ASize);
  FillChar(Result^, ASize, 0);
  FItems.Add(Result);
  FRemoved.Add(False);
end;

procedure TFakeThinkers.Remove(AItem: Pointer);
var
  LIndex: Integer;
begin
  LIndex := FItems.IndexOf(AItem);
  if LIndex >= 0 then
    FRemoved[LIndex] := True;
end;

function TFakeThinkers.IsRemoved(AItem: Pointer): Boolean;
var
  LIndex: Integer;
begin
  LIndex := FItems.IndexOf(AItem);
  Result := (LIndex >= 0) and FRemoved[LIndex];
end;

function TFakeThinkers.Count: Integer;
begin
  Result := FItems.Count;
end;

function TFakeThinkers.Item(AIndex: Integer): Pointer;
begin
  Result := FItems[AIndex];
end;

function TFakeThinkers.Running(AIndex: Integer): Boolean;
begin
  Result := not FRemoved[AIndex];
end;

end.
