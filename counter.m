%% Main Script
pathname = uigetdir();
newpathname = append(pathname,'_counted');
copyfile(pathname,newpathname,'f');

outputLog = fopen(append(newpathname,'\dropouts_and_errors.txt'),'wt');
filePattern = fullfile(newpathname, '*.MF4');
fileNames = dir(filePattern);

for i = 1:length(fileNames)
    %print file header
    fprintf(outputLog,'############  %s  ############\n\n',fileNames(i).name);

    for busChannel = 1:2
        %print bus header
        fprintf(outputLog,'    ####  Data for Bus %d  ####\n',busChannel);

        %read in and parse data from mdf file
        [tempCanTable,tempErrorTable,errors] = readmdf(fullfile(fileNames(i).folder, fileNames(i).name),busChannel);
        [tempCanData,tempErrorData,ID_uniqueList] = canLoopParser(tempCanTable,tempErrorTable);

        %determine runtime
        runtime = tempCanTable.TimestampEpoch(end)-tempCanTable.TimestampEpoch(1);
        fprintf(outputLog,'    Log runtime: %d seconds\n\n', uint32(runtime));

        %determine and print dropout counts
        for k=1:length(ID_uniqueList)
            drop_indx = tempCanData.(['ID' ID_uniqueList{k}]).msgDropouts;
            if any(drop_indx)
                    fprintf(outputLog,'    %d dropouts were identified for CAN ID: %s\n',num2str(sum(drop_indx)),ID_uniqueList{k});
            end
        end

        %determine and print error counts
        if errors
            totalErrorCount = length(tempErrorTable);
            fprintf(outputLog,'\n    Total Number of Errors: %d\n',totalErrorCount);

            if isfield(tempErrorData,'error0')
                error0count = length(tempErrorData.error0);
                fprintf(outputLog,'     Number of Unknown Errors: %d\n',error0count);
            end
            if isfield(tempErrorData,'error1')
                error1count = length(tempErrorData.error1);
                fprintf(outputLog,'     Number of Bit Errors: %d\n',error1count);
            end
            if isfield(tempErrorData,'error2')
                error2count = length(tempErrorData.error2);
                fprintf(outputLog,'     Number of Form Errors: %d\n',error2count);
            end
            if isfield(tempErrorData,'error3')
                error3count = length(tempErrorData.error3);
                fprintf(outputLog,'     Number of Bit-Stuffing Errors: %d\n',error3count);
            end
            if isfield(tempErrorData,'error4')
                error4count = length(tempErrorData.error4);
                fprintf(outputLog,'     Number of CRC Errors: %d\n',error4count);
            end
            if isfield(tempErrorData,'error5')
                error5count = length(tempErrorData.error5);
                fprintf(outputLog,'     Number of ACK Errors: %d\n',error5count);
            end
        else
            fprintf(outputLog,'\n    Errors not present in this log');
        end

        fprintf(outputLog,'\n\n\n');
        disp([fileNames(i).name ' Bus ' num2str(busChannel) ' complete'])
    end
end

fclose('all');
disp('Script Complete.')

function [canData, errorData, ID_uniqueList] = canLoopParser(canLog_rawTable, errorLog_rawTable)
%CAN LOOP PARSER 
%Identify unique IDs store timestap/sample data and if known process it

%Author: Sean Bazzocchi (sean.bazzocchi@gmail.com)
    
    %Get list of unique IDs and errors
    ID_uniqueList = unique(canLog_rawTable.ID);
    try
        error_uniqueList = unique(errorLog_rawTable.ErrorType);
        errors = true;
    catch
        errors = false;
        errorData = [];
    end

    %Create variable of indexes to delete
    delete_indexes = [];

    %Initialize timestamp to 0
    if errors
        if canLog_rawTable.TimestampEpoch(1) <= errorLog_rawTable.TimestampEpoch(1)
            canLog_rawTable.TimestampEpoch = canLog_rawTable.TimestampEpoch-canLog_rawTable.TimestampEpoch(1);
            errorLog_rawTable.TimestampEpoch = errorLog_rawTable.TimestampEpoch-canLog_rawTable.TimestampEpoch(1);
        else
            canLog_rawTable.TimestampEpoch = canLog_rawTable.TimestampEpoch-errorLog_rawTable.TimestampEpoch(1);
            errorLog_rawTable.TimestampEpoch = errorLog_rawTable.TimestampEpoch-errorLog_rawTable.TimestampEpoch(1);
        end
    else
        canLog_rawTable.TimestampEpoch = canLog_rawTable.TimestampEpoch - canLog_rawTable.TimestampEpoch(1);
    end
    
    %Loop through every unique error
    if errors
        for error_index = 1:length(error_uniqueList)
            temp_error = error_uniqueList(error_index);
            temp_errorname = ['error' int2str(temp_error)];
            temp_errorIndexList = errorLog_rawTable.ErrorType == temp_error;
            temp_errorTimestamp = errorLog_rawTable.TimestampEpoch(temp_errorIndexList);

            errorData.(temp_errorname).TimestampEpoch = temp_errorTimestamp;
        end
    end

    %Loop through every unique ID
    for ID_index = 1:length(ID_uniqueList)  
        
        temp_id = ID_uniqueList{ID_index};
        temp_fieldname = ['ID' temp_id]; %Need to start the filedname with a letter hence the ID prefix
        temp_indexList = strcmp(temp_id, canLog_rawTable.ID);
        
        temp_timestamp = canLog_rawTable.TimestampEpoch(temp_indexList);
        temp_timestep = [NaN; diff(temp_timestamp)];
        temp_msgDropouts = temp_timestep>mode(temp_timestep)+0.005;

        %Save temp variables to data structure
        canData.(temp_fieldname).timeStamp = temp_timestamp;
        canData.(temp_fieldname).timeStep = temp_timestep;
        canData.(temp_fieldname).msgDropouts = temp_msgDropouts;
        
end

function [rawCanTable,rawErrorTable,errors] = readmdf(filename,busChannel)
    %Converts MF4 log files to a mat table
    
    try
        finalizedPath = mdfFinalize(filename);
    catch ME
        disp(ME.message)
    end
    
    m = mdf(finalizedPath);
    
    can_Data_idx = 8;
    rawTable_Data = timetable2table(read(m,can_Data_idx,["Timestamp" "CAN_DataFrame.BusChannel" "CAN_DataFrame.ID"]),'ConvertRowTimes',false);
    
    errors = true;
    can_Error_idx = 7;
    rawTable_Errors = timetable2table(read(m,can_Error_idx,["Timestamp" "CAN_ErrorFrame.BusChannel" "CAN_ErrorFrame.ErrorType"]),'ConvertRowTimes',false);
    
    initialTimestamp = double(convertTo(m.InitialTimestamp,'epochtime'));
    
    clear m can_Data_idx can_Error_idx
    
    if busChannel == 1
        rawTable_Data = rawTable_Data(rawTable_Data.CAN_DataFrame_BusChannel == 1,:);
        try
            rawTable_Errors = rawTable_Errors(rawTable_Errors.CAN_ErrorFrame_BusChannel == 1,:);
        catch
            errors = false;
            rawErrorTable = [];
        end
    elseif busChannel == 2
        rawTable_Data = rawTable_Data(rawTable_Data.CAN_DataFrame_BusChannel == 2,:);
        try
            rawTable_Errors = rawTable_Errors(rawTable_Errors.CAN_ErrorFrame_BusChannel == 2,:);
        catch
            errors = false;
            rawErrorTable = [];
        end
    end
    
    %load data into final structure
    rawCanTable.TimestampEpoch = rawTable_Data.Timestamp + initialTimestamp;
    rawCanTable.ID = compose("%X",rawTable_Data.CAN_DataFrame_ID);
    
    if errors
        rawErrorTable.TimestampEpoch = rawTable_Errors.Timestamp + initialTimestamp;
        rawErrorTable.ErrorType = rawTable_Errors.CAN_ErrorFrame_ErrorType;
    end
    
    clear rawTable_Data rawTable_Errors
    
    rawCanTable = struct2table(rawCanTable);
    if errors
        rawErrorTable = struct2table(rawErrorTable);
    end
    end
end