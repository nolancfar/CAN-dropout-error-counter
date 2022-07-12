%% Main Script
pathname = uigetdir();
newpathname = append(pathname,'_counted');
copyfile(pathname,newpathname,'f');

outputLog = fopen(append(newpathname,'\dropouts_and_errors.txt'),'wt');
filePattern = fullfile(newpathname, '*.MF4');
fileNames = dir(filePattern);

for i = 1:length(fileNames)
    %print file header
    fprintf(outputLog,'########  %s  ########\n',fileNames(i).name);

    %read in and parse data from mdf file
    [tempCanTable,tempErrorTable,errors] = readmdf(fullfile(fileNames(i).folder, fileNames(i).name));
    [tempCanData,tempErrorData,ID_uniqueList] = canLoopParser(tempCanTable,tempErrorTable);

    %determine runtime
    runtime = tempCanTable.TimestampEpoch(end)-tempCanTable.TimestampEpoch(1);
    fprintf(outputLog,'Log runtime: %d seconds\n', uint32(runtime));
    k = 1;

    %determine and print dropout counts
    for k=1:length(ID_uniqueList)
        drop_indx = tempCanData.(['ID' ID_uniqueList{k}]).msgDropouts;
        if any(drop_indx)
                fprintf(outputLog,'%d dropouts were identified for CAN ID: %s\n',num2str(sum(drop_indx)),ID_uniqueList{k});
        end
    end

    %determine and print error counts
    if errors
        totalErrorCount = length(tempErrorTable);
        fprintf(outputLog,'\n\nTotal Number of Errors: %d\n',totalErrorCount);

        if isfield(tempErrorData,'error0')
            error0count = length(tempErrorData.error0);
            fprintf(outputLog,'   Number of Unknown Errors: %d\n',error0count);
        end
        if isfield(tempErrorData,'error1')
            error1count = length(tempErrorData.error1);
            fprintf(outputLog,'   Number of Bit Errors: %d\n',error1count);
        end
        if isfield(tempErrorData,'error2')
            error2count = length(tempErrorData.error2);
            fprintf(outputLog,'   Number of Form Errors: %d\n',error2count);
        end
        if isfield(tempErrorData,'error3')
            error3count = length(tempErrorData.error3);
            fprintf(outputLog,'   Number of Bit-Stuffing Errors: %d\n',error3count);
        end
        if isfield(tempErrorData,'error4')
            error4count = length(tempErrorData.error4);
            fprintf(outputLog,'   Number of CRC Errors: %d\n',error4count);
        end
        if isfield(tempErrorData,'error5')
            error5count = length(tempErrorData.error5);
            fprintf(outputLog,'   Number of ACK Errors: %d\n',error5count);
        end
    else
        fprintf(outputLog,'\n\nErrors not present in this log');
    end

    fprintf(outputLog,'\n\n\n');
    disp([fileNames(i).name ' complete'])
end

fclose('all');
disp('Script Complete.')
