function [rawCanTable,rawErrorTable,errors] = mdf2mat(filename,busChannel)
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