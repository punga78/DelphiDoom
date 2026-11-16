{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixForceFieldRules                           }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of RX_ForceFieldThrust (radix_forcefield.pas) and of the force field   }
{  test of PIT_CheckLine (p_map.pas) of Rad-X                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Physics.ForceField;

// The angles are 32 bit binary angles: the subtraction wraps on purpose
{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The force fields of the sectors (the bit FORCEFIELD_MASK of the special of a sector of
  ///   Rad-X): a line between a sector with a field and one without stops a craft and throws
  ///   it back, away from the field
  /// </summary>
  TRadixForceFieldRules = class
  public const
    /// <summary>The bit of the special of a sector with a force field</summary>
    FORCEFIELD_MASK = $400;
    /// <summary>The speed a craft is thrown back with (map units a tic)</summary>
    THRUST = 30;
    /// <summary>A quarter of a turn</summary>
    ANG90 = $40000000;
    /// <summary>From a binary angle to the index of the tables of sines of the engine</summary>
    ANGLETOFINESHIFT = 19;
  public
    /// <summary>True when the special of a sector has a force field</summary>
    class function HasField(ASectorSpecial: Integer): Boolean; static;
    /// <summary>True when a two sided line stops a craft: one of its sectors only has a field</summary>
    class function BlocksCraft(AFrontSpecial, ABackSpecial: Integer): Boolean; static;
    /// <summary>
    ///   True when the direction of the line is taken from its first vertex to the second (the
    ///   field is in the back sector), false from the second to the first
    /// </summary>
    class function FromFirstVertex(ABackSpecial: Integer): Boolean; static;
    /// <summary>
    ///   The index in the tables of sines (finecosine for x, finesine for y) of the direction of
    ///   the thrust: a quarter of a turn to the right of the direction of the line
    /// </summary>
    /// <param name="ALineAngle">The angle of the direction that FromFirstVertex tells</param>
    class function ThrustFineAngle(ALineAngle: Cardinal): Integer; static;
    /// <summary>The momentum on one axis: THRUST times the value of the table (16.16)</summary>
    class function Momentum(AFineValue: Integer): Integer; static;
  end;

implementation

{ TRadixForceFieldRules }

class function TRadixForceFieldRules.HasField(ASectorSpecial: Integer): Boolean;
begin
  Result := ASectorSpecial and FORCEFIELD_MASK <> 0;
end;

class function TRadixForceFieldRules.BlocksCraft(AFrontSpecial, ABackSpecial: Integer): Boolean;
begin
  Result := HasField(AFrontSpecial) <> HasField(ABackSpecial);
end;

class function TRadixForceFieldRules.FromFirstVertex(ABackSpecial: Integer): Boolean;
begin
  Result := HasField(ABackSpecial);
end;

class function TRadixForceFieldRules.ThrustFineAngle(ALineAngle: Cardinal): Integer;
begin
  Result := Integer(Cardinal(ALineAngle - ANG90) shr ANGLETOFINESHIFT);
end;

class function TRadixForceFieldRules.Momentum(AFineValue: Integer): Integer;
begin
  Result := THRUST * AFineValue;
end;

end.
