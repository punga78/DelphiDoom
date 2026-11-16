{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the names of color regions and blood colors    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.TranslationNames;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>
  ///   The naming rules of r_translations.pas: how a name (BRICK, CR_RED, CRRED, a lump name)
  ///   finds a table and which lumps to try (the blood colors are TTranslationBlood). The tables
  ///   themselves stay in the engine: here a table is a slot number
  /// </summary>
  TTranslationNames = class(TInterfacedObject, ITranslationNames)
  strict private
    var
      FSlots: TDictionary<string, Integer>;
      FNextSlot: Integer;
    class function StartsWith(const APrefix, AText: string): Boolean; static;
    procedure RegisterRegions;
  public
    constructor Create;
    destructor Destroy; override;
    function FindSlot(const AName: string; out AKey: string): Integer;
    function AddSlot(const AKey: string): Integer;
    function LumpCandidates(const AName: string): TArray<string>;
  end;

implementation

{ TTranslationNames }

constructor TTranslationNames.Create;
begin
  inherited Create;
  FSlots := TDictionary<string, Integer>.Create;
  FNextSlot := REGION_COUNT;
  RegisterRegions;
end;

destructor TTranslationNames.Destroy;
begin
  FSlots.Free;
  inherited Destroy;
end;

class function TTranslationNames.StartsWith(const APrefix, AText: string): Boolean;
begin
  Result := (Length(AText) >= Length(APrefix)) and (Copy(AText, 1, Length(APrefix)) = APrefix);
end;

procedure TTranslationNames.RegisterRegions;
const
  NAMES: array[0..REGION_COUNT - 1] of string = (
    'BRICK', 'TAN', 'GRAY', 'GREEN', 'BROWN', 'GOLD', 'RED', 'BLUE', 'ORANGE', 'YELLOW', 'BLUE2',
    'BLACK', 'PURPL', 'WHITE', 'TRANS0', 'TRANS1', 'TRANS2', 'TRANS3', 'TRANS4', 'TRANS5',
    'TRANS6', 'TRANS7', 'TRANS8', 'TRANS9');
var
  LIndex: Integer;
begin
  for LIndex := 0 to REGION_COUNT - 1 do
    FSlots.AddOrSetValue(NAMES[LIndex], LIndex);
  FSlots.AddOrSetValue('PURPLE', REGION_PURPL);
end;

function TTranslationNames.FindSlot(const AName: string; out AKey: string): Integer;
begin
  AKey := UpperCase(AName);
  if not FSlots.TryGetValue(AKey, Result) then
  begin
    Result := -1;
    if StartsWith('CR_', AKey) then
    begin
      Delete(AKey, 1, 3);
      if not FSlots.TryGetValue(AKey, Result) then
        Result := -1;
    end;
    if Result < 0 then
      if StartsWith('CR', AKey) then
      begin
        Delete(AKey, 1, 2);
        if not FSlots.TryGetValue(AKey, Result) then
          Result := -1;
      end;
  end;
end;

function TTranslationNames.AddSlot(const AKey: string): Integer;
begin
  Result := FNextSlot;
  Inc(FNextSlot);
  FSlots.AddOrSetValue(AKey, Result);
end;

function TTranslationNames.LumpCandidates(const AName: string): TArray<string>;
var
  LShort: string;
begin
  Result := [AName];
  if StartsWith('CR_', UpperCase(AName)) then
  begin
    LShort := AName;
    Delete(LShort, 3, 1);
    Result := Result + [LShort];
  end
  else if StartsWith('CR', UpperCase(AName)) then
  begin
    LShort := AName;
    Insert('_', LShort, 3);
    Result := Result + [LShort];
  end
  else
    Result := Result + ['CR' + AName, 'CR_' + AName];
end;

end.
