{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - floating point exceptions     }
{                                                                              }
{  The C of renderer\tr_shade_calc.c never traps: a division by zero or an     }
{  overflow gives an infinity or a NaN that the next comparison or conversion  }
{  turns into a number. Delphi raises an exception for them by default.        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.FloatMask;

interface

uses
  System.Math;

type
  /// <summary>
  ///   Masks every arithmetic exception of the FPU from <c>Enter</c> until the returned interface is released
  ///   (the end of the method that holds it), then puts the mask back as it was. Win32 (x87) and Win64 (SSE).
  /// </summary>
  TQ3FloatMask = class(TInterfacedObject)
  strict private
    FSaved: TArithmeticExceptionMask;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Starts the masking: keep the result in a local variable of the method</summary>
    class function Enter: IInterface; static;
  end;

implementation

constructor TQ3FloatMask.Create;
begin
  inherited Create;
  FSaved := SetExceptionMask(exAllArithmeticExceptions);
end;

destructor TQ3FloatMask.Destroy;
begin
  SetExceptionMask(FSaved);
  inherited Destroy;
end;

class function TQ3FloatMask.Enter: IInterface;
begin
  Result := TQ3FloatMask.Create;
end;

end.
