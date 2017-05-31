function sig = F_sigSIC(sig, sig_sic, delay, len)
% ----
% 此函数根据信号时延进行干扰消除
% 输入:
%	sig:原信号
%	sig_sic:需消除的干扰信号
%	delay:干扰信号时延
%	len:信号长度
% 输出:
%	sig:消除干扰后的信号
% ----
	idx_ch = delay + (1:len);
	if idx_ch(1)<1
		tmp = find(idx_ch<1);
		idx_i = max(tmp)+ 1:len;
		idx_ch = 1:idx_ch(end);
	elseif idx_ch(end)>length(sig)
		tmp = find(idx_ch>length(sig));
		idx_i = 1 : min(tmp)-1;
		idx_ch = idx_ch(1):length(sig);
	else
		idx_i = 1:len;
	end

	sig(idx_ch) = sig(idx_ch) - sig_sic(idx_i);
end