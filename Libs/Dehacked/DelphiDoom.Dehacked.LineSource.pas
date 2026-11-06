{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the lines of a patch                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.LineSource;

interface

uses
  DelphiDoom.Dehacked.Intf;

type
  /// <summary>
  ///   The lines of a patch (DEH_NextLine): the lines that are blank or that start with # or //
  ///   are left out, the others are trimmed and in upper case
  /// </summary>
  TDehackedLineSource = class(TInterfacedObject, IDehackedLineSource)
  private
    FLines: TArray<string>;
    FCounter: Integer;
    FLast: string;
    FLastNumber: Integer;
    FPushedBack: Boolean;
  public
    constructor Create(const ALines: TArray<string>);
    function Next(out ALine: string; ASkipBlank: Boolean = True): Boolean;
    function HasMoreLines: Boolean;
    function LastLine: string;
    function LineNumber: Integer;
    procedure PushBack;
    function TakePushBack: Boolean;
  end;

implementation

uses
  DelphiDoom.Dehacked.Strings;

{ TDehackedLineSource }

constructor TDehackedLineSource.Create(const ALines: TArray<string>);
begin
  inherited Create;
  FLines := ALines;
end;

function TDehackedLineSource.Next(out ALine: string; ASkipBlank: Boolean): Boolean;
var
  LText, LTrimmed: string;
  LSkip: Boolean;
begin
  LSkip := ASkipBlank;
  while FCounter < Length(FLines) do
  begin
    LText := FLines[FCounter];
    LTrimmed := TDehackedStrings.Trim(LText);
    if LSkip then
      LText := LTrimmed;
    Inc(FCounter);
    // the old function called itself for the lines it left out, and the call always skipped
    // the blank lines, whatever the first one did
    if (LSkip and (LText = '')) or (TDehackedStrings.IndexOfChar('#', LTrimmed) = 1) or
      TDehackedStrings.StartsWith('//', LTrimmed) then
    begin
      LSkip := True;
      Continue;
    end;
    FLast := TDehackedStrings.Upper(LText);
    FLastNumber := FCounter;
    ALine := FLast;
    Exit(True);
  end;
  ALine := FLast;
  Result := False;
end;

function TDehackedLineSource.HasMoreLines: Boolean;
begin
  Result := FCounter < Length(FLines);
end;

function TDehackedLineSource.LastLine: string;
begin
  Result := FLast;
end;

function TDehackedLineSource.LineNumber: Integer;
begin
  Result := FLastNumber;
end;

procedure TDehackedLineSource.PushBack;
begin
  FPushedBack := True;
end;

function TDehackedLineSource.TakePushBack: Boolean;
begin
  Result := FPushedBack;
  FPushedBack := False;
end;

end.
