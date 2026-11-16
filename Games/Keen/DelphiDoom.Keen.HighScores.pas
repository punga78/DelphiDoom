{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the table of the scores                           }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  Scores[], US_DisplayHighScores and US_CheckHighScore of id_us.c              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.HighScores;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf;

type
  /// <summary>
  ///   The ten best scores, with the number of levels done. A new score takes the place of the first one that is
  ///   lower (or equal with fewer levels) and the ones below go down; the screen shows the table and, for a new
  ///   line, asks for the name
  /// </summary>
  TKeenHighScores = class(TInterfacedObject, IKeenHighScores)
  strict private
    FWindows: IKeenUserWindows;
    FInput: IKeenInput;
    FScores: array[0..KEEN_MAX_SCORES - 1] of TKeenHighScore;
    FDirty: Boolean;
    procedure CheckIndex(AIndex: Integer);
  public
    /// <param name="AWindows">Where the table is drawn</param>
    /// <param name="AInput">The wait of five seconds after the table (IN_UserInput)</param>
    constructor Create(const AWindows: IKeenUserWindows; const AInput: IKeenInput);
    function GetScore(AIndex: Integer): TKeenHighScore;
    procedure SetScore(AIndex: Integer; const AValue: TKeenHighScore);
    function GetDirty: Boolean;
    function Insert(AScore: Integer; ACompleted: Word): Integer;
    procedure Display(AWhich: Integer);
    procedure Check(AScore: Integer; ACompleted: Word);
  end;

implementation

{ TKeenHighScores }

constructor TKeenHighScores.Create(const AWindows: IKeenUserWindows; const AInput: IKeenInput);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AWindows) then
    raise EArgumentNilException.Create('AWindows');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  FWindows := AWindows;
  FInput := AInput;
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
    FScores[LIndex].Score := 10000;
end;

procedure TKeenHighScores.CheckIndex(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= KEEN_MAX_SCORES) then
    raise EArgumentOutOfRangeException.Create('AIndex');
end;

function TKeenHighScores.GetScore(AIndex: Integer): TKeenHighScore;
begin
  CheckIndex(AIndex);
  Result := FScores[AIndex];
end;

procedure TKeenHighScores.SetScore(AIndex: Integer; const AValue: TKeenHighScore);
begin
  CheckIndex(AIndex);
  FScores[AIndex] := AValue;
end;

function TKeenHighScores.GetDirty: Boolean;
begin
  Result := FDirty;
end;

function TKeenHighScores.Insert(AScore: Integer; ACompleted: Word): Integer;
var
  LIndex: Integer;
  LMove: Integer;
begin
  Result := -1;
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
    if (AScore > FScores[LIndex].Score) or
      ((AScore = FScores[LIndex].Score) and (ACompleted > FScores[LIndex].Completed)) then
    begin
      for LMove := KEEN_MAX_SCORES - 1 downto LIndex + 1 do
        FScores[LMove] := FScores[LMove - 1];
      FScores[LIndex].Name := '';
      FScores[LIndex].Score := AScore;
      FScores[LIndex].Completed := ACompleted;
      FDirty := True;
      Exit(LIndex);
    end;
end;

procedure TKeenHighScores.Display(AWhich: Integer);
var
  LVideo: IKeenBufferedVideo;
  LWindow: TKeenWindowRec;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LMiddle: Integer;
  LDigits: AnsiString;
  LDigit: Integer;
  LWidth: Integer;
  LHeight: Integer;
  LName: AnsiString;
begin
  LVideo := FWindows.Video;
  FWindows.CenterWindow(30, KEEN_MAX_SCORES + (KEEN_MAX_SCORES div 2));
  LWindow := FWindows.Window;
  LMiddle := LWindow.X + (LWindow.W div 2);
  FWindows.Print(' Name');
  FWindows.PrintX := LMiddle + 20;
  FWindows.Print('Score');
  FWindows.PrintX := LMiddle + 60;
  FWindows.Print('Done'#10#10);
  FWindows.PrintY := FWindows.PrintY - 3;
  // the line under the titles
  LX := LWindow.X;
  while LX < LWindow.X + LWindow.W do
  begin
    LVideo.DrawTile8Masked(LX, LWindow.Y + 8, 10);
    Inc(LX, 8);
  end;
  LVideo.DrawTile8Masked(LWindow.X - 8, LWindow.Y + 8, 9);
  LVideo.DrawTile8Masked(LWindow.X + LWindow.W, LWindow.Y + 8, 11);
  LY := 0;
  for LIndex := 0 to KEEN_MAX_SCORES - 1 do
  begin
    if LIndex = AWhich then
      LVideo.FontColor := KEEN_F_SECONDCOLOR
    else
      LVideo.FontColor := KEEN_F_BLACK;
    if LIndex <> AWhich then
    begin
      FWindows.Print(' ');
      if Length(FScores[LIndex].Name) > 0 then
        FWindows.Print(FScores[LIndex].Name)
      else
        FWindows.Print('-');
    end
    else
      LY := FWindows.PrintY;
    FWindows.PrintX := LMiddle + (7 * 8);
    // the score with the digits of fixed width of the font (the characters 129..138)
    LDigits := AnsiString(UIntToStr(Cardinal(FScores[LIndex].Score)));
    for LDigit := 1 to Length(LDigits) do
      LDigits[LDigit] := AnsiChar(Ord(LDigits[LDigit]) + (129 - Ord('0')));
    LVideo.MeasureString(LDigits, LWidth, LHeight);
    FWindows.PrintX := FWindows.PrintX - LWidth;
    FWindows.Print(LDigits);
    FWindows.PrintX := LMiddle + 60;
    if FScores[LIndex].Completed <> 0 then
      FWindows.PrintUnsigned(FScores[LIndex].Completed)
    else
      FWindows.Print('-');
    FWindows.Print(#10);
  end;
  if (AWhich >= 0) and (AWhich < KEEN_MAX_SCORES) then
  begin
    LVideo.FontColor := KEEN_F_SECONDCOLOR;
    FWindows.PrintY := LY;
    FWindows.PrintX := LWindow.X;
    FWindows.Print(' ');
    LName := '';
    FWindows.LineInput(FWindows.PrintX, FWindows.PrintY, LName, '', True, KEEN_MAX_HIGH_NAME, (LWindow.W div 2) - 8);
    FScores[AWhich].Name := LName;
  end;
  LVideo.FontColor := KEEN_F_BLACK;
  LVideo.UpdateScreen;
end;

procedure TKeenHighScores.Check(AScore: Integer; ACompleted: Word);
var
  LPlace: Integer;
begin
  LPlace := Insert(AScore, ACompleted);
  FWindows.Video.InitDoubleBuffer;
  FWindows.Video.Bar(0, 0, KEEN_MAX_X, KEEN_MAX_Y, KEEN_FIRSTCOLOR);
  Display(LPlace);
  FInput.UserInput(5 * KEEN_TICKBASE, False);
end;

end.
