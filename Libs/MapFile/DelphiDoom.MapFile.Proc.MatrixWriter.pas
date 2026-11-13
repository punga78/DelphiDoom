{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - numbers of a .proc file as dmap writes them  }
{                                                                              }
{  Port of WriteFloat and Write1DMatrix (output.cpp of dmap), Doom 3 GPL       }
{  Source Code.                                                                }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.MatrixWriter;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MapFile.TextWriter;

type
  /// <summary>
  ///   A float that is within 0.001 of an integer is written as that integer, any other with
  ///   the format "%f" (see TMapTextWriter.AddFloat); a matrix is "( v v v ) " with a space
  ///   after every number and after the closing parenthesis; indexes are "i " with a line break
  ///   after every 18
  /// </summary>
  TProcMatrixWriter = class
  public
    class procedure WriteFloat(const AOutput: TMapTextWriter; const AValue: Single); static;
    class procedure Write1DMatrix(const AOutput: TMapTextWriter; const AValues: array of Single); static;
    /// <summary>The run of indexes, each followed by a space, then a line break if the last line is not full</summary>
    class procedure WriteIndexes(const AOutput: TMapTextWriter; const AIndexes: TArray<Integer>); static;
  end;

implementation

uses
  DelphiDoom.Geometry.FloatMath, DelphiDoom.MapFile.Proc.Types;

{ TProcMatrixWriter }

class procedure TProcMatrixWriter.WriteFloat(const AOutput: TMapTextWriter; const AValue: Single);
var
  LRounded: Single;
begin
  LRounded := TGeoMath.Rint(AValue);
  if Abs(AValue - LRounded) < 0.001 then
    AOutput.AddInteger(Integer(Trunc(LRounded)))
  else
    AOutput.AddFloat(AValue);
  AOutput.Add(' ');
end;

class procedure TProcMatrixWriter.Write1DMatrix(const AOutput: TMapTextWriter;
  const AValues: array of Single);
var
  LIndex: Integer;
begin
  AOutput.Add('( ');
  for LIndex := 0 to High(AValues) do
    WriteFloat(AOutput, AValues[LIndex]);
  AOutput.Add(') ');
end;

class procedure TProcMatrixWriter.WriteIndexes(const AOutput: TMapTextWriter;
  const AIndexes: TArray<Integer>);
var
  LIndex, LColumn: Integer;
begin
  LColumn := 0;
  for LIndex := 0 to High(AIndexes) do
  begin
    AOutput.AddInteger(AIndexes[LIndex]);
    AOutput.Add(' ');
    Inc(LColumn);
    if LColumn = PROC_INDEXES_PER_LINE then
    begin
      LColumn := 0;
      AOutput.Add(#10);
    end;
  end;
  if LColumn <> 0 then
    AOutput.Add(#10);
end;

end.
