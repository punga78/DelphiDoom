{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the factory of the application of a map          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Apply.Factory;

interface

uses
  DelphiDoom.Udmf.Apply.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the application of a map</summary>
  TUdmfApplyFactory = class
  public
    class function CreateSectorInterpreter: IUdmfSectorInterpreter; static;
    class function CreateTriangleSlopes: IUdmfTriangleSlopes; static;
    /// <param name="ASpecialStart">First special of the UDMF range</param>
    /// <param name="ANormalAdd">Distance between the normal range and the UDMF one</param>
    class function CreateLineSpecialTranslator(ASpecialStart, ANormalAdd: Integer): IUdmfLineSpecialTranslator; static;
    class function CreateFakeContrast: IUdmfFakeContrast; static;
  end;

implementation

uses
  DelphiDoom.Udmf.Apply.SectorInterpreter, DelphiDoom.Udmf.Apply.TriangleSlopes,
  DelphiDoom.Udmf.Apply.LineSpecialTranslator, DelphiDoom.Udmf.Apply.FakeContrast;

{ TUdmfApplyFactory }

class function TUdmfApplyFactory.CreateSectorInterpreter: IUdmfSectorInterpreter;
begin
  Result := TUdmfSectorInterpreter.Create;
end;

class function TUdmfApplyFactory.CreateTriangleSlopes: IUdmfTriangleSlopes;
begin
  Result := TUdmfTriangleSlopes.Create;
end;

class function TUdmfApplyFactory.CreateLineSpecialTranslator(ASpecialStart,
  ANormalAdd: Integer): IUdmfLineSpecialTranslator;
begin
  Result := TUdmfLineSpecialTranslator.Create(ASpecialStart, ANormalAdd);
end;

class function TUdmfApplyFactory.CreateFakeContrast: IUdmfFakeContrast;
begin
  Result := TUdmfFakeContrast.Create;
end;

end.
