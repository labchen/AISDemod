function sigOut = F_cutSig(sigIn, delayEst, len)
% ----
% 此函数根据时延判断信号是否完整并进行补零操作
% 输入:
%	sigIn:待解调GMSK信号
%	delayEst:信号时延估计
%	len:信号长度
% 输出:
%	sigOut:VA算法译码序列
% ----
	tmp_idx = delayEst+(1:len);     % 信号位置编号, 从估计的时延开始向后取一个时隙
	if tmp_idx(1)<1
		% 输入信号第一个时隙不完整, 前面补零
		tmp = find(tmp_idx<1);
		sigOut = [zeros(1,length(tmp)), sigIn(1:tmp_idx(end))];
	elseif tmp_idx(end)>length(sigIn)
		% 输入信号的最后一个时隙不完整, 后面补零
		tmp = find(tmp_idx>length(sigIn));
		sigOut = [sigIn(tmp_idx(1):end), zeros(1,length(tmp))];
	else
		% 输入信号第一时隙为完整时隙
		sigOut = sigIn(tmp_idx);
	end
end