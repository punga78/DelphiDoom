{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - the parts of idCommon                     }
{                                                                              }
{  Port of Doom 3 (id Software): framework\Common.cpp, EventLoop.cpp.          }
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
unit DelphiDoom.D3Host.Common;

interface

uses
  DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Printer, DelphiDoom.D3Host.Diagnostics, DelphiDoom.D3Host.ErrorHandler,
  DelphiDoom.D3Host.CommandLine, DelphiDoom.D3Host.EventLoop;

type
  /// <summary>
  ///   What the factory built: the pieces of idCommonLocal that exist without a session or a renderer. The
  ///   object owns them all; the ones that implement an interface (the printer, the error handler, the command
  ///   line) are reference counted and are held through it, so use them only while this object lives.
  /// </summary>
  TD3CommonHost = class
  strict private
    FState: TD3CommonState;
    FPrinter: TD3Printer;
    FDiagnostics: TD3Diagnostics;
    FErrors: TD3ErrorHandler;
    FCommandLine: TD3CommandLine;
    FEventLoop: TD3EventLoop;
    FPrinterRef: IInterface;
    FErrorsRef: IInterface;
    FCommandLineRef: IInterface;
  public
    constructor Create(const AState: TD3CommonState; const APrinter: TD3Printer; const ADiagnostics: TD3Diagnostics;
      const AErrors: TD3ErrorHandler; const ACommandLine: TD3CommandLine; const AEventLoop: TD3EventLoop);
    destructor Destroy; override;
    property State: TD3CommonState read FState;
    property Printer: TD3Printer read FPrinter;
    property Diagnostics: TD3Diagnostics read FDiagnostics;
    property Errors: TD3ErrorHandler read FErrors;
    property CommandLine: TD3CommandLine read FCommandLine;
    property EventLoop: TD3EventLoop read FEventLoop;
  end;

implementation

constructor TD3CommonHost.Create(const AState: TD3CommonState; const APrinter: TD3Printer;
  const ADiagnostics: TD3Diagnostics; const AErrors: TD3ErrorHandler; const ACommandLine: TD3CommandLine;
  const AEventLoop: TD3EventLoop);
begin
  inherited Create;
  FState := AState;
  FPrinter := APrinter;
  FDiagnostics := ADiagnostics;
  FErrors := AErrors;
  FCommandLine := ACommandLine;
  FEventLoop := AEventLoop;
  // the reference counted classes live as long as this object
  FPrinterRef := FPrinter as IInterface;
  FErrorsRef := FErrors as IInterface;
  FCommandLineRef := FCommandLine as IInterface;
end;

destructor TD3CommonHost.Destroy;
begin
  FEventLoop.Free;
  FCommandLineRef := nil;
  FErrorsRef := nil;
  FDiagnostics.Free;
  FPrinterRef := nil;
  FState.Free;
  inherited Destroy;
end;

end.
