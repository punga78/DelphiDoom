{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the .MCD files of the terrain             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.McdReader;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Intf;

type
  /// <summary>
  ///   MapDataSet::loadData: records of 62 bytes (struct MCD, packed). The file is read as it is, with 16 bit
  ///   numbers little endian; the check of the references is a separate step because the rules can patch the
  ///   records before it
  /// </summary>
  TXcomMcdReader = class(TInterfacedObject, IXcomMcdReader)
  public
    function Read(const ABytes: TBytes): TArray<TXcomMcdRecord>;
    procedure Validate(const ARecords: TArray<TXcomMcdRecord>);
  end;

implementation

{ TXcomMcdReader }

function TXcomMcdReader.Read(const ABytes: TBytes): TArray<TXcomMcdRecord>;
var
  LCount: Integer;
begin
  LCount := Length(ABytes) div XCOM_MCD_RECORD_BYTES;
  SetLength(Result, LCount);
  if LCount > 0 then
    Move(ABytes[0], Result[0], LCount * XCOM_MCD_RECORD_BYTES);
end;

procedure TXcomMcdReader.Validate(const ARecords: TArray<TXcomMcdRecord>);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ARecords) do
  begin
    if ARecords[LIndex].DieMcd >= Length(ARecords) then
      raise EXcomDataException.CreateFmt(SXcomMcdBadReference,
        [LIndex, 'DieMCD', ARecords[LIndex].DieMcd, Length(ARecords)]);
    if ARecords[LIndex].AltMcd >= Length(ARecords) then
      raise EXcomDataException.CreateFmt(SXcomMcdBadReference,
        [LIndex, 'AltMCD', ARecords[LIndex].AltMcd, Length(ARecords)]);
    if ARecords[LIndex].Armor = 0 then
      raise EXcomDataException.CreateFmt(SXcomMcdNoArmor, [LIndex]);
  end;
end;

end.
