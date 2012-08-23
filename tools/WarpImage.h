
#include <math.h>

typedef unsigned char BYTE;

struct FloatPoint{
	float x;
	float y;
};

struct Image {
	BYTE * imageData;
	int width;
	int height;
	int widthStep;
    FloatPoint landmark1;
	FloatPoint landmark2;
};

struct Warp {
	Image src;
	Image dst;
    
    FloatPoint * pts_src;
    FloatPoint * pts_dst;
    int point_num;
    
};

inline void bilinear_interpolate_color(Image *src, float x_prime, float y_prime, BYTE *pixel)
{
	int x0 = (int)floor(x_prime),
		y0 = (int)floor(y_prime);

	float wx1 = x_prime - x0,
		wy1 = y_prime - y0;
	float wx0wy0 = (1 - wx1)*(1-wy1),
		wx1wy0 = wx1*(1 - wy1),
		wx0wy1 = (1 - wx1)*wy1,
		wx1wy1 = wx1*wy1;
	float v;
	const BYTE *p = src->imageData + y0*src->widthStep + x0*3;

	v = wx0wy0*(*p) + wx1wy0*(*(p+3)) + 
		wx0wy1*(*(p+src->widthStep)) + wx1wy1*(*(p+src->widthStep+3));
	pixel[0] = BYTE(v);
	p++;

	v = wx0wy0*(*p) + wx1wy0*(*(p+3)) + 
		wx0wy1*(*(p+src->widthStep)) + wx1wy1*(*(p+src->widthStep+3));
	pixel[1] = BYTE(v);
	p++;

	v = wx0wy0*(*p) + wx1wy0*(*(p+3)) + 
		wx0wy1*(*(p+src->widthStep)) + wx1wy1*(*(p+src->widthStep+3));
	pixel[2] = BYTE(v);
}

int WarpImage(Warp * wp)
{
	int w = wp->src.width;
	int h = wp->src.height;
	int w_prime = wp->dst.width;
	int h_prime = wp->dst.height;
    
    float dx = wp->src.landmark2.x - wp->src.landmark1.x;
    float dy = wp->src.landmark2.y - wp->src.landmark1.y;
    float x0 = wp->src.landmark1.x;
    float y0 = wp->src.landmark1.y;
        
    float dx_prime = wp->dst.landmark2.x - wp->dst.landmark1.x;
    float dy_prime = wp->dst.landmark2.y - wp->dst.landmark1.y;
    float x0_prime = wp->dst.landmark1.x;
    float y0_prime = wp->dst.landmark1.y;
        
    float model_from_prime = dx_prime*dx_prime+dy_prime*dy_prime;
    float tr_real_from_prime = (dx*dx_prime + dy*dy_prime)/model_from_prime;
    float tr_imag_from_prime = (-dx*dy_prime + dy*dx_prime)/model_from_prime;  
            
	for(int y_prime = 0; y_prime<h_prime; y_prime++){
		for(int x_prime = 0; x_prime<w_prime; x_prime++){
            float x2_prime = float(x_prime) - x0_prime;
            float y2_prime = float(y_prime) - y0_prime;
            
            float x = tr_real_from_prime * x2_prime - tr_imag_from_prime * y2_prime + x0;
            float y = tr_imag_from_prime * x2_prime + tr_real_from_prime * y2_prime + y0;
			
			BYTE pixel[3];
			if(x < 0 || y < 0 || x+1 >= w-1 || y+1 >= h-1){	
				pixel[0] = 0;
				pixel[1] = 0;
				pixel[2] = 0;
			}
			else{
				bilinear_interpolate_color(&wp->src, x, y, pixel);
			}

			(wp->dst.imageData + y_prime*wp->dst.widthStep)[x_prime*3] = pixel[0];
			(wp->dst.imageData + y_prime*wp->dst.widthStep)[x_prime*3+1] = pixel[1];
			(wp->dst.imageData + y_prime*wp->dst.widthStep)[x_prime*3+2] = pixel[2];
		}
	}
    
    if(wp->point_num <= 0)
        return 1;    
    
    float model_to_prime = dx*dx+dy*dy;
    float tr_real_to_prime = (dx*dx_prime + dy*dy_prime)/model_to_prime;
    float tr_imag_to_prime = (dx*dy_prime - dy*dx_prime)/model_to_prime;  
    
    for(int n=0; n<wp->point_num; n++)
    {
            float x2 = wp->pts_src[n].x - x0;
            float y2 = wp->pts_src[n].y - y0;
            
            float x2_prime = tr_real_to_prime * x2 - tr_imag_to_prime * y2 + x0_prime;
            float y2_prime = tr_imag_to_prime * x2 + tr_real_to_prime * y2 + y0_prime;
        
            wp->pts_dst[n].x = x2_prime;
            wp->pts_dst[n].y = y2_prime;
    }
	return 1;
}



