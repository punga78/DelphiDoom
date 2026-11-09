{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - LOFTEMPS.DAT, a row of 16 bit numbers     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.WordTableReader;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Intf;

type
  /// <summary>MapDataSet::loadLOFTEMPS: 16 bit little endian words, one after the other</summary>
  TXcomWordTableReader = class(TInterfacedObject, IXcomWordTableReader)
  public
    function Read(const ABytes: TBytes): TArray<Word>;
  end;

implementation

{ TXcomWordTableReader }

function TXcomWordTableReader.Read(const ABytes: TBytes): TArray<Word>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ABytes) div 2);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := Word(ABytes[LIndex * 2]) or (Word(ABytes[LIndex * 2 + 1]) shl 8);
end;

end.
