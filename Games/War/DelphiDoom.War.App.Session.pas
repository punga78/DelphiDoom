{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a game that can be saved and loaded               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.Session;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.GameHost.Types, DelphiDoom.War.Ui.Intf,
  DelphiDoom.War.Save.Types, DelphiDoom.War.App.SessionTypes, DelphiDoom.War.App.SessionRequests;

type
  /// <summary>
  ///   A game and the history that made it. The model of the game is deterministic (the same generator, the same
  ///   times, the same input give the same game), so the history is what is saved: how the game started and, for each
  ///   frame, the time and the events of the player. Loading makes a new game and plays the history again without
  ///   showing it. The saved game is small and has no pointers; its cost is that loading takes as long to compute as the
  ///   game took to play (without the screen and the clock). F5 and F9 save and load the quick slot
  /// </summary>
  TWarSession = class
  strict private
    FBuilder: TWarGameBuilder;
    FStart: TWarSessionStart;
    FDataSize: Cardinal;
    FRequests: TWarSessionRequests;
    FRequestsRef: IWarSessionRequests;
    FGame: IWarSessionGame;
    FFrames: TList<TWarSaveFrame>;
    FPending: TList<TGameHostEvent>;
    FBeforeReplay: TProc;
    FAfterReplay: TProc;
    function IsHotKey(const AEvent: TGameHostEvent): Boolean;
  public
    /// <summary>
    ///   The builder makes the game (now, and each time a game is loaded); ADataSize is the size of the DATA.WAR in
    ///   use (a saved game of another file is refused). The two procedures, which may be nil, are called around the
    ///   replay of a loaded game: the program mutes the sound while the old frames are played again
    /// </summary>
    constructor Create(const ABuilder: TWarGameBuilder; const AStart: TWarSessionStart; ADataSize: Cardinal;
      const ABeforeReplay, AAfterReplay: TProc);
    destructor Destroy; override;
    /// <summary>
    ///   An event of the window: the game sees it at once, and it goes in the history of the frame that comes next.
    ///   F5 and F9 are not the game's: they ask to save and to load
    /// </summary>
    procedure Post(const AEvent: TGameHostEvent);
    /// <summary>One frame of ADelta seconds, with the events posted since the last one</summary>
    procedure RunFrame(ADelta: Single);
    /// <summary>The bytes of a saved game of the history so far</summary>
    function Save: TBytes;
    /// <summary>
    ///   Makes a new game and plays on it the history in the bytes; the game that was running is let go when
    ///   the replay has succeeded, and stays if it has not. EWarSaveException if the bytes are not a game that this
    ///   program can play
    /// </summary>
    procedure Load(const ABytes: TBytes);
    property Game: IWarSessionGame read FGame;
    /// <summary>The requests of the menus and of the keys: the loop of the program takes them between two frames</summary>
    property RequestsObject: TWarSessionRequests read FRequests;
    property Requests: IWarSessionRequests read FRequestsRef;
    /// <summary>The frames played, in this game or in the one that was loaded</summary>
    function FrameCount: Integer;
    property Start: TWarSessionStart read FStart;
  end;

implementation

uses
  DelphiDoom.War.Save.Writer, DelphiDoom.War.Save.Reader;

const
  VK_F5_KEY = $74;
  VK_F9_KEY = $78;

{ TWarSession }

constructor TWarSession.Create(const ABuilder: TWarGameBuilder; const AStart: TWarSessionStart; ADataSize: Cardinal;
  const ABeforeReplay, AAfterReplay: TProc);
begin
  inherited Create;
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('ABuilder');
  FBuilder := ABuilder;
  FStart := AStart;
  FDataSize := ADataSize;
  FBeforeReplay := ABeforeReplay;
  FAfterReplay := AAfterReplay;
  FRequests := TWarSessionRequests.Create;
  FRequestsRef := FRequests;
  FFrames := TList<TWarSaveFrame>.Create;
  FPending := TList<TGameHostEvent>.Create;
  FGame := FBuilder(FStart, FRequestsRef);
end;

destructor TWarSession.Destroy;
begin
  FGame := nil;
  FPending.Free;
  FFrames.Free;
  FRequestsRef := nil;
  inherited Destroy;
end;

function TWarSession.IsHotKey(const AEvent: TGameHostEvent): Boolean;
begin
  Result := (AEvent.Kind in [hekKeyDown, hekKeyUp]) and ((AEvent.VirtualKey = VK_F5_KEY) or
    (AEvent.VirtualKey = VK_F9_KEY));
end;

procedure TWarSession.Post(const AEvent: TGameHostEvent);
begin
  if IsHotKey(AEvent) then
  begin
    if AEvent.Kind = hekKeyDown then
    begin
      if AEvent.VirtualKey = VK_F5_KEY then
        FRequests.RequestSave
      else
        FRequests.RequestLoad;
    end;
    Exit;
  end;
  if TWarSaveWriter.IsSaved(AEvent) then
    FPending.Add(AEvent);
  FGame.Post(AEvent);
end;

procedure TWarSession.RunFrame(ADelta: Single);
var
  LFrame: TWarSaveFrame;
begin
  LFrame.Delta := ADelta;
  LFrame.Events := FPending.ToArray;
  FPending.Clear;
  FFrames.Add(LFrame);
  FGame.RunFrame(ADelta);
end;

function TWarSession.FrameCount: Integer;
begin
  Result := FFrames.Count;
end;

function TWarSession.Save: TBytes;
var
  LContent: TWarSaveContent;
begin
  LContent := Default(TWarSaveContent);
  LContent.Seed := FStart.Seed;
  LContent.DataSize := FDataSize;
  LContent.StartRace := FStart.Race;
  LContent.StartMission := FStart.Mission;
  LContent.Introduction := FStart.Introduction;
  LContent.Frames := FFrames.ToArray;
  Result := TWarSaveWriter.Write(LContent);
end;

procedure TWarSession.Load(const ABytes: TBytes);
var
  LContent: TWarSaveContent;
  LStart: TWarSessionStart;
  LGame: IWarSessionGame;
  LFrame: Integer;
  LEvent: Integer;
begin
  LContent := TWarSaveReader.Read(ABytes, FDataSize);
  LStart.Seed := LContent.Seed;
  LStart.Race := LContent.StartRace;
  LStart.Mission := LContent.StartMission;
  LStart.Introduction := LContent.Introduction;
  LGame := FBuilder(LStart, FRequestsRef);
  if Assigned(FBeforeReplay) then
    FBeforeReplay();
  try
    for LFrame := 0 to High(LContent.Frames) do
    begin
      for LEvent := 0 to High(LContent.Frames[LFrame].Events) do
        LGame.Post(LContent.Frames[LFrame].Events[LEvent]);
      LGame.RunFrame(LContent.Frames[LFrame].Delta);
    end;
  finally
    if Assigned(FAfterReplay) then
      FAfterReplay();
  end;
  // what the buttons asked while the old frames were played again was asked then, not now
  FRequests.Clear;
  FStart := LStart;
  FFrames.Clear;
  FFrames.AddRange(LContent.Frames);
  FPending.Clear;
  FGame := LGame;
end;

end.
