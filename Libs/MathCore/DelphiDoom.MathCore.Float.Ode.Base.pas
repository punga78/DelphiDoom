{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdOde, base class of the ODE       }
{  solvers                                                                     }
{                                                                              }
{  Port of idODE (idlib\math\Ode.h) of the Doom 3 GPL Source Code. Copyright   }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom   }
{  3 GPL Source Code (id Software).                                            }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Ode.Base;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Float.Ode.Intf;

type
  /// <summary>
  ///   The common part of the solvers (idODE): dimension and derive function, which the
  ///   constructor receives (the C++ also takes a <c>userData</c> pointer, here the derive
  ///   function is a closure). The object is reference counted: hold it in an interface variable,
  ///   or free it by hand only while no interface reference is alive.
  /// </summary>
  TIdOde = class abstract(TInterfacedObject, IIdOde)
  strict private
    FDimension: Integer;
    FDerive: TIdOdeDeriveProc;
  protected
    /// <summary>Raises if a state array is shorter than the dimension</summary>
    procedure CheckArrays(const AState, ANewState: TArray<Single>);
    property Derive: TIdOdeDeriveProc read FDerive;
  public
    /// <param name="ADimension">Number of components of the state, not negative</param>
    /// <param name="ADerive">The derivative function, not nil</param>
    constructor Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
    function Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
      const AT0, AT1: Single): Single; virtual; abstract;
    function GetDimension: Integer;
    property Dimension: Integer read FDimension;
  end;

implementation

uses
  System.SysUtils;

const
  SDimensionNegative = 'The dimension of an ODE system cannot be negative';
  SStateTooShort = 'The state arrays must have at least Dimension elements';

{ TIdOde }

constructor TIdOde.Create(const ADimension: Integer; const ADerive: TIdOdeDeriveProc);
begin
  inherited Create;
  if not Assigned(ADerive) then
    raise EArgumentNilException.Create('ADerive');
  if ADimension < 0 then
    raise EArgumentOutOfRangeException.Create(SDimensionNegative);
  FDimension := ADimension;
  FDerive := ADerive;
end;

procedure TIdOde.CheckArrays(const AState, ANewState: TArray<Single>);
begin
  if (Length(AState) < FDimension) or (Length(ANewState) < FDimension) then
    raise EArgumentOutOfRangeException.Create(SStateTooShort);
end;

function TIdOde.GetDimension: Integer;
begin
  Result := FDimension;
end;

end.
