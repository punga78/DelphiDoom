{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the messages the game shows to the player        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): writemsg and rewritemsg of  }
{  d_font.pas                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MessageLine;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Font,
  DelphiDoom.Greed.TextPrinter;

const
  /// <summary>MSGQUESIZE: the lines that are shown together</summary>
  GREED_MESSAGE_QUEUE_SIZE = 3;
  /// <summary>MSGTIME: the tics after which the oldest line goes away</summary>
  GREED_MESSAGE_TIME = 350;
  /// <summary>The lines are string[255] in the original: a longer text is cut</summary>
  GREED_MESSAGE_MAX_LENGTH = 255;

type
  /// <summary>
  ///   msgstr and timemsg of d_font.pas. WriteMessage (writemsg) puts the text in the last of the three lines,
  ///   moving the others up if that one is taken; Rewrite (rewritemsg) draws the lines that are not empty at each
  ///   frame, with the first font and the base color 73, and when the time is over drops the first line.
  ///   Not ported: the copy of the message on the console (printf)
  /// </summary>
  TGreedMessageLine = class(TInterfacedObject, IGreedMessages)
  strict private
    FState: TGreedGameState;
    FPrinter: TGreedTextPrinter;
    FFont: TGreedFont;
    FLines: array[0..GREED_MESSAGE_QUEUE_SIZE - 1] of string;
    FTimeMessage: Integer;
    function GetLine(AIndex: Integer): string;
  public
    /// <summary>
    ///   AState gives timecount; AFont is font1 of the original (the lump FONT1). Nothing is owned
    /// </summary>
    constructor Create(AState: TGreedGameState; APrinter: TGreedTextPrinter; AFont: TGreedFont);
    /// <summary>writemsg(s)</summary>
    procedure WriteMessage(const AText: string);
    /// <summary>
    ///   rewritemsg: ACurrentViewSize is currentViewSize (from 4 on the lines start 10 rows lower, under the top
    ///   bar)
    /// </summary>
    procedure Rewrite(ACurrentViewSize: Integer);
    /// <summary>msgstr[index]</summary>
    property Lines[AIndex: Integer]: string read GetLine;
    /// <summary>timemsg</summary>
    property TimeMessage: Integer read FTimeMessage write FTimeMessage;
  end;

implementation

uses
  DelphiDoom.Greed.Types;

const
  MESSAGE_BASE_COLOR = 73;

{ TGreedMessageLine }

constructor TGreedMessageLine.Create(AState: TGreedGameState; APrinter: TGreedTextPrinter; AFont: TGreedFont);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(APrinter) then
    raise EArgumentNilException.Create('APrinter');
  if not Assigned(AFont) then
    raise EArgumentNilException.Create('AFont');
  FState := AState;
  FPrinter := APrinter;
  FFont := AFont;
end;

function TGreedMessageLine.GetLine(AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= GREED_MESSAGE_QUEUE_SIZE) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [AIndex, 'message line', 0, GREED_MESSAGE_QUEUE_SIZE - 1]);
  Result := FLines[AIndex];
end;

procedure TGreedMessageLine.WriteMessage(const AText: string);
var
  LIndex: Integer;
begin
  if FLines[GREED_MESSAGE_QUEUE_SIZE - 1] <> '' then
    for LIndex := 1 to GREED_MESSAGE_QUEUE_SIZE - 1 do
      FLines[LIndex - 1] := FLines[LIndex];
  FLines[GREED_MESSAGE_QUEUE_SIZE - 1] := Copy(AText, 1, GREED_MESSAGE_MAX_LENGTH);
  FTimeMessage := FState.TimeCount + GREED_MESSAGE_TIME;
end;

procedure TGreedMessageLine.Rewrite(ACurrentViewSize: Integer);
var
  LIndex: Integer;
  LLine: Integer;
begin
  FPrinter.BaseColor := MESSAGE_BASE_COLOR;
  FPrinter.Font := FFont;
  LLine := 0;
  for LIndex := 0 to GREED_MESSAGE_QUEUE_SIZE - 1 do
    if FLines[LIndex] <> '' then
    begin
      FPrinter.PrintX := 2;
      FPrinter.PrintY := 1 + LLine * 6;
      Inc(LLine);
      if ACurrentViewSize >= 4 then
        FPrinter.PrintY := FPrinter.PrintY + 10;
      FPrinter.RawPrint2(FLines[LIndex]);
    end;
  if FState.TimeCount > FTimeMessage then
  begin
    for LIndex := 1 to GREED_MESSAGE_QUEUE_SIZE - 1 do
      FLines[LIndex - 1] := FLines[LIndex];
    FLines[GREED_MESSAGE_QUEUE_SIZE - 1] := '';
    FTimeMessage := FState.TimeCount + GREED_MESSAGE_TIME;
  end;
end;

end.
