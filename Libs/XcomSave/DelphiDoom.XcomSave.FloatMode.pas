{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the precision of the x87 for the       }
{  trigonometry of the targets                                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.FloatMode;

interface

uses
  System.Math;

type
  /// <summary>
  ///   The precision of the x87 while the speeds of the targets are worked out: a 53 bit mantissa, so every
  ///   operation is rounded to a double as with SSE (the Delphi runtime keeps 64 bits). Enter changes the
  ///   precision (on Win32) and masks the arithmetic exceptions (a division by zero is an infinity or a not a
  ///   number, as in C++), and Leave puts both back. On Win64 (SSE) both are no-ops. The reference C++ runs on the
  ///   x87 with extended intermediates, so the last bit of a speed can still differ (see MovingTarget)
  /// </summary>
  TXcomFloatMode = record
  strict private
    FPrevious: TFPUPrecisionMode;
    FMask: TArithmeticExceptionMask;
  public
    /// <summary>Sets the double precision and remembers the one that was set</summary>
    class function Enter: TXcomFloatMode; static;
    /// <summary>Restores the precision that Enter found</summary>
    procedure Leave;
  end;

implementation

{ TXcomFloatMode }

class function TXcomFloatMode.Enter: TXcomFloatMode;
begin
  Result.FPrevious := SetPrecisionMode(pmDouble);
  // the C++ divides by zero and gets an infinity or a not a number, which it tests for: no exceptions
  Result.FMask := SetExceptionMask(exAllArithmeticExceptions);
end;

procedure TXcomFloatMode.Leave;
begin
  SetExceptionMask(FMask);
  SetPrecisionMode(FPrevious);
end;

end.
