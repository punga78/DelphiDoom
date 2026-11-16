{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the marks on the map                          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.Marks;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Automap.Types, DelphiDoom.Automap.Intf;

type
  /// <summary>
  ///   A ring of marks (the old markpoints and markpointnum): AUTOMAP_MAX_MARKS places, the
  ///   oldest one is replaced when all are used
  /// </summary>
  /// <remarks>
  ///   As in the old code a mark with x equal to -1 means "empty", so a mark put exactly at that
  ///   x does not show.
  /// </remarks>
  TAutomapMarks = class(TInterfacedObject, IAutomapMarks)
  strict private
    FPoints: array[0..AUTOMAP_MAX_MARKS - 1] of TAutomapPoint;
    FNextIndex: Integer;
  public
    constructor Create;
    function GetCount: Integer;
    function GetNextIndex: Integer;
    procedure Add(const AX, AY: TFixed);
    procedure Clear;
    function IsUsed(const AIndex: Integer): Boolean;
    function Point(const AIndex: Integer): TAutomapPoint;
  end;

implementation

uses
  System.SysUtils;

const
  EMPTY_MARK = -1;

{ TAutomapMarks }

constructor TAutomapMarks.Create;
begin
  inherited Create;
  Clear;
end;

function TAutomapMarks.GetCount: Integer;
begin
  Result := AUTOMAP_MAX_MARKS;
end;

function TAutomapMarks.GetNextIndex: Integer;
begin
  Result := FNextIndex;
end;

procedure TAutomapMarks.Add(const AX, AY: TFixed);
begin
  FPoints[FNextIndex].X := AX;
  FPoints[FNextIndex].Y := AY;
  FNextIndex := (FNextIndex + 1) mod AUTOMAP_MAX_MARKS;
end;

procedure TAutomapMarks.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to AUTOMAP_MAX_MARKS - 1 do
    FPoints[LIndex].X := EMPTY_MARK;
  FNextIndex := 0;
end;

function TAutomapMarks.IsUsed(const AIndex: Integer): Boolean;
begin
  Result := Point(AIndex).X <> EMPTY_MARK;
end;

function TAutomapMarks.Point(const AIndex: Integer): TAutomapPoint;
begin
  if (AIndex < 0) or (AIndex >= AUTOMAP_MAX_MARKS) then
    raise EAutomapException.CreateFmt(SMarkIndexOutOfRange, [AIndex]);
  Result := FPoints[AIndex];
end;

end.
