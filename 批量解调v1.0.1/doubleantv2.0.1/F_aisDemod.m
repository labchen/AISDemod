function demodResult = F_aisDemod(sig)
% ----
% 本函数为多个AIS信号解调方案
% 输入:
%	sig:输入的待解调基带GMSK信号, 为m*n矩阵, n为信号抽样点数, m为接收信号天线数
% 输出:
%	demodResult:解调结果, data为解调正确信息(不含帧附加比特), pos为解调正确
%				的抽样点位置, slotNum为总时隙数, par为解调正确信号的参数估计
% ----
	% 全局变量设置
	global Start_pos BlockLength os DecodLenth ant_num TrainingLength FlagLength
	Start_pos = 1;
    if size(sig, 1) > size(sig, 2)
		sig = sig.';
    end
    
    % test 测试多天线和双天线性能时，用双天线程序解四天线信号
    if size(sig,1) ~= 2
        sig = sig(1:2,:);
    end
    
	aisData_all = cell(0);
	sigPos_all = zeros(0, 2);
	parsEst_all = zeros(0, 2);
	% 查找第一个信号位置, flag为1是找到同步的标志
	End_pos = min(length(sig),Start_pos+2*DecodLenth*os-1);       % 截取2*DecodLength*os的信息长度, 保证译码长度内找到的同步位置向后一个译码长度内有数据
	Delay = zeros(1, size(sig, 1));
	flag = zeros(1, size(sig,1));
	while Start_pos<length(sig) && End_pos-Start_pos>=BlockLength*os-1
		SlotCutIdx = Start_pos:End_pos;     % 截取信息在全部信息中的编号
		sig_ch = sig(:,SlotCutIdx);
		for mm = 1 : size(sig,1)
			% 对各通道信号进行信道估计 并 VA解调找信号同步
			[Delay(mm), dopplerEst, hEst, flag(mm), decisionSeq, match_len, startIndex] = ...
				F_channelEstAndDemod(sig_ch(mm,:));
		end
		if all(flag == 0)
			% 所有天线都没有找到同步, 加上所有天线中最小的时延估计再同步
			Start_pos = max(1, Start_pos+min(Delay));
			End_pos = min(length(sig), Start_pos+2*DecodLenth*os-1);
			continue;
		else
			% 有信号找到同步, 证明卫星开始接受, 向前一段距离重新开始同步并解调
			Start_pos = max(1, Start_pos+min(Delay)-10*os);      % 应为110bit, 因为信号到达卫星的最大延时为110bit, 此处为仿真时用10bit
			End_pos = min(length(sig), Start_pos+2*DecodLenth*os-1);
			break;
		end
    end
    
	Block_count = 0;
	% 查找信号位置, 若找到则解调
	while Start_pos<length(sig)&& End_pos-Start_pos>=BlockLength*os-1
		% 确定第一个信号的位置, 再同步开始解调信号
  		SlotCutIdx = Start_pos:End_pos;
		sig_ch_tmp = [];
 		for ant_num = {[1 2]}
%		for ant_num = {[1 3], [2 4]}
			sig_ch = sig(cell2mat(ant_num), SlotCutIdx);
			if ~all(sig_ch(1,:)==0)&&~all(sig_ch(2,:)==0)
				sig_ch_tmp = [sig_ch_tmp; fastICA_Complex_lly_jw(sig_ch)];
			else
				sig_ch_tmp = [sig_ch_tmp; sig_ch];
			end
		end
		for mm = 1:size(sig_ch_tmp,1)   
			% 对各通道信号进行信道估计 并 VA解调找信号同步
			[Delay(mm), dopplerEst, hEst, flag(mm), decisionSeq, match_len, startIndex] = ...
				F_channelEstAndDemod(sig_ch_tmp(mm, :));
		end
		if all(flag==0)
			% 两个天线都没有找到同步, 加上两天线中最小的时延估计再同步
			Start_pos = Start_pos+min(Delay);
			End_pos = min(length(sig),Start_pos+2*DecodLenth*os-1);
			continue;
        else
			% 有信号找到同步, 证明卫星开始接受, 向前一段距离重新开始同步并解调
			Start_pos = max(1, Start_pos+min(Delay)-10*os);      % 应为110bit, 因为信号到达卫星的最大延时为110bit, 此处为仿真时用10bit
			End_pos = min(length(sig), Start_pos+2*DecodLenth*os-1);
        end
        
		% 根据同步位置截取信号
		SlotCutIdx = Start_pos : End_pos;
		SigLength = length(SlotCutIdx);
		if SigLength < BlockLength*os
			break;
		end
		Block_count = Block_count + 1;
		disp('==========================');
		disp(['时隙: ' num2str(Block_count)]);
		disp(['起始位置: ', num2str(Start_pos)]); 		
        for ant_num = {[1 2]}
%		for ant_num = {[1 3], [2 4]}
			% 对各信号单天线解调
			sig_ch = sig(cell2mat(ant_num),SlotCutIdx);
			BSS_output_1 = fastICA_Complex_lly_jw(sig_ch);
			sig_ch_sic = zeros(size(BSS_output_1));
% 			figure;subplot(211);plot(abs(BSS_output_1(1, :)));subplot(212);plot(abs(BSS_output_1(2, :)));
			for mm = 1 : 1 : size(BSS_output_1, 1)
                [sig_ch_sic(mm,:), aisData, sigPos, parsEst] = F_singleAntDemod(BSS_output_1(mm,:));
%   				[sig_ch_sic(mm,:), aisData, sigPos, parsEst] = F_singleAntOneDemod_ver2(BSS_output_1(mm,:));
                %test
                if ~isempty(aisData)
                    for iii = 1 : 1 : length(aisData)
                       curData = aisData{iii};
                       curData(curData==' ')=[];
                       disp(['第一次盲分离',curData]);
                    end
                    aisData_all = [aisData_all aisData];
                    sigPos_all = [sigPos_all; sigPos];
                    parsEst_all = [parsEst_all; parsEst];
                end
                %test end
			end
			
%             BSS_output_2 = fastICA_Complex_lly_jw(sig_ch_sic);
% %             figure;subplot(211);plot(abs(BSS_output_2(1, :)));subplot(212);plot(abs(BSS_output_2(2, :)));
%             for mm = 1 : 1 : size(BSS_output_2, 1)
%                 [sig_ch_sic(mm,:), aisData, sigPos, parsEst] = F_singleAntDemod(BSS_output_2(mm,:));
%                 if length(aisData) > 0
%                    for iii = 1 : 1 : length(aisData)
%                        curData = aisData{iii};
%                        curData(curData==' ')=[];
%                        disp(['第二次盲分离',curData]);
%                    end 
%                    aisData_all = [aisData_all aisData];
%                    sigPos_all = [sigPos_all; sigPos];
%                    parsEst_all = [parsEst_all; parsEst];
%                 end          
%             end
			num_of_checked = length(aisData_all);          % 解调函数中记录解对信号
			disp(['译码正确报文个数：',num2str(num_of_checked)]);
		end
		Start_pos = Start_pos+(BlockLength-TrainingLength-FlagLength)*os;
% 	    Start_pos = Start_pos+2*4*9600;
		End_pos = min(length(sig),Start_pos+2*DecodLenth*os-1);
	end
	% 删除重复的帧
%     [sigPos_all_uni, ind_uni] = unique(sigPos_all, 'rows', 'stable');
% 	demodResult.data = aisData_all(ind_uni);
% 	demodResult.pos = sigPos_all_uni;
% 	demodResult.slotNum = Block_count;
% 	demodResult.par = parsEst_all(ind_uni, :);

	demodResult.data = aisData_all;
	demodResult.pos = sigPos_all;
	demodResult.slotNum = Block_count;
	demodResult.par = parsEst_all;
end