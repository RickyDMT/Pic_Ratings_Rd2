function SimpleExposure_CC(varargin)
% Notes on 2/19/15
%Ratings file location: Make sure ratings files are in folder called "Ratings" within same folder as SimpleExposure_CC.m
%Pics folder path: Adjust accordingly Make sure THIS is true too.
%Only using session 1 ratings, regardless of fMRI session?: Assumes only uses ratings from Session 1. Change as needed.
%Check Pic size & adjust imgrect accordingly.
%Different sizes for different pic types?  Adjust accordingly.

global KEY COLORS w wRect XCENTER YCENTER PICS STIM SimpExp trial

%This is for food exposure!

prompt={'SUBJECT ID' 'Session' 'fMRI (1 = Yes, 0 = No)'};
defAns={'4444' '1' '1'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
% COND = str2double(answer{2});
SESS = str2double(answer{2});
fmri = str2double(answer{3});
% prac = str2double(answer{4});


% rng(ID); %Seed random number generator with subject ID
d = clock;

KEY = struct;
KEY.ONE= KbName('1!');
KEY.TWO= KbName('2@');
KEY.THREE= KbName('3#');
KEY.FOUR= KbName('4$');
KEY.FIVE= KbName('5%');
KEY.SIX= KbName('6^');
KEY.SEVEN= KbName('7&');
KEY.EIGHT= KbName('8*');
KEY.NINE= KbName('9(');
KEY.TEN= KbName('0)');
rangetest = cell2mat(struct2cell(KEY));
KEY.all = rangetest;

% KEY.trigger = KbName('''');     %FOR PCs, UNCOMMENT THIS
KEY.trigger = KbName('''"');  %FOR MACs, UNCOMMENT THIS


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.rect = COLORS.GREEN;

STIM = struct;
STIM.blocks = 1;
STIM.trials = 60;
STIM.totes = STIM.blocks*STIM.trials;
STIM.H_trials = 20; %40;
STIM.UnH_trials = 20; %40;
STIM.neut_trials = 20;
STIM.trialdur = 5;
STIM.jitter = [2 3 4];
% STIM.jitter = [.5 1 1.5];


%% Keyboard stuff for fMRI...

%list devices
[keyboardIndices, productNames] = GetKeyboardIndices;

isxkeys=strcmp(productNames,'Xkeys');

xkeys=keyboardIndices(isxkeys);
macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));

%in case something goes wrong or the keyboard name isn?t exactly right
if isempty(macbook)
    macbook=-1;
end

%in case you?re not hooked up to the scanner, then just work off the keyboard
if isempty(xkeys)
    xkeys=macbook;
end

%% Find & load in pics
%find the image directory by figuring out where the .m is kept
% [mdir,~,~] = fileparts(which('SimpleExposure_CC.m'));
mdir = '/Users/sticelab/Desktop/CraveControl';
subj_dir = [mdir filesep sprintf('%d',ID)];

% savedir = subj_dir; %[mdir filesep 'Results' filesep];
savename = sprintf('SimpleExposure_CC_%d-%d.mat',ID,SESS);
savefile = [mdir filesep savename];
% Check if file exists...

if exist(savefile,'file') == 2;
    error('File already exists. Please double-check and/or re-enter participant number and session information.');
end

picratefolder = subj_dir; %fullfile(mdir,'Ratings');   %XXX: Make sure ratings files are in folder called "Ratings" within same folder as SimpleExposure_CC.m
imgdir = fullfile(mdir,'MasterPics');             %XXX: Adjust accordingly Make sure THIS is true too.
%  imgdir = '/Users/canelab/Documents/StudyTasks/MasterPics';    %for testing purposes

randopics = 0;

try
    cd(picratefolder)
catch
    error('Could not find and/or open the folder that contains the image ratings.');
end


filen = sprintf('PicRating_CC_%d-1.mat',ID); %XXX: Assumes only uses ratings from Session 1. Change as needed.
try
    p = open(filen);
catch
    warning('Attemped to open file called "%s" for Subject #%d. Could not find and/or open this training rating file. Double check that you have typed in the subject number appropriately.',filen,ID);
    commandwindow;
    randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
    if randopics == 1
        cd(imgdir)
        p = struct;
        p.PicRating.no = dir('Unhealthy*');
        p.PicRating.go = dir('Healthy*');
        
        PICS.in.H = struct('name',{p.PicRating.go(randperm(STIM.H_trials)).name}');
        PICS.in.UnH = struct('name',{p.PicRating.no(randperm(STIM.UnH_trials)).name}');
        
    else
        error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
    end
    
end
cd(imgdir);

if randopics == 0;
    PICS.in.H = struct('name',{p.PicRating.H.name}');
    PICS.in.UnH = struct('name',{p.PicRating.U.name}');
    
end

neutpics = dir('water*');

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(neutpics) || isempty(PICS.in.H) || isempty(PICS.in.UnH)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Fill in rest of pertinent info
SimpExp = struct;


%1 = hi cal food, 2 = low cal food, 0 = water
pictype = [ones(STIM.H_trials,1); repmat(2,STIM.UnH_trials,1); zeros(STIM.neut_trials,1)];


if randopics == 1
    %Just choose some random pics
    
    piclist = [randperm(length(PICS.in.H),STIM.H_trials)'; randperm(length(PICS.in.UnH),STIM.UnH_trials)'; randperm(length(neutpics),STIM.neut_trials)'];
    
else
    %UPDATE 5/31/17: Need just top 20 images from each category
    
    %Because picratings are ordered, we can just choose the top 20 from
    %that list.
    piclist = [randperm(STIM.H_trials)'; randperm(STIM.UnH_trials)'; randperm(length(neutpics),STIM.neut_trials)'];
end

%Concatenate these into a long list of trial types.
trial_types = [pictype piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

jitter = BalanceTrials(STIM.totes,1,STIM.jitter);

if length(jitter) > length(trial_types)
    jitter = jitter(1:length(trial_types),:);
end


 for x = 1:STIM.blocks
     for y = 1:STIM.trials;
         tc = (x-1)*STIM.trials + y;
         SimpExp.data(tc).block = x;
         SimpExp.data(tc).trial = y;
         SimpExp.data(tc).pictype = shuffled(tc,1);
%          SimpExp.data(tc).training = shuffled(tc,2);
         if shuffled(tc,1) == 1
            SimpExp.data(tc).picname = PICS.in.H(shuffled(tc,2)).name;
         elseif shuffled(tc,1) == 0
             SimpExp.data(tc).picname = neutpics(shuffled(tc,2)).name;
         elseif shuffled(tc,1) == 2;
             SimpExp.data(tc).picname = PICS.in.UnH(shuffled(tc,2)).name;
         end
         SimpExp.data(tc).jitter = jitter(tc);
         SimpExp.data(tc).fix_onset = NaN;
         SimpExp.data(tc).pic_onset = NaN;
     end

 end

    SimpExp.info.ID = ID;
%     SimpExp.info.Condition = COND;
    SimpExp.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    


commandwindow;


%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber=max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%     Screen('Resolution',0,1024,768,[],32);
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,25);

KbName('UnifyKeyNames');

%% How big to make image;

%image should take up X% of vertical space.
halfside = fix((wRect(4)*.75)/2);
%pics are naturally 1/3 Wider than tall...
x_halfside = fix((wRect(4)*.75*(1+1/3))/2); %XXX: CHECK PIC SIZE FOR PROPER PROPORTION W:H.

imgrect = [XCENTER-x_halfside; YCENTER-halfside; XCENTER+x_halfside; YCENTER+halfside];
imgrect_neut = [XCENTER-x_halfside; YCENTER-halfside; XCENTER+x_halfside; YCENTER+halfside];

    
%% Initial screen
DrawFormattedText(w,'In this task, we will show you a series of images of foods. We want you to imagine you''re eating the food that is present on the screen.\n\nPress any key when you are ready to begin.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
% KbWait([],2);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end


Screen('Flip',w);
WaitSecs(1);

    

%% Trigger

if fmri == 1;
    DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
    Screen('Flip',w);
    
    scan_sec = KbTriggerWait(KEY.trigger,xkeys);
else
    scan_sec = GetSecs();
end

%%
for block = 1:STIM.blocks
    old = Screen('TextSize',w,60);
    for trial = 1:STIM.trials
        tcounter = (block-1)*STIM.trials + trial;
        
        tpx = imread(getfield(SimpExp,'data',{tcounter},'picname'));
        texture = Screen('MakeTexture',w,tpx);
        
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        fixon = Screen('Flip',w);
        SimpExp.data(tcounter).fix_onset  = fixon - scan_sec;
        WaitSecs(SimpExp.data(tcounter).jitter);
        
        %XXX: If different size pix for different trial types (i.e.,
        %neutral are oddly shaped), do if statement for imgrect);
        if SimpExp.data(tcounter).pictype == 0;
            Screen('DrawTexture',w,texture,[],imgrect_neut);
        else
            Screen('DrawTexture',w,texture,[],imgrect);
        end
        
        picon = Screen('Flip',w);
        SimpExp.data(tcounter).pic_onset = picon - scan_sec;
        WaitSecs(STIM.trialdur);
        
    end
    
    Screen('TextSize',w,old);
    
    if block < STIM.blocks;
        interblocktext = sprintf('That concludes Block %d.\n\nPress any key to continue to Block %d when you are ready.',block,block+1);
        DrawFormattedText(w,interblocktext,'center','center',COLORS.WHITE);
        Screen('Flip',w);
%         KbWait([],2);
        FlushEvents();
        while 1
            [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
            if pracDown == 1 && any(pracCode(KEY.all))
                break
            end
        end
        
    end
     
    
end

%% Save all the data

try
    save(savefile,'SimpExp');
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        %This "if exists" is bascially taken care of above, where the
        %script crashes if the file already exists. But if the script gets
        %lost and needs to save some place ~random, it should check to make
        %sure to not overwrite data...
        if exist(savename,'file')==2;
            savename = sprintf('SimpleExposure_CC_%d-%d_%s_%2.0f%02.0f.mat',ID,SESS,date,d(4),d(5));
        end
        save(savename,'SimpExp');
    catch
        warning('STILL problems saving....Try right-clicking on ''SimpExp'' and Save as...');
        save SimpExp
    end
end

SimpExp_table = struct2table(SimpExp.data);
SimpExp_table.SUBID = repmat(SimpExp.info.ID,height(SimpExp_table),1);
temp_date_cell = cell(height(SimpExp_table),1);
[temp_date_cell{1:height(SimpExp_table)}] = deal(SimpExp.info.date);
SimpExp_table.Date = temp_date_cell;

savename_csv = [mdir filesep sprintf('SimpExp_Food_%d-%d.csv',ID,SESS)];
writetable(SimpExp_table,savename_csv);

DrawFormattedText(w,'That concludes this task. The assessor will be with you soon.','center','center',COLORS.WHITE);
Screen('Flip', w);
% WaitSecs(5);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end


sca

end
