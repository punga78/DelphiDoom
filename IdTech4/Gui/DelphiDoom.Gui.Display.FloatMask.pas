{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - floating point exceptions of the input code       }
{                                                                              }
{  ui_shared.c never traps: a list box with an element height of zero divides  }
{  by zero and the integer conversion of the infinity gives the smallest       }
{  integer. Delphi raises an exception for the division by default.            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Display.FloatMask;

interface

uses
  System.Math;

type
  /// <summary>
  ///   Masks every arithmetic exception of the FPU from <c>Enter</c> until the returned interface is released,
  ///   then puts the mask back (x87 on Win32, SSE on Win64). Keep the result in a local variable.
  /// </summary>
  TGuiFloatMask = class(TInterfacedObject)
  strict private
    FSaved: TArithmeticExceptionMask;
  public
    constructor Create;
    destructor Destroy; override;
    class function Enter: IInterface; static;
  end;

implementation

constructor TGuiFloatMask.Create;
begin
  inherited Create;
  FSaved := SetExceptionMask(exAllArithmeticExceptions);
end;

destructor TGuiFloatMask.Destroy;
begin
  SetExceptionMask(FSaved);
  inherited Destroy;
end;

class function TGuiFloatMask.Enter: IInterface;
begin
  Result := TGuiFloatMask.Create;
end;

end.
