{******************************************************************************}
{                                                                              }
{  DelphiDoom: test shim of d_delphi for the per-game OpenGL scene tests        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Stands in for IdTech1\Common\d_delphi.pas in DelphiDoom.Tests.OpenGl.<Game> only: the scene units take
// from it the type float and the allocation helpers of the light buffer.
unit d_delphi;

interface

type
  float = Single;
  Pfloat = ^float;

  twointeger_t = record
    num1, num2: integer;
  end;

  /// <summary>The list of pairs of d_delphi (only what the scene units use: Add, Count, Numbers)</summary>
  T2DNumberList = class
  strict private
    FItems: array of twointeger_t;
    function Get(Index: Integer): twointeger_t;
  public
    function Add(const value1, value2: integer): integer;
    function Count: integer;
    property Numbers[Index: Integer]: twointeger_t read Get; default;
  end;

/// <summary>The realloc of d_delphi: a block of the new size that keeps the bytes of the old one</summary>
procedure realloc(var P: Pointer; const OldSize, NewSize: Integer);

implementation

function T2DNumberList.Get(Index: Integer): twointeger_t;
begin
  Result := FItems[Index];
end;

function T2DNumberList.Add(const value1, value2: integer): integer;
begin
  Result := Length(FItems);
  SetLength(FItems, Result + 1);
  FItems[Result].num1 := value1;
  FItems[Result].num2 := value2;
end;

function T2DNumberList.Count: integer;
begin
  Result := Length(FItems);
end;

procedure realloc(var P: Pointer; const OldSize, NewSize: Integer);
begin
  if NewSize = 0 then
  begin
    FreeMem(P, OldSize);
    P := nil;
  end
  else if NewSize <> OldSize then
    ReallocMem(P, NewSize);
end;

end.
