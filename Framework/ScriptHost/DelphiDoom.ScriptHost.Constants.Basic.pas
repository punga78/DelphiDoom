{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the basic constants of every script               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Constants.Basic;

interface

uses
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>NaN, Infinity, NegInfinity and MAXINT: they do not depend on the game</summary>
  TScriptBasicConstants = class(TInterfacedObject, IScriptConstantProvider)
  public
    procedure Describe(const ATable: IScriptConstantTable);
  end;

implementation

uses
  System.Math;

{ TScriptBasicConstants }

procedure TScriptBasicConstants.Describe(const ATable: IScriptConstantTable);
begin
  // the constants of System.Math are the 0.0 / 0.0 and 1.0 / 0.0 of the old code, folded by the
  // compiler (a division at run time would raise with the exceptions of the FPU unmasked)
  ATable.AddExtended('NaN', System.Math.NaN);
  ATable.AddExtended('Infinity', System.Math.Infinity);
  ATable.AddExtended('NegInfinity', System.Math.NegInfinity);
  ATable.AddInteger('MAXINT', MaxInt);
end;

end.
