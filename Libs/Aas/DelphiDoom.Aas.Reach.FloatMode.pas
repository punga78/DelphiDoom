{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the floating point mode of the C code             }
{                                                                              }
{  The reachability code of Quake III never traps (a division by zero or the   }
{  square root of a negative number gives infinity or not a number) and the C  }
{  compiler for SSE rounds every operation to its type. Delphi unmasks the     }
{  exceptions by default and its x87 code of Win32 rounds to 64 bits of        }
{  mantissa: a double operation is rounded twice, once to 64 and once to 53    }
{  bits. This sets the masks and the precision of the double for the time of   }
{  a calculation. Not derived from the original.                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.FloatMode;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  System.Math;

type
  /// <summary>Masks every arithmetic exception and rounds to 53 bits until the interface is released</summary>
  TAasReachFloatMode = class(TInterfacedObject)
  strict private
    FSavedMask: TArithmeticExceptionMask;
    FSavedPrecision: TFPUPrecisionMode;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Keep the result in a local variable: the mode goes back when it goes out of scope</summary>
    class function Enter: IInterface; static;
  end;

implementation

{ TAasReachFloatMode }

constructor TAasReachFloatMode.Create;
begin
  inherited Create;
  FSavedMask := SetExceptionMask(exAllArithmeticExceptions);
  FSavedPrecision := SetPrecisionMode(pmDouble);
end;

destructor TAasReachFloatMode.Destroy;
begin
  SetPrecisionMode(FSavedPrecision);
  SetExceptionMask(FSavedMask);
  inherited Destroy;
end;

class function TAasReachFloatMode.Enter: IInterface;
begin
  Result := TAasReachFloatMode.Create;
end;

end.
