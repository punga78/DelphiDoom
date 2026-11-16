{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelFactory                              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Factory;

interface

uses
  DelphiDoom.Radix.Context, DelphiDoom.Radix.Level.Intf;

type
  /// <summary>The only place that knows the classes of the levels</summary>
  TRadixLevelFactory = class
  public
    class function CreateReader: IRadixLevelReader; static;
    class function CreateFixSelector: IRadixLevelFixSelector; static;
    /// <summary>The step of the translation that makes the levels (GenerateLevels: with the extra lumps)</summary>
    class function CreatePart(AExtraInfo: Boolean = True): IRadixPart; static;
  end;

implementation

uses
  DelphiDoom.Radix.Level.Reader, DelphiDoom.Radix.Level.FixSelector, DelphiDoom.Radix.Level.Converter,
  DelphiDoom.Radix.LevelPart;

{ TRadixLevelFactory }

class function TRadixLevelFactory.CreateReader: IRadixLevelReader;
begin
  Result := TRadixLevelReader.Create;
end;

class function TRadixLevelFactory.CreateFixSelector: IRadixLevelFixSelector;
begin
  Result := TRadixLevelFixSelector.Create;
end;

class function TRadixLevelFactory.CreatePart(AExtraInfo: Boolean): IRadixPart;
begin
  Result := TRadixLevelPart.Create(TRadixLevelConverter.Create(CreateReader, CreateFixSelector), AExtraInfo);
end;

end.
