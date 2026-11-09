{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the loading in a worker thread             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ThreadLoadTask;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, DelphiDoom.XcomEngine.GameLoader.Intf, DelphiDoom.XcomEngine.GameLoadTask;

type
  /// <summary>
  ///   Loads in a thread of its own (SDL_CreateThread of StartState::init). The status is a number that the thread
  ///   writes once at the end, so reading it from the game thread is safe; the thread is waited for in the destructor
  ///   (SDL_KillThread of the C++ is not available: the loading is let to finish)
  /// </summary>
  TXcomThreadLoadTask = class(TXcomGameLoadTask)
  strict private
    FThread: TThread;
    FStatus: Integer;
  public
    constructor Create(const ALoader: IXcomGameLoader);
    destructor Destroy; override;
    procedure Start; override;
    function Status: TXcomLoadStatus; override;
  end;

implementation

constructor TXcomThreadLoadTask.Create(const ALoader: IXcomGameLoader);
begin
  inherited Create(ALoader);
  FStatus := Ord(lsNotStarted);
end;

destructor TXcomThreadLoadTask.Destroy;
begin
  if Assigned(FThread) then
  begin
    FThread.WaitFor;
    FThread.Free;
  end;
  inherited Destroy;
end;

procedure TXcomThreadLoadTask.Start;
begin
  if Assigned(FThread) then
    Exit;
  FStatus := Ord(lsRunning);
  FThread := TThread.CreateAnonymousThread(
    procedure
    begin
      if RunLoader then
        TInterlocked.Exchange(FStatus, Ord(lsSuccessful))
      else
        TInterlocked.Exchange(FStatus, Ord(lsFailed));
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

function TXcomThreadLoadTask.Status: TXcomLoadStatus;
begin
  Result := TXcomLoadStatus(TInterlocked.CompareExchange(FStatus, 0, 0));
end;

end.
