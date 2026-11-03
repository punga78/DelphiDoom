{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the host functions that need a shared memory manager   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Script.Memory;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('script')]
  TTestScriptMemory = class(TObject)
  public
    [Test]
    [TestCase('Intero', 'function F(a: Integer): Integer;|False', '|')]
    [TestCase('Procedura', 'procedure P(a, b: Integer);|False', '|')]
    [TestCase('Senza parametri', 'function F: Integer;|False', '|')]
    [TestCase('Reale', 'function F(a: Double): Double;|False', '|')]
    [TestCase('Stringa per valore', 'function F(s: string): Integer;|False', '|')]
    [TestCase('Stringa const', 'function F(const s: string): Integer;|False', '|')]
    [TestCase('Risultato stringa', 'function F(a: Integer): string;|True', '|')]
    [TestCase('Risultato stringa senza parametri', 'function F: string;|True', '|')]
    [TestCase('Risultato ansistring', 'function F: AnsiString;|True', '|')]
    [TestCase('Risultato variant', 'function F: Variant;|True', '|')]
    [TestCase('Risultato array', 'function F: array of integer;|True', '|')]
    [TestCase('Stringa var', 'procedure P(var s: string);|True', '|')]
    [TestCase('Stringa out', 'procedure P(a: Integer; out s: string);|True', '|')]
    [TestCase('Array var', 'procedure P(var a: array of integer);|True', '|')]
    [TestCase('Intero var', 'procedure P(var a: Integer);|False', '|')]
    [TestCase('Gruppo con var stringa', 'procedure P(a, b: Integer; var s, t: string);|True', '|')]
    [TestCase('Maiuscole', 'FUNCTION F(A: INTEGER): STRING;|True', '|')]
    procedure TestNeedsSharedMemory(const ADeclaration: string; AExpected: Boolean);
    [Test]
    procedure TestEmptyDeclarationNeedsNothing;
  end;

implementation

uses
  DelphiDoom.Script.Native;

{ TTestScriptMemory }

procedure TTestScriptMemory.TestNeedsSharedMemory(const ADeclaration: string;
  AExpected: Boolean);
begin
  Assert.AreEqual(AExpected,
    TScriptNative.NeedsSharedMemory(AnsiString(ADeclaration)));
end;

procedure TTestScriptMemory.TestEmptyDeclarationNeedsNothing;
begin
  Assert.IsFalse(TScriptNative.NeedsSharedMemory(''));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestScriptMemory);

end.
