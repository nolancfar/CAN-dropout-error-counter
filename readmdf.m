function [rawCanTable,rawErrorTable,errors] = mdf2mat(filename)
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

%load data into final structure
rawCanTable.TimestampEpoch = rawTable_Data.Timestamp + initialTimestamp;
rawCanTable.ID = compose("%X",rawTable_Data.CAN_DataFrame_ID);

try
    rawErrorTable.TimestampEpoch = rawTable_Errors.Timestamp + initialTimestamp;
    rawErrorTable.ErrorType = rawTable_Errors.CAN_ErrorFrame_ErrorType;
catch
    rawErrorTable = [];
    errors = false;
end

clear rawTable_Data rawTable_Errors

rawCanTable = struct2table(rawCanTable);
if errors
    rawErrorTable = struct2table(rawErrorTable);
end
end