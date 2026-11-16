{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the factory of the choice of the sounds           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sound.Factory;

interface

uses
  DelphiDoom.War.Sound.Intf;

type
  /// <summary>The only place that knows the concrete classes of the choice of the sounds</summary>
  TWarSoundFactory = class
  public
    class function CreateTable: IWarSoundTable; static;
    class function CreateRandom(ASeed: Cardinal): IWarRandom; static;
    /// <summary>The picker with the table of the original and the generator it is given</summary>
    class function CreatePicker(const ARandom: IWarRandom): IWarSoundPicker; static;
  end;

implementation

uses
  DelphiDoom.War.Sound.Table, DelphiDoom.War.Sound.Picker, DelphiDoom.War.Sound.SeededRandom;

{ TWarSoundFactory }

class function TWarSoundFactory.CreateTable: IWarSoundTable;
begin
  Result := TWarSoundTable.Create;
end;

class function TWarSoundFactory.CreateRandom(ASeed: Cardinal): IWarRandom;
begin
  Result := TWarSeededRandom.Create(ASeed);
end;

class function TWarSoundFactory.CreatePicker(const ARandom: IWarRandom): IWarSoundPicker;
begin
  Result := TWarSoundPicker.Create(CreateTable, ARandom);
end;

end.
