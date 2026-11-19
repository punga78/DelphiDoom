{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R1) - the list of      }
{  drawSurfs                                                                   }
{                                                                              }
{  tr.refdef.drawSurfs, R_AddDrawSurf and R_DecomposeSort of renderer\tr_main.c }
{  (the entity number that the next surfaces are added for is              }
{  tr.shiftedEntityNum). Based on the Quake III Arena GPL Source Code (id      }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Draw.List;

interface

uses
  System.SysUtils, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf;

type
  /// <summary>
  ///   The array of 65536 drawSurf_t of a frame and the count of the ones added (the count can be above the size:
  ///   the index wraps, as the C does instead of checking for an overflow)
  /// </summary>
  TQ3DrawList = class
  strict private
    FShaders: IQ3ShaderTable;
    FSurfaces: TArray<TQ3DrawSurf>;
    FCount: Integer;
    FEntityNumber: Integer;
    FShiftedEntityNumber: Cardinal;
  public
    constructor Create(const AShaders: IQ3ShaderTable);
    /// <summary>tr.refdef.numDrawSurfs = 0 (R_ToggleSmpFrame at the end of a frame)</summary>
    procedure Clear;
    /// <summary>tr.currentEntityNum and tr.shiftedEntityNum: the entity the next surfaces are for</summary>
    procedure SetEntity(AEntityNumber: Integer);
    /// <summary>R_AddDrawSurf: AShader is an index of the shader table</summary>
    procedure Add(const ASurface: TQ3SurfaceRef; AShader, AFogIndex, ADlightMap: Integer);
    /// <summary>The surface at an index of the array (the index is masked as the C masks it)</summary>
    function Item(AIndex: Integer): TQ3DrawSurf;
    /// <summary>R_DecomposeSort: the entity number, the shader index (of the sorted list), the fog and the dlights</summary>
    class procedure Decompose(ASort: Cardinal; out AEntityNumber, ASortedShader, AFogNumber, ADlightMap: Integer);
    /// <summary>The array: the sort works on it in place</summary>
    /// <summary>qsortFast of the ACount surfaces from AFirst (the range of one view, in the array)</summary>
    procedure SortRange(AFirst, ACount: Integer);
    property Count: Integer read FCount write FCount;
    property EntityNumber: Integer read FEntityNumber;
  end;

implementation

uses
  DelphiDoom.Q3Render.Draw.Sorter;

procedure TQ3DrawList.SortRange(AFirst, ACount: Integer);
begin
  TQ3DrawSurfSorter.Sort(FSurfaces, AFirst, ACount);
end;

constructor TQ3DrawList.Create(const AShaders: IQ3ShaderTable);
begin
  inherited Create;
  if not Assigned(AShaders) then
    raise EArgumentNilException.Create('AShaders');
  FShaders := AShaders;
  SetLength(FSurfaces, Q3_MAX_DRAWSURFS);
end;

procedure TQ3DrawList.Clear;
begin
  FCount := 0;
end;

procedure TQ3DrawList.SetEntity(AEntityNumber: Integer);
begin
  FEntityNumber := AEntityNumber;
  FShiftedEntityNumber := Cardinal(AEntityNumber) shl Q3_QSORT_ENTITYNUM_SHIFT;
end;

procedure TQ3DrawList.Add(const ASurface: TQ3SurfaceRef; AShader, AFogIndex, ADlightMap: Integer);
var
  LIndex: Integer;
begin
  LIndex := FCount and Q3_DRAWSURF_MASK;
  // the sort data are packed in one 32 bit value that is compared while sorting
  FSurfaces[LIndex].Sort := (Cardinal(FShaders.SortedIndexOf(AShader)) shl Q3_QSORT_SHADERNUM_SHIFT) or
    FShiftedEntityNumber or (Cardinal(AFogIndex) shl Q3_QSORT_FOGNUM_SHIFT) or Cardinal(ADlightMap);
  FSurfaces[LIndex].Surface := ASurface;
  Inc(FCount);
end;

function TQ3DrawList.Item(AIndex: Integer): TQ3DrawSurf;
begin
  Result := FSurfaces[AIndex and Q3_DRAWSURF_MASK];
end;

class procedure TQ3DrawList.Decompose(ASort: Cardinal; out AEntityNumber, ASortedShader, AFogNumber,
  ADlightMap: Integer);
begin
  AFogNumber := (ASort shr Q3_QSORT_FOGNUM_SHIFT) and 31;
  ASortedShader := (ASort shr Q3_QSORT_SHADERNUM_SHIFT) and (Q3_MAX_SHADERS - 1);
  AEntityNumber := (ASort shr Q3_QSORT_ENTITYNUM_SHIFT) and 1023;
  ADlightMap := ASort and 3;
end;

end.
