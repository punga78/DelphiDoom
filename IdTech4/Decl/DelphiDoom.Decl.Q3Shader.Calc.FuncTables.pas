{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - the function tables           }
{                                                                              }
{  The "init function tables" loop of R_Init (renderer\tr_init.c) and          }
{  TableForFunc (renderer\tr_shade_calc.c) of Quake III Arena (id Software,    }
{  GPL v2 or later). Based on the Quake III Arena GPL Source Code (id          }
{  Software).                                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.FuncTables;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types;

type
  /// <summary>
  ///   <c>tr.sinTable</c>, <c>squareTable</c>, <c>triangleTable</c>, <c>sawToothTable</c> and
  ///   <c>inverseSawToothTable</c>: five tables of 1024 floats, computed once. The object holds no other state:
  ///   it can be shared by every calculation.
  /// </summary>
  TQ3FuncTables = class
  strict private
    FSin: TQ3FuncTable;
    FSquare: TQ3FuncTable;
    FTriangle: TQ3FuncTable;
    FSawTooth: TQ3FuncTable;
    FInverseSawTooth: TQ3FuncTable;
  public
    constructor Create;
    /// <summary>
    ///   TableForFunc: the table of a waveform function. <c>gfNone</c> and <c>gfNoise</c> have none (the noise
    ///   is not a table): <c>EDeclQ3ShaderCalcException</c>, the <c>ri.Error</c> of the original.
    /// </summary>
    function TableFor(const AFunc: TQ3GenFunc): TQ3FuncTable;
    /// <summary>tr.sinTable (the rotation, the turbulence and the bulge read it directly)</summary>
    property SinTable: TQ3FuncTable read FSin;
  end;

implementation

uses
  System.SysUtils;

const
  SNoTable = 'TableForFunc called with invalid function ''%d''';

constructor TQ3FuncTables.Create;
var
  LIndex: Integer;
  LAngle, LRadians, LStep: Single;
  LSize, LPi, L180: Single;
begin
  inherited Create;
  SetLength(FSin, Q3_FUNCTABLE_SIZE);
  SetLength(FSquare, Q3_FUNCTABLE_SIZE);
  SetLength(FTriangle, Q3_FUNCTABLE_SIZE);
  SetLength(FSawTooth, Q3_FUNCTABLE_SIZE);
  SetLength(FInverseSawTooth, Q3_FUNCTABLE_SIZE);
  // M_PI is a float constant in q_shared.h (3.14159265358979323846f)
  LPi := 3.14159265358979323846;
  L180 := 180.0;
  LSize := Q3_FUNCTABLE_SIZE - 1;
  for LIndex := 0 to Q3_FUNCTABLE_SIZE - 1 do
  begin
    // sin( DEG2RAD( i * 360.0f / ( ( float ) ( FUNCTABLE_SIZE - 1 ) ) ) ): every step a float, sin a double
    LStep := LIndex;
    LAngle := LStep * 360.0;
    LAngle := LAngle / LSize;
    LRadians := LAngle * LPi;
    LRadians := LRadians / L180;
    FSin[LIndex] := Sin(Double(LRadians));
    if LIndex < Q3_FUNCTABLE_SIZE div 2 then
      FSquare[LIndex] := 1.0
    else
      FSquare[LIndex] := -1.0;
    LStep := LIndex;
    FSawTooth[LIndex] := LStep / Q3_FUNCTABLE_SIZE;
    FInverseSawTooth[LIndex] := 1.0 - FSawTooth[LIndex];
    if LIndex < Q3_FUNCTABLE_SIZE div 2 then
    begin
      if LIndex < Q3_FUNCTABLE_SIZE div 4 then
        FTriangle[LIndex] := LStep / (Q3_FUNCTABLE_SIZE div 4)
      else
        FTriangle[LIndex] := 1.0 - FTriangle[LIndex - Q3_FUNCTABLE_SIZE div 4];
    end
    else
      FTriangle[LIndex] := -FTriangle[LIndex - Q3_FUNCTABLE_SIZE div 2];
  end;
end;

function TQ3FuncTables.TableFor(const AFunc: TQ3GenFunc): TQ3FuncTable;
begin
  case AFunc of
    gfSin:
      Result := FSin;
    gfTriangle:
      Result := FTriangle;
    gfSquare:
      Result := FSquare;
    gfSawtooth:
      Result := FSawTooth;
    gfInverseSawtooth:
      Result := FInverseSawTooth;
  else
    raise EDeclQ3ShaderCalcException.CreateFmt(SNoTable, [Ord(AFunc)]);
  end;
end;

end.
