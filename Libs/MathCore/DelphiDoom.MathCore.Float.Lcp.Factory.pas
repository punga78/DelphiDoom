{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdLcpFactory, the only place that  }
{  knows the LCP solver classes                                                }
{                                                                              }
{  Port of idLCP::AllocSquare and idLCP::AllocSymmetric (idlib\math\Lcp.cpp)   }
{  of the Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a   }
{  ZeniMax Media company. Based on the Doom 3 GPL Source Code (id Software).   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Lcp.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.MathCore.Float.Lcp.Intf;

type
  /// <summary>Creates the solvers with the default maximum number of iterations (32)</summary>
  TIdLcpFactory = class sealed
  public
    /// <summary>A solver for any square matrix (LU); the log may be nil</summary>
    class function AllocSquare(const ALog: ILog = nil;
      const AShowFailures: Boolean = False): IIdLcp; static;
    /// <summary>A solver for a symmetric matrix (LDL'); the log may be nil</summary>
    class function AllocSymmetric(const ALog: ILog = nil;
      const AShowFailures: Boolean = False): IIdLcp; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Lcp.Square, DelphiDoom.MathCore.Float.Lcp.Symmetric;

{ TIdLcpFactory }

class function TIdLcpFactory.AllocSquare(const ALog: ILog; const AShowFailures: Boolean): IIdLcp;
begin
  Result := TIdLcpSquare.Create(ALog, AShowFailures);
  Result.SetMaxIterations(LCP_DEFAULT_MAX_ITERATIONS);
end;

class function TIdLcpFactory.AllocSymmetric(const ALog: ILog;
  const AShowFailures: Boolean): IIdLcp;
begin
  Result := TIdLcpSymmetric.Create(ALog, AShowFailures);
  Result.SetMaxIterations(LCP_DEFAULT_MAX_ITERATIONS);
end;

end.
