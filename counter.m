%% Main Script
pathname = uigetdir();
newpathname = append(pathname,'_counted');
copyfile(pathname,newpathname,'f');

outputLog = fopen(append(newpathname,'\dropouts_and_errors.txt'),'wt');
filePattern = fullfile(newpathname, '*.MF4');
fileNames = dir(filePattern);

%initialize totals variables
for channel = 1:2
    tempName = ['bus' num2str(channel)];
    totals.(tempName).runtime = 0;
    totals.(tempName).totalErrorCount = 0;
    totals.(tempName).error0count = 0;
    totals.(tempName).error1count = 0;
    totals.(tempName).error2count = 0;
    totals.(tempName).error3count = 0;
    totals.(tempName).error4count = 0;
    totals.(tempName).error5count = 0;
end

dropoutIDIndex = 1;

%loop through every file in the folder
for i = 1:length(fileNames)
    %print file header
    fprintf(outputLog,'############  %s  ############\n\n',fileNames(i).name);

    for busChannel = 1:2
        %print bus header
        fprintf(outputLog,'    ####  Data for Bus %d  ####\n',busChannel);

        temp_busname = ['bus' num2str(busChannel)];

        %read in and parse data from mdf file
        [tempCanTable,tempErrorTable,errors] = readmdf(fullfile(fileNames(i).folder, fileNames(i).name),busChannel);
        [tempCanData,tempErrorData,ID_uniqueList] = canLoopParser(tempCanTable,tempErrorTable);

        %determine runtime
        runtime = tempCanTable.TimestampEpoch(end)-tempCanTable.TimestampEpoch(1);
        fprintf(outputLog,'    Log runtime: %d seconds\n\n', uint32(runtime));
        totals.(temp_busname).runtime = totals.(temp_busname).runtime + runtime;

        %determine and print dropout counts
        for k=1:length(ID_uniqueList)
            temp_IDname = ['ID' ID_uniqueList{k}];
            drop_indx = tempCanData.(temp_IDname).msgDropouts;
            if any(drop_indx)
                fprintf(outputLog,'    %s dropouts were identified for CAN ID: %s\n',num2str(sum(drop_indx)),ID_uniqueList{k});
                
                if isfield(totals.(temp_busname),temp_IDname)
                    totals.(temp_busname).(temp_IDname) = totals.(temp_busname).(temp_IDname) + sum(drop_indx);
                else
                    totals.(temp_busname).(temp_IDname) = sum(drop_indx);
                    ID_dropoutList.(temp_busname){dropoutIDIndex} = temp_IDname;
                    dropoutIDIndex = dropoutIDIndex + 1;
                end
            end
        end

        %determine and print error counts
        if errors
            totalErrorCount = length(tempErrorTable.TimestampEpoch);
            fprintf(outputLog,'\n    Total Number of Errors: %d\n',totalErrorCount);
            totals.(temp_busname).totalErrorCount = totals.(temp_busname).totalErrorCount + totalErrorCount;

            if isfield(tempErrorData,'error0')
                error0count = length(tempErrorData.error0.TimestampEpoch);
                fprintf(outputLog,'       Number of Unknown Errors: %d\n',error0count);
                totals.(temp_busname).error0count = totals.(temp_busname).error0count + error0count;
            end
            if isfield(tempErrorData,'error1')
                error1count = length(tempErrorData.error1.TimestampEpoch);
                fprintf(outputLog,'       Number of Bit Errors: %d\n',error1count);
                totals.(temp_busname).error1count = totals.(temp_busname).error1count + error1count;
            end
            if isfield(tempErrorData,'error2')
                error2count = length(tempErrorData.error2.TimestampEpoch);
                fprintf(outputLog,'       Number of Form Errors: %d\n',error2count);
                totals.(temp_busname).error2count = totals.(temp_busname).error2count + error2count;
            end
            if isfield(tempErrorData,'error3')
                error3count = length(tempErrorData.error3.TimestampEpoch);
                fprintf(outputLog,'       Number of Bit-Stuffing Errors: %d\n',error3count);
                totals.(temp_busname).error3count = totals.(temp_busname).error3count + error3count;
            end
            if isfield(tempErrorData,'error4')
                error4count = length(tempErrorData.error4.TimestampEpoch);
                fprintf(outputLog,'       Number of CRC Errors: %d\n',error4count);
                totals.(temp_busname).error4count = totals.(temp_busname).error4count + error4count;
            end
            if isfield(tempErrorData,'error5')
                error5count = length(tempErrorData.error5.TimestampEpoch);
                fprintf(outputLog,'       Number of ACK Errors: %d\n',error5count);
                totals.(temp_busname).error5count = totals.(temp_busname).error5count + error5count;
            end
        else
            fprintf(outputLog,'\n    Errors not present in this log');
        end

        fprintf(outputLog,'\n\n\n');
        disp([fileNames(i).name ' Bus ' num2str(busChannel) ' complete'])

        clear tempErrorData tempErrorTable tempCanData tempCanTable ID_uniqueList drop_indx runtime totalErrorCount
    end
end

%print folder summary
fprintf(outputLog,'##################  SUMMARY  ##################\n\n');
fprintf(outputLog,'####  Bus 1  ####\n');
fprintf(outputLog,'Total runtime: %d seconds\n\n',uint32(totals.bus1.runtime));

%print errors on bus 1
if totals.bus1.totalErrorCount == 0
    fprintf(outputLog,'No errors present on this bus\n\n');
else
    fprintf(outputLog,'Total Errors: %d\n',totals.bus1.totalErrorCount);
    if totals.bus1.error0count ~= 0
        fprintf(outputLog,'   Total Unknown Errors: %d\n',totals.bus1.error0count);
    end
    if totals.bus1.error1count ~= 0
        fprintf(outputLog,'   Total Bit Errors: %d\n',totals.bus1.error1count);
    end
    if totals.bus1.error2count ~= 0
        fprintf(outputLog,'   Total Form Errors: %d\n',totals.bus1.error2count);
    end
    if totals.bus1.error3count ~= 0
        fprintf(outputLog,'   Total Bit-Stuffing Errors: %d\n',totals.bus1.error3count);
    end
    if totals.bus1.error4count ~= 0
        fprintf(outputLog,'   Total CRC Errors: %d\n',totals.bus1.error4count);
    end
    if totals.bus1.error5count ~= 0
        fprintf(outputLog,'   Total ACK Errors: %d\n',totals.bus1.error5count);
    end
end

%print dropouts on bus 1
% if isfield(ID_dropoutList,'bus1')
%     for i = 1:length(ID_dropoutList.bus1)
        
%     end
% else
%     fprintf(outputLog,'No dropouts were detected on this bus\n');
% end


fprintf(outputLog,'\n\n####  Bus 2  ####\n');
fprintf(outputLog,'Total runtime: %d seconds\n\n',uint32(totals.bus2.runtime));

%print errors
if totals.bus2.totalErrorCount == 0
    fprintf(outputLog,'No errors present on this bus\n\n');
else
    fprintf(outputLog,'Total Errors: %d\n',totals.bus2.totalErrorCount);
    if totals.bus2.error0count ~= 0
        fprintf(outputLog,'   Total Unknown Errors: %d\n',totals.bus2.error0count);
    end
    if totals.bus2.error1count ~= 0
        fprintf(outputLog,'   Total Bit Errors: %d\n',totals.bus2.error1count);
    end
    if totals.bus2.error2count ~= 0
        fprintf(outputLog,'   Total Form Errors: %d\n',totals.bus2.error2count);
    end
    if totals.bus2.error3count ~= 0
        fprintf(outputLog,'   Total Bit-Stuffing Errors: %d\n',totals.bus2.error3count);
    end
    if totals.bus2.error4count ~= 0
        fprintf(outputLog,'   Total CRC Errors: %d\n',totals.bus2.error4count);
    end
    if totals.bus2.error5count ~= 0
        fprintf(outputLog,'   Total ACK Errors: %d\n',totals.bus2.error5count);
    end
end

%final cleanup
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
        if isempty(error_uniqueList)
            errors = false;
            errorData = [];
        else
            errors = true;
        end
    catch
        errors = false;
        errorData = [];
    end

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

    if isempty(rawTable_Errors)
        errors = false;
        rawErrorTable = [];
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
