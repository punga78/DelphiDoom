{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the PS_FIXED unit of script                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The 9 functions of the fixed point numbers (the PS_FIXED lines of           }
{  ps_import.pas). They have no body here: scripts call the routines of the    }
{  engine (m_fixed) directly, so the unit only knows the declarations.         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Fixed.Functions;

interface

uses
  DelphiDoom.ScriptHost.Intf;

type
  /// <summary>The functions of the unit PS_FIXED, one slot for each</summary>
  TScriptFixedRoutine = (
    sfrFixedMul,
    sfrFixedDiv,
    sfrFixedSqrt,
    sfrFloatToFixed,
    sfrDoubleToFixed,
    sfrExtendedToFixed,
    sfrFixedToFloat,
    sfrFixedToDouble,
    sfrFixedToExtended
  );

  /// <summary>The routine that the interpreter calls for every function</summary>
  TScriptFixedRoutines = array[TScriptFixedRoutine] of Pointer;

  /// <summary>The unit PS_FIXED of the scripts</summary>
  TScriptFixedFunctions = class(TInterfacedObject, IScriptFunctionGroup)
  strict private
    FRoutines: TScriptFixedRoutines;
  public
    /// <param name="ARoutines">What the interpreter calls for every function</param>
    constructor Create(const ARoutines: TScriptFixedRoutines);
    function UnitName: string;
    procedure Describe(const ATable: IScriptFunctionTable);
  end;

const
  /// <summary>The declarations of the functions of PS_FIXED as the compiler of the scripts reads them</summary>
  SCRIPT_FIXED_DECLARATIONS: array[TScriptFixedRoutine] of string = (
    'function FixedMul(const a, b: fixed_t): fixed_t;',
    'function FixedDiv(const a, b: fixed_t): fixed_t;',
    'function FixedSqrt(const a: fixed_t): fixed_t;',
    'function FloatToFixed(const f: single): fixed_t;',
    'function DoubleToFixed(const f: double): fixed_t;',
    'function ExtendedToFixed(const f: extended): fixed_t;',
    'function FixedToFloat(const x: fixed_t): single;',
    'function FixedToDouble(const x: fixed_t): double;',
    'function FixedToExtended(const x: fixed_t): extended;'
  );

  /// <summary>The name of the unit</summary>
  SCRIPT_UNIT_FIXED = 'PS_FIXED';

implementation

{ TScriptFixedFunctions }

constructor TScriptFixedFunctions.Create(const ARoutines: TScriptFixedRoutines);
begin
  inherited Create;
  FRoutines := ARoutines;
end;

function TScriptFixedFunctions.UnitName: string;
begin
  Result := SCRIPT_UNIT_FIXED;
end;

procedure TScriptFixedFunctions.Describe(const ATable: IScriptFunctionTable);
var
  LRoutine: TScriptFixedRoutine;
begin
  for LRoutine := Low(TScriptFixedRoutine) to High(TScriptFixedRoutine) do
    ATable.Add(SCRIPT_FIXED_DECLARATIONS[LRoutine], FRoutines[LRoutine]);
end;

end.
