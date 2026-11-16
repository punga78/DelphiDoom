{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the report of an exception of the loop  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.MainExceptionReport;

// The main loop of every game is inside "try DoomMain except ... end": a Delphi exception (an access
// violation of the code of the game, a range error) did not reach the unhandled exception filter and
// the program ended with code 0 and no trace (issue #168, docs\PENDING_ISSUES.md). The report is the
// text that the handler writes in crash.txt; it works at 32 and at 64 bit because it needs only the
// class, the message and the address of the exception.

interface

uses
  System.SysUtils;

type
  TMainExceptionReport = class
  public
    /// <summary>
    ///   The text of crash.txt: the class and the message of the exception, where it happened (the
    ///   offset from the image base, the number to look for in the map file of the linker) and
    ///   the bitness of the program
    /// </summary>
    /// <param name="AClassName">The class of the exception, or an empty text when it is not an object</param>
    /// <param name="AAddress">The address of the exception</param>
    /// <param name="AImageBase">The address where the program is loaded</param>
    class function Build(const AClassName, AMessage: string; AAddress, AImageBase: NativeUInt): string; static;
    /// <summary>The code that the program ends with after an exception of the loop</summary>
    class function ExitCode: Integer; static;
  end;

implementation

const
  EXIT_CODE_EXCEPTION = 1;

{ TMainExceptionReport }

class function TMainExceptionReport.Build(const AClassName, AMessage: string; AAddress,
  AImageBase: NativeUInt): string;
var
  LClass: string;
begin
  LClass := AClassName;
  if LClass = '' then
    LClass := 'unknown exception';
  Result := 'Unhandled exception in the main loop' + #13#10 +
    'Exception: ' + LClass + #13#10 +
    'Message: ' + AMessage + #13#10;
  if AAddress >= AImageBase then
    Result := Result + Format('Address: %s (offset %s from the image base %s)', [
      IntToHex(AAddress, SizeOf(NativeUInt) * 2), IntToHex(AAddress - AImageBase, 8),
      IntToHex(AImageBase, SizeOf(NativeUInt) * 2)]) + #13#10
  else
    Result := Result + Format('Address: %s (outside of the program)', [IntToHex(AAddress, SizeOf(NativeUInt) * 2)]) +
      #13#10;
  Result := Result + Format('Program: %d bit, find the offset in the .map file next to the executable',
    [SizeOf(Pointer) * 8]) + #13#10;
end;

class function TMainExceptionReport.ExitCode: Integer;
begin
  Result := EXIT_CODE_EXCEPTION;
end;

end.
