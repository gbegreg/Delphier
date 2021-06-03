program Delphier;

uses
  System.StartUpCopy,
  FMX.Forms,
  FMX.Types,
  uMain in 'uMain.pas' {FormMain},
  uGame in 'uGame.pas',
  uUtils in 'uUtils.pas';

{$R *.res}

begin
  {$IFDEF MACOS}
    GlobalUseMetal := True;
  {$ENDIF}
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape];
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.

