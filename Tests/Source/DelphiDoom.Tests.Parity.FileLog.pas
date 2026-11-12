{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the log in a file                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.FileLog;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.FileLog,
  DelphiDoom.Parity.Intf;

type
  [TestFixture]
  [Category('parity')]
  TTestParityFileLog = class(TObject)
  strict private
    FFileName: string;
    function ReadAll: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLeRigheConIlSoloLineFeed;
    [Test]
    procedure FlushDovrebbeMettereTutteLeRigheNelFile;
    [Test]
    procedure LaChiusuraDovrebbeMettereTutteLeRigheNelFile;
    [Test]
    procedure UnFileEsistenteDovrebbeEssereSovrascritto;
    [Test]
    procedure UnaRigaPiuGrandeDelBufferDovrebbeEssereScrittaIntera;
    [Test]
    procedure MoltRigheDovrebberoRestareNellOrdine;
    [Test]
    procedure UnPercorsoImpossibileDovrebbeDareEccezione;
  end;

implementation

uses
  DelphiDoom.Parity.Types;

procedure TTestParityFileLog.Setup;
begin
  FFileName := TPath.Combine(TPath.GetTempPath, 'parity_filelog_test.txt');
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
end;

procedure TTestParityFileLog.TearDown;
begin
  if TFile.Exists(FFileName) then
    TFile.Delete(FFileName);
end;

function TTestParityFileLog.ReadAll: TBytes;
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, LStream.Size);
    if LStream.Size > 0 then
      LStream.ReadBuffer(Result[0], LStream.Size);
  finally
    LStream.Free;
  end;
end;

procedure TTestParityFileLog.DovrebbeScrivereLeRigheConIlSoloLineFeed;
var
  LLog: IParityLog;
  LBytes: TBytes;
begin
  LLog := TParityFileLog.Create(FFileName);
  LLog.WriteLine('ab');
  LLog.WriteLine('c');
  LLog.Flush;
  LBytes := ReadAll;
  Assert.AreEqual(5, Length(LBytes));
  Assert.AreEqual(Byte(Ord('a')), LBytes[0]);
  Assert.AreEqual(Byte(10), LBytes[2]);
  Assert.AreEqual(Byte(10), LBytes[4]);
end;

procedure TTestParityFileLog.FlushDovrebbeMettereTutteLeRigheNelFile;
var
  LLog: IParityLog;
begin
  LLog := TParityFileLog.Create(FFileName);
  LLog.WriteLine('uno');
  Assert.AreEqual(0, Length(ReadAll), 'ancora nel buffer');
  LLog.Flush;
  Assert.AreEqual(4, Length(ReadAll));
end;

procedure TTestParityFileLog.LaChiusuraDovrebbeMettereTutteLeRigheNelFile;
var
  LLog: IParityLog;
begin
  LLog := TParityFileLog.Create(FFileName);
  LLog.WriteLine('uno');
  LLog := nil;
  Assert.AreEqual(4, Length(ReadAll));
end;

procedure TTestParityFileLog.UnFileEsistenteDovrebbeEssereSovrascritto;
var
  LLog: IParityLog;
begin
  TFile.WriteAllText(FFileName, 'vecchio contenuto molto lungo');
  LLog := TParityFileLog.Create(FFileName);
  LLog.WriteLine('x');
  LLog := nil;
  Assert.AreEqual(2, Length(ReadAll));
end;

procedure TTestParityFileLog.UnaRigaPiuGrandeDelBufferDovrebbeEssereScrittaIntera;
var
  LLog: IParityLog;
begin
  LLog := TParityFileLog.Create(FFileName);
  LLog.WriteLine(StringOfChar('z', 200000));
  LLog := nil;
  Assert.AreEqual(200001, Length(ReadAll));
end;

procedure TTestParityFileLog.MoltRigheDovrebberoRestareNellOrdine;
var
  LLog: IParityLog;
  LLines: TArray<string>;
  LIndex: Integer;
begin
  LLog := TParityFileLog.Create(FFileName);
  for LIndex := 0 to 9999 do
    LLog.WriteLine('line ' + IntToStr(LIndex));
  LLog := nil;
  LLines := TFile.ReadAllText(FFileName).Split([#10], TStringSplitOptions.ExcludeEmpty);
  Assert.AreEqual(10000, Length(LLines));
  Assert.AreEqual('line 0', LLines[0]);
  Assert.AreEqual('line 9999', LLines[9999]);
end;

procedure TTestParityFileLog.UnPercorsoImpossibileDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityFileLog.Create(TPath.Combine(TPath.GetTempPath, 'no_such_folder_parity\x\log.txt'));
    end, EParityException);
end;

end.
