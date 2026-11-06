{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture definitions library - the records on disk  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TextureDefs.Types;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('texturedefs')]
  TTestTextureDefsTypes = class(TObject)
  public
    [Test]
    procedure TestPatchOfStandardHasTenBytes;
    [Test]
    procedure TestPatchOfStrifeHasSixBytes;
    [Test]
    procedure TestHeaderOfStandardHasTwentyTwoBytes;
    [Test]
    procedure TestHeaderOfStrifeHasEighteenBytes;
    [Test]
    procedure TestTheExceptionKeepsItsCode;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TextureDefs.Types;

{ TTestTextureDefsTypes }

procedure TTestTextureDefsTypes.TestPatchOfStandardHasTenBytes;
begin
  Assert.AreEqual(10, SizeOf(TTextureDefsMapPatchStandard), 'dovrebbe avere 10 byte');
  Assert.AreEqual(TEXTUREDEFS_PATCH_SIZE_STANDARD, SizeOf(TTextureDefsMapPatchStandard));
end;

procedure TTestTextureDefsTypes.TestPatchOfStrifeHasSixBytes;
begin
  Assert.AreEqual(6, SizeOf(TTextureDefsMapPatchStrife), 'dovrebbe avere 6 byte');
  Assert.AreEqual(TEXTUREDEFS_PATCH_SIZE_STRIFE, SizeOf(TTextureDefsMapPatchStrife));
end;

procedure TTestTextureDefsTypes.TestHeaderOfStandardHasTwentyTwoBytes;
begin
  Assert.AreEqual(22, SizeOf(TTextureDefsMapTextureStandard), 'dovrebbe avere 22 byte');
  Assert.AreEqual(TEXTUREDEFS_HEADER_SIZE_STANDARD, SizeOf(TTextureDefsMapTextureStandard));
end;

procedure TTestTextureDefsTypes.TestHeaderOfStrifeHasEighteenBytes;
begin
  Assert.AreEqual(18, SizeOf(TTextureDefsMapTextureStrife), 'dovrebbe avere 18 byte');
  Assert.AreEqual(TEXTUREDEFS_HEADER_SIZE_STRIFE, SizeOf(TTextureDefsMapTextureStrife));
end;

procedure TTestTextureDefsTypes.TestTheExceptionKeepsItsCode;
var
  LException: ETextureDefsException;
begin
  LException := ETextureDefsException.Create(TTextureDefsError.BadPatchIndex, 'm');
  try
    Assert.AreEqual(Ord(TTextureDefsError.BadPatchIndex), Ord(LException.Code), 'dovrebbe tenere il codice');
    Assert.AreEqual('m', LException.Message);
  finally
    LException.Free;
  end;
end;

end.
