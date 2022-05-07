%SplineMidline(filename,xfull,yfull,step,plt,nframes,npts)
%
%This function takes points along the midline of the fish, splines a line
%along said points and then subsamples npts evenly spaced points along that
%line. Note that you always want n+1 points (i.e. if you want 100 pts plus
%the head and tail spaced evenly along the fish you actually need npts =
%101).  :)  
%
%INPUTS
%filename: filename to find your video file (.avi).
%xfull: x-coordinates for your points along the midline of the animal. Rows
%represent frames, columns represent points along the body of the fish.
%yfull: y-coordinates for your points along the midline of the animal. Rows
%represent frames, columns represent points along the body of the fish.
%step: skip parameter. If you found the midline for every other frame, this
%value = 2.
%plt: binary input to determine if you'd like to plot nframes to check your
%subsampled data against the original video. 1 = plot, 0 = don't plot.
%nframes: the number of frames you'd like to check your subsampled data
%for.
%npts: the number of points your final spline will have.
%
%OUTPUTS
%splinex: x-coordinates for your npts splined points along the midline of
%the animal.
%spliney: y-coordinates for your nts points.
%splinexFLP: x-coordinates for your npts spline points along the midline of
%the animal, flipped to work for overlay on a video.
%splineyFLP: y-coordinates for your npts spline points along the midline of
%the animal, flipped to work for overlay on a video.
%filename: filename you fed in.
%
%REQUIRED FUNCTIONS
%flipDLThorizontal.mat
%
%By: Keegan Lutek
%September 21, 2018
% Updated January 17, 2020

function [splinemidline]=SplineMidline(filename,xfull,yfull,step,plt,nframes,npts)

%% Troubleshooting
% xfull=submidline.xfull;
% yfull=submidline.yfull;
% step=4;
% plt=1;
% nframes=2;
%%

%Shape data for following interpolation
data(1:size(xfull,1),1:2*size(xfull,2))=NaN;
data(1:step:end,1:2:2*size(xfull,2))=xfull(1:step:end,:);
data(1:step:end,2:2:2*size(xfull,2))=yfull(1:step:end,:);

%make an empty matrix for the raw data and interpolated data
orig_data=NaN(size(data,2)/2,2,size(data,1));
sample_data=NaN(npts,2,size(data,1));

%get the interpolated points from a natural spline
for i=1:step:size(data,1)
    tempData = reshape(data(i,:),2,size(data,2)/2)'; %just reshaping the data
    orig_data(:,:,i)=tempData;
    
    %if the first or last point is missing do nothing
    if isnan(tempData(1,1))||isnan(tempData(size(tempData,1),1))
        
        %if one of the points in the middle is missing remove the NaNs and
        %proceed
    elseif any(isnan(tempData(2:size(tempData,1)-1,1))) && length(find(~isnan(tempData(:,1))))<=2 %If you've just got the nose and tail for a particular frame....hopefully...
        %do nothing
    elseif any(isnan(tempData(2:size(tempData,1)-1,1))) && length(find(~isnan(tempData(:,1))))>2
        tempData = tempData(~isnan(tempData(:,1)),:);
        %calculate chordal distance
        z = cumsum(sqrt(sum((tempData-[tempData(1,:);tempData(1:size(tempData,1)-1,:)]).^2,2)));
        %get interpolated points on the spline
        cspline1=csape(z,tempData(:,1),'variational');
        cspline2=csape(z,tempData(:,2),'variational');
        sample_data(:,1,i)=fnval(cspline1, linspace(min(z),max(z),npts));
        sample_data(:,2,i)=fnval(cspline2, linspace(min(z),max(z),npts));
    else
        %calculate chordal distance
        z = cumsum(sqrt(sum((tempData-[tempData(1,:);tempData(1:size(tempData,1)-1,:)]).^2,2)));
        
        %get interpolated points on the spline
        cspline1=csape(z,tempData(:,1),'variational');
        cspline2=csape(z,tempData(:,2),'variational');
        sample_data(:,1,i)=fnval(cspline1, linspace(min(z),max(z),npts));
        sample_data(:,2,i)=fnval(cspline2, linspace(min(z),max(z),npts));
    end
    
    splinex(1:size(sample_data,3),size(sample_data,1))=NaN;
    spliney(1:size(sample_data,3),size(sample_data,1))=NaN;
    
    %Pull out x and y as we like it
    for i=1:size(sample_data,1)
        splinex(:,i)=sample_data(i,1,:);
        spliney(:,i)=sample_data(i,2,:);
    end
    
    splin(:,1:2:size(splinex,2)*2)=splinex;
    splin(:,2:2:size(spliney,2)*2)=spliney;
end
if plt==1
    % Load in video
    if exist(sprintf('%s.avi',filename),'file');
        videoObject=VideoReader(sprintf('%s.avi',filename));
        fn=sprintf('%s.avi',filename);
    else
        msgbox(sprintf('Could not find %s.avi in the current folder. Select appropriate movie file in the next dialogue.',filename))
        [fn,pn]=uigetfile('.avi','Pick your movie file');
        videoObject = VideoReader([pn fn]);
    end
    numberOfFrames = videoObject.NumberOfFrames; % The number of frames in your video
    
    for i=1:size(splin,1)
        splineFLP(i,:)=flipDLThorizontal(splin(i,:),videoObject.height);
    end
    
    xsplineFLP=splineFLP(:,1:2:end);
    ysplineFLP=splineFLP(:,2:2:end);
    
    
    %Set range for plotting
    x_range = [min(min(xsplineFLP(1:2:end,:))) max(max(xsplineFLP(1:2:end,:)))];
    y_range = [min(min(ysplineFLP(1:2:end,:))) max(max(ysplineFLP(1:2:end,:)))];
    
    %Pull out 10 frames to check your points.
    chkseq=1:step:size(xsplineFLP,1); %All your frames with splines in them.
    chkref=round(linspace(1,size(chkseq,2),nframes));
    chkframes=chkseq(chkref);
    
    %Plot to check.
    full=figure(1);
    for i=1:size(chkframes,2)
        %disp(chkframes(i))
        thisFrame = read(videoObject,chkframes(i));
        imshow(thisFrame);hold on;
        plot(xsplineFLP(chkframes(i),:),ysplineFLP(chkframes(i),:),'r.')
        axis equal
        axis([x_range y_range])
        title({'Do your points capture the shape of the fish?',...
            'Are they evenly spaced?','Enter to check the next frame'})
        pause()
        clf        
    end
end
close

splinemidline.splinex=splinex;
splinemidline.spliney=spliney;
if plt==1
    splinemidline.splinexFLP=xsplineFLP;
    splinemidline.splineyFLP=ysplineFLP;
    splinemidline.moviename=fn;
end
splinemidline.filename=filename;


end