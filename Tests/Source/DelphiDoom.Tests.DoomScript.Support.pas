{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - shared helpers          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.Support;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>Helpers shared by the fixtures of the Doom script library</summary>
  TDoomScriptTestSupport = class
  public
    /// <summary>Runs the code and checks that it raises exactly this class with exactly this message</summary>
    class procedure ExpectError(const AProc: TProc; const AClass: ExceptClass; const AMessage: string); static;
    /// <summary>Runs the code and checks that it raises exactly this class</summary>
    class procedure ExpectClass(const AProc: TProc; const AClass: ExceptClass); static;
  end;

implementation

class procedure TDoomScriptTestSupport.ExpectError(const AProc: TProc; const AClass: ExceptClass;
  const AMessage: string);
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    AProc();
  except
    on E: Exception do
    begin
      LRaised := True;
      Assert.AreEqual(AClass.ClassName, E.ClassName, 'exception class');
      Assert.AreEqual(AMessage, E.Message, 'exception message');
    end;
  end;
  Assert.IsTrue(LRaised, 'no exception, expected: ' + AMessage);
end;

class procedure TDoomScriptTestSupport.ExpectClass(const AProc: TProc; const AClass: ExceptClass);
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    AProc();
  except
    on E: Exception do
    begin
      LRaised := True;
      Assert.AreEqual(AClass.ClassName, E.ClassName, 'exception class');
    end;
  end;
  Assert.IsTrue(LRaised, 'no exception, expected ' + AClass.ClassName);
end;

end.
