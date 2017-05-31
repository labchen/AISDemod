function sig = F_aisModul(data, buffer, delay, doppler, h)
% ----
% 此函数对二进制信息进行AIS调制, 含NRZI编码、GMSK调制并增加信号频偏和幅值
% 输入:
%	data:二进制信息序列
%	delay:信号时延
%	doppler:信号频偏
%	h:信道响应幅值
%	buffer:缓冲区长度
% 输出:
%	sig:AIS信号
% ----
	if ~exist('delay', 'var')
		delay = 0;
	end
	if ~exist('doppler', 'var')
		doppler = 0;
	end
	if ~exist('h', 'var')
		h = 1;
	end
	global symbols next_out_diff next_state_diff m_diff terminate_diff ...
		RisingLength os Rb BT L Kf truncate
	% NRZI编码
	data_r = 1 - data;
	% differential encoder
	data_diff_r = encode_trellis(data_r, next_out_diff, next_state_diff, ...
		m_diff, terminate_diff);
	% NRZI
	sym_nrzi_r = symbols(data_diff_r + 1);
	% GMSK调制
	sig_gmsk_r = F_gmskMod(sym_nrzi_r, os, Rb, BT, L, Kf, truncate);
	sig_gmsk_ext_r = [zeros(1,RisingLength*os), sig_gmsk_r, zeros(1,buffer*os)];	% 增加信号上升沿
	% 增加频偏
	t = (delay + (0:length(sig_gmsk_ext_r)-1))/os/Rb;
	CarrierOffset_est_SIC = exp(1j*2*pi*doppler*t);
	PhaseShift_est = 1; % H_est adjusted
	sig = PhaseShift_est*h.*CarrierOffset_est_SIC.*sig_gmsk_ext_r;
end