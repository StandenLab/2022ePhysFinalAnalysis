%% ePhys Analysis Pipeline
clear
clc

pth=uigetdir("","Select the folder with your _dvProject files");
flls=dir(sprintf("%s\\*_dvProject.mat",pth));    % Digitized 10 points along the midline of the fish starting just anterior to the pectoral fins.

%Because these videos are weird and have different numbers of frames depending on where you load them in.
nframes=[849,...    %tr04
    848,...         %tr05
    869,...         %tr07
    914,...         %tr08
    791,...         %tr09
    893,...         %tr10
    813];           %tr15

%To convert px to cm (each value represents 1 cm in px)
cm=[42.70,...  %tr04
    34.56,...  %tr05
    47.368,... %tr07
    34.909,... %tr08
    33.336,... %tr09
    36.891,... %tr10
    40.043];   %tr15

for f=1:size(flls,1)
    kineProject.info.framerate=60;                                                          % video framerate
    kineProject.info.videoname=extractBefore(flls(f).name,'_dvProject.mat');                % base video name
    kineProject.info.trial=cell2mat(extractBetween(kineProject.info.videoname,'tr','_'));   % trial number
    kineProject.info.nframes=nframes(f);                                                    % number of frames in the video
    kineProject.info.px2cm=cm(f);                                                           % pixel to cm conversion factor
    
    % Add electrical stimulation parameters. freq=stimulation frequency,
    % amp=stimulation amplitude.
    switch kineProject.info.trial
        case '04'            
            kineProject.info.freq=10;
            kineProject.info.amp=16;
        case '05'
            kineProject.info.freq=14;
            kineProject.info.amp=16;
        case '07'
            kineProject.info.freq=14;
            kineProject.info.amp=17;            
        case '08'
            kineProject.info.freq=14;
            kineProject.info.amp=18;            
        case '09'
            kineProject.info.freq=14;
            kineProject.info.amp=19;            
        case '10'
            kineProject.info.freq=14;
            kineProject.info.amp=20;
        case '15'
            kineProject.info.freq=20;
            kineProject.info.amp=16;            
    end
    
    load(sprintf("%s\\%s",pth,flls(f).name))        % load current DLT points file
    xy=full(udExport.data.xypts);                   % pull out the x-y coordinates
    xy=xy(1:nframes(f),:);                          % trim the end of the x-y points so that they match the "real" (i.e. as determined in imageJ) number of frames
    xy(xy==0)=NaN;                                  % get rid of any zeros
    
    % Flip the coordinates so they lie on the video correctly
    for i=1:size(xy,1)
        xy(i,:)=flipDLThorizontal(xy(i,:),1080);
    end
    x=xy(:,1:2:end);    % separate x
    y=xy(:,2:2:end);    % separate y
    
    %Spline 101 points along the midline
    kineProject.splinemidline=SplineMidline(flls(f).name,x,y,1,0,10,101); % note that there is a weird offset of about + 2 frames between the midline data and the video. I've left it because this doesn't affect any of the calculations, but it does mean that the plotting checks here look incorrect.
        
    %Find the average shape of your fish
    meanx=mean(kineProject.splinemidline.splinex,'omitnan');
    meany=mean(kineProject.splinemidline.spliney,'omitnan');
    
    %Find the perpendicular distance to the average position of the tail
    %This is "amplitude".
    xy=[kineProject.splinemidline.splinex(:,101),kineProject.splinemidline.spliney(:,101)];
    dist=pdist2(xy,[meanx(101),meany(101)]);
    [kineProject.kineVars.tailamp,kineProject.kineVars.tailampframes]=findpeaks(dist,'MinPeakProminence',range(dist)/4);
    
    %Plot the identified tail amp frames to check
    fig=figure;
    plot(1:length(dist),dist,'k'); hold on;
    plot(kineProject.kineVars.tailampframes,dist(kineProject.kineVars.tailampframes),'ro');
    title([string(kineProject.info.videoname),"Check peaks (i.e. maximum distances from average","position) are pulled correctly.","--- Close figure to continue ---"],'Interpreter','none')
    xlabel("frame")
    ylabel("distance from average position (px)")
    uiwait(fig)
    
    clear fig
    
    fig=figure;
    plot(xy(:,1),xy(:,2),'k'); hold on;
    plot(xy(kineProject.kineVars.tailampframes,1),xy(kineProject.kineVars.tailampframes,2),'ro')
    title([string(kineProject.info.videoname),"Check that the maximum amplitudes are fulled correctly","--- Close figure to continue ---"],'Interpreter','none')
    xlabel("x coordinate (px)")
    ylabel("y coordinate (px)")
    uiwait(fig)
    
    %Find the period and frequency based on the tailampframes above
    kineProject.kineVars.tailperiod=(diff(kineProject.kineVars.tailampframes)*(1/60))*2;
    kineProject.kineVars.tailfreq=1./kineProject.kineVars.tailperiod;
    
    kineProject.kineVars.tailampcm=kineProject.kineVars.tailamp/kineProject.info.px2cm;
    
    
    save(sprintf('%s\\%s_kineProject.mat',pth,kineProject.info.videoname),'kineProject')
    
    [out]=createDataTable(kineProject.kineVars,cellstr(["tailamp","tailampcm","tailperiod","tailfreq"]),...
        'Trial',kineProject.info.trial,...
        'Treatment',kineProject.info.freq,...
        'Treatment2',kineProject.info.amp);
    if f==1
        output=out;
    else
        output=[output;out];
    end
    clearvars -except plt flls nframes f out output cm pth
end

output.Properties.VariableNames={'trial','stimF','stimA','tailamp','tailampcm','tailperiod','tailfreq'};
writetable(output,sprintf('%s\\ePhys_KineVars.csv',pth));

clear
clc
%% Make midline plots for Fig. 5
clear
clc

pth=uigetdir("","Select the folder with your _kineProject files");
cd(pth)

% Filenames
flls=["Polyp2020-024_tr04_ePhys_vid_stab_kineProject.mat",...
    "Polyp2020-024_tr05_ePhys_vid_stab_kineProject.mat",...
    "Polyp2020-024_tr15_ePhys_vid_stab_kineProject.mat",...
    "Polyp2019-059_tr11_swim_kineProject.mat"];
% Start frames for example bout
strt=[487,....
    436,...
    624,...
    1];
% End frames for example bout
nd=[585,...
    519,...
    679,...
    20];

% Shades of grey for plotting
clrs=linspace(0,220,20)/255;

% Plot each set of data
for f=1:4
    load(flls(f))                               % load kineProject file
    frs=round(linspace(strt(f),nd(f),20));      % generate plotting frames
    
    % Make the plots
    if f < 4    % for the semi-intact examples
        for i=1:length(frs)
            plot(kineProject.splinemidline.splinex(frs(i),:),kineProject.splinemidline.spliney(frs(i),:),'Color',repmat(clrs(i),[1,3])); hold on;
        end
        title("--- Close figure to continue ---")
        axis equal
    else        % for the swimming example, use rotated translated data to align as in semi-intact setup
        for i=1:length(frs)
            plot(kineProject.rotdatax(frs(i),:),kineProject.rotdatay(frs(i),:),'Color',repmat(clrs(i),[1,3])); hold on;
        end
        title("--- Close figure to continue ---")
        axis equal
    end
    uiwait
    close all
    
    clearvars -except flls strt nd clrs
end
clear
clc