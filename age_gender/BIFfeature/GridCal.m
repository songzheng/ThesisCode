function [grid_x,grid_y,grid_num]=GridCal(win_size,grid_size,grid_stride,align)
grid_num=floor((win_size-grid_size)./grid_stride)+1;
margin=win_size-(grid_num-1).*grid_stride-grid_size;

switch align
    case 'tl'
        margin_tl=[0,0];
        margin_br=margin;
    case 'm'
        margin_tl=round(margin./2.0);
        margin_br=margin-margin_tl;
    case 'br'
        margin_tl=margin;
        margin_br=[0,0];
    otherwise
        error('Wrong Alignment');
end


grid_x=margin_tl(1)+(0:grid_num(1)-1)*grid_stride(1)+1;
grid_y=margin_tl(2)+(0:grid_num(2)-1)*grid_stride(2)+1;

[grid_y,grid_x]=meshgrid(grid_y,grid_x);
grid_x=grid_x(:);
grid_y=grid_y(:);
