{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the event loop (idEventLoop)              }
{                                                                              }
{  Port of Doom 3 (id Software): framework\EventLoop.cpp, EventLoop.h.         }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.EventLoop;

interface

uses
  System.SysUtils, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf, DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf;

type
  /// <summary>
  ///   The event loop receives events from the system and dispatches them to the various parts of the engine
  ///   (key states, the command buffer for console lines, the session for the others). It also handles the
  ///   journal: with com_journal 1 every event that the system gives is written to journal.dat, with 2 the
  ///   events come from the file. In the journal an event takes 20 bytes (type, value, value2, length of the
  ///   data, and 4 bytes of the pointer of the original, written as 0), then its data.
  /// </summary>
  TD3EventLoop = class
  strict private
    FSource: ID3EventSource;
    FSession: ID3CommonSession;
    FKeys: ID3KeyTracker;
    FBuffer: ICmdBuffer;
    FFiles: ID3CommonFileSystem;
    FSystem: ID3CommonSystem;
    FPrinter: ID3Printer;
    FStartup: ID3StartupVariables;
    FJournal: ID3JournalSettings;
    FFatal: ID3FatalErrorSink;
    FJournalFile: ID3CommonFile;
    FJournalDataFile: ID3CommonFile;
    FInitialTimeOffset: Integer;
    FPushedHead: Integer;
    FPushedTail: Integer;
    FPushed: array[0..D3_MAX_PUSHED_EVENTS - 1] of TD3SysEvent;
    FPrintedWarning: Boolean;
    function GetRealEvent: TD3SysEvent;
    procedure ProcessEvent(const AEvent: TD3SysEvent);
    procedure FatalJournal(const AText: AnsiString);
  public
    constructor Create(const ASource: ID3EventSource; const ASession: ID3CommonSession; const AKeys: ID3KeyTracker;
      const ABuffer: ICmdBuffer; const AFiles: ID3CommonFileSystem; const ASystem: ID3CommonSystem;
      const APrinter: ID3Printer; const AStartup: ID3StartupVariables; const AJournal: ID3JournalSettings;
      const AFatal: ID3FatalErrorSink);
    /// <summary>idEventLoop::Init: the journal files, as com_journal says; "Couldn't open journal files" otherwise</summary>
    procedure Init;
    /// <summary>idEventLoop::Shutdown: closes the journal files</summary>
    procedure Shutdown;
    /// <summary>
    ///   idEventLoop::GetEvent: a pushed event, or the real one (from the system or from the journal). It is
    ///   possible to get an event at the beginning of a frame that has a time stamp lower than the last event
    ///   from the previous frame
    /// </summary>
    function GetEvent: TD3SysEvent;
    /// <summary>idEventLoop::PushEvent: at most 64 pushed events; at the 65th the oldest is lost</summary>
    procedure PushEvent(const AEvent: TD3SysEvent);
    /// <summary>
    ///   idEventLoop::RunEventLoop: dispatches all the pending events (with ACommandExecution, the command buffer
    ///   is run before each event); the result is 0
    /// </summary>
    function RunEventLoop(const ACommandExecution: Boolean = True): Integer;
    /// <summary>idEventLoop::Milliseconds: Sys_Milliseconds minus the time of Init</summary>
    function Milliseconds: Integer;
    /// <summary>idEventLoop::JournalLevel: 1 = record, 2 = play back</summary>
    function JournalLevel: Integer;
    /// <summary>com_pushedEventsHead: the pushed events ever added</summary>
    function PushedHead: Integer;
    /// <summary>com_pushedEventsTail: the pushed events ever taken (or lost)</summary>
    function PushedTail: Integer;
  end;

implementation

type
  TJournalHeader = packed record
    EvType: Integer;
    EvValue: Integer;
    EvValue2: Integer;
    EvPtrLength: Integer;
    EvPtr: Integer;
  end;

const
  SJournalOverflow = 'WARNING: Com_PushEvent overflow' + #10;
  SJournaling = 'Journaling events' + #10;
  SReplaying = 'Replaying journaled events' + #10;
  SCouldNotOpen = 'Couldn''t open journal files' + #10;
  SJournalRead = 'Error reading from journal file';
  SJournalWrite = 'Error writing to journal file';
  SJournalFile = 'journal.dat';
  SJournalDataFile = 'journaldata.dat';
  SJournalVariable = 'journal';

constructor TD3EventLoop.Create(const ASource: ID3EventSource; const ASession: ID3CommonSession;
  const AKeys: ID3KeyTracker; const ABuffer: ICmdBuffer; const AFiles: ID3CommonFileSystem;
  const ASystem: ID3CommonSystem; const APrinter: ID3Printer; const AStartup: ID3StartupVariables;
  const AJournal: ID3JournalSettings; const AFatal: ID3FatalErrorSink);
begin
  inherited Create;
  FSource := ASource;
  FSession := ASession;
  FKeys := AKeys;
  FBuffer := ABuffer;
  FFiles := AFiles;
  FSystem := ASystem;
  FPrinter := APrinter;
  FStartup := AStartup;
  FJournal := AJournal;
  FFatal := AFatal;
end;

procedure TD3EventLoop.FatalJournal(const AText: AnsiString);
begin
  FFatal.FatalError(AText);
end;

function TD3EventLoop.GetRealEvent: TD3SysEvent;
var
  LHeader: TJournalHeader;
begin
  // either get an event from the system or the journal file
  if FJournal.JournalLevel = 2 then
  begin
    if FJournalFile.Read(LHeader, SizeOf(LHeader)) <> SizeOf(LHeader) then
      FatalJournal(SJournalRead);
    Result.EvType := LHeader.EvType;
    Result.EvValue := LHeader.EvValue;
    Result.EvValue2 := LHeader.EvValue2;
    Result.EvData := nil;
    if LHeader.EvPtrLength <> 0 then
    begin
      SetLength(Result.EvData, LHeader.EvPtrLength);
      if FJournalFile.Read(Result.EvData[0], LHeader.EvPtrLength) <> LHeader.EvPtrLength then
        FatalJournal(SJournalRead);
    end;
  end
  else
  begin
    Result := FSource.GetEvent;

    // write the journal value out if needed
    if FJournal.JournalLevel = 1 then
    begin
      LHeader.EvType := Result.EvType;
      LHeader.EvValue := Result.EvValue;
      LHeader.EvValue2 := Result.EvValue2;
      LHeader.EvPtrLength := Length(Result.EvData);
      LHeader.EvPtr := 0;
      if FJournalFile.Write(LHeader, SizeOf(LHeader)) <> SizeOf(LHeader) then
        FatalJournal(SJournalWrite);
      if Length(Result.EvData) <> 0 then
        if FJournalFile.Write(Result.EvData[0], Length(Result.EvData)) <> Length(Result.EvData) then
          FatalJournal(SJournalWrite);
    end;
  end;
end;

procedure TD3EventLoop.PushEvent(const AEvent: TD3SysEvent);
var
  LSlot: Integer;
begin
  LSlot := FPushedHead and (D3_MAX_PUSHED_EVENTS - 1);
  if FPushedHead - FPushedTail >= D3_MAX_PUSHED_EVENTS then
  begin
    // don't print the warning constantly, or it can give time for more...
    if not FPrintedWarning then
    begin
      FPrintedWarning := True;
      FPrinter.Printf(SJournalOverflow);
    end;
    Inc(FPushedTail);
  end
  else
    FPrintedWarning := False;
  FPushed[LSlot] := AEvent;
  Inc(FPushedHead);
end;

function TD3EventLoop.GetEvent: TD3SysEvent;
begin
  if FPushedHead > FPushedTail then
  begin
    Inc(FPushedTail);
    Exit(FPushed[(FPushedTail - 1) and (D3_MAX_PUSHED_EVENTS - 1)]);
  end;
  Result := GetRealEvent;
end;

procedure TD3EventLoop.ProcessEvent(const AEvent: TD3SysEvent);
var
  LLength: Integer;
  LText: AnsiString;
begin
  // track key up / down states
  if AEvent.EvType = SE_KEY then
    FKeys.PreliminaryKeyEvent(AEvent.EvValue, AEvent.EvValue2 <> 0);

  if AEvent.EvType = SE_CONSOLE then
  begin
    // from a text console outside the game window: the data is a C string
    LLength := 0;
    while (LLength < Length(AEvent.EvData)) and (AEvent.EvData[LLength] <> 0) do
      Inc(LLength);
    if LLength > 0 then
      SetString(LText, PAnsiChar(@AEvent.EvData[0]), LLength)
    else
      LText := '';
    FBuffer.BufferCommandText(ceAppend, LText);
    FBuffer.BufferCommandText(ceAppend, #10);
  end
  else
    FSession.ProcessEvent(AEvent);
end;

function TD3EventLoop.RunEventLoop(const ACommandExecution: Boolean): Integer;
var
  LEvent: TD3SysEvent;
begin
  while True do
  begin
    if ACommandExecution then
      // execute any bound commands before processing another event
      FBuffer.ExecuteCommandBuffer;

    LEvent := GetEvent;

    // if no more events are available
    if LEvent.EvType = SE_NONE then
      Exit(0);
    ProcessEvent(LEvent);
  end;
end;

procedure TD3EventLoop.Init;
begin
  FInitialTimeOffset := FSystem.Milliseconds;

  FStartup.StartupVariable(SJournalVariable, False);

  if FJournal.JournalLevel = 1 then
  begin
    FPrinter.Printf(SJournaling);
    FJournalFile := FFiles.OpenFileWrite(SJournalFile, '');
    FJournalDataFile := FFiles.OpenFileWrite(SJournalDataFile, '');
  end
  else if FJournal.JournalLevel = 2 then
  begin
    FPrinter.Printf(SReplaying);
    FJournalFile := FFiles.OpenFileRead(SJournalFile);
    FJournalDataFile := FFiles.OpenFileRead(SJournalDataFile);
  end;

  // like the original, this is also said when no journal was asked for
  if (not Assigned(FJournalFile)) or (not Assigned(FJournalDataFile)) then
  begin
    FJournal.SetJournalLevel(0);
    FJournalFile := nil;
    FJournalDataFile := nil;
    FPrinter.Printf(SCouldNotOpen);
  end;
end;

procedure TD3EventLoop.Shutdown;
begin
  if Assigned(FJournalFile) then
  begin
    FFiles.CloseFile(FJournalFile);
    FJournalFile := nil;
  end;
  if Assigned(FJournalDataFile) then
  begin
    FFiles.CloseFile(FJournalDataFile);
    FJournalDataFile := nil;
  end;
end;

function TD3EventLoop.Milliseconds: Integer;
begin
  Result := FSystem.Milliseconds - FInitialTimeOffset;
end;

function TD3EventLoop.JournalLevel: Integer;
begin
  Result := FJournal.JournalLevel;
end;

function TD3EventLoop.PushedHead: Integer;
begin
  Result := FPushedHead;
end;

function TD3EventLoop.PushedTail: Integer;
begin
  Result := FPushedTail;
end;

end.
