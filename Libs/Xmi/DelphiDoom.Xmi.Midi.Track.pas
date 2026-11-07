{******************************************************************************}
{                                                                              }
{  DelphiDoom: XMI/CMF/SOP - a track: a list of events                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xmi.Midi.Track;

interface

uses
  System.SysUtils, DelphiDoom.Xmi.Midi.Types;

type
  /// <summary>
  ///   The events of one track, in order. Their fields can be changed in
  ///   place through Events
  /// </summary>
  TXmiTrack = class
  private
    FEvents: TArray<TXmiEvent>;
    FCount: Integer;
    FTitle: AnsiString;
    function GetEvent(AIndex: Integer): TXmiEvent;
    procedure Grow;
  public
    function Add(const AEvent: TXmiEvent): Integer;

    /// <summary>
    ///   Adds an event read from a file: the first track name (meta event 3
    ///   with a text) becomes the title of the track
    /// </summary>
    procedure AddRead(const AEvent: TXmiEvent);

    /// <summary>
    ///   Inserts AEvent before the event AIndex (at the end if AIndex = Count)
    /// </summary>
    procedure Insert(AIndex: Integer; const AEvent: TXmiEvent);

    /// <summary>
    ///   Removes the event AIndex; with ASaveTime its delay is added to the
    ///   next event, so the rest of the track keeps its time
    /// </summary>
    procedure Delete(AIndex: Integer; ASaveTime: Boolean);

    /// <summary>
    ///   Address of the event AIndex, to change one of its fields in place
    ///   (valid until the next Add, Insert or Delete)
    /// </summary>
    function EventAt(AIndex: Integer): PXmiEvent;

    property Event[AIndex: Integer]: TXmiEvent read GetEvent; default;
    property Count: Integer read FCount;
    property Title: AnsiString read FTitle write FTitle;
  end;

implementation

{ TXmiTrack }

function TXmiTrack.GetEvent(AIndex: Integer): TXmiEvent;
begin
  Result := FEvents[AIndex];
end;

function TXmiTrack.EventAt(AIndex: Integer): PXmiEvent;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.Create('AIndex');

  Result := @FEvents[AIndex];
end;

procedure TXmiTrack.Grow;
begin
  if FCount = Length(FEvents) then
  begin
    if FCount < 16 then
      SetLength(FEvents, 16)
    else
      SetLength(FEvents, FCount * 2);
  end;
end;

function TXmiTrack.Add(const AEvent: TXmiEvent): Integer;
begin
  Grow;
  FEvents[FCount] := AEvent;
  Result := FCount;
  Inc(FCount);
end;

procedure TXmiTrack.AddRead(const AEvent: TXmiEvent);
begin
  if (AEvent.Status = XMI_STATUS_META) and (AEvent.Param1 = XMI_META_TRACK_NAME) and
     (FTitle = '') and (AEvent.Text <> '') then
    FTitle := AEvent.Text;
  Add(AEvent);
end;

procedure TXmiTrack.Insert(AIndex: Integer; const AEvent: TXmiEvent);
var
  LIndex: Integer;
begin
  if (AIndex < 0) or (AIndex > FCount) then
    raise EArgumentOutOfRangeException.Create('AIndex');

  Grow;
  for LIndex := FCount downto AIndex + 1 do
    FEvents[LIndex] := FEvents[LIndex - 1];
  FEvents[AIndex] := AEvent;
  Inc(FCount);
end;

procedure TXmiTrack.Delete(AIndex: Integer; ASaveTime: Boolean);
var
  LIndex: Integer;
  LDelay: UInt64;
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.Create('AIndex');

  LDelay := FEvents[AIndex].Ticks;
  for LIndex := AIndex + 1 to FCount - 1 do
    FEvents[LIndex - 1] := FEvents[LIndex];
  Dec(FCount);
  FEvents[FCount] := Default(TXmiEvent);
  if ASaveTime and (AIndex < FCount) then
    FEvents[AIndex].Ticks := FEvents[AIndex].Ticks + LDelay;
end;

end.
