program Sit;

uses
  Forms,
  SitMain in 'SitMain.pas' {Main},
  SitInfo in 'SitInfo.pas' {Info},
  SitAPI in 'SitAPI.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'SIT';
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
