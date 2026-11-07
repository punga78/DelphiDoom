{******************************************************************************}
{                                                                              }
{  DelphiDoom: obituary library - the formatter of the messages                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Obituary.Formatter;

interface

uses
  DelphiDoom.Obituary.Types, DelphiDoom.Obituary.Intf;

type
  /// <summary>Fills the placeholders of an obituary in a single pass over the model</summary>
  TObituaryFormatter = class(TInterfacedObject, IObituaryFormatter)
  strict private
    FGenders: IObituaryGenders;
  public
    /// <summary>AGenders gives the pronouns; nil raises EArgumentNilException</summary>
    constructor Create(const AGenders: IObituaryGenders);
    /// <summary>The message of a death</summary>
    function Compose(const AModel, AVictimName, AKillerName: string;
      const AVictimGender, AKillerGender: TObituaryGender): string;
  end;

implementation

uses
  System.SysUtils;

{ TObituaryFormatter }

constructor TObituaryFormatter.Create(const AGenders: IObituaryGenders);
begin
  inherited Create;
  if not Assigned(AGenders) then
    raise EArgumentNilException.Create('AGenders');
  FGenders := AGenders;
end;

function TObituaryFormatter.Compose(const AModel, AVictimName, AKillerName: string;
  const AVictimGender, AKillerGender: TObituaryGender): string;
var
  LBuilder: TStringBuilder;
  LVictim: TObituaryPronouns;
  LKiller: TObituaryPronouns;
  LIndex: Integer;
  LLength: Integer;
  LReplacement: string;
  LKnown: Boolean;
begin
  LVictim := FGenders.PronounsOf(AVictimGender);
  LKiller := FGenders.PronounsOf(AKillerGender);
  LLength := Length(AModel);
  LBuilder := TStringBuilder.Create(LLength + Length(AVictimName) + Length(AKillerName));
  try
    LIndex := 1;
    while LIndex <= LLength do
    begin
      LKnown := False;
      LReplacement := '';
      if (AModel[LIndex] = '%') and (LIndex < LLength) then
      begin
        LKnown := True;
        case AModel[LIndex + 1] of
          'o', 'O': LReplacement := AVictimName;
          'k', 'K': LReplacement := AKillerName;
          'g', 'G': LReplacement := LVictim.Subject;
          'h', 'H': LReplacement := LKiller.ObjectForm;
          'p', 'P': LReplacement := LKiller.Possessive;
          's', 'S': LReplacement := LKiller.Independent;
          'r', 'R': LReplacement := LKiller.Contraction;
        else
          LKnown := False;
        end;
      end;
      if LKnown then
      begin
        LBuilder.Append(LReplacement);
        Inc(LIndex, 2);
      end
      else
      begin
        LBuilder.Append(AModel[LIndex]);
        Inc(LIndex);
      end;
    end;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

end.
