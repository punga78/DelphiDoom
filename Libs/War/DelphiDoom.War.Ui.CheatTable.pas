{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the table of the cheats                           }
{                                                                              }
{  Port of war1 (acoto87/war1), war_cheats.c (cheatDescriptors and the         }
{  matching of wcheat_applyCheat), (c) 2019 Alejandro Coto Gutierrez, zlib     }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version, not    }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.CheatTable;

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Strings;

type
  /// <summary>One line of cheatDescriptors: the text and whether the cheat takes an argument</summary>
  TWarCheatDescriptor = record
    Text: AnsiString;
    HasArgument: Boolean;
  end;

  /// <summary>The 24 cheats in the order of the original (the order decides which one a text is)</summary>
  TWarCheatTable = class
  strict private
    class var FDescriptors: TArray<TWarCheatDescriptor>;
    class procedure Fill; static;
  public
    class function Descriptors: TArray<TWarCheatDescriptor>; static;
    /// <summary>
    ///   wcheat_applyCheat: the first cheat whose text is the whole text (no argument: letters compared without case)
    ///   or the start of it (with an argument: the rest, without the spaces at its left, is the argument). False if the text
    ///   is no cheat ("Unknown cheat")
    /// </summary>
    class function Match(const AText: AnsiString; out ADescriptor: TWarCheatDescriptor; out AArgument: AnsiString): Boolean;
      static;
  end;

implementation

{ TWarCheatTable }

class procedure TWarCheatTable.Fill;

  procedure Put(AIndex: Integer; const AText: AnsiString; AHasArgument: Boolean);
  begin
    FDescriptors[AIndex].Text := AText;
    FDescriptors[AIndex].HasArgument := AHasArgument;
  end;

begin
  SetLength(FDescriptors, 24);
  Put(0, 'Pot of gold', False);
  Put(1, 'Eye of newt', False);
  Put(2, 'Iron forge', False);
  Put(3, 'Ides of march', False);
  Put(4, 'Corwin of Amber', False);
  Put(5, 'There can be only one', False);
  Put(6, 'Yours truly', False);
  Put(7, 'Crushing defeat', False);
  Put(8, 'Sally Shears', False);
  Put(9, 'Human', True);
  Put(10, 'Orc', True);
  Put(11, 'Hurry up guys', False);
  Put(12, 'Music vol', True);
  Put(13, 'Sound vol', True);
  Put(14, 'Music', True);
  Put(15, 'Sound', True);
  Put(16, 'Scale', True);
  Put(17, 'Speed', True);
  Put(18, 'Edit', True);
  Put(19, 'Add unit', True);
  Put(20, 'Rain of fire', False);
  Put(21, 'Poison cloud', False);
  Put(22, 'Raise dead', False);
  Put(23, 'Debug render', True);
end;

class function TWarCheatTable.Descriptors: TArray<TWarCheatDescriptor>;
begin
  if Length(FDescriptors) = 0 then
    Fill;
  Result := FDescriptors;
end;

class function TWarCheatTable.Match(const AText: AnsiString; out ADescriptor: TWarCheatDescriptor;
  out AArgument: AnsiString): Boolean;
var
  LDescriptors: TArray<TWarCheatDescriptor>;
  LIndex: Integer;
begin
  LDescriptors := Descriptors;
  AArgument := '';
  for LIndex := 0 to High(LDescriptors) do
  begin
    if not LDescriptors[LIndex].HasArgument then
    begin
      if TWarStrings.EqualsIgnoreCase(AText, LDescriptors[LIndex].Text) then
      begin
        ADescriptor := LDescriptors[LIndex];
        Exit(True);
      end;
    end
    else if TWarStrings.StartsWithIgnoreCase(AText, LDescriptors[LIndex].Text) then
    begin
      ADescriptor := LDescriptors[LIndex];
      AArgument := TWarStrings.TrimLeft(Copy(AText, Length(LDescriptors[LIndex].Text) + 1, MaxInt));
      Exit(True);
    end;
  end;
  ADescriptor := Default(TWarCheatDescriptor);
  Result := False;
end;

end.
