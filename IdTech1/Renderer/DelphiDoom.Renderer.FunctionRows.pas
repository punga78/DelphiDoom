{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the rows of the table of drawing functions   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_SetRenderingFunctions of r_main.pas                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.FunctionRows;

interface

type
  /// <summary>
  ///   One assignment of the table: in the detail level Detail and in the combinations of the flags that have their
  ///   bit set in Combos (bit n = the combination whose number is n) the variable that Slot points to gets Value.
  ///   Slot and Value are the size of a pointer: the variables are the procedural variables of the renderer
  /// </summary>
  TRendererFunctionRow = record
    Detail: Integer;
    Combos: Cardinal;
    Slot: PPointer;
    Value: Pointer;
  end;

  /// <summary>
  ///   Applies the rows of the table of drawing functions. It is the one pass of the old R_SetRenderingFunctions: it runs
  ///   when the detail level or a flag changes, never for a column, a span or a frame
  /// </summary>
  TRendererFunctionRows = class sealed
  public const
    /// <summary>The number of combinations that a Combos mask can hold</summary>
    MAX_COMBINATIONS = 32;
  public
    /// <summary>
    ///   Gives every variable of the rows of the level ADetail that are valid for the combination ACombination its value.
    ///   The variables that no row of the level and the combination names are not touched. EArgumentOutOfRangeException
    ///   when the combination is not from 0 to 31
    /// </summary>
    class procedure Apply(const ARows: array of TRendererFunctionRow; ADetail, ACombination: Integer); static;
  end;

implementation

uses
  System.SysUtils;

const
  SWrongCombination = 'The combination %d of the flags is not from 0 to %d';

{ TRendererFunctionRows }

class procedure TRendererFunctionRows.Apply(const ARows: array of TRendererFunctionRow; ADetail,
  ACombination: Integer);
var
  LIndex: Integer;
  LBit: Cardinal;
begin
  if (ACombination < 0) or (ACombination >= MAX_COMBINATIONS) then
    raise EArgumentOutOfRangeException.CreateFmt(SWrongCombination, [ACombination, MAX_COMBINATIONS - 1]);
  LBit := Cardinal(1) shl ACombination;
  for LIndex := Low(ARows) to High(ARows) do
    if (ARows[LIndex].Detail = ADetail) and ((ARows[LIndex].Combos and LBit) <> 0) then
      ARows[LIndex].Slot^ := ARows[LIndex].Value;
end;

end.
