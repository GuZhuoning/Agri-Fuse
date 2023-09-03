function data=read_ENVIimagefile(imgfilename)
%��������ȡimg��ʽ��ǰ����imgͼ����ʽ����'.img'��׺����
if length(imgfilename)>=4
    switch strcmp(imgfilename(length(imgfilename)-3:end), '.img')
        case 0
            hdrfilename=strcat(imgfilename, '.hdr');
        case 1
            hdrfilename=strcat(imgfilename(1: (length(imgfilename)-4)), '.hdr');
    end
else
    hdrfilename=strcat(imgfilename, '.hdr');
end
%��ȡENVI��׼��ʽͼ���ļ�
%��ȡͼ��ͷ�ļ�
fid = fopen(hdrfilename, 'r');
info = fread(fid,'char=>char');
info=info';%Ĭ�϶�������������Ҫת��Ϊ��������������ʾ
fclose(fid);
%��������
a=strfind(info,'samples = ');
b=length('samples = ');
c=strfind(info,'lines');
samples=[];
for i=a+b:c-1
    samples=[samples,info(i)];
end
samples=str2num(samples);
%��������
a=strfind(info,'lines   = ');
b=length('lines   = ');
c=strfind(info,'bands');
lines=[];
for i=a+b:c-1
    lines=[lines,info(i)];
end
lines=str2num(lines);
%���Ҳ�����
a=strfind(info,'bands   = ');
b=length('bands   = ');
c=strfind(info,'header offset');
bands=[];
for i=a+b:c-1
    bands=[bands,info(i)];
end
bands=str2num(bands);
%������������
a=strfind(info,'data type = ');
b=length('data type = ');
%c=strfind(info,'data ignore');
c=strfind(info,'interleave');
datatype=[];
for i=a+b:c-1
    datatype=[datatype,info(i)];
end
datatype=str2num(datatype);
precision=[];
switch datatype
    case 1
        precision='uint8=>uint8';%ͷ�ļ���datatype=1��ӦENVI����������ΪByte����ӦMATLAB����������Ϊuint8
    case 2
        precision='int16=>int16';%ͷ�ļ���datatype=2��ӦENVI����������ΪInteger����ӦMATLAB����������Ϊint16
    case 12
        precision='uint16=>uint16';%ͷ�ļ���datatype=12��ӦENVI����������ΪUnsighed Int����ӦMATLAB����������Ϊuint16
    case 3
        precision='int32=>int32';%ͷ�ļ���datatype=3��ӦENVI����������ΪLong Integer����ӦMATLAB����������Ϊint32
    case 13
        precision='uint32=>uint32';%ͷ�ļ���datatype=13��ӦENVI����������ΪUnsighed Long����ӦMATLAB����������Ϊuint32
    case 4
        precision='float32=>float32';%ͷ�ļ���datatype=4��ӦENVI����������ΪFloating Point����ӦMATLAB����������Ϊfloat32
    case 5
        precision='double=>double';%ͷ�ļ���datatype=5��ӦENVI����������ΪDouble Precision����ӦMATLAB����������Ϊdouble
    otherwise
        error('invalid datatype');%�����ϼ��ֳ�����������֮�������������Ϊ��Ч����������
end
%�������ݸ�ʽ
a=strfind(info,'interleave = ');
b=length('interleave = ');
c=strfind(info,'sensor type');
interleave=[];
for i=a+b:c-1
    interleave=[interleave,info(i)];
end
interleave=strtrim(interleave);%ɾ���ַ����еĿո�
%��ȡͼ���ļ�
fid = fopen(imgfilename, 'r');
data = multibandread(imgfilename ,[lines, samples, bands],precision,0,interleave,'ieee-le');
data= double(data);
fclose(fid);
end