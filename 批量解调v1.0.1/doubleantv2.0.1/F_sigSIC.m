function sig = F_sigSIC(sig, sig_sic, delay, len)
% ----
% �˺��������ź�ʱ�ӽ��и�������
% ����:
%	sig:ԭ�ź�
%	sig_sic:�������ĸ����ź�
%	delay:�����ź�ʱ��
%	len:�źų���
% ���:
%	sig:�������ź���ź�
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