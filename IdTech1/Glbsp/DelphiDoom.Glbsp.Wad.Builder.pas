{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - builds the nodes of all the levels of a WAD            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of GlbspBuildNodes of glbsp.c of glBSP 2.24                            }
{  (C) 2000-2007 Andrew Apted                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Wad.Builder;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiDoom.Glbsp.Options;

type
  /// <summary>
  ///   Raised when the WAD cannot be processed (for instance it has no levels)
  /// </summary>
  EGlbspBuildException = class(Exception);

  /// <summary>
  ///   Reads a WAD from a stream, builds the nodes of every level and writes
  ///   the result to another stream: the whole work of the glbsp program,
  ///   without files and without a separate process
  /// </summary>
  TGlbspWadBuilder = class
  private
    FOptions: TGlbspOptions;
    FMessages: TStringList;
    FTimeProvider: TFunc<string>;
  public
    constructor Create(const AOptions: TGlbspOptions);
    destructor Destroy; override;

    /// <summary>
    ///   Builds the nodes. With GwaMode the output holds only the new lumps
    ///   (a GWA file); otherwise it is the input WAD with the new lumps added.
    ///   Without LoadAll the input stream must stay valid until Build returns
    /// </summary>
    /// <returns>The number of levels that were processed</returns>
    /// <exception cref="EGlbspBuildException">no levels in the WAD</exception>
    /// <exception cref="EGlbspWadException">bad or truncated WAD</exception>
    /// <exception cref="EGlbspLevelException">the data of a level is bad</exception>
    function Build(const AInput, AOutput: TStream): Integer;

    /// <summary>Warnings of the last build, one per line</summary>
    property Messages: TStringList read FMessages;
    /// <summary>
    ///   Text of the TIME line; by default the current time. Tests fix it
    /// </summary>
    property TimeProvider: TFunc<string> read FTimeProvider write FTimeProvider;
  end;

implementation

uses
  DelphiDoom.Glbsp.Level.Processor,
  DelphiDoom.Glbsp.Wad.Document;

const
  SNoLevels = 'No levels found in wad !';

{ TGlbspWadBuilder }

constructor TGlbspWadBuilder.Create(const AOptions: TGlbspOptions);
begin
  inherited Create;
  FOptions := AOptions;
  FMessages := TStringList.Create;
end;

destructor TGlbspWadBuilder.Destroy;
begin
  FMessages.Free;
  inherited Destroy;
end;

function TGlbspWadBuilder.Build(const AInput, AOutput: TStream): Integer;
var
  LWad: TGlbspWad;
  LProcessor: TGlbspLevelProcessor;
begin
  Result := 0;
  FMessages.Clear;

  LWad := TGlbspWad.Create;
  try
    LWad.ReadFromStream(AInput, FOptions.LoadAll, FOptions.GwaMode);

    if LWad.CountLevels <= 0 then
      raise EGlbspBuildException.Create(SNoLevels);

    LProcessor := TGlbspLevelProcessor.Create(LWad, FOptions, FMessages);
    try
      LProcessor.TimeProvider := FTimeProvider;

      // Every level of the WAD
      while LWad.FindNextLevel do
      begin
        LProcessor.Process;
        Inc(Result);
      end;
    finally
      LProcessor.Free;
    end;

    // All the lumps are written to the output
    LWad.WriteToStream(AOutput);

    FMessages.AddStrings(LWad.Warnings);
  finally
    LWad.Free;
  end;
end;

end.
