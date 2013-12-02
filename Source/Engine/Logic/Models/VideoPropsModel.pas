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
unit VideoPropsModel;

interface

uses
  NiceModels, Models, SysUtils, Types,
  
  DirectShow9, DShowHlp;

type
  TVideoPropsModel = class(TObject)
  private
    UpdateLock:Boolean;

    procedure CreateModels;
    procedure DestroyModels;

    procedure OnVideoDecoder;
    procedure OnZoom;
    procedure OnZoomX;
    procedure OnZoomY;
    procedure OnZoomReset;
  public
    Ofs,Zoom,Ratio:TPoint;

    constructor Create;
    destructor Destroy; override;

    function IsFreeProps:Boolean;
    procedure DeltaZoom(DeltaX,DeltaY:LongInt);
    procedure SetZoom(AZoom:TPoint);
    procedure GeometryChanged;
    function GetMappedRect(WndW,WndH:LongInt):TRect;
  end;

implementation

uses
  LACore, MainUnit;

constructor TVideoPropsModel.Create;
begin
  inherited Create;
  Ofs:=Point(0,0);
  Ratio:=Point(0,0);
  Zoom:=Point(100,100);
  CreateModels;
end;

procedure TVideoPropsModel.CreateModels;
begin
  with Core.MdlMgr do begin
    SetModel('App.VideoProps.Decoder',TCommandModel.Create(OnVideoDecoder));
    SetModel('App.VideoProps.ZoomX',TSInt32Model.Create(Zoom.X,OnZoomX));
    SetModel('App.VideoProps.ZoomY',TSInt32Model.Create(Zoom.Y,OnZoomY));
    SetModel('App.VideoProps.ZoomReset',TCommandModel.Create(OnZoomReset));
    SetModel('App.VideoProps.Geometry',TModel.Create(NIL));
  end;
end;

procedure TVideoPropsModel.DeltaZoom;
begin
  Inc(Zoom.X,DeltaX);
  if (Zoom.X<50) then Zoom.X:=50;
  if (Zoom.X>300) then Zoom.X:=300;

  Inc(Zoom.Y,DeltaY);
  if (Zoom.Y<50) then Zoom.Y:=50;
  if (Zoom.Y>300) then Zoom.Y:=300;

  Core.MdlMgr.SetSInt32('App.VideoProps.ZoomX',Zoom.X);
  Core.MdlMgr.SetSInt32('App.VideoProps.ZoomY',Zoom.Y);
end;

destructor TVideoPropsModel.Destroy;
begin
  DestroyModels;
  inherited Destroy;
end;

procedure TVideoPropsModel.DestroyModels;
begin
  with Core.MdlMgr do begin
    DestroyModel('App.VideoProps.Geometry');
    DestroyModel('App.VideoProps.ZoomReset');
    DestroyModel('App.VideoProps.ZoomY');
    DestroyModel('App.VideoProps.ZoomX');
    DestroyModel('App.VideoProps.Decoder');
  end;
end;

procedure TVideoPropsModel.GeometryChanged;
begin
  with Core.MdlMgr do begin
    DestroyModel('App.VideoProps.Geometry');
    SetModel('App.VideoProps.Geometry',TModel.Create(NIL));
  end;
end;

function TVideoPropsModel.GetMappedRect;
var
  Rx,Ry,ZoomX,ZoomY:Double;
  L,T,W,H,WZ,HZ:LongInt;
  VideoW,VideoH:LongInt;
  ByWidth,ByHeight:Boolean;
begin
  Result:=Rect(0,0,0,0);
  if not(Assigned(DSH)) then Exit;
  if (WndH=0) or (WndW=0) then Exit;

  ZoomX:=Zoom.X/100;
  ZoomY:=Zoom.Y/100;
  VideoW:=DSH.VideoWidth;
  VideoH:=DSH.VideoHeight;

  if (Ratio.X>=0) and (Ratio.Y>=0) then
    ZoomX:=ZoomY;
  if (Ratio.X>0) and (Ratio.Y>0) then
    VideoH:=Round(VideoW*Ratio.Y/Ratio.X);

  Rx:=VideoW/WndW;
  Ry:=VideoH/WndH;
  ByWidth:=(Ratio.X=0) and (Ratio.Y=1);
  ByHeight:=(Ratio.X=1) and (Ratio.Y=0);
  if ((Rx<Ry) or ByWidth) and not(ByHeight) then begin
    T:=0;
    H:=WndH;
    W:=Round(VideoW/Ry);
    L:=(WndW-W) div 2;
  end else begin
    L:=0;
    W:=WndW;
    H:=Round(VideoH/Rx);
    T:=(WndH-H) div 2;
  end;

  WZ:=Round(ZoomX*W);
  HZ:=Round(ZoomY*H);
  L:=L-((WZ-W) div 2);
  T:=T-((HZ-H) div 2);
  W:=WZ;
  H:=HZ;
  L:=L+Ofs.X;
  T:=T+Ofs.Y;

  Result:=Rect(L,T,L+W,T+H);
end;

function TVideoPropsModel.IsFreeProps;
begin
  Result:=(Ratio.X=-1) and (Ratio.X=-1);
end;

procedure TVideoPropsModel.OnVideoDecoder;
var
  Filter:IBaseFilter;
begin
  Filter:=DSH.GetVideoDecoder;
  if Assigned(Filter) then
    DSH.FilterProperties(frMain.Handle,Filter);
  Filter:=NIL;
end;

procedure TVideoPropsModel.OnZoom;
begin
  DeltaZoom(0,0);
  GeometryChanged;
end;

procedure TVideoPropsModel.OnZoomReset;
begin
  Core.MdlMgr.SetSInt32('App.VideoProps.ZoomX',100);
  Core.MdlMgr.SetSInt32('App.VideoProps.ZoomY',100);
end;

procedure TVideoPropsModel.OnZoomX;
begin
  if UpdateLock then Exit;
  UpdateLock:=TRUE;

  Zoom.X:=Core.MdlMgr.GetSInt32('App.VideoProps.ZoomX');
  if not(IsFreeProps) then begin
    Zoom.Y:=Zoom.X;
    Core.MdlMgr.SetSInt32('App.VideoProps.ZoomY',Zoom.Y);
  end;
  OnZoom;
  UpdateLock:=FALSE;
end;

procedure TVideoPropsModel.OnZoomY;
begin
  if UpdateLock then Exit;
  UpdateLock:=TRUE;

  Zoom.Y:=Core.MdlMgr.GetSInt32('App.VideoProps.ZoomY');
  if not(IsFreeProps) then begin
    Zoom.X:=Zoom.Y;
    Core.MdlMgr.SetSInt32('App.VideoProps.ZoomX',Zoom.X);
  end;
  OnZoom;
  UpdateLock:=FALSE;
end;

procedure TVideoPropsModel.SetZoom(AZoom: TPoint);
begin
  DeltaZoom(-1000,-1000);
  DeltaZoom(AZoom.X-50,AZoom.Y-50);
end;

end.
