{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the stack of integers                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.IntegerStack;

interface

uses
  System.Generics.Collections;

type
  /// <summary>
  ///   A last in, first out stack of integers (the TIntegerStack of the old m_stack, without
  ///   the global stack: who needs one owns one)
  /// </summary>
  TIntegerStack = class
  private
    FItems: TList<Integer>;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(const AValue: Integer);
    /// <summary>Takes the last number; False (and AValue untouched) if the stack is empty</summary>
    function Pop(var AValue: Integer): Boolean;
    procedure Clear;
    property Count: Integer read GetCount;
  end;

implementation

{ TIntegerStack }

constructor TIntegerStack.Create;
begin
  inherited Create;
  FItems := TList<Integer>.Create;
end;

destructor TIntegerStack.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TIntegerStack.GetCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TIntegerStack.Push(const AValue: Integer);
begin
  FItems.Add(AValue);
end;

function TIntegerStack.Pop(var AValue: Integer): Boolean;
begin
  Result := FItems.Count > 0;
  if Result then
  begin
    AValue := FItems[FItems.Count - 1];
    FItems.Delete(FItems.Count - 1);
  end;
end;

procedure TIntegerStack.Clear;
begin
  FItems.Clear;
end;

end.
