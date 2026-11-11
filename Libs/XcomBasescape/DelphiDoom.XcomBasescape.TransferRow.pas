{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - TransferRow of OpenXcom (a row of the   }
{  lists of purchase, sale and transfer)                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.TransferRow;

interface

uses
  DelphiDoom.XcomSave.BaseCapacity;

type
  /// <summary>
  ///   TransferRow: what a row of a list of quantities stands for. Rule is the rule (soldier, craft or item; nil for
  ///   scientists and engineers) or, for sales and transfers of objects of the base, the soldier or the craft;
  ///   not owned
  /// </summary>
  TXcomTransferRow = record
    Kind: TXcomTransferKind;
    Rule: TObject;
    Name: string;
    Cost: Integer;
    QtySrc: Integer;
    QtyDst: Integer;
    Amount: Integer;
  end;

implementation

end.
