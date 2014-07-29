function [idxa, idxb] = createPairs(sampleData, SampleCountEachPerson)
%idxa: ����sampleData��ǰһ��������ͼƬ�Եĵ�һ��ͼƬ�� ��һ���ǲ�����ͼƬ�Եĵ�һ��ͼƬ
%idxb: ����sampleData��ǰһ��������ͼƬ�Եĵڶ���ͼƬ�� ��һ���ǲ�����ͼƬ�Եĵڶ���ͼƬ

idxa = 1:size(sampleData,2);

%��������ͼƬ�Եĵڶ���ͼƬ������
idxb = zeros(1, size(idxa,2));
t=0;
for i=1:length(SampleCountEachPerson)
    NumOfPerson = SampleCountEachPerson(i);
    idxb(t+1: t+NumOfPerson) = randperm(NumOfPerson)+t;
    while(sum(idxb(t+1: t+NumOfPerson) == idxa(t+1: t+NumOfPerson)) ~= 0)
        idxb(t+1: t+NumOfPerson) = randperm(NumOfPerson)+t;
    end
    t = t+NumOfPerson;
end

 

end