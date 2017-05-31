function [delayEst, dopplerEst, hEst, flag, decisionSeq, match_len, startIndex] = ...
	F_channelEstAndDemod(sig)
% ----
% 此函数对信号参数估计并解调, 先信道估计, 然后进行VA解调, 如不成功则进行差分解调
% 两种解调之前还可加入均衡的代码(为了仿真速度此处未加)
% 输入:
%	sig:接收到的AIS信号
% 输出:
%	delayEst:时延估计
%	dopplerEst:频偏估计
%	hEst:信道响应幅值估计
%	flag:找到同步位的标志
%	decisionSeq:解调后序列
%	match_len:匹配程度
%	startIndex:同步序列的开始位置
% ----
	global Training StartFlag DecodLenth TrainingLength FlagLength locSig ...
		mode os
	if length(sig)<DecodLenth*os
		% 若信号长度小于译码长度则补零
		sig = [sig, zeros(1,DecodLenth*os-length(sig))];
	end
	% 信道参数估计
	[delayEst, dopplerEst, hEst] = F_channelEstimation(sig);
	% VA解调并查找同步位
	VA_dec = F_viterbiDemod(sig, delayEst, dopplerEst);
	VA_dec = F_deNRZI(VA_dec, 1);
	
	% 查找同步位
	startIndex = F_findDataLoc(VA_dec);
	Train_data = [Training, StartFlag];
	test_syn = VA_dec(max(1,startIndex-(TrainingLength+FlagLength)):(startIndex-1));
	len = length(test_syn);
	decisionSeq = VA_dec;
	match_len_VA = sum(test_syn==Train_data(end-len+1:end))/len;
	if strcmp(mode, 'diff')
		% 若为差分+VA模式则判断VA解调的正确性, 若完全正确则无需差分, 否则进行差分解调并
		% 将正确率较高的序列作为输出
		if match_len_VA ~= 1
			% 在此处可加均衡的程序..mex_v2
			[diff_dec, match_len_diff, startIndex_diff] = diff_algo(sig, DecodLenth,...
				delayEst, dopplerEst);
			if match_len_diff > match_len_VA
				decisionSeq = diff_dec;
				match_len = match_len_diff;
			else
				decisionSeq = VA_dec;
				match_len = match_len_VA;
			end
		else
			decisionSeq = VA_dec;
			match_len = match_len_VA;
		end
	else
		match_len = match_len_VA;
	end
	flag = 1;
	if match_len < 0.5
		% 若匹配度小于0.5则认为不能正确解出
		delayEst = locSig.total_time_delay-33;
		flag = 0;
		hEst =  0;
		return;
	end
end