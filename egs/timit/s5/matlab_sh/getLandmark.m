function [phoneCount, phoneList] = getLandmark(fileInd)

IS_FORCE = 0;
IS_39P = 0;
IS_48P = 0;
SAVE_TO_MAT = 1;
PRINT_OUT = 0;

path_to_timit_test = '/home/hd89cgm/ece544na/TIMIT/TIMIT/TEST/';

path_to_info = '/home/hd89cgm/ece544na/kaldi-trunk/egs/timit/s5/exp/tri2/decode_test/';

path_to_temp = '/home/hd89cgm/ece544na/kaldi-trunk/egs/timit/s5/temp/';

if IS_39P == 1,
    VOWEL_LIST = {'iy', 'ih', 'eh', 'ey', 'ae', 'aa', 'aw', 'ay',...
    'ah', 'oy', 'ow', 'uh', 'uw', 'er'};
    
    GLIDE_LIST = {'l', 'r', 'w', 'y', 'hh'};

    NASAL_LIST = {'m', 'n', 'ng'};

    STOP_CLOSE_LIST = {'sil'};

    STOP_LIST = {'b', 'd', 'g', 'p', 't', 'k', 'dx'};

    FRICATIVE_LIST = {'s', 'sh', 'z', 'f', 'th', 'v', 'dh'};

    AFFRICATE_LIST = {'jh', 'ch'};
elseif IS_48P == 1,
    VOWEL_LIST = {'iy', 'ih', 'eh', 'ey', 'ae', 'aa', 'aw', 'ay',...
    'ah', 'ao', 'oy', 'ow', 'uh', 'uw', 'er', 'ax',...
    'ix'};

    GLIDE_LIST = {'l', 'r', 'w', 'y', 'hh', 'el'};

    NASAL_LIST = {'m', 'n', 'ng', 'en'};

    STOP_CLOSE_LIST = {'vcl', 'cl', 'sil'};

    STOP_LIST = {'b', 'd', 'g', 'p', 't', 'k', 'dx'};

    FRICATIVE_LIST = {'s', 'sh', 'z', 'zh', 'f', 'th', 'v', 'dh'};

    AFFRICATE_LIST = {'jh', 'ch'};
else
    VOWEL_LIST = {'iy', 'ih', 'eh', 'ey', 'ae', 'aa', 'aw', 'ay',...
    'ah', 'ao', 'oy', 'ow', 'uh', 'uw', 'ux', 'er', 'ax',...
    'ix', 'axr', 'ax-h'};

    GLIDE_LIST = {'l', 'r', 'w', 'y', 'hh', 'hv', 'el'};

    NASAL_LIST = {'m', 'n', 'ng', 'em', 'en', 'eng', 'nx'};

    STOP_CLOSE_LIST = {'bcl', 'dcl', 'gcl', 'pcl', 'tcl', 'kcl'};

    STOP_LIST = {'b', 'd', 'g', 'p', 't', 'k', 'dx', 'q'};

    FRICATIVE_LIST = {'s', 'sh', 'z', 'zh', 'f', 'th', 'v', 'dh'};

    AFFRICATE_LIST = {'jh', 'ch'};
    
    REMAIN_LIST = {'epi', 'h#', 'pau'};
end;

phoneList = [VOWEL_LIST GLIDE_LIST NASAL_LIST STOP_CLOSE_LIST STOP_LIST ...
    FRICATIVE_LIST AFFRICATE_LIST REMAIN_LIST];

phoneCount = zeros(1, length(phoneList));

USE_REGION = 0;



addpath(path_to_timit_test);
addpath(path_to_info);
addpath(path_to_temp);

info_file_name = ['frame_info.' num2str(fileInd) '.txt'];

fileID = fopen(info_file_name);
info = textscan(fileID, '%s %s %s');
fclose(fileID);

uttCount = length(info{1,1});
folder = cell(uttCount,1);
fileName = cell(uttCount,1);
frameCount = zeros(uttCount,1);

for i = 1:uttCount,
    temp = strsplit(info{1,1}{i},'_');
    folder{i} = temp{1,1};
    fileName{i} = temp{1,2};
    frameCount(i) = str2double(info{1,2}{i});
end

endPts = cell(uttCount,1);
startPts = cell(uttCount,1);
phoneLabels = cell(uttCount,1);
for i = 1:uttCount,
    if IS_FORCE == 1,
        pho_fileID = fopen([info{1,1}{i} '.force.txt']);
    else
        [~,path_fold] = unix(['find ' path_to_timit_test '* -name "' folder{i} '"']);
        pho_fileID = fopen([path_fold(1:end - 1) '/' fileName{i} '.PHN']);
    end;
    info2 = textscan(pho_fileID,'%s %s %s');
    endPts{i} = str2double(info2{1,2});
    startPts{i} = str2double(info2{1,1});
    phoneLabels{i} = info2{1,3};
    fclose(pho_fileID);
end;

frame_marks = cell(uttCount,1);
for i = 1:uttCount,
    temp_phone_count = length(phoneLabels{i});
    frame_mark = cell(length(frameCount(i)),1);
    for j = 1:frameCount(i),
        frame_mark{j} = 'E';
    end;
    temp_phone_list = phoneLabels{i};
    temp_start_list = startPts{i};
    temp_end_list = endPts{i};
    mapping_ratio = temp_end_list(end)/frameCount(i);
    for j = 1:temp_phone_count,
        %find phone type and mark landmarks
        if find(strcmp(temp_phone_list(j),VOWEL_LIST)),
            mark_point = (temp_start_list(j) + temp_end_list(j))/2;
            frame_point = mark_point/mapping_ratio;
            if USE_REGION == 1,
                frame_mark = mark_round(frame_mark, frame_point - 1.5, 'V');
                frame_mark = mark_round(frame_mark, frame_point - 0.5, 'V');
                frame_mark = mark_round(frame_mark, frame_point + 0.5, 'V');
                frame_mark = mark_round(frame_mark, frame_point + 1.5, 'V');
            elseif USE_REGION == 2,
                frame_mark = mark_round(frame_mark, frame_point - 1, 'V');
                frame_mark = mark_round(frame_mark, frame_point, 'V');
                frame_mark = mark_round(frame_mark, frame_point + 1, 'V');
            else
                frame_mark = mark_round(frame_mark, frame_point, 'V');
            end;
            
        elseif find(strcmp(temp_phone_list(j), GLIDE_LIST)),
            mark_point = (temp_start_list(j) + temp_end_list(j))/2;
            frame_point = mark_point/mapping_ratio;
            if USE_REGION == 1,
                frame_mark = mark_round(frame_mark, frame_point - 1.5, 'G');
                frame_mark = mark_round(frame_mark, frame_point - 0.5, 'G');
                frame_mark = mark_round(frame_mark, frame_point + 0.5, 'G');
                frame_mark = mark_round(frame_mark, frame_point + 1.5, 'G');
            elseif USE_REGION == 2,
                frame_mark = mark_round(frame_mark, frame_point - 1, 'G');
                frame_mark = mark_round(frame_mark, frame_point, 'G');
                frame_mark = mark_round(frame_mark, frame_point + 1, 'G');                
            else
                frame_mark = mark_round(frame_mark, frame_point, 'G');
            end;
                
        elseif find(strcmp(temp_phone_list(j), NASAL_LIST)),
            if USE_REGION == 1,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Nc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 1.5, 'Nc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 1.5, 'Nr');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 0.5, 'Nr');
            elseif USE_REGION == 2,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Nc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Nc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 0.5, 'Nr');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio, 'Nr');
            else
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Nc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio, 'Nr');
            end;
            
        elseif find(strcmp(temp_phone_list(j), STOP_CLOSE_LIST)),
            if USE_REGION == 1,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Sc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 1.5, 'Sc');
            elseif USE_REGION == 2,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Sc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Sc');                
            else
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Sc');
            end;
            
        elseif find(strcmp(temp_phone_list(j), STOP_LIST)),
            if USE_REGION == 1,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio - 1.5, 'Sr');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio - 0.5, 'Sr');
            elseif USE_REGION == 2,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio - 0.5, 'Sr');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Sr');
            else
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Sr');
            end;
            
        elseif find(strcmp(temp_phone_list(j), FRICATIVE_LIST)),
            if USE_REGION == 1,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Fc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 1.5, 'Fc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 1.5, 'Fr');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 0.5, 'Fr');
            elseif USE_REGION == 2,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Fc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Fc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 0.5, 'Fr');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio, 'Fr');
            else
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Fc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio, 'Fr');
            end;
            
        elseif find(strcmp(temp_phone_list(j), AFFRICATE_LIST)),
            if USE_REGION == 1,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio - 1.5, 'Sr');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio - 0.5, 'Sr');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Fc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 1.5, 'Fc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 1.5, 'Fr');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 0.5, 'Fr');
            elseif USE_REGION == 2,
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio - 0.5, 'Sr');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Sr');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Fc');
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio + 0.5, 'Fc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio - 0.5, 'Fr');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio, 'Fr');
            else
                frame_mark = mark_round(frame_mark, temp_start_list(j)/mapping_ratio, 'Sr-Fc');
                frame_mark = mark_round(frame_mark, temp_end_list(j)/mapping_ratio, 'Fr');
            end;
            
%         else
%             mark_start = temp_start_list(j)/mapping_ratio;
%             if mark_start - floor(mark_start) > 0.6,
%                 mark_start = ceil(mark_start);
%             end;
%             mark_end = temp_end_list(j)/mapping_ratio;
%             if mark_end - floor(mark_end) < 0.3,
%                 mark_end = floor(mark_end);
%             end;
%             
%             for k = floor(mark_start):ceil(mark_end),
%                 frame_mark = mark_round(frame_mark, k, 'U');
%             end;
%             
        end;
        tempPhoneInd = find(strcmp(phoneList,temp_phone_list(j)));
        phoneCount(tempPhoneInd) = phoneCount(tempPhoneInd) + 1;
    end;
    frame_marks{i} = frame_mark;
end;

if IS_FORCE == 1,
    if IS_39P == 1,
        out_fileID = fopen([path_to_info 'force_phone39_mark_info.' num2str(fileInd) '.txt'], 'w');
    elseif IS_48P == 1,
        out_fileID = fopen([path_to_info 'force_phone48_mark_info.' num2str(fileInd) '.txt'], 'w');
    else
        out_fileID = fopen([path_to_info 'force_phone_mark_info.' num2str(fileInd) '.txt'], 'w');
    end;
else
    out_fileID = fopen([path_to_info 'phone_mark_info.' num2str(fileInd) '.txt'], 'w');
end;

for i = 1:uttCount,
    fprintf(out_fileID, '%s', [folder{i} '_' fileName{i}]);
    for j = 1:length(frame_marks{i}),
        fprintf(out_fileID, ' %s', char(frame_marks{i}(j)));
    end;
    fprintf(out_fileID, '\n');
end;
fclose(out_fileID);

end

function frame_mark = mark_round(frame_mark, frame_point, mark)

MARK_PRE = 0;

if (frame_point - floor(frame_point) < 0.6) && (floor(frame_point) == 0),
        if strcmp(frame_mark{floor(frame_point) + 1},'E'),
            frame_mark{floor(frame_point) + 1} = mark;
        else
            frame_mark{floor(frame_point) + 1} = [frame_mark{floor(frame_point) + 1} '-' mark];
        end;
        return;
end;

if MARK_PRE == 1,
	if (frame_point - floor(frame_point) > 0.3) && (frame_point - floor(frame_point) < 0.6) && (floor(frame_point) == 0),
		MARK_PRE = 0;
	end;
end;

%landmarks can overlap on a single frame
if frame_point - floor(frame_point) > 0.3,
    if frame_point - floor(frame_point) < 0.6,
        if strcmp(frame_mark{floor(frame_point)},'E'),
            frame_mark{floor(frame_point)} = mark;
        else
            frame_mark{floor(frame_point)} = [frame_mark{floor(frame_point)} '-' mark];
        end;
        if strcmp(frame_mark{ceil(frame_point)},'E')
            frame_mark{ceil(frame_point)} = mark;
        else
            frame_mark{ceil(frame_point)} = [frame_mark{ceil(frame_point)} '-' mark];
        end;
    else
        if strcmp(frame_mark{ceil(frame_point)},'E')
            frame_mark{ceil(frame_point)} = mark;
        else
            frame_mark{ceil(frame_point)} = [frame_mark{ceil(frame_point)} '-' mark];
        end;
    end;
else
    if strcmp(frame_mark{floor(frame_point)},'E'),
        frame_mark{floor(frame_point)} = mark;
    else
        frame_mark{floor(frame_point)} = [frame_mark{floor(frame_point)} '-' mark];
    end;
end;

end

function frame_mark = mark_round2(frame_mark, frame_point, mark)

MARK_PRE = 0;

if (frame_point - floor(frame_point) < 0.6) && (floor(frame_point) == 0),
        if strcmp(frame_mark{floor(frame_point) + 1},'E'),
            frame_mark{floor(frame_point) + 1} = mark;
        else
            frame_mark{floor(frame_point) + 1} = [frame_mark{floor(frame_point) + 1} '-' mark];
        end;
        return;
end;

if MARK_PRE == 1,
	if (frame_point - floor(frame_point) > 0.3) && (frame_point - floor(frame_point) < 0.6) && (floor(frame_point) == 0),
		MARK_PRE = 0;
	end;
end;

%landmarks can overlap on a single frame
if frame_point - floor(frame_point) > 0.3,
    if frame_point - floor(frame_point) < 0.6,
        if strcmp(frame_mark{floor(frame_point)},'E'),
            frame_mark{floor(frame_point)} = mark;
        else
            frame_mark{floor(frame_point)} = [frame_mark{floor(frame_point)} '-' mark];
        end;
        if strcmp(frame_mark{ceil(frame_point)},'E')
            frame_mark{ceil(frame_point)} = mark;
        else
            frame_mark{ceil(frame_point)} = [frame_mark{ceil(frame_point)} '-' mark];
        end;
    else
        if strcmp(frame_mark{ceil(frame_point)},'E')
            frame_mark{ceil(frame_point)} = mark;
        else
            frame_mark{ceil(frame_point)} = [frame_mark{ceil(frame_point)} '-' mark];
        end;
    end;
else
    if strcmp(frame_mark{floor(frame_point)},'E'),
        frame_mark{floor(frame_point)} = mark;
    else
        frame_mark{floor(frame_point)} = [frame_mark{floor(frame_point)} '-' mark];
    end;
end;

end
