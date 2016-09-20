function compare_monthly_ndbc(months,years,varargin)
%----------------------------------------------------
% compare_monthly_ndbc.m
%----------------------------------------------------
% 
% Grabs data from the National Data Buoy Center website for station
% 46042, specified months and years.  Generates monthly day-of-year time series 
% (for wind speed and water temp) and wind-rose plots for comparing conditions across years.
% 
%
% USE AS:  compare_monthly_ndbc(3:5,2010:2015,'D:\images');
% INPUTS:  months      = vector including months of interest 
%          years       = vector including years of interest 
%        ((image_dir)) = ((optional)) output directory, if interested in saving images.
%        
% OUTPUTS: Monthly time-series plots (of wspd and wtemp), and monthly windrose plots, comparing specified years     
%
% AUTHOR: Tanya Maurer
% DATE: 05/11/2016
% REQUIRED: nanmin.m; nanmax.m
%           myfig.m
%           ScatterWindRose.M
%           image processing toolbox (for saving images).
% UPDATES: 6/7/2016 added wind rose plot and function capability.
% NOTES: Input months and years do not need to be sequential.
%        Include trailing backslash for image_dir.
% ---------------------------------------------------- 

%%
% BEGIN

numvarargs = length(varargin);
if numvarargs > 1;
    error('Too many input arguments.');
end

station = '46042';
themonths{1} = '1';
themonths{2} = '2';
themonths{3} = '3';
themonths{4} = '4';
themonths{5} = '5';
themonths{6} = '6';
themonths{7} = 'Jul';
themonths{8} = 'Aug';
themonths{9} = 'Sep';
themonths{10} = 'Oct';
themonths{11} = 'Nov';
themonths{12} = 'Dec';

d = datevec(date);
currentYear = d(1);
currentMonth = d(2);

% DEFINE COLORS.  Each year plotted as different color.
yl = length(years);
mycolors=hsv(yl); 
ml = length(months);

%%
% BEGIN LOOPS.
for i = 1:ml;  % Loop through months of interest
    MO = months(i);
    disp(['Processing data from NDBC buoy ',station,' for month of ',themonths{MO},','])
    H1 = myfig(0.15,0.08,0.6,0.7);
    H2 = myfig(0.15,0.08,0.6,0.7);
    k = 1; %index for plot colors
    for j = 1:yl; % Loop through years of interest
        YR = years(j);
        disp([num2str(YR),'...'])
        
        %GET DATA.  URLs for months in current year vary from more
        % historical data.
        if YR == currentYear;
            URL = ['http://www.ndbc.noaa.gov/view_text_file.php?filename=',station,num2str(MO),num2str(YR),'.txt.gz&dir=data/stdmet/',themonths{months(i)},'/'];
            if MO == currentMonth-1;
                URL = ['http://www.ndbc.noaa.gov/data/stdmet/',themonths{months(i)},'/46042.txt'];
            end
        else
            URL = ['http://www.ndbc.noaa.gov/view_text_file.php?filename=',station,'h',num2str(YR),'.txt.gz&dir=data/historical/stdmet/'];
        end
        
        try
            data = urlread(URL);
        catch
            warning(['Bad URL. No data exists for ',themonths{months(i)},', ',num2str(YR),'. Skipping to next year.']);
            continue
        end
        
        %PARSE DATA
        %RESOLVE HISTORICAL CHANGES TO HEADER FORMAT
        a=strfind(data,'ft');
        if isempty(a);
            a=strfind(data,'TIDE');
            if isempty(a);
                a=strfind(data,'VIS');
                ind = a+3;
            end
            ind=a+4;
        else
            ind=a+2;
        end

        %RESOLVE HISTORICAL CHANGES TO DATA FORMAT.
        DATA = str2num(data(ind:end));
        if ~isempty(DATA); % DATA for year is populated.
            if size(DATA,2)==16;
                yy = DATA(:,1)+1900;
            else
                yy = DATA(:,1);
            end
            mo = DATA(:,2);
            dy = DATA(:,3);
            hr = DATA(:,4);
            if size(DATA,2)<18;
                mn = zeros(length(yy),1);
                WDIR = DATA(:,5);
                WSPD = DATA(:,6);
                WTMP = DATA(:,14);
            else
                mn = DATA(:,5);
                WDIR = DATA(:,6);
                WSPD = DATA(:,7);
                WTMP = DATA(:,15);
            end
            WSPD(WSPD>50)=nan; % A couple of gross quality checks.
            WTMP(WTMP>40)=nan;
            s = zeros(length(yy),1);

            %CREATE MASTER OB ARRAY.
            D = [datenum(yy,mo,dy,hr,mn,s) WSPD WDIR WTMP]; 

            %ORGANIZE DATA INTO MONTHLY CELL ARRAYS.
            numdays = [31 28 31 30 31 30 31 31 30 31 30 31]; %number of days in each month
            MONTH=cell(12,1);
            for mi = 1:12;
                MONTH{mi} = find(D(:,1)>=datenum(YR,mi,1) & D(:,1)<=datenum(YR,mi,numdays(mi)));
            end
            x=MONTH{MO};
            if ~isempty(x); % Data for month is populated.
                mo_tag = themonths{MO};
                d = D(x,:);
                d(:,1)=d(:,1)-datenum(YR,0,0); % Convert to Day Of Year for plotting

                %CREATE PLOTS
                figure(H1)
                subplot(2,1,1)
                hold on
                p{k} = plot(d(:,1),d(:,2).*1.944,'color',mycolors(k,:));
                ylabel('WSPD (knts)','fontsize',18)
                xlabel('Day of Year','fontsize',18)
                subplot(2,1,2)
                hold on
                plot(d(:,1),d(:,4),'color',mycolors(k,:))
                ylabel('SST (C)','fontsize',18)
                xlabel('Day of Year','fontsize',18)
                figure(H2)
                h{k} = ScatterWindRose(d(:,3),d(:,2).*1.944,[nanmin(D(:,2))*1.944,nanmax(D(:,2))*1.944],'KNTS');
                set(h{k},'Marker','o','markerfacecolor',mycolors(k,:))
                hold on
                set(h{k},'color',mycolors(k,:))
                leg{k} = num2str(YR);
                k=k+1;
            else
                disp(['No Data for ',themonths{MO},' ,',num2str(YR),'.'])
            end % end if << Data for month is populated. >>
        else
            disp(['Format Error, skipping data for Year',num2str(YR),'.'])
        end % end if << DATA for year is populated. >>
    end  % end for << Loop through years of interest. >>
    
    % FINALIZE AND SAVE IMAGES.
    figure(H1)
    subplot(2,1,1)
    legend([p{:}],leg)
    title(['NDBC Station ',station,' in ',mo_tag],'fontsize',20)
    figure(H2)
    title(['NDBC Station ',station,' Winds in ',mo_tag],'fontsize',18)
    set(gcf,'color','w');
    legend([h{:}],leg,'location','NorthEastOutside');
    if numvarargs>0;
        I=getframe(H1);
        imwrite(I.cdata,[varargin{1},'NDBC_46042_',mo_tag,'.png'],'xresolution',1500,'yresolution',1500)
        I=getframe(H2);
        imwrite(I.cdata,[varargin{1},'NDBC_46042_WINDROSE_',mo_tag,'.png'],'xresolution',1500,'yresolution',1500)
    end
end % end for << Loop through months of interest. >>

%%
% END

