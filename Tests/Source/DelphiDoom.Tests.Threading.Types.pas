{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the threading library - the exceptions                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Threading.Types;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('threading')]
  TTestThreadingTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeTenereClasseEMessaggioDellEccezioneOriginale;
    [Test]
    procedure DovrebbeMettereClasseEMessaggioNelTesto;
    [Test]
    procedure DovrebbeEssereUnErroreDellaLibreria;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Threading.Types;

procedure TTestThreadingTypes.DovrebbeTenereClasseEMessaggioDellEccezioneOriginale;
var
  LError: EWorkerJobException;
begin
  LError := EWorkerJobException.Create('EAccessViolation', 'nowhere');
  try
    Assert.AreEqual('EAccessViolation', LError.OriginalClassName);
    Assert.AreEqual('nowhere', LError.OriginalMessage);
  finally
    LError.Free;
  end;
end;

procedure TTestThreadingTypes.DovrebbeMettereClasseEMessaggioNelTesto;
var
  LError: EWorkerJobException;
begin
  LError := EWorkerJobException.Create('EAccessViolation', 'nowhere');
  try
    Assert.IsTrue(Pos('EAccessViolation', LError.Message) > 0, LError.Message);
    Assert.IsTrue(Pos('nowhere', LError.Message) > 0, LError.Message);
  finally
    LError.Free;
  end;
end;

procedure TTestThreadingTypes.DovrebbeEssereUnErroreDellaLibreria;
begin
  Assert.WillRaise(
    procedure
    begin
      raise EWorkerJobException.Create('E', 'm');
    end, EThreadingException);
end;

end.
