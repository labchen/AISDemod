function VA_dec = F_viterbiDemod(sig, delayEst, dopplerEst)
% ----
% 此函数使用viterbi算法解调, 并查找同步位
% 输入:
%	sig:待解调GMSK信号
%	delayEst:信号时延估计
%	dopplerEst:信号频偏估计
% 输出:
%	VA_dec:VA算法译码序列
% ----
	global os Rb state_all state_in state_number decision_delay ...
		Kf L qt DecodLenth
	t = (delayEst+(0:DecodLenth*os-1))/os/Rb;     % 考虑时延的信号时间
	CarrierOffset_est = exp(1j*2*pi*dopplerEst*t); % 频偏恢复载波
	sig_ch_est = F_cutSig(sig, delayEst, DecodLenth*os);
	sig_ch_eq = sig_ch_est ./ CarrierOffset_est;
	VA_dec = VA2_CorrDecay_mex(sig_ch_eq,...
		DecodLenth,os,Kf,L,qt,decision_delay, state_all.', state_in.', state_number,0.9);             % VA译码
	
end