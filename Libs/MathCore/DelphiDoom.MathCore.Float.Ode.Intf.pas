{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - contract of the ODE solvers         }
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
unit DelphiDoom.MathCore.Float.Ode.Intf;

{$Q-}
{$R-}

interface

type
  /// <summary>
  ///   The derivative function of the system (<c>deriveFunction_t</c> of the original): writes in
  ///   <c>ADerivatives</c> the derivative of every component of <c>AState</c> at time <c>ATime</c>.
  ///   The <c>userData</c> pointer of the C++ is a capture of the method. Both arrays have at
  ///   least <c>Dimension</c> elements; the function must not change the length of the arrays.
  /// </summary>
  TIdOdeDeriveProc = reference to procedure(const ATime: Single; const AState: TArray<Single>;
    var ADerivatives: TArray<Single>);

  /// <summary>A numerical solver of an ordinary differential equation system (idODE)</summary>
  IIdOde = interface
    ['{6D7B9E52-3C51-4F8E-9A0B-2E5C41A7D3F1}']
    /// <summary>
    ///   Advances the system from time <c>AT0</c> to <c>AT1</c> and writes the new state in
    ///   <c>ANewState</c> (it may be the same array as <c>AState</c> for Euler and midpoint, not
    ///   for the RK4 solvers, as in the original); returns the time step the solver actually
    ///   covered (the adaptive solver can return more than <c>AT1 - AT0</c>)
    /// </summary>
    function Evaluate(const AState: TArray<Single>; var ANewState: TArray<Single>;
      const AT0, AT1: Single): Single;
    /// <summary>The number of components of the state</summary>
    function GetDimension: Integer;
    property Dimension: Integer read GetDimension;
  end;

  /// <summary>The RK4 solver with an error estimate (idODE_RK4Adaptive)</summary>
  IIdOdeAdaptive = interface(IIdOde)
    ['{0B4F6A18-95C2-4D07-8E13-7A9D3C60B5E2}']
    function GetMaxError: Single;
    /// <summary>Sets the maximum relative error; a value that is not positive is ignored</summary>
    procedure SetMaxError(const AError: Single);
    property MaxError: Single read GetMaxError write SetMaxError;
  end;

implementation

end.
