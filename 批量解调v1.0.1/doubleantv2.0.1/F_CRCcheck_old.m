function [data_rec_raw, crc_check] = F_CRCcheck(info)
% remove zeros inserted and do CRC check
%     idx = 1;
%     while idx+7<=length(info) 
%         if sum(info(idx:idx+7)==[0 1 1 1 1 1 1 0])>=7
%             startIndex = idx+8;
%             if startIndex>32
%                 break;
%             else
%                 idx = idx+1;
%             end
%         else
%             if idx>50
%                 startIndex = 41;
%                 break;
%             else
%                 idx = idx+1;
%             end
%         end
%     end
    startIndex = F_findDataLoc(info);
    % 验证同步序列是否正确
    Training = ones(1,24);
    Training(1:2:end) = 0;
    StartFlag = [0 1 1 1 1 1 1 0];
    Train_data = [Training,StartFlag];
    test_syn = info(max(1,startIndex-32):(startIndex-1));
    len = length(test_syn);
    if sum(test_syn~=Train_data(end-len+1:end))>(len/2)
        flag = 0;
    end
    % 验证结束

    
    
    data_rec = info(startIndex:end);
    idx = 1;
    while idx+6<=length(data_rec) && sum(data_rec(idx:idx+6)==[0 1 1 1 1 1 1])~=7
        if sum(data_rec(idx:idx+5)==[1 1 1 1 1 0])==6
            data_rec(idx+5:end-1) = data_rec(idx+6:end);
            idx = idx+5;
        else
            idx = idx+1;
        end
        if idx==185
            data_rec_tmp = data_rec(1:184);
            [data_rec_raw, crc_check] =FCS_crc_check(data_rec_tmp);
            if crc_check==0
                return;
            end
        end
    end
%     [endIndex, endFlag] = F_findEndFlag(info, startIndex);
%     data_rec = info(startIndex:endIndex);

%     disp(['信息段起始位置',num2str(startIndex),'信息段结束位置',num2str(idx),'
%     信息段长度',num2str(length(data_rec))])
    if length(data_rec)>16
        [data_rec_raw, crc_check] =FCS_crc_check(data_rec);
    else
        data_rec_raw = info;
        crc_check = -1;
    end

end