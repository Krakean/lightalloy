unit CfgPgEvents;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, ExtCtrls, StdCtrls;

type
  TCPEvents = class(TConfigPageForm)
    gbOnStart: TGroupBox;
    cbOnStartResize: TCheckBox;
    cbAlwaysPrMonitor: TCheckBox;
    gbOnOpen: TGroupBox;
    cbEvOpenHidePanels: TCheckBox;
    cbEvOpenFullScreen: TCheckBox;
    cbEvOpenResize: TCheckBox;
    cbEvOpenCenter: TCheckBox;
    rgOnPLEnd: TRadioGroup;
    cbOnMinimizePause: TCheckBox;
    cbSeekLast: TCheckBox;
    cbOnDoneRewind: TCheckBox;
    cbApplySettings: TCheckBox;
    cbRestorePlayback: TCheckBox;
    cbOnAutoSeek: TCheckBox;
    cbSearchForSimilarFiles: TCheckBox;
    procedure cbOnMinimizePauseClick(Sender: TObject);
  private
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore;

procedure TCPEvents.ApplyChanges;
begin
  with Core.Prefs do begin
   // WriteBool('OnStart.Resize',cbOnStartResize.Checked);
    WriteBool('OnStart.AlwaysPrMonitor',cbAlwaysPrMonitor.Checked);
   // WriteBool('OnStart.Center',cbOnStartCenter.Checked);
    WriteBool('OnOpen.HidePanels',cbEvOpenHidePanels.Checked);
    WriteBool('OnOpen.FullScreen',cbEvOpenFullScreen.Checked);
    WriteBool('OnOpen.Resize',cbEvOpenResize.Checked);
    WriteBool('OnOpen.Center',cbEvOpenCenter.Checked);
    WriteBool('OnOpen.AutoSeek',cbOnAutoSeek.Checked);
    WriteInteger('Playlist.OnPlayListEnd',rgOnPLEnd.ItemIndex);
    WriteBool('OnMinimize.Pause',cbOnMinimizePause.Checked);
    WriteBool('OnMinimize.RestorePlayback',cbRestorePlayback.Checked);
    WriteBool('OnOpen.SearchForSimilarFiles', cbSearchForSimilarFiles.Checked);
    WriteBool('OnOpen.SeekLastPos', cbSeekLast.Checked);
    WriteBool('OnOpen.ApplySettings', cbApplySettings.Checked);
    WriteBool('OnDone.Rewind', cbOnDoneRewind.Checked);
  end;
    if Core.Prefs.ReadBool('OnStart.Resize') <> cbOnStartResize.Checked then begin
      Core.Prefs.WriteBool('OnStart.Resize',cbOnStartResize.Checked);
      NeedReloadApp := True;
    end;
end;

procedure TCPEvents.ReadPrefs;
begin
  with Core.Prefs do begin
    cbOnStartResize.Checked:=ReadBool('OnStart.Resize');
    cbAlwaysPrMonitor.Checked:=ReadBool('OnStart.AlwaysPrMonitor');
    //cbOnStartCenter.Checked:=ReadBool('OnStart.Center');
    cbEvOpenHidePanels.Checked:=ReadBool('OnOpen.HidePanels');
    cbEvOpenFullScreen.Checked:=ReadBool('OnOpen.FullScreen');
    cbEvOpenResize.Checked:=ReadBool('OnOpen.Resize');
    cbEvOpenCenter.Checked:=ReadBool('OnOpen.Center');
    cbOnAutoSeek.Checked:= ReadBool('OnOpen.AutoSeek');
    rgOnPLEnd.ItemIndex:=ReadInteger('Playlist.OnPlayListEnd');
    cbOnMinimizePause.Checked:=ReadBool('OnMinimize.Pause');
    cbRestorePlayback.Checked:=ReadBool('OnMinimize.RestorePlayback');
    cbApplySettings.Checked:=ReadBool('OnOpen.ApplySettings');
    cbSearchForSimilarFiles.Checked := ReadBool('OnOpen.SearchForSimilarFiles');
  end;
  cbSeekLast.Checked:=INI.Bool['OnOpen.SeekLastPos'];
  cbOnDoneRewind.Checked:=INI.Bool['OnDone.Rewind'];
end;

procedure TCPEvents.UpdateLang;
begin
  gbOnStart.Caption:=' '+MS('Config.OnStart')+' ';
  cbOnStartResize.Caption:=MS('Config.OnStart.Resize');
  cbAlwaysPrMonitor.Caption:=MS('Config.OnStart.AlwaysPrMonitor');
 // cbOnStartCenter.Caption:=MS('Config.OnStart.Center');

  gbOnOpen.Caption:=' '+MS('Config.OnLoad')+' ';
  cbEvOpenResize.Caption:=MS('Config.OnLoad.Resize');
  cbEvOpenCenter.Caption:=MS('Config.OnLoad.Center');
  cbEvOpenFullScreen.Caption:=MS('Config.OnLoad.FullScreen');
  cbEvOpenHidePanels.Caption:=MS('Config.OnLoad.HidePanel');
  cbSeekLast.Caption:=MS('Config.OnLoad.SeekLastPos');
  cbApplySettings.Caption:=MS('Config.OnLoad.ApplySettings');
  cbOnAutoSeek.Caption:=MS('Config.OnLoad.OnAutoSeek');
  cbSearchForSimilarFiles.Caption:=MS('Config.OnLoad.SearchForSimilarFiles');

  cbOnDoneRewind.Caption:=MS('Config.OnDone.Rewind');

  rgOnPLEnd.Caption:=' '+MS('Config.OnPLEnd')+' ';
  rgOnPLEnd.Items[0]:=MS('Config.OnPLEnd.0');
  rgOnPLEnd.Items[1]:=MS('Config.OnPLEnd.1');
  rgOnPLEnd.Items[2]:=MS('Config.OnPLEnd.2');

  cbOnMinimizePause.Caption:=MS('Config.OnMinimize.Pause');
  cbRestorePlayback.Caption:=MS('Config.OnMinimize.RestorePlayback');
end;

procedure TCPEvents.cbOnMinimizePauseClick(Sender: TObject);
begin
  inherited;
  if cbOnMinimizePause.Checked then
    cbRestorePlayback.Enabled := Sender = cbOnMinimizePause
  else
  cbRestorePlayback.Enabled := false;
end;

end.
