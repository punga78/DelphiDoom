{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the text of SNDINFO                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.SoundInfoParser;

interface

uses
  System.SysUtils, DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf,
  DelphiDoom.ActorDef.SoundAliases;

type
  /// <summary>
  ///   Reads the text of SNDINFO (all the lumps one after the other, as one text) and fills the
  ///   aliases of the sounds. A line is a name and a value, separated by spaces, = or tabs; what
  ///   follows // or ; is a comment. In Hexen $MAP gives the song of a map and the names go to the
  ///   engine too: that is for the listener
  /// </summary>
  TActorDefSoundInfoParser = class
  private
    FProfile: TActorDefProfile;
    FAliases: IActorDefSoundAliasTable;
    FListener: IActorDefSoundInfoListener;
  public
    /// <param name="AAliases">Where the names go</param>
    /// <param name="AListener">What the engine does with $MAP and with the names (Hexen); may be nil</param>
    constructor Create(const AProfile: TActorDefProfile; const AAliases: IActorDefSoundAliasTable;
      const AListener: IActorDefSoundInfoListener);
    procedure Parse(const AText: string);
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TActorDefSoundInfoParser }

constructor TActorDefSoundInfoParser.Create(const AProfile: TActorDefProfile;
  const AAliases: IActorDefSoundAliasTable; const AListener: IActorDefSoundInfoListener);
begin
  inherited Create;
  FProfile := AProfile;
  FAliases := AAliases;
  FListener := AListener;
end;

procedure TActorDefSoundInfoParser.Parse(const AText: string);

  // splits at the first space, = or tab; both parts are trimmed (the old splitstring)
  procedure Split(const AInput: string; out AFirst, ASecond: string);
  var
    LIndex: Integer;
  begin
    for LIndex := 1 to Length(AInput) do
      if CharInSet(AInput[LIndex], [' ', '=', #9]) then
      begin
        AFirst := TScannerStrings.Trim(Copy(AInput, 1, LIndex - 1));
        ASecond := TScannerStrings.Trim(Copy(AInput, LIndex + 1, MaxInt));
        Exit;
      end;
    AFirst := AInput;
    ASecond := '';
  end;

var
  LLine: string;
  LText: string;
  LPosition: Integer;
  LName: string;
  LValue: string;
  LMapId: Integer;
begin
  for LLine in TScannerStrings.SplitLines(TActorDefSoundAliases.Normalize(AText)) do
  begin
    LText := TScannerStrings.Trim(LLine);
    LPosition := Pos('//', LText);
    if LPosition > 0 then
      LText := Copy(LText, 1, LPosition - 1);
    LPosition := Pos(';', LText);
    if LPosition > 0 then
      LText := Copy(LText, 1, LPosition - 1);
    if LText = '' then
      Continue;
    Split(LText, LName, LValue);
    LValue := TScannerStrings.Trim(LValue);
    if LValue = '' then
      Continue;

    if FProfile.SoundInfoHexenExtensions and (LName = '$MAP') then
    begin
      // the song of a map
      LText := LValue;
      Split(LText, LName, LValue);
      if LName <> '0' then
      begin
        LMapId := TScannerStrings.ToInteger(LName);
        if (LMapId > 0) and Assigned(FListener) then
          FListener.SongForMap(LMapId, LValue);
      end;
    end
    else
    begin
      LName := TScannerStrings.Trim(LName);
      FAliases.Add(LName, LValue);
      if FProfile.SoundInfoHexenExtensions and Assigned(FListener) then
        FListener.AliasDeclared(LName, LValue);
    end;
  end;
end;

end.
