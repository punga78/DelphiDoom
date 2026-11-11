{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the crafts of a base (Base::getCraft-   }
{  Count and Base::removeCraft with the unloading)                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.BaseCrafts;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Transfer;

type
  /// <summary>
  ///   What Base does with its crafts that the saved game library does not have: counting the crafts of a type
  ///   (also those in transit) and taking a craft out of the base, unloading it into the storage
  /// </summary>
  TXcomBaseCrafts = class
  public
    /// <summary>getCraftCount: the crafts of the type, those that are being transferred included</summary>
    class function Count(const ABase: TXcomBase; const ACraftType: string): Integer; static;
    /// <summary>
    ///   removeCraft(craft, unload): the craft goes back to the storage when ACraft is unloaded, and leaves the
    ///   base; it is not freed (the caller owns it, as the C++ deletes it after the call)
    /// </summary>
    class function Remove(const ABase: TXcomBase; const ACraft: TXcomCraft; AUnload: Boolean;
      const ARuleset: TXcomRuleset): TXcomCraft; static;
  end;

implementation

{ TXcomBaseCrafts }

class function TXcomBaseCrafts.Count(const ABase: TXcomBase; const ACraftType: string): Integer;
var
  LTransfer: TXcomTransfer;
  LCraft: TXcomCraft;
begin
  Result := 0;
  for LTransfer in ABase.Transfers do
    if Assigned(LTransfer.Craft) and (LTransfer.Craft.Rules.CraftType = ACraftType) then
      Inc(Result);
  for LCraft in ABase.Crafts do
    if LCraft.Rules.CraftType = ACraftType then
      Inc(Result);
end;

class function TXcomBaseCrafts.Remove(const ABase: TXcomBase; const ACraft: TXcomCraft; AUnload: Boolean;
  const ARuleset: TXcomRuleset): TXcomCraft;
begin
  if AUnload then
    ACraft.Unload(ABase.StorageItems, ABase.Soldiers, ARuleset);
  // the hangar that held the craft is not modelled by the saved game library
  Result := ABase.RemoveCraft(ACraft);
end;

end.
