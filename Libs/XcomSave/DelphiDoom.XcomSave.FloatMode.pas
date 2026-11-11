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
    const
      /// <summary>The precision control field of the x87 control word (bits 8 and 9)</summary>
      PRECISION_MASK = $0300;
      /// <summary>The value of the field for a 53 bit mantissa</summary>
      PRECISION_DOUBLE = $0200;
    var
      FPrevious: Word;
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
{$IFDEF CPUX86}
var
  LControl: Word;
{$ENDIF}
begin
  // the control word is written directly: SetPrecisionMode of System.Math does the same but is marked as
  // specific to a platform
{$IFDEF CPUX86}
  LControl := Get8087CW;
  Result.FPrevious := LControl and PRECISION_MASK;
  Set8087CW((LControl and not PRECISION_MASK) or PRECISION_DOUBLE);
{$ELSE}
  Result.FPrevious := 0;
{$ENDIF}
  // the C++ divides by zero and gets an infinity or a not a number, which it tests for: no exceptions
  Result.FMask := SetExceptionMask(exAllArithmeticExceptions);
end;

procedure TXcomFloatMode.Leave;
begin
  SetExceptionMask(FMask);
{$IFDEF CPUX86}
  Set8087CW((Get8087CW and not PRECISION_MASK) or FPrevious);
{$ENDIF}
end;

end.
