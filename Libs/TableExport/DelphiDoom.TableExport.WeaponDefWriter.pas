{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the weapons as WEAPON definitions         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.WeaponDefWriter;

interface

uses
  DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf, DelphiDoom.TableExport.Profile,
  DelphiDoom.TableExport.StateChain;

type
  /// <summary>
  ///   Writes the weapons as WEAPON definitions: the level (Heretic) or the class of the
  ///   player (Hexen), the ammo, the flags and the states
  /// </summary>
  TExportWeaponDefWriter = class(TInterfacedObject, IExportWeaponDefWriter)
  strict private
    FProfile: TExportProfile;
    FWeapons: IExportWeaponSource;
    FEnums: IExportEnumNames;
    FFlags: IExportFlagNames;
    FChain: TExportStateChain;
    FHasLevel: Boolean;
    function Write(const AWeapon: TExportWeapon): string;
  public
    /// <exception cref="EArgumentNilException">A source is nil</exception>
    constructor Create(const AProfile: TExportProfile; const AWeapons: IExportWeaponSource;
      const AStates: IExportStateSource; const AEnums: IExportEnumNames; const AFlags: IExportFlagNames);
    destructor Destroy; override;
    function WriteAll: string;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.IndentedText;

{ TExportWeaponDefWriter }

constructor TExportWeaponDefWriter.Create(const AProfile: TExportProfile;
  const AWeapons: IExportWeaponSource; const AStates: IExportStateSource;
  const AEnums: IExportEnumNames; const AFlags: IExportFlagNames);
var
  LLine: TExportLine;
begin
  inherited Create;
  if not Assigned(AWeapons) then
    raise EArgumentNilException.Create('AWeapons');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AEnums) then
    raise EArgumentNilException.Create('AEnums');
  if not Assigned(AFlags) then
    raise EArgumentNilException.Create('AFlags');
  FProfile := AProfile;
  FWeapons := AWeapons;
  FEnums := AEnums;
  FFlags := AFlags;
  FChain := TExportStateChain.Create(AStates);
  for LLine in AProfile.WeaponLines do
    if LLine.Kind = lkLevel then
      FHasLevel := True;
end;

destructor TExportWeaponDefWriter.Destroy;
begin
  FChain.Free;
  inherited Destroy;
end;

function TExportWeaponDefWriter.Write(const AWeapon: TExportWeapon): string;
var
  LText: TExportIndentedText;
  LName: string;
  LAmmo: Integer;
  LNames: TArray<string>;
  LBit: Integer;
  LLabels: TArray<TExportStateLabel>;
  LEntry: TExportStateLabel;

  function Entry(const ALabel: string; AField: TExportWeaponField): TExportStateLabel;
  begin
    Result.Name := ALabel;
    Result.State := AWeapon.Numbers[AField];
  end;

begin
  LText := TExportIndentedText.Create;
  try
    LName := UpperCase(FEnums.Name(eeWeapon, AWeapon.WeaponNo));
    LText.AddLine('// ' + LName);
    LText.AddLine('WEAPON ' + LName);
    LText.AddLine('{');
    if FHasLevel then
      LText.AddLine('Level LEVEL' + IntToStr(AWeapon.Level));
    if FProfile.WeaponHeaderHasClass then
      LText.AddLine('PlayerClass ' + UpperCase(FEnums.Name(eePlayerClass, AWeapon.PlayerClass)));

    LAmmo := AWeapon.Numbers[wfAmmo];
    if (LAmmo >= 0) and (LAmmo < FEnums.Count(eeAmmo)) then
      LText.AddLine('Ammo ' + UpperCase(FEnums.Name(eeAmmo, LAmmo)))
    else
      LText.AddLine('Ammo ' + IntToStr(LAmmo));
    LText.AddLine('AmmoPerShot ' + IntToStr(AWeapon.Numbers[wfAmmoPerShot]));

    LNames := FFlags.Names(fsWeaponFlagsMbf21);
    for LBit := 0 to High(LNames) do
      if (LBit < 32) and ((Cardinal(AWeapon.Numbers[wfMbf21Bits]) and (Cardinal(1) shl LBit)) <> 0) then
        LText.AddLine('+' + LNames[LBit]);

    LLabels := [
      Entry('Up', wfUpState), Entry('Down', wfDownState), Entry('Ready', wfReadyState),
      Entry('Attack', wfAttackState), Entry('Hold', wfHoldAttackState), Entry('Flash', wfFlashState)
    ];
    LText.AddLine('States');
    LText.AddLine('{');
    for LEntry in LLabels do
      FChain.Write(LText, LEntry.Name, LEntry.State, LLabels);
    LText.AddLine('}');
    LText.AddLine('}');
    LText.AddLine('');
    Result := LText.Text;
  finally
    LText.Free;
  end;
end;

function TExportWeaponDefWriter.WriteAll: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FWeapons.Count - 1 do
    Result := Result + Write(FWeapons.Get(LIndex));
end;

end.
