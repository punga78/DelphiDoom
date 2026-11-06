{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the table of the sines of the engine          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.SineTable;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   fixedsine of tables.pas: entry i is round($FFFF * sin((0.5 + i) / $10000 * 2 * pi)),
  ///   for five quarters of the circle (the last one lets cosine be read at an offset).
  ///   It is computed once; the test compares it with the table of the engine
  /// </summary>
  TImagingFixedSineTable = class(TInterfacedObject, IImagingSineTable)
  private
    FValues: TArray<Integer>;
  public
    constructor Create;
    function Sine(AIndex: Integer): Integer;
  end;

implementation

{ TImagingFixedSineTable }

constructor TImagingFixedSineTable.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FValues, IMAGING_SINE_TABLE_SIZE);
  for LIndex := 0 to IMAGING_SINE_TABLE_SIZE - 1 do
    FValues[LIndex] := Round($FFFF * Sin((0.5 + LIndex) / $10000 * 2 * Pi));
end;

function TImagingFixedSineTable.Sine(AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= Length(FValues)) then
    raise EImagingException.Create(SImagingBadSineTable);
  Result := FValues[AIndex];
end;

end.
