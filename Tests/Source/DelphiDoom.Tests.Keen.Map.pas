{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - a map                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Map;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenMap = class(TObject)
  private
    function Header(AWidth, AHeight: Word; const AName: AnsiString): TKeenMapHeader;
    function Planes(ACount: Integer): TArray<TArray<Word>>;
    function MakeMap(AWidth, AHeight: Word; const AName: AnsiString): IKeenMap;
  public
    [Test]
    procedure DovrebbeDareNumeroDimensioniENome;
    [Test]
    procedure DovrebbeTagliareIlNomeAlPrimoZero;
    [Test]
    procedure DovrebbeDareIlNomeDiSedicicCaratteriSenzaZero;
    [Test]
    procedure DovrebbeDareLaParolaDiUnTile;
    [Test]
    procedure DovrebbeDareILaHeaderCosiCome;
    [Test]
    procedure DovrebbeRifiutareUnTileFuoriDallaMappa;
    [Test]
    procedure DovrebbeRifiutareUnPianoCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnPianoDiDimensioneSbagliata;
    [Test]
    procedure DovrebbeVolereTrePiani;
  end;

implementation

uses
  DelphiDoom.Keen.Map;

{ TTestKeenMap }

function TTestKeenMap.Header(AWidth, AHeight: Word; const AName: AnsiString): TKeenMapHeader;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Width := AWidth;
  Result.Height := AHeight;
  Move(AName[1], Result.Name[0], Length(AName));
end;

function TTestKeenMap.Planes(ACount: Integer): TArray<TArray<Word>>;
var
  LPlane: Integer;
  LIndex: Integer;
begin
  SetLength(Result, 3);
  for LPlane := 0 to 2 do
  begin
    SetLength(Result[LPlane], ACount);
    for LIndex := 0 to ACount - 1 do
      Result[LPlane][LIndex] := Word(LPlane * 1000 + LIndex);
  end;
end;

function TTestKeenMap.MakeMap(AWidth, AHeight: Word; const AName: AnsiString): IKeenMap;
begin
  Result := TKeenMap.Create(7, Header(AWidth, AHeight, AName), Planes(AWidth * AHeight));
end;

procedure TTestKeenMap.DovrebbeDareNumeroDimensioniENome;
var
  LMap: IKeenMap;
begin
  LMap := MakeMap(4, 3, 'LAND OF TUBERIA');
  Assert.AreEqual(7, LMap.Number);
  Assert.AreEqual(4, LMap.Width);
  Assert.AreEqual(3, LMap.Height);
  Assert.AreEqual('LAND OF TUBERIA', LMap.Name);
end;

procedure TTestKeenMap.DovrebbeTagliareIlNomeAlPrimoZero;
begin
  Assert.AreEqual('TEMP1', MakeMap(1, 1, 'TEMP1').Name);
end;

procedure TTestKeenMap.DovrebbeDareIlNomeDiSedicicCaratteriSenzaZero;
begin
  Assert.AreEqual('0123456789ABCDEF', MakeMap(1, 1, '0123456789ABCDEF').Name);
end;

procedure TTestKeenMap.DovrebbeDareLaParolaDiUnTile;
var
  LMap: IKeenMap;
begin
  LMap := MakeMap(4, 3, 'X');
  Assert.AreEqual(0, Integer(LMap.GetTile(0, 0, 0)));
  Assert.AreEqual(1000 + 6, Integer(LMap.GetTile(1, 2, 1)), 'x 2, y 1: indice 1 * 4 + 2');
  Assert.AreEqual(2000 + 11, Integer(LMap.GetTile(2, 3, 2)));
end;

procedure TTestKeenMap.DovrebbeDareILaHeaderCosiCome;
var
  LMap: IKeenMap;
begin
  LMap := MakeMap(4, 3, 'X');
  Assert.AreEqual(4, Integer(LMap.Header.Width));
  Assert.AreEqual(3, Length(LMap.Planes[0]) div 4);
end;

procedure TTestKeenMap.DovrebbeRifiutareUnTileFuoriDallaMappa;
var
  LMap: IKeenMap;
begin
  LMap := MakeMap(4, 3, 'X');
  Assert.WillRaise(procedure begin LMap.GetTile(0, 4, 0); end, EKeenDataException);
  Assert.WillRaise(procedure begin LMap.GetTile(0, 0, 3); end, EKeenDataException);
  Assert.WillRaise(procedure begin LMap.GetTile(0, -1, 0); end, EKeenDataException);
  Assert.WillRaise(procedure begin LMap.GetTile(0, 0, -1); end, EKeenDataException);
end;

procedure TTestKeenMap.DovrebbeRifiutareUnPianoCheNonCe;
var
  LMap: IKeenMap;
begin
  LMap := MakeMap(4, 3, 'X');
  Assert.WillRaise(procedure begin LMap.GetPlane(3); end, EKeenDataException);
  Assert.WillRaise(procedure begin LMap.GetPlane(-1); end, EKeenDataException);
end;

procedure TTestKeenMap.DovrebbeRifiutareUnPianoDiDimensioneSbagliata;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenMap.Create(1, Header(4, 3, 'X'), Planes(11));
    end, EKeenDataException);
end;

procedure TTestKeenMap.DovrebbeVolereTrePiani;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenMap.Create(1, Header(1, 1, 'X'), [Planes(1)[0], Planes(1)[1]]);
    end, EKeenDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenMap);

end.
