function sigOut = F_cutSig(sigIn, delayEst, len)
% ----
% �˺�������ʱ���ж��ź��Ƿ����������в������
% ����:
%	sigIn:�����GMSK�ź�
%	delayEst:�ź�ʱ�ӹ���
%	len:�źų���
% ���:
%	sigOut:VA�㷨��������
% ----
	tmp_idx = delayEst+(1:len);     % �ź�λ�ñ��, �ӹ��Ƶ�ʱ�ӿ�ʼ���ȡһ��ʱ϶
	if tmp_idx(1)<1
		% �����źŵ�һ��ʱ϶������, ǰ�油��
		tmp = find(tmp_idx<1);
		sigOut = [zeros(1,length(tmp)), sigIn(1:tmp_idx(end))];
	elseif tmp_idx(end)>length(sigIn)
		% �����źŵ����һ��ʱ϶������, ���油��
		tmp = find(tmp_idx>length(sigIn));
		sigOut = [sigIn(tmp_idx(1):end), zeros(1,length(tmp))];
	else
		% �����źŵ�һʱ϶Ϊ����ʱ϶
		sigOut = sigIn(tmp_idx);
	end
end