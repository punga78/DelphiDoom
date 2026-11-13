{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the saving of an export to a file (DUnitX)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.Saver;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.TableExport.Saver.Intf;

type
  /// <summary>An output that writes a log of what it was asked to do</summary>
  TFakeExportOutput = class(TInterfacedObject, ITableExportOutput)
  strict private
    FLog: TStringList;
  public
    constructor Create(const ALog: TStringList);
    procedure Print(const AText: string);
    function SaveFileName(const AName: string): string;
    procedure SaveLines(const AFileName: string; const ALines: TArray<string>);
  end;

  [TestFixture]
  [Category('tableexport')]
  TTestTableExportSaver = class
  strict private
    FLog: TStringList;
    FSaver: ITableExportSaver;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDireCheMancaIlNomeSenzaCalcolareIlTesto;
    [Test]
    procedure DovrebbeAggiungereLEstensioneSeIlNomeNonHaIlPunto;
    [Test]
    procedure DovrebbeLasciareIlNomeCheHaIlPunto;
    [Test]
    procedure DovrebbeSalvareNellaCartellaDeiSalvataggi;
    [Test]
    procedure DovrebbeTagliareUnTestoInRigheComeUnElencoDiStringhe;
    [Test]
    procedure DovrebbeSalvareLeRigheComeSono;
    [Test]
    procedure DovrebbeRifiutareUnOutputNil;
    [Test]
    procedure DovrebbeDareLeStesseRigheDiUnTDStringListSuTestiCasuali;
  end;

implementation

uses
  d_delphi,
  DelphiDoom.TableExport.Saver;

{ TFakeExportOutput }

constructor TFakeExportOutput.Create(const ALog: TStringList);
begin
  inherited Create;
  FLog := ALog;
end;

procedure TFakeExportOutput.Print(const AText: string);
begin
  FLog.Add('print ' + AText);
end;

function TFakeExportOutput.SaveFileName(const AName: string): string;
begin
  Result := 'save\' + AName;
end;

procedure TFakeExportOutput.SaveLines(const AFileName: string; const ALines: TArray<string>);
begin
  FLog.Add('save ' + AFileName + ' ' + IntToStr(Length(ALines)) + ' ' + string.Join('/', ALines));
end;

{ TTestTableExportSaver }

procedure TTestTableExportSaver.Setup;
begin
  FLog := TStringList.Create;
  FSaver := TTableExportSaver.Create(TFakeExportOutput.Create(FLog));
end;

procedure TTestTableExportSaver.TearDown;
begin
  FSaver := nil;
  FLog.Free;
end;

procedure TTestTableExportSaver.DovrebbeDireCheMancaIlNomeSenzaCalcolareIlTesto;
var
  LCalled: Boolean;
begin
  LCalled := False;
  FSaver.SaveText('', '.txt', 'missing', 'saved %s',
    function: string
    begin
      LCalled := True;
      Result := 'x';
    end);
  Assert.AreEqual(1, FLog.Count);
  Assert.AreEqual('print missing', FLog[0]);
  Assert.IsFalse(LCalled);
end;

procedure TTestTableExportSaver.DovrebbeAggiungereLEstensioneSeIlNomeNonHaIlPunto;
begin
  FSaver.SaveText('out', '.bex', 'm', 'saved %s', function: string begin Result := 'a'; end);
  Assert.AreEqual('save save\out.bex 1 a', FLog[0]);
end;

procedure TTestTableExportSaver.DovrebbeLasciareIlNomeCheHaIlPunto;
begin
  FSaver.SaveText('out.dat', '.bex', 'm', 'saved %s', function: string begin Result := 'a'; end);
  Assert.AreEqual('save save\out.dat 1 a', FLog[0]);
end;

procedure TTestTableExportSaver.DovrebbeSalvareNellaCartellaDeiSalvataggi;
begin
  FSaver.SaveText('out', '.txt', 'm', 'DEHACKED settings saved to %s', function: string begin Result := 'a'; end);
  Assert.AreEqual('print DEHACKED settings saved to save\out.txt', FLog[1]);
end;

procedure TTestTableExportSaver.DovrebbeTagliareUnTestoInRigheComeUnElencoDiStringhe;
begin
  FSaver.SaveText('o', '.txt', 'm', 's %s', function: string begin Result := 'a'#13#10'b'#10'c'; end);
  Assert.AreEqual('save save\o.txt 3 a/b/c', FLog[0]);
end;

procedure TTestTableExportSaver.DovrebbeSalvareLeRigheComeSono;
begin
  FSaver.SaveLines('o', '.csv', 'm', 's %s',
    function: TArray<string>
    begin
      Result := ['x', '', 'y'];
    end);
  Assert.AreEqual('save save\o.csv 3 x//y', FLog[0]);
end;

procedure TTestTableExportSaver.DovrebbeRifiutareUnOutputNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTableExportSaver.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestTableExportSaver.DovrebbeDareLeStesseRigheDiUnTDStringListSuTestiCasuali;
const
  Alphabet: array[0..6] of string = ('a', 'b', #13, #10, #13#10, ' ', 'z');
var
  LRound: Integer;
  LIndex: Integer;
  LText: string;
  LList: TDStringList;
  LExpected: string;
  LItem: Integer;
  LCount: Integer;
begin
  RandSeed := 193;
  for LRound := 1 to 2000 do
  begin
    LText := '';
    for LIndex := 1 to Random(10) do
      LText := LText + Alphabet[Random(Length(Alphabet))];
    LList := TDStringList.Create;
    try
      LList.Text := LText;
      LExpected := '';
      LCount := LList.Count;
      for LItem := 0 to LList.Count - 1 do
      begin
        if LItem > 0 then
          LExpected := LExpected + '/';
        LExpected := LExpected + LList[LItem];
      end;
    finally
      LList.Free;
    end;
    FLog.Clear;
    FSaver.SaveText('o', '', 'm', 's %s', function: string begin Result := LText; end);
    Assert.AreEqual('save save\o ' + IntToStr(LCount) + ' ' + LExpected,
      FLog[0], LText);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTableExportSaver);

end.
