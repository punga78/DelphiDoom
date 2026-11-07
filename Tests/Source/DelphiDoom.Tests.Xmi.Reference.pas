{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiConverter against the golden of the old converter  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Reference;

// Tests\Data\Xmi\reference.golden.txt was written by the converter of xmi_core
// (the code before the library, git f3e33468~1) on the songs of
// DelphiDoom.Tests.Xmi.ReferenceCases: track count and MIDI bytes of each song

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiReference = class(TObject)
  private
    FGolden: TStringList;
    function GoldenOf(const AName: string): TArray<string>;
    procedure CheckCase(const AName: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAvereUnaRigaPerOgniBrano;
    [Test]
    [TestCase('ogni evento', 'xmi_every_event')]
    [TestCase('durata troppo lunga', 'xmi_duration_overflow')]
    [TestCase('durata troncata', 'xmi_duration_truncated')]
    [TestCase('attesa troncata', 'xmi_delay_truncated')]
    [TestCase('lunghezza troppo lunga', 'xmi_length_overflow')]
    [TestCase('lunghezza di sysex troncata', 'xmi_exclusive_length_truncated')]
    [TestCase('lunghezza di meta troncata', 'xmi_meta_length_truncated')]
    [TestCase('FORM senza CAT', 'xmi_form_without_cat')]
    [TestCase('due FORM senza CAT', 'xmi_two_forms_without_cat')]
    [TestCase('brano senza eventi', 'xmi_song_without_events')]
    [TestCase('INFO oltre i brani', 'xmi_info_beyond_the_songs')]
    [TestCase('INFO a zero', 'xmi_info_zero')]
    [TestCase('senza INFO', 'xmi_without_info')]
    [TestCase('eventi oltre il file', 'xmi_events_beyond_the_file')]
    [TestCase('batteria del CMF', 'cmf_drums')]
    [TestCase('titolo dopo la musica', 'cmf_title_after_music')]
    [TestCase('autore dopo la musica', 'cmf_composer_after_music')]
    [TestCase('note dopo la musica', 'cmf_remarks_after_music')]
    [TestCase('strumenti dopo la musica', 'cmf_instruments_after_music')]
    [TestCase('posizioni oltre il file', 'cmf_offsets_beyond_the_file')]
    [TestCase('versione sbagliata', 'cmf_bad_version')]
    [TestCase('attesa del CMF troncata', 'cmf_delay_truncated')]
    [TestCase('meta del CMF troncato', 'cmf_meta_truncated')]
    procedure DovrebbeDareLoStessoFileDelVecchioConvertitore(const AName: string);
    /// <summary>
    ///   Where the data ends inside an event the old converter read the last
    ///   byte of the file again and again; the library drops an event whose
    ///   parameters are missing and fills the missing bytes of a meta event
    ///   with zeros. The bytes expected here are the ones of the golden with
    ///   that rule applied by hand
    /// </summary>
    [Test]
    [TestCase('parametro troncato', 'xmi_parameter_truncated,' +
      '4D5468640000000600020001003C4D54726B0000000300C005')]
    [TestCase('valore di meta troncato', 'xmi_meta_value_truncated,' +
      '4D5468640000000600020001003C4D54726B0000000A00C00500FF5103070000')]
    [TestCase('meta di misura fissa troncato', 'xmi_fixed_meta_truncated,' +
      '4D5468640000000600020001003C4D54726B0000000B00C00500FF580404000000')]
    [TestCase('parametro del CMF troncato', 'cmf_parameter_truncated,' +
      '4D546864000000060000000100604D54726B0000000A00FF51030F424000C005')]
    procedure DovrebbeNonRipetereLUltimoByteDelFile(const AName, AExpected: string);
  end;

implementation

uses
  System.IOUtils, System.TypInfo, DelphiDoom.Xmi.Midi.Types, DelphiDoom.Xmi.Converter,
  DelphiDoom.Tests.Xmi.ReferenceCases;

const
  GOLDEN_FIELDS = 6;

{ TTestXmiReference }

procedure TTestXmiReference.Setup;
begin
  FGolden := TStringList.Create;
  FGolden.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Xmi\reference.golden.txt')));
end;

procedure TTestXmiReference.TearDown;
begin
  FreeAndNil(FGolden);
end;

function TTestXmiReference.GoldenOf(const AName: string): TArray<string>;
var
  LLine: string;
begin
  for LLine in FGolden do
  begin
    if LLine.StartsWith('#') then
      Continue;
    Result := LLine.Split([';']);
    if (Length(Result) = GOLDEN_FIELDS) and (Result[0] = AName) then
      Exit;
  end;
  Result := nil;
end;

procedure TTestXmiReference.CheckCase(const AName: string);
var
  LCase: TXmiReferenceCase;
  LFound: Boolean;
  LGolden: TArray<string>;
  LCount: Integer;
  LCountStatus, LStatus: TXmiConversionStatus;
  LMidi: TBytes;
begin
  LFound := False;
  for LCase in TXmiReferenceCases.All do
  begin
    if LCase.Name <> AName then
      Continue;
    LFound := True;
    LGolden := GoldenOf(AName);
    Assert.AreEqual(GOLDEN_FIELDS, Length(LGolden), 'golden of ' + AName);
    Assert.AreEqual(LGolden[1], IntToStr(LCase.Track), 'track');

    LCountStatus := TXmiConverter.CountTracks(Pointer(LCase.Data), Length(LCase.Data), LCount);
    Assert.AreEqual(LGolden[2], GetEnumName(TypeInfo(TXmiConversionStatus), Ord(LCountStatus)),
      'count status');
    Assert.AreEqual(LGolden[3], IntToStr(LCount), 'track count');

    LStatus := TXmiConverter.ConvertToMidi(Pointer(LCase.Data), Length(LCase.Data),
      LCase.Track, LMidi);
    Assert.AreEqual(LGolden[4], GetEnumName(TypeInfo(TXmiConversionStatus), Ord(LStatus)),
      'conversion status');
    Assert.AreEqual(LGolden[5], TXmiReferenceCases.ToHex(LMidi), 'MIDI bytes');
  end;
  Assert.IsTrue(LFound, 'song ' + AName);
end;

procedure TTestXmiReference.DovrebbeAvereUnaRigaPerOgniBrano;
var
  LCase: TXmiReferenceCase;
begin
  for LCase in TXmiReferenceCases.All do
    Assert.AreEqual(GOLDEN_FIELDS, Length(GoldenOf(LCase.Name)), LCase.Name);
end;

procedure TTestXmiReference.DovrebbeDareLoStessoFileDelVecchioConvertitore(const AName: string);
begin
  CheckCase(AName);
end;

procedure TTestXmiReference.DovrebbeNonRipetereLUltimoByteDelFile(const AName,
  AExpected: string);
var
  LCase: TXmiReferenceCase;
  LGolden: TArray<string>;
  LMidi: TBytes;
begin
  LGolden := GoldenOf(AName);
  Assert.AreEqual(GOLDEN_FIELDS, Length(LGolden), 'golden of ' + AName);
  Assert.AreNotEqual(AExpected, LGolden[5], 'the old converter gave other bytes');
  for LCase in TXmiReferenceCases.All do
    if LCase.Name = AName then
    begin
      Assert.AreEqual(Ord(TXmiConversionStatus.Ok), Ord(TXmiConverter.ConvertToMidi(
        Pointer(LCase.Data), Length(LCase.Data), LCase.Track, LMidi)));
      Assert.AreEqual(AExpected, TXmiReferenceCases.ToHex(LMidi));
      Exit;
    end;
  Assert.Fail('song ' + AName);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiReference);

end.
