%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is a MATLAB GUI made for measuring the polarized absorption using
% - a framegrabber with camera
% - a rotation-stage with polarizer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Don't stay in bed unless you can make money in bed.
% - George Burns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = dichroimag(varargin)
% DICHROIMAG MATLAB code for dichroimag.fig
%      DICHROIMAG, by itself, creates a new DICHROIMAG or raises the existing
%      singleton*.
%
%      H = DICHROIMAG returns the handle to a new DICHROIMAG or the handle to
%      the existing singleton*.
%
%      DICHROIMAG('CALLBACK',hObject,eventData,h,...) calls the local
%      function named CALLBACK in DICHROIMAG.M with the given input arguments.
%
%      DICHROIMAG('Property','Value',...) creates a new DICHROIMAG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dichroimag_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dichroimag_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIh

% Edit the above text to modify the response to help dichroimag

% Last Modified by GUIDE v2.5 02-Jun-2020 18:19:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dichroimag_OpeningFcn, ...
                   'gui_OutputFcn',  @dichroimag_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before dichroimag is made visible.
function dichroimag_OpeningFcn(hObject, ~, h, varargin)
% set format
%     clc;
    format compact
    % cd to the directory of this script
    cd(fileparts(mfilename('fullpath')));

% disable serial read warnings
    warning('off','MATLAB:serial:fread:unsuccessfulRead')
    
% set gui position
    h.figure_gui_phal.Units = 'pixels';
    h.figure_gui_phal.Position = [1, 100, 1383, 787];
    
% imtek logo
    logo_imtek = imread('logo_imtek.png');
    imshow(logo_imtek, 'Parent',h.axes_imtek);

% colors
    colormap hot;
    h.color = load_colors(hObject, h);
    h.dark_mode = 1;
    toggle_dark_mode(hObject, h);
    h.button_facts.BackgroundColor = h.color.gray_medium;
    h.flag_saved = 1;
    
% clear all plots
    blank_img = imread('blank_gray.png');
    imshow(blank_img, 'Parent', h.axes_live_view)
    imshow(blank_img, 'Parent', h.axes_capture)
    imshow(blank_img, 'Parent', h.axes_angle)
    imshow(blank_img, 'Parent', h.axes_contrast)
    h.axes_histogram.Color = h.color.gray_dark;

% set parameters
    h.chosen_resolution_str = string(h.list_resolutions.String(1));
    h.popup_anglestep.Value = 5;
    h.anglestep = 20;
    h.cc = 3; % color channel (r, g, b) = (1, 2, 3)
    h.popup_color.Value = 3;
    h.chosen_res_x = 640;
    h.chosen_res_y = 360;
    h.capture_canceled = 0;
    h.capture_running = 0;
    h.radio_capture_time.Value = 0;
    h.capture_wait_time = 2; % time between shots in seconds
    h.radio_capture_dialog.Value = 1;
    % Choose lower threshold value for the contrast
    h.thresh_min = 2/100;
    h.filename = 'image';
    h.savename = './data/M-1-20d.mat';
    h.edit_savename.String = h.savename;

% sound to play after capturing images
    h.stepsound = importdata('glass-plink-2.wav'); %handel, laughter, chirp, splat, train, chirp
    h.finalsound = importdata('glass-plink-1.wav');    
    
% disable the data editing buttons
    h.radio_data_raw.Enable = 'off';
    h.radio_data_gauss2.Enable = 'off';
    h.radio_data_gauss4.Enable = 'off';

% assign inital values
    h.radio_data_raw.Value = 1;
    h.radio_data_gauss2.Value = 0;
    h.radio_data_gauss4.Value = 0;

% clear potential camera imaq objects
    a = imaqfind('Type', 'videoinput');
    clear a;

% clear motors if one connected
h.serialport_stage = '/dev/ttyUSB6';
    if exist('h.s', 'var')
        try
            if ~isunix
                disp('disconnecting stage')
                disconnect(h.s)
                delete(h.s)
            else
                fclose(h.s);
                delete(h.s)
            end
        catch
            disp('no stage connected')
        end
        clear h.s
    end

% Choose default command line output for dichroimag
h.output = hObject;

% Update h structure
guidata(hObject, h);

% --- Outputs from this function are returned to the command line.
function varargout = dichroimag_OutputFcn(~, ~, h) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% h    structure with h and user data (see GUIDATA)

% Get default command line output from h structure
varargout{1} = h.output;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            % CREATE FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function popup_anglestep_CreateFcn(hObject, ~, ~)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function list_resolutions_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_threshold_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_savename_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function popup_color_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                % CALLBACKs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CAPTURE settings
function toggle_en_camera_Callback(hObject, ~, h)
    if (get(hObject, 'Value') == get(hObject, 'Max'))
        try
            if isunix
                h.camh = videoinput('linuxvideo',1, h.chosen_resolution_str);
                h.camh.ReturnedColorspace = 'rgb';
            else
                h.camh = videoinput('winvideo',1, 'RGB32_640x360');
%                 h.camh = videoinput('winvideo',1, 'RGB32_1920x1080');  
                h.camh.ReturnedColorspace = 'rgb';
            end
            disp('connected to framegrabber')
            % comment this line out when you comment the below lines in
                hImage = image(zeros(h.chosen_res_y, h.chosen_res_x, 3),'Parent',h.axes_live_view);
            % comment these lines in to have the live view in a separate figure!
%                 tempfig = figure();
%                 a = gca;
%                 hImage = image(zeros(h.chosen_res_y, h.chosen_res_x, 3),'Parent',a);
            preview(h.camh,hImage);
        catch
            disp('couldnt find video object')
            h.toggle_en_camera.Value = 0;
        end
        h.toggle_en_camera.BackgroundColor = h.color.green;
        h.toggle_en_camera.String = 'Disable Camera';
    else
        if isfield(h, 'camh')
            disp('disconnecting framegrabber')
            stoppreview(h.camh);
            delete(h.camh);
            clear_plot(hObject, h, h.axes_live_view);
            clear_plot(hObject, h, h.axes_capture);
            blank_img = imread('blank_gray.png');
            imshow(blank_img, 'Parent', h.axes_live_view)
            imshow(blank_img, 'Parent', h.axes_capture)
        else 
            disp('failed at disconnecting')
            h.toggle_en_camera.Value = 0;
        end
        h.toggle_en_camera.BackgroundColor = h.color.red;
        h.toggle_en_camera.String = 'Enable Camera';
    end
    
    guidata(hObject, h)
    
function list_resolutions_Callback(hObject, ~, h)
	chosen_res_index = get(hObject,'Value');
    h.chosen_resolution_str = string(h.list_resolutions.String(chosen_res_index));
    disp(h.chosen_resolution_str)
    switch chosen_res_index
        case 1 % 640x360 = 1.78
            h.chosen_res_x = 640;
            h.chosen_res_y = 360;
        case 2 % 960x540 = 1.78
            h.chosen_res_x = 960;
            h.chosen_res_y = 540;
        case 3 % 1024x576 = 1.78
            h.chosen_res_x = 1024;
            h.chosen_res_y = 576;
        case 4 % 1280x720 = 1.78
            h.chosen_res_x = 1280;
            h.chosen_res_y = 720;    
        case 5 % 1368x768 = 1.78
            h.chosen_res_x = 1368;
            h.chosen_res_y = 768;
        case 6 % 1920x1080 = 1.78
            h.chosen_res_x = 1920;
            h.chosen_res_y = 1080;
        case 7 % 2560x1440 = 1.78
            h.chosen_res_x = 2560;
            h.chosen_res_y = 1440;
        case 8 % 3840x2160 = 1.78
            h.chosen_res_x = 3840;
            h.chosen_res_y = 2160;
        case 9 % 640x480 = 1.33
            h.chosen_res_x = 640;
            h.chosen_res_y = 480;
        case 10 % 800x600 = 1.33
            h.chosen_res_x = 800;
            h.chosen_res_y = 600;
        case 11 % 1600x1200 = 1.33
            h.chosen_res_x = 1600;
            h.chosen_res_y = 1200;
        case 12 % 720x480 = 1.5
            h.chosen_res_x = 720;
            h.chosen_res_y = 480;
        
        otherwise
            disp('not specified, defaulting to 640x360')
            h.chosen_res_x = 640;
            h.chosen_res_y = 360;
    end
    guidata(hObject, h);
    
function button_histogram_Callback(hObject, ~, h)
% check if camera is connected
if ~isfield(h, 'camh')
    disp('no camera connected')
    return
end
while (get(hObject, 'Value') == get(hObject, 'Max'))
    % get an image
    image_temp = getsnapshot(h.camh);
    % get nof saturated pixels and display in the text box
    if length(h.cc) == 1
        % for one color
        nof_sat_px = length(find(image_temp(:,:,h.cc) == 255));
        h.text_sat_pix.String = num2str(nof_sat_px);
        h.text_med_std.String = ['med: ', num2str(median(image_temp(:,:,h.cc),'all')), ' std: ', num2str(std(double(image_temp(:,:,h.cc)), 0, 'all'))];
        histogram(image_temp(:,:,h.cc), 'Parent', h.axes_histogram)
    elseif length(h.cc) == 2
        % for two colors
        nof_sat_px_1 = length(find(image_temp(:,:,h.cc(1)) == 255));
        nof_sat_px_2 = length(find(image_temp(:,:,h.cc(2)) == 255));
        h.text_sat_pix.String = num2str(nof_sat_px_1 + nof_sat_px_2);
        histogram(image_temp(:, :, h.cc(1)), 'facealpha', .5, 'Parent', h.axes_histogram)
        hold on
        histogram(image_temp(:, :, h.cc(2)), 'facealpha', .5, 'Parent', h.axes_histogram)
        hold off
    end
        
    % limit axis height to 10 % of number of pixels
    ylim([0, 0.1*numel(image_temp(:, :, h.cc(1)))])
    xlim([0, 255])
    h.axes_histogram.XColor = 'white';
    h.axes_histogram.YColor = 'white';
    pause(1)
end
h.text_med_std.String = '';
h.text_sat_pix.String = '';
if ~isempty(h.axes_histogram.Children)
    delete(h.axes_histogram.Children);
end
h.axes_histogram.Color = h.color.gray_dark;
h.axes_histogram.XColor = h.color.gray_dark;
h.axes_histogram.YColor = h.color.gray_dark;
guidata(hObject, h);    
    
function popup_anglestep_Callback(hObject, ~, h)
    if h.popup_anglestep.Value >= 1
        chosen_anglestep = str2double(h.popup_anglestep.String(h.popup_anglestep.Value));
        disp(['Chose ', num2str(chosen_anglestep), ' degree steps'])
        h.anglestep = chosen_anglestep;
    else
        disp('not valid, setting 20 degree steps')
        h.anglestep = 20;
    end
    guidata(hObject,h);

function popup_color_Callback(hObject, ~, h)    
    h.cc = h.popup_color.Value;
    if h.cc == 4
        h.cc = [2, 3];
        disp('Chose color channels green and blue')
    else
        disp(['Chose color channel ', num2str(h.cc)])
    end
    guidata(hObject,h)

function radio_capture_time_Callback(hObject, ~, h)    
if (get(hObject,'Value') == get(hObject,'Max'))
	disp('Selected time based capture');
    h.radio_capture_dialog.Value = 0;
    h.radio_capture_auto.Value = 0;
else
	disp('Cannot unselect');
    h.radio_capture_time.Value = 1;
end
guidata(hObject, h);

function radio_capture_dialog_Callback(hObject, ~, h)
if (get(hObject,'Value') == get(hObject,'Max'))
	disp('Selected dialog based capture');
    h.radio_capture_time.Value = 0;
    h.radio_capture_auto.Value = 0;
else
	disp('Cannot unselect');
    h.radio_capture_dialog.Value = 1;
end
guidata(hObject, h);

function radio_capture_auto_Callback(hObject, ~, h)
if (get(hObject,'Value') == get(hObject,'Max'))
	disp('Selected automated capture');
    h.radio_capture_time.Value = 0;
    h.radio_capture_dialog.Value = 0;
    % connect to motor
    if ~isunix
        a = thmotor.listdevices;
        h.s = thmotor;
        connect(h.s, a{1})
        % turn home
        home(h.s)
        currpos = h.s.position;
        disp(['currently at position:', num2str(currpos)])
    else
        if ~isempty(instrfind)
            % clear all previous connections
            a = instrfind;
            fclose(a(:));
            delete(a(:));
            clear a
        end
        % set up serial connection
        h.s = serial(h.serialport_stage);
        try
            fopen(h.s);
        catch
            disp(['serial port ', h.serialport_stage, ' not available'])
            h.radio_capture_dialog.Value = 1;
            h.radio_capture_auto.Value = 0;
            return
        end
        h.s.BaudRate = 115200;
        h.s.DataBits = 8;
        h.s.StopBits = 1;
        h.s.Parity = 'none';
        h.s.FlowControl = 'hardware';
        h.s.Terminator = '';
        h.s.Timeout = 4;
        pause(0.1)
        % flash display
        str = '23 02 00 00 50 01'; % to identify stage
        command = sscanf(str, '%2X'); % convert string to hex sequence
        disp(['command to stage: ', str])
        fwrite(h.s, command, 'int8')
        % move home
        str = '43 04 01 00 50 01';
        command = sscanf(str, '%2X');
        disp(['command to stage: ', str])
        fwrite(h.s, command, 'int8')
        message = fread(h.s);
%         disp(message)
    end
else
	disp('Cannot unselect');
    h.radio_capture_auto.Value = 1;
end
guidata(hObject, h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CAPTURE images
function button_start_capture_Callback(hObject, ~, h)
    if ~isfield(h, 'camh')
        disp('no camera connected, returing')
        return
    end
    % check it if was saved yet
    if ~h.flag_saved
        f = warndlg('Data is not saved yet!', '!! Start? !!');
        waitfor(f);
        h.flag_saved = 1;
        guidata(hObject,h);
        return
    end
    h.capture_canceled = 0;
    h.capture_running = 1;
    nof_steps = round(180/h.anglestep);
% nof_steps = round(360/h.anglestep);
    disp(['taking ', num2str(nof_steps), ' shots'])
    nof_sat_px = zeros(nof_steps,1);
    data_raw = zeros(h.chosen_res_y, h.chosen_res_x, nof_steps);
    
%     % measure background (with unaligned sample!)
%     f = warndlg('Measure background noise, put blank sample!', '!! Prestart !!');
%     waitfor(f);
%     img_temp = getsnapshot(h.camh);
%     background = img_temp(:, :, 3);
%     sound(h.stepsound.data, h.stepsound.fs);
%     % pop up a dialog before starting
%     f = warndlg('Background measured, now put sample!', '!! Start !!');
%     waitfor(f);
    
    % capture plus rotation
    for n=1:nof_steps
        % wait for confirmation if dialog-capture
        if h.radio_capture_dialog.Value
            % pop up a dialog before each capture if set
            f = warndlg(['Pressing OK will record image #', num2str(n),'/', num2str(nof_steps)],...
                '!! Next Step !!');
            waitfor(f);
        end
        
        % get snapshot
        disp(['Getting shot #', num2str(n)])
        img_temp = getsnapshot(h.camh);
        % display snapshot
        image(img_temp, 'Parent', h.axes_capture)
        axis(h.axes_capture, 'off')
        
        % correct gamma with empirical factors (measured at 1/500 exposure time)
        % and get saturated pixels
        if length(h.cc) == 1
            % for one color
            img_corrected = 0.06*double(img_temp(:, :, h.cc)).^1.55;
%     img_corrected = img_temp(:, :, h.cc); %%%% disable correction
            nof_sat_px(n) = length(find(img_temp(:,:,h.cc) == 255));
        elseif length(h.cc) == 2
            % for two colors
            img_corrected_1 = 0.06*double(img_temp(:, :, h.cc(1))).^1.55;
            img_corrected_2 = 0.06*double(img_temp(:, :, h.cc(2))).^1.55;
            % average over the two color channels
            img_corrected = (img_corrected_1 + img_corrected_2)/2;
            
            nof_sat_px_1 = sum(find(img_temp(:,:,h.cc(1)) == 255));
            nof_sat_px_2 = sum(find(img_temp(:,:,h.cc(2)) == 255));
            nof_sat_px(n) = max(nof_sat_px_1, nof_sat_px_2);
        else
            disp('invalid color channel')
        end
        
        % save just data of the selected color channel h.cc
        data_raw(:, :, n) = img_corrected;
            
        if nof_sat_px(n) > 10
            disp(['saturated pixels: ', num2str(nof_sat_px(n))])
        end
        h.text_nof_sat_px.String = nof_sat_px(n);
        
        % play sound after each capture
        sound(h.stepsound.data, h.stepsound.fs);

        % move stage if automatic measurement        
        if (h.radio_capture_auto.Value && (n~=nof_steps))
            if isfield(h, 's')
                if ~isunix
                    moveto(h.s, (n-1)*h.anglestep)
                    currpos = h.s.position;
                    disp(['rotation stage now at ', num2str(round(currpos,1)), ' degree'])
                else
                    moverel(h.s, h.anglestep)
                    pause(0.5)
                end
            else
                disp('no rotation stage connected')
                return
            end
        end
        
        h = guidata(hObject);
        
        % check if cancelled
        if h.capture_canceled
            disp('cancelled capture')
            h.capture_canceled = 0;
            break
        end
        % wait for time if timed capture
        if h.radio_capture_time.Value
            pause(h.capture_wait_time)
        end
    end
    
    % move motor home
    if h.radio_capture_auto.Value
        % turn home
        if ~isunix
            home(h.s)
            currpos = h.s.position;
            disp(['currently at position:', num2str(currpos)])
        else
            str = '43 04 01 00 50 01';
            command = sscanf(str, '%2X');
            disp(['command to stage: ', str])
            fwrite(h.s, command, 'int8')
        end
    end
    disp('finished taking images')
    sound(h.finalsound.data, h.finalsound.fs);
    h.flag_saved = 0;
    h.capture_running = 0;
    
    % plot data
    [h.data_contrast_filtered, h.data_angle_filtered] = plot_maxmin(hObject, h, data_raw);
    % enable the data editing buttons
    h.radio_data_raw.Enable = 'on';
    h.radio_data_gauss2.Enable = 'on';
    h.radio_data_gauss4.Enable = 'on';
    
    h.data_raw = data_raw;
    guidata(hObject,h);

function button_cancel_capture_Callback(hObject, ~, h)
if ~h.capture_running
    disp('nothing to cancel')
    return
end
disp('pressed cancel button');
h.capture_canceled = 1;
guidata(hObject,h); 

function button_single_capture_Callback(~, ~, h)
if ~isfield(h, 'camh')
        disp('no camera connected')
        return
end
% get a single snapshot from the live stream and open it in a new figure
temp_img = getsnapshot(h.camh);
singleshot = figure('Name', 'single shot', 'WindowState', 'fullscreen');
temp_axis = gca;

imagesc(temp_img, 'Parent', temp_axis);
axis off
drawnow
% uncomment this to save the snapshot immediately in the home directory
    dt = datetime;
    dtstring = sprintf('%i-%02i-%02i_%02i.%02i.%02i',dt.Year, dt.Month, dt.Day, dt.Hour, dt.Minute, round(dt.Second));
    imwrite(temp_img, ['~/', dtstring, '.png'])
pause(2)
close(singleshot)

function button_single_color_Callback(~, ~, h)
if ~isfield(h, 'camh')
        disp('no camera connected')
        return
end
% get a single snapshot from the live stream and open it in a new figure
temp_img = getsnapshot(h.camh);
temp_mat_corrected = 0.06*double(temp_img(:, :, h.cc)).^1.55;
a = temp_mat_corrected;

% save the variables
disp('saving single color snapshot file...')
dt = datetime;
dtstring = sprintf('%i-%02i-%02i_%02i.%02i.%02i',dt.Year, dt.Month, dt.Day, dt.Hour, dt.Minute, round(dt.Second));
save(['~/', dtstring, '.mat'], 'a', '-v7.3')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROCESSING

function edit_savename_Callback(hObject, ~, h)
h.savename = h.edit_savename.String;
guidata(hObject, h);

function button_save_data_Callback(hObject, ~, h)
% check if a measurement has been done
if ~isfield(h, 'data_raw')
    disp('no data measured to save')
    return
end

[filename, path] = uiputfile(h.savename);
if isequal(filename,0) || isequal(path,0)
    disp('User clicked Cancel.')
else
    disp(['User selected ',fullfile(path,filename),' and then clicked Save.'])
    % select all the necessary data and store it in a
    a.data_raw = h.data_raw;
    a.chosen_res_x = h.chosen_res_x;
    a.chosen_res_y = h.chosen_res_y;
    a.anglestep = h.anglestep;
    % save the variables
    disp('writing file...')
    save(fullfile(path,filename), 'a', '-v7.3')
    disp(['has been saved as: ', fullfile(path,filename)]);
    clear a;
    h.flag_saved = 1;
    guidata(hObject,h);
end
    
function button_load_data_Callback(hObject, ~, h) 
    [filename, path] = uigetfile({'*.mat','plausible preset files (*.mat)'},'Select preset file','./data');
    if isequal(filename,0)
        disp('User selected Cancel')
        return
    else
        disp('loading file ...')
        load(fullfile(path,filename));
        disp('loading variables')
        h.savename = ['./data/', filename];
        h.edit_savename.String = ['./data/', filename];
        h.data_raw = a.data_raw;
        h.chosen_res_x = a.chosen_res_x;
        h.chosen_res_y = a.chosen_res_y;
        h.anglestep = a.anglestep;
        clear a;
        h.filename = filename;
        % plot maxmin
        [h.data_contrast_filtered, h.data_angle_filtered] = plot_maxmin(hObject, h, h.data_raw);
        % enable the data editing buttons
        h.radio_data_raw.Enable = 'on';
        h.radio_data_gauss2.Enable = 'on';
        h.radio_data_gauss4.Enable = 'on';
    end
    guidata(hObject, h)
    
function edit_threshold_Callback(hObject, ~, h)
thresh_min = str2double(h.edit_threshold.String);
if isnan(thresh_min)
    disp('invalid value, defaulting to 5 %')
    thresh_min = 5;
    h.edit_threshold.String = 5;
end
h.thresh_min = thresh_min/100;
[h.data_contrast_filtered, h.data_angle_filtered] = plot_maxmin(hObject, h, h.data_raw);
guidata(hObject, h);

function radio_data_raw_Callback(hObject, ~, h)
if (get(hObject,'Value') == get(hObject,'Max'))
	disp('Selected to show data raw');
    h.radio_data_gauss2.Value = 0;
    h.radio_data_gauss4.Value = 0;
    [h.data_contrast_filtered, h.data_angle_filtered] = plot_maxmin(hObject, h, h.data_raw);
else
	disp('Cannot unselect');
    h.radio_data_raw.Value = 1;
end
guidata(hObject,h);

function radio_data_gauss2_Callback(hObject, ~, h)
if (get(hObject,'Value') == get(hObject,'Max'))
	disp('Selected to apply Gauss2');
    h.radio_data_raw.Value = 0;
    h.radio_data_gauss4.Value = 0;
    data_gauss2 = imgaussfilt(h.data_raw, 2);
    [h.data_contrast_filtered, h.data_angle_filtered] = plot_maxmin(hObject, h, data_gauss2);
else
	disp('Cannot unselect');
    h.radio_data_gauss2.Value = 1;
end
guidata(hObject,h);

function radio_data_gauss4_Callback(hObject, ~, h)
if (get(hObject,'Value') == get(hObject,'Max'))
	disp('Selected to apply Gauss4');
    h.radio_data_raw.Value = 0;
    h.radio_data_gauss2.Value = 0;
    data_gauss4 = imgaussfilt(h.data_raw, 4);
    [h.data_contrast_filtered, h.data_angle_filtered] = plot_maxmin(hObject, h, data_gauss4);
else
	disp('Cannot unselect');
    h.radio_data_gauss4.Value = 1;
end
guidata(hObject,h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GUI control

function button_reset_Callback(~, ~, h)
    if exist('h.camh', 'var')
        delete(h.camh);
    end
    if exist('h.s', 'var')
        try
            if ~isunix
                disp('disconnecting stage')
                disconnect(h.s)
                delete(h.s)
            else
                fclose(h.s);
                delete(h.s)
            end
        catch
            disp('no stage connected')
        end
        clear h.s
    end
    close(h.fig_absimg)
    absimg

function button_quit_Callback(~, ~, h)
    if ~h.flag_saved
        f = warndlg('Data is not saved yet!', '!! Save? !!');
        waitfor(f);
        h.flag_saved = 1;
        guidata(hObject,h);
        return
    end
    if exist('h.camh', 'var')
        delete(h.camh);
    end
    if exist('h.s', 'var')
        try
            if ~isunix
                disp('disconnecting stage')
                disconnect(h.s)
                delete(h.s)
            else
                fclose(h.s);
                delete(h.s)
            end
        catch
            disp('no stage connected')
        end
        clear h.s
    end
    % DEBUG
        % save the variables of h to the workspace
%         disp('saving all the variables to the workspace as "h"')
%         assignin('base','h',h);
    close(h.fig_absimg)
    
function button_facts_Callback(~, ~, h)
if isempty(h.button_facts.String)
    h.button_facts.String = 'This GUI is proudly presented by Yannick Folwill 2020';
else
    h.button_facts.String = '';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% save and export buttons

function button_open_angle_Callback(hObject, ~, h)
if ~isfield(h, 'data_angle_filtered')
    disp('no data loaded')
    return
end
h.toprint_angle = figure();
imagesc(h.data_angle_filtered);
a = gca;
colormap(a, ycolormap('twilight'));
axis off
colorbar('Ticks', [-90, -45, 0, 45, 90], 'TickDirection', 'out');
guidata(hObject, h);

function button_save_angle_Callback(hObject, ~, h)
if ~isfield(h, 'toprint_angle')
    disp('no data loaded')
    return
end
% saves the image plot with the name of the sample in the home directory
print(h.toprint_angle,['~/', h.filename, '_image.png'],'-dpng', '-r300');
guidata(hObject, h);

function button_angle_hist_Callback(hObject, ~, h)
if ~isfield(h, 'data_angle_filtered')
    disp('no data loaded')
    return
end
h.histplot_angle = figure();
histogram(h.data_angle_filtered(h.data_contrast_filtered < 0.4), 200)
guidata(hObject, h);

function button_open_contrast_Callback(hObject, ~, h)
if ~isfield(h, 'data_contrast_filtered')
    disp('no data loaded')
    return
end
h.toprint_contrast = figure();
imagesc(100*h.data_contrast_filtered);
a = gca;
a.CLim = [0, 40];
axis off
colormap(a, ycolormap('magma'));
colorbar('Ticks', [0, 10, 20, 30, 40], 'TickDirection', 'out')
guidata(hObject, h);

function button_save_contrast_Callback(hObject, ~, h)
% saves the mask plot with the name of the sample
if ~isfield(h, 'toprint_contrast')
    disp('no data loaded')
    return
end
print(h.toprint_contrast,['~/', h.filename,'_mask.png'],'-dpng', '-r300');
    guidata(hObject, h);    

function button_contrast_hist_Callback(hObject, ~, h)
if ~isfield(h, 'data_contrast_filtered')
    disp('no data loaded')
    return
end
h.histplot_contrast = figure();
histogram(100*h.data_contrast_filtered(h.data_contrast_filtered < 0.4), 200)
guidata(hObject, h);

function button_save_contrast_mat_Callback(hObject, ~, h)
% saves the contrast with the name of the sample in the home directory
if ~isfield(h, 'data_contrast_filtered')
    disp('no data loaded')
    return
end
contrast = h.data_contrast_filtered;
save(['~/', h.filename(1:(end-4)),'_contrast.mat'], 'contrast');
guidata(hObject, h);
    
function button_save_angle_mat_Callback(hObject, ~, h)
% saves the angle as mat file with the name of the sample in the home directory
if ~isfield(h, 'data_angle_filtered')
    disp('no data loaded')
    return
end
angle = h.data_angle_filtered;
save(['~/', h.filename(1:(end-4)),'_angle.mat'], 'angle');
guidata(hObject, h);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extra functions

function [] = clear_plot(hObject, h, input_axis)
    if isvalid(input_axis)
        items = input_axis.Children;
        if ~isempty(items)
            delete(input_axis.Children);
        end
    end
    guidata(hObject, h);

function[data_contrast_filtered, data_angle_filtered] = plot_maxmin(hObject, h, data)    
    % fourier transform every pixel and find the phase and amplitude of
    % lowest frequency, as well as amplitude of DC value
    datafft = fft(data, [], 3);
    data_DC = abs(datafft(:, :, 1));
    data_sig = abs(datafft(:, :, 2));
    data_contrast = data_sig./data_DC * 2;
    data_angle = rad2deg(angle(datafft(:, :, 2)))/2; %divide by 2 for -90-90 degree
    
    % filtering
    data_contrast_filtered = data_contrast;
    data_angle_filtered = data_angle;
    % remove values that are way smaller than the mean
%     data_contrast_filtered(data_sig < 0.4*mean(data_sig(:))) = NaN;
%     data_angle_filtered(data_sig < 0.4*mean(data_sig(:))) = NaN;

    % filter with contrast threshold
    data_angle_filtered(data_contrast < h.thresh_min) = NaN;
    data_contrast_filtered(data_contrast < h.thresh_min) = NaN;
    
    % export to workspace for further analysis
    assignin('base', 'contrast', data_contrast_filtered);
    assignin('base', 'angle', data_angle_filtered);
    
    % plot the angle
% imagesc(data_angle, 'Parent', h.axes_angle);
    imagesc(data_angle_filtered, 'Parent', h.axes_angle);
    axis(h.axes_angle,'off')
    h.axes_angle.CLim = [-90, 90];
    colorbar(h.axes_angle, 'Color', 'white', 'Ticks', [-90, -45, 0, 45, 90], 'TickDirection', 'out');
    h.axes_angle.Colormap = ycolormap('twilight');
    
    % plot the contrast
% imagesc(100*data_contrast, 'Parent', h.axes_contrast);
    imagesc(100*data_contrast_filtered, 'Parent', h.axes_contrast);
    axis(h.axes_contrast, 'off')
% comment this out if you do not want to scale the color axis!
h.axes_contrast.CLim = [0, 40];
    colorbar(h.axes_contrast, 'Color', 'white', 'Ticks', [0, 10, 20, 30, 40], 'TickDirection', 'out')
    h.axes_contrast.Colormap = ycolormap('magma');
    guidata(hObject, h);
    
function [color] = load_colors(~, ~)
colors = lines(7);
color.blue = colors(1,:);
color.orange = colors(2,:);
color.yellow = colors(3,:);
color.purple = colors(4,:);
color.green = colors(5,:);
color.blue_light = colors(6,:);
color.red = colors(7,:);
color.gray_light = [0.94, 0.94, 0.94];
color.gray_medium = [0.4, 0.4, 0.4];
color.gray_dark = [0.15, 0.15, 0.15];

function toggle_dark_mode(~, h)
% to make the GUI brighter set h.dark_mode=0 and then run toggle_dark_mode(hObject, h)
if h.dark_mode
    color_bg = h.color.gray_dark;
    color_bg2 = h.color.gray_medium;
    color_fg = 'white';
else
    color_bg = h.color.gray_light;
    color_bg2 = h.color.gray_light;
    color_fg = 'black';
end
% change GUI background
a = findall(gcf, 'Tag', 'fig_absimg');
for n=1:length(a)
    a(n).Color = color_bg;
end
% change uipanel elements
a = findall(gcf, 'Type', 'uibuttongroup');
for n=1:length(a)
    a(n).BackgroundColor = color_bg;
    a(n).ForegroundColor = color_fg;
end
% change checkbox elements
a = findall(gcf, 'Type', 'uicontrol', 'Style', 'checkbox');
for n=1:length(a)
    a(n).BackgroundColor = color_bg2;
end
% change radio elements
a = findall(gcf, 'Type', 'uicontrol', 'Style', 'radio');
for n=1:length(a)
    a(n).BackgroundColor = color_bg;
    a(n).ForegroundColor = color_fg;
end
% change text elements
a = findall(gcf, 'Type', 'uicontrol', 'Style', 'text');
for n=1:length(a)
    a(n).BackgroundColor = color_bg;
    a(n).ForegroundColor = color_fg;
end
% change edit elements
a = findall(gcf, 'Type', 'uicontrol', 'Style', 'edit');
for n=1:length(a)
    a(n).BackgroundColor = color_bg2;
    a(n).ForegroundColor = color_fg;
end
% change pushbutton elements
a = findall(gcf, 'Type', 'uicontrol', 'Style', 'pushbutton');
for n=1:length(a)
    a(n).BackgroundColor = color_bg2;
    a(n).ForegroundColor = color_fg;
end
% change togglebutton elements
a = findall(gcf, 'Type', 'uicontrol', 'Style', 'togglebutton');
for n=1:length(a)
    a(n).BackgroundColor = color_bg2;
    a(n).ForegroundColor = color_fg;
end
    
function moverel(s, anglestep)
    switch anglestep
        case 5
            str = '48 04 06 00 D0 01 01 00 7E 25 00 00';
        case 10
            str = '48 04 06 00 D0 01 01 00 FC 4A 00 00';
        case 15
            str = '48 04 06 00 D0 01 01 00 7A 70 00 00';
        case 18
            str = '48 04 06 00 D0 01 01 00 F9 86 00 00';
        case 20
            str = '48 04 06 00 D0 01 01 00 F8 95 00 00';
        case 30
            str = '48 04 06 00 D0 01 01 00 F5 E0 00 00';
        case 36
            str = '48 04 06 00 D0 01 01 00 F3 0D 01 00';
        case 45
            str = '48 04 06 00 D0 01 01 00 6F 51 01 00';
        case 60
            str = '48 04 06 00 D0 01 01 00 EA C1 01 00';
    end
    command = sscanf(str, '%2X');
%     disp(['command to stage: ', str])
    disp(['rotating ', num2str(anglestep), ' degrees'])
    fwrite(s, command, 'uint8')
    pause(0.5)
    message = fread(s);
%     disp(message)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% new functions (always rename "handles" to "h")    
