{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block [PARS]                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Pars;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>The ranges that the par times of a game accept</summary>
  TDehackedParsLimits = record
    /// <summary>PAR episode map time: the episodes go from 1 to this</summary>
    Episodes: Integer;
    /// <summary>and the maps from 1 to this</summary>
    MapsPerEpisode: Integer;
    /// <summary>PAR map time (the games with one list of maps): from 1 to this; 0 if the game has none, and the line is warned about</summary>
    Maps: Integer;
  end;

  /// <summary>
  ///   [PARS]: lines PAR episode map time, or PAR map time. A line whose numbers are out of the ranges
  ///   of the game is left out without a warning, as the old code did
  /// </summary>
  TDehackedParsReader = class(TDehackedReaderBase)
  private
    FLimits: TDehackedParsLimits;
  public
    constructor Create(const AKeywords: TArray<string>; const ALog: ILog;
      const ALimits: TDehackedParsLimits);
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedParsReader }

constructor TDehackedParsReader.Create(const AKeywords: TArray<string>; const ALog: ILog;
  const ALimits: TDehackedParsLimits);
begin
  inherited Create(AKeywords, ALog);
  FLimits := ALimits;
end;

function TDehackedParsReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LLine, LWord, LRest, LFirst, LSecond, LThird, LTail: string;
  LEntry: TDehackedEntry;
  LEpisode, LMap, LTime: Integer;
begin
  Result := CreateSection(dskPars, AKeyword, ARest, ASource);
  while ASource.Next(LLine) do
  begin
    TDehackedStrings.SplitChar(LLine, LWord, LRest);
    if LWord <> 'PAR' then
    begin
      ASource.PushBack;
      Break;
    end;

    TDehackedStrings.SplitChar(LRest, LFirst, LSecond);
    if LSecond = '' then
      Continue;

    LTail := LSecond;
    TDehackedStrings.SplitChar(LTail, LSecond, LThird);

    LEntry := Default(TDehackedEntry);
    LEntry.Line := ASource.LineNumber;
    LEntry.Key := LWord;
    if LThird <> '' then
    begin // episode, map and time
      LEpisode := TDehackedStrings.ToInteger(LFirst, -1);
      LMap := TDehackedStrings.ToInteger(LSecond, -1);
      LTime := TDehackedStrings.ToInteger(LThird, -1);
      if (LEpisode >= 1) and (LEpisode <= FLimits.Episodes) and (LMap >= 1) and
        (LMap <= FLimits.MapsPerEpisode) and (LTime >= 0) then
      begin
        LEntry.Numbers := [LEpisode, LMap, LTime];
        Result.AddEntry(LEntry);
      end;
    end
    else if FLimits.Maps > 0 then
    begin // map and time
      LMap := TDehackedStrings.ToInteger(LFirst, -1);
      LTime := TDehackedStrings.ToInteger(LSecond, -1);
      if (LMap >= 1) and (LMap <= FLimits.Maps) and (LTime >= 0) then
      begin
        LEntry.Numbers := [LMap, LTime];
        Result.AddEntry(LEntry);
      end;
    end
    else
      Warn('DEH_Parse(): Wrong misc value %s, field = %s'#13#10, [LFirst, LWord]);
  end;
end;

end.
