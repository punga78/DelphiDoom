{******************************************************************************}
{                                                                              }
{  DelphiDoom: a test that needs the data of the real game and does not find   }
{  it is ignored, not passed                                                   }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 2 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.Skip;

interface

type
  /// <summary>
  ///   The data of X-COM (Reference\_dati\xcom_tftd, xcom_ufo) and the parity files made from it are not in the
  ///   repository. A test that cannot find them, or whose scenario does not have what it needs (a soldier with a
  ///   clip to unload), checks nothing: it must not be counted among the passed ones
  /// </summary>
  TXcomTestSkip = class
  public
    /// <summary>
    ///   Ends the test as ignored (the runner counts it in "Tests Ignored") and writes the reason in its log.
    ///   Raises: the code after the call does not run
    /// </summary>
    class procedure Ignore(const AReason: string); static;
  end;

implementation

uses
  DUnitX.TestFramework, DUnitX.Exceptions;

class procedure TXcomTestSkip.Ignore(const AReason: string);
begin
  // the runner does not keep the message of the exception: the reason goes to the log of the test
  TDUnitX.CurrentRunner.Log(TLogLevel.Warning, 'ignorato: ' + AReason);
  raise ETestIgnored.Create(AReason);
end;

end.
