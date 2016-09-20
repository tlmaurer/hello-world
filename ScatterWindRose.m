function [hpol] =ScatterWindRose(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Goal: create a scatter polar plot with 2 to 3 variables as input

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% INPUT:
% varargin: 1 to 6 inputs :

% #1 Direction ; type: float ; size: [1 x N] in DEGREES
% #2 variable associated to direction (ex: speed); type: float; size: [1 x N]
% #3 limits associated to #2; type: float ; size [1x2] -> if empty variable '[]' is written, the [min(#2),max(#2)] is used
% #4 name of variable #2; type: string;
% #5 variable associated to #2 and #1; type: float; size: [1 x N]
% #6 name of variable #5; type: string;

% Syntax : [hpol] =ScatterWindRose(Dir,U,lim,)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% OUTPUT
% A figure is displayed with its handle
% hpol can be a float or a cell

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%       ------------------------------------------------------
%       ------------------------------------------------------
%                               SCRIPT
%       ------------------------------------------------------
%       ------------------------------------------------------

%                   --------------------------
%                   Affectation of variables
%                   --------------------------
% Parse possible Axes input
[cax,args,nargs] = axescheck(varargin{:});

% nargs
if nargs <= 1 || nargs > 6
    error('MATLAB:polar:InvalidInput', 'Requires 2 to 6 data arguments.')
    
    % case of 2 arguments only
    % must be wind direction and wind speed
elseif nargs == 2
    X = args{1};
    Y = args{2};
    label_Y = '';
    label_Z='';
    line_style = '+';
    Y_limits = [min(Y),max(Y)];
elseif nargs == 3
    X = args{1};
    Y = args{2};
    line_style = '+';
    if isempty(args{3}),
        Y_limits=[min(Y),max(Y)];
    else
        Y_limits = [args{3}];
    end
    label_Y = '';
    label_Z='';
    if numel(args{3})>2,
        fprintf('format of the speed limits bust be [min, max] \n')
        error('myApp:argChk', 'Wrong number of input arguments for varargin(3)')
    end
    
elseif nargs == 4
    X = args{1};
    Y = args{2};
    line_style = '+';
    if isempty(args{3}),
        Y_limits=[min(Y),max(Y)];
    else
        Y_limits = [args{3}];
    end
    label_Y = args{4};
    label_Z='';
    if numel(args{3})>2,
        fprintf('format of the speed limits bust be [min, max] \n')
        error('myApp:argChk', 'Wrong number of input arguments for varargin(3)')
    end
else % nargs >=5
    X = args{1};
    Y = args{2};
    if isempty(args{3}),
        Y_limits=[min(Y),max(Y)];
    else
        Y_limits = [args{3}];
    end
    label_Y = args{4};
    Z=args{5};
    label_Z=args{6};
    if numel(args{3})>2,
        fprintf('format of the speed limits bust be [min, max] \n')
        error('myApp:argChk', 'Wrong number of input arguments for varargin(3)')
    end
end
%%                  --------------------------
%                    Initialisation of figure
%                   --------------------------
if ischar(X) || ischar(Y)
    error('MATLAB:polar:InvalidInputType', 'Input arguments must be numeric.');
end
if ~isequal(size(X),size(Y))
    error('MATLAB:polar:InvalidInput', 'X and Y must be the same size.');
end
% get hold state
cax = newplot(cax);

if ~ishold(cax);
    
    % make a radial grid
    hold(cax,'on');
    % Get limits
    % ensure that Inf values don't enter into the limit calculation.
    Ymax = min(max(Y),Y_limits(2));
    Ymin = max(min(Y),Y_limits(1));
    subset = find(Y(:) <= Ymin | Y(:) >= Ymax);
    X(subset) = nan;
    Y(subset) = nan;
    Z(subset) = nan;
    
    %% Create circles and radius
    % define a circle
    Ncirc = 4;
    createCircles(Ncirc,Ymax,Ymin,label_Y)
    % create radius
    createRadius(Ymax,Ymin)
    % set view to 2-D
    view(cax,2);
    % set axis limits
    axis(cax,(Ymax-Ymin)*[-1 1 -1.15 1.15]);
    setappdata( cax, 'rMin', Ymin );
else
    %Try to find the inner radius of the current axis.
    if (isappdata ( cax, 'rMin' ) )
        Ymin = getappdata(cax, 'rMin' );
    else
        Ymin = 0;
    end
end
%%                  --------------------------
%                         PLOT the data
%                   --------------------------
% transform data to Cartesian coordinates.
xx = (Y - Ymin).*cosd(90-X);
yy = (Y - Ymin).*sind(90-X);
% plot data on top of grid
if nargs >=5,
    h = scatter(xx,yy,25,Z,'filled');
    c =colorbar;
    set(c,'location','NorthOutside');
    title(c,label_Z)
else
    h = plot(xx,yy,line_style,'parent',cax);
end
if nargout == 1
    hpol = h;
end

set(cax,'dataaspectratio',[1 1 1]), axis(cax,'off');
set(get(cax,'xlabel'),'visible','on')
set(get(cax,'ylabel'),'visible','on')
set(gcf,'color','w');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function createCircles(Ncirc,Ymax,Ymin,label_Y)
        theta = linspace(0,360,100);
        xunit = cosd(theta);
        yunit = sind(theta);
        cos_scale = cosd(-20);
        sin_scale = sind(-20);
        % draw radial circles
        for ii = 1:Ncirc,
            line(xunit*ii.*(Ymax-Ymin)./Ncirc,...
                yunit*ii.*(Ymax-Ymin)./Ncirc,'color','k',...
                'linestyle',':');
            if ii >= Ncirc,
                text(ii.*(Ymax-Ymin)./Ncirc.*cos_scale,...
                    ii.*(Ymax-Ymin)./Ncirc.*sin_scale, ...
                    [' ',num2str((Ymin+ii.*(Ymax-Ymin)./Ncirc),2),' ',...
                    '   ',...
                    label_Y],'verticalalignment','bottom');
            else
                text(ii.*(Ymax-Ymin)./Ncirc.*cos_scale,...
                    ii.*(Ymax-Ymin)./Ncirc.*sin_scale, ...
                    [' ',num2str((Ymin+ii.*(Ymax-Ymin)./Ncirc),2)],...
                    'verticalalignment','bottom');
            end
        end
    end
    function createRadius(Ymax,Ymin)
        % origin aligned with the NORTH
        thetaLabel = [[90,60,30],[360:-30:120]];
        theta = 0:30:360;
        cs = [-cosd(theta); cosd(theta)];
        sn = [-sind(theta); sind(theta)];
        line((Ymax-Ymin)*cs,(Ymax-Ymin)*sn,'color','k',...
            'linestyle',':')
        % annotate spokes in degrees
        rt = 1.1*(Ymax-Ymin);
        for iAngle = 1:numel(thetaLabel),
            if theta(iAngle) ==0,
                text(rt*cosd(theta(iAngle)),rt*sind(theta(iAngle)),'E',...
                    'horizontalalignment','center');
            elseif theta(iAngle) == 90,
                text(rt*cosd(theta(iAngle)),rt*sind(theta(iAngle)),'N',...
                    'horizontalalignment','center');
            elseif theta(iAngle) == 180,
                text(rt*cosd(theta(iAngle)),rt*sind(theta(iAngle)),'W',...
                    'horizontalalignment','center');
            elseif theta(iAngle) == 270,
                text(rt*cosd(theta(iAngle)),rt*sind(theta(iAngle)),'S',...
                    'horizontalalignment','center');
            else
                text(rt*cosd(theta(iAngle)),rt*sind(theta(iAngle)),int2str(abs(thetaLabel(iAngle))),...
                    'horizontalalignment','center');
            end
        end
        
    end
end