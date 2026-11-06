{******************************************************************************}
{                                                                              }
{  DelphiDoom: math core library - the queue of integers                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.IntegerQueue;

interface

uses
  System.Generics.Collections;

type
  /// <summary>A first in, first out queue of integers (the TIntegerQueue of the old m_stack)</summary>
  TIntegerQueue = class
  private
    FItems: TList<Integer>;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a number at the end (the old Add)</summary>
    procedure Add(const AValue: Integer);
    /// <summary>Takes the first number; False (and AValue untouched) if the queue is empty</summary>
    function Remove(var AValue: Integer): Boolean;
    procedure Clear;
    property Count: Integer read GetCount;
  end;

implementation

{ TIntegerQueue }

constructor TIntegerQueue.Create;
begin
  inherited Create;
  FItems := TList<Integer>.Create;
end;

destructor TIntegerQueue.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TIntegerQueue.GetCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TIntegerQueue.Add(const AValue: Integer);
begin
  FItems.Add(AValue);
end;

function TIntegerQueue.Remove(var AValue: Integer): Boolean;
begin
  Result := FItems.Count > 0;
  if Result then
  begin
    AValue := FItems[0];
    FItems.Delete(0);
  end;
end;

procedure TIntegerQueue.Clear;
begin
  FItems.Clear;
end;

end.
