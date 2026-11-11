{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - the names that the screens of a base   }
{  show (Target::getName, Craft::getDefaultName, Soldier::getRankString and    }
{  getCraftString)                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.Names;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.Transfer;

type
  /// <summary>
  ///   The texts of crafts and soldiers in the language of the game: a craft has the custom name or "Triton-1", a
  ///   soldier has the name of its rank and the craft it is on
  /// </summary>
  TXcomBaseNames = class
  public
    /// <summary>
    ///   Craft::getName: the custom name, or STR_CRAFTNAME of the language with the name of the type and the id (the
    ///   type of the rules, as in the ids of the saved game)
    /// </summary>
    class function CraftName(const ACraft: TXcomCraft; const ALanguage: TXcomLanguage): string; static;
    /// <summary>Soldier::getRankString: the key of the text of the rank; '' for a rank that does not exist</summary>
    class function RankKey(ARank: Integer): string; static;
    /// <summary>
    ///   Soldier::getCraftString: STR_WOUNDED while the soldier recovers, STR_NONE_UC when it has no craft, else the
    ///   name of the craft
    /// </summary>
    /// <summary>
    ///   Transfer::getName: the name of the soldier, of the craft, STR_SCIENTISTS, STR_ENGINEERS or the text of the item
    /// </summary>
    class function TransferName(const ATransfer: TXcomTransfer; const ALanguage: TXcomLanguage): string; static;
    class function CraftText(const ASoldier: TXcomSoldier; const ALanguage: TXcomLanguage): string; static;
  end;

implementation

{ TXcomBaseNames }

class function TXcomBaseNames.CraftName(const ACraft: TXcomCraft; const ALanguage: TXcomLanguage): string;
begin
  if ACraft.Name <> '' then
    Exit(ACraft.Name);
  Result := ALanguage.GetString('STR_CRAFTNAME').Arg(ALanguage.GetString(ACraft.TargetType).Text)
    .Arg(ACraft.Id).Text;
end;

class function TXcomBaseNames.RankKey(ARank: Integer): string;
const
  KEYS: array[0..5] of string = ('STR_ROOKIE', 'STR_SQUADDIE', 'STR_SERGEANT', 'STR_CAPTAIN', 'STR_COLONEL',
    'STR_COMMANDER');
begin
  if (ARank >= 0) and (ARank <= High(KEYS)) then
    Result := KEYS[ARank]
  else
    Result := '';
end;

class function TXcomBaseNames.CraftText(const ASoldier: TXcomSoldier; const ALanguage: TXcomLanguage): string;
begin
  if ASoldier.WoundRecovery > 0 then
    Result := ALanguage.GetString('STR_WOUNDED').Text
  else if not Assigned(ASoldier.Craft) then
    Result := ALanguage.GetString('STR_NONE_UC').Text
  else
    Result := CraftName(TXcomCraft(ASoldier.Craft), ALanguage);
end;

class function TXcomBaseNames.TransferName(const ATransfer: TXcomTransfer; const ALanguage: TXcomLanguage): string;
begin
  if Assigned(ATransfer.Soldier) then
    Result := ATransfer.Soldier.Name
  else if Assigned(ATransfer.Craft) then
    Result := CraftName(ATransfer.Craft, ALanguage)
  else if ATransfer.Scientists <> 0 then
    Result := ALanguage.GetString('STR_SCIENTISTS').Text
  else if ATransfer.Engineers <> 0 then
    Result := ALanguage.GetString('STR_ENGINEERS').Text
  else
    Result := ALanguage.GetString(ATransfer.ItemId).Text;
end;

end.
