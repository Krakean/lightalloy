///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// xx.xx.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////

unit OptiBtn;

interface

uses
  Windows, Classes, SysUtils, Controls, ExtCtrls, Graphics,
  OptiRes, OptiImage, OptiCtl, OptiWrapper, NICE;

type
  TOptiButton = class(TOptiControl)
  private
    procedure OnModelAppears;
    procedure TestHint(S1,S2:String);
  protected
    arBG:TOptiArea;
    ORes:TOptiResource;
    Pressed:Boolean;

    procedure Paint; override;
    procedure OnHoverChanged; override;
    procedure MouseDown(Button:TMouseButton;Shift:TShiftState;X,Y:LongInt); override;
    procedure MouseUp(Button:TMouseButton;Shift:TShiftState;X,Y:LongInt); override;
  public
    Mdl:TModel;
    Cmd:String;

    procedure ChooseHint;

    constructor Create(AOwner:TComponent); override;
    destructor Destroy; override;
  end;

  TOptiButtonWrapper = class(TOptiWrapper)
  private
    OB:TOptiButton;
  public
    procedure Load; override;
  end;

implementation

uses
  LACore, CmdC, BasicModelMgr;

var
  Cntr:TCommandCenter;

procedure TOptiButton.ChooseHint;
begin
  TestHint('App.About','Command.452');
  TestHint('App.Minimize','Command.205');
  TestHint('App.Maximize','Command.202');
  TestHint('App.StayOnTop','Command.204');
  TestHint('App.SuperPlay','Command.102');
  TestHint('App.Prefs','Command.450');
  TestHint('App.Exit','Command.453');

  TestHint('Window.FullScreen','Command.202');
  TestHint('Window.Original','Command.203');
  TestHint('Window.PlayList','Command.201');

  TestHint('Application.Scheduler','Command.458');
  TestHint('Application.Hibernate','Command.455');
  TestHint('Application.MonitorOff','Command.456');
  TestHint('Application.PowerOff','Command.454');

  TestHint('File.PlayDVD','Command.500');
  TestHint('File.OpenDVD','Command.502');
  TestHint('File.OSDInfo','Command.052');

  TestHint('Playback.Play','Command.101');
  TestHint('Playback.Stop','Command.105');
  TestHint('Playback.RealStop','Command.100');

  TestHint('Player.FrameStep','Command.150');
  TestHint('Player.SpeedPlay','Command.103');
  TestHint('Player.ScreenShot','Command.301');

  TestHint('PlayList.OpenFiles','Command.050');
  TestHint('PlayList.Next','Command.250');
  TestHint('PlayList.Prev','Command.251');

  TestHint('Audio.Mute','Command.403');
  TestHint('Sound.Switch','Command.405');
  TestHint('Video.ScreenshotCB','Command.321');

  TestHint('Seek.SetBookmark','Command.157');
  TestHint('Seek.SetOE','Command.158');  

  TestHint('Window.AudioProps','Command.400');
  TestHint('Window.VideoProps','Command.300');
  TestHint('Window.SubProps','Command.352');
  TestHint('Window.Filters','Command.104');
  TestHint('Window.FileInfo','Command.051');

  TestHint('PList.Play','Command.252');
  TestHint('PList.AddFiles','Command.253');
  TestHint('PList.Remove','Command.255');
  TestHint('PList.MoveUp','Command.258');
  TestHint('PList.Shuffle','Command.260');
  TestHint('PList.VisShuffle','Command.269');
  TestHint('PList.ShowMarks','Command.264');

  TestHint('PList.Repeat','Command.263');
  TestHint('PList.AddDir','Command.254');
  TestHint('PList.Clear','Command.256');
  TestHint('PList.MoveDown','Command.259');
  TestHint('PList.Sort','Command.261');
  TestHint('PList.Report','Command.262');
  TestHint('PList.Save','Command.257');

  TestHint('PList.Jump','Command.265');
  TestHint('PList.Search','Command.266');

  TestHint('Subtitles.Switch','Command.357');
end;

constructor TOptiButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParentBackground:=FALSE;
  DoubleBuffered:=TRUE;
  BevelOuter:=bvNone;
  Cntr:=TCommandCenter.Create;
end;

destructor TOptiButton.Destroy;
begin
  if (Cmd<>'') then begin
    if (Mdl<>NIL) then
      Mdl.Detach(Invalidate);
    Core.MdlMgr.Detach(Cmd,OnModelAppears);
  end;

  inherited Destroy;
end;

procedure TOptiButton.MouseDown;
begin
  inherited MouseDown(Button,Shift,X,Y);
  Pressed:=TRUE;
  Invalidate;
end;

procedure TOptiButton.MouseUp;
begin
  inherited MouseUp(Button,Shift,X,Y);
  Pressed:=FALSE;
  Invalidate;
  Core.MdlMgr.Execute(Cmd);
end;

procedure TOptiButton.OnHoverChanged;
begin
  Invalidate;
end;

procedure TOptiButton.OnModelAppears;
begin
  if (Mdl=NIL) then begin
    Mdl:=Core.MdlMgr.GetModel(Cmd);
    if (Mdl<>NIL) then
      Mdl.Attach(Invalidate);
    Invalidate;
  end;
end;

procedure TOptiButton.Paint;
var
  SR,DR:TRect;
  dy:LongInt;
begin
  inherited Paint;

  DR:=Rect(0,0,Width,Height);
  SR:=Rect(0,0,Width,Height);

  dy:=(Height+1);
  OffsetRect(SR,arBG.SR.Left,arBG.SR.Top+(dy*Ord(Hovered))+(dy*Ord(Pressed)));

  if (Mdl is TSInt32Model) then begin
    if ((Mdl as TSInt32Model).get_SInt32>0) then
      OffsetRect(SR,Width+1,0);
  end;

  Canvas.CopyRect(DR,arBG.BMP.Canvas,SR);
end;

{ TOptiButtonWrapper }

procedure TOptiButtonWrapper.Load;
var
  S:String;
begin
  OB:=TOptiButton.Create(ParCtl);
  OB.Parent:=ParCtl;
  Ctl:=OB;

  S:=Node.Attr('img');
  if (S<>'') then
    OB.arBG:=ORes.GetArea(S);

  ApplyPos;

  OB.Cmd:=Node.Attr('link');
  if (OB.Cmd<>'') then begin
    Core.MdlMgr.Attach(OB.Cmd,OB.OnModelAppears);
    OB.OnModelAppears;
    OB.ChooseHint;
  end;
end;

procedure TOptiButton.TestHint(S1, S2: String);
var
  K: string;
  T: string;
begin
  if Cntr<>nil then
    K:=Cntr.GetCommandKey(StrToInt(Copy(S2,Pos('.',S2)+1,3)));
  if SameText(Cmd,S1) then begin
    T:=MS(S2);
    if K<>'' then
      Hint:=T+' ('+K+')'
    else
      Hint:=T;
  end;
end;

end.
