function imLabel( labels, position, S, pvPairs )
% Improved method for labeling figure axes.
%
% USAGE
%  imLabel( labels, position, [S], [pvPairs] )
%
% INPUTS
%  labels          - cell array of strings, labels for display
%  position        - 'left', 'right', 'bottom', or 'top'
%  S               - [] rotation for top and bottom labels in [-90,90]
%  pvPairs         - [] parameter / value list for text
%
% OUTPUTS
%
% EXAMPLE
%  load( 'images.mat' ); clf; cla; montage2( images(:,:,1:9) );
%  imLabel( {'row1','row2','row3'}, 'left',[],{'FontSize',20} );
%  imLabel( {'col1','col2','col3'}, 'bottom', -25, {'FontSize',20} );
%
% See also MONTAGE2, TEXT2, TEXT
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

if( nargin<3 || isempty(S) ); S=0; end
if( nargin<4 || isempty(pvPairs) ); pvPairs={}; end
if( abs(S)>90 ); error( 'slant must be between -90 and 90'); end

%%% set up for ydir reversed, xdir normal :)
ys = ylim; nys=ys(2)-ys(1);
xs = xlim; nxs=xs(2)-xs(1);
if(strcmp(get(gca,'YDir'),'reverse')); ys=ys([2 1]); nys=-nys; end
if(strcmp(get(gca,'XDir'),'reverse')); xs=xs([2 1]); nxs=-nxs; end

%%% write labels
nlabels = length( labels );
switch position
    case 'bottom'
        set(gca,'XTick',[]); %tick interfere
        if(abs(S)<=15)
            H='center'; V='top';
        elseif( S>15 && S<50 )
            H='right'; V='top';
        elseif( S>=50 )
            H='right'; V='middle';
        elseif( S<-15 && S>-50 )
            H='left'; V='top';
        elseif( S<=-50 )
            H='left'; V='middle';
        end;
        txtAlign ={'VerticalAlignment',V,'HorizontalAlignment',H,'Rotation',S};
        yloc = ys(1);
        for i=1:nlabels
            xloc = xs(1) + (2*i-1)/(2*nlabels)*nxs;
            text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
        end;
        
    case 'top'
        title(''); %title interfere
        if(abs(S)<=15)
            H='center'; V='bottom';
        elseif( S>15 && S<50 )
            H='left'; V='bottom';
        elseif( S>=50 )
            H='left'; V='middle';
        elseif( S<-15 && S>-50 )
            H='right'; V='bottom';
        elseif( S<=-50 )
            H='right'; V='middle';
        end;
        txtAlign ={'VerticalAlignment',V,'HorizontalAlignment',H,'Rotation',S};
        txtAlign = {txtAlign{:}, 'Rotation',S}; %rotate
        yloc = ys(2) + nys/40;
        for i=1:nlabels
            xloc = xs(1) + (2*i-1)/(2*nlabels)*nxs;
            text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
        end;
        
    case 'left'
        set(gca,'YTick',[]); %ticks interfere
        txtAlign ={'VerticalAlignment','middle','HorizontalAlignment','right'};
        xloc = xs(1) - nxs/20;
        for i=1:nlabels
            yloc = ys(2) - (2*i-1)/(2*nlabels)*nys;
            text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
        end;
        
    case 'right'
        colorbar off; % colorbar interferes
        txtAlign = {'VerticalAlignment','middle','HorizontalAlignment','left'};
        xloc = xs(2) + nxs/20;
        for i=1:nlabels
            yloc = ys(2) - (2*i-1)/(2*nlabels)*nys;
            text2( xloc,yloc,labels{i},txtAlign{:},pvPairs{:});
        end;
        
    otherwise
        error(['illegal position: ' position]);
end

function varargout = text2( varargin )
% Wrapper for text.m that ensures displayed text fits in figure.
%
% When text is called, Matlab displays the text, but does nothing to ensure
% that all of the text fits in the figure.  This function, after calling
% text, shrinks the axes until the text is fully visible.  Note that since
% font doesn't resize as the figure does, just because the text fully fits
% after text2 is called, no guaranties are made after the figure is
% resized.  Hence it is a good idea to resize the figure appropriately
% before calling text2.
%
% Same input/output options as Matlab's text.m command.
%
% USAGE
%  varargout = text2( varargin )
%
% INPUTS
%  varargin   - input to Matlab's text
%
% OUTPUTS
%  varargout  - output to Matlab's text
%
% EXAMPLE
%  figure(1); clf; text( -1 , 2, 'hello world' )  % will not appear
%  figure(2); clf; text2( -1 , 2, 'hello world' ) % will appear
%
% See also TEXT, IMLABEL
%
% Piotr's Image&Video Toolbox      Version 2.0
% Copyright 2008 Piotr Dollar.  [pdollar-at-caltech.edu]
% Please email me if you find bugs, or have suggestions or questions!
% Licensed under the Lesser GPL [see external/lgpl.txt]

%%% call text normally
error(nargoutchk(0,1,nargout));
hs = text( varargin{:} );
if(nargout==1); varargout={hs}; end;

%%% now make sure text fits
%%% update the OuterPosition (not regular Position) so good resize behavior
nhs = length(hs);
for i=1:nhs;  set(hs(i),'Units','Normalized');  end;
oldunits = get(gca,'Units'); set(gca,'Units','Normalized');
opos = get(gca,'OuterPosition'); %x y w h
updated = 1; updatedpos=1;
while( updated ); updated=0;
  for p=1:4
    if( updatedpos ); updatedpos=0;
      % get overall pos of text in normalized AXIS coordinates
      pos = [inf inf -inf -inf]; % [l b r t]
      for i=1:nhs
        extent = get(hs(i),'Extent'); % slow [l b w h]
        pos(1:2) = min( pos(1:2), extent(1:2) );
        pos(3:4) = max( pos(3:4), extent(1:2) + extent(3:4) );
      end;
      pos = pos * 1.05;
      pos(3:4) = pos(3:4) - pos(1:2);  % [l b w h]

      % convert pos to normalized FIGURE coordinates
      % must move origin, and also account for scaling
      axisPos = get(gca,'Position');
      pos(1) = axisPos(1) + pos(1) * axisPos(3);
      pos(2) = axisPos(2) + pos(2) * axisPos(4);
      pos(3) = pos(3) * axisPos(3);
      pos(4) = pos(4) * axisPos(4);
    end

    % if necessary, move OuterPosition of axes accordingly
    if( p<=2 && pos(p)<0 )
      step = min(.1,max(.001,-pos(p)/50));
      opos(p) = opos(p)+step;
      opos(p+2) = opos(p+2)-step;
      set(gca,'OuterPosition',opos);
      updated=1; updatedpos=1;
    elseif( p>2 && (pos(p-2)+pos(p))>1 )
      step = min(.1,max(.001,pos(p)/50));
      opos(p)=opos(p)-step;
      set(gca,'OuterPosition',opos);
      updated=1; updatedpos=1;
    end
  end
end
set(gca,'Units',oldunits);

%   if necessary, move OuterPosition of axes accordingly
%   if(p<=2 && pos(p)<0 )
%       step = max(.01,abs(pos(p))/1.5);
%       opos, step, pos, p
%       opos(p)=opos(p)+step;
%       opos(p+2)=opos(p+2)-step;
%       updated=1; updatedpos=1;
%       set(gca,'OuterPosition',opos);
%   elseif( p>2 && pos(p)>1 )
%       step = max(.01,(pos(p)-1)/1.5);
%       opos(p)=opos(p)-step;
%       updated=1; updatedpos=1;
%       set(gca,'OuterPosition',opos);
%   end
