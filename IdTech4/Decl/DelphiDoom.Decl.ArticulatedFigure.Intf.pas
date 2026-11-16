{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - interfaces of the "articulatedFigure"     }
{  declaration                                                                 }
{                                                                              }
{  Written for DelphiDoom (the shape of the data follows framework\DeclAF.h    }
{  of Doom 3).                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.Intf;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Decl.ArticulatedFigure.Types;

type
  /// <summary>
  ///   What <c>Finish</c> asks of the model the figure is for: the place of a joint. It replaces the function
  ///   pointer <c>getJointTransform_t</c> with its model and frame of joints.
  /// </summary>
  IAfJointResolver = interface
    ['{7B1D2C44-3A6E-4F0B-8C1A-5D2E9A4B7C01}']
    /// <summary>False if the model has no joint with that name</summary>
    function GetJointTransform(const AJointName: AnsiString; out AOrigin: TIdVec3; out AAxis: TIdMat3): Boolean;
  end;

  /// <summary>The data of an articulated figure (idDeclAF): settings, bodies and constraints; lists are copies</summary>
  IDeclArticulatedFigure = interface
    ['{7B1D2C44-3A6E-4F0B-8C1A-5D2E9A4B7C02}']
    function GetSettings: TAfSettings;
    procedure SetSettings(const ASettings: TAfSettings);
    function GetNumBodies: Integer;
    /// <summary>A copy of the body; an <c>EDeclArticulatedFigureException</c> when out of range</summary>
    function GetBody(const AIndex: Integer): TAfBody;
    procedure SetBody(const AIndex: Integer; const ABody: TAfBody);
    function GetNumConstraints: Integer;
    function GetConstraint(const AIndex: Integer): TAfConstraint;
    procedure SetConstraint(const AIndex: Integer; const AConstraint: TAfConstraint);
    /// <summary>
    ///   idDeclAF::Finish: gives every vector given by joints its value (the vectors of the bodies and the anchors,
    ///   shafts, axes and limit axes of the constraints). A joint the model does not have is a warning and a zero vector.
    /// </summary>
    procedure Finish(const AResolver: IAfJointResolver);
  end;

  /// <summary>What the figure editor of the original does with an <c>idDeclAF</c></summary>
  IDeclArticulatedFigureEditor = interface
    ['{7B1D2C44-3A6E-4F0B-8C1A-5D2E9A4B7C03}']
    procedure NewBody(const AName: AnsiString);
    /// <summary>Renames the body and the references of the constraints to it</summary>
    procedure RenameBody(const AOldName, ANewName: AnsiString);
    /// <summary>Deletes the body and the constraints that use it</summary>
    procedure DeleteBody(const AName: AnsiString);
    procedure NewConstraint(const AName: AnsiString);
    procedure RenameConstraint(const AOldName, ANewName: AnsiString);
    procedure DeleteConstraint(const AName: AnsiString);
    /// <summary>idDeclAF::RebuildTextSource: the text the editor writes; it is also the text of the declaration</summary>
    function RebuildTextSource: AnsiString;
    /// <summary>Rebuilds the text, replaces it in the source file and clears <c>Modified</c></summary>
    function Save: Boolean;
  end;

implementation

end.
