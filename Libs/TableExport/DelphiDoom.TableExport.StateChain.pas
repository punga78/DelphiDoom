{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - a group of states as a definition         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.StateChain;

interface

uses
  DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf, DelphiDoom.TableExport.IndentedText;

type
  /// <summary>
  ///   Writes the states that follow one another from a first state as a block
  ///   "Label: { ... }" of an ACTOR or WEAPON definition. The chain stops at a state that never
  ///   ends, at the end of the states, at a state that was written already (Loop and Goto) or at
  ///   a state that starts another label of the owner (Goto Label)
  /// </summary>
  TExportStateChain = class
  strict private
    FStates: IExportStateSource;
    class function ActionText(const AState: TExportState): string; static;
    class function DurationText(const AState: TExportState): string; static;
  public
    /// <exception cref="EArgumentNilException">AStates is nil</exception>
    constructor Create(const AStates: IExportStateSource);
    /// <summary>Nothing is written if AFirstState is 0 or less</summary>
    procedure Write(const AText: TExportIndentedText; const ALabel: string; AFirstState: Integer;
      const ALabels: TArray<TExportStateLabel>);
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections;

{ TExportStateChain }

constructor TExportStateChain.Create(const AStates: IExportStateSource);
begin
  inherited Create;
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  FStates := AStates;
end;

class function TExportStateChain.ActionText(const AState: TExportState): string;
begin
  if not AState.HasAction then
    Exit('');
  Result := AState.ActionName;
  if Result = 'NULL' then
    Exit('');
  Result := ' ' + Result;
  if AState.HasParams then
    Result := Result + ' ' + AState.Params;
end;

class function TExportStateChain.DurationText(const AState: TExportState): string;
var
  LTics: Integer;
  LTics2: Integer;
  LFlags: Integer;
begin
  LTics := AState.Numbers[sfTics];
  LTics2 := AState.Numbers[sfTics2];
  LFlags := AState.Numbers[sfFlagsEx];
  if LFlags and EXPORT_STATE_RANDOM_SELECT <> 0 then
    Result := 'RANDOMSELECT(' + IntToStr(LTics) + ',' + IntToStr(LTics2) + ')'
  else if LFlags and EXPORT_STATE_RANDOM_RANGE <> 0 then
    Result := 'RANDOMRANGE(' + IntToStr(LTics) + ',' + IntToStr(LTics2) + ')'
  else
    Result := IntToStr(LTics);
end;

procedure TExportStateChain.Write(const AText: TExportIndentedText; const ALabel: string;
  AFirstState: Integer; const ALabels: TArray<TExportStateLabel>);
var
  LChain: TList<Integer>;
  LCurrent: Integer;
  LNext: Integer;
  LIndex: Integer;
  LState: TExportState;
  LLine: string;

  function GotoOtherLabel(AState: Integer): Boolean;
  var
    LEntry: TExportStateLabel;
  begin
    for LEntry in ALabels do
      if AState = LEntry.State then
      begin
        AText.AddLine('Goto ' + LEntry.Name);
        Exit(True);
      end;
    Result := False;
  end;

begin
  if AFirstState <= 0 then
    Exit;
  LChain := TList<Integer>.Create;
  try
    LChain.Add(AFirstState);
    LCurrent := AFirstState;
    AText.AddLine(ALabel + ':');
    AText.AddLine('{');
    while True do
    begin
      LState := FStates.Get(LCurrent);
      LLine := LState.SpriteName + ' ' +
        Char(Ord('A') + (LState.Numbers[sfFrame] and EXPORT_FRAME_MASK)) + ' ' +
        DurationText(LState) + ActionText(LState);
      if LState.Numbers[sfFrame] and EXPORT_FRAME_FULLBRIGHT <> 0 then
        LLine := LLine + ' BRIGHT';
      if LState.Numbers[sfMbf21Bits] and EXPORT_STATE_SKILL5FAST <> 0 then
        LLine := LLine + ' FAST';
      AText.AddLine(LLine);

      if LState.Numbers[sfTics] < 0 then
        Break;
      LNext := LState.Numbers[sfNextState];
      if LNext <= 0 then
      begin
        AText.AddLine('Stop');
        Break;
      end;
      LIndex := LChain.IndexOf(LNext);
      if LIndex >= 0 then
      begin
        if LIndex = 0 then
          AText.AddLine('Loop')
        else
          AText.AddLine('Goto ' + ALabel + '+' + IntToStr(LIndex));
        Break;
      end;
      if GotoOtherLabel(LNext) then
        Break;
      LChain.Add(LNext);
      LCurrent := LNext;
    end;
    AText.AddLine('}');
  finally
    LChain.Free;
  end;
end;

end.
