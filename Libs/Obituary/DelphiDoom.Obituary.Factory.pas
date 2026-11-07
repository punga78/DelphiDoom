{******************************************************************************}
{                                                                              }
{  DelphiDoom: obituary library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Obituary.Factory;

interface

uses
  DelphiDoom.Obituary.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the library</summary>
  TObituaryFactory = class
  public
    /// <summary>The table of the six genders of the game</summary>
    class function CreateGenders: IObituaryGenders; static;
    /// <summary>The formatter of the messages, on a table of genders</summary>
    class function CreateFormatter(const AGenders: IObituaryGenders): IObituaryFormatter; static;
  end;

implementation

uses
  DelphiDoom.Obituary.GenderTable, DelphiDoom.Obituary.Formatter;

{ TObituaryFactory }

class function TObituaryFactory.CreateGenders: IObituaryGenders;
begin
  Result := TObituaryGenderTable.Create;
end;

class function TObituaryFactory.CreateFormatter(const AGenders: IObituaryGenders): IObituaryFormatter;
begin
  Result := TObituaryFormatter.Create(AGenders);
end;

end.
