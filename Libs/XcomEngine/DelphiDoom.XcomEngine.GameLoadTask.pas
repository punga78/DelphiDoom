{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the task that loads the game data while    }
{  the start screen runs (the thread of StartState::load)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.GameLoadTask;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomEngine.GameLoader.Intf;

type
  /// <summary>The phases of the loading (LoadingPhase of StartState; "done" is when the error has been shown)</summary>
  TXcomLoadStatus = (lsNotStarted, lsRunning, lsSuccessful, lsFailed);

  /// <summary>
  ///   Runs an IXcomGameLoader and tells how it is going. The way it runs (a thread, at once, never) is the decision
  ///   of the descendants; the start screen only reads the status from the thread of the game
  /// </summary>
  TXcomGameLoadTask = class abstract
  strict private
    FLoader: IXcomGameLoader;
  protected
    FResources: IXcomResources;
    FLanguage: TXcomLanguage;
    FError: string;
    /// <summary>Runs the loader and keeps what it gives or the message of its error; true if it worked</summary>
    function RunLoader: Boolean;
  public
    constructor Create(const ALoader: IXcomGameLoader);
    destructor Destroy; override;
    procedure Start; virtual; abstract;
    function Status: TXcomLoadStatus; virtual; abstract;
    /// <summary>The text of the error when the status is lsFailed</summary>
    function Error: string;
    /// <summary>
    ///   The data once the status is lsSuccessful; the caller owns them from here (the language is freed by whoever
    ///   takes it, the task forgets it)
    /// </summary>
    procedure TakeResult(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
  end;

implementation

constructor TXcomGameLoadTask.Create(const ALoader: IXcomGameLoader);
begin
  inherited Create;
  FLoader := ALoader;
end;

destructor TXcomGameLoadTask.Destroy;
begin
  FLanguage.Free;
  inherited Destroy;
end;

function TXcomGameLoadTask.RunLoader: Boolean;
begin
  try
    FLoader.Load(FResources, FLanguage);
    Result := True;
  except
    on E: Exception do
    begin
      FError := E.Message;
      Result := False;
    end;
  end;
end;

function TXcomGameLoadTask.Error: string;
begin
  Result := FError;
end;

procedure TXcomGameLoadTask.TakeResult(out AResources: IXcomResources; out ALanguage: TXcomLanguage);
begin
  AResources := FResources;
  ALanguage := FLanguage;
  FLanguage := nil;
end;

end.
