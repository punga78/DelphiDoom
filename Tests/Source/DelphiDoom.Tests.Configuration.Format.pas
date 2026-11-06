{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the configuration library - the format, the document   }
{  and the writer                                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Configuration.Format;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Configuration.Intf;

type
  [TestFixture]
  [Category('configuration')]
  TTestConfigurationFormat = class(TObject)
  private
    FFormat: IConfigurationFormat;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestHeader;
    [Test]
    procedure TestHeaderOfAnOldVersion;
    [Test]
    procedure TestTheCurrentVersionIsAccepted;
    [Test]
    procedure TestTheNextVersionIsAccepted;
    [Test]
    procedure TestOlderVersionsDownTo110AreAccepted;
    [Test]
    procedure TestVersionsBelow110AndAfterTheNextAreNot;
    [Test]
    procedure TestOtherTextIsNot;
    [Test]
    procedure TestDocumentNamesAndValues;
    [Test]
    procedure TestDocumentNamesAreLowerCase;
    [Test]
    procedure TestLookupIsCaseInsensitive;
    [Test]
    procedure TestRepeatedNamesGiveTheFirstValue;
    [Test]
    procedure TestAValueMayHaveAnEqualSign;
    [Test]
    procedure TestMissingNameGivesAnEmptyValue;
    [Test]
    procedure TestPositionOutOfRange;
    [Test]
    procedure TestEmptyFile;
    [Test]
    procedure TestWriterOrderAndGroups;
    [Test]
    procedure TestWhatIsWrittenIsRead;
    [Test]
    procedure TestTheConfigurationFilesOfTheGamesWriteBackTheSame;
  end;

implementation

uses
  DelphiDoom.Configuration.Types, DelphiDoom.Configuration.Factory;

{ TTestConfigurationFormat }

procedure TTestConfigurationFormat.Setup;
begin
  FFormat := TConfigurationFactory.CreateFormat;
end;

procedure TTestConfigurationFormat.TestHeader;
begin
  Assert.AreEqual('[Delphi Doom ver 2.07]', FFormat.FormatHeader('Delphi Doom', 207));
  Assert.AreEqual('[Delphi Hexen ver 1.10]', FFormat.FormatHeader('Delphi Hexen', 110));
end;

procedure TTestConfigurationFormat.TestHeaderOfAnOldVersion;
begin
  Assert.AreEqual('[X ver 1.00]', FFormat.FormatHeader('X', 100));
  Assert.AreEqual('[X ver 0.99]', FFormat.FormatHeader('X', 99));
end;

procedure TTestConfigurationFormat.TestTheCurrentVersionIsAccepted;
begin
  Assert.IsTrue(FFormat.AcceptsHeader('[Delphi Doom ver 2.07]', 207));
end;

procedure TTestConfigurationFormat.TestTheNextVersionIsAccepted;
begin
  Assert.IsTrue(FFormat.AcceptsHeader('[Delphi Doom ver 2.08]', 207));
end;

procedure TTestConfigurationFormat.TestOlderVersionsDownTo110AreAccepted;
begin
  Assert.IsTrue(FFormat.AcceptsHeader('[Delphi Doom ver 1.10]', 207));
  Assert.IsTrue(FFormat.AcceptsHeader('[Delphi Doom ver 2.03]', 207));
  Assert.IsTrue(FFormat.AcceptsHeader('[Delphi Doom ver 1.22]', 207));
end;

procedure TTestConfigurationFormat.TestVersionsBelow110AndAfterTheNextAreNot;
begin
  Assert.IsFalse(FFormat.AcceptsHeader('[Delphi Doom ver 1.09]', 207));
  Assert.IsFalse(FFormat.AcceptsHeader('[Delphi Doom ver 0.99]', 207));
  Assert.IsFalse(FFormat.AcceptsHeader('[Delphi Doom ver 2.09]', 207));
  Assert.IsFalse(FFormat.AcceptsHeader('[Delphi Doom ver 3.00]', 207));
end;

procedure TTestConfigurationFormat.TestOtherTextIsNot;
begin
  Assert.IsFalse(FFormat.AcceptsHeader('', 207));
  Assert.IsFalse(FFormat.AcceptsHeader('display=1', 207));
end;

procedure TTestConfigurationFormat.TestDocumentNamesAndValues;
var
  LDocument: IConfigurationDocument;
begin
  LDocument := FFormat.Parse(TArray<string>.Create('[Delphi Doom ver 2.07]', '', '[Display]',
    'soft_screenwidth=640', 'use_mouse=1'));
  Assert.AreEqual('[Delphi Doom ver 2.07]', LDocument.Header);
  Assert.AreEqual(4, LDocument.Count);
  Assert.AreEqual('', LDocument.NameAt(0), 'a blank line');
  Assert.AreEqual('', LDocument.NameAt(1), 'a group');
  Assert.AreEqual('soft_screenwidth', LDocument.NameAt(2));
  Assert.AreEqual('640', LDocument.ValueOf('soft_screenwidth'));
  Assert.AreEqual('1', LDocument.ValueOf('use_mouse'));
end;

procedure TTestConfigurationFormat.TestDocumentNamesAreLowerCase;
begin
  Assert.AreEqual('mouse_sensitivity',
    FFormat.Parse(TArray<string>.Create('h', 'Mouse_Sensitivity=5')).NameAt(0));
end;

procedure TTestConfigurationFormat.TestLookupIsCaseInsensitive;
var
  LDocument: IConfigurationDocument;
begin
  LDocument := FFormat.Parse(TArray<string>.Create('h', 'Mouse_Sensitivity=5'));
  Assert.AreEqual('5', LDocument.ValueOf('mouse_sensitivity'));
  Assert.AreEqual('5', LDocument.ValueOf('MOUSE_SENSITIVITY'));
end;

procedure TTestConfigurationFormat.TestRepeatedNamesGiveTheFirstValue;
var
  LDocument: IConfigurationDocument;
begin
  LDocument := FFormat.Parse(TArray<string>.Create('h', 'a=1', 'b=2', 'a=3'));
  Assert.AreEqual('1', LDocument.ValueOf('a'));
  Assert.AreEqual('a', LDocument.NameAt(2), 'the line is still there');
end;

procedure TTestConfigurationFormat.TestAValueMayHaveAnEqualSign;
begin
  Assert.AreEqual('a=b', FFormat.Parse(TArray<string>.Create('h', 'name=a=b')).ValueOf('name'));
  Assert.AreEqual('', FFormat.Parse(TArray<string>.Create('h', 'name=')).ValueOf('name'));
end;

procedure TTestConfigurationFormat.TestMissingNameGivesAnEmptyValue;
begin
  Assert.AreEqual('', FFormat.Parse(TArray<string>.Create('h', 'a=1')).ValueOf('b'));
end;

procedure TTestConfigurationFormat.TestPositionOutOfRange;
var
  LDocument: IConfigurationDocument;
begin
  LDocument := FFormat.Parse(TArray<string>.Create('h', 'a=1'));
  Assert.WillRaise(procedure begin LDocument.NameAt(1); end, EConfigurationException);
  Assert.WillRaise(procedure begin LDocument.NameAt(-1); end, EConfigurationException);
end;

procedure TTestConfigurationFormat.TestEmptyFile;
var
  LDocument: IConfigurationDocument;
begin
  LDocument := FFormat.Parse(nil);
  Assert.AreEqual('', LDocument.Header);
  Assert.AreEqual(0, LDocument.Count);
  Assert.AreEqual('', LDocument.ValueOf('a'));
end;

procedure TTestConfigurationFormat.TestWriterOrderAndGroups;
var
  LWriter: IConfigurationWriter;
  LLines: TArray<string>;
begin
  LWriter := FFormat.CreateWriter('[X ver 2.07]');
  LWriter.AddGroup('Display');
  LWriter.AddValue('width', '640');
  LWriter.AddGroup('Mouse');
  LWriter.AddValue('use_mouse', '1');
  LLines := LWriter.Lines;
  Assert.AreEqual(7, Length(LLines));
  Assert.AreEqual('[X ver 2.07]', LLines[0]);
  Assert.AreEqual('', LLines[1]);
  Assert.AreEqual('[Display]', LLines[2]);
  Assert.AreEqual('width=640', LLines[3]);
  Assert.AreEqual('[Mouse]', LLines[5]);
  Assert.AreEqual('use_mouse=1', LLines[6]);
end;

procedure TTestConfigurationFormat.TestWhatIsWrittenIsRead;
var
  LWriter: IConfigurationWriter;
  LDocument: IConfigurationDocument;
begin
  LWriter := FFormat.CreateWriter(FFormat.FormatHeader('Delphi Doom', 207));
  LWriter.AddGroup('Display');
  LWriter.AddValue('soft_screenwidth', FFormat.FormatInteger(1024));
  LWriter.AddValue('use_mouse', FFormat.FormatBoolean(True));
  LWriter.AddValue('name', 'some text');
  LDocument := FFormat.Parse(LWriter.Lines);
  Assert.IsTrue(FFormat.AcceptsHeader(LDocument.Header, 207));
  Assert.AreEqual(1024, FFormat.ParseInteger(LDocument.ValueOf('soft_screenwidth')));
  Assert.IsTrue(FFormat.ParseBoolean(LDocument.ValueOf('use_mouse')));
  Assert.AreEqual('some text', LDocument.ValueOf('name'));
end;

procedure TTestConfigurationFormat.TestTheConfigurationFilesOfTheGamesWriteBackTheSame;
var
  LGame, LPath, LLine: string;
  LRead: TStringList;
  LLines: TArray<string>;
  LDocument: IConfigurationDocument;
  LWriter: IConfigurationWriter;
  LIndex: Integer;
  LRoot: string;
  LChecked: Integer;
begin
  // The files that the engine wrote (bin\<Game>\*.ini, not in the repository): read, written
  // again with the writer, they must be the same lines
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..'));
  LChecked := 0;
  for LGame in ['Doom', 'Heretic', 'Hexen', 'Strife'] do
    for LPath in TDirectory.GetFiles(TPath.Combine(LRoot, LGame), '*.ini') do
    begin
      LRead := TStringList.Create;
      try
        LRead.LoadFromFile(LPath);
        if LRead.Count < 2 then
          Continue;
        SetLength(LLines, LRead.Count);
        for LIndex := 0 to LRead.Count - 1 do
          LLines[LIndex] := LRead[LIndex];
        LDocument := FFormat.Parse(LLines);
        LWriter := FFormat.CreateWriter(LDocument.Header);
        for LIndex := 0 to LDocument.Count - 1 do
        begin
          LLine := LLines[LIndex + 1];
          if LDocument.NameAt(LIndex) <> '' then
            LWriter.AddValue(Copy(LLine, 1, Pos('=', LLine) - 1), Copy(LLine, Pos('=', LLine) + 1, MaxInt))
          else if (LLine <> '') and (LLine[1] = '[') then
            LWriter.AddGroup(Copy(LLine, 2, Length(LLine) - 2))
          else if LLine <> '' then
            Continue;
        end;
        // the writer puts a blank line before each group: so the old file had it too
        Assert.AreEqual(Length(LLines), Length(LWriter.Lines), LPath);
        for LIndex := 0 to High(LLines) do
          Assert.AreEqual(LLines[LIndex], LWriter.Lines[LIndex], LPath + ' line ' + IntToStr(LIndex + 1));
        Inc(LChecked);
      finally
        LRead.Free;
      end;
    end;
  if LChecked = 0 then
    Assert.Pass('no configuration file of the games in bin');
end;

end.