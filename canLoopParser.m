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
    