{******************************************************************************}
{                                                                              }
{  DelphiDoom: sources and host functions shared by the tests of the Script    }
{  library                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Samples;

interface

const
  // Smallest valid source
  SOURCE_SUM: AnsiString =
    'program Test;' + #13#10 +
    'function Somma(a, b: Integer): Integer;' + #13#10 +
    'begin' + #13#10 +
    '  Result := a + b;' + #13#10 +
    'end;' + #13#10 +
    'begin' + #13#10 +
    'end.';

  // Functions on every kind of value, a runtime error and global variables
  SOURCE_RICH: AnsiString =
    'program Rich;' + #13#10 +
    'var' + #13#10 +
    '  Counter: Integer;' + #13#10 +
    '  Total: Integer;' + #13#10 +
    'function Somma(a, b: Integer): Integer;' + #13#10 +
    'begin' + #13#10 +
    '  Result := a + b;' + #13#10 +
    'end;' + #13#10 +
    'function Media(a, b: Double): Double;' + #13#10 +
    'begin' + #13#10 +
    '  Result := (a + b) / 2;' + #13#10 +
    'end;' + #13#10 +
    'function Unisci(a, b: string): string;' + #13#10 +
    'begin' + #13#10 +
    '  Result := a + b;' + #13#10 +
    'end;' + #13#10 +
    'function Dividi(a, b: Integer): Integer;' + #13#10 +
    'begin' + #13#10 +
    '  Result := a div b;' + #13#10 +
    'end;' + #13#10 +
    'procedure Incrementa;' + #13#10 +
    'begin' + #13#10 +
    '  Counter := Counter + 1;' + #13#10 +
    'end;' + #13#10 +
    'begin' + #13#10 +
    '  Counter := 10;' + #13#10 +
    '  Total := 5;' + #13#10 +
    'end.';

  // Calls the three host functions
  SOURCE_HOST: AnsiString =
    'program Host;' + #13#10 +
    'function Raddoppia(x: Integer): Integer;' + #13#10 +
    'begin' + #13#10 +
    '  Result := HostDouble(x) + 1;' + #13#10 +
    'end;' + #13#10 +
    'function Lunghezza(s: string): Integer;' + #13#10 +
    'begin' + #13#10 +
    '  Result := HostLength(s);' + #13#10 +
    'end;' + #13#10 +
    'function SommaStd(a, b: Integer): Integer;' + #13#10 +
    'begin' + #13#10 +
    '  Result := HostAddStd(a, b);' + #13#10 +
    'end;' + #13#10 +
    'begin' + #13#10 +
    'end.';

  // The unknown identifier is on the third line
  SOURCE_UNKNOWN_IDENTIFIER: AnsiString =
    'program Wrong;' + #13#10 +
    'begin' + #13#10 +
    '  Missing := 1;' + #13#10 +
    'end.';

  // Declarations of the host functions, as the compiler and the executor
  // receive them
  DECLARATION_HOST_DOUBLE: AnsiString = 'function HostDouble(a: Integer): Integer;';
  DECLARATION_HOST_LENGTH: AnsiString = 'function HostLength(s: string): Integer;';
  DECLARATION_HOST_ADDSTD: AnsiString = 'function HostAddStd(a, b: Integer): Integer;';

/// <summary>
///   Host function with the Delphi register convention, the one of the engine
/// </summary>
function HostDouble(AValue: Integer): Integer;

/// <summary>
///   Host function with a string parameter: reaches it as an AnsiString that
///   it only reads
/// </summary>
function HostLength(const AText: AnsiString): Integer;

/// <summary>
///   Host function with the stdcall convention
/// </summary>
function HostAddStd(AFirst, ASecond: Integer): Integer; stdcall;

implementation

function HostDouble(AValue: Integer): Integer;
begin
  Result := AValue * 2;
end;

function HostLength(const AText: AnsiString): Integer;
begin
  Result := Length(AText);
end;

function HostAddStd(AFirst, ASecond: Integer): Integer; stdcall;
begin
  Result := AFirst + ASecond;
end;

end.
