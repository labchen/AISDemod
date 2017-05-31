function [ output, indicate] = FCS_crc_check(input)
%  the function is proposed for deleting crc bits from the input sequence
n = size(input,2);
crc_no=16;
output = input(1:n);

correct_code=[ 0 0 0 1 1 1 0 1 0 0 0 0 1 1 1 1];

% generator = [1 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 1]; %D^16+D^12+D^5+1
% input(1:crc_no)=mod((input(1:crc_no)+1),2);%x^16[x^16G(x)+FCS]+x^n(x^15+x^14+...+x+1)
% for ii = 1:n % not n-crc_no
%    if(input(1) == 1)
%      input(1:crc_no+1) = mod((input(1:crc_no+1)+generator),2);
%    end
%   input = [input(2:end) input(1)];
% end
% check = input(1:16);

% reuse CRC generator code
tmp = FCS_crc_add(input);
check = 1-tmp(n+1:n+crc_no);

% 0: correct; other: incorrect
indicate = sum(abs(check-correct_code)); 
