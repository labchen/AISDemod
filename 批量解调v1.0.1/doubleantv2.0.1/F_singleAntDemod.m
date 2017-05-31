function [sig, aisData, sigPos, parsEst] = F_singleAntDemod(sig)
% ----
% 此函数为单个AIS信号(含冲突信号)的单天线解调方案
% 输入:
%	sigIn:输入的接收AIS信号
% 输出:
%	sigOut:消除强信号后的信号, 可再次调用该函数解多重冲突
%	aisData:解调后二进制信息
%	sigPos:解调正确信号位置
%	parsEst:估计出的信号时延频偏
% ----
	global BlockLength os DataLength Training StartFlag EndFlag DecodLenth ...
		L RisingLength FrameLength truncate symbols h0 Start_pos ant_num Rb ...
		TrainingLength FlagLength
	sig_ch_sic = sig;
	SigLength = length(sig);     % 信号长度
	if SigLength> 3*BlockLength*os
		% 解调起始位置, 针对冲突信号的解调, 详见
		% AIS项目单通道两用户仿真结果分析报告_v2.0
		sicStartLoc = [1,(BlockLength-TrainingLength-FlagLength)*os+1, 1];	
% 		sicStartLoc = [1,1];		% 无冲突信号时减少运行时间
	else
		sicStartLoc = [1,1];
	end
	
	K = length(sicStartLoc);			% 解调起始位置总数
	num_est = 0;					% 估计信号数
	BufferLength = 24*ones(1, K);	% 各信号的缓冲区长度
	
	VA_result_dec = zeros(K, DecodLenth);
	Delay_est = zeros(1, K);
	Doppler_est = zeros(1, K);
	H_est = zeros(1, K);
	VA_dec_start = zeros(1, K);
	VA_dec_end = zeros(1, K);
	DataIdx = cell(1, K);
	for kk = 1 : 1 : K
		[delayEst, dopplerEst, hEst, flag, decisionSeq, match_len, dataLoc] = ...
			F_channelEstAndDemod(sig_ch_sic(sicStartLoc(kk):end));
		if flag == 0
			% 未找到同步, 则从下一个起始位置解
			continue;
		end
		num_est = num_est+1;        % 找到同步, 估计信号个数加1
		VA_result_dec(num_est, :) = decisionSeq;		% 记录信道估计中VA解调的结果
		Delay_est(num_est) = delayEst+sicStartLoc(kk)-1;	% 根据sicStartLoc调整Delay_est
		Doppler_est(num_est) = dopplerEst;				% 记录估计出的信号频偏
		H_est(num_est) = hEst;
		VA_dec_start(num_est) = dataLoc;				% 记录估计出的信息位置
		[VA_dec_end(num_est), sic_flag] = F_findEndFlag(decisionSeq, VA_dec_start(num_est));	% 查找结束标志
		DataIdx{num_est} = VA_dec_start(num_est):VA_dec_end(num_est);       % 数据标号
		
		% 重建较强信号并消去
		if sic_flag == 1
			% 找到结束标志, 重建训练序列和结束标志
			DataFrame_r = [Training StartFlag decisionSeq(DataIdx{num_est}) EndFlag];
		else
			% 未找到结束标志, 从开始标志估计的后184位, 重建训练序列
			DataFrame_r = [Training StartFlag decisionSeq(DataIdx{num_est})];
		end
		sig_gmsk_ext_r = F_aisModul(DataFrame_r, 0);
		
		% 使用重构信号再估计频偏位置
		sig_ch_est = F_cutSig(sig_ch_sic, Delay_est(num_est), length(sig_gmsk_ext_r));
		% 根据完整的重建信号重新估计频偏
		TuneRange = dopplerEst+(-25:0.5:25);   % 估计频偏基础上前后25Hz范围内相关运算
		TuneCorr = zeros(1,length(TuneRange));
		t = (Delay_est(num_est)+(0:length(sig_gmsk_ext_r)-1))/os/Rb;
		for freqIdx = 1:length(TuneRange)
			CarrierOffset_tmp = exp(1j*2*pi*TuneRange(freqIdx)*t);
			sig_tmp = CarrierOffset_tmp.*sig_gmsk_ext_r;
			TuneCorr(freqIdx) = sig_ch_est*sig_tmp'/(sig_tmp*sig_tmp');
		end
		[maxCorr, maxPos] = max(TuneCorr);   % 找到相关性最大的频偏位置
		Doppler_est(num_est) = TuneRange(maxPos);
		H_est(num_est) = TuneCorr(maxPos);
		CarrierOffset_est_VA = exp(1j*2*pi*Doppler_est(num_est)*t);     % 相位估计
		
		% 在kk<K时进行干扰消除
		if kk < K
			PhaseShift_est = 1;
			sig_ch_i = PhaseShift_est*H_est(num_est).*CarrierOffset_est_VA.*sig_gmsk_ext_r;     % 根据估计相位和幅度恢复一个用户信号
			% 干扰消除
			sig_ch_sic = F_sigSIC(sig_ch_sic, sig_ch_i, Delay_est(num_est), length(sig_gmsk_ext_r));
		end
	end
	if num_est < K
		% 删除多分配的空间
		VA_result_dec(num_est+1:end, :) = [];
		Delay_est(num_est+1:end) = [];
		Doppler_est(num_est+1:end) = [];
		VA_dec_start(num_est+1:end) = [];
		VA_dec_end(num_est+1:end) = [];
		DataIdx(num_est+1:end) = [];
	end
	
	K = num_est;        % 记录估计出的信号个数
	aisData = [];
	sigPos = [];
	parsEst = [];
	if K ~= 0
		data_rec_VA = cell(1, K);
		VA_crc_check = zeros(1, K);
        for kk = 1 : 1 : K
			% 对分离出的各信号进行CRC校验
			[data_rec_VA{kk}, VA_crc_check(kk)] = F_CRCcheck(VA_result_dec(kk, :));
        end
		
        if ~(all(VA_crc_check == 0))
            [JMLSE_result_dec] = F_jmlseDemod(sig, Delay_est, Doppler_est, H_est, num_est);
            JMLSE_dec_start = zeros(1, K);
            data_rec_JMLSE = cell(1, K);
            JMLSE_crc_check = zeros(1, K);
            for kk = 1 : 1 : K
                JMLSE_dec_start(kk) = F_findDataLoc(JMLSE_result_dec(kk, :));
                [data_rec_JMLSE{kk}, JMLSE_crc_check(kk)] = F_CRCcheck(JMLSE_result_dec(kk, :));
            end
            JMLSE_dec_end = DataLength + JMLSE_dec_start - 1;
        else
            JMLSE_crc_check = -ones(1,K);
        end
		
		% 记录解调校验通过的信号, 并返回消除所有强信号的信号用于再次单天线解调
		corrNum = K - sum(VA_crc_check & JMLSE_crc_check);
		corrLoc = 1;
		for SIC_idx = 1 : 1 : K
            if VA_crc_check(SIC_idx) == 0
				aisData{corrLoc} = num2str(data_rec_VA{SIC_idx});
				sigPos(corrLoc, :) = [Start_pos, cell2mat(ant_num)];
				parsEst(corrLoc, :) = [Delay_est(SIC_idx) Doppler_est(SIC_idx)];
				corrLoc = corrLoc + 1;
				DataIdx{SIC_idx} = VA_dec_start(SIC_idx):VA_dec_end(SIC_idx);
				BufferLength(SIC_idx) = 24-(VA_dec_end(SIC_idx)-VA_dec_start(SIC_idx)+1-DataLength);
				DataFrame_r = [Training StartFlag VA_result_dec(SIC_idx,DataIdx{SIC_idx}) EndFlag];
				sig_ch_i = F_aisModul(DataFrame_r, BufferLength(SIC_idx), Delay_est(SIC_idx), Doppler_est(SIC_idx), H_est(SIC_idx));
				sig = F_sigSIC(sig, sig_ch_i, Delay_est(SIC_idx), BlockLength*os);
				continue;
			elseif JMLSE_crc_check(SIC_idx)==0
				aisData{corrLoc} = num2str(data_rec_JMLSE{SIC_idx});
				sigPos(corrLoc, :) = [Start_pos, cell2mat(ant_num)];
				parsEst(corrLoc, :) = [Delay_est(SIC_idx) Doppler_est(SIC_idx)];
				corrLoc = corrLoc + 1;
				DataIdx{SIC_idx} = JMLSE_dec_start(SIC_idx):JMLSE_dec_end(SIC_idx);
				BufferLength(SIC_idx) = 24-(JMLSE_dec_end(SIC_idx)-JMLSE_dec_start(SIC_idx)+1-DataLength);
				DataFrame_r = [Training StartFlag VA_result_dec(SIC_idx,DataIdx{SIC_idx}) EndFlag];
				sig_ch_i = F_aisModul(DataFrame_r, BufferLength(SIC_idx), Delay_est(SIC_idx), Doppler_est(SIC_idx), H_est(SIC_idx));
				sig = F_sigSIC(sig, sig_ch_i, Delay_est(SIC_idx), BlockLength*os);
            end
		end
	end
end