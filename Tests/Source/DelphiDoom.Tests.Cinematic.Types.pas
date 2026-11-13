{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the types of the cinematic library                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.Types;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestCinematicTypes = class(TObject)
  public
    [Test]
    procedure DovrebbeAvereIntestazioneDiOttoByte;
    [Test]
    procedure DovrebbeAvereGliIdentificatoriDelFormato;
    [Test]
    procedure DovrebbeDerivareLeEccezioniDallaBase;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types;

{ TTestCinematicTypes }

procedure TTestCinematicTypes.DovrebbeAvereIntestazioneDiOttoByte;
begin
  Assert.AreEqual(8, SizeOf(TRoqChunkHeader));
  Assert.AreEqual(ROQ_HEADER_SIZE, SizeOf(TRoqChunkHeader));
end;

procedure TTestCinematicTypes.DovrebbeAvereGliIdentificatoriDelFormato;
begin
  Assert.AreEqual($1084, ROQ_FILE);
  Assert.AreEqual($1001, ROQ_QUAD_INFO);
  Assert.AreEqual($1002, ROQ_CODEBOOK);
  Assert.AreEqual($1011, ROQ_QUAD_VQ);
  Assert.AreEqual($1020, ROQ_SOUND_MONO);
  Assert.AreEqual($1021, ROQ_SOUND_STEREO);
  Assert.AreEqual($1030, ROQ_PACKET);
end;

procedure TTestCinematicTypes.DovrebbeDerivareLeEccezioniDallaBase;
begin
  Assert.IsTrue(ERoqTruncatedException.InheritsFrom(ECinematicException));
  Assert.IsTrue(ERoqMissingCodebookException.InheritsFrom(ECinematicException));
  Assert.IsTrue(ERoqMissingInfoException.InheritsFrom(ECinematicException));
  Assert.IsTrue(ERoqInvalidDataException.InheritsFrom(ECinematicException));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCinematicTypes);

end.
