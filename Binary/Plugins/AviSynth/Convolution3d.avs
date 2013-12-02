LoadPlugin("{PLUGS}\convolution3d.dll") 
AVISource({SOURCE}) 
ConvertToYUY2
Convolution3d (matrix=0, ythresh=3, cthresh=4, t_ythresh=3, t_cthresh=4, influence=3, debug=0)
